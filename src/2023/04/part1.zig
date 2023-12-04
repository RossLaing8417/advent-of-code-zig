const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8, _: std.mem.Allocator) usize {
    var result: usize = 0;

    var data_itr = std.mem.split(u8, data, "\n");

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var card_itr = std.mem.splitBackwardsSequence(u8, line, ":");

        var pipe_itr = std.mem.splitSequence(u8, card_itr.first(), "|");
        var winning_itr = std.mem.splitSequence(u8, pipe_itr.first(), " ");
        var num_itr = std.mem.splitSequence(u8, pipe_itr.next().?, " ");

        var count: usize = 0;

        while (winning_itr.next()) |winning_num| {
            if (winning_num.len == 0) {
                continue;
            }

            num_itr.reset();

            while (num_itr.next()) |num| {
                if (num.len == 0) {
                    continue;
                }
                if (std.mem.eql(u8, winning_num, num)) {
                    count += 1;
                    break;
                }
            }
        }

        if (count > 0) {
            result += std.math.pow(usize, 2, count - 1);
        }
    }

    return result;
}

test "Example" {
    const data =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;

    var result = solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 13), result);
}
