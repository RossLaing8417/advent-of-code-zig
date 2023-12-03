const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = solve(data, gpa.allocator());
    if (result == 527422) return error.NotThisValue;
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const Number = struct {
    value: u32,
    start: usize,
    end: usize,
};

fn solve(data: []const u8, allocator: std.mem.Allocator) usize {
    var result: usize = 0;

    var numbers = std.ArrayList(Number).init(allocator);
    defer numbers.deinit();

    const line_length = std.mem.indexOf(u8, data, "\n") orelse data.len;

    var start: usize = 0;
    var tracking_number = false;

    for (data, 0..) |char, i| {
        if (!tracking_number and std.ascii.isDigit(char)) {
            start = i;
            tracking_number = true;
            continue;
        } else if (tracking_number and !std.ascii.isDigit(char)) {
            tracking_number = false;
            numbers.append(.{
                .value = std.fmt.parseUnsigned(u32, data[start..i], 10) catch unreachable,
                .start = start,
                .end = i,
            }) catch unreachable;
        }
    }

    if (tracking_number) {
        numbers.append(.{
            .value = std.fmt.parseUnsigned(u32, data[start..data.len], 10) catch unreachable,
            .start = start,
            .end = data.len,
        }) catch unreachable;
    }

    for (data, 0..) |char, index| {
        if (char != '*') {
            continue;
        }

        const top_left = index - line_length - 2;
        const top_right = index - line_length;
        // const mid_left = index - 1; // Don't need this as num.end is exclusive so comparing num.end == index is valid
        const mid_right = index + 1;
        const bot_left = index + line_length;
        const bot_right = index + line_length + 2;

        var count: usize = 0;
        var product: usize = 1;
        for (numbers.items) |num| {
            var top_range = (num.end > top_left and num.start <= top_right);
            var mid_range = (num.end == index or num.start == mid_right);
            var bot_range = (num.end > bot_left and num.start <= bot_right);

            if (top_range or mid_range or bot_range) {
                count += 1;
                product *= num.value;
            }
        }

        if (count == 2) {
            result += product;
        }
    }

    return result;
}

test "Example" {
    // Only (467,35) and (755,598)
    const data =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;

    var result = solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 467835), result);
}
