// Buf B (buffer) — Frozen Barrens by knarkowicz
// https://www.shadertoy.com/view/XltGRX

// Bloom downsample

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 srcUV = 4.0 * fragCoord.xy / iResolution.xy;
    if ( srcUV.x > 1.0 || srcUV.y > 1.0 )
    {
        discard;
    }

    vec2 off = 0.7 / iResolution.xy;
    vec3 mainTap = texture( iChannel0, srcUV ).xyz;
    vec3 color = mainTap;
    color += texture( iChannel0, srcUV + vec2( +off.x, +off.y ) ).xyz;
    color += texture( iChannel0, srcUV + vec2( -off.x, +off.y ) ).xyz;
    color += texture( iChannel0, srcUV + vec2( -off.x, -off.y ) ).xyz;
    color += texture( iChannel0, srcUV + vec2( +off.x, -off.y ) ).xyz;
    
	float bloomLuminance = ( mainTap.x + mainTap.y + mainTap.z ) / 3.0 - 0.5;
	color *= clamp( bloomLuminance / 2.0, 0.0, 1.0 );
    color = clamp( color, 0.0, 100.0 );
    
    fragColor = vec4( color / 5.0, 1.0 );
}