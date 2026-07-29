// Buffer C (buffer) — Apple I Emulator by Flyguy
// https://www.shadertoy.com/view/tlX3W7

/*
MOS 6502 Emulator

Decimal mode & illegal opcodes are not implemented.

Instructions are decoded into a simplified form using the "microcode" table in Buffer A.

Uses a hash-map based cache to keep track of changed values in RAM without a large array
the full size of RAM or searching the entire cache for each read/write.
This can sometimes get bottlenecked due to the cache size, reducing the speed as a result.
The cache is somewhat small since large arrays have a significant performance impact.

Calculates the hash of the destination address mod cache size.
Indexes the cache with the hash result.
Checks the cache at the location to see if it's free (2 slots per cache entry)
If it's free, writes the address & value to the cache.
If it's in use, sets 'collision' to true to stop the emulator and purge the cache.

The cache functions assume an address of 0 in the cache array is a unused slot.
The address+1 is saved to the cache array. When read, the address-1 is returned.
This assumes the array is automatically initialized to 0, though this may be undefined behavior on some systems.
*/

//Globals
ivec2 uv;
vec4 frag;
CPUState cpu, lastState;
bool collision = false, displayReady = false;
ivec4[CACHE_SIZE] cache;
int[DSPBUF_SIZE] dsp_buffer;
int dsp_ptr = 0;

//Writes the cache to the backbuffer for write-back.
void saveCache()
{
    if(IN_RECT(uv, CACHE_BASE, ivec2(CACHE_SIZE,1)))
	{
        frag = vec4(cache[uv.x - CACHE_BASE.x]);
    }
    
    if(IN_RECT(uv, DSPBUF_BASE, ivec2(DSPBUF_SIZE,1)))
	{
        frag = vec4(dsp_buffer[uv.x - DSPBUF_BASE.x],0,0,0);
    }
}

//Writes CPU state to the backbuffer
void saveState(CPUState state)
{
    if(uv == STATE_BASE)
    {
    	frag = vec4(pack_cpu_state(state));   
    }
}

//Read CPU stste from last frame
CPUState readState()
{
	return unpack_cpu_state(ivec4(texelFetch(iChannel1, STATE_BASE, 0)));
}

void writePIA(int addr, inout int v)
{
    if(addr == DSP) //Set bit 7 of DSP if written to
    {
        //If the display isn't ready, write null chars (0).
        //7th bit is dropped as some chars from wozmon/basic have the 7th bit set which 
        v = displayReady ? v & 0x7F : 0x00;
        
        if(dsp_ptr < DSPBUF_SIZE)
        {
        	dsp_buffer[dsp_ptr++] = v;
            
            if(dsp_ptr >= DSPBUF_SIZE)
            {
                v |= 0x80; //Set bit 7 (terminal wait) if the buffer is full.
            }
        }
        else
        {
            v |= 0x80; //Keep bit 7 set if written to after the buffer is full.
        }
    }

    if(addr == DSPCR) //Set display ready flag if DSPCR != 0
    {
        displayReady = (v != 0); 
    }   
}

//Writes an address & value to the cache, written to memory next frame.
//collision = true if the cache location is in use.
void writeMem(int addr, int v)
{
    addr &= ADDR_MASK;
    v &= DATA_MASK;
    
    writePIA(addr, v);
    
    int ci = hash(addr);
    ivec4 cr = cache[ci];
    
    if(cr.x == 0 || cr.x == addr+1)
    {
    	cache[ci].xy = ivec2(addr+1, v);
        return;
    }
    else if(cr.z == 0 || cr.z == addr+1)
    {
        cache[ci].zw = ivec2(addr+1, v);
        return;
    } 
    
    collision = true;
}


void readPIA(int addr)
{
    if(addr == KBD) //Clear KBDCR if KBD is read
    {
        writeMem(KBDCR,0x00);
    }
}

//Read 8-bit value from memory
//Checks if an address is cached.
//If so, returns cached result
//If not, reads from the memory buffer
int readMem8(int addr)
{
    addr &= ADDR_MASK;
    
    readPIA(addr);
    
    ivec4 cr = cache[hash(addr)]; 
    bvec2 cmp = equal(cr.xz, ivec2(addr+1));
    int result = int(texelFetch(iChannel0, map_region(addr, MEM_BASE, MEM_SIZE), 0).x);;
    
    if(any(cmp))
    {
    	result = cmp.x ? cr.y : cr.w;
    }
    
    return result;
}

//Read 16-bit value from memory (low byte 1st)
int readMem16(int addr)
{
	int lo = readMem8(addr);
    int hi = readMem8(addr+1);
    return (hi << DATA_BITS) | lo;
}

//Fetch 8-bit value at current PC
int fetch8()
{
	int result = readMem8(cpu.reg_PC);
    cpu.reg_PC++;
    return result;
}

//Fetch 16-bit value at current PC
int fetch16()
{
	int lo = readMem8(cpu.reg_PC);
    cpu.reg_PC++;
    int hi = readMem8(cpu.reg_PC);
    cpu.reg_PC++;
    return (hi << DATA_BITS) | lo;
}

//Set negative & zero flags based on A register
void setNZ()
{
    BSET(cpu.reg_PSW, N, GETBIT(cpu.reg_A, N));
    BSET(cpu.reg_PSW, Z, cpu.reg_A == 0);
}

//Set negative & zero flags based on value 'v'
void setNZ(int v)
{
    BSET(cpu.reg_PSW, N, GETBIT(v, N));
    BSET(cpu.reg_PSW, Z, v == 0);
}

int decodeAddress(int mode)
{
    int addr = 0;
    
    if(mode == NON)
    {
        //Do nothing    
    }
    
    if(mode == IND)
    {
        int indAddr = fetch16();
        int pcLo = readMem8(indAddr);
        int pcHi = readMem8((indAddr&0xFF00) | (indAddr+1)&0xFF);
        addr = (pcHi << 8) | pcLo;
    }
    
    if(mode == ABS)
    {
        addr = fetch16();
    }
    
    if(mode == REL)
    {
        addr = signed8(fetch8()) + cpu.reg_PC;
    }
    
    if(mode == IMM)
    {
        addr = cpu.reg_PC;
        cpu.reg_PC++;
    }
    
    if(mode == ZPG)
    {
        addr = fetch8();
    }
    
    if(mode == ZPX)
    {
        addr = (fetch8() + cpu.reg_X) & DATA_MASK;
    }
    
    if(mode == ZPY)
    {
        addr = (fetch8() + cpu.reg_Y) & DATA_MASK;
    }
    
    if(mode == IDX)
    {
        addr = readMem16((fetch8() + cpu.reg_X) & DATA_MASK);
    }
    
    if(mode == IDY)
    {
        addr = readMem16(fetch8());
        addr = (addr & 0xFF00) | ((addr + cpu.reg_Y) & 0xFF); //Page boundary bug
    }
    
    if(mode == ABX)
    {
        addr = (fetch16() + cpu.reg_X) & ADDR_MASK;
    }
    
    if(mode == ABY)
    {
        addr = (fetch16() + cpu.reg_Y) & ADDR_MASK;
    }
    
    return addr;
}

int readRegister(int reg, int mode, out int addr)
{
    int val = 0;
  
    if(reg == NON)
    {
        //Do nothing    
    }
    
    if(reg == ACC)
    {
        val = cpu.reg_A;
    }
    
    if(reg == XRE)
    {
        val = cpu.reg_X;
    }
    
    if(reg == YRE)
    {
        val = cpu.reg_Y;
    }
    
    if(reg == STK) //Pop on read
    {
        cpu.reg_SP = (cpu.reg_SP+1) & DATA_MASK; 
        val = readMem8(STACK_BASE + cpu.reg_SP);
    }
    
    if(reg == SPT)
    {
        val = cpu.reg_SP;
    }
    
    if(reg == PSW)
    {
        val = cpu.reg_PSW;
    }
    
    if(reg == IPT)
    {
        val = cpu.reg_PC;
    }
    
    if(reg == MEM)
    {
        addr = decodeAddress(mode);
        val = readMem8(addr);
    }
    
    return val;
}

int readRegister(int reg, int mode)
{
    int tmp = 0;
    return readRegister(reg,mode,tmp);
}

void writeRegister(int reg, int addr, int val)
{
    if(reg == NON)
    {
        //Do nothing    
    }
    
    if(reg == ACC)
    {
        cpu.reg_A = val;
    }
    
    if(reg == XRE)
    {
        cpu.reg_X = val;
    }
    
    if(reg == YRE)
    {
        cpu.reg_Y = val;
    }
    
    if(reg == STK) //Push on write
    {
        writeMem(STACK_BASE + cpu.reg_SP, val);
        cpu.reg_SP = (cpu.reg_SP-1) & DATA_MASK;
    }
    
    if(reg == SPT)
    {
        cpu.reg_SP = val;
    }
    
    if(reg == PSW)
    {
        cpu.reg_PSW = val;
    }
    
    if(reg == IPT)
    {
        cpu.reg_PC = val;
    }
    
    if(reg == MEM)
    {
        writeMem(addr, val);
    }
}


void executeOp(ivec4 ucode)
{
    int dst = ucode.x;  //Destination Register
    int src = ucode.y;  //Source Register
    int mode = ucode.z; //Address Mode (for MEM/Branches)
    int oper = ucode.w; //Operation
    
    int tmp = 0;
    int dstAddr = 0;
    int dstVal = (dst != STK) ? readRegister(dst, mode, dstAddr) : 0;
	int srcVal = (!(src == MEM && dst == MEM)) ? readRegister(src, mode) : 0; 
    
    if(oper == NON)
    {
        //Do nothing    
    }
    
    if(oper == MOV) //Move/Copy
    {
        dstVal = srcVal;
        if(dst != PSW && dst != MEM && dst != STK && dst != SPT)
        {
        	setNZ(dstVal);
        }
    }
    
    if(oper == INC) //Increment
    {
        dstVal = (dstVal + 1) & DATA_MASK;
        setNZ(dstVal);
    }
    
    if(oper == DEC) //Decrement
    {
        dstVal = (dstVal - 1) & DATA_MASK;
        setNZ(dstVal);
    }
    
    if(oper == ADC || oper == SBC) //Add with carry / Subtract with borrow
    {
        srcVal = (oper == SBC) ? (~srcVal) & DATA_MASK : srcVal; //Invert source bits for SBC
        
        int carry = GETBIT(cpu.reg_PSW, C);
        int tmp_unsigned = dstVal + srcVal + carry;
        int tmp_signed = signed8(dstVal) + signed8(srcVal) + carry;
        
        //C=1 if unsigned add result is >255
        BSET(cpu.reg_PSW, C, tmp_unsigned > 0xFF);
        //V=1 if signed add result is outside the range of a signed 8-bit number (-128 - 127)
        BSET(cpu.reg_PSW, V, tmp_signed < -128 || tmp_signed > 127);
        
        dstVal = tmp_unsigned & DATA_MASK;
        setNZ(dstVal);
    }

    if(oper == AND) ///Bitwise AND
    {
        dstVal = dstVal & srcVal;
        setNZ(dstVal);
    }
    
    if(oper == OR ) //Bitwise OR 
    {
        dstVal = dstVal | srcVal;
        setNZ(dstVal);
    }
    
    if(oper == EOR) //Bitwise XOR
    {
        dstVal = dstVal ^ srcVal;
        setNZ(dstVal);
    }
    
    if(oper == ASL) //Shift bits left, MSB shifted into C
    {
        dstVal = (dstVal << 1);
        BSET(cpu.reg_PSW, C, GETBIT(dstVal, 8));
        dstVal &= DATA_MASK;
		
        setNZ(dstVal);
    }
    
    if(oper == LSR) //Shift bits right, LSB shifted into C
    {
        BSET(cpu.reg_PSW, C, GETBIT(dstVal, 0));
        dstVal = (dstVal >> 1) & DATA_MASK;
		
        setNZ(dstVal);
    }
    
    if(oper == ROL) //Shift bits left, C shifted into LSB, MSB shifted into C
    {
        dstVal = (dstVal << 1);
        dstVal |= GETBIT(cpu.reg_PSW, C);
        BSET(cpu.reg_PSW, C, GETBIT(dstVal, 8));
        dstVal &= DATA_MASK;

        setNZ(dstVal);
    }
    
    if(oper == ROR) //Shift bits right, C shifted into MSB, LSB shifted into C
    {
        dstVal |= GETBIT(cpu.reg_PSW, C) << 8;
        BSET(cpu.reg_PSW, C, GETBIT(dstVal, 0));
        dstVal = (dstVal >> 1) & DATA_MASK;

        setNZ(dstVal);
    }
    
    if(oper == CMP) //Compare DST & SRC (C = DST >= SRC, N = MSB of result, Z = DST == SRC)
    {
        tmp = dstVal - srcVal;
        BSET(cpu.reg_PSW, C, dstVal >= srcVal);
        BSET(cpu.reg_PSW, N, GETBIT(tmp & DATA_MASK, N));
        BSET(cpu.reg_PSW, Z, tmp == 0);
    }
    
    if(oper == BIT) //N = SRC[7], V = SRC[6], Z = (SRC & DST) == 0
    {
        BSET(cpu.reg_PSW, N, GETBIT(srcVal, 7));
        BSET(cpu.reg_PSW, V, GETBIT(srcVal, 6));
        BSET(cpu.reg_PSW, Z, (dstVal & srcVal) == 0);
    }
    
    if(oper == BRK) //Break
    {
        writeRegister(STK, NON, LO(cpu.reg_PC));
        writeRegister(STK, NON, HI(cpu.reg_PC));
        writeRegister(STK, NON, cpu.reg_PSW);
        cpu.reg_PC = readMem16(0xFFFE);
        BSET(cpu.reg_PSW, B, 1);
        BSET(cpu.reg_PSW, I, 1);
    }
    
    if(oper == JMP) //Jump to address
    {
        cpu.reg_PC = decodeAddress(mode);
    }
    
    if(oper == JSR) //Jump to subroutine (Push PC-1 into stack, Jump to address)
    {
        int newPC = decodeAddress(mode);
        cpu.reg_PC = (cpu.reg_PC - 1) & ADDR_MASK;
        writeRegister(STK, NON, HI(cpu.reg_PC));
        writeRegister(STK, NON, LO(cpu.reg_PC));
        cpu.reg_PC = newPC;
    }
    
    if(oper == RTS) //Return from subroutine (Pop PC off stack + 1)
    {   
        int pcLo = readRegister(STK, NON); 
        int pcHi = readRegister(STK, NON); 
            
        cpu.reg_PC = ((pcHi << 8 | pcLo) + 1) & ADDR_MASK;
    }
    
    if(oper == RTI) //Return from interrupt (Pop PSW & PC off stack)
    {
        cpu.reg_PSW = readRegister(STK, NON);
        
        int pcLo = readRegister(STK, NON); 
        int pcHi = readRegister(STK, NON); 
            
        cpu.reg_PC = (pcHi << 8 | pcLo) & ADDR_MASK;
    }
    
    if(oper == BSE) //Jump to address if flag is set
    {
        tmp = decodeAddress(mode);
        if(GETBIT(cpu.reg_PSW, src) == 1)
        {
            cpu.reg_PC = tmp;
        } 
    }
    
    if(oper == BCL) //Jump to address if flag is clear
    {
        tmp = decodeAddress(mode);
        if(GETBIT(cpu.reg_PSW, src) == 0)
        {
            cpu.reg_PC = tmp; 
        }
    }
    
    if(oper == FSE) //Set flag
    {
        BSET(cpu.reg_PSW, src, 1);
    }
    
    if(oper == FCL) //Clear flag
    {
        BSET(cpu.reg_PSW, src, 0);
    }

    writeRegister(dst, dstAddr, dstVal);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    uv = ivec2(fragCoord);
    frag = texelFetch(iChannel1, uv, 0);
    
    bool isCPU = uv == STATE_BASE;
    bool isCache = IN_RECT(uv,CACHE_BASE,ivec2(CACHE_SIZE,1));
    bool isVariable = IN_RECT(uv,VAR_BASE,ivec2(8,1));
    bool isDisplayBuffer = IN_RECT(uv,DSPBUF_BASE,ivec2(DSPBUF_SIZE,1));
    
    if(isCPU || isCache || isVariable || isDisplayBuffer)
    {
        int hitrate = 0;
		int opcode = 0;
        ivec4 ucode = ivec4(0);
        cpu = readState();
        displayReady = bool(READ_VAR4(2,iChannel1).y);
        
        //Initial CPU state
        if(iFrame == 0)
        {
            cpu.reg_A = 0;
            cpu.reg_X = 0;
            cpu.reg_Y = 0;
            cpu.reg_SP = 0xFD;
            cpu.reg_PSW = 0x00;
            cpu.reg_PC = readMem16(RESET_VECTOR);;
            lastState = cpu;
            saveState(cpu);
            displayReady = false;
        }
        
        cpu.reg_PSW |= 0x20; //Unused flag 5 should always be 1
        
        for(int i = 0;i < CYCLES;i++)
        {
            lastState = cpu;
            opcode = fetch8();
			ucode = ivec4(texelFetch(iChannel2,ivec2(opcode,0),0));
            executeOp(ucode);
            
            if(collision)
            {
                //If there's a cache collision, stop the loop until the next frame to clear the cache.
            	cpu = lastState;
                break;
            }
                
            hitrate++;
        }
		
        saveState(cpu); //Save the CPU state
        saveCache(); //Save the cache to be written back to RAM
        
        //Debuging values
        WRITE_VAR4(0,
              lastState.reg_PC,
              opcode,
              0.02*(float((100*hitrate)/CYCLES) - frag.z)+frag.z,
              0.02*(float(hitrate)/iTimeDelta - frag.w)+frag.w);
        
        WRITE_VAR4(1, cpu.reg_A, cpu.reg_X, cpu.reg_Y, cpu.reg_SP);
        WRITE_VAR4(2, cpu.reg_PSW, int(displayReady), 0, 0);
    }
    
    fragColor = frag;
}