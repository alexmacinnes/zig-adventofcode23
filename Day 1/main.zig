const std = @import("std");

const NODIGIT = 255;

pub fn main() !void {
    var first: u8 = 0;
    var last: u8 = 0;
    var total: u64 = 0;
    var digit: u8 = 0;
    var i: usize = 0;
    var nextVal: u8 = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [8192]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        for (line) |ch| {
            digit = toDigit(ch);
            if (digit != NODIGIT) {
                first = digit;
                break;
            }
        }

        i = line.len;
        while (i > 0) {
            i -= 1;
            digit = toDigit(line[i]);
            if (digit != NODIGIT) {
                last = digit;
                break;
            }
        }

        nextVal = (10 * first) + last;
        total += nextVal;
    }

    std.debug.print("{d}", .{total});
    return;
}

inline fn toDigit(ch: u8) u8 {
    if (ch >= '0' and ch <= '9') {
        return ch - '0';
    }
    return NODIGIT;
}
