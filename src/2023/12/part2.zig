const std = @import("std");

pub fn main() !void {
    const data = @embedFile("input.txt");
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var result = try solve(data, gpa.allocator());
    try std.io.getStdOut().writer().print("{d}\n", .{result});
}

const State = struct {
    index: usize,
    group_index: usize,
    group_size: usize,
};

const StateMap = std.AutoHashMap(State, usize);

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

        var new_springs = try std.ArrayList(u8).initCapacity(allocator, (springs.len * 5) + 4);
        defer new_springs.deinit();

        var new_groups = try std.ArrayList(usize).initCapacity(allocator, groups.items.len * 5);
        defer new_groups.deinit();

        var cache = StateMap.init(allocator);
        defer cache.deinit();

        for (0..5) |i| {
            if (i > 0) {
                try new_springs.append('?');
            }
            try new_springs.appendSlice(springs);
            try new_groups.appendSlice(groups.items);
        }

        var r = try trySpringCombinations(&cache, new_springs.items, 0, new_groups.items, 0, 0, allocator);

        result += r;
    }

    return result;
}

fn trySpringCombinations(
    cache: *StateMap,
    springs: []const u8,
    index: usize,
    groups: []const usize,
    group_index: usize,
    group_size: usize,
    allocator: std.mem.Allocator,
) !usize {
    var state = State{
        .index = index,
        .group_index = group_index,
        .group_size = group_size,
    };

    if (cache.get(state)) |value| {
        return value;
    }

    if (index == springs.len) {
        if ((group_index == groups.len - 1 and group_size == groups[group_index]) or group_index == groups.len) {
            try cache.put(state, 1);
            return 1;
        }

        try cache.put(state, 0);
        return 0;
    }

    if (springs[index] == '.') {
        if (group_size == 0) {
            var result = try trySpringCombinations(cache, springs, index + 1, groups, group_index, 0, allocator);
            try cache.put(state, result);
            return result;
        }
        if (group_index < groups.len and group_size == groups[group_index]) {
            var result = try trySpringCombinations(cache, springs, index + 1, groups, group_index + 1, 0, allocator);
            try cache.put(state, result);
            return result;
        }

        try cache.put(state, 0);
        return 0;
    }

    var result: usize = 0;
    var new_springs = springs;

    if (springs[index] == '?') {
        if (group_size == 0) {
            result += try trySpringCombinations(cache, new_springs, index + 1, groups, group_index, 0, allocator);
        }
        if (group_index < groups.len and group_size == groups[group_index]) {
            result += try trySpringCombinations(cache, new_springs, index + 1, groups, group_index + 1, 0, allocator);
        }
    }

    if (group_index == groups.len) {
        try cache.put(state, result);
        return result;
    }

    var new_group_size = group_size + 1;

    if (new_group_size > groups[group_index]) {
        try cache.put(state, result);
        return result;
    }

    result += try trySpringCombinations(cache, new_springs, index + 1, groups, group_index, new_group_size, allocator);

    try cache.put(state, result);
    return result;
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

    try std.testing.expectEqual(@as(@TypeOf(result), 525152), result);
}
