// Image (image) — Satin Flow - Dispersion by cornusammonis
// https://www.shadertoy.com/view/ld3cWN

#define BUMP 0.3

// dispersion amount
#define DISP_SCALE 0.3

// minimum IOR
#define MIN_IOR 1.1

// chromatic dispersion samples, higher values decrease banding
#define SAMPLES 9

// time scale
#define TIME 0.1*iTime

// sharpness of the sample weight distributions, higher values increase separation of colors
#define SHARP 15.0

#define FILMIC
#ifdef FILMIC
// tweaked version of a filmic curve from paniq with a softer left knee
vec3 contrast(vec3 x) {
    x=log(1.0+exp(x*10.0-7.2));
    return (x*(x*6.2+0.5))/(x*(x*6.2+1.7)+0.06);
}
#else
#define SIGMOID_CONTRAST 8.0
vec3 contrast(vec3 x) {
	return (1.0 / (1.0 + exp(-SIGMOID_CONTRAST * (x - 0.5))));    
}
#endif

vec2 normz(vec2 x) {
	return x == vec2(0) ? vec2(0) : normalize(x);
}

vec3 normz(vec3 x) {
	return x == vec3(0) ? vec3(0) : normalize(x);
}

vec3 sampleWeights(float i) {
	return vec3(exp(-SHARP*pow(i-0.25,2.0)), exp(-SHARP*pow(i-0.5,2.0)), exp(-SHARP*pow(i-0.75,2.0)));
}

mat3 cameraMatrix() {
    vec3 ro = vec3(sin(TIME),0.0,cos(TIME));
    vec3 ta = vec3(0,1.5,0);  
    vec3 w = normalize(ta - ro);
    vec3 u = normalize(cross(w,vec3(0,1,0)));
    vec3 v = normalize(cross(u,w));
    return mat3(u,v,w);
}

// same as the normal refract() but returns the coefficient
vec3 refractK(vec3 I, vec3 N, float eta, out float k) {
    k = max(0.0,1.0 - eta * eta * (1.0 - dot(N, I) * dot(N, I)));
    if (k <= 0.0)
        return vec3(0.0);
    else
        return eta * I - (eta * dot(N, I) + sqrt(k)) * N;
}

vec3 sampleDisp(vec2 uv, vec3 disp) {
	vec2 p = uv - 0.5;

    // camera movement
    mat3 camMat = cameraMatrix();

    vec3 rd = normz(camMat * vec3(p.xy, 1.0));
    vec3 norm = normz(camMat * disp);
    
    vec3 col = vec3(0);
    const float SD = 1.0 / float(SAMPLES);
    float wl = 0.0;
    vec3 denom = vec3(0);
    for(int i = 0; i < SAMPLES; i++) {
        vec3 sw = sampleWeights(wl);
        denom += sw;
        float k;
        vec3 refr = refractK(rd, norm, MIN_IOR + wl * DISP_SCALE, k);
        vec3 refl = reflect(rd, norm);
        col += sw * mix(texture(iChannel1, refl).xyz, texture(iChannel1, refr).xyz, k);
        wl  += SD;
    }
    
    return col / denom;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 texel = 1. / iResolution.xy;
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec2 n  = vec2(0.0, texel.y);
    vec2 e  = vec2(texel.x, 0.0);
    vec2 s  = vec2(0.0, -texel.y);
    vec2 w  = vec2(-texel.x, 0.0);

    float d   = texture(iChannel0, uv).x;
    // uncomment to just render the heightmap
    //#define SIMPLE
    #ifdef SIMPLE
    fragColor = 0.5+0.02*vec4(d);
    #else
    float d_n  = texture(iChannel0, (uv+n)  ).x;
    float d_e  = texture(iChannel0, (uv+e)  ).x;
    float d_s  = texture(iChannel0, (uv+s)  ).x;
    float d_w  = texture(iChannel0, (uv+w)  ).x; 
    float d_ne = texture(iChannel0, (uv+n+e)).x;
    float d_se = texture(iChannel0, (uv+s+e)).x;
    float d_sw = texture(iChannel0, (uv+s+w)).x;
    float d_nw = texture(iChannel0, (uv+n+w)).x; 

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
    
    vec3 dispCol = vec3(0);
    
    // compute dispersion and specular with antialiasing
    vec3 avd = vec3(0);
    for(int i = 0; i < 3; i++) {
        for(int j = 0; j < 3; j++) {
            vec2 dxy = vec2(dxn[i], dyn[j]);
            float w = dcn[i] * dcn[j];
            vec3 bn = reflect(normalize(vec3(BUMP*dxy, -1.0)), vec3(0,1,0));
            avd += w * bn;
            den += w;
            dispCol += w * sampleDisp(uv, bn);
            spec += w * ggx(bn, vec3(0,1,0), ld, 0.3, 1.0);
        }
    }

    avd /= den;
    spec /= den;
    dispCol /= den;
    
    // end bumpmapping section

    fragColor =  vec4(contrast(dispCol),1) + 1.0*vec4(0.9, 0.85, 0.8, 1)*spec;

    #endif

}