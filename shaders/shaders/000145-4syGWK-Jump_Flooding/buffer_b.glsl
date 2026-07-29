// Buf B (buffer) — Jump Flooding by paniq
// https://www.shadertoy.com/view/4syGWK

// channel 2: take snapshot of stage

vec4 load0(ivec2 p) {
    vec2 uv = (vec2(p)-0.5) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);
}

vec4 load1(ivec2 p) {
    vec2 uv = (vec2(p)-0.5) / iChannelResolution[1].xy;
    return texture(iChannel1, uv);
}

void store(out vec4 t, vec4 v) {
    t = v;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 tc = ivec2(fragCoord + 0.5);
    int iter = int(mod(float(iFrame),13.0));
    int frame = int(mod(iTime,15.0));
    if ((iter == frame) || ((frame > 12) && (iter == 12))) {
        // snapshot
        store(fragColor,load0(tc));
    } else {
        // copy
        store(fragColor,load1(tc));
    }
}