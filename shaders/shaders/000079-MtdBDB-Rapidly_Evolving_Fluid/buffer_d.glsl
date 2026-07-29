// Buffer D (buffer) — Rapidly Evolving Fluid by wyatt
// https://www.shadertoy.com/view/MtdBDB

vec2 R;float N;// R is resolution, N is number of samples
vec4 T ( vec2 U ) {return texture(iChannel0,U/R);}//Samples previous field state
float X (vec2 U0, vec2 U, vec2 U1, inout vec4 Q, in vec2 r) {
    vec2 V = U + r, u = T(V).xy,
         V0 = V - u,
         V1 = V + u;
    float P = T (V0).z, rr = length(r);
    Q.xy -= r*(P-Q.z)/rr/N;
    return (0.5*(length(V0-U0)-length(V1-U1))+P)/N;
    /* This is the interaction function
		U1 is my current position
		U is my previous position
		Q is my previous state
		r is the relativity between me and my neighbor
    	V1 is my neighbor's current position
		V is my neighbor's previous position
		P is my neighbors pressure
		Q.z is my previous pressure
		rr is the distance between me and my neighbor
		r*(P-Q.z)/rr/N is this interaction's contribution
			to the my velocity. It is the gradient of
			the pressure between me and my neighbor
		length(V0-U0)-length(V1-U1) is the space contraction between
			the next and the previous state. Because pressure
			is energy per volume. If the volume contracts
			there must be a higher energy density. If
			the space expands, the energy is disipated
			over a larger area.
		I add P because I completely trade pressures 
			with my neighbors. This is why the best
			sampling patterns are like checkerboards.
			every other point in space should interact
			so that there is a feedback system.
			The physical explanation of this is that
			the fluid is kind of like many billiards
			balls. When two billiards balls collide,
			they completely swap energies.
		I divide the outputs by N to average each interaction.
    */
}

void mainImage( out vec4 Q, in vec2 U )
{   R = iResolution.xy;
 	vec2 U0 = U - T(U).xy, // get previous state
         U1 = U + T(U).xy; // get next state
 	float P = 0.; Q = T(U0);
 	N = 4.;// checkerboard sampling pattern
    P += X (U0,U,U1,Q, vec2( 1, 0) );
 	P += X (U0,U,U1,Q, vec2( 0,-1) );
 	P += X (U0,U,U1,Q, vec2(-1, 0) );
 	P += X (U0,U,U1,Q, vec2( 0, 1) );
 	Q.z = P;
 	
 	// Init and Walls
 	if (iFrame < 1) Q = vec4(0);
    if (U.x < 1.||U.y < 1.||R.x-U.x < 1.||R.y-U.y < 1.) Q.xy *= 0.;
    //This Jet setup will cause pressure to always increase in the system
 	if (length(U-vec2(0,0.5*R.y)) < 4.) {Q.xy= Q.xy*.9+.1*vec2(.8,0);; Q.w = 1.;}
    if (length(U-vec2(R.x,0.5*R.y)) < 4.) {Q.xy= Q.xy*.9+.1*vec2(-.8,0);; Q.w = 1.;}
}