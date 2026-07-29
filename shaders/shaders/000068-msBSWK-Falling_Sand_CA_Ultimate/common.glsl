// Common (common) — Falling Sand CA Ultimate by gelami
// https://www.shadertoy.com/view/msBSWK


#define SCALE 2.0

#define MOUSE_RADIUS 3.0
#define MOUSE_STRENGTH 0.5

#define IMPROVED_OFFSET

//#define RAINBOW_MODE

#define ZOOM_POINT vec2(RES * 0.5 / SCALE)

#define AIR 0.0
#define SMOKE 1.0
#define FIRE 2.0
#define LAVA 3.0
#define WATER 4.0
#define SAND 5.0
#define STONE 6.0
#define WOOD 7.0
#define PLANT 8.0
#define WALL 9.0

#define EPSILON 1e-4

#define RES iResolution.xy
#define IRES ivec2(iResolution.xy)

#define sampleTex0(p) texelFetch(iChannel0, ivec2(p) % IRES, 0)
#define sampleTex1(p) texelFetch(iChannel1, ivec2(p), 0)

#define PI (acos(-1.0))
#define TAU (2.0 * PI)

const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;

const int KEY_0 = 48;

const int KEY_PLUS = 187;
const int KEY_MINUS = 189;

const int KEY_BRACKET_LEFT = 219;
const int KEY_BRACKET_RIGHT = 221;

const int KEY_SPACE = 32;
const int KEY_R = 82;

// 1D LOD Gaussian blur from Fabrice
// https://www.shadertoy.com/view/WtKfD3
vec4 gaussian1D(sampler2D tx, vec2 U, vec2 D, vec2 R)
{
    const int N = 32;
    const float w = 0.1;
    
    float z = ceil(max(0., log2(w*R.y/float(N))));
    
    vec4  O = vec4(0);                                                      
    float r = float(N-1)/2., g, t=0., x;                                    
    for( int k=0; k<N; k++ ) {                                              
        x = float(k)/r-1.;                                                  
        t += g = exp(-8.0*x*x );                                            
        O += g * texture(tx, (U+w*x*D) *R.y/R, z );     
    }                                                                       
    return O/t;                                                             
}

// https://iquilezles.org/articles/distfunctions2d/
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}


float saturate(float x) { return clamp(x, 0., 1.); }

vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(0)); }

vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }

// RNG
uint state;
void initState(vec2 coord, int frame)
{
    state = uint(coord.x) * 1321u + uint(coord.y) * 4123u + uint(frame) * 4123u*4123u;
}

// From Chris Wellons Hash Prospector
// https://nullprogram.com/blog/2018/07/31/
// https://www.shadertoy.com/view/WttXWX
uint hashi(inout uint x)
{
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

// Modified to work with 4 values at once
uvec4 hash4i(inout uint y)
{
    uvec4 x = y * uvec4(213u, 2131u, 21313u, 213132u);
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    y = x.x;
    return x;
}

float hash(inout uint x)
{
    return float( hashi(x) ) / float( 0xffffffffU );
}

vec2 hash2(inout uint x)
{
    return vec2(hash(x), hash(x));
}

vec3 hash3(inout uint x)
{
    return vec3(hash(x), hash(x), hash(x));
}

vec4 hash4(inout uint x)
{
    return vec4( hash4i(x) ) / float( 0xffffffffU );
    //return vec4(hash(x), hash(x), hash(x), hash(x));
}

vec4 hash42(uvec2 p)
{
    uint x = p.x*2131u + p.y*2131u*2131u;
    return vec4( hash4i(x) ) / float( 0xffffffffU );
    //return vec4(hash(x), hash(x), hash(x), hash(x));
}

vec4 hash43(uvec3 p)
{
    uint x = p.x*461u + p.y*2131u + p.z*2131u*2131u;
    return vec4( hash4i(x) ) / float( 0xffffffffU );
    //return vec4(hash(x), hash(x), hash(x), hash(x));
}

void swap(inout vec4 a, inout vec4 b)
{
    vec4 tmp = a;
    a = b;
    b = tmp;
}

vec4 sampleCells(sampler2D ch, ivec2 p, ivec2 res)
{
    if (p.x == 0 && p.y == 0)
        return vec4(WALL, 0, 0, 0);
        
    if (p.x < 0 || p.x >= res.x || p.y < 0 || p.y >= res.y)
        return vec4(WALL, 0, 0, 0);
    
    if (p.x >= res.x-1 || p.y >= res.y-1)
        return vec4(WALL, 0, 0, 0);
    
    p = clamp(p, ivec2(0), res-1);  
    
    vec4 tex = texelFetch(ch, ivec2(p), 0);
    
    return tex;
}

ivec2 getMargolusOffset(int frame)
{
#ifndef IMPROVED_OFFSET
    frame = frame % 2;
    if (frame == 1)
        return ivec2(1, 1);
    return ivec2(0, 0);
#else
    frame = frame % 4;

    if (frame == 1)
        return ivec2(1, 1);
    else if (frame == 2)
       return ivec2(0, 1);
    else if (frame == 3)
        return ivec2(1, 0);
    return ivec2(0, 0);
#endif
}

int cellToID(vec4 p)
{
    return int(dot(p, vec4(1, 2, 4, 8)));
}

vec4 IDToCell(int id)
{
    return vec4(id%2, (id/2)%2, (id/4)%2, (id/8)%2);
}

float getOpacity(float id)
{
    if (id == SMOKE)
        return 0.2;
    else if (id == FIRE)
        return 0.8;
    else if (id == LAVA)
        return 0.9;
    else if (id == WATER)
        return 0.4;
    else if (id >= SAND)
        return 1.0;
    return 0.0;
}

vec4 simulate(sampler2D ch, ivec2 p, ivec2 res, int frame, int bof)
{
    ivec2 of = getMargolusOffset(frame + bof);
        
    p += of;
    
    ivec2 fp = (p / 2) * 2;
    ivec2 fr = p & 1;
    int x = fr.x + (fr.y) * 2;
    
    fp -= of;
    p -= of;
    
    vec4 t00 = sampleCells(ch, fp + ivec2(0, 0), res);
    vec4 t10 = sampleCells(ch, fp + ivec2(1, 0), res);
    vec4 t01 = sampleCells(ch, fp + ivec2(0, 1), res);
    vec4 t11 = sampleCells(ch, fp + ivec2(1, 1), res);
    
    if (t00.x == AIR && t10.x == AIR &&
        t01.x == AIR && t11.x == AIR)
        return vec4(0);
    
    vec4 tn00 = sampleCells(ch, fp + ivec2(0, -1), res);
    vec4 tn10 = sampleCells(ch, fp + ivec2(1, -1), res);
    
    ivec2 o = ivec2(fr.x, fr.y);
    
    vec4 v = hash43(uvec3(fp, frame));
    vec4 v2 = hash43(uvec3(fp, frame/8));
    
    if (v.x < 0.5)
    {
        swap(t00, t10);
        swap(t01, t11);
    }
    
    // Sand
    if ((t01.x == SAND && t11.x < SAND ||
        t01.x < SAND && t11.x == SAND) &&
        t00.x < SAND && t10.x < SAND && v.y < 0.4)
    {
        swap(t01, t11);
    }
    if (t01.x == SAND)
    {
        if (t00.x < SAND)
        {
            if (v.z < 0.9) swap(t01, t00);
        } else if (t11.x < SAND && t10.x < SAND)
        {
            swap(t01, t10);
        }
    }
    if (t11.x == SAND)
    {
        if (t10.x < SAND)
        {
            if (v.z < 0.9) swap(t11, t10);
        } else if (t00.x < SAND && t01.x < SAND)
        {
            swap(t11, t00);
        }
    }
    
    // Stone
    if ((t01.x == STONE && t11.x < SAND ||
        t01.x < SAND && t11.x == STONE) &&
        t00.x < SAND && t10.x < SAND && v.y < 0.05)
    {
        swap(t01, t11);
    }
    if (t01.x == STONE && v.z < 0.8)
    {
        if (t00.x < SAND)
        {
            swap(t01, t00);
        } else if (t11.x < SAND && t10.x < SAND)
        {
            swap(t01, t10);
        }
    }
    if (t11.x == STONE && v.z < 0.8)
    {
        if (t10.x < SAND)
        {
            swap(t11, t10);
        } else if (t00.x < SAND && t01.x < SAND)
        {
            swap(t11, t00);
        }
    }
    
    // Water
    if ((t00.x == WATER || t10.x == WATER ||
         t01.x == WATER || t11.x == WATER))
    {
        if (t00.x == FIRE)
        {
            t00.x = SMOKE;
        }
        if (t10.x == FIRE)
        {
            t10.x = SMOKE;
        }
        if (t01.x == FIRE)
        {
            t01.x = SMOKE;
        }
        if (t11.x == FIRE)
        {
            t11.x == SMOKE;
        }
    }
    
    bool a = false;
    if (t01.x == WATER)
    {
        if (t00.x < WATER && v.z < 0.95)
        {
            //if (v.z < 0.9)
                swap(t01, t00);
                a = true;
        } 
        else if (t11.x < WATER && t10.x < WATER && v.x < 0.2)
        {
            swap(t01, t10);
            a = true;
        }
    }
    if (t11.x == WATER)
    {
        if (t10.x < WATER && v.z < 0.95)
        {
            //if (v.z < 0.9)
                swap(t11, t10);
                a = true;
                
        } else if (t01.x < WATER && t00.x < WATER && v.x < 0.2)
        {
            swap(t11, t00);
            a = true;
        }
    }
    //if (t00.x >= WATER && t10.x >= WATER)
    //if (v.w < 1.0)
    if (!a)
    {
        if ((t01.x == WATER && t11.x < WATER ||
            t01.x < WATER && t11.x == WATER) &&
            (t00.x >= WATER && t10.x >= WATER || v.w < 0.8))
        {
            swap(t01, t11);
        }
        if ((t00.x == WATER && t10.x < WATER ||
            t00.x < WATER && t10.x == WATER) &&
            (tn00.x >= WATER && tn10.x >= WATER || v.w < 0.8))
        {
            swap(t00, t10);
        }
    }
    
    
    // Lava
    if ((t00.x == LAVA && t10.x < LAVA ||
        t00.x < LAVA && t10.x == LAVA) && v.y < 0.2)
    {
        swap(t00, t10);
    }
    if (t01.x == LAVA)
    {
        if (t00.x == WATER)
        {
            t01.x = STONE;
            t00.x = SMOKE;
        }
        if (t11.x == WATER)
        {
            t01.x = STONE;
            t11.x = SMOKE;
        }
        if (t00.x < LAVA)
        {
            if (v.z < 0.5) swap(t01, t00);
        } 
        else if (t11.x < LAVA && t10.x < LAVA)
        {
            swap(t01, t10);
        }
    }
    if (t11.x == LAVA)
    {
        if (t01.x == WATER)
        {
            t11.x = STONE;
            t01.x = SMOKE;
        }
        if (t10.x == WATER)
        {
            t11.x = STONE;
            t10.x = SMOKE;
        }
        if (t10.x < LAVA)
        {
            if (v.z < 0.5) swap(t11, t10);
        }
        else if (t01.x < LAVA && t00.x < LAVA)
        {
            swap(t11, t00);
        }
    }
    
    
    // Smoke
    if (t00.x == SMOKE && t01.x > SMOKE && v.w < 0.02)
    {
        t00.x = AIR;
    }
    
    if ((t00.x == SMOKE && t10.x < SMOKE ||
        t00.x < SMOKE && t10.x == SMOKE) && v.y < 0.1)
    {
        swap(t00, t10);
    }
    if ((t01.x == SMOKE && t11.x < SMOKE ||
        t01.x < SMOKE && t11.x == SMOKE) && v.y < 0.1)
    {
        swap(t01, t11);
    }
    if (t00.x == SMOKE)
    {
        if (t01.x < SMOKE)
        {
            if (v.z < 0.2)
                swap(t00, t01);
        } else if (t10.x < SMOKE)
        {
            swap(t00, t10);
        }
    }
    if (t10.x == SMOKE)
    {
        if (t11.x < SMOKE)
        {
            if (v.z < 0.2)
                swap(t10, t11);
        } else if (t00.x < SMOKE)
        {
            swap(t10, t00);
        }
    }
    
    
    // Fire
    if ((t00.x == FIRE || t10.x == FIRE ||
         t01.x == FIRE || t11.x == FIRE ||
         t00.x == LAVA || t10.x == LAVA ||
         t01.x == LAVA || t11.x == LAVA) && v.x < 0.03)
    {
        if (t00.x == WOOD || t00.x == PLANT)
        {
            t00.x = FIRE;
        }
        if (t10.x == WOOD || t00.x == PLANT)
        {
            t10.x = FIRE;
        }
        if (t01.x == WOOD || t00.x == PLANT)
        {
            t01.x = FIRE;
        }
        if (t11.x == WOOD || t00.x == PLANT)
        {
            t11.x == FIRE;
        }
    }
    
    if ((t01.x == FIRE && t11.x < FIRE ||
        t01.x < FIRE && t11.x == FIRE) && v.y < 0.05)
    {
        swap(t01, t11);
    }
    if (t00.x == FIRE)
    {
        if (t01.x == AIR && v.w < 0.005)
        {
            t01.x = SMOKE;
        }
        
        if (v.x < 0.002)
        {
            t00.x = SMOKE;
        } else if (v.z < 0.05)
        {
            if (t01.x < FIRE)
            {
                    swap(t00, t01);
            } else if (t10.x < FIRE)
            {
                swap(t00, t10);
            }
        }
    }
    if (t10.x == FIRE)
    {
        if (v.x < 0.002)
        {
            t10.x = SMOKE;
        }
        else if (v.z < 0.05)
        {
            if (t11.x < FIRE)
            {
                swap(t10, t11);
            } else if (t00.x < FIRE)
            {
                swap(t10, t00);
            }
         }
    }
    
    // Plant
    if (t00.x == PLANT && t01.x == WATER && t10.x != PLANT &&
       (tn00.x == SAND || tn00.x == PLANT) && v.w < 0.01)
    {
        t01.x = PLANT;
    }
    if (t01.x == PLANT)
    {
        if (t00.x < SAND)
        {
            swap(t01, t00);
        }
    }
    
    
    if (v.x < 0.5)
    {
        swap(t00, t10);
        swap(t01, t11);
    }
    
    switch (x)
    {
        case 0:
            return t00;
        case 1:
            return t10;
        case 2:
            return t01;
        case 3:
            return t11;
    }
    
    return vec4(0);
}

// https://www.chilliant.com/rgb2hsv.html
vec3 RGBtoHCV(in vec3 RGB)
{
    // Based on work by Sam Hocevar and Emil Persson
    vec4 P = (RGB.g < RGB.b) ? vec4(RGB.bg, -1.0, 2.0/3.0) : vec4(RGB.gb, 0.0, -1.0/3.0);
    vec4 Q = (RGB.r < P.x) ? vec4(P.xyw, RGB.r) : vec4(RGB.r, P.yzx);
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6.0 * C + EPSILON) + Q.z);
    return vec3(H, C, Q.x);
}
  
vec3 RGBtoHSV(in vec3 RGB)
{
    vec3 HCV = RGBtoHCV(RGB);
    float S = HCV.y / (HCV.z + EPSILON);
    return vec3(HCV.x, S, HCV.z);
}

vec3 RGBtoHSL(in vec3 RGB)
{
    vec3 HCV = RGBtoHCV(RGB);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1.0 - abs(L * 2.0 - 1.0) + EPSILON);
    return vec3(HCV.x, S, L);
}


vec3 HUEtoRGB(in float H)
{
    float R = abs(H * 6.0 - 3.0) - 1.0;
    float G = 2.0 - abs(H * 6.0 - 2.0);
    float B = 2.0 - abs(H * 6.0 - 4.0);
    return saturate(vec3(R,G,B));
}

vec3 HSVtoRGB(in vec3 HSV)
{
    vec3 RGB = HUEtoRGB(HSV.x);
    return ((RGB - 1.0) * HSV.y + 1.0) * HSV.z;
}

vec3 HSLtoRGB(in vec3 HSL)
{
    vec3 RGB = HUEtoRGB(HSL.x);
    float C = (1.0 - abs(2.0 * HSL.z - 1.0)) * HSL.y;
    return (RGB - 0.5) * C + HSL.z;
}
