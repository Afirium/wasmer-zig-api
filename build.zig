const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const build_examples_option = b.option(bool, "examples", "Build example files") orelse false;

    const run_step = b.step("run", "Run the app");

    const wasmer_module = b.addModule("wasmer", .{
        .root_source_file = b.path("src/wasmer.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (build_examples_option) {
        var examples_dir = try std.fs.cwd().openDir("examples", .{ .iterate = true });
        defer examples_dir.close();

        var examples_dir_iter = examples_dir.iterate();

        while (try examples_dir_iter.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".zig")) {
                var buffer_exe_path = std.ArrayList(u8).init(b.allocator);
                const exe_name = entry.name[0 .. entry.name.len - 4];

                try buffer_exe_path.appendSlice("examples/");
                try buffer_exe_path.appendSlice(entry.name);

                const exe_path = try buffer_exe_path.toOwnedSlice();

                const example_exe = b.addExecutable(.{
                    .name = exe_name,
                    .root_source_file = b.path(exe_path),
                    .target = target,
                    .optimize = optimize,
                    .link_libc = true,
                });

                example_exe.root_module.addImport("wasmer", wasmer_module);
                example_exe.root_module.addLibraryPath(.{ .cwd_relative = "/home/afirium/.wasmer/lib" });
                example_exe.root_module.linkSystemLibrary("wasmer", .{});

                b.installArtifact(example_exe);
                const run_example_cmd = b.addRunArtifact(example_exe);
                run_example_cmd.step.dependOn(b.getInstallStep());

                run_step.dependOn(&run_example_cmd.step);
            }
        }
    }

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const wasmer_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/wasmer.zig"),
        .target = target,
        .optimize = optimize,
    });

    wasmer_unit_tests.linkLibC();
    wasmer_unit_tests.addLibraryPath(.{ .cwd_relative = "/home/afirium/.wasmer/lib" });
    wasmer_unit_tests.linkSystemLibrary("wasmer");

    const run_wasmer_unit_tests = b.addRunArtifact(wasmer_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_wasmer_unit_tests.step);
}
