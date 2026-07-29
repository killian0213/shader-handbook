// Buffer A (buffer) — Swiss Alps by piyushslayer
// https://www.shadertoy.com/view/ttcSD8

/**
  Buffer A generates Perlin-Worley and Worley fbm noises used for modeling clouds
  in buffer C. This buffer only writes to texture at the beginning or whenever the
  viewport resolution is changed.
*/

bool resolutionChanged() {
    return int(texelFetch(iChannel1, ivec2(0), 0).r) != int(iResolution.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if (resolutionChanged())
    {
        vec2 uv = fragCoord / iResolution.xy;
        vec4 col = vec4(0.);
        col.r += perlinFbm(vec3(uv, .4), 4., 15) * .5;
        col.r = abs(col.r * 2. - 1.);
        col.r = remap(col.r,  worleyFbm(vec3(uv, .2), 4., true) - 1., 1., 0., 1.);
        col.g += worleyFbm(vec3(uv, .5), 8., true) * .625 + 
            	 worleyFbm(vec3(uv, .5), 16., true) * .25  +
            	 worleyFbm(vec3(uv, .5), 32., true) * .125;
        col.b = 1. - col.g;
        fragColor = col;
    }
    else
    {
		fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);   
    }
}