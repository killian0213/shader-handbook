// Buffer A (buffer) — Multispectral Paint Blending by cornusammonis
// https://www.shadertoy.com/view/Wtcfz4

#define K_FUNC_VEL 1.0
#define K_FUNC_OFF 0.0
#define OFFSET_SCALE_OFF 1.0
#define OFFSET_SCALE_VEL 1.0
#define OFFSET_TEMPORAL_SMOOTH 0.0
#define ADVECT_TIMESTEP 1.0
#define DIVERGENCE_MIN -0.0005
#define VELOCITY_FEED 1.0
#define VISCOSITY 0.0015
#define DAMPING 0.005
#define MOUSE_AMP 1.0

bool reset() {
    return texture(iChannel3, vec2(32.5/256.0, 0.5) ).x > 0.5;
}

#ifdef HI_QUALITY
    #define E(d) sample_biquadratic_exact_lod(iChannel0, uv + texel * (d+0.), 0)
#else
    #define E(d) textureLod(iChannel0, uv + texel * (d+0.), 0.0)
#endif
#define K_F(k) (K_FUNC_VEL*k.xy+K_FUNC_OFF*k.zw)
vec4 advect(vec2 uv, vec2 v, float ts){
    vec2 texel = 1.0/iResolution.xy;
    uv -= v * texel;
    vec4 k1 = E();
    vec4 k2 = E(-0.5*K_F(k1)*ts);
    vec4 k3 = E(-0.5*K_F(k2)*ts);
    vec4 k4 = E(-K_F(k3)*ts);
    return 1.0*(k1+2.0*k2+2.0*k3+k4)/6.0;
}
#ifdef HI_QUALITY
    #define C(x,y) sample_biquadratic_exact_lod(iChannel0, t*(U+float(1<<s)*vec2(x,y)), s)
#else
    #define C(x,y) textureLod(iChannel0, t*(U+float(1<<s)*vec2(x,y)), float(s))
#endif
#define D() sample_biquadratic_gradient_lod(iChannel2, uv, s)
void mainImage( out vec4 O, in vec2 U )
{
    O = O-O;
    vec2 t = 1./iResolution.xy;
    vec2 uv = U*t;

    int s = int(max(log2(iResolution.x),log2(iResolution.y)));
    vec2 mdiff = vec2(0);
    vec4 sample_prev = textureLod(iChannel0, uv, 0.0);
    vec2 offset_prev = sample_prev.zw;
	const float L0 = -3.0;
	const float L1 = 0.5;
	const float L2 = 0.25;
	vec4 lapl = vec4(0);
    for (; s >= 0; s--) {
		vec4 c_n = C(0,1);
		vec4 c_s = C(0,-1);
		vec4 c_e = C(1,0);
		vec4 c_w = C(-1,0);
		vec4 c_ne = C(1,1);
		vec4 c_se = C(1,-1);
		vec4 c_nw = C(-1,1);
		vec4 c_sw = C(-1,-1);
		vec4 c = C(0,0);
		lapl += pow(float(s+1),1.0) * (L0 * c + L1 * (c_n+c_e+c_w+c_s) + L2 * (c_ne+c_se+c_nw+c_sw));
		O.xy += pow(float(s+1),1.0) * (2.0 * vec2(c_n.x + c_s.x, c_e.y + c_w.y) -4.0 * c.xy + (c_se - c_ne - c_sw + c_nw).yx);
        mdiff += pow(float(s+1),1.0) * D();
    }
    vec2 offset = OFFSET_SCALE_OFF*O.xy + OFFSET_SCALE_VEL*sample_prev.xy;
    vec2 new_offset = mix(offset,offset_prev,OFFSET_TEMPORAL_SMOOTH);
    O = vec4(advect(uv,new_offset,ADVECT_TIMESTEP).xy 
            + DIVERGENCE_MIN * mdiff 
            + VELOCITY_FEED * t.xx * new_offset 
            + VISCOSITY * lapl.xy 
            - DAMPING * sample_prev.xy
            , new_offset
    );

    // mouse control
    vec4 mouseUV;
    if (iMouse.z > 0.0) {
        mouseUV = iMouse / iResolution.xyxy;
    } else {
        mouseUV = MOUSE_VEC;
    }   
    vec2 delta = -normz(mouseUV.xy - abs(mouseUV.zw));
    vec2 md = (mouseUV.xy - uv) * vec2(1.0,t.x/t.y);
    float amp = clamp(exp(max(-24.0,-dot(md,md)/MOUSE_RADIUS)),0.0,1.0);
    O += vec4(MOUSE_AMP * delta * amp,0,0);

    // init
    if(iChannelResolution[1].z < 1.0) {
    	O = vec4(1e-4);    
    } else if(reset()) {
        O = vec4(1e-4);
    }
}