// Image (image) — Organic Dodecahedron by lsdlive
// https://www.shadertoy.com/view/wd3GWM

/*
@lsdlive
CC-BY-NC-SA

Organic Dodecahedron.

Alpha-blending volumetric algorithm inspired from:
"Cloudy spikeball" by Duke (& las): https://www.shadertoy.com/view/MljXDw
"Pyroclastic explosion" by simesgreen: https://www.shadertoy.com/view/XdfGz8


Some notation:
p: position (usually in world space)
rd: ray direction (eye or view vector)
*/


// Radial blur postfx from XT95:
// https://github.com/XT95/VisualLiveSystem/blob/master/release/data/postFX/green-pink%20blur.glsl

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;

    float amt_blur = 45.;
	float amt_dist = 50.;
    
	vec2 offset =  normalize(uv-.5)*pow(length(uv-.5),4.)/amt_blur;
	vec2 offset2 = (uv-.5)/amt_dist;
	vec3 col = vec3(0.);
	for(int i=0; i<16; i++)
	{
		//RGB distortion
		col.r += texture(iChannel0,uv+offset*float(i)+offset2).r;
		col.g += texture(iChannel0,uv+offset*float(i)).g;
		col.b += texture(iChannel0,uv+offset*float(i)-offset2).b;
	}
	col /= 16.; // box blur
    
    // vignetting
    col *= 0.5 + 0.5*pow(16.0*uv.x*uv.y*(1.0 - uv.x)*(1.0 - uv.y), 0.25);
    
    fragColor.rgb = col;
	fragColor.a = 1.;
}