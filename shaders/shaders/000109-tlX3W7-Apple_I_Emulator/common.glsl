// Common (common) — Apple I Emulator by Flyguy
// https://www.shadertoy.com/view/tlX3W7

//Emulator Parameters
#define KBD_LAYOUT 0            //0 = QWERTY(US) / 1 = AZERTY
#define CYCLES 600              //Max cycles per frame.
#define CACHE_SIZE 67           //Size of the RAM cache, large values will impact the frame rate.
#define MEM_SIZE ivec2(256,256) //Size of the memory area 256*256=65536 bytes.
#define RESET_VECTOR 0xFFFC     //Location to read the starting address from
#define STACK_BASE 0x100        //Stack base address
#define TERM_SIZE ivec2(40,24)  //Terminal size (chars)
#define DSPBUF_SIZE 40          //Terminal buffer size (max characters per frame)

//Feedback variable locations
#define MEM_BASE ivec2(0,0)    //RAM
#define CURSOR_BASE ivec2(0,0) //Terminal cursor
#define STATE_BASE ivec2(0,0)  //CPU State
#define CACHE_BASE ivec2(1,0)  //RAM Cache
#define VAR_BASE ivec2(0,1)    //Misc persistent variables
#define DSPBUF_BASE ivec2(0,2) //DSP/Terminal buffer

//Apple I PIA Registers
#define KBD 0xD010   //Keyboard input
#define KBDCR 0xD011 //Bit 7 = key was pressed
#define DSP 0xD012   //Terminal output/Bit 7 = wait (PEEK/POKE -12270 in BASIC) 
#define DSPCR 0xD013 //Terminal control register

//Bit Masks
#define DATA_BITS 8
#define ADDR_BITS 16
#define DATA_MASK ((1<<DATA_BITS) - 1)
#define ADDR_MASK ((1<<ADDR_BITS) - 1)

//Microcode labels
//Data Sources (X, Y)
//Flags (NV1BDIZC) (Y)
#define C 0 //Carry
#define Z 1 //Zero
#define I 2 //Interrupt Enabled
#define D 3 //Decimal Mode
#define B 4 //Break
//unused  5 //Always 1
#define V 6 //Overflow
#define N 7 //Negative

//Registers
#define NOR 8  //No Register
#define ACC 9  //Accumulator
#define XRE 10 //X Index
#define YRE 11 //Y Index
#define STK 12 //Stack (read = pull, write = push)
#define SPT 13 //Stack Pointer 
#define PSW 14 //Processor Status Word (Flags)
#define IPT 15 //Instruction Pointer (PC)
#define MEM 16 //Memory
 
//Address Modes (Z)
#define NON 0  //No address
#define IND 1  //addr = mem16[fetch16()]
#define ABS 2  //addr = fetch16()
#define REL 3  //addr = PC + signed8(fetch8())
#define IMM 4  //addr = PC
#define ZPG 5  //addr = fetch8()
#define ZPX 6  //addr = fetch8() + X
#define ZPY 7  //addr = fetch8() + Y
#define IDX 8  //addr = mem16[fetch8() + X]
#define IDY 9  //addr = mem16[fetch8()] + Y
#define ABX 10 //addr = fetch16() + X
#define ABY 11 //addr = fetch16() + Y

//Operations (W)
#define NOP 0  //No Operation
#define MOV 1  //Move
#define INC 2  //Increment
#define DEC 3  //Decrement
#define ADC 4  //Add w/ Carry
#define SBC 5  //Subtract w/ Borrow
#define AND 6  //Bitwise AND
#define OR  7  //Bitwise OR
#define EOR 8  //Bitwise EOR
#define ASL 9  //Arithmatic Shift Left
#define LSR 10 //Logical Shift Right
#define ROL 11 //Rotate Bits Left
#define ROR 12 //Rotate Bits Right
#define CMP 13 //Compare
#define BIT 14 //Check Bits
#define BRK 15 //Break
#define JMP 16 //Jump
#define JSR 17 //Jump To Subroutine
#define RTS 18 //Return From Subroutine
#define RTI 19 //Return From Interrupt
#define BSE 20 //Branch If Flag Is Set
#define BCL 21 //Branch If Flag Is Clear
#define FSE 22 //Set Flag
#define FCL 23 //Flag Clear

//Current state of the cpu
//A = Accumulator Register
//X,Y = Index Registers
//SP = Stack Pointer
//PSW = Processor Status Word (Flags Register)
//PC = Program Counter
struct CPUState
{
	int reg_A,     //8
        reg_X,     //8
        reg_Y,     //8
        reg_SP,    //8
        reg_PSW,   //8 - N,V,1,B,D,I,Z,C
        reg_PC;    //16 
};

//Pack / unpack CPU state to/from an ivec4
//ivec4([0:8,A:8] ,[X:8,Y:8], [SP:8, FLAGS:8], [PC:16])
ivec4 pack_cpu_state(CPUState state)
{
    ivec4 packed = ivec4(0);
    
    packed.x = state.reg_A & DATA_MASK;
    packed.y = ((state.reg_X & DATA_MASK) << DATA_BITS) | (state.reg_Y & DATA_MASK);
    packed.z = ((state.reg_SP & DATA_MASK) << DATA_BITS) | (state.reg_PSW & DATA_MASK);
    packed.w = state.reg_PC & ADDR_MASK;
    
    return packed;
}
    
CPUState unpack_cpu_state(ivec4 packed)
{
	CPUState state;
    state.reg_A = packed.x & DATA_MASK;
    state.reg_X = (packed.y >> DATA_BITS) & DATA_MASK;
    state.reg_Y = packed.y & DATA_MASK;
    state.reg_SP = (packed.z >> DATA_BITS) & DATA_MASK;
    state.reg_PSW = packed.z & DATA_MASK;
    state.reg_PC = packed.w & ADDR_MASK;
    
    return state;
}

//Global Functions
/*
Get 'n' bits from 'v' at index 'i' 
Example: n = 5, i = 2
   |-n-|
v:00000000
       |
i:76543210
*/
#define GETBITS(v,n,i) (((v) >> (i)) & ((1<<(n))-1))

//Get bit 'i' from 'v'
#define GETBIT(v,i) (((v) >> (i))&1)

//Set bit 'i' to 'b' in value 'v', 'b' accepts integer or boolean input.
#define BSET(v,i,b) ((v) = bool(b) ? ((v) | (1<<(i))) : ((v) & ~(1<<(i))))

//Create a mask of 'n' bits Example:n = 3, returns 00000111
#define BITMASK(n) ((1<<(n))-1)

//Get high/low byte of 16-bit value
#define HI(v) ((v >> 8) & 0xFF) 
#define LO(v) (v & 0xFF)

//Write a,b,c,d to variable group 'i'
#define WRITE_VAR4(i,a,b,c,d) if(uv == (VAR_BASE+ivec2(i,0))){frag=vec4(a,b,c,d);}

//Read variable group 'i' from previous frame.
#define READ_VAR4(i,c) texelFetch(c,VAR_BASE+ivec2(i,0),0)

//Is point 'p' is inside the rectangle at point 'o' with size 's'?
#define IN_RECT(p,o,s) (all(greaterThanEqual(p, o)) && all(lessThan(p, (o) + (s))))

//Hash used for the hash-map cache.
int hash(int i)
{
    uint x = uint(i);
    x = ((x >> 16) ^ x) * 0x45d9f3bu;
    x = ((x >> 16) ^ x) * 0x45d9f3bu;
    x = (x >> 16) ^ x;
    return int(x % uint(CACHE_SIZE));  
}

//Unsigned 8-bit number to signed 8-bit number.
//Used for branch offsets and checking for overflow
int signed8(int u8)
{
    u8 &= DATA_MASK;
    return GETBIT(u8, 7)==1 ? -(0x100-u8) : u8;
}

//Maps a linear address to a location in a 2D region.
ivec2 map_region(int addr, ivec2 base, ivec2 size)
{
    return ivec2(addr % size.x, (addr / size.x) % size.y) + base;
}

//Maps a location in a 2D region to a linear address.
int unmap_region(ivec2 uv, ivec2 base, ivec2 size)
{
    uv -= base;
    return (uv.x + uv.y * size.x);
}