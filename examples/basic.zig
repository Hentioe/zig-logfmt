const std = @import("std");
const logfmt = @import("zig_logfmt");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer).terminal();
    defer std.debug.unlockStderr();

    const options = logfmt.WriteOptions{};

    var n: u32 = 98;
    n += 1;
    // -- 写入到终端 --
    var formatted = logfmt.format(.info, .main, "Runtime number: {d}", .{n});
    formatted.timestamp = std.Io.Timestamp.now(io, .real);
    try formatted.write(.{ .terminal = stderr }, options);

    // -- 调整选项：隐藏 scope、禁用颜色 --
    var new_options = options;
    new_options.hide_scope = true;
    new_options.no_color = true; // 禁用颜色
    try formatted.write(.{ .terminal = stderr }, new_options);

    // -- 写入到内存 --
    var aw: std.Io.Writer.Allocating = .init(init.gpa);
    defer aw.deinit();

    var mem_hello = logfmt.format(.debug, .mem, "Hello memory: {}", .{n});
    mem_hello.timestamp = std.Io.Timestamp.now(io, .real);
    new_options.no_color = false; // 注意：非终端需主动启用颜色
    try mem_hello.write(.{ .raw = &aw.writer }, new_options);
    try stderr.writer.writeAll(aw.written());
}
