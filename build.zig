const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const exe = b.addExecutable(.{
        .name = "zox",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
    });

    b.installArtifact(exe);
}
