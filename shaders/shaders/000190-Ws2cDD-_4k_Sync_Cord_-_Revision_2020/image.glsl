// Image (image) — [4k] Sync Cord - Revision 2020 by NuSan
// https://www.shadertoy.com/view/Ws2cDD

// if sound doesn't start or seems desynchronised:
// try clicking pause/start button in the "soundcloud" square in the bottom right
// then press rewind just under the shader picture on the left

/*
----     Sync Cord     ----
---- by NuSan & Valden ----

4th place at Revision 2020 - PC 4k intro

NuSan: Concept, visual, code
Valden: Music

Original Tools: Leviathan 2.0, 4klang, Shader Minifier

https://www.pouet.net/prod.php?which=85222
https://www.youtube.com/watch?v=f3VSeLyooXA
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    	
	vec2 uv=fragCoord.xy/iResolution.xy;
	vec4 value = texture(iChannel0, uv);
	vec3 col = value.xyz;

   	float time=iTime+StartOffset;
    // bloom
    // take random samples in a disk
	vec3 a0=rnd23(gl_FragCoord.xy+fract(time));
    for(int i=0; i<25; ++i) {
		float an = (float(i/5)+a0.x)*1.25;
		float ad = float(i%5)+1.+a0.y;
		vec4 cur = texture(iChannel0, uv + vec2(cos(an),sin(an)) * ad*ad * 6./iResolution.xy);
        // we use a threshold to only bloom very bright parts
		col += cur.xyz * smoothstep(.8,1.,dot(cur.xyz,vec3(.33))) * .05;
    }

    // super basic tone mapping
    col=pow(smoothstep(0.,1.,col), vec3(0.4545));
    
    // fade in at the beginning
	col*=c01((time-2.8)*2.);
    // fade out at the end
    col*=c01((118.6-time)*.35);
	
	fragColor = vec4(col,1.);
}