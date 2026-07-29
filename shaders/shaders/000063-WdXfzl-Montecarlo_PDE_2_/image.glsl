// Image (image) — Montecarlo PDE (2) by iq
// https://www.shadertoy.com/view/WdXfzl

// Playing with Keenan Crane's latest paper in collab with
// Rohan Sawhney: http://www.cs.cmu.edu/~kmcrane/Projects/MonteCarloGeometryProcessing/paper.pdf[/url]
//
// Used contour lines from https://www.shadertoy.com/view/XdKGDW
//
// See https://www.shadertoy.com/view/WsXBzl for a simpler example
//
// Change the define in line 397 of "Buffer A" in order to see the
// actual color contour curves.

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 data = texelFetch(iChannel0,ivec2(fragCoord),0);
    fragColor = vec4(data.xyz/data.w, 1.0 );
}