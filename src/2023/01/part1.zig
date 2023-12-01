const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var result = solve(data);
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8) u16 {
    var itr = std.mem.split(u8, data, "\n");
    var sum: u16 = 0;

    while (itr.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var first: u16 = undefined;
        var last: u8 = undefined;
        var found = false;

        for (line) |char| {
            if (std.ascii.isDigit(char)) {
                // std.debug.print("Char - {c}\n", .{char});
                if (!found) {
                    first = std.fmt.charToDigit(char, 10) catch unreachable;
                    found = true;
                }
                last = char;
            }
        }

        last = std.fmt.charToDigit(last, 10) catch unreachable;

        sum += (first * 10) + last;
    }

    return sum;
}

test "Example" {
    const data =
        \\"1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;

    var result = solve(data);

    try std.testing.expectEqual(@as(@TypeOf(result), 142), result);
}
