pub struct Cpu {
    pub registers: [u8; 16],
    pub position_in_memory: usize,
    pub memory: [u8; 0x1000],
    pub stack: [u16; 16],
    pub stack_pointer: usize,
}

impl Cpu {
    pub fn read_opcode(&self) -> u16 {
        let p = self.position_in_memory;
        let op_byte1 = self.memory[p] as u16;
        let op_byte2 = self.memory[p + 1] as u16;
        op_byte1 << 8 | op_byte2
    }

    pub fn run(&mut self) {
        loop {
            let opcode = self.read_opcode();
            self.position_in_memory += 2;

            // let c = ((opcode & 0xF000) >> 12) as u8;
            let x = ((opcode & 0x0F00) >> 8) as u8;
            let y = ((opcode & 0x00F0) >> 4) as u8;
            let d = (opcode & 0x000F) as u8;

            let addr = opcode & 0x0FFF;
            let kk = opcode & 0x00FF;

            match opcode {
                0x0000 => return,
                0x00EE => self.ret(),
                0x2000..=0x2FFF => self.call(addr),
                0x3000..=0x3FFF => self.se(x, d),
                0x4000..=0x4FFF => self.sne(x, d),
                0x6000..=0x6FFF => self.ld(x, kk as u8),
                0x7000..=0x7FFF => self.add(x, d),
                0x8000..=0x8FFF => match d {
                    0 => self.ld(x, y),
                    1 => self.or(x, y),
                    2 => self.and(x, y),
                    3 => self.xor(x, y),
                    4 => self.add_xy(x, y),
                    _ => todo!("opcode {:04x}", opcode),
                },
                _ => todo!("opcode {:04x}", opcode),
            }
        }
    }

    pub fn se(&mut self, register: u8, kk: u8) {
        if self.registers[register as usize] == kk {
            self.position_in_memory += 2;
        }
    }

    pub fn sne(&mut self, register: u8, kk: u8) {
        if self.registers[register as usize] != kk {
            self.position_in_memory += 2;
        }
    }

    pub fn ld(&mut self, register: u8, kk: u8) {
        self.registers[register as usize] = kk;
    }

    pub fn add(&mut self, register: u8, kk: u8) {
        let (val, overflow) = self.registers[register as usize].overflowing_add(kk);
        self.registers[register as usize] = val;
        if overflow {
            self.registers[0xF] = 1;
        } else {
            self.registers[0xF] = 0;
        }
    }

    pub fn and(&mut self, x: u8, y: u8) {
        self.registers[x as usize] &= self.registers[y as usize];
    }

    pub fn or(&mut self, x: u8, y: u8) {
        self.registers[x as usize] |= self.registers[y as usize];
    }

    pub fn xor(&mut self, x: u8, y: u8) {
        self.registers[x as usize] ^= self.registers[y as usize];
    }

    pub fn add_xy(&mut self, x: u8, y: u8) {
        let arg1 = self.registers[x as usize];
        let arg2 = self.registers[y as usize];

        let (val, overflow) = arg1.overflowing_add(arg2);
        self.registers[x as usize] = val;
        if overflow {
            self.registers[0xF] = 1;
        } else {
            self.registers[0xF] = 0;
        }
    }

    pub fn call(&mut self, addr: u16) {
        let sp = self.stack_pointer;
        let stack = &mut self.stack;

        if sp > stack.len() {
            panic!("Stack overflow!")
        }

        stack[sp] = self.position_in_memory as u16;
        self.stack_pointer += 1;
        self.position_in_memory = addr as usize;
    }

    pub fn ret(&mut self) {
        if self.stack_pointer == 0 {
            panic!("Stack underflow!")
        }
        self.stack_pointer -= 1;
        self.position_in_memory = self.stack[self.stack_pointer] as usize;
    }
}
