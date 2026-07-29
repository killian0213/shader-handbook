// Buf B (buffer) — Satin Flow by cornusammonis
// https://www.shadertoy.com/view/Mstczn

#define _G0 0.25
#define _G1 0.125
#define _G2 0.0625
#define TIMESTEP 0.1
#define GSCALE -1000.0
#define DV 0.70710678

vec3 gaussian(vec3 x, vec3 x_nw, vec3 x_n, vec3 x_ne, vec3 x_w, vec3 x_e, vec3 x_sw, vec3 x_s, vec3 x_se) {
    return _G0*x + _G1*(x_n + x_e + x_w + x_s) + _G2*(x_nw + x_sw + x_ne + x_se);
}

vec4 gaussian(vec4 x, vec4 x_nw, vec4 x_n, vec4 x_ne, vec4 x_w, vec4 x_e, vec4 x_sw, vec4 x_s, vec4 x_se) {
    return _G0*x + _G1*(x_n + x_e + x_w + x_s) + _G2*(x_nw + x_sw + x_ne + x_se);
}

bool reset() {
    return texture(iChannel3, vec2(32.5/256.0, 0.5) ).x > 0.5;
}

vec3 normz(vec3 x) {
	return x == vec3(0.0) ? vec3(0.0) : normalize(x);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 vUv = fragCoord.xy / iResolution.xy;
    vec2 texel = 1. / iResolution.xy;
    
    vec3 n  = vec3(0.0,   1.0, 0.0);
    vec3 ne = vec3(1.0,   1.0, 0.0);
    vec3 e  = vec3(1.0,   0.0, 0.0);
    vec3 se = vec3(1.0,  -1.0, 0.0);
    vec3 s  = vec3(0.0,  -1.0, 0.0);
    vec3 sw = vec3(-1.0, -1.0, 0.0);
    vec3 w  = vec3(-1.0,  0.0, 0.0);
    vec3 nw = vec3(-1.0,  1.0, 0.0);

    vec3 u =    texture(iChannel0, fract(vUv)).xyz;
    vec3 u_n =  texture(iChannel0, fract(vUv+texel*n.xy)).xyz;
    vec3 u_e =  texture(iChannel0, fract(vUv+texel*e.xy)).xyz;
    vec3 u_s =  texture(iChannel0, fract(vUv+texel*s.xy)).xyz;
    vec3 u_w =  texture(iChannel0, fract(vUv+texel*w.xy)).xyz;
    vec3 u_nw = texture(iChannel0, fract(vUv+texel*nw.xy)).xyz;
    vec3 u_sw = texture(iChannel0, fract(vUv+texel*sw.xy)).xyz;
    vec3 u_ne = texture(iChannel0, fract(vUv+texel*ne.xy)).xyz;
    vec3 u_se = texture(iChannel0, fract(vUv+texel*se.xy)).xyz;
    
    vec3 u_blur = gaussian(u, u_nw, u_n, u_ne, u_w, u_e, u_sw, u_s, u_se);
    
    vec4 v =    texture(iChannel2, fract(vUv));
    vec4 v_n =  texture(iChannel2, fract(vUv+texel*n.xy));
    vec4 v_e =  texture(iChannel2, fract(vUv+texel*e.xy));
    vec4 v_s =  texture(iChannel2, fract(vUv+texel*s.xy));
    vec4 v_w =  texture(iChannel2, fract(vUv+texel*w.xy));
    vec4 v_nw = texture(iChannel2, fract(vUv+texel*nw.xy));
    vec4 v_sw = texture(iChannel2, fract(vUv+texel*sw.xy));
    vec4 v_ne = texture(iChannel2, fract(vUv+texel*ne.xy));
    vec4 v_se = texture(iChannel2, fract(vUv+texel*se.xy));
    
    vec4 v_blur = gaussian(v, v_nw, v_n, v_ne, v_w, v_e, v_sw, v_s, v_se);
    
    float gc = v_blur.w;

    vec3 du = u_blur + TIMESTEP * v.xyz;
    
    // initialize with noise
    if(iFrame < 10 || reset()) {
        vec3 rnd = vec3(noise(16.0 * vUv + 1.1), noise(16.0 * vUv + 2.2), noise(16.0 * vUv + 3.3));
        fragColor = vec4(rnd,0);
    } else {
        float ld = length(du);
        // hard clamping
        //du = length(du) > 1.0 ?  normz(du) : du;
        // soft clamping
        du = du - 0.005* ld*ld*ld*normz(du);
        fragColor = vec4(du, gc);
    }
    

}