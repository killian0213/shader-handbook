// Buffer A (buffer) — Interactive Fluid Simulation by wyatt
// https://www.shadertoy.com/view/XtGcDK

/*
	So how this works makes total sense in my head, but
	its a little difficult to describe coherently

	I have been thinking about how to make a fluid for a long time.
	I came up with this algorithm by thinking about particles and waves
	and how they work together and are kind of the same thing

	so particles are like discritizations of a wave
	and waves are like large sums of particles
	that create a continuum of information

	the pressure in the feild is like a wave.
	it stores energy when the space contracts 
	and releases that energy when the space expands
    
	a particle would experience an acceleraton down
    the slope of the wave just as a surfer would

	as the particles accelerate in the direction of the wave
	they may start to move together or move apart
	this affects the divergence/contraction of the space
	
	this way there is a feedback between the wave-like characteristics
    of the space and the particle-like characteristics of the space

	so I simulate a neighborhood of 5 particles and discern 
    how their interactions will predict the contraction of the space

	then I accelerate the central particle in the direction of the
	pressure gradient which is found by measuring the pressure of 
	each neighbor particle and doing a spacial derivative of these pressures

*/

vec2 R;
float ln (vec2 p, vec2 a, vec2 b) { // returns distance to line segment for mouse input
    return length(p-a-(b-a)*clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.));
}
vec4 T ( vec2 U ) {return texture(iChannel0,U/R);} // samples fluid
void mainImage( out vec4 Q, in vec2 U )
{   R = iResolution.xy;
 	// U A B C D are locations of particles that make a square with U in the middle
 	vec2 O = U,A = U+vec2(1,0),B = U+vec2(0,1),C = U+vec2(-1,0),D = U+vec2(0,-1);
 	// u a b c d are states of particles at there respective locations as per the fluid information feild
 	vec4 u = T(U), a = T(A), b = T(B), c = T(C), d = T(D);
 	// p is going to be the particle interaction force from a b c and d on u
 	vec4 p;
 	// g is going to be the average force of the pressure gradient on particle u
 	vec2 g = vec2(0);
 	// we iterate twice to advect the fluid and sum particle and wave forces
 	#define I 2
 	for (int i = 0; i < I; i++) {
        // here we increment the position of each particle by the velocity at that particle's location
        U -=u.xy; A -=a.xy; B -=b.xy; C -=c.xy; D -=d.xy; 
        // here we add the particle force which is just the change in the distance between the particles
        p += vec4(length(U-A),length(U-B),length(U-C),length(U-D))-1.;
        // here we add the wave force which is just the gradient of the pressure
        g += vec2(a.z-c.z,b.z-d.z);
        // here we update the state of each particle based on its new location
        u = T(U);a = T(A); b = T(B); c = T(C); d = T(D);
 	}   
 	// here we make the output equal to the previous state of the particle 
 	Q = u; // which is the state of particle u
 	vec4 N = 0.25*(a+b+c+d);// average the neighbor particles to calculate laplacian
 	Q = mix(Q,N, vec4(0,0,1,0)); // blend output with neighbors (just the pressure is blended)
 	Q.xy -= g/10./float(I); // add the wave force (gradient of the pressure) to the velocity
 	Q.z += (p.x+p.y+p.z+p.w)/10.; // add the particle force to the pressure of the output
 	
 	
 	// for some reason the pressure slowly builds, this is just like a pressure release
 	Q.z *= 0.9999;
    // get mouse pos and prev pos from buffer D
 	vec4 mouse = texture(iChannel1,vec2(0.5));
 		// find distance to line segment that is from mouse start to mouse end
        float q = ln(U,mouse.xy,mouse.zw);
        vec2 m = mouse.xy-mouse.zw;
        float l = length(m);
        if (mouse.z>0.&&l>0.) {
            // accelerate fluid and add ink
            Q.xyw = mix(Q.xyw,vec3(-normalize(m)*min(l,20.)/25.,1.),max(0.,5.-q)/25.);
        }
 
 	// init zeros
 	if (iFrame < 1) Q = vec4(0);
 	// add some ink and velocity to the middle of the screen
 	if (iFrame < 14 && length(U-0.5*R) < 20.) Q.xyw = vec3(0,.1,1);
 	// bound the edges and make them still
 	if (U.x<1.||U.y<1.||R.x-U.x<1.||R.y-U.y<1.) Q.xyw*=0.;
}