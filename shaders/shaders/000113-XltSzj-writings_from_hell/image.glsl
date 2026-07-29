// Image (image) — writings from hell by flockaroo
// https://www.shadertoy.com/view/XltSzj

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// just a dummy shader because i needed some feedback of own color (not possible in image tab)
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texture(iChannel0,fragCoord.xy/iResolution.xy);
}
