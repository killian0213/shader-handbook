// Common (common) — Voxel Terrain Minmax Traversal by gelami
// https://www.shadertoy.com/view/csscD4


#define SSAA 0

//#define TURNTABLE_CAM
//#define STATIC_CAM
//#define SHOW_STEPS
//#define SHOW_NORMALS

//#define SCALE 0.125
#define SCALE 0.1
//#define SCALE 0.0625

#define MIN_LOD 0
#define MAX_LOD 8

#define MAX_HEIGHT 1.0

#define STEPS 256
#define MAX_DIST 200.
#define EPS 1e-4

#define PI (acos(-1.))
#define TAU (PI*2.)


float henyeyGreenstein(float cosTheta, float g)
{
    //const float k = 1.0 / (4.0 * PI);
    float g2 = g * g;
    
    return (1.0 - g2) / pow(1.0 + g2 - 2.0 * g * cosTheta, 3.0 / 2.0);
}

// Ray-sphere intersesction
// https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
vec2 sphereIntersection(vec3 ro, vec3 rd, float ra )
{
    vec3 oc = ro;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    if (b > 0.0 && c > 0.0)
        return vec2(MAX_DIST);
    float h = b*b - c;
    if( h<0.0 ) return vec2(MAX_DIST); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

// Cubemap helper functions
// https://en.wikipedia.org/wiki/Cube_mapping#Memory_addressing

// Cubemap ID as per OpenGL indices
int cubeID(vec3 normal)
{
    return int(dot(max(-normal, vec3(0)), vec3(1)) + dot(abs(normal), vec3(0, 2, 4)));
}

vec2 cubeNearest(vec2 uv, float res)
{
    return (floor(uv * res) + 0.5) / res;
}

// OpenGL face orientation from
// https://www.khronos.org/opengl/wiki/Cubemap_Texture
vec2 cubePosToUV(vec3 pos, vec3 normal)
{
    pos = pos + 0.5;

    vec3 mask = abs(normal);
    vec2 uv = mask.x > 0. ? vec2(-pos.z * normal.x, -pos.y) :
              mask.y > 0. ? vec2( pos.x,  pos.z * normal.y) :
                            vec2( pos.x * normal.z, -pos.y);
    
    uv = fract(uv);
   
    return uv;
}

vec2 cubePosToUV(vec3 pos, int id)
{   
    pos = pos + 0.5;

    vec2 uv;
    switch(id)
    {
        case 0:
            uv = vec2(-pos.z, -pos.y); break;
        case 1:
            uv = vec2( pos.z, -pos.y); break;
        case 2:
            uv = vec2( pos.x,  pos.z); break;
        case 3:
            uv = vec2( pos.x, -pos.z); break;
        case 4:
            uv = vec2( pos.x, -pos.y); break;
        case 5:
            uv = vec2(-pos.x, -pos.y); break;
    }
    
    uv = fract(uv);

    return uv;
}

// Based on Shane's cubemap texture function
// Geometric Cellular Surfaces - Shane
// https://www.shadertoy.com/view/Wt33zH

// Modified to match OpenGL face orientation
// https://www.khronos.org/opengl/wiki/Cubemap_Texture
vec3 cubeUVToPos(vec2 uv, int id)
{
    uv = fract(uv) - .5;
    
    
    switch(id)
    {
        case 0:
            return vec3(0.5, -uv.yx);
        case 1:
            return vec3(-0.5, -uv.y, uv.x);
        case 2:
            return vec3(uv.x, 0.5, uv.y);
        case 3:
            return vec3(uv.x, -0.5, -uv.y);
        case 4:
            return vec3(uv.x, -uv.y, 0.5);
        case 5:
            return vec3(-uv, -0.5);
    }
    
    return vec3(0);
}

vec3 cubeIntersect(vec3 rayDir, out vec3 normal)
{
    vec3 sideDist = abs(0.5 / rayDir);
    
    float t = min(sideDist.x, min(sideDist.y, sideDist.z));
    vec3 mask = step(sideDist, sideDist.yzx) * step(sideDist, sideDist.zxy);
    
    normal = mask * sign(rayDir);
    
    return rayDir * t;
}

const int[] LOD_TEX_START = int[](0, 512, 768, 896, 960, 992, 1008, 1016, 1020, 1022);
const int[] LOD_TEX_END = int[](512, 768, 896, 960, 992, 1008, 1016, 1020, 1022, 1023);

int getLodSize(int lod)
{
    return 1024>>lod;
}

vec4 SampleCubemapLod(samplerCube tex, vec2 uv, vec2 res, int lod)
{
    if (lod <= 0)
    {
        return texture(tex, cubeUVToPos(uv, 0));
    }
    
    vec2 size = vec2(getLodSize(lod));
    vec2 offset = vec2(LOD_TEX_START[lod-1], 0);
    
    return texture(tex, cubeUVToPos((uv * size + offset) / res, 1));
}

vec4 SampleCubemapLodNearest(samplerCube tex, vec2 uv, vec2 res, int lod)
{
    if (lod <= 0)
    {
        uv = (floor(uv * res) + 0.5) / res;
        return texture(tex, cubeUVToPos(uv, 0));
    }
    
    vec2 size = vec2(getLodSize(lod));
    vec2 offset = vec2(LOD_TEX_START[lod-1], 0);
    
    uv = floor(uv * size) + 0.5;
    return texture(tex, cubeUVToPos((uv + offset) / res, 1));
}

mat3 getCameraMatrix(vec3 ro, vec3 lo)
{
    vec3 cw = normalize(lo - ro);
    vec3 cu = normalize(cross(cw, vec3(0, 1, 0)));
    vec3 cv = cross(cu, cw);

    return mat3(cu, cv, cw);
}

float safeacos(float x) { return acos(clamp(x, -1.0, 1.0)); }

float saturate(float x) { return clamp(x, 0., 1.); }
vec2 saturate(vec2 x) { return clamp(x, vec2(0), vec2(1)); }
vec3 saturate(vec3 x) { return clamp(x, vec3(0), vec3(1)); }

float sqr(float x) { return x*x; }
vec2 sqr(vec2 x) { return x*x; }
vec3 sqr(vec3 x) { return x*x; }

float luminance(vec3 col) { return dot(col, vec3(0.2126729, 0.7151522, 0.0721750)); }

mat2 rot2D(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

// https://iquilezles.org/articles/smin/
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
    
float smax( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }


// https://iquilezles.org/articles/palettes/
vec3 palette(float t)
{
    return .5 + .5 * cos(TAU * (vec3(1, 1, 1) * t + vec3(0, .33, .67)));
}

// matplotlib colormaps + turbo - mattz
// https://www.shadertoy.com/view/3lBXR3
vec3 turbo(float t) {

    const vec3 c0 = vec3(0.1140890109226559, 0.06288340699912215, 0.2248337216805064);
    const vec3 c1 = vec3(6.716419496985708, 3.182286745507602, 7.571581586103393);
    const vec3 c2 = vec3(-66.09402360453038, -4.9279827041226, -10.09439367561635);
    const vec3 c3 = vec3(228.7660791526501, 25.04986699771073, -91.54105330182436);
    const vec3 c4 = vec3(-334.8351565777451, -69.31749712757485, 288.5858850615712);
    const vec3 c5 = vec3(218.7637218434795, 67.52150567819112, -305.2045772184957);
    const vec3 c6 = vec3(-52.88903478218835, -21.54527364654712, 110.5174647748972);

    return c0+t*(c1+t*(c2+t*(c3+t*(c4+t*(c5+t*c6)))));

}

// Hash without Sine
// https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 hash23(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec3 sRGBToLinear(vec3 col)
{
    return mix(pow((col + 0.055) / 1.055, vec3(2.4)), col / 12.92, lessThan(col, vec3(0.04045)));
}

vec3 linearTosRGB(vec3 col)
{
    return mix(1.055 * pow(col, vec3(1.0 / 2.4)) - 0.055, col * 12.92, lessThan(col, vec3(0.0031308)));
}

// ACES tone mapping curve fit to go from HDR to LDR
//https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
vec3 ACESFilm(vec3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return clamp((x*(a*x + b)) / (x*(c*x + d) + e), 0.0f, 1.0f);
}

vec3 ReinhardExtLuma(vec3 col, const float w)
{
    float l = luminance(col);
    float n = l * (1.0 + l / (w * w));
    float ln = n / (1.0 + l);
    return col * ln / l;
}
