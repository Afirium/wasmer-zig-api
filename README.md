# [WIP] wasmer-zig-api

Zig bindings for the [Wasmer](https://github.com/wasmerio/wasmer/tree/main/lib/c-api) WebAssembly runtime.

This module is based on the zigwasm/wasmer-zig fork. The old API does not work with newer versions of zig, and the main goal of this project is to continue to support the module for newer versions of zig.

All tests from the “wasmer” lib C repository are also reimplemented on zig. You can learn more about the API of this module through rich examples.

The current module works with Zig 0.12.0+.

## Wasmer C API test examples

- [ ] early-exit.c
- [ ] exports-function.c
- [ ] exports-global.c
- [ ] features.c
- [ ] imports-exports.c
- [x] instance.c
- [x] memory.c
- [ ] memory2.c
- [ ] wasi.c

## Running tests and examples
 
- Run library unit tests:
```bash
zig build test
```

- Build and run examples:
```bash
zig build run -Dexamples=true
```
