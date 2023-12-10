const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8, allocator: std.mem.Allocator) !usize {
    var result: usize = 0;

    var line_length = std.mem.indexOf(u8, data, "\n").?;
    var cur_index = std.mem.indexOf(u8, data, "S").?;

    var is_pipe_list = try allocator.alloc(bool, data.len);
    defer allocator.free(is_pipe_list);

    var start_pipe: u8 = blk: {
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

    var pipe = start_pipe;
    var prev_index = data.len;

    while (true) {
        is_pipe_list[cur_index] = true;

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

        if (pipe == 'S') {
            break;
        }
    }

    var prev_char: u8 = undefined;
    var in_loop = false;
    for (data, is_pipe_list) |char, is_pipe| {
        if (is_pipe or char == '\n') {} else {}

        if (is_pipe) {
            switch (if (char == 'S') start_pipe else char) {
                'F', 'L' => prev_char = if (char == 'S') start_pipe else char,
                '7' => in_loop = if (prev_char == 'F') in_loop else !in_loop,
                'J' => in_loop = if (prev_char == 'L') in_loop else !in_loop,
                '|' => in_loop = !in_loop,
                '-' => {},
                else => unreachable,
            }
        } else if (in_loop) {
            result += 1;
        }
    }

    return result;
}

test "Example 1" {
    const data =
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 4), result);
}

test "Example 2" {
    const data =
        \\..........
        \\.S------7.
        \\.|F----7|.
        \\.||....||.
        \\.||....||.
        \\.|L-7F-J|.
        \\.|..||..|.
        \\.L--JL--J.
        \\..........
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 4), result);
}

test "Example 3" {
    const data =
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 8), result);
}

test "Example 4" {
    const data =
        \\FF7FSF7F7F7F7F7F---7
        \\L|LJ||||||||||||F--J
        \\FL-7LJLJ||||||LJL-77
        \\F--JF--7||LJLJ7F7FJ-
        \\L---JF-JLJ.||-FJLJJ7
        \\|F|F-JF---7F7-L7L|7|
        \\|FFJF7L7F-JF7|JL---7
        \\7-L-JL7||F7|L7F-7F7|
        \\L.L7LFJ|||||FJL7||LJ
        \\L7JLJL-JLJLJL--JLJ.L
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 10), result);
}
