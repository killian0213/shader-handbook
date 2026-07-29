// Image (image) — Branching Paths by wyatt
// https://www.shadertoy.com/view/ts33DS

#define R iResolution.xy
#define A(U) texture(iChannel0,(U)/R)
vec4 X (inout vec2 c, vec2 u, vec2 r) {
    vec4 n = A(u+r);
	if (length(u+r-n.xy)<length(u-c)) c = n.xy;
    return n;
} 
void mainImage( out vec4 Q, vec2 U )
{
    vec4 a = A(U);
    vec2 c = Q.xy;
    vec4 
        n = X(c,U,+vec2(0,1)),
        e = X(c,U,+vec2(1,0)),
        s = X(c,U,-vec2(0,1)),
        w = X(c,U,-vec2(1,0)),
        m = 0.25*(n+e+s+w);
 	vec3 g = normalize(vec3(e.z-w.z,n.z-s.z,.3));
    g = reflect(g,vec3(0,0,1));
 	vec3 b = normalize(vec3(e.w-w.w,n.w-s.w,1));
    float d = dot(g,normalize(vec3(0,1,.5)));
    Q = (exp(-4.*d*d))*m.w*abs(sin(2.+vec4(1,2,3,4)*(1.+2.*m.z)));

    Q = .8+.2*g.x-.8*(1.+0.5*(b.x+b.y)) * a.w * sin(2.+0.5*(g.z)*vec4(1,2,3,4));
}