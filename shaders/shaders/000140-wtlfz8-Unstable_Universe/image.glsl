// Image (image) — Unstable Universe by julianlumia
// https://www.shadertoy.com/view/wtlfz8


#define T(uv) texture(iChannel0,uv)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord/iResolution.xy);

    
    float f = length(uv  - 0.6);
    fragColor.x = T(uv + f*0.001).x;
    fragColor.y = T(uv -f*0.002).y;
    fragColor.z = T(uv-f*0.001).z;
}