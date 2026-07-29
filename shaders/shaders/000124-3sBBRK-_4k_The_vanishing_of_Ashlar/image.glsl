// Image (image) — [4k] The vanishing of Ashlar by NuSan
// https://www.shadertoy.com/view/3sBBRK

// The vanishing of Ashlar by NuSan
// PC 4k intro made for Outline Online 2020

// Unfortunately, the GPU Synthesizer I made cannot be ported on shadertoy, as it uses a second audio pass to compute reverbs
// So only soundcloud for now ...

// Original Tools: Leviathan, custom GPU synth based on Oidos, Shader Minifier, Crinkler
// https://www.pouet.net/prod.php?which=85684
// https://youtu.be/lAvug7LKiIE

// if sound doesn't start or seems desynchronised:
// try clicking pause/start button in the "soundcloud" square in the bottom right
// then press rewind just under the shader picture on the left

///////////////////////
// POST PROCESS PASS //
///////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec3 col = texture(iChannel0, uv).xyz;

    float time = iTime - .9;
    
    // Bloom computation
    vec3 cumul = vec3(0);
	for(float i=-2.; i<=2.5; ++i) {
		for(float j=-2.; j<=2.5; ++j) {
			vec4 cur = textureLod(iChannel1, uv + (vec2(i,j))*36./vec2(1920.,1080.), iResolution.y>720. ? 6. : 4.);
			cumul += cur.xyz;
		}
	}
    // use more bloom for brighter values
	col += cumul * clamp(dot(cumul.xyz,vec3(.01))-.2,0.,1.)*0.1;
    
    // 'tone mapping'
    col = smoothstep(0.,1.,col);
    col = pow(col,vec3(.6));
    
    // fade in / fade out
    col *= sat(time*2.) * sat(127.-time);
    
    fragColor = vec4(col, 1);
}