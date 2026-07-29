// Image (image) — Alien corridor by zguerrero
// https://www.shadertoy.com/view/4slyRs

//bloom & vignet effect

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{ 
    vec2 uv =  fragCoord.xy/iResolution.xy;
   
    vec4 tex = texture(iChannel1, uv);
    vec4 texBlurred = texture(iChannel0, uv);
    float vignet = length(uv - vec2(0.5))*1.5;
        
	fragColor = mix(tex, texBlurred*texBlurred, vignet) + texBlurred*texBlurred*0.5;
}