// Image (image) — veinss by lomateron
// https://www.shadertoy.com/view/fldXRH

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 u = fragCoord/iResolution.xy;
    vec4 a = texture(iChannel0,u);
    fragColor =+sin(a.x*4.+vec4(1,3,5,4))*.25
               +sin(a.y*4.+vec4(1,3,2,4))*.25
               +.5;
}