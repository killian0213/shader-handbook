// Image (image) — maze worms / graffitis 3c by FabriceNeyret2
// https://www.shadertoy.com/view/Xs2cRD

void mainImage( out vec4 O, vec2 U )
{
    O = texture(iChannel0, U/iResolution.xy);
}