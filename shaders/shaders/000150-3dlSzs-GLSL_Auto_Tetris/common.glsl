// Common (common) — GLSL Auto Tetris by morimea
// https://www.shadertoy.com/view/3dlSzs


//delete define no_AI to have AI boards, Angle comile time ~20+sec
//OpenGL compile time ~6sec
#define no_AI

//set number of launched AI bots, set 0 for max (debug use its also)
#define AI 199


// 2022 update uint map
#define use_uint_map


//define debug for debug draw
//#define debug

//debug for tetris block drop on line 479 BufA

//speed of faling blocks for player and AI, speed in frames (255 max)
#define speed 35
#define AIspeed 5


const ivec2 msize=ivec2(10,22);

//actions
// _l logic actions
// _e action to execute
#define nac 0
#define left_l 1
#define right_l 2
#define down_l 3
#define rotate_l 4
#define left_e 11
#define right_e 12
#define down_e 13
#define rotate_e 14
#define draw 100
#define afc 200
#define afc_e 201

#ifndef use_uint_map
#ifndef debug
int map[msize.x*msize.y]=int[](
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0
);
#else
//debug map to see its loaded and work correct
int map[msize.x*msize.y]=int[](
    0,0,1,0,0,0,1,0,0,0,
    0,0,1,0,0,0,1,0,0,0,
    0,0,1,0,0,0,1,0,0,0,
    1,0,1,0,0,0,1,1,1,0,
    0,1,1,0,0,0,0,0,1,0,
    0,0,1,0,0,1,1,1,1,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,
    0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,1,0,1,0,0,0,
    0,0,0,1,0,1,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,
    0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,
    0,0,0,0,0,0,0,0,0,0
);
#endif
int get_map_global(int idx){return map[idx];}
void set_map_global(int idx, int val){map[idx]=val;}

#else
// 2022 update - uint map

#ifndef debug
uint map[7]=uint[](0u,0u,0u,0u,0u,0u,0u);
#else
uint map[7]=uint[](0x22088222u, 0x8E6089E0u, 0u, 0u, 0x3FF00028u, 0x14000FFCu, 0x00FFC000u);
#endif


// index 0-3
uint getByteFromUint(uint number, uint index)
{
    return (number >> (index << 3u)) & 0xFFu;
}

// index 0-7
uint getBitFromByte(uint byte, uint index)
{
    return ((byte >> index) & 1u);
}

// idx = 0-31
uint setBitUint(uint val, int bit, int idx){
    if(bool(bit)) val |= 1u<<idx;
    else val &= ~(1u<<uint(idx));
    return val;
}

int get_map_global(int idx){
    uint val=map[idx/32];
    idx=(31-(idx%32));
    uint tv = getBitFromByte(getByteFromUint(val,uint((idx%32)/8)),uint((idx%32)%8));
    return int(tv);
}
void set_map_global(int idx, int val){
    map[idx/32]=setBitUint(map[idx/32], val, 31-(idx%32));
    return;
}

#endif


// 0xff max
ivec3 decodeval16(int varz) {
    ivec3 iret=ivec3(0);
    iret.x=varz>>16;
    iret.y=(varz>>8)&0xff;
    iret.z=(varz>>0)&0xff;
    return iret;
}

// &0xff just to make each val max 0xff
int encodeval16(ivec3 colz) {
    return int(((colz[0]&0xff)<<16)|((colz[1]&0xff)<< 8)|((colz[2]&0xff)<< 0));
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

const int bsize=4;

const int barr=19;

const ivec2 b_sizes[barr]=ivec2[](
    ivec2(4,1),
    ivec2(1,4),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(2,2),
    ivec2(3,2),
    ivec2(2,3),
    ivec2(3,2),
    ivec2(2,3)
);

//webgl GLSL does not suport arrays of arrays(can be packed as array[19] of vec4, and (0x1111>>4)&0xf)

const int block_I0[bsize*bsize]=int[](
    1,1,1,1,
	0,0,0,0,
	0,0,0,0,
	0,0,0,0
);

const int block_I1[bsize*bsize]=int[](
    1,0,0,0,
	1,0,0,0,
	1,0,0,0,
	1,0,0,0
);

const int block_T0[bsize*bsize]=int[](
    0,1,0,0,
	1,1,1,0,
	0,0,0,0,
	0,0,0,0
);

const int block_T1[bsize*bsize]=int[](
    0,1,0,0,
	1,1,0,0,
	0,1,0,0,
	0,0,0,0
);

const int block_T2[bsize*bsize]=int[](
    1,1,1,0,
	0,1,0,0,
	0,0,0,0,
	0,0,0,0
);

const int block_T3[bsize*bsize]=int[](
    1,0,0,0,
	1,1,0,0,
	1,0,0,0,
	0,0,0,0
);

const int block_L0[bsize*bsize]=int[](
    0,0,1,0,
	1,1,1,0,
	0,0,0,0,
	0,0,0,0
);

const int block_L1[bsize*bsize]=int[](
    1,0,0,0,
	1,0,0,0,
	1,1,0,0,
	0,0,0,0
);

const int block_L2[bsize*bsize]=int[](
    1,1,1,0,
	1,0,0,0,
	0,0,0,0,
	0,0,0,0
);

const int block_L3[bsize*bsize]=int[](
    1,1,0,0,
	0,1,0,0,
	0,1,0,0,
	0,0,0,0
);

const int block_Lr0[bsize*bsize]=int[](
    1,0,0,0,
	1,1,1,0,
	0,0,0,0,
	0,0,0,0
);

const int block_Lr1[bsize*bsize]=int[](
    1,1,0,0,
	1,0,0,0,
	1,0,0,0,
	0,0,0,0
);

const int block_Lr2[bsize*bsize]=int[](
    1,1,1,0,
	0,0,1,0,
	0,0,0,0,
	0,0,0,0
);

const int block_Lr3[bsize*bsize]=int[](
    0,1,0,0,
	0,1,0,0,
	1,1,0,0,
	0,0,0,0
);

const int block_O0[bsize*bsize]=int[](
    1,1,0,0,
	1,1,0,0,
	0,0,0,0,
	0,0,0,0
);

const int block_Z0[bsize*bsize]=int[](
    1,1,0,0,
	0,1,1,0,
	0,0,0,0,
	0,0,0,0
);

const int block_Z1[bsize*bsize]=int[](
    0,1,0,0,
	1,1,0,0,
	1,0,0,0,
	0,0,0,0
);

const int block_Zr0[bsize*bsize]=int[](
    0,1,1,0,
	1,1,0,0,
	0,0,0,0,
	0,0,0,0
);

const int block_Zr1[bsize*bsize]=int[](
    1,0,0,0,
	1,1,0,0,
	0,1,0,0,
	0,0,0,0
);

//https://www.shadertoy.com/view/ldsyz4
// The MIT License
// Copyright 2017 Inigo Quilez
// Digit data by P_Malin (https://www.shadertoy.com/view/4sf3RN)
const int[] font = int[](0x75557, 0x22222, 0x74717, 0x74747, 0x11574, 0x71747, 0x71757, 0x74444, 0x75757, 0x75747);
const int[] powers = int[](1, 10, 100, 1000, 10000, 100000, 1000000);

int PrintInt( in vec2 uv, in int value, const int maxDigits )
{
    if( abs(uv.y-0.5)<0.5 )
    {
        int iu = int(floor(uv.x));
        if( iu>=0 && iu<maxDigits )
        {
            int n = (value/powers[maxDigits-iu-1]) % 10;
            uv.x = fract(uv.x);//(uv.x-float(iu)); 
            ivec2 p = ivec2(floor(uv*vec2(4.0,5.0)));
            return (font[n] >> (p.x+p.y*4)) & 1;
        }
    }
    return 0;
}

//using https://iquilezles.org/articles/distfunctions2d
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}
