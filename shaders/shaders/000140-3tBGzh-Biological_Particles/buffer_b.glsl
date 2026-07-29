// Buffer B (buffer) — Biological Particles by wyatt
// https://www.shadertoy.com/view/3tBGzh

// SPACIALLY SORT VORONOI PARTICLES
// ALLOW MOVING PARTICLES TO LEAVE A TRAIL OF CLONES
void swap (inout vec4 Q, vec2 U, vec2 r) {
	vec4 n = B(U+r);
    if (length(U-n.xy)<length(U-Q.xy)) Q = n;
}
void mainImage( out vec4 Q, in vec2 U)
{
    // FIND NEAREST PARTICLE
    Q = B(U);
    swap(Q,U,vec2(1,0));
    swap(Q,U,vec2(0,1));
    swap(Q,U,vec2(-1,0));
    swap(Q,U,vec2(0,-1));
    swap(Q,U,vec2(1,1));
    swap(Q,U,vec2(1,-1));
    swap(Q,U,vec2(-1,1));
    swap(Q,U,vec2(-1,-1));
    // LEAVE A TRIAL OF CLONES AS PARTICLE TRANSLATES
    Q.xy += A(mix(U,Q.xy,0.7)).xy;
    // BOUNDARY CONDITIONS
    if ((iMouse.z>0.&&length(iMouse.xy-U)<30.)||iFrame < 1) {
    	Q = vec4(U,0,0);
        Q.w = .1*(Q.x+R.x*Q.y+dot(iDate,vec4(1)));
    }
   
}