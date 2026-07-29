// Image (image) — Refractive Index by NuSan
// https://www.shadertoy.com/view/fljGWV

// Coded live during livecode.demozoo.org Release Party
// on https://www.twitch.tv/psenough
// comments have been added after the live and code is a bit cleanner
// original file is here: https://lezanu.fr/LiveCode/RefractiveIndex.glsl

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec3 col=texture(iChannel0, fragCoord.xy / iResolution.xy).xyz;
  
      col=smoothstep(0.01,0.9,col);
      col=pow(col, vec3(0.4545));
  
	fragColor = vec4(col, 1);
}