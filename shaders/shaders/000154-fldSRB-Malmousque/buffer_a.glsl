// Buffer A (buffer) — Malmousque by XT95
// https://www.shadertoy.com/view/fldSRB

// ---------------------------------------------------------------------------------
// Sky
// https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/simulating-sky/simulating-colors-of-the-sky
// ---------------------------------------------------------------------------------
float iSphere(vec3 ro, vec3 rd, float radius) {
    float b = 2.0 * dot(rd, ro);
    float c = dot( ro, ro ) - radius * radius;
    float disc = b * b - 4.0 * c;
    if (disc < 0.0)
        return (-1.0);
    float q = (-b + ((b < 0.0) ? -sqrt(disc) : sqrt(disc))) / 2.0;
    float t0 = q;
    float t1 = c / q;
    return max(t0,t1);//vec2(t0,t1);
}

vec3 skyColor( in vec3 rd )
{
    const int nbSamples = 64;
    const int nbSamplesLight = 32;
    
    vec3 absR = vec3(3.8e-6f, 13.5e-6f, 33.1e-6f);
    vec3 absM = vec3(21e-6f);
    
    
    vec3 accR = vec3(0.);
    vec3 accM = vec3(0.);
    
    float mu = dot(rd, sundir);
    float g = 0.76f; 
    vec2 phase = vec2(3.f / (16.f * PI) * (1. + mu * mu), 3.f / (8.f * PI) * ((1.f - g * g) * (1.f + mu * mu)) / ((2.f + g * g) * pow(1.f + g * g - 2.f * g * mu, 1.5f)));

    float radA = 6420e3;
    float radE = 6360e3;
    vec3 ro = vec3(0., radE+1., 0.);
    float t = iSphere(ro, rd, radA);
    float stepSize = t / float(nbSamples);
    
    vec2 opticalDepth = vec2(0.);
    
    for(int i=ZERO; i<nbSamples; i++) {
     	vec3 p = ro + rd * (float(i)+.5) * stepSize;
        
        float h = length(p) - radE;
        vec2 thickness = vec2(exp(-h/7994.), exp(-h/1200.)) * stepSize;
        opticalDepth += thickness;
        
        float tl = iSphere(p, sundir, radA);
        float stepSizeLight = tl / float(nbSamplesLight);
        vec2 opticalDepthLight = vec2(0.);
        int j;
        for(j=ZERO; j<nbSamplesLight; j++) {
            vec3 pl = p + sundir * (float(j)+.5) * stepSizeLight;
            float hl = length(pl) - radE;
            if (hl < 0.) break;
        	opticalDepthLight += vec2(exp(-hl/7994.), exp(-hl/1200.)) * stepSizeLight;
        }
        if (j == nbSamplesLight) {
            vec3 tau = absR * (opticalDepth.x + opticalDepthLight.x) + absM * 1.1 * (opticalDepth.y + opticalDepthLight.y);
            vec3 att = exp(-tau);
            accR += att * thickness.x ;
            accM += att * thickness.y;
        }
    }
    
    return (accR * absR * phase.x + accM * absM * phase.y)*1.5;
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy*4.;
    
    if (uv.x>1. || uv.y>1.) return;
    
    vec3 rd = equi2cube(uv);
    
    // compute only on the first frame!
    //if (iFrame < 4) {
        fragColor = vec4(skyColor(rd), 1.);
    //} else {
    //    fragColor = texture(iChannel0, uv*.25);
    //}
}