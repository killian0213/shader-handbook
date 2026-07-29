// Image (image) — Nebula Explained by Xor
// https://www.shadertoy.com/view/DlySDD

/*
    Explanation for "Nebula":
    https://twitter.com/XorDev/status/1666179395260694529
*/

void mainImage(out vec4 color, vec2 coord)
{
    vec3 res = iResolution;
    //Output Buf A
    color = texture(iChannel0, coord/res.xy);
}