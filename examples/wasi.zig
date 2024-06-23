const std = @import("std");
const wasmer = @import("wasmer");
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const wat =
    \\(module
    \\   (type $mem_size_t (func (result i32)))
    \\   (type $get_at_t (func (param i32) (result i32)))
    \\   (type $set_at_t (func (param i32) (param i32)))
    \\   (memory $mem 1)
    \\   (func $get_at (type $get_at_t) (param $idx i32) (result i32)
    \\     (i32.load (local.get $idx)))
    \\   (func $set_at (type $set_at_t) (param $idx i32) (param $val i32)
    \\     (i32.store (local.get $idx) (local.get $val)))
    \\   (func $mem_size (type $mem_size_t) (result i32)
    \\     (memory.size))
    \\   (export "get_at" (func $get_at))
    \\   (export "set_at" (func $set_at))
    \\   (export "mem_size" (func $mem_size))
    \\   (export "memory" (memory $mem)))
;

pub fn main() !void {
    run() catch |err| {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});

        return err;
    };
}

pub fn run() !void {
    std.log.info("creating the store...", .{});

    const engine = try wasmer.Engine.init();
    defer engine.deinit();
    const store = try wasmer.Store.init(engine);
    defer store.deinit();

    std.log.info("setting up WASI...", .{});

    const wasi_config = try wasmer.WasiConfig.init();

    const js_string =
        \\function greet(name) {
        \\    return JSON.stringify('Hello, ' + name);
        \\};
        \\
        \\print(greet('World'));
    ;

    wasi_config.setArg("--eval");
    wasi_config.setArg(js_string);

    std.log.info("loading binary...", .{});

    const file_content = @embedFile("./assets/qjs.wasm");

    var binary = wasmer.ByteVec.fromSlice(file_content);
    defer binary.deinit();

    std.log.info("compiling module...", .{});

    const module = try wasmer.Module.init(store, binary.toSlice());
    defer module.deinit();

    const wasi_env = try wasmer.WasiEnv.init(store, wasi_config);
    defer wasi_env.deinit();

    std.log.info("instantiating module...", .{});

    var imports = try wasmer.getImports(store, wasi_env, module);
    imports = try wasmer.getImports(store, wasi_env, module);
    defer imports.deinit();

    const instance = try wasmer.Instance.initFromImports(store, module, &imports);
    defer instance.deinit();

    try wasi_env.initializeInstance(store, instance);

    std.log.info("extracting exports...", .{});

    const run_func = try wasmer.getStartFunction(instance);
    defer run_func.deinit();

    std.log.info("calling export...", .{});

    run_func.call(void, .{}) catch |err| {
        std.log.err("Failed to call \"run_func\": {any}", .{err});
        return err;
    };
}
