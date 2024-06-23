const std = @import("std");
const wasmer = @import("wasmer");
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const wat =
    \\(module
    \\   (func $host_function (import "" "host_function"))
    \\   ;; (global $host_global (import "env" "host_global") i32)
    \\   (func $function (export "guest_function") (result i32) (global.get $global))
    \\   (global $global (export "guest_global") i32 (i32.const 42))
    \\   (table $table (export "guest_table") 1 1 funcref)
    \\   (memory $memory (export "guest_memory") 1)
    \\)
;

fn host_func_callback() void {
    std.log.info("Calling back...\n> ", .{});
}

pub fn main() !void {
    run() catch |err| {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});

        return err;
    };
}

pub fn run() !void {
    var wasm_bytes = try wasmer.watToWasm(wat);
    defer wasm_bytes.deinit();

    std.log.info("creating the store...", .{});

    const engine = try wasmer.Engine.init();
    defer engine.deinit();
    const store = try wasmer.Store.init(engine);
    defer store.deinit();

    std.log.info("compiling module...", .{});

    const module = try wasmer.Module.init(store, wasm_bytes.toSlice());
    defer module.deinit();

    std.log.info("creating the imported function...", .{});

    const host_func = try wasmer.Func.init(store, host_func_callback);
    // defer host_func.deinit();

    // std.log.info("Creating the imported global...", .{});

    std.log.info("instantiating module...", .{});

    const instance = try wasmer.Instance.init(store, module, &.{host_func});
    defer instance.deinit();

    std.log.info("retrieving exports...", .{});

    const guest_function = instance.getExportFunc(module, "guest_function") orelse {
        std.log.err("failed to retrieve \"guest_function\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer guest_function.deinit();

    const memory = instance.getExportMem(module, "guest_memory") orelse {
        std.log.err("failed to retrieve \"guest_memory\" export from instance", .{});
        return error.ExportNotFound;
    };
    defer memory.deinit();
}
