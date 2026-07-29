// Image (image) — The Beach - V2 by Maurogik
// https://www.shadertoy.com/view/3sy3Wy

// https://shadertoy.com/view/3tfSD7

//Music from : https://soundcloud.com/sleepmusiconthebeach/power-sleep-relaxing-piano


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;

	vec4 colour = texture(iChannel0, uv);
    
    //Smoothstep tonemapping, because why not !
    colour = smoothstep(-0.13, 1.35, colour);

    colour.rgb = safePow(colour.rgb, vec3(1.0/2.2));
    fragColor = colour;
}