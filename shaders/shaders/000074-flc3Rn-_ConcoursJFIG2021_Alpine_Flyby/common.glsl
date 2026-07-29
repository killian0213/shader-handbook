// Common (common) — [ConcoursJFIG2021] Alpine Flyby by loicvdb
// https://www.shadertoy.com/view/flc3Rn

// Uncomment for keyboard control
// wasd/zqsd + crtl + maj to move arround
//#define FLY_MODE_QWERTY
//#define FLY_MODE_AZERTY


uniform sampler2D iChannel0Fake;

vec3 getVec3(int add) {
    return vec3(
        texelFetch(iChannel0Fake, ivec2(add, 0), 0).w,
        texelFetch(iChannel0Fake, ivec2(add, 1), 0).w,
        texelFetch(iChannel0Fake, ivec2(add, 3), 0).w
    );
}


void setVec3(vec3 v, int add, inout vec4 o) {
    ivec2 u = ivec2(gl_FragCoord.xy);
    if(u == ivec2(add, 0)) o.w = v.x;
    if(u == ivec2(add, 1)) o.w = v.y;
    if(u == ivec2(add, 3)) o.w = v.z;
}


void setMat3(mat3 m, int add, inout vec4 o) {
    for(int i = 0; i < 4; i++) {
        setVec3(m[i], add+i, o);
    }
}


mat3 getMat3(int address) {
    return mat3(getVec3(address), getVec3(address+1), getVec3(address+2));
}


int hash(int i) {
    // 2024-03-03 : fixed integer rollback by switching hashing to uint
    uint j = uint(i);
	j *= 0xB5297A4Du;
	j ^= j >> 8;
	j += 0x68E31DA4u;
	j ^= j << 8;
	j *= 0x1B56C4E9u;
	j ^= j >> 8;
	return int(j & 0x7FFFFFFFu);
}


float fhash(int i) {
	return float(hash(i))/2147483648.;
}


float fhash2(ivec2 i) {
    return fhash(i.x - 0x8CB * i.y);
}


#define INIT_NOISE Seed = hash(int(floor(gl_FragCoord.x)+floor(gl_FragCoord.y)*12345.)) ^ hash(iFrame)


int Seed;


float random() {
    return fhash(Seed++);
}


float smoothnoise(vec2 x) {
    ivec2 ix = ivec2(floor(x));
    vec2 f = smoothstep(0., 1., fract(x));
    return mix(
        mix(fhash2(ix+ivec2(0,0)), fhash2(ix+ivec2(1,0)), f.x),
        mix(fhash2(ix+ivec2(0,1)), fhash2(ix+ivec2(1,1)), f.x),
        f.y
    )-.5;
}


float fbm(vec2 x) {
    const float weight = .5;
    const float scale = 2.;
    const int iterations = 6;
    float o = 0., a = 1.;
    for(int i = 0; i < iterations; i++) {
        o += smoothnoise(x) * a;
        a *= weight;
        x *= scale;
    }
    return o;
}

#ifdef FLY_MODE_AZERTY
#define FLY_MODE
#endif

#ifdef FLY_MODE_QWERTY
#define FLY_MODE
#endif

const float FocalLength = 1.5;