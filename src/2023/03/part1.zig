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

fn solve(data: []const u8, allocator: std.mem.Allocator) u32 {
    var result: u32 = 0;

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

    for (numbers.items) |num| {
        var valid = false;

        for (num.start..num.end) |index| {
            const row = (index - (index % (line_length + 1))) / (line_length + 1);
            const col = index - (line_length * row) - row;

            if (row > 0 and isValid(data, row - 1, col, line_length)) {
                valid = true;
                break;
            }
            if (isValid(data, row + 1, col, line_length)) {
                valid = true;
                break;
            }

            // Only on the start and end to we need to search diagonally and left or right

            if (index == num.start and col > 0) {
                if (row > 0 and isValid(data, row - 1, col - 1, line_length)) {
                    valid = true;
                    break;
                }
                if (isValid(data, row, col - 1, line_length)) {
                    valid = true;
                    break;
                }
                if (isValid(data, row + 1, col - 1, line_length)) {
                    valid = true;
                    break;
                }
            }

            if (index == num.end - 1 and col < line_length - 1) {
                if (row > 0 and isValid(data, row - 1, col + 1, line_length)) {
                    valid = true;
                    break;
                }
                if (isValid(data, row, col + 1, line_length)) {
                    valid = true;
                    break;
                }
                if (isValid(data, row + 1, col + 1, line_length)) {
                    valid = true;
                    break;
                }
            }
        }

        if (valid) {
            result += num.value;
        }
    }

    return result;
}

fn isValid(data: []const u8, row: usize, col: usize, line_length: usize) bool {
    var i = (row * line_length) + row + col;

    if (i >= data.len) return false;

    const char = data[i];

    if (char == '.' or char == '\n') return false;
    if (std.ascii.isDigit(char)) return false;
    if (std.ascii.isAlphabetic(char)) return false;

    return true;
}

test "Example" {
    // All valid except 114 and 58
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

    try std.testing.expectEqual(@as(@TypeOf(result), 4361), result);
}
