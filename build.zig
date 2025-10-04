const std = @import("std");

pub fn build(b: *std.Build) void {
    const testsuite_step = b.step("test:testsuite", "Compile and run testsuite binary");
    const test_step = b.step("test", "Run all tests");

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const link_mode = b.option(std.builtin.LinkMode, "linkage", "how the library should be linked (default: static)");
    const enable_libpng = b.option(bool, "libpng", "Enable libpng to build the test case.") orelse false;

    test_step.dependOn(testsuite_step);

    const zlib = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
    });
    const libspng_src = b.dependency("libspng", .{});

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.linkLibrary(zlib.artifact("z"));
    mod.addCSourceFile(.{
        .file = libspng_src.path("spng/spng.c"),
    });

    const lib = b.addLibrary(.{
        .name = "spng",
        .root_module = mod,
        .linkage = link_mode orelse .static,
    });
    lib.installHeader(libspng_src.path("spng/spng.h"), "spng.h");

    b.installArtifact(lib);

    // tests
    if (enable_libpng) {
        if (b.lazyDependency("libpng", .{})) |libpng| {
            const testsuite_mod = b.createModule(.{
                .target = target,
                .optimize = optimize,
            });
            testsuite_mod.linkLibrary(libpng.artifact("png"));
            testsuite_mod.linkLibrary(lib);
            testsuite_mod.addCSourceFile(.{
                .file = libspng_src.path("tests/testsuite.c"),
            });
            const testsuite_exe = b.addExecutable(.{
                .name = "testsuite",
                .root_module = testsuite_mod,
            });
            const testsuite_exe_run = b.addRunArtifact(testsuite_exe);
            if (b.args) |args| {
                testsuite_exe_run.addArgs(args);
            }
            testsuite_step.dependOn(&testsuite_exe_run.step);
        }
    } else {
        const fail_step = b.addFail("pass -Dlibpng to build/run testsuite");
        testsuite_step.dependOn(&fail_step.step);
    }
}
