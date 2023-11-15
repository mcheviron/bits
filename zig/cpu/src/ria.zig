const std = @import("std");

pub const Cpu = struct {
    position_in_memory: usize,
    registers: [16]u8,
    memory: [4096]u8,
    stack: [16]u16,
    stack_pointer: usize,

    pub fn readOpCode(self: *Cpu) u16 {
        var p = self.position_in_memory;
        var op_byte1: u16 = @as(u16, self.memory[p]);
        var op_byte2: u16 = @as(u16, self.memory[p + 1]);

        return op_byte1 << 8 | op_byte2;
    }

    pub fn run(self: *Cpu) void {
        while (true) {
            const opcode = self.readOpCode();
            self.position_in_memory += 2;

            var c = @as(u4, @truncate(((opcode & 0xF000) >> 12)));
            _ = c;
            var x = @as(u4, @truncate(((opcode & 0x0F00) >> 8)));
            var y = @as(u4, @truncate(((opcode & 0x00F0) >> 4)));
            var op_minor = @as(u4, @truncate(opcode & 0x000F));
            var nnn: u16 = opcode & 0x0FFF;
            var kk = @as(u8, @truncate(((opcode & 0x00FF))));

            switch (opcode) {
                0x0000 => return,
                0x00EE => self.ret(),
                0x2000...0x2FFF => self.call(nnn),
                0x3000...0x3FFF => self.se(x, op_minor),
                0x4000...0x4FFF => self.sne(x, op_minor),
                0x6000...0x6FFF => self.ld(x, kk),
                0x7000...0x7FFF => self.add(x, op_minor),
                0x8000...0x8FFF => {
                    switch (op_minor) {
                        0 => self.ld(x, y),
                        1 => self.or_xy(x, y),
                        2 => self.and_xy(x, y),
                        3 => self.xor_xy(x, y),
                        4 => self.add_xy(x, y),
                        else => @panic("Unknown opcode"),
                    }
                },
                else => @panic("Unknown opcode"),
            }
        }
    }

    pub fn se(self: *Cpu, register: u8, d: u8) void {
        if (self.registers[register] == d) {
            self.position_in_memory += 2;
        }
    }

    pub fn sne(self: *Cpu, register: u8, d: u8) void {
        if (self.registers[register] != d) {
            self.position_in_memory += 2;
        }
    }

    pub fn ld(self: *Cpu, register: u8, kk: u8) void {
        self.registers[register] = kk;
    }

    pub fn add(self: *Cpu, register: u8, d: u8) void {
        self.registers[register] += d;
    }

    pub fn or_xy(self: *Cpu, x: u8, y: u8) void {
        self.registers[x] |= self.registers[y];
    }

    pub fn and_xy(self: *Cpu, x: u8, y: u8) void {
        self.registers[x] &= self.registers[y];
    }

    pub fn xor_xy(self: *Cpu, x: u8, y: u8) void {
        self.registers[x] ^= self.registers[y];
    }

    pub fn add_xy(self: *Cpu, x: u8, y: u8) void {
        const a = self.registers[x];
        const b = self.registers[y];
        const result = @addWithOverflow(a, b);
        self.registers[@as(usize, @intCast(x))] = @as(u8, result[0]);
        self.registers[0xF] = @as(u8, result[1]);
    }

    pub fn call(self: *Cpu, addr: u16) void {
        if (self.stack_pointer >= self.stack.len) {
            @panic("Stack overflow\n");
        }
        self.stack[self.stack_pointer] = @as(u16, @intCast(self.position_in_memory));
        self.stack_pointer += 1;
        self.position_in_memory = @as(usize, @intCast(addr));
    }

    pub fn ret(self: *Cpu) void {
        if (self.stack_pointer == 0) {
            @panic("Stack underflow\n");
        }
        self.stack_pointer -= 1;
        self.position_in_memory = self.stack[self.stack_pointer];
    }
};
