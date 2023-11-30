const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
    const epoch_day = epoch_seconds.getEpochDay();
    const epoch_yd = epoch_day.calculateYearDay();

    const year: u16 = b.option(u16, "year", "Year") orelse epoch_yd.year;
    const day: u5 = b.option(u5, "day", "Day") orelse epoch_yd.calculateMonthDay().day_index + 1;

    std.debug.print("Year - {} / Day - {d:0>2}\n", .{ year, day });

    const part: u2 = b.option(u2, "part", "Part") orelse {
        std.debug.print("Specify part 1 or 2\n", .{});
        std.os.exit(2);
    };

    if (part < 1 or part > 2) {
        std.debug.print("Specify part 1 or 2\n", .{});
        std.os.exit(2);
    }

    var src_buff = [_]u8{0} ** 32;
    var src_name = std.fmt.bufPrint(&src_buff, "src/{d:0>4}/{d:0>2}/part{d}.zig", .{ year, day, part }) catch unreachable;

    var exe_buff = [_]u8{0} ** 32;
    var exe_name = std.fmt.bufPrint(&exe_buff, "aoc_{d:0>4}_{d:0>2}_{d}", .{ year, day, part }) catch unreachable;

    const exe = b.addExecutable(.{
        .name = exe_name,
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = src_name },
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
        .root_source_file = .{ .path = src_name },
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
