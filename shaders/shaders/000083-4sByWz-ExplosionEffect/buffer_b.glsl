// Buf B (buffer) — ExplosionEffect by kuvkar
// https://www.shadertoy.com/view/4sByWz

/**
	Horizontal blur for glow.. I felt lazy and didn't do the vertical pass as this looks good enough.
	Sampling the texels from the corners boosts the blurring process with filtering.
	
	reference: https://www.shadertoy.com/view/Xd33Rf by IQ
*/

//gaussian weights. 
// http://dev.theomader.com/gaussian-kernel-calculator/
const float [] weights = float [] (	0.44198,	0.27901);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec3 col = vec3(0.0);
    vec2 offset = vec2(.5)/iResolution.xy;
    for (int i = 0; i < 3; ++i)
    {
        int index = abs(i-1);
        float w = weights[index];
        vec2 uv = vec2(fragCoord.xy + vec2(float(index)+0.5, 0.5))/iResolution.xy;
        vec3 cl = texture(iChannel0, uv).rgb;
        
        float f = smoothstep(0.1, .8, cl.r-cl.b);
    	col += cl*w*f;
    }
    
	fragColor.rgb = col;
}