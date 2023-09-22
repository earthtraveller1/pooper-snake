const std = @import("std");

fn does_ninja_exist(allocator: std.mem.Allocator) bool {
    const args = [_][]const u8{ "ninja", "--version" };
    const result = std.process.Child.exec(.{ .allocator = allocator, .argv = &args }) catch {
        return false;
    };

    const Term = std.process.Child.Term;

    switch (result.term) {
        Term.Exited => |exit_code| {
            return exit_code == 0;
        },
        else => {
            return false;
        },
    }

    return false;
}

fn run_command(allocator: std.mem.Allocator, args: []const []const u8) !void {
    const result = try std.process.Child.exec(.{ .allocator = allocator, .argv = args });

    const Term = std.process.Child.Term;

    switch (result.term) {
        Term.Exited => |exit_code| {
            if (exit_code != 0) {
                std.log.err("[ERROR]: Failed to execute command '{s}'. Error log: {s}", .{ args[0], result.stderr });
                return error.ExecutionFailed;
            }
        },
        else => {
            std.log.err("[ERROR]: Failed to execute command '{s}'. Error log: {s}", .{ args[0], result.stderr });
            return error.ExecutionFailed;
        },
    }
}

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const allocator = std.heap.page_allocator;

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Open the directory where all the dependencies are going to go, and create it
    // if it doesn't exist.
    const deps_dir = std.fs.cwd().openDir("deps", .{}) catch deps_block: {
        try std.fs.cwd().makeDir("deps");
        break :deps_block try std.fs.cwd().openDir("deps", .{});
    };

    // Check if the raylib directory exists, and clone the repo if it doesn't.
    const raylib_dir = deps_dir.openDir("raylib", .{}) catch raylib_block: {
        const args = [_][]const u8{ "git", "clone", "--depth=1", "--branch=4.5.0", "https://github.com/raysan5/raylib.git", "deps/raylib" };

        _ = try run_command(allocator, &args);

        break :raylib_block try deps_dir.openDir("raylib", .{});
    };

    // Check if the build directory exists, and build the project if it doesn't.
    _ = raylib_dir.openDir("build", .{}) catch raylib_build_block: {
        var args = std.ArrayList([]const u8).init(allocator);
        defer args.deinit();

        const permanent_args = [_][]const u8{ "cmake", "-S", "deps/raylib", "-B", "deps/raylib/build", "-D", "BUILD_EXAMPLES=False" };
        try args.appendSlice(&permanent_args);

        // Prefer to use Ninja as the build system if it exists, mainly because it's faster.
        if (does_ninja_exist(allocator)) {
            try args.append("-G");
            try args.append("Ninja");
        }

        try run_command(allocator, args.items);

        const build_args = [_][]const u8{ "cmake", "--build", "deps/raylib/build" };
        try run_command(allocator, &build_args);

        break :raylib_build_block try raylib_dir.openDir("build", .{});
    };

    const exe = b.addExecutable(.{
        .name = "pooper-snake",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
