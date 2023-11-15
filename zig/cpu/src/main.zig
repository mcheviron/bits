const std = @import("std");
const ria = @import("ria.zig");

pub fn main() !void {
    var cpu = ria.Cpu{
        .position_in_memory = 0,
        .registers = [_]u8{0} ** 16,
        .memory = [_]u8{0} ** 4096,
        .stack = [_]u16{0} ** 16,
        .stack_pointer = 0,
    };

    cpu.registers[0] = 5;
    cpu.registers[1] = 10;

    const mem = &cpu.memory;

    mem[0x000] = 0x21;
    mem[0x001] = 0x00;
    mem[0x002] = 0x21;
    mem[0x003] = 0x00;

    mem[0x100] = 0x80;
    mem[0x101] = 0x14;
    mem[0x102] = 0x80;
    mem[0x103] = 0x14;
    mem[0x104] = 0x00;
    mem[0x105] = 0xEE;

    cpu.run();

    try std.testing.expectEqual(cpu.registers[0], 0x2D);
    std.debug.print("5 + (10 * 2) + (10 * 2) = {}\n", .{cpu.registers[0]});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
