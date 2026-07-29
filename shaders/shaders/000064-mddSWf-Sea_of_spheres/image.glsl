// Image (image) — Sea of spheres by z0rg
// https://www.shadertoy.com/view/mddSWf

// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;

    vec3 rgb = texture(iChannel0, uv).xyz;
    fragColor = vec4(rgb,1.0);
}