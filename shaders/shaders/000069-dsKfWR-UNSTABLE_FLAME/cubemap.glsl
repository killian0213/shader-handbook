// Cube A (cubemap) — UNSTABLE FLAME by alro
// https://www.shadertoy.com/view/dsKfWR

/*
    Update a density field with curl noise.
*/

// Using gyroid noise FBM by default
const bool gradientNoise = false;

//-------------------------------- Rotations --------------------------------

vec3 rotate(vec3 p, vec4 q){
  return 2.0 * cross(q.xyz, p * q.w + cross(q.xyz, p)) + p;
}
vec3 rotateX(vec3 p, float angle){
    return rotate(p, vec4(sin(angle/2.0), 0.0, 0.0, cos(angle/2.0)));
}
vec3 rotateY(vec3 p, float angle){
	return rotate(p, vec4(0.0, sin(angle/2.0), 0.0, cos(angle/2.0)));
}
vec3 rotateZ(vec3 p, float angle){
	return rotate(p, vec4(0.0, 0.0, sin(angle/2.0), cos(angle/2.0)));
}

//---------------------------- Distance functions ----------------------------

// https://iquilezles.org/articles/distfunctions
float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

//------------------------- Geometry -------------------------

float getSDF(vec3 p){
    p -= vec3(0.5, 0.25, 0.5);
   
    float dist = 1e5;
    vec3 q = p;
    
    dist = sphereSDF(q, 0.25);
/*
    q = p;
    q = rotateY(q, 3.0*iTime);
    q.z = abs(q.z);
    q.z -= 0.33;
    q.y += 0.05*cos(5.0*iTime);
    dist = min(dist, sphereSDF(q, 0.075));
    
    q = p;
    q = rotateY(q, -3.0*iTime);

    q.z = abs(q.z);
    q.z -= 0.3;
    q.y += 0.05*sin(5.0*iTime);
    dist = min(dist, sphereSDF(q, 0.075));
*/
   
    return dist;
}

//---------------------------- Noise ----------------------------

// 5th order polynomial interpolation
vec3 fade(vec3 t){
    return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0);
}

// https://www.shadertoy.com/view/4djSRW
vec3 hash(vec3 p3){
    p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return 2.0 * fract((p3.xxy + p3.yxx) * p3.zyx) - 1.0;
}

float noise(vec3 p){
    vec3 i = floor(p);
    vec3 f = fract(p);
	
	vec3 u = fade(f);

    return mix( mix( mix( dot( hash(i + vec3(0.0,0.0,0.0)), f - vec3(0.0,0.0,0.0)), 
              dot( hash(i + vec3(1.0,0.0,0.0)), f - vec3(1.0,0.0,0.0)), u.x),
         mix( dot( hash(i + vec3(0.0,1.0,0.0)), f - vec3(0.0,1.0,0.0)), 
              dot( hash(i + vec3(1.0,1.0,0.0)), f - vec3(1.0,1.0,0.0)), u.x), u.y),
    mix( mix( dot( hash(i + vec3(0.0,0.0,1.0)), f - vec3(0.0,0.0,1.0)), 
              dot( hash(i + vec3(1.0,0.0,1.0)), f - vec3(1.0,0.0,1.0)), u.x),
         mix( dot( hash(i + vec3(0.0,1.0,1.0)), f - vec3(0.0,1.0,1.0)), 
              dot( hash(i + vec3(1.0,1.0,1.0)), f - vec3(1.0,1.0,1.0)), u.x), u.y), u.z );
}

//---------------------------- Gyroid ----------------------------

// https://en.wikipedia.org/wiki/Gyroid
// https://www.shadertoy.com/view/wddfDM
float gyroid(vec3 p, float thickness, float bias, float frequency){
    // Multpliers break repetition in the gyroid.
    return clamp((dot(sin(p*0.5), cos(p.zxy*1.23) * frequency) - bias) - thickness, -3.0, 3.0)/6.0;
}

const float fbmScale = 1.93;
const int octaves = 4;

float fbm(vec3 p){

    if(gradientNoise){
        return noise(p);
    }

    // Rotation of the gyroid every iteration to produce a noise look
    const float a = PI / float(octaves);
    const mat3 m3 = fbmScale * mat3(cos(a), sin(a), 0, -sin(a), cos(a), 0, 0, 0, 1);

    float weight = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float res = 0.0;
    
    for(int i = min(0, iFrame); i < octaves; i++){
        res += amplitude * gyroid(p, 0.0, 0.0, frequency);
        p *= m3;
        weight += amplitude;
        frequency *= 0.5;
    }
    
    return res;
}

//---------------------------- Curl ----------------------------

// https://atyuwen.github.io/posts/bitangent-noise/
vec3 getCurl(vec3 p){
    const float eps = 1e-4;
    
    p += vec3(0.125*sin(2.0*iTime), -5.0*iTime, 0.125*cos(2.0*iTime));

    float dx = fbm(p + vec3(eps, 0, 0)) - fbm(p - vec3(eps, 0, 0));
    float dy = fbm(p + vec3(0, eps, 0)) - fbm(p - vec3(0, eps, 0));
    float dz = fbm(p + vec3(0, 0, eps)) - fbm(p - vec3(0, 0, eps));

    vec3 noiseGrad0 = vec3(dx, dy, dz)/(2.0 * eps);

    // Offset position for second noise read
    p += 1000.5;

    dx = fbm(p + vec3(eps, 0, 0)) - fbm(p - vec3(eps, 0, 0));
    dy = fbm(p + vec3(0, eps, 0)) - fbm(p - vec3(0, eps, 0));
    dz = fbm(p + vec3(0, 0, eps)) - fbm(p - vec3(0, 0, eps));

    vec3 noiseGrad1 = vec3(dx, dy, dz)/(2.0 * eps);

    vec3 curl = cross(noiseGrad0, noiseGrad1);

    return normalize(curl)+vec3(0,0.8,0);
}


void mainCubemap( out vec4 fragColor, in vec2 fragCoord, in vec3 rayOri, in vec3 rayDir ){
    
    vec3 rd = abs(rayDir);

    uint face;
    if(rd.x > rd.y && rd.x > rd.z){
        face = rayDir.x > 0.0 ? 0u : 1u;
    }else if(rd.y > rd.z){
        face = rayDir.y > 0.0 ? 2u : 3u;
    }else{
        face = rayDir.z > 0.0 ? 4u : 5u;
    }

    uint idx = face * 1024u * 1024u + uint(fragCoord.y) * 1024u + uint(fragCoord.x); //encodeMorton2(uint(fragCoord.x), uint(fragCoord.y));
    if(idx < maxIdx){
        vec3 pos = idxToPoint(idx);
        float source = smoothstep(0.0, -0.1, getSDF(pos/float(width)));
        if(iFrame == 0){
        
            vec3 curl = iTimeDelta*getCurl(pos / 20.0);
            fragColor = vec4(curl, source);
        }else{
            vec3 curl = iTimeDelta*getCurl(pos / 20.0);
            vec3 p = pos - 80.0 * curl;
            p = clamp(p, vec3(0), scale-1.0);
            vec4 data = getDataInterpolated(p, iChannel0);

            float value = mix(data.a - iTimeDelta / 200.0, source, 0.12);
            fragColor = vec4(curl, max(0.0, value));
       }
   }else{
       fragColor = vec4(0);
   }
}