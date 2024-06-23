const std = @import("std");
const wasmer = @import("wasmer");
const assert = std.debug.assert;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    std.log.info("Initializing...", .{});

    const engine = try wasmer.Engine.init();
    defer engine.deinit();
    const store = try wasmer.Store.init(engine);
    defer store.deinit();

    const memory_type_1 = try wasmer.MemoryType.init(.{ .min = 0, .max = 0x7FFFFFFF });
    defer memory_type_1.deinit();
    _ = wasmer.Memory.init(store, memory_type_1) catch {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});
    };

    const memory_type_2 = try wasmer.MemoryType.init(.{ .min = 15, .max = 25 });
    defer memory_type_2.deinit();
    const memory_2 = try wasmer.Memory.init(store, memory_type_2);
    defer memory_2.deinit();

    const memory_type_3 = try wasmer.MemoryType.init(.{ .min = 15, .max = 0xFFFFFFFF });
    defer memory_type_3.deinit();
    const memory_3 = try wasmer.Memory.init(store, memory_type_3);
    defer memory_3.deinit();

    std.log.info("Memory size: {any}", .{memory_3.size()});

    // Error: the minimum requested memory is greater than the maximum allowed memory
    const memory_type_4 = try wasmer.MemoryType.init(.{ .min = 0x7FFFFFFF, .max = 0x7FFFFFFF });
    defer memory_type_4.deinit();
    _ = wasmer.Memory.init(store, memory_type_4) catch {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});
    };

    // Error: the minimum requested memory is greater than the maximum allowed memory
    const memory_type_5 = try wasmer.MemoryType.init(.{ .min = 0x7FFFFFFF, .max = 0x0FFFFFFF });
    defer memory_type_5.deinit();
    _ = wasmer.Memory.init(store, memory_type_5) catch {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});
    };

    // Error: the memory is invalid because the maximum is less than the minium
    const memory_type_6 = try wasmer.MemoryType.init(.{ .min = 15, .max = 10 });
    defer memory_type_6.deinit();
    _ = wasmer.Memory.init(store, memory_type_6) catch {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});
    };

    // Error: the minimum requested memory is greater than the maximum allowed memory
    const memory_type_7 = try wasmer.MemoryType.init(.{ .min = 0x7FFFFFFF, .max = 10 });
    defer memory_type_7.deinit();
    _ = wasmer.Memory.init(store, memory_type_7) catch {
        const err_msg = try wasmer.lastError(std.heap.c_allocator);
        defer std.heap.c_allocator.free(err_msg);

        std.log.err("{s}", .{err_msg});
    };

    std.log.info("Done.", .{});
}
