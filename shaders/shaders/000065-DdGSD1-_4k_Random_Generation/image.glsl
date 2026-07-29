// Image (image) — [4k] Random Generation by Kali
// https://www.shadertoy.com/view/DdGSD1

// **********************************************************
// RANDOM GENERATION by Latitude Independent Association
// **********************************************************
// The 4k executable introduce variations each time is run
// Here you can click the mouse at different points along
// the X axis to see these variations
// **********************************************************

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    fragColor = texture(iChannel0,uv);
}