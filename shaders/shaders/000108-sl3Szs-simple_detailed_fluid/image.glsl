// Image (image) — simple detailed fluid by lomateron
// https://www.shadertoy.com/view/sl3Szs

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 u = fragCoord/iResolution.xy;
    vec4 a = texture(iChannel0,u);
    fragColor = a.z*(+sin(a.x*4.+vec4(1,3,5,4))*.2
                     +sin(a.y*4.+vec4(1,3,2,4))*.2+.6);
}