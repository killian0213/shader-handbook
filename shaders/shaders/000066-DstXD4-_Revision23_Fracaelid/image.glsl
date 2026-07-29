// Image (image) — [Revision23] Fracaelid by EvilRyu
// https://www.shadertoy.com/view/DstXD4

vec3 tonemap(vec3 x)
{
    const float a = 2.51, b = .03, c = 2.43, d = .59, e = .14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}
 
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec3 col = texelFetch(iChannel0, ivec2(fragCoord), 0).xyz;
    col = tonemap(col);
    col = pow(col, vec3(.45));
    col = col * .6 + .4 * col * col * (3. - 2. * col);
    col *= .5 + .5 * pow(16. * uv.x * uv.y * (1. - uv.x) * (1. - uv.y), .1);
    col = pow(col, vec3(.45));
    fragColor.xyz=col;
}
