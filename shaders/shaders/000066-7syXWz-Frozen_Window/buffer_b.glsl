// Buffer B (buffer) — Frozen Window by davidar
// https://www.shadertoy.com/view/7syXWz

void mainImage( out vec4 O, in vec2 U )
{
    vec2 R = iResolution.xy, pw = 1./R, uv = U/R;
    vec3 o = vec3(1,0,-1);
#define N(swizzle) texture(iChannel0, uv+pw*o.swizzle)
    vec4 v = N(yy);
    vec4[6] n = vec4[6](N(xy), N(xx), N(yx), N(yz), N(zz), N(zy));
    float change;
    change = (v.y == 1.0) ? GAMMA : -ALPHA*v.x;
    float nrs = 0.0;
    for (int i = 0; i < 6; i++) if(n[i].y == 0.0) nrs += n[i].x;
    change += (nrs/6.0)*ALPHA;
    O = vec4(v.x + change, 0,0,0);
    if (iFrame < 10) {
      O = vec4(BETA + 0.1 * (hash12(U) - 0.5),0,0,0);
      if (floor(U) == vec2(0,0) || (hash22(U).x < 1e-3 && hash22(U).y < 1e-2))  O = vec4(1.1,0,0,0);
    }
    if (iFrame % 100 == 0 && hash23(vec3(U,iFrame)).x < 1e-3 && hash23(vec3(U,iFrame)).y < 1e-3) O.x++;
}