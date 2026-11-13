//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;
const ztime = @import("zig_time");
const Time = ztime.Time;
const Level = std.log.Level;
const Writer = Io.Writer;
const Terminal = Io.Terminal;

pub const WriteTarget = union(enum) {
    terminal: Terminal,
    raw: *Writer,
};

pub const WriteOptions = struct {
    time_fmt: []const u8 = "YYYY-MM-DDTHH:mm:ssZ",
    timezone_offset: i32 = 0,
    /// 隐藏 scope 字段。用于不需要 scope 的目标。
    hide_scope: bool = false,
};

pub fn format(
    comptime level: Level,
    comptime scope: @EnumLiteral(),
    comptime fmt: []const u8,
    args: anytype,
) Instance(@TypeOf(args), level, scope, fmt) {
    return Instance(@TypeOf(args), level, scope, fmt){ .args = args };
}

fn Instance(
    comptime Args: type,
    comptime level: Level,
    comptime scope: @EnumLiteral(),
    comptime fmt: []const u8,
) type {
    return struct {
        const Self = @This();
        pub const LEVEL_S = levelText(level);
        pub const LEVEL_C = levelColor(level);
        pub const SCOPE = scope;

        timestamp: ?Io.Timestamp = null,
        args: Args,

        pub fn write(self: *Self, wt: WriteTarget, options: WriteOptions) Writer.Error!void {
            var w: *Writer = undefined;
            var t: ?Terminal = null;
            switch (wt) {
                .terminal => {
                    w = wt.terminal.writer;
                    t = wt.terminal;
                },
                .raw => w = wt.raw,
            }
            if (self.timestamp) |ts| {
                const time = Time.fromNanoTimestamp(ts.nanoseconds).setLoc(.create(options.timezone_offset, ""));
                try time.fmt(options.time_fmt).format(w); // 写入格式化的时间
                try w.writeAll(" "); // 时间后追加空格
            }
            if (t) |term| {
                term.setColor(Self.LEVEL_C) catch {};
                term.setColor(.bold) catch {};
            }
            try w.writeAll(Self.LEVEL_S ++ " "); // 写入级别字符串
            if (t) |term| term.setColor(.reset) catch {};
            if (!options.hide_scope) {
                try w.writeAll(@tagName(Self.SCOPE) ++ " "); // 写入 scope 字符串
            }
            try w.print(fmt ++ "\n", self.args);
        }
    };
}

pub fn levelText(comptime level: Level) []const u8 {
    return switch (level) {
        .debug => "DEBUG",
        .info => "INFO",
        .warn => "WARN",
        .err => "ERROR",
    };
}

pub fn levelColor(comptime level: Level) Terminal.Color {
    return switch (level) {
        .err => .red,
        .warn => .yellow,
        .info => .green,
        .debug => .magenta,
    };
}
