// Image (image) — exploding blobs by lomateron
// https://www.shadertoy.com/view/slcGRX

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 u = fragCoord/iResolution.xy;
    vec4 a = texture(iChannel0,u);
    fragColor = a.z+a.z*sin(length(a.xy)+vec4(1,2,3,4)+0.);
}