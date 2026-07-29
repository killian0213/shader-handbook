// Image (image) — subway of the death by zguerrero
// https://www.shadertoy.com/view/llGfzc

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 path = path(iTime*5.0 + 5.5, iTime);
    path.x *= -iResolution.x/iResolution.y;
    
	vec2 uv = fragCoord.xy/iResolution.xy;
    
    vec2 uvCenter = uv - vec2(0.5) - path*0.025;
    vec2 pc;
    pc.x = atan(uvCenter.x, uvCenter.y) / 3.14159265359;
    pc.y = length(uvCenter)*2.0;
    vec2 coords = pc * vec2(2.0, 0.025) + vec2(0.0, 1.0) * iTime;
    float n = smoothstep(0.2, 1.0, texture(iChannel2, coords).x) * clamp(pc.y - 0.75, 0.0, 1.0);
    
    uv -= normalize(uvCenter) * n;
	vec4 tex = texture(iChannel0, uv);
	vec4 texblurred = texture(iChannel1, uv);
    
    vec4 col1 = pow(tex, vec4(2.0)) * 1.5 + texblurred;
    vec4 col2 = texblurred*3.0;
    float vignet = smoothstep(0.5, 1.25, pc.y);
    
	fragColor = mix(col1, col2, vignet);
}