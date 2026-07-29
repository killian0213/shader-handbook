// Image (image) — Long Way From Home by yx
// https://www.shadertoy.com/view/tly3z3

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy/iResolution.xy;
    vec4 tex = texture(iChannel0,uv);
    
    // divide by sample-count
	vec3 color = tex.rgb/tex.a;
    
    #if !GRADING
    fragColor.rgb=color;return;
    #endif
    
	// vignette to darken the corners
	uv-=.5;
	color *= mix(vec3(.6,.9,1),vec3(1),1.-dot(uv,uv)*.75);

	// exposure
	color *= 2.5;

	// tonemap
	color /= color+1.;

	// gamma correction
	color = pow(color, vec3(.45));

	// grading
	{
		// make it pop
		color = smoothstep(.3,1.,color);

		// cold tint
		color = pow(color,vec3(1,1.05,1.1).bgr);
	}
	    
	fragColor = vec4(color,1);
}