// Image (image) — Extruded Quadtree Path Tracing by gelami
// https://www.shadertoy.com/view/Dly3DW


// Extruded Quadtree Path Tracing - gelami
// https://www.shadertoy.com/view/Dly3DW

/* 
 * Shrimple path tracing of a quadtree of extruded rectangular prisms
 *   with polygonal bokeh for depth of field
 *
 * Mouse drag to look around
 * Defines in Common
 * 
 * This was originally made for an SVGF implementation
 * but its still work in progress for now,
 * so I gave it some color and we have this instead ^ - ^
 * 
 * Quadtree traversal method based from my other shader:
 * Rectangular Pillar LOD Traversal - gelami
 * https://www.shadertoy.com/view/mttGWX
 * 
 */

// Fork of "Quadtree Path Tracing SVGF" by gelami. https://shadertoy.com/view/Dly3Dh
// 2023-05-13 06:41:06

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 fc = ivec2(fragCoord);
    
    if (fc == ivec2(0, 0)) fc = ivec2(0, 1);
    if (fc == ivec2(1, 0)) fc = ivec2(1, 1);
    
    vec3 col = texelFetch(iChannel0, fc, 0).rgb;
    
    col = col / (1. + col);
    
    fragColor = vec4(linearTosRGB(col), 1);
    fragColor += (dot(hash23(vec3(fragCoord, iTime)), vec2(1)) - 0.5) / 255.;
}