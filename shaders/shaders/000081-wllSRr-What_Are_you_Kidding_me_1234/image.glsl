// Image (image) — What! Are you Kidding me? 1234 by wyatt
// https://www.shadertoy.com/view/wllSRr

/*
	It was quite the journey figuring it out, but this is how the thing I made works : 
	
	This is a system of linear differential equations that correspond to the following set:

    {[(G dG)]   [(p dp) (n dn)]  [(r dr) (g dg) (b db)]}
    
	Each pair of wave functions (Psi dPsi) evolves like this:

	dPsi += Laplacian(Psi) - Psi/||SubGroup|| + Psi/||SuperGroup||
    Psi += dPsi

    So there are 12 degrees of freedom across 6 wave fields, gravity, positive, negative, red, green, blue.
    Each field interacts with itself with the wave equation. 
    Each field also interacts with the composition of the set it belongs to (ie positive interacts with positive and negative) but there is also a unifying force where each field interacts with the composition of all 6 fields! 

	There are 4 forces :

	1 : Gravity [mass]
	2 : Electromagnitism [positive negative]
	3 : Chromodynamics [red green blue]
	4 : Unification {1 2 3 4}

	The trippy part is that set of forces includes the set of all forces.
	The unifying force has 4 elements Gravity, Electromagnitism, Chromodynics and itself

*/

void mainImage( out vec4 Q, in vec2 U )
{
    vec4 a = A(U);
    vec4 b = B(U);
    vec4 c = C(U);
    vec4 d = D(U);
    c = .1*vec4(c.x,0.5*c.x+0.5*c.y,c.y,1);
    d = .1*vec4(d.x,0.5*d.x+0.5*d.y,d.y,1);
    Q = .8*(sqrt(c*c+10.*d*d+.01*(a*a+5.*b*b)));
    Q.xyz = mix(Q.xyz,normalize(Q.xyz),min(1.,length(Q.xyz)));
	
}