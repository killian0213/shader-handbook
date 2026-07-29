// Buf C (buffer) — Pseudofluidfade by noby
// https://www.shadertoy.com/view/MdSBzm

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
	vec2 uv = fragCoord.xy / iResolution.yy;
    fragColor  = mix(vec4(0), vec4(1,0,0,1), pow( (0.5+0.5*sin(uv.y*120.0)),99.));
    fragColor *= mix(vec4(0), vec4(1,0,0,1), pow( (0.5+0.5*sin(uv.x*120.0)),99.));
}