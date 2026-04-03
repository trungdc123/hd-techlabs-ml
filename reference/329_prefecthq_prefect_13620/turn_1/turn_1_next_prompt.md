The implementation handles async def flows via AsyncFunctionDef in the AST walkers, but it does not handle keyword-only arguments in _signature_from_ast. If a flow function uses keyword-only parameters (arguments after a bare * in the signature), the current implementation will silently drop them from the generated schema.

Additionally, the _read_flow_decorator_kwargs function returns None both when the function is not found and when the function is found but has no flow decorator. The callers in _entrypoint_flow_name and _entrypoint_flow_description cannot distinguish these cases, which could silently produce incorrect results when the wrong function name is specified.

Review the keyword-only argument handling in _signature_from_ast and verify that the parameter schema includes kwonly parameters. Also consider whether _read_flow_decorator_kwargs should distinguish between "function not found" and "function found without decorator" for more precise error reporting upstream.
