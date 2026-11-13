const std = @import("std");
const logfmt = @import("zig_logfmt");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer).terminal();
    defer std.debug.unlockStderr();

    const options = logfmt.WriteOptions{};

    var n: u32 = 41;
    n += 1;
    var formatted = logfmt.format(.info, .main, "Runtime number: {d}", .{n});
    formatted.timestamp = std.Io.Timestamp.now(io, .real);

    try formatted.write(.{ .terminal = stderr }, options);

    var new_options = options;
    new_options.hide_scope = true;
    try formatted.write(.{ .terminal = stderr }, new_options);
}
