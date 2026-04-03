# Model A Execution Evidence

## Approach
Model A implemented AST-based static extraction in `src/prefect/utilities/callables.py` with the following new functions:
- `_generate_parameter_schema()` — shared schema-generation logic for both live and static paths
- `_resolve_source_path()` — splits entrypoints in `path:func` or `module.path.func` formats
- `_find_flow_decorator_kwargs()` — locates `@flow` decorator on AST FunctionDef
- `_read_flow_decorator_kwargs_from_source()` — extracts specific keyword from `@flow(...)` via AST
- `_entrypoint_flow_name()` / `_entrypoint_flow_description()` — convenience wrappers
- `_build_safe_namespace()` (aliased as `_load_safe_namespace`) — executes imports individually with error suppression
- `_signature_from_ast()` — builds `inspect.Signature` from AST
- `parameter_schema_from_entrypoint()` — generates schema from entrypoint string

Updated `src/prefect/cli/deploy.py` to use static alternatives, removed `load_flow_from_entrypoint` import, removed mutual-exclusion check.

Created new test file `tests/utilities/test_callables_static.py` with 26 tests.

## Test Execution
- Ran `python3 -m pytest tests/utilities/test_callables_static.py -q --no-header`: **26 passed in 1.68s**
- Ran `ruff check` on modified files: **All checks passed**
- Import verification: `from prefect.cli.deploy import _run_single_deploy; print('import ok')` — succeeded
- Also reset `tests/utilities/test_callables.py` after noticing it had B workspace stash merge changes

## File Changes
- `src/prefect/cli/deploy.py`: 31 insertions/deletions net change
- `src/prefect/utilities/callables.py`: 322 new lines of implementation
- `tests/utilities/test_callables_static.py`: 323 lines (new file)
- Total: 636 insertions, 40 deletions

## Runtime
9m34s
