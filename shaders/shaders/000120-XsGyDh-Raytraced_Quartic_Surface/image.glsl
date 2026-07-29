// Image (image) — Raytraced Quartic Surface by Shane
// https://www.shadertoy.com/view/XsGyDh

/*

	Raytraced Quartic Surface
	-------------------------

	Mattz's quartic solvers inspired me to put this together, and Ninjakoala's refined
	quartic solver enabled me to port it to Shadertoy. :) I coded up a generalized quartic 
	surface intersection many years ago, and didn't particularly enjoy the experience, so 
	haven't been in a hurry to port it to the pixel shader environmnet. :)
	
	For the most part, I did this for academic purposes. I like raytracing, but I find it 
	a bit limiting. It appears that everyone else does too, because raytraced triangulated 
	scenes aside, I seldom see anything more than basic primitives rendered. This is 
	understandable, since surfaces described by higher order equations require far more 
	calculation.

	For that reason, there's not a lot of raytraced quartic code out there, but now there's
	a reference on Shadertoy... I don't have a great deal of interest in it myself, but I 
	figured the raytracing crowd might find it novel having something to render other than 
	spheres and cylinders. :)

	Another reason I avoid realtime raytraced scenes is the hard shadows. With this example,
	I partly got around the problem by employing a cheap jittering trick, which I wouldn't 
	recommend, but I think I got away with it here... kind of. :)

	I applied some geometric tiling and a simple radial blur, in a half hearted attempt to 
	make up for the fact that this is a pretty uninspiring lacklustre scene. :)	

	By the way, I hurriedly hacked together the reflection\refraction loop as an 
	afterthought. It's not entirely physically accurate, since it lacks proper stack logic, 
	but other than that, it seems to be about right. However, if anyone spots any errors 
	(incorrect normal direction, calculation, etc), feel free to let me know.


 	Quartic examples:

	Ellipse / quartic - mattz
	https://www.shadertoy.com/view/4dVcR1

	Cubic bezier - Signed Distance - NinjaKoala
	https://www.shadertoy.com/view/4sKyzW

    
	Raytracing examples for grown ups. :D
	Actually, they might be raymarched, but either way. :)

	stochastic path tracer v1 - otaviogood
	https://www.shadertoy.com/view/4ddcRn


	Spectral Path Tracer Test - P_Malin
	https://www.shadertoy.com/view/4s3cRr

	



	Full Scene Radial Blur
	----------------------

	Inspired by:

	Blue Dream - Passion
	https://www.shadertoy.com/view/MdG3RD

	Radial Blur - IQ
	https://www.shadertoy.com/view/4sfGRn

	Rays of Blinding Light - mu6k
	https://www.shadertoy.com/view/lsf3Dn

*/

// The radial blur section. Shadertoy user, Passion, did a good enough job, so I've used a
// slightly trimmed down version of that. By the way, there are accumulative weighting 
// methods that do a slightly better job, but this method is good enough for this example.


// Radial blur samples. More is always better, but there's frame rate to consider.
const float SAMPLES = 32.; 


// 2x1 hash. Used to jitter the samples.
float hash( vec2 p ){ return fract(sin(dot(p, vec2(41, 289)))*45758.5453); }


// Light offset.
//
// I realized, after a while, that determining the correct light position doesn't help, since 
// radial blur doesn't really look right unless its focus point is within the screen boundaries, 
// whereas the light is often out of frame. Therefore, I decided to go for something that at 
// least gives the feel of following the light. In this case, I normalized the light position 
// and rotated it in unison with the camera rotation. Hacky, for sure, but who's checking? :)
vec3 lOff(){    
    
    //vec2 u = sin(vec2(1.57, 0) - iTime/2.);
    //mat2 a = mat2(u, -u.y, u.x);
    
    vec3 l = normalize(vec3(.5, 3., 2.5));
    //l.xz = a * l.xz;
    //l.xy = a * l.xy;
    
    return l;
    
}



void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    // Screen coordinates.
    vec2 uv = fragCoord.xy / iResolution.xy;

    // Radial blur factors.
    //
    // Falloff, as we radiate outwards.
    float decay = 0.925; 
    // Controls the sample density, which in turn, controls the sample spread.
    float density = 0.7; 
    // Sample weight. Decays as we radiate outwards.
    float weight = 0.05; 
    
    // Light offset. Kind of fake. See above.
    vec3 l = lOff();
    
    // Offset texture position (uv - .5), offset again by the fake light movement.
    // It's used to set the blur direction (a direction vector of sorts), and is used 
    // later to center the spotlight.
    //
    // The range is centered on zero, which allows the accumulation to spread out in
    // all directions. Ie; It's radial.
    vec2 tuv =  uv - .5 - l.xy*.45;
    
    // Dividing the direction vector above by the sample number and a density factor
    // which controls how far the blur spreads out. Higher density means a greater 
    // blur radius.
    vec2 dTuv = tuv*density/SAMPLES;
    
    // Grabbing a portion of the initial texture sample. Higher numbers will make the
    // scene a little clearer and brighter.
    vec4 col = texture(iChannel0, uv.xy)*0.5;
    
    // Jittering, to get rid of banding. Vitally important when accumulating discontinuous 
    // samples, especially when only a few layers are being used.
    uv += dTuv*(hash(uv.xy + fract(iTime))*2. - 1.);
    
    // The radial blur loop. Take a texture sample, move a little in the direction of
    // the radial direction vector (dTuv) then take another, slightly less weighted,
    // sample, add it to the total, then repeat the process until done.
    for(float i=0.; i < SAMPLES; i++){
    
        uv -= dTuv;
        col += texture(iChannel0, uv) * weight;
        weight *= decay;
        
    }
    
    
    // Vignette.
    uv = fragCoord/iResolution.xy;
    //col = mix(col, col.xzyw, uv.y);
    col = mix(col, vec4(0), (1. - pow(16.*uv.x*uv.y*(1.-uv.x)*(1.-uv.y), 0.25)));

    
    // Multiplying the final color with a spotlight centered on the focal point of the radial
    // blur. It's a nice finishing touch... that Passion came up with. If it's a good idea,
    // it didn't come from me. :)
    //col *= (1. - dot(tuv, tuv)*.75);
    
    // Smoothstepping the final color, just to bring it out a bit more.
    //col = smoothstep(0., .5, col);
    
    // Bypassing the radial blur to show the scene on its own.
    //fragColor = sqrt(texture(iChannel0, fragCoord.xy / iResolution.xy));
    
    fragColor = sqrt(mix(max(col, 0.), texture(iChannel0, fragCoord.xy / iResolution.xy), .5));
}

