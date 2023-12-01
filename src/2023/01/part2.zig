const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var result = solve(data);
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const Number = struct {
    word: []const u8,
    value: u16,
};

const numbers = [_]Number{
    .{ .word = "one", .value = 1 },
    .{ .word = "two", .value = 2 },
    .{ .word = "three", .value = 3 },
    .{ .word = "four", .value = 4 },
    .{ .word = "five", .value = 5 },
    .{ .word = "six", .value = 6 },
    .{ .word = "seven", .value = 7 },
    .{ .word = "eight", .value = 8 },
    .{ .word = "nine", .value = 9 },
};

fn solve(data: []const u8) u16 {
    var itr = std.mem.split(u8, data, "\n");
    var sum: u16 = 0;

    while (itr.next()) |line| {
        if (line.len == 0) {
            break;
        }

        var first: u16 = undefined;
        var last: u16 = undefined;
        var found = false;

        for (line, 0..) |char, i| {
            if (std.ascii.isDigit(char)) {
                last = std.fmt.charToDigit(char, 10) catch unreachable;
                if (!found) {
                    first = last;
                    found = true;
                }
            } else {
                for (numbers) |num| {
                    if (line.len - i >= num.word.len) {
                        const word = line[i..(i + num.word.len)];
                        if (std.mem.eql(u8, word, num.word)) {
                            last = num.value;
                            if (!found) {
                                first = last;
                                found = true;
                            }
                            break;
                        }
                    }
                }
            }
        }

        sum += (first * 10) + last;
    }

    return sum;
}

test "Example" {
    const data =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;

    var result = solve(data);

    try std.testing.expectEqual(@as(@TypeOf(result), 281), result);
}
