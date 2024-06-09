const std = @import("std");
const builtin = @import("builtin");
pub const wasm = @import("./wasm.zig");

// Re-exports
pub const ByteVec = wasm.ByteVec;
pub const Engine = wasm.Engine;
pub const Store = wasm.Store;
pub const Module = wasm.Module;
pub const Instance = wasm.Instance;
pub const Extern = wasm.Extern;
pub const Func = wasm.Func;

const OS_PATH_MAX: usize = switch (builtin.os.tag) {
    .windows => std.os.windows.MAX_PATH,
    .linux, .macos => std.os.linux.PATH_MAX,
    else => std.math.maxInt(usize),
};

/// Detect Wasmer library directory
pub fn detectWasmerLibDir(allocator: std.mem.Allocator) !?[]const u8 {
    const argv = [_][]const u8{ "wasmer", "config", "--libdir" };

    // By default, child will inherit stdout & stderr from its parents,
    // this usually means that child's output will be printed to terminal.
    // Here we change them to pipe and collect into `ArrayList`.
    var child = std.process.Child.init(&argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    var stdout = std.ArrayList(u8).init(allocator);
    var stderr = std.ArrayList(u8).init(allocator);
    defer {
        stdout.deinit();
        stderr.deinit();
    }

    try child.spawn();
    try child.collectOutput(&stdout, &stderr, OS_PATH_MAX);

    const term = try child.wait();

    if (stderr.items.len != 0 or term.Exited != 0) return null;

    const stdout_res = try stdout.toOwnedSlice();
    defer allocator.free(stdout_res);

    return try allocator.dupe(u8, std.mem.trimRight(u8, stdout_res, "\r\n"));
}

pub fn lastError(allocator: std.mem.Allocator) ![:0]u8 {
    const buf_len = @as(usize, @intCast(wasmer_last_error_length()));
    const buf = try allocator.alloc(u8, buf_len);
    _ = wasmer_last_error_message(buf.ptr, @as(c_int, @intCast(buf_len)));
    return buf[0 .. buf_len - 1 :0];
}

pub extern "c" fn wasmer_last_error_length() c_int;
pub extern "c" fn wasmer_last_error_message([*]const u8, c_int) c_int;

pub fn watToWasm(wat: []const u8) !ByteVec {
    var wat_bytes = ByteVec.fromSlice(wat);
    defer wat_bytes.deinit();

    var wasm_bytes: ByteVec = undefined;
    wat2wasm(&wat_bytes, &wasm_bytes);

    if (wasm_bytes.size == 0) return error.WatParse;

    return wasm_bytes;
}

extern "c" fn wat2wasm(*const wasm.ByteVec, *wasm.ByteVec) void;

test "detect wasmer lib directory" {
    const result = try detectWasmerLibDir(std.testing.allocator) orelse "";
    defer std.testing.allocator.free(result);

    std.debug.print("Wasmer lib path: {s}\n", .{result});

    try std.testing.expectStringEndsWith(result, ".wasmer/lib");
}

test "transform WAT to WASM" {
    const wat =
        \\(module
        \\  (type $add_one_t (func (param i32) (result i32)))
        \\  (func $add_one_f (type $add_one_t) (param $value i32) (result i32)
        \\    local.get $value
        \\    i32.const 1
        \\    i32.add)
        \\  (export "add_one" (func $add_one_f)))
    ;

    var wasm_bytes = try watToWasm(wat);
    defer wasm_bytes.deinit();

    std.debug.print("Wasm2Wadt {any}", .{wasm_bytes});
}
