// Image (image) — My dark land by iapafoto
// https://www.shadertoy.com/view/ll2BWm



void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor = mix(texture(iChannel0, fragCoord/iResolution.xy),
                    texture(iChannel1, fragCoord/iResolution.xy), smoothstep(31., 30., iTime) /* smoothstep(200., 199., iTime)*/);
}