// Image (image) — Satin Flow by cornusammonis
// https://www.shadertoy.com/view/Mstczn

#define BUMP 10.0

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

    float d   = texture(iChannel0, uv).x;
    //#define SIMPLE
    #ifdef SIMPLE
    fragColor = 0.5+0.02*vec4(d);
    #else
    float d_n  = texture(iChannel0, fract(uv+n)  ).x;
    float d_e  = texture(iChannel0, fract(uv+e)  ).x;
    float d_s  = texture(iChannel0, fract(uv+s)  ).x;
    float d_w  = texture(iChannel0, fract(uv+w)  ).x; 
    float d_ne = texture(iChannel0, fract(uv+n+e)).x;
    float d_se = texture(iChannel0, fract(uv+s+e)).x;
    float d_sw = texture(iChannel0, fract(uv+s+w)).x;
    float d_nw = texture(iChannel0, fract(uv+n+w)).x; 

    float dxn[3];
    float dyn[3];
    float dcn[3];
    
    dcn[0] = 0.5;
    dcn[1] = 1.0; 
    dcn[2] = 0.5;

    dyn[0] = d_nw - d_sw;
    dyn[1] = d_n  - d_s; 
    dyn[2] = d_ne - d_se;

    dxn[0] = d_ne - d_nw; 
    dxn[1] = d_e  - d_w; 
    dxn[2] = d_se - d_sw; 

    // The section below is an antialiased version of 
    // Shane's Bumped Sinusoidal Warp shadertoy here:
    // https://www.shadertoy.com/view/4l2XWK
	#define SRC_DIST 8.0
    vec3 sp = vec3(uv-0.5, 0);
    vec3 light = vec3(cos(iTime/2.0)*0.5, sin(iTime/2.0)*0.5, -SRC_DIST);
    vec3 ld = light - sp;
    float lDist = max(length(ld), 0.001);
    ld /= lDist;
    float aDist = max(distance(vec3(light.xy,0),sp) , 0.001);
    float atten = min(0.07/(0.25 + aDist*0.5 + aDist*aDist*0.05), 1.);
    vec3 rd = normalize(vec3(uv - 0.5, 1.));

    float spec = 0.0;
	float den = 0.0;
    
    // apply some antialiasing to the normals
    vec3 avd = vec3(0);
    for(int i = 0; i < 3; i++) {
        for(int j = 0; j < 3; j++) {
            vec2 dxy = vec2(dxn[i], dyn[j]);
            float w = dcn[i] * dcn[j];
            vec3 bn = reflect(normalize(vec3(BUMP*dxy, -1.0)), vec3(0,1,0));
            avd += w * bn;
            den += w;
        }
    }

    avd /= den;
    spec += ggx(avd, vec3(0,1,0), ld, 0.7, 0.3);
    
    // end bumpmapping section
    
    // cheap occlusion with mipmaps
    float occ = 0.0;
    for (float m = 1.0; m <= 10.0; m +=1.0) {
        float dm = texture(iChannel0, uv, m).x;
    	occ += smoothstep(-8.0, 2.0, (d - dm))/(m*m);
    }
    
    occ = pow(occ / 1.5, 2.0);
    
    fragColor = occ * vec4(0.9,0,0.05,0) + 2.5*vec4(0.9, 0.85, 0.8, 1)*spec;
    #endif

}