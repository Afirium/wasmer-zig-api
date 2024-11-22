# wasmer-zig-api

Zig bindings for the [Wasmer](https://github.com/wasmerio/wasmer/tree/main/lib/c-api) WebAssembly runtime.

This module is based on the zigwasm/wasmer-zig fork. The old API does not work with newer versions of zig, and the main goal of this project is to continue to support the module for newer versions of zig.

All WASI APIs are also implemented.

All tests from the "wasmer" lib C repository are also reimplemented on zig. You can learn more about the API of this module through rich examples.

The current module works with Zig 0.14.0+.

## Wasmer C API test examples [WIP]

- [ ] early-exit.c
- [ ] exports-function.c
- [ ] exports-global.c
- [ ] features.c
- [x] imports-exports.c
- [x] instance.c
- [x] memory.c
- [x] memory2.c
- [x] wasi.c

## Running tests and examples

The `WASMER_DIR` environment variable is used to determine the presence and location of the Wasmer library. Ensure this variable is set correctly to avoid issues with library detection.

- Run library unit tests:
```bash
zig build test
```

- Build and run examples:
```bash
zig build run -Dexamples=true
```

## Using it

In your zig project folder (where build.zig is located), run:

```bash
zig fetch --save "git+https://github.com/Afirium/wasmer-zig-api#v0.2.0"
```

Then, in your `build.zig`'s `build` function, add the following before
`b.installArtifact(exe)`:

```zig 
    const wasmerZigAPI= b.dependency("wasmer_zig_api", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("wasmer", wasmerZigAPI.module("wasmer"));
    exe.linkLibC();
    exe.addLibraryPath(.{ .cwd_relative = "/home/path_to_your_wasmer/.wasmer/lib" });
    exe.linkSystemLibrary("wasmer");
```
