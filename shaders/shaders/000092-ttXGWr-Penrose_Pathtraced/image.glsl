// Image (image) — Penrose Pathtraced by yx
// https://www.shadertoy.com/view/ttXGWr

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
	vec2 uv=gl_FragCoord.xy/iResolution.xy;
    vec4 tex=texture(iChannel0,uv);
    
    // divide by sample-count and multiply by exposure
	vec3 color=tex.rgb*1.2/tex.a;
    
    // vignette to lighten the corners
	uv-=.5;
	color += dot(uv,uv)*.5;
    
    // gamma correction and a slight blue color grading
	color=pow(color, .45*vec3(1.2,1.1,1));
    
	fragColor.rgb=color;
}