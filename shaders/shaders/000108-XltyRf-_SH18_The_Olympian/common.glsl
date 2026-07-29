// Common (common) — [SH18] The Olympian by Klems
// https://www.shadertoy.com/view/XltyRf

#define PI 3.14159265359
#define s(a, b, x) smoothstep(a, b, x)
#define rot(a) mat2(cos(a + PI*0.5*vec4(0,1,3,0)))
#define Z min(0, iFrame)

// simpler, easier version to compile of the dude
// #define SIMPLE_HUMAN

// hash functions by Dave_Hoskins
#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)
#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)

float hash11( in float p ) {
	vec3 p3 = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash12( in vec2 p ) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float hash13( in vec3 p3 ) {
	p3  = fract(p3 * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash21( in float p ) {
	vec3 p3 = fract(vec3(p) * HASHSCALE3);
	p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 hash22( vec2 p ) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec2 hash23( in vec3 p3 ) {
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);
}

vec3 hash31( in float p ) {
   vec3 p3 = fract(vec3(p) * HASHSCALE3);
   p3 += dot(p3, p3.yzx+19.19);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

vec3 hash32( in vec2 p ) {
	vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 hash33( in vec3 p3 ) {
	p3 = fract(p3 * HASHSCALE3);
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

vec4 hash41( in float p ) {
	vec4 p4 = fract(vec4(p) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

vec4 hash42( in vec2 p ) {
	vec4 p4 = fract(vec4(p.xyxy) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

vec4 hash43( in vec3 p ) {
	vec4 p4 = fract(vec4(p.xyzx)  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

vec4 hash44( in vec4 p4 ) {
	p4 = fract(p4  * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

// 1D perlin, between -1 and 1
float perlin( in float x, in float seed ) {
    x += hash11(seed);
    float a = floor(x);
    float b = a + 1.0;
    float f = fract(x);
    a = hash12(vec2(seed, a));
    b = hash12(vec2(seed, b));
    f = f*f*(3.0-2.0*f);
    return mix(a, b, f)*2.0-1.0;
}

// return sequence id and time in this sequence
void getSequence( in float time, out int seqID, out float seqTime ) {
    
    seqID = 0;
    seqTime = time;
    
    if (time < 34.0) {
        seqID = 0;
        seqTime = time;
    } else if (time < 64.0) {
        seqID = 1;
        seqTime = time-34.0;
    } else if (time < 74.0) {
        seqID = 2;
        seqTime = time-64.0;
    } else if (time < 94.0) {
        seqID = 3;
        seqTime = time-74.0;
    } else if (time < 104.0) {
        seqID = 4;
        seqTime = time-94.0;
    } else if (time < 144.0) {
        seqID = 5;
        seqTime = time-104.0;
    } else {
        seqID = 6;
        seqTime = time-144.0;
    }

}

// return vertical fov
float getFOV( in int seqID, in float seqTime ) {
    
    if (seqID == 2) {
        // slightly higher fov in the closeup
        return 1.5;
    } else if(seqID == 4) {
        // zoom in on the dude passing by a planet
        return 1.0 - s(5.0, 9.0, seqTime)*0.98;
    }
    
    return 1.0;
}

// camera direction and position
void getCamera(in vec2 uv, in int seqID, in float seqTime,
               out vec3 dir, out vec3 from ) {
    
    // look at and up vector
    vec3 up = vec3(0, 1, 0);
    vec3 lookAt = vec3(0);
    from = vec3(0, 0, -1);
    
    if (seqID == 0) {
        // rotate around our dude
        up = normalize(vec3(1, 10, 2));
        lookAt = vec3(0);
        float rota = seqTime*0.1;
        from = vec3(cos(rota), 0, sin(rota))*5.0;
        // send our dude flying
        from.z -= s(31.7, 37.0, seqTime)*200.0;
        from.z -= s(30.5, 34.0, seqTime)*5.0;
        // makes the camera a bit more interesting
        lookAt.x += perlin(seqTime*0.3, 0.0)*0.3;
        lookAt.y += perlin(seqTime*0.3, 1.0)*0.3;
        lookAt.z += perlin(seqTime*0.3, 2.0)*0.3;
    } else if (seqID == 1) {
        // rotate around our dude
        up = normalize(vec3(2, 12, 3));
        lookAt = vec3(0);
        float rota = seqTime*0.2 + 3.5;
        from = vec3(cos(rota), 0.2, sin(rota))*4.0;
    } else if (seqID == 2) {
        // closeup on the dude
        up = vec3(0, 1, 0);
        lookAt = vec3(0, 0.7, 0);
        // add a bit of shaking
        lookAt.x += perlin(seqTime*5.0, 0.0)*0.1;
        lookAt.y += perlin(seqTime*5.0, 1.0)*0.1;
        // zoom in on his face
        from = vec3(0, 0.8, 4.0 - seqTime*0.13);
    } else if (seqID == 3) {
        // zigzag around planets
        up = normalize(vec3(2, 12, 3));
        float devia = sin(seqTime*0.5);
        float sqDevia = devia*devia;
        sqDevia *= sqDevia;
        lookAt = vec3(0, 0.5, 1);
        lookAt.x += perlin(seqTime*10.0, 0.0)*0.1*sqDevia;
        lookAt.y += perlin(seqTime*10.0, 1.0)*0.1*sqDevia;
        lookAt.z += perlin(seqTime*10.0, 2.0)*0.1*sqDevia;
        from = vec3(devia*6.0, 2, -6);
    } else if (seqID == 4) {
        // starts near a planet, look at the dude passing by
        up = normalize(vec3(4, 12, -3));
        lookAt = vec3(0);
        float move = (seqTime - 5.0)*50.0;
        from = vec3(-20, 0, 0);
        from.z -= move;
    } else if (seqID == 5) {
        
        // look at the dude flying and braking
        up = normalize(vec3(1, 12, -2));
        // look in front of the dude
        lookAt = s(1.0, 4.0, seqTime)*vec3(0, 0.5, 3);
        
        // look toward the sun
        float rota = 0.8;
        // then look toward the earth
        rota += s(9.0, 13.0, seqTime)*1.7;
        vec2 off = vec2(cos(rota), sin(rota))*7.0;
        from = lookAt + vec3(-off.x, 0, -off.y);
        // at the beginning, look at the dude in the distance
        from.z += s(4.0, -4.0, seqTime)*150.0;
        
        // makes the camera a bit more interesting
        lookAt.x += perlin(seqTime*0.3, 0.0)*0.3;
        lookAt.y += perlin(seqTime*0.3, 1.0)*0.3;
        lookAt.z += perlin(seqTime*0.3, 2.0)*0.3;
        
        // zoom on the planet
        float f1 = s(21.0, 28.0, seqTime);
        const vec3 planet = vec3(-2.5, 0, 3);
        from = mix(from, vec3(-3, 0, 5), f1);
        lookAt = mix(lookAt, from+planet, f1);

    } else if (seqID == 6) {
        // dude passing by
        up = normalize(vec3(2, 12, 3));
        lookAt = vec3(0, 0, 1);
        from = vec3(-4, -1, 15);
        from.z -= s(-1.0, 20.0, seqTime)*100.0;
    }
    
    vec3 forward = normalize(lookAt - from);
    vec3 right = normalize(cross(forward, up));
    vec3 upward = cross(right, forward);
    float fov = getFOV(seqID, seqTime);
    float dist = 0.5 / tan(fov*0.5);
    
    dir = normalize(forward*dist + right*uv.x + upward*uv.y);
    
}

