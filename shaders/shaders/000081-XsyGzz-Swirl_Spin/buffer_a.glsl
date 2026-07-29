// Buf A (buffer) — Swirl Spin by TekF
// https://www.shadertoy.com/view/XsyGzz

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
//    fragColor = texture(iChannel0, (floor( (fragCoord*.98 + iResolution.xy*.01 + (fragCoord-iResolution.xy/2.).yx*vec2(-.03,.03)) )+.5) / iResolution.xy);
    fragColor = texture(iChannel0, (fragCoord*.98 + iResolution.xy*.01 + (fragCoord-iResolution.xy/2.).yx*vec2(-.03,.03)) / iResolution.xy);
    
    float t = iTime*.5;

    vec4 col = vec4(sin(t*vec3(13,11,17))*.5+.5,1);
    float idx = .0+1.0*smoothstep( 6., 20., length( fragCoord - sin(vec2(11,13)*t)*60. - iResolution.xy/2. ) );
    fragColor = mix( col, fragColor, idx );
}