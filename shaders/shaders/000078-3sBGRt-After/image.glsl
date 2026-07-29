// Image (image) — After... by Dave_Hoskins
// https://www.shadertoy.com/view/3sBGRt

// After...
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//----------------------------------------------------------------------------------------
void mainImage( out vec4 colour, in vec2 coord )
{
    vec2 q = coord / iResolution.xy;
    
    vec3 col  = min(texture(iChannel0, q)*1.4, 1.0).xyz;			// ...Brightness.
    col  = col*col*(3.0-2.0*col)*1.2;					  				// ...Contrast.
    col *= 0.6 + 0.6*pow( 100.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.6);  // ...Vignette.
    col *= smoothstep(.0,4.0, iTime);								// ...Fade in.
    colour = vec4(min(sqrt(col),1.0),1.);								// ...Gamma and alpha 1 out.
  
}