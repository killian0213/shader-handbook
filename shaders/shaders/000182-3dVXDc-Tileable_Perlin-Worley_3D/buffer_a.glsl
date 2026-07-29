// Buffer A (buffer) — Tileable Perlin-Worley 3D by piyushslayer
// https://www.shadertoy.com/view/3dVXDc

/**
This buffer writes the tileable 3D noise to a texture. 
*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 m = iMouse.xy / iResolution.xy;

    vec4 col = vec4(0.);
    
    float slices = 128.; // number of layers of the 3d texture
    float freq = 4.;
    
    float pfbm= mix(1., perlinfbm(vec3(uv, floor(m.y*slices)/slices), 4., 7), .5);
    pfbm = abs(pfbm * 2. - 1.); // billowy perlin noise
    
    col.g += worleyFbm(vec3(uv, floor(m.y*slices)/slices), freq);
    col.b += worleyFbm(vec3(uv, floor(m.y*slices)/slices), freq*2.);
    col.a += worleyFbm(vec3(uv, floor(m.y*slices)/slices), freq*4.);
    col.r += remap(pfbm, 0., 1., col.g, 1.); // perlin-worley
    
    fragColor = vec4(col);
}