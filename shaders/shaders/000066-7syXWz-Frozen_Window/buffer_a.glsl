// Buffer A (buffer) — Frozen Window by davidar
// https://www.shadertoy.com/view/7syXWz

void mainImage( out vec4 O, in vec2 U )
{
    vec2 R = iResolution.xy, pw = 1./R, uv = U/R;
    vec3 o = vec3(1,0,-1);
#define N(swizzle) texture(iChannel0, uv+pw*o.swizzle)
    vec4 v = N(yy);
    vec4[6] n = vec4[6](N(xy), N(xx), N(yx), N(yz), N(zz), N(zy));
    bool receptive = v.x >= 1.0;
    for (int i = 0; i < 6; i++) {
        receptive = receptive || (n[i].x >= 1.0); 
    }
    O = vec4(v.x, float(receptive), 0, 0);
}