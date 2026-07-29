// Buffer A (buffer) — Smoking Duck by xjorma
// https://www.shadertoy.com/view/mtfXD4

// Created by David Gallardo - xjorma/2023
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0


float noise(vec3 p)
{
	vec3 ip=floor(p);
    p-=ip; 
    vec3 s=vec3(7,157,113);
    vec4 h=vec4(0.,s.yz,s.y+s.z)+dot(ip,s);
    p=p*p*(3.-2.*p); 
    h=mix(fract(sin(h)*43758.5),fract(sin(h+s.x)*43758.5),p.x);
    h.xy=mix(h.xz,h.yw,p.y);
    return mix(h.x,h.y,p.z); 
}

vec2 fbm(vec3 p, int octaveNum)
{
	vec2 acc = vec2(0);	
	float freq = 1.0;
	float amp = 0.5;
    vec3 shift = vec3(100);
	for (int i = 0; i < octaveNum; i++)
	{
		acc += vec2(noise(p), noise(p + vec3(0,0,10))) * amp;
        p = p * 2.0 + shift;
        amp *= 0.5;
	}
	return acc;
}


vec3 sampleMinusGradient(vec2 coord)
{
    vec3	veld	= texture(iChannel1, coord / iResolution.xy).xyz;
    float	left	= texture(iChannel0,(coord + vec2(-1, 0)) / iResolution.xy).w;
    float	right	= texture(iChannel0,(coord + vec2( 1, 0)) / iResolution.xy).w;
    float	bottom	= texture(iChannel0,(coord + vec2( 0,-1)) / iResolution.xy).w;
    float	top 	= texture(iChannel0,(coord + vec2( 0, 1)) / iResolution.xy).w;
    vec2	grad 	= vec2(right - left,top - bottom) * 0.5;
    return	vec3(veld.xy - grad, veld.z);
}

float vignette(vec2 q, float v)
{
    return pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), v);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float vig = vignette(fragCoord / iResolution.xy, 0.6);
	// Euler advection
    vec2	velocity = sampleMinusGradient(fragCoord).xy;
    vec3	veld = sampleMinusGradient(fragCoord - dissipation * velocity).xyz;
    float	density = veld.z;
    velocity = veld.xy;

    vec2	uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    // Small perturbation
    vec2 detailNoise = fbm(vec3(uv*25., iTime + 30.), 7) - 0.5;
    
    // Injection
    vec2 injectionNoise = fbm(vec3(uv *1.5, iTime * 0.1 + 30.), 7) - 0.5;
    //velocity += injectionNoise * 0.1;
    density += (length(injectionNoise) * 0.004) * mix(1., vig, 1.0);
    velocity += injectionNoise * 0.01;

    // Inject emiter
    float influenceRadius = ballRadius * 2.;
    vec2 p = duckPosition(iFrame, iResolution.x / iResolution.y);
    float dist = distance(uv, p);
    if(dist < influenceRadius)
    {
        vec2 op = duckPosition(iFrame + 1, iResolution.x / iResolution.y);
        vec2 ballVelocity = p - op;
        float infuence = (influenceRadius - dist) / influenceRadius;
        density += infuence * length(ballVelocity) * 4.0;
        density = max(0., density);
        velocity += infuence * (ballVelocity * 40. + detailNoise * 4.);   
    }
        
    density = min(1., density);
    density *= 0.995;     // damp
    veld = vec3(velocity, density);
    veld *=  mix(1., vig, 0.02);
    fragColor = vec4(veld, texture(iChannel0,fragCoord / iResolution.xy).w);
}