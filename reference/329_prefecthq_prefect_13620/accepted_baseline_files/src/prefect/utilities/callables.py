"""
Utilities for working with Python callables.
"""

import ast
import inspect
from functools import partial
from pathlib import Path
from typing import Any, Callable, Dict, Iterable, List, Optional, Tuple

import cloudpickle

from prefect._internal.pydantic import HAS_PYDANTIC_V2
from prefect._internal.pydantic.v1_schema import has_v1_type_as_param

if HAS_PYDANTIC_V2:
    import pydantic.v1 as pydantic

    from prefect._internal.pydantic.v2_schema import (
        create_v2_schema,
        process_v2_params,
    )
else:
    import pydantic

from griffe.dataclasses import Docstring
from griffe.docstrings.dataclasses import DocstringSectionKind
from griffe.docstrings.parsers import Parser, parse
from typing_extensions import Literal

from prefect.exceptions import (
    ParameterBindError,
    ReservedArgumentError,
    SignatureMismatchError,
)
from prefect.logging.loggers import disable_logger


def get_call_parameters(
    fn: Callable,
    call_args: Tuple[Any, ...],
    call_kwargs: Dict[str, Any],
    apply_defaults: bool = True,
) -> Dict[str, Any]:
    """
    Bind a call to a function to get parameter/value mapping. Default values on the
    signature will be included if not overridden.

    Raises a ParameterBindError if the arguments/kwargs are not valid for the function
    """
    try:
        bound_signature = inspect.signature(fn).bind(*call_args, **call_kwargs)
    except TypeError as exc:
        raise ParameterBindError.from_bind_failure(fn, exc, call_args, call_kwargs)

    if apply_defaults:
        bound_signature.apply_defaults()

    # We cast from `OrderedDict` to `dict` because Dask will not convert futures in an
    # ordered dictionary to values during execution; this is the default behavior in
    # Python 3.9 anyway.
    return dict(bound_signature.arguments)


def get_parameter_defaults(
    fn: Callable,
) -> Dict[str, Any]:
    """
    Get default parameter values for a callable.
    """
    signature = inspect.signature(fn)

    parameter_defaults = {}

    for name, param in signature.parameters.items():
        if param.default is not signature.empty:
            parameter_defaults[name] = param.default

    return parameter_defaults


def explode_variadic_parameter(
    fn: Callable, parameters: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Given a parameter dictionary, move any parameters stored in a variadic keyword
    argument parameter (i.e. **kwargs) into the top level.

    Example:

        ```python
        def foo(a, b, **kwargs):
            pass

        parameters = {"a": 1, "b": 2, "kwargs": {"c": 3, "d": 4}}
        explode_variadic_parameter(foo, parameters)
        # {"a": 1, "b": 2, "c": 3, "d": 4}
        ```
    """
    variadic_key = None
    for key, parameter in inspect.signature(fn).parameters.items():
        if parameter.kind == parameter.VAR_KEYWORD:
            variadic_key = key
            break

    if not variadic_key:
        return parameters

    new_parameters = parameters.copy()
    for key, value in new_parameters.pop(variadic_key, {}).items():
        new_parameters[key] = value

    return new_parameters


def collapse_variadic_parameters(
    fn: Callable, parameters: Dict[str, Any]
) -> Dict[str, Any]:
    """
    Given a parameter dictionary, move any parameters stored not present in the
    signature into the variadic keyword argument.

    Example:

        ```python
        def foo(a, b, **kwargs):
            pass

        parameters = {"a": 1, "b": 2, "c": 3, "d": 4}
        collapse_variadic_parameters(foo, parameters)
        # {"a": 1, "b": 2, "kwargs": {"c": 3, "d": 4}}
        ```
    """
    signature_parameters = inspect.signature(fn).parameters
    variadic_key = None
    for key, parameter in signature_parameters.items():
        if parameter.kind == parameter.VAR_KEYWORD:
            variadic_key = key
            break

    missing_parameters = set(parameters.keys()) - set(signature_parameters.keys())

    if not variadic_key and missing_parameters:
        raise ValueError(
            f"Signature for {fn} does not include any variadic keyword argument "
            "but parameters were given that are not present in the signature."
        )

    if variadic_key and not missing_parameters:
        # variadic key is present but no missing parameters, return parameters unchanged
        return parameters

    new_parameters = parameters.copy()
    if variadic_key:
        new_parameters[variadic_key] = {}

    for key in missing_parameters:
        new_parameters[variadic_key][key] = new_parameters.pop(key)

    return new_parameters


def parameters_to_args_kwargs(
    fn: Callable,
    parameters: Dict[str, Any],
) -> Tuple[Tuple[Any, ...], Dict[str, Any]]:
    """
    Convert a `parameters` dictionary to positional and keyword arguments

    The function _must_ have an identical signature to the original function or this
    will return an empty tuple and dict.
    """
    function_params = dict(inspect.signature(fn).parameters).keys()
    # Check for parameters that are not present in the function signature
    unknown_params = parameters.keys() - function_params
    if unknown_params:
        raise SignatureMismatchError.from_bad_params(
            list(function_params), list(parameters.keys())
        )
    bound_signature = inspect.signature(fn).bind_partial()
    bound_signature.arguments = parameters

    return bound_signature.args, bound_signature.kwargs


def call_with_parameters(fn: Callable, parameters: Dict[str, Any]):
    """
    Call a function with parameters extracted with `get_call_parameters`

    The function _must_ have an identical signature to the original function or this
    will fail. If you need to send to a function with a different signature, extract
    the args/kwargs using `parameters_to_positional_and_keyword` directly
    """
    args, kwargs = parameters_to_args_kwargs(fn, parameters)
    return fn(*args, **kwargs)


def cloudpickle_wrapped_call(
    __fn: Callable, *args: Any, **kwargs: Any
) -> Callable[[], bytes]:
    """
    Serializes a function call using cloudpickle then returns a callable which will
    execute that call and return a cloudpickle serialized return value

    This is particularly useful for sending calls to libraries that only use the Python
    built-in pickler (e.g. `anyio.to_process` and `multiprocessing`) but may require
    a wider range of pickling support.
    """
    payload = cloudpickle.dumps((__fn, args, kwargs))
    return partial(_run_serialized_call, payload)


def _run_serialized_call(payload) -> bytes:
    """
    Defined at the top-level so it can be pickled by the Python pickler.
    Used by `cloudpickle_wrapped_call`.
    """
    fn, args, kwargs = cloudpickle.loads(payload)
    retval = fn(*args, **kwargs)
    return cloudpickle.dumps(retval)


class ParameterSchema(pydantic.BaseModel):
    """Simple data model corresponding to an OpenAPI `Schema`."""

    title: Literal["Parameters"] = "Parameters"
    type: Literal["object"] = "object"
    properties: Dict[str, Any] = pydantic.Field(default_factory=dict)
    required: List[str] = None
    definitions: Optional[Dict[str, Any]] = None

    def dict(self, *args, **kwargs):
        """Exclude `None` fields by default to comply with
        the OpenAPI spec.
        """
        kwargs.setdefault("exclude_none", True)
        return super().dict(*args, **kwargs)


def parameter_docstrings(docstring: Optional[str]) -> Dict[str, str]:
    """
    Given a docstring in Google docstring format, parse the parameter section
    and return a dictionary that maps parameter names to docstring.

    Args:
        docstring: The function's docstring.

    Returns:
        Mapping from parameter names to docstrings.
    """
    param_docstrings = {}

    if not docstring:
        return param_docstrings

    with (
        disable_logger("griffe.docstrings.google"),
        disable_logger("griffe.agents.nodes"),
    ):
        parsed = parse(Docstring(docstring), Parser.google)
        for section in parsed:
            if section.kind != DocstringSectionKind.parameters:
                continue
            param_docstrings = {
                parameter.name: parameter.description for parameter in section.value
            }

    return param_docstrings


def process_v1_params(
    param: inspect.Parameter,
    *,
    position: int,
    docstrings: Dict[str, str],
    aliases: Dict,
) -> Tuple[str, Any, "pydantic.Field"]:
    # Pydantic model creation will fail if names collide with the BaseModel type
    if hasattr(pydantic.BaseModel, param.name):
        name = param.name + "__"
        aliases[name] = param.name
    else:
        name = param.name

    type_ = Any if param.annotation is inspect._empty else param.annotation
    field = pydantic.Field(
        default=... if param.default is param.empty else param.default,
        title=param.name,
        description=docstrings.get(param.name, None),
        alias=aliases.get(name),
        position=position,
    )
    return name, type_, field


def create_v1_schema(name_: str, model_cfg, **model_fields):
    model: "pydantic.BaseModel" = pydantic.create_model(
        name_, __config__=model_cfg, **model_fields
    )
    return model.schema(by_alias=True)


def _generate_parameter_schema(
    signature: inspect.Signature, docstring: Optional[str]
) -> ParameterSchema:
    """Shared logic for generating a parameter schema from a signature and docstring."""
    model_fields = {}
    aliases = {}
    docstrings = parameter_docstrings(docstring)

    if HAS_PYDANTIC_V2 and not has_v1_type_as_param(signature):
        from pydantic import ConfigDict

        ModelConfig = ConfigDict(arbitrary_types_allowed=True)
        create_schema = create_v2_schema
        process_params = process_v2_params
    else:

        class ModelConfig:
            arbitrary_types_allowed = True

        create_schema = create_v1_schema
        process_params = process_v1_params

    for position, param in enumerate(signature.parameters.values()):
        name, type_, field = process_params(
            param, position=position, docstrings=docstrings, aliases=aliases
        )
        # Generate a Pydantic model at each step so we can check if this parameter
        # type supports schema generation
        try:
            create_schema(
                "CheckParameter", model_cfg=ModelConfig, **{name: (type_, field)}
            )
        except (ValueError, TypeError):
            # This field's type is not valid for schema creation, update it to `Any`
            type_ = Any
        model_fields[name] = (type_, field)

    # Generate the final model and schema
    schema = create_schema("Parameters", model_cfg=ModelConfig, **model_fields)
    return ParameterSchema(**schema)


def parameter_schema(fn: Callable) -> ParameterSchema:
    """Given a function, generates an OpenAPI-compatible description
    of the function's arguments, including:
        - name
        - typing information
        - whether it is required
        - a default value
        - additional constraints (like possible enum values)

    Args:
        fn (Callable): The function whose arguments will be serialized

    Returns:
        ParameterSchema: the argument schema
    """
    try:
        signature = inspect.signature(fn, eval_str=True)  # novm
    except (NameError, TypeError):
        # `eval_str` is not available in Python < 3.10
        signature = inspect.signature(fn)

    return _generate_parameter_schema(signature, inspect.getdoc(fn))


def raise_for_reserved_arguments(fn: Callable, reserved_arguments: Iterable[str]):
    """Raise a ReservedArgumentError if `fn` has any parameters that conflict
    with the names contained in `reserved_arguments`."""
    function_paremeters = inspect.signature(fn).parameters

    for argument in reserved_arguments:
        if argument in function_paremeters:
            raise ReservedArgumentError(
                f"{argument!r} is a reserved argument name and cannot be used."
            )


def _resolve_entrypoint(entrypoint: str) -> Tuple[str, str]:
    """Split an entrypoint string into (source_path, function_name).

    Supports both ``path/to/file.py:func`` and ``module.path.func`` formats.
    """
    if ":" in entrypoint:
        path, func_name = entrypoint.rsplit(":", maxsplit=1)
    else:
        path, func_name = entrypoint.rsplit(".", maxsplit=1)
    return path, func_name


def _read_flow_decorator_kwargs(
    source_code: str, func_name: str
) -> Optional[Dict[str, Any]]:
    """Parse *source_code* as an AST and return the keyword arguments of the
    ``@flow(...)`` decorator applied to *func_name*.

    Returns:
        A dict of keyword arguments when a ``@flow`` decorator is found
        (empty dict for a bare ``@flow``).  ``None`` when the function is
        found but has no ``@flow`` decorator.

    Raises:
        ValueError: If *func_name* does not exist in *source_code*.
    """
    tree = ast.parse(source_code)
    func_found = False
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name != func_name:
                continue
            func_found = True
            for decorator in node.decorator_list:
                if isinstance(decorator, ast.Call):
                    # @flow(...) or @prefect.flow(...)
                    func = decorator.func
                    is_flow = (isinstance(func, ast.Name) and func.id == "flow") or (
                        isinstance(func, ast.Attribute)
                        and func.attr == "flow"
                        and isinstance(func.value, ast.Name)
                        and func.value.id == "prefect"
                    )
                    if is_flow:
                        kwargs: Dict[str, Any] = {}
                        for kw in decorator.keywords:
                            if kw.arg is not None and isinstance(
                                kw.value, ast.Constant
                            ):
                                kwargs[kw.arg] = kw.value.value
                        return kwargs
                elif isinstance(decorator, (ast.Name, ast.Attribute)):
                    # Bare @flow or @prefect.flow
                    is_flow = (
                        isinstance(decorator, ast.Name) and decorator.id == "flow"
                    ) or (
                        isinstance(decorator, ast.Attribute)
                        and decorator.attr == "flow"
                        and isinstance(decorator.value, ast.Name)
                        and decorator.value.id == "prefect"
                    )
                    if is_flow:
                        return {}
            # Function found but no @flow decorator
            return None
    if not func_found:
        raise ValueError(f"Function {func_name!r} not found in source.")
    return None


def _entrypoint_flow_name(entrypoint: str) -> str:
    """Return the flow name for an entrypoint without importing the module.

    Uses AST parsing to read the ``name`` kwarg from the ``@flow`` decorator.
    Falls back to the function name with underscores replaced by hyphens.

    Raises ``ValueError`` if the function specified in the entrypoint cannot
    be found in the source.
    """
    path, func_name = _resolve_entrypoint(entrypoint)

    if ":" in entrypoint:
        source_code = Path(path).read_text()
    else:
        # module path – resolve to a file
        import importlib.util

        spec = importlib.util.find_spec(path)
        if spec is None or spec.origin is None:
            return func_name.replace("_", "-")
        source_code = Path(spec.origin).read_text()

    # Raises ValueError if the function doesn't exist in the source
    kwargs = _read_flow_decorator_kwargs(source_code, func_name)
    if kwargs is None:
        # Function found but no @flow decorator — fall back to name convention
        return func_name.replace("_", "-")
    return kwargs.get("name", func_name.replace("_", "-"))


def _entrypoint_flow_description(entrypoint: str) -> Optional[str]:
    """Return the flow description for an entrypoint without importing the module.

    Uses AST parsing to read the ``description`` kwarg from the ``@flow`` decorator.
    Returns ``None`` when no description is set.

    Raises ``ValueError`` if the function specified in the entrypoint cannot
    be found in the source.
    """
    path, func_name = _resolve_entrypoint(entrypoint)

    if ":" in entrypoint:
        source_code = Path(path).read_text()
    else:
        import importlib.util

        spec = importlib.util.find_spec(path)
        if spec is None or spec.origin is None:
            return None
        source_code = Path(spec.origin).read_text()

    # Raises ValueError if the function doesn't exist in the source
    kwargs = _read_flow_decorator_kwargs(source_code, func_name)
    if kwargs is None:
        # Function found but no @flow decorator
        return None
    return kwargs.get("description", None)


def _load_safe_namespace(source_code: str) -> Dict[str, Any]:
    """Build a best-effort namespace from *source_code* by executing each
    top-level import and class/function definition individually, swallowing
    any errors so that missing third-party packages don't cause failures.
    """
    tree = ast.parse(source_code)
    namespace: Dict[str, Any] = {}
    for node in tree.body:
        if isinstance(
            node,
            (
                ast.Import,
                ast.ImportFrom,
                ast.ClassDef,
                ast.FunctionDef,
                ast.AsyncFunctionDef,
            ),
        ):
            try:
                code = compile(
                    ast.Module(body=[node], type_ignores=[]),
                    filename="<safe_namespace>",
                    mode="exec",
                )
                exec(code, namespace)
            except Exception:
                pass
    return namespace


def _signature_from_ast(
    func_node: ast.FunctionDef, namespace: Dict[str, Any]
) -> inspect.Signature:
    """Construct an ``inspect.Signature`` from an AST function definition.

    Annotations and default values are evaluated against *namespace*; failures
    are silently replaced with ``inspect.Parameter.empty``.

    Handles all parameter kinds: positional-only, positional-or-keyword,
    VAR_POSITIONAL (*args), keyword-only, and VAR_KEYWORD (**kwargs).
    """
    parameters: List[inspect.Parameter] = []

    # --- positional-only parameters (before / in the signature) ---
    posonlyargs = func_node.args.posonlyargs

    # --- regular positional-or-keyword parameters ---
    regular_args = func_node.args.args

    # defaults are right-aligned across posonlyargs + args combined
    all_positional = posonlyargs + regular_args
    num_positional = len(all_positional)
    num_defaults = len(func_node.args.defaults)
    non_default_count = num_positional - num_defaults

    for i, arg in enumerate(all_positional):
        annotation = _eval_ast_node(arg.annotation, namespace)

        default = inspect.Parameter.empty
        default_idx = i - non_default_count
        if default_idx >= 0:
            default = _eval_ast_node(func_node.args.defaults[default_idx], namespace)

        kind = (
            inspect.Parameter.POSITIONAL_ONLY
            if i < len(posonlyargs)
            else inspect.Parameter.POSITIONAL_OR_KEYWORD
        )

        parameters.append(
            inspect.Parameter(
                arg.arg,
                kind=kind,
                default=default,
                annotation=annotation,
            )
        )

    # --- *args (VAR_POSITIONAL) ---
    if func_node.args.vararg is not None:
        vararg = func_node.args.vararg
        parameters.append(
            inspect.Parameter(
                vararg.arg,
                kind=inspect.Parameter.VAR_POSITIONAL,
                annotation=_eval_ast_node(vararg.annotation, namespace),
            )
        )

    # --- keyword-only arguments (those after * or *args) ---
    for j, arg in enumerate(func_node.args.kwonlyargs):
        annotation = _eval_ast_node(arg.annotation, namespace)

        default = inspect.Parameter.empty
        if j < len(func_node.args.kw_defaults):
            kw_default_node = func_node.args.kw_defaults[j]
            # kw_defaults entries are None when no default is provided
            if kw_default_node is not None:
                default = _eval_ast_node(kw_default_node, namespace)

        parameters.append(
            inspect.Parameter(
                arg.arg,
                kind=inspect.Parameter.KEYWORD_ONLY,
                default=default,
                annotation=annotation,
            )
        )

    # --- **kwargs (VAR_KEYWORD) ---
    if func_node.args.kwarg is not None:
        kwarg = func_node.args.kwarg
        parameters.append(
            inspect.Parameter(
                kwarg.arg,
                kind=inspect.Parameter.VAR_KEYWORD,
                annotation=_eval_ast_node(kwarg.annotation, namespace),
            )
        )

    return inspect.Signature(parameters=parameters)


def _eval_ast_node(node: Optional[ast.expr], namespace: Dict[str, Any]) -> Any:
    """Evaluate an AST expression node against *namespace*.

    Returns ``inspect.Parameter.empty`` when *node* is ``None`` or evaluation
    fails.
    """
    if node is None:
        return inspect.Parameter.empty
    try:
        return eval(  # noqa: S307
            compile(ast.Expression(body=node), "<ast_eval>", "eval"),
            namespace,
        )
    except Exception:
        return inspect.Parameter.empty


def _get_docstring_from_ast(func_node: ast.FunctionDef) -> Optional[str]:
    """Extract the docstring from an AST function definition."""
    return ast.get_docstring(func_node)


def parameter_schema_from_entrypoint(entrypoint: str) -> ParameterSchema:
    """Generate a parameter schema from an entrypoint string without importing
    the module.

    This parses the source file, builds a safe namespace, constructs an
    ``inspect.Signature`` from the AST, and generates the OpenAPI schema.
    """
    path, func_name = _resolve_entrypoint(entrypoint)

    if ":" in entrypoint:
        source_code = Path(path).read_text()
    else:
        import importlib.util

        spec = importlib.util.find_spec(path)
        if spec is None or spec.origin is None:
            return ParameterSchema()
        source_code = Path(spec.origin).read_text()

    tree = ast.parse(source_code)
    func_node = None
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name == func_name:
                func_node = node
                break

    if func_node is None:
        return ParameterSchema()

    namespace = _load_safe_namespace(source_code)
    signature = _signature_from_ast(func_node, namespace)
    docstring = _get_docstring_from_ast(func_node)

    return _generate_parameter_schema(signature, docstring)
