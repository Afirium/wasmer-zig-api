# wasmer-zig-api

Zig bindings for the [Wasmer](https://github.com/wasmerio/wasmer/tree/main/lib/c-api) WebAssembly runtime.

This module is based on the zigwasm/wasmer-zig fork. The old API does not work with newer versions of zig, and the main goal of this project is to continue to support the module for newer versions of zig.

All WASI APIs are also implemented.

All tests from the "wasmer" lib C repository are also reimplemented on zig. You can learn more about the API of this module through rich examples.

The current module works with Zig 0.12.0+.

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
 
- Run library unit tests:
```bash
zig build test
```

- Build and run examples:
```bash
zig build run -Dexamples=true
```

## Using it

To use in your own projects, put this dependency into your `build.zig.zon`:

```zig
        .wasmer_zig_api = .{
            .url = "https://github.com/Afirium/wasmer-zig-api/archive/refs/tags/v0.1.0.tar.gz",
            .hash = "122045bc571913d6657fc5671039aca6307d5c636ace43cbdf16897d649b0ba81897",
        }
```

Here is a complete `build.zig.zon` example:

```zig
.{
    .name = "My example project",
    .version = "0.0.1",

    .dependencies = .{
        .wasmer_zig_api = .{
            .url = "https://github.com/Afirium/wasmer-zig-api/archive/refs/tags/v0.1.0.tar.gz",
            .hash = "122045bc571913d6657fc5671039aca6307d5c636ace43cbdf16897d649b0ba81897",
        },
        .paths = .{
            "",
        },
    }
}

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
