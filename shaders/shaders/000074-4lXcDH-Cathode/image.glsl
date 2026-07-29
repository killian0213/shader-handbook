// Image (image) — Cathode by nimitz
// https://www.shadertoy.com/view/4lXcDH

//Cathode by nimitz (twitter: @stormoid)
//2017 nimitz All rights reserved

/*
	CRT simulation shadowmask style, I also have a trinitron version
	optimized for 4X scaling on a ~100ppi display.

	The "Scanlines" seen in the simulated picture are only a side effect of the phoshor placement
	and decay, instead of being artificially added on at the last step.

	I have done some testing and it performs especially well with "hard" input such a faked
	(dither based) transparency and faked specular highlights as seen in the bigger sprite.
	A version tweaked and made for 4k displays could look pretty close to the real thing.
*/

//Phosphor decay
float decay(in float d)
{
    return mix(exp2(-d*d*2.5-.3),0.05/(d*d*d*0.45+0.055),.65)*0.99;
}

//Phosphor shape
float sqd(in vec2 a, in vec2 b)
{
    a -= b;
    a *= vec2(1.25,1.8)*.905;
    float d = max(abs(a.x), abs(a.y));
    d = mix(d, length(a*vec2(1.05, 1.))*0.85, .3);
    return d;
}

vec3 phosphors(in vec2 p, sampler2D tex)
{   
    vec3 col = vec3(0);
    
    for(int i=-2;i<=2;i++)
    for(int j=-2;j<=2;j++)
    {
        vec2 tap = floor(p) + 0.5 + vec2(i,j);
		vec3 rez = texture(tex, tap/iChannelResolution[0].xy).rgb; //nearest neighbor
        
		//center points
        float rd = sqd(tap, p + vec2(0.0,0.2));//distance to red dot
		const float xoff = .25;
        float gd = sqd(tap, p + vec2(xoff,.0));//distance to green dot
        float bd = sqd(tap, p + vec2(-xoff,.0));//distance to blue dot
		
        rez = pow(rez,vec3(1.1))*1.05;
        rez.r *= decay(rd);
        rez.g *= decay(gd);
        rez.b *= decay(bd);
		
        col += rez;
    }
    return col;
}

vec3 nearest(in vec2 p, sampler2D tex)
{
    p -= 0.25;
    return texture(tex, (floor(p) + 0.5)/iChannelResolution[0].xy).rgb;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = fragCoord.xy/iResolution.xy;
    vec2 f = fragCoord.xy;
    
    vec3 col = phosphors(fragCoord.xy/4.0, iChannel0);
    if (f.y > 200.)
        col = phosphors(fragCoord.xy/4.0 - vec2(0,30.), iChannel1);
    
    if (f.x > 265.)
    {
        col = texture(iChannel0, p/4. + vec2(-70./iResolution.x,0)).rgb;
        if (f.y > 200.)
            col = texture(iChannel1, p/4. - vec2(70, 30)/iResolution.xy).rgb;
    }
    
    if (f.x > 530.)
    {
        col = nearest(fragCoord.xy/4.0 - vec2(137,0), iChannel0).rgb;
        if (f.y > 200.)
    		col = nearest(fragCoord.xy/4.0 - vec2(137,29), iChannel1).rgb;
    }
    
    
    col = min(col, smoothstep(0.,2., abs(f.x-266.0)));
    col = min(col, smoothstep(0.,2., abs(f.x-531.)));
    
	fragColor = vec4(col, 1.0);
}