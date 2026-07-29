// Image (image) — Perceptual Depth Poisson Solver by cornusammonis
// https://www.shadertoy.com/view/MlByW3

/*
	This shader adds perceived depth to a vector map by running the map through a Poisson solver.
	A vector map is supplied by a dynamical system in Buf A (see: https://www.shadertoy.com/view/Mtc3Dj),
    the Laplacian of the map is computed in Buf B, and the depth of the map is computed using a
    Poisson solver in Buf C and Buf D. The Poisson solver uses a technique conceptually similar to 
    the standard Jacobi method, but with a larger kernel and faster convergence times.

	Comment out "#define POISSON" below to render using the original vector map without using the
    Poisson solver.
*/

// displacement
#define DISP 0.01

// contrast
#define SIGMOID_CONTRAST 20.0

// mip level
#define MIP 0.0

// comment to use the original vector field without running through the Poisson solver
#define POISSON


vec3 contrast(vec3 x) {
	return 1.0 / (1.0 + exp(-SIGMOID_CONTRAST * (x - 0.5)));    
}

vec3 normz(vec3 x) {
	return x == vec3(0) ? vec3(0) : normalize(x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 texel = 1. / iResolution.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec2 n  = vec2(0.0, texel.y);
    vec2 e  = vec2(texel.x, 0.0);
    vec2 s  = vec2(0.0, -texel.y);
    vec2 w  = vec2(-texel.x, 0.0);

    #ifdef POISSON
        float d   = texture(iChannel0, uv).x;
        float d_n = texture(iChannel0, fract(uv+n)).x;
        float d_e = texture(iChannel0, fract(uv+e)).x;
        float d_s = texture(iChannel0, fract(uv+s)).x;
        float d_w = texture(iChannel0, fract(uv+w)).x; 

        float d_ne = texture(iChannel0, fract(uv+n+e)).x;
        float d_se = texture(iChannel0, fract(uv+s+e)).x;
        float d_sw = texture(iChannel0, fract(uv+s+w)).x;
        float d_nw = texture(iChannel0, fract(uv+n+w)).x; 

        float dxn[3];
        float dyn[3];

        dyn[0] = d_nw - d_sw;
        dyn[1] = d_n  - d_s; 
        dyn[2] = d_ne - d_se;

        dxn[0] = d_ne - d_nw; 
        dxn[1] = d_e  - d_w; 
        dxn[2] = d_se - d_sw; 
    #else
        vec2 d   = texture(iChannel2, uv).xy;
        vec2 d_n = texture(iChannel2, fract(uv+n)).xy;
        vec2 d_e = texture(iChannel2, fract(uv+e)).xy;
        vec2 d_s = texture(iChannel2, fract(uv+s)).xy;
        vec2 d_w = texture(iChannel2, fract(uv+w)).xy; 

        vec2 d_ne = texture(iChannel2, fract(uv+n+e)).xy;
        vec2 d_se = texture(iChannel2, fract(uv+s+e)).xy;
        vec2 d_sw = texture(iChannel2, fract(uv+s+w)).xy;
        vec2 d_nw = texture(iChannel2, fract(uv+n+w)).xy; 

        float dxn[3];
        float dyn[3];

        dyn[0] = d_n.y;
        dyn[1] = d.y; 
        dyn[2] = d_s.y;

        dxn[0] = d_e.x; 
        dxn[1] = d.x; 
        dxn[2] = d_w.x; 
    #endif

    vec3 i   = texture(iChannel1, fract(vec2(0.5) + DISP * vec2(dxn[0],dyn[0])), MIP).xyz;
    vec3 i_n = texture(iChannel1, fract(vec2(0.5) + DISP * vec2(dxn[1],dyn[1])), MIP).xyz;
    vec3 i_e = texture(iChannel1, fract(vec2(0.5) + DISP * vec2(dxn[2],dyn[2])), MIP).xyz;
    vec3 i_s = texture(iChannel1, fract(vec2(0.5) + DISP * vec2(dxn[1],dyn[2])), MIP).xyz;
    vec3 i_w = texture(iChannel1, fract(vec2(0.5) + DISP * vec2(dxn[2],dyn[0])), MIP).xyz;

    // The section below is an antialiased version of 
    // Shane's Bumped Sinusoidal Warp shadertoy here:
    // https://www.shadertoy.com/view/4l2XWK

    vec3 sp = vec3(uv, 0);
    vec3 light = vec3(cos(iTime/2.0)*0.5, sin(iTime/2.0)*0.5, -1.);
    vec3 ld = light - sp;
    float lDist = max(length(ld), 0.001);
    ld /= lDist;  
    float atten = min(1./(0.25 + lDist*0.5 + lDist*lDist*0.05), 1.);
    vec3 rd = normalize(vec3(uv - 1.0, 1.));

    float bump = 2.0;



    float spec = 0.0;
    for(int i = 0; i < 3; i++) {
        for(int j = 0; j < 3; j++) {
            vec2 dxy = vec2(dxn[i], dyn[j]);
            vec3 bn = normalize(vec3(dxy * bump, -1.0));
            spec += pow(max(dot( reflect(-ld, bn), -rd), 0.), 8.) / 9.0;                 
        }
    }

    // end bumpmapping section

    vec3 ib = 0.4 * i + 0.15 * (i_n+i_e+i_s+i_w);

    vec3 texCol = 0.9*contrast(0.9*ib);

    fragColor = vec4((texCol + vec3(0.9, 0.85, 0.8)*spec) * atten,1.0);

}