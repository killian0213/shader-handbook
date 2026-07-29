// Common (common) — happy bouncing variation 1 by leon
// https://www.shadertoy.com/view/ftGXR1


// Inigo Quilez
// https://iquilezles.org/articles/distfunctions2d
float sdArc( in vec2 p, in float ta, in float tb, in float ra, float rb )
{
    vec2 sca = vec2(sin(ta),cos(ta));
    vec2 scb = vec2(sin(tb),cos(tb));
    p *= mat2(sca.x,sca.y,-sca.y,sca.x);
    p.x = abs(p.x);
    float k = (scb.y*p.x>scb.x*p.y) ? dot(p,scb) : length(p);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

// snippets
#define fill(sdf) (smoothstep(.001, 0., sdf))
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }
float circle (vec2 p, float size)
{
    return length(p)-size;
}