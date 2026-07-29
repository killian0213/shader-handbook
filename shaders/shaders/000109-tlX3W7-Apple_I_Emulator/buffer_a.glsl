// Buffer A (buffer) — Apple I Emulator by Flyguy
// https://www.shadertoy.com/view/tlX3W7

/*
Microcode ROM
Used as a lookup table to decode the 6502 opcodes into a simpler form.

ALU instruction format:
DST, SRC, ADDRMODE, OPERATION

Control flow instruction format:
XXX, FLAG, ADDRMODE, OPERATION
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if(iFrame == 0)
    {
        int addr = int(fragCoord.x);
        ivec4 op = ivec4(1);
        
        switch(addr)
        {
            //ADC
            case(0x69): op = ivec4(ACC,MEM,IMM,ADC); break; 
            case(0x65): op = ivec4(ACC,MEM,ZPG,ADC); break; 
            case(0x75): op = ivec4(ACC,MEM,ZPX,ADC); break; 
            case(0x6D): op = ivec4(ACC,MEM,ABS,ADC); break; 
            case(0x7D): op = ivec4(ACC,MEM,ABX,ADC); break; 
            case(0x79): op = ivec4(ACC,MEM,ABY,ADC); break; 
            case(0x61): op = ivec4(ACC,MEM,IDX,ADC); break; 
            case(0x71): op = ivec4(ACC,MEM,IDY,ADC); break; 

            //AND 
            case(0x29): op = ivec4(ACC,MEM,IMM,AND); break; 
            case(0x25): op = ivec4(ACC,MEM,ZPG,AND); break; 
            case(0x35): op = ivec4(ACC,MEM,ZPX,AND); break; 
            case(0x2D): op = ivec4(ACC,MEM,ABS,AND); break; 
            case(0x3D): op = ivec4(ACC,MEM,ABX,AND); break; 
            case(0x39): op = ivec4(ACC,MEM,ABY,AND); break; 
            case(0x21): op = ivec4(ACC,MEM,IDX,AND); break; 
            case(0x31): op = ivec4(ACC,MEM,IDY,AND); break; 

            //ASL
            case(0x0A): op = ivec4(ACC,ACC,NON,ASL); break; 
            case(0x06): op = ivec4(MEM,MEM,ZPG,ASL); break; 
            case(0x16): op = ivec4(MEM,MEM,ZPX,ASL); break; 
            case(0x0E): op = ivec4(MEM,MEM,ABS,ASL); break; 
            case(0x1E): op = ivec4(MEM,MEM,ABX,ASL); break; 

            //BIT
            case(0x24): op = ivec4(ACC,MEM,ZPG,BIT); break; 
            case(0x2C): op = ivec4(ACC,MEM,ABS,BIT); break; 

            //CMP
            case(0xC9): op = ivec4(ACC,MEM,IMM,CMP); break; 
            case(0xC5): op = ivec4(ACC,MEM,ZPG,CMP); break; 
            case(0xD5): op = ivec4(ACC,MEM,ZPX,CMP); break; 
            case(0xCD): op = ivec4(ACC,MEM,ABS,CMP); break; 
            case(0xDD): op = ivec4(ACC,MEM,ABX,CMP); break; 
            case(0xD9): op = ivec4(ACC,MEM,ABY,CMP); break; 
            case(0xC1): op = ivec4(ACC,MEM,IDX,CMP); break; 
            case(0xD1): op = ivec4(ACC,MEM,IDY,CMP); break; 

            //CPX
            case(0xE0): op = ivec4(XRE,MEM,IMM,CMP); break; 
            case(0xE4): op = ivec4(XRE,MEM,ZPG,CMP); break; 
            case(0xEC): op = ivec4(XRE,MEM,ABS,CMP); break; 

            //CPY
            case(0xC0): op = ivec4(YRE,MEM,IMM,CMP); break; 
            case(0xC4): op = ivec4(YRE,MEM,ZPG,CMP); break; 
            case(0xCC): op = ivec4(YRE,MEM,ABS,CMP); break; 

            //DEC
            case(0xC6): op = ivec4(MEM,MEM,ZPG,DEC); break; 
            case(0xD6): op = ivec4(MEM,MEM,ZPX,DEC); break; 
            case(0xCE): op = ivec4(MEM,MEM,ABS,DEC); break; 
            case(0xDE): op = ivec4(MEM,MEM,ABX,DEC); break; 
            case(0xCA): op = ivec4(XRE,XRE,NON,DEC); break; 
            case(0x88): op = ivec4(YRE,YRE,NON,DEC); break; 

            //INC 
            case(0xE6): op = ivec4(MEM,MEM,ZPG,INC); break; 
            case(0xF6): op = ivec4(MEM,MEM,ZPX,INC); break; 
            case(0xEE): op = ivec4(MEM,MEM,ABS,INC); break; 
            case(0xFE): op = ivec4(MEM,MEM,ABX,INC); break; 
            case(0xE8): op = ivec4(XRE,XRE,NON,INC); break; 
            case(0xC8): op = ivec4(YRE,YRE,NON,INC); break; 

            //EOR 
            case(0x49): op = ivec4(ACC,MEM,IMM,EOR); break; 
            case(0x45): op = ivec4(ACC,MEM,ZPG,EOR); break; 
            case(0x55): op = ivec4(ACC,MEM,ZPX,EOR); break; 
            case(0x4D): op = ivec4(ACC,MEM,ABS,EOR); break; 
            case(0x5D): op = ivec4(ACC,MEM,ABX,EOR); break; 
            case(0x59): op = ivec4(ACC,MEM,ABY,EOR); break; 
            case(0x41): op = ivec4(ACC,MEM,IDX,EOR); break; 
            case(0x51): op = ivec4(ACC,MEM,IDY,EOR); break; 

            //LDA
            case(0xA9): op = ivec4(ACC,MEM,IMM,MOV); break; 
            case(0xA5): op = ivec4(ACC,MEM,ZPG,MOV); break; 
            case(0xB5): op = ivec4(ACC,MEM,ZPX,MOV); break; 
            case(0xAD): op = ivec4(ACC,MEM,ABS,MOV); break; 
            case(0xBD): op = ivec4(ACC,MEM,ABX,MOV); break; 
            case(0xB9): op = ivec4(ACC,MEM,ABY,MOV); break; 
            case(0xA1): op = ivec4(ACC,MEM,IDX,MOV); break; 
            case(0xB1): op = ivec4(ACC,MEM,IDY,MOV); break; 

            //LDX
            case(0xA2): op = ivec4(XRE,MEM,IMM,MOV); break; 
            case(0xA6): op = ivec4(XRE,MEM,ZPG,MOV); break; 
            case(0xB6): op = ivec4(XRE,MEM,ZPY,MOV); break; 
            case(0xAE): op = ivec4(XRE,MEM,ABS,MOV); break; 
            case(0xBE): op = ivec4(XRE,MEM,ABY,MOV); break; 

            //LDY
            case(0xA0): op = ivec4(YRE,MEM,IMM,MOV); break; 
            case(0xA4): op = ivec4(YRE,MEM,ZPG,MOV); break; 
            case(0xB4): op = ivec4(YRE,MEM,ZPX,MOV); break; 
            case(0xAC): op = ivec4(YRE,MEM,ABS,MOV); break; 
            case(0xBC): op = ivec4(YRE,MEM,ABX,MOV); break; 

            //LSR
            case(0x4A): op = ivec4(ACC,ACC,NON,LSR); break; 
            case(0x46): op = ivec4(MEM,MEM,ZPG,LSR); break; 
            case(0x56): op = ivec4(MEM,MEM,ZPX,LSR); break; 
            case(0x4E): op = ivec4(MEM,MEM,ABS,LSR); break; 
            case(0x5E): op = ivec4(MEM,MEM,ABX,LSR); break; 

            //NOP 
            case(0xEA): op = ivec4(NOR,NOR,NON,NOP); break; 

            //ORA 
            case(0x09): op = ivec4(ACC,MEM,IMM,OR ); break; 
            case(0x05): op = ivec4(ACC,MEM,ZPG,OR ); break; 
            case(0x15): op = ivec4(ACC,MEM,ZPX,OR ); break; 
            case(0x0D): op = ivec4(ACC,MEM,ABS,OR ); break; 
            case(0x1D): op = ivec4(ACC,MEM,ABX,OR ); break; 
            case(0x19): op = ivec4(ACC,MEM,ABY,OR ); break; 
            case(0x01): op = ivec4(ACC,MEM,IDX,OR ); break; 
            case(0x11): op = ivec4(ACC,MEM,IDY,OR ); break; 

            //STACK 
            case(0x48): op = ivec4(STK,ACC,NON,MOV); break; //PHA
            case(0x08): op = ivec4(STK,PSW,NON,MOV); break; //PSW
            case(0x68): op = ivec4(ACC,STK,NON,MOV); break; //PLA
            case(0x28): op = ivec4(PSW,STK,NON,MOV); break; //PLP

            //ROL
            case(0x2A): op = ivec4(ACC,ACC,NON,ROL); break; 
            case(0x26): op = ivec4(MEM,MEM,ZPG,ROL); break; 
            case(0x36): op = ivec4(MEM,MEM,ZPX,ROL); break; 
            case(0x2E): op = ivec4(MEM,MEM,ABS,ROL); break; 
            case(0x3E): op = ivec4(MEM,MEM,ABX,ROL); break; 

            //ROR 
            case(0x6A): op = ivec4(ACC,ACC,NON,ROR); break; 
            case(0x66): op = ivec4(MEM,MEM,ZPG,ROR); break; 
            case(0x76): op = ivec4(MEM,MEM,ZPX,ROR); break; 
            case(0x6E): op = ivec4(MEM,MEM,ABS,ROR); break; 
            case(0x7E): op = ivec4(MEM,MEM,ABX,ROR); break; 

            //SBC
            case(0xE9): op = ivec4(ACC,MEM,IMM,SBC); break; 
            case(0xE5): op = ivec4(ACC,MEM,ZPG,SBC); break; 
            case(0xF5): op = ivec4(ACC,MEM,ZPX,SBC); break; 
            case(0xED): op = ivec4(ACC,MEM,ABS,SBC); break; 
            case(0xFD): op = ivec4(ACC,MEM,ABX,SBC); break; 
            case(0xF9): op = ivec4(ACC,MEM,ABY,SBC); break; 
            case(0xE1): op = ivec4(ACC,MEM,IDX,SBC); break; 
            case(0xF1): op = ivec4(ACC,MEM,IDY,SBC); break; 

            //STA 
            case(0x85): op = ivec4(MEM,ACC,ZPG,MOV); break; 
            case(0x95): op = ivec4(MEM,ACC,ZPX,MOV); break; 
            case(0x8D): op = ivec4(MEM,ACC,ABS,MOV); break; 
            case(0x9D): op = ivec4(MEM,ACC,ABX,MOV); break; 
            case(0x99): op = ivec4(MEM,ACC,ABY,MOV); break; 
            case(0x81): op = ivec4(MEM,ACC,IDX,MOV); break; 
            case(0x91): op = ivec4(MEM,ACC,IDY,MOV); break; 

            //STX
            case(0x86): op = ivec4(MEM,XRE,ZPG,MOV); break; 
            case(0x96): op = ivec4(MEM,XRE,ZPY,MOV); break; 
            case(0x8E): op = ivec4(MEM,XRE,ABS,MOV); break; 

            //STY 
            case(0x84): op = ivec4(MEM,YRE,ZPG,MOV); break; 
            case(0x94): op = ivec4(MEM,YRE,ZPX,MOV); break; 
            case(0x8C): op = ivec4(MEM,YRE,ABS,MOV); break; 

            //REGISTER TRANSFERS
            case(0xAA): op = ivec4(XRE,ACC,NON,MOV); break; //TAX
            case(0xA8): op = ivec4(YRE,ACC,NON,MOV); break; //TAY
            case(0xBA): op = ivec4(XRE,SPT,NON,MOV); break; //TSX
            case(0x8A): op = ivec4(ACC,XRE,NON,MOV); break; //TXA
            case(0x9A): op = ivec4(SPT,XRE,NON,MOV); break; //TXS
            case(0x98): op = ivec4(ACC,YRE,NON,MOV); break; //TYA

            //---------------------------------------------------
            
            //BRANCHES/CONTROL FLOW
            case(0x90): op = ivec4(NOR,  C,REL,BCL); break; //BCC
            case(0xB0): op = ivec4(NOR,  C,REL,BSE); break; //BCS
            case(0xF0): op = ivec4(NOR,  Z,REL,BSE); break; //BEQ
            case(0xD0): op = ivec4(NOR,  Z,REL,BCL); break; //BNE
            case(0x30): op = ivec4(NOR,  N,REL,BSE); break; //BMI
            case(0x10): op = ivec4(NOR,  N,REL,BCL); break; //BPL
            case(0x50): op = ivec4(NOR,  V,REL,BCL); break; //BVC
            case(0x70): op = ivec4(NOR,  V,REL,BSE); break; //BVS

            case(0x00): op = ivec4(NOR,  B,REL,BRK); break; //BRK

            case(0x18): op = ivec4(NOR,  C,REL,FCL); break; //CLC
            case(0xD8): op = ivec4(NOR,  D,REL,FCL); break; //CLD
            case(0x58): op = ivec4(NOR,  I,REL,FCL); break; //CLI
            case(0xB8): op = ivec4(NOR,  V,REL,FCL); break; //CLV
            case(0x38): op = ivec4(NOR,  C,REL,FSE); break; //SEC
            case(0xF8): op = ivec4(NOR,  D,REL,FSE); break; //SED
            case(0x78): op = ivec4(NOR,  I,REL,FSE); break; //SEI

            case(0x6C): op = ivec4(NOR,NOR,IND,JMP); break; //JMP
            case(0x4C): op = ivec4(NOR,NOR,ABS,JMP); break; //JMP

            case(0x20): op = ivec4(NOR,NOR,ABS,JSR); break; //JSR
            case(0x60): op = ivec4(NOR,NOR,NON,RTS); break; //RTS
            case(0x40): op = ivec4(NOR,NOR,NON,RTI); break; //RTS
            
            default: op = ivec4(NOR,NOR,NON,NOP); break; 
        }
        
        fragColor = vec4(op);
    }
    else
    {
    	fragColor = texelFetch(iChannel0,ivec2(fragCoord),0);
    }
}