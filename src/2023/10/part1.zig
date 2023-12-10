const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8, _: std.mem.Allocator) !usize {
    var result: usize = 0;

    var line_length = std.mem.indexOf(u8, data, "\n").?;
    var cur_index = std.mem.indexOf(u8, data, "S").?;

    var pipe: u8 = blk: {
        const l_pipe: u8 = if (cur_index > 0 and data[cur_index - 1] != '\n') data[cur_index - 1] else '.';
        const r_pipe: u8 = if (cur_index < data.len - 1 and data[cur_index + 1] != '\n') data[cur_index + 1] else '.';
        const t_pipe: u8 = if (cur_index > line_length) data[cur_index - line_length - 1] else '.';
        const b_pipe: u8 = if (cur_index < data.len - 1 - line_length - 1) data[cur_index + line_length + 1] else '.';

        const l_join = l_pipe == '-' or l_pipe == 'L' or l_pipe == 'F';
        const r_join = r_pipe == '-' or r_pipe == 'J' or r_pipe == '7';
        const t_join = t_pipe == '|' or t_pipe == '7' or t_pipe == 'F';
        const b_join = b_pipe == '|' or b_pipe == 'L' or b_pipe == 'J';

        if (l_join and r_join) break :blk '-';
        if (t_join and b_join) break :blk '|';

        if (l_join and t_join) break :blk 'J';
        if (l_join and b_join) break :blk '7';

        if (r_join and t_join) break :blk 'L';
        if (r_join and b_join) break :blk 'F';
    };

    var loop_length: usize = 0;
    var prev_index = data.len;

    while (true) {
        var next_index: usize = switch (pipe) {
            '|' => if (prev_index == cur_index - line_length - 1) cur_index + line_length + 1 else cur_index - line_length - 1,
            '-' => if (prev_index == cur_index - 1) cur_index + 1 else cur_index - 1,
            'L' => if (prev_index == cur_index + 1) cur_index - line_length - 1 else cur_index + 1,
            'J' => if (prev_index == cur_index - 1) cur_index - line_length - 1 else cur_index - 1,
            '7' => if (prev_index == cur_index - 1) cur_index + line_length + 1 else cur_index - 1,
            'F' => if (prev_index == cur_index + 1) cur_index + line_length + 1 else cur_index + 1,
            else => unreachable,
        };

        prev_index = cur_index;
        cur_index = next_index;
        pipe = data[cur_index];
        loop_length += 1;

        if (pipe == 'S') {
            break;
        }
    }

    result = loop_length / 2;

    return result;
}

test "Example 1" {
    const data =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 4), result);
}

test "Example 2" {
    const data =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 8), result);
}
