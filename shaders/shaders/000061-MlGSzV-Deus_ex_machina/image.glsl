// Image (image) — Deus ex machina by nimitz
// https://www.shadertoy.com/view/MlGSzV

// Deus ex machina by nimitz (twitter: @stormoid)
// https://www.shadertoy.com/view/MlGSzV
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

/*
	Base idea inspired by numberphile's "Sandpiles" video
	https://www.youtube.com/watch?v=1MtEUErz7Gg

	Some of the main differences are that the numbers are encoded as
	floating point, that the "piles" have 8 neighbors and that the values
	are clamped

	The initial condition is just a completely uniform plane, all the
	complexity is created from the rule itself (and the boundary conditions)

	Unrelated: Am I the only one who gets very noticeable rendering speed variation
	with this shader? (this began when shadertoy moved to WebGL 2.0) It tends to oscillate
	between 30 fps and 60 fps
*/

#define time iTime

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    
    vec2 p = q-0.5;
    float r = sqrt(length(p));
    p *= .91 + r*0.11;
    q = p+0.5;
    
    vec4 tex = texture(iChannel0, q);
    
    float rz = tex.x;
    
    vec3 col = sin(vec3(1,2,3) + rz +0.)*0.5+0.5;
    
    col = tex.yzw;
    col = clamp(col,0.,1.);
    
    vec2 p2 = p*=1.85;
    p2*=p2; p2*=p2; p2*=p2;
    col *= 1.2-pow(length(p2)*1.3,.4);
    col = clamp(col,0.,1.);
    
    col = pow(col, vec3(.8));
    col = smoothstep(0.,1.,col);
    col *= smoothstep(-1.,-0.9, sin(gl_FragCoord.y*3.14159265*.5 + 0.5))*0.1+1.;
    col *= smoothstep(-1.,-0.9, sin(gl_FragCoord.x*3.14159265*.5 + 0.5))*0.1+1.;
    
    fragColor = vec4(col, 1.);
}