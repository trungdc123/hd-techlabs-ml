Both models hit the context limit in turn 3 before writing test coverage for the new parameter kinds. The implementation is complete and verified via inline scripts, but no new test cases were added for VAR_POSITIONAL, VAR_KEYWORD, or POSITIONAL_ONLY parameter handling.

Add test cases to tests/utilities/test_callables.py that verify _signature_from_ast (and by extension parameter_schema_from_entrypoint) correctly handles:

1. A flow function using *args with a type annotation — the schema should include args with the correct type and as required.
2. A flow function using **kwargs with a type annotation — the schema should include kwargs with the correct type and as required.
3. A flow function using positional-only parameters (before /) — the schema should include those parameters at the correct positions with their types and defaults.
4. A flow function combining all five parameter kinds (positional-only, positional-or-keyword, *args, keyword-only, **kwargs) — the schema should include all parameters in the correct order with the correct types, defaults, and required status.
5. A flow function with positional-only parameters that have defaults — verify the defaults are correctly aligned across the combined posonlyargs + args sequence.

Run the existing test suite for test_callables.py after adding the tests to confirm nothing regressed.
