// Common (common) — Scattered Honey by fizzer
// https://www.shadertoy.com/view/ttl3R2


mat3 rotX(float a)
{
    return mat3(1., 0., 0.,
                0., cos(a), sin(a),
                0., -sin(a), cos(a));
}

mat3 rotY(float a)
{
    return mat3(cos(a), 0., sin(a),
                0., 1., 0.,
                -sin(a), 0., cos(a));
}

mat3 rotZ(float a)
{
    return mat3(cos(a), sin(a), 0.,
                -sin(a), cos(a), 0.,
                0., 0., 1.);
}

// Smooth 3D texture interpolation
vec4 smoothSample(sampler3D tex, vec3 p, int level)
{
    vec3 sz = vec3(textureSize(tex, 0));
    
    ivec3 ip = ivec3(floor(p * sz));
    
    vec4 s0 = texelFetch(tex, (ip + ivec3(0, 0, 0)) & ivec3(sz - 1.), level);
    vec4 s1 = texelFetch(tex, (ip + ivec3(1, 0, 0)) & ivec3(sz - 1.), level);
    vec4 s2 = texelFetch(tex, (ip + ivec3(0, 1, 0)) & ivec3(sz - 1.), level);
    vec4 s3 = texelFetch(tex, (ip + ivec3(1, 1, 0)) & ivec3(sz - 1.), level);
    vec4 s4 = texelFetch(tex, (ip + ivec3(0, 0, 1)) & ivec3(sz - 1.), level);
    vec4 s5 = texelFetch(tex, (ip + ivec3(1, 0, 1)) & ivec3(sz - 1.), level);
    vec4 s6 = texelFetch(tex, (ip + ivec3(0, 1, 1)) & ivec3(sz - 1.), level);
    vec4 s7 = texelFetch(tex, (ip + ivec3(1, 1, 1)) & ivec3(sz - 1.), level);
    vec3 f = smoothstep(0., 1., fract(p * sz));

    return mix(
        mix(mix(s0, s1, f.x),
            mix(s2, s3, f.x), f.y),
        mix(mix(s4, s5, f.x),
            mix(s6, s7, f.x), f.y),
        f.z);
}
