// Image (image) — Matte compositing by iq
// https://www.shadertoy.com/view/XsfGzn

// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


#define METHOD 2  // try method 1 and method 2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 q = fragCoord.xy / iResolution.xy;
    
	vec3 bg = texture( iChannel0, q ).xyz;
	vec3 fg = texture( iChannel1, q ).xyz;
	
    
    float maxrb = max( fg.r, fg.b );
    float k = clamp( (fg.g-maxrb)*5.0, 0.0, 1.0 );
    
#if METHOD==1
    
	float ll = length( fg );
    fg.g = min( fg.g, maxrb*0.8 );
    fg = ll*normalize(fg);

#else    

    float dg = fg.g; 
    fg.g = min( fg.g, maxrb*0.8 ); 
    fg += dg - fg.g;

#endif

    fragColor = vec4( mix(fg, bg, k), 1.0 );
}
