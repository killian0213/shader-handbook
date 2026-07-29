// Buffer C (buffer) — Niolon by XT95
// https://www.shadertoy.com/view/Nt3XDM

// ---------------------------------------------------------------------------------
// Light scattering pass
// ---------------------------------------------------------------------------------


// ---------------------------------------------------------------------------------
// Signed Distance Field
// ---------------------------------------------------------------------------------
float terrain(vec3 p) {
    
    float d = length(abs(p.xy)+vec2(-220.,50.))-200.; // 2 cylinders 
    d = min(d, length(p.zy-vec2(-10.,60.))-50.+cos(p.x*.04)*10.);
    d = min(d, length(p.zy-vec2(-400.,0.))-150.);
    d = min(d, length(p.zy-vec2(400.,0.))-150.);
    d = d*.2  + noise(p*.04-.9)*10. - noise(p*.2)*0.9+.5;
    d = min(d, p.y*.5 + d);
    return d;
}
// iq Soft Shadow - https://iquilezles.org/articles/rmshadows
float shadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = terrain(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}

// ---------------------------------------------------------------------------------
// Scattering phase
// ---------------------------------------------------------------------------------
float phaseFunction(float lightDotView)
{
    const float k = .9;
	float v = 1.0 - k * k;
	v /= (4.0 * PI * pow(1.0 + k * k - (2.0 * k)*lightDotView, 1.5));
	return v;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 invRes = vec2(1.) / iResolution.xy;
    
    // early exit (half resolution here)
    vec2 uv = fragCoord * invRes * 2.;
	float l = texture(iChannel1, uv/SCALE_FACTOR).a;
    if(uv.x>1. || uv.y>1. )
    {
        fragColor = vec4(0.);
        return;
    } 
    
    // camera ray
    vec2 v = -1.0+2.0*(uv);
    v.x *= iResolution.x/iResolution.y;
    vec3 ro = vec3(0.,10.,185.-time*0.1);
    vec3 rd = normalize( vec3(v.x, v.y, -2.) );
    
    
    
    // blue noise jittering
    const float eps = 0.1;
    float jitt = fract(texture(iChannel2, fragCoord/1024.).r + float(frame)*GOLDEN_RATIO) * eps;
    
    // scatter loop
    float phase = phaseFunction(dot(sundir,rd));
    vec3 scattering = vec3(0.);
    for(float i=jitt; i<1.; i+=eps) {
       vec3 p = ro+rd*l*i;
       float d = shadow(p,sundir, 2.,200., 500.);
       scattering += d * phase;
    }
    
    fragColor = mix(texture(iChannel0,uv*.5), vec4(vec3(1.,.7,.5)*scattering*.15, l), .15);
}