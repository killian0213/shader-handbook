// Buffer A (buffer) — Dry ice by xjorma
// https://www.shadertoy.com/view/3d3fRB

// Created by David Gallardo - xjorma/2020
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

vec3 sampleMinusGradient(vec2 coord)
{
    vec3	veld	= texture(iChannel1, coord / iResolution.xy).xyz;
    float	left	= texture(iChannel0,(coord + vec2(-1, 0)) / iResolution.xy).x;
    float	right	= texture(iChannel0,(coord + vec2( 1, 0)) / iResolution.xy).x;
    float	bottom	= texture(iChannel0,(coord + vec2( 0,-1)) / iResolution.xy).x;
    float	top 	= texture(iChannel0,(coord + vec2( 0, 1)) / iResolution.xy).x;
    vec2	grad 	= vec2(right - left,top - bottom) * 0.5;
    return	vec3(veld.xy - grad, veld.z);
}

vec3 vignette(vec3 color, vec2 q, float v)
{
    color *= 0.99 + 0.01 * pow(16.0 * q.x * q.y * (1.0 - q.x) * (1.0 - q.y), v);
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// Euler advection
    vec2	velocity = sampleMinusGradient(fragCoord).xy;
    vec3	veld = sampleMinusGradient(fragCoord - dissipation * velocity).xyz;
    float	density = veld.z;
    velocity = veld.xy;


    vec2	uv = (2. * fragCoord - iResolution.xy) / iResolution.y;
    
    // Inject emiter
    
    for(int i = 0 ; i < nbSphere ; i++)
    {
        vec2 p = rotate(float(i) * tau / float(nbSphere) + iTime * 0.2, 0.8);
        float dist = distance(uv, p);
        if(dist < ballRadius)
        {
            density += ((ballRadius - dist) / ballRadius) * 0.20;
            density = min(density, 1.);
         	velocity = normalize(-p) * 3.;   
        }
        
    }	    
    
    // damp
    //d *= 0.999;  
    fragColor = vec4(vignette(vec3(velocity, density), fragCoord / iResolution.xy, 1.), 1);
}