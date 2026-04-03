# Model B Execution Evidence

## Approach
Model B implemented AST-based static extraction in `src/prefect/utilities/callables.py` with the following new functions:
- `_generate_parameter_schema` — shared schema-generation logic used by both `parameter_schema()` and `parameter_schema_from_entrypoint()`
- `_resolve_entrypoint` — splits entrypoint strings into (path, func_name) supporting both colon and dot formats
- `_read_flow_decorator_kwargs` — AST-based extraction of `@flow(...)` kwargs, handles bare `@flow`, `@flow(...)`, and `@prefect.flow(...)` forms
- `_entrypoint_flow_name` / `_entrypoint_flow_description` — convenience functions
- `_load_safe_namespace` — executes imports individually with error suppression
- `_signature_from_ast` — builds `inspect.Signature` from AST FunctionDef
- `parameter_schema_from_entrypoint` — generates ParameterSchema from entrypoint string

Updated `src/prefect/cli/deploy.py` to replace runtime flow loading with static alternatives. Also fixed a pydantic v2 compatibility issue using `ConfigDict(arbitrary_types_allowed=True)`.

Added 20 new tests in `tests/utilities/test_callables.py` (in the existing test file, not a new file).

## Test Execution
- Ran pytest on new test classes: **20 passed, 34 deselected in 9.49s**
- Fixed `TestBuildSafeNamespace` → `TestLoadSafeNamespace` naming to match actual function
- Noted pre-existing failures in `TestFunctionToSchema` (pydantic v2 schema format differences with `$ref` vs `allOf`), confirmed these are not caused by the changes
- Ran comprehensive test: **29 passed, 25 deselected in 9.16s**
- Ran ruff check and format: fixed 2 lint errors, reformatted 2 files
- All lint issues resolved

## File Changes
- `src/prefect/cli/deploy.py`: modified imports and entrypoint logic
- `src/prefect/utilities/callables.py`: added static extraction functions
- `tests/utilities/test_callables.py`: added 20 new tests across 3 test classes

## Runtime
10m21s
