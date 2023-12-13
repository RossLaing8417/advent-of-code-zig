const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

fn solve(data: []const u8, child_allocator: std.mem.Allocator) !usize {
    var result: usize = 0;

    var arena = std.heap.ArenaAllocator.init(child_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var data_itr = std.mem.splitSequence(u8, data, "\n");

    while (data_itr.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var line_itr = std.mem.splitSequence(u8, line, " ");
        var springs = line_itr.first();

        var groups = try std.ArrayList(usize).initCapacity(allocator, std.mem.count(u8, line, ",") + 1);
        defer groups.deinit();

        var length_itr = std.mem.splitSequence(u8, line_itr.next().?, ",");

        while (length_itr.next()) |length| {
            try groups.append(try std.fmt.parseUnsigned(usize, length, 10));
        }

        var r = trySpringCombinations(springs, 0, groups.items, 0, 0);

        result += r;
    }

    return result;
}

fn trySpringCombinations(
    springs: []const u8,
    index: usize,
    groups: []const usize,
    group_index: usize,
    group_size: usize,
) usize {
    if (index == springs.len) {
        if ((group_index == groups.len - 1 and group_size == groups[group_index]) or group_index == groups.len) {
            return 1;
        }

        return 0;
    }

    if (springs[index] == '.') {
        if (group_size == 0) {
            return trySpringCombinations(springs, index + 1, groups, group_index, 0);
        }
        if (group_index < groups.len and group_size == groups[group_index]) {
            return trySpringCombinations(springs, index + 1, groups, group_index + 1, 0);
        }

        return 0;
    }

    var result: usize = 0;

    if (springs[index] == '?') {
        if (group_size == 0) {
            result += trySpringCombinations(springs, index + 1, groups, group_index, 0);
        }
        if (group_index < groups.len and group_size == groups[group_index]) {
            result += trySpringCombinations(springs, index + 1, groups, group_index + 1, 0);
        }
    }

    if (group_index == groups.len) {
        return result;
    }

    var new_group_size = group_size + 1;

    if (new_group_size > groups[group_index]) {
        return result;
    }

    return result + trySpringCombinations(springs, index + 1, groups, group_index, new_group_size);
}

test "Example" {
    const data =
        \\???.### 1,1,3
        \\.??..??...?##. 1,1,3
        \\?#?#?#?#?#?#?#? 1,3,1,6
        \\????.#...#... 4,1,1
        \\????.######..#####. 1,6,5
        \\?###???????? 3,2,1
    ;

    var result = try solve(data, std.testing.allocator);

    try std.testing.expectEqual(@as(@TypeOf(result), 21), result);
}
