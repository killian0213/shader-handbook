// Image (image) — Montecarlo PDE (1) by iq
// https://www.shadertoy.com/view/WsXBzl

// Playing with Keenan Crane's latest paper in collab with
// Rohan Sawhney: http://www.cs.cmu.edu/~kmcrane/Projects/MonteCarloGeometryProcessing/paper.pdf[/url]
//
// See https://www.shadertoy.com/view/WdXfzl for a more complex example

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 data = texelFetch(iChannel0,ivec2(fragCoord),0);
    fragColor = vec4(data.xyz/data.w, 1.0 );
}