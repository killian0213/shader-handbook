// Buf B (buffer) — Photon's journey by zguerrero
// https://www.shadertoy.com/view/4tK3Wd

float sampleDistance = 0.05;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy - vec2(0.5);
	
    vec4 col = vec4(0.0);
    for(int i = 0; i < 4; i++)
    {
        
        col += texture(iChannel0, uv/(1.0 + float(i)*sampleDistance) + vec2(0.5));
    }
    
    col /= 4.0;
    
    fragColor = col;
}