const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const link_mode = b.option(std.builtin.LinkMode, "linkage", "how the library should be linked (default: static)");

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
}
