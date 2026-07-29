// Buffer A (buffer) — Love and Domination by wyatt
// https://www.shadertoy.com/view/wdjGRc

vec2 R;
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
void X (vec2 U, inout vec4 Q, vec2 u) {
    vec4 p = A(U+u);//read neighbor
    if (length(p.xy - U) < length(Q.xy-U)) Q = p;
}
void mainImage( out vec4 Q, in vec2 U )
{	R = iResolution.xy;
 	Q = A(U);
 	// measure the neighborhood
 	X(U,Q,vec2(1,0)); 
 	X(U,Q,vec2(0,1));
 	X(U,Q,vec2(0,-1));
 	X(U,Q,vec2(-1,0));
 	X(U,Q,vec2(1,1));
 	X(U,Q,vec2(-1,1));
 	X(U,Q,vec2(1,-1));
 	X(U,Q,vec2(-1,-1));
	// get gradient of pheromone feild
 	// 0 : x  1 : y 2 : z
 	// x > y > z > x > y ...
 	vec4 
        n = C(U+vec2(0,1)),
        e = C(U+vec2(1,0)),
        s = C(U+vec2(0,-1)),
        w = C(U+vec2(-1,0));
        
 	vec3 dx = e.xyz-w.xyz;
 	vec3 dy = n.xyz-s.xyz;
	
 	vec2 v = vec2(0);
    if (Q.w == 0.) v = vec2(dx.z-dx.y+0.3*dx.x,dy.z-dy.y+0.3*dy.x);
    if (Q.w == 1.) v = vec2(dx.x-dx.z+0.1*dx.y,dy.x-dy.z+0.1*dy.y);
    if (Q.w == 2.) v = vec2(dx.y-dx.x+0.2*dx.z,dy.y-dy.x+0.2*dy.z);
 	if (length(v) > 0.) 
        Q.xy += normalize(v)*min(1.,SPEED*length(v));
    
    if (iFrame < 1) {
        U = floor((U)/8.)*8.+5.;
    	Q = vec4(U,1,floor(mod(-U.x/R.x*5.,3.)));
    }
 	if (iMouse.z > 0. && length(iMouse.xy-Q.xy) < MOUSE_SIZE) Q=vec4(-100,-100,0,0);
}