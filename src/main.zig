const std = @import("std");

const runner = @import("runner.zig");

pub fn run_prompt() !void {}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();

    const filepath = args.next();
    if (filepath == null) {
        return runner.run_line();
    }

    return runner.run_file(filepath.?);
}
