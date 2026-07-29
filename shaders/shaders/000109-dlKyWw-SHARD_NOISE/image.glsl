// Image (image) — SHARD NOISE by ENDESGA
// https://www.shadertoy.com/view/dlKyWw

// @ENDESGA
// splat-field forked from https://www.shadertoy.com/view/clGyWm

#define R iResolution
#define T (iTime * .1)

vec3 hash(vec3 p)
{
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5,183.3,246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
    p = fract(sin(p) * 43758.5453123);
    return p;
}

#define tau 6.283185307179586

float shard_noise(in vec3 p, in float sharpness) {
    vec3 ip = floor(p);
    vec3 fp = fract(p);

    float v = 0., t = 0.;
    for (int z = -1; z <= 1; z++) {
        for (int y = -1; y <= 1; y++) {
            for (int x = -1; x <= 1; x++) {
                vec3 o = vec3(x, y, z);
                vec3 io = ip + o;
                vec3 h = hash(io);
                vec3 r = fp - (o + h);

                float w = exp2(-tau*dot(r, r));
                // tanh deconstruction and optimization by @Xor
                float s = sharpness * dot(r, hash(io + vec3(11, 31, 47)) - 0.5);
                v += w * s*inversesqrt(1.0+s*s);
                t += w;
            }
        }
    }
    return ((v / t) * .5) + .5;
}

void mainImage( out vec4 C, in vec2 F )
{
    vec2 p = F/R.y;
    vec3 uv = vec3( p + T, T * .5 );
    bool click = iMouse.z>0.;

    float fade = click ? 4. : pow(p.x,2.) * 30.;
    
    if(p.y<0.5 || click) // octave-blend demo
    {
        C = vec4(vec3(
            (shard_noise(64.0*uv,fade) * .03125) +
            (shard_noise(32.0*uv,fade) * .0625) +
            (shard_noise(16.0*uv,fade) * .125) +
            (shard_noise(8.0*uv,fade) * .25) +
            (shard_noise(4.0*uv,fade) * .5)
        ),1.);
    }
    else
    C = vec4( vec3(shard_noise(16.0*uv,fade)), 1. );
    if((p.y > .875 || p.y < .125) && !click) C = round(C);
}