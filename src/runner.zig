const std = @import("std");
const scanner = @import("scanner.zig");
const token = @import("token.zig");

const fmt = std.fmt;

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

pub fn run_file(
    filepath: [:0]const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    try file.seekTo(0);
    const lines = try file.readToEndAlloc(
        arena.allocator(),
        (try file.stat()).size,
    );

    var s = scanner.init(lines);
    const res = s.scan(arena.allocator());
    if (res) |list| {
        std.debug.print("{any}\n", .{list.items});
    } else |_| {}
}

pub fn run_line() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var line_num: i32 = 1;

    while (true) {
        _ = try stdout.write("> ");

        if (try stdin.readUntilDelimiterOrEofAlloc(arena.allocator(), '\n', 1024)) |line| {
            var s = scanner.init(line);
            const res = s.scan(arena.allocator());
            if (res) |list| {
                std.debug.print("{any}\n", .{list.items});
                line_num += 1;
            } else |_| {}
        } else {
            return;
        }
    }
}

pub fn report(line: i32, where: []const u8, message: []const u8) void {
    _ = try fmt.format(stderr, "Error on {d} {s} {message}\n", .{
        line, where, message,
    });
}
