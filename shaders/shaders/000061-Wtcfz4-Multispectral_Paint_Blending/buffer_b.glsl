// Buffer B (buffer) — Multispectral Paint Blending by cornusammonis
// https://www.shadertoy.com/view/Wtcfz4

#define K_FUNC_VEL 0.0
#define K_FUNC_OFF 1.0
#define ADVECT_INIT_VEL 0.0
#define ADVECT_INIT_OFF 0.5
#define ADVECT_TIMESTEP 0.7
#define ADVECT_BLEND 1.0
#define MOUSE_AMP 10.0
#define SPEC_AMP_MAX 0.5
#define SPEC_AMP_MIN -1.5

#ifdef HI_QUALITY
    #define E(d) sample_biquadratic_exact_lod(iChannel0, uv + tx * (d+0.), 0)
#else
    #define E(d) textureLod(iChannel0, uv + tx * (d+0.), 0.0)
#endif

#define K_F(k) (K_FUNC_VEL*k.xy+K_FUNC_OFF*k.zw)
vec4 advect(vec2 uv, vec2 v, float ts, out float result[WAVELENGTHS]){
    vec2 tx = 1.0/iResolution.xy;
    uv -= v * tx;
    vec4 k1 = E();
		float spectrum_advect0[WAVELENGTHS];
		sample_bilinear_unpack(iChannel2, uv - tx*K_F(k1), iResolution.xy, spectrum_advect0);
    vec4 k2 = E(-0.5*K_F(k1)*ts);
		float spectrum_advect1[WAVELENGTHS];
		sample_bilinear_unpack(iChannel2, uv -0.5*tx*K_F(k2), iResolution.xy, spectrum_advect1);
    vec4 k3 = E(-0.5*K_F(k2)*ts);
		float spectrum_advect2[WAVELENGTHS];
		sample_bilinear_unpack(iChannel2, uv -0.5*tx*K_F(k3), iResolution.xy, spectrum_advect2);
    vec4 k4 = E(-K_F(k3)*ts);
		float spectrum_advect3[WAVELENGTHS];
		sample_bilinear_unpack(iChannel2, uv - tx*K_F(k4), iResolution.xy, spectrum_advect3);

		for (int i = 0; i < WAVELENGTHS; i++) {
			 result[i] = (spectrum_advect0[i]+2.0*spectrum_advect1[i]+2.0*spectrum_advect2[i]+spectrum_advect3[i])/6.0;
		}
    return 1.0*(k1+2.0*k2+2.0*k3+k4)/6.0;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 tx = 1.0 / iResolution.xy;

    float spectrum[WAVELENGTHS];

    vec4 A = textureLod(iChannel0, uv, 0.0);

    vec4 packed_spectrum = getPackedSpectrum(iChannel2, fragCoord);
    unpackSpectrum(packed_spectrum, spectrum);

    float spectrum_advect[WAVELENGTHS];

	advect(uv, ADVECT_INIT_OFF*A.zw + ADVECT_INIT_VEL*A.xy, ADVECT_TIMESTEP, spectrum_advect);

    for (int i = 0; i < WAVELENGTHS; i++) {
    	 spectrum[i] = mix(spectrum[i], spectrum_advect[i], ADVECT_BLEND);
    }

    // mouse control
    vec4 mouseUV;
    vec2 delta;
    if (iMouse.z > 0.0) {
        mouseUV = iMouse / iResolution.xyxy;
        delta = -normz(mouseUV.xy - abs(mouseUV.zw));
    } else {
        mouseUV = MOUSE_VEC;
        delta = -normz(mouseUV.xy - abs(mouseUV.zw));
    }
    
    vec2 md = (mouseUV.xy - uv) * vec2(1.0,tx.x/tx.y);
    float amp = clamp(MOUSE_AMP*exp(max(-24.0,-0.5*dot(md,md)/MOUSE_RADIUS)),0.0,1.0);

    // generate a paint color spectrum
    vec4 r0 = rand4(vec2(iTime), iResolution.xy, 0);
    vec4 r1 = rand4(vec2(iTime), iResolution.xy, 1);
    vec4 r2 = rand4(vec2(iTime), iResolution.xy, 2);
    for (int i = 0; i < WAVELENGTHS; i++) {
        float spec = (
            r0.x * gaussian(float(i), float(WAVELENGTHS) * r0.y, r0.z * 2.0) +
            r1.x * gaussian(float(i), float(WAVELENGTHS) * r1.y, r1.z * 2.0) +
            r2.x * gaussian(float(i), float(WAVELENGTHS) * r2.y, r2.z * 2.0));

        spectrum[i] = max(1.0/255.0,spectrum[i] + mix(SPEC_AMP_MIN,SPEC_AMP_MAX,r0.w) * spec * amp);
    }

    // init
    if(iChannelResolution[1].z < 1.0) {  
        fragColor = vec4(0);
    } else if((iChannelResolution[1].z == 1.0 && texture(iChannel2,vec2(0.5)) == vec4(0))) {
        vec3 up = textureLod(iChannel1, uv, 0.0).xyz;
        upsample(up, spectrum);  
        fragColor = packSpectrum(spectrum);
    } else {
		fragColor = packSpectrum(spectrum);
    }
}