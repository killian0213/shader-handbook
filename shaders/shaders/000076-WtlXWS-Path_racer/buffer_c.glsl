// Buffer C (buffer) — Path racer by XT95
// https://www.shadertoy.com/view/WtlXWS

// Created by anatole duprat - XT95/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// God ray pass in half resolution


float phaseFunction(float lightDotView)
{
    const float k = .8;
	float v = 1.0 - k * k;
	v /= (4.0 * PI * pow(1.0 + k * k - (2.0 * k)*lightDotView, 1.5));
	return v;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // init global
    vec2 invRes = vec2(1.) / iResolution.xy;
    data = readGameData(iChannel0, invRes);
    time = iTime;
    
    // early exit because we want half resolution
    vec2 uv = fragCoord * invRes*2.;
	float l = texture(iChannel1, uv).a;
    if(uv.x>1. || uv.y>1. )
    {
        fragColor = vec4(0.);
        return;
    } 
    
    // camera ray
    vec2 v = -1.0+2.0*(uv);
	v.x *= iResolution.x/iResolution.y;
    vec3 ro = vec3(0., 1.3, 0.)+data.shipPos-data.shipDirection*3.;
    vec3 rd = normalize( vec3(v, 1.45) );
    rd.xy = rotate(data.shipAccel.x*.2) * rd.xy;
    rd.xz = rotate(-data.shipTheta) * rd.xz;
    
    float jitt = hash2Interleaved(gl_FragCoord.xy)*.2;
    const float eps = 0.2;
    
    // acc shadow loop
    float phase = phaseFunction(dot(sunDir,rd));
    vec3 godray = vec3(0.);
    for(float i=0.0; i<1.; i+=eps) {
       vec3 p = ro+rd*l*(i+jitt);
       float d = shadow(p, sunDir, float(.2), float(80.));
       d += d*(texture(iChannel3, p*0.01+time*0.05).r*2.-1.);
       d += d*(texture(iChannel3, p*0.02-time*0.02).r*2.-1.);
       godray += d * phase;
    }
	godray = vec3(1.,.7,.5) * godray;
        
    
    fragColor = vec4(godray,l);
}