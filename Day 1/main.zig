const std = @import("std");

const NumberLiteral = struct { text: []const u8, value: u8 };

const NUMBER_LITERALS = [_]NumberLiteral{
    NumberLiteral{ .text = "one", .value = 1 },
    NumberLiteral{ .text = "two", .value = 2 },
    NumberLiteral{ .text = "six", .value = 6 },

    NumberLiteral{ .text = "four", .value = 4 },
    NumberLiteral{ .text = "five", .value = 5 },
    NumberLiteral{ .text = "nine", .value = 9 },

    NumberLiteral{ .text = "three", .value = 3 },
    NumberLiteral{ .text = "seven", .value = 7 },
    NumberLiteral{ .text = "eight", .value = 8 },
};

const NODIGIT = 255;

pub fn main() !void {
    var first: u8 = 0;
    var last: u8 = 0;
    var total: u64 = 0;
    var digit: u8 = 0;
    var nextVal: u8 = 0;
    var i: usize = 0;

    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [8192]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        i = 0;
        while (i < line.len) {
            digit = toDigit(line, i);
            if (digit != NODIGIT) {
                first = digit;
                break;
            }
            i += 1;
        }

        i = line.len;
        while (i > 0) {
            i -= 1;
            digit = toDigit(line, i);
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

inline fn toDigit(line: []u8, idx: usize) u8 {
    var ch = line[idx];
    if (ch >= '0' and ch <= '9') {
        return ch - '0';
    }

    for (NUMBER_LITERALS) |x| {
        var lengthRequired = idx + x.text.len;
        if (lengthRequired > line.len) {
            break;
        }
        var slice = line[idx .. idx + x.text.len];
        if (std.mem.eql(u8, slice, x.text)) {
            return x.value;
        }
    }

    return NODIGIT;
}
