const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8, allocator: std.mem.Allocator) !i64 {
    var result: i64 = 0;

    var data_itr = std.mem.splitSequence(u8, data, "\n");

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var sequence = try allocator.alloc(i64, std.mem.count(u8, line, " ") + 1);
        defer allocator.free(sequence);

        var i: usize = 0;
        var line_itr = std.mem.splitSequence(u8, line, " ");
        while (line_itr.next()) |number| : (i += 1) {
            sequence[i] = try std.fmt.parseInt(i64, number, 10);
        }

        result += try getNextSequenceValue(allocator, sequence);
    }

    return result;
}

fn getNextSequenceValue(allocator: std.mem.Allocator, parent_sequence: []i64) !i64 {
    var sequence = try allocator.alloc(i64, parent_sequence.len - 1);
    defer allocator.free(sequence);

    var all_zero = true;

    for (0..sequence.len) |i| {
        sequence[i] = parent_sequence[i + 1] - parent_sequence[i];

        if (sequence[i] != 0) {
            all_zero = false;
        }
    }

    var next_value = if (all_zero) 0 else try getNextSequenceValue(allocator, sequence);

    return parent_sequence[parent_sequence.len - 1] + next_value;
}

test "Example" {
    const data =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 114), result);
}
