// Image (image) — Rapidly Evolving Fluid by wyatt
// https://www.shadertoy.com/view/MtdBDB

/*  Hello! Let me try to explain how this works.
	It took me a long time to undertand this stuff
	so bare with me.
	
	Lets start with the ideal gass law:
	PV = nRT
	Temperature is actually the kinetic energy of particles
	So without really getting into it, nRT is the total KE of the system
	So that means PV equals the kinetic energy of a system

	We could arrive at this conclusion in another way as well

	P = F/A         (Pressure is force per area)
	P = F/A * d/d   (here we multiply by 1 in the form of another spacial dimension)
	P = F*d / V     (Area * Length = Volume)
	P = E / V		(Force * distance = Work)
	PV = E  --> P = E/V
	
	So, it follows that pressure is kinetic energy per volume
	
	So lets think of any fluid as a large sum of particles
	that are continuously banging into each other.
	How can you possibly keep track of all that?!
	Well, we can represent different forms of kinetic energy.
	Specifically chaotic kinetic energy and ordered kinetic energy

	so we have 4 channels to work with, so we could have :

r(x)	x direction KE
g(y)	y direction KE
b(z)	and chaotic KE (which is pressure)
a(w)	ink to move around

	Since the medium is moving though itself, any time we
	want to find out about one of these values, we
	have to look them up where they used to be.

	So if I am a pixel and I want to know about my state
	I have to look up the velocity where I am and then
	subtract it from my current location to make a good
	guess of where I was last. In code this looks like this:

	U = my position
	T(U).xy = velocity where I am now
	U - T(U).xy = where I probably was last
	
	Now we want to find out how my pressure (which is
	also my internal kinetic energy) has changed since
	the last state of the fluid.

	Since the last time we knew the state of the
	fluid, each part of the fluid as interacted with its
	neighbors. When one region of space interacts with
	another, it is kind of like they collided with each
	other. Their energies talk to each other in three
	significant ways : 
	
1.	Ordered energy is lost to chaos: A change in 
		the separation between two regions
		corresponds to a linear change in volume.
		A linear change in volume corresponds to a
		linear change in pressure.

2.  The two regions completely exchange pressure.
	 	Think of this as two billiards balls smacking 
		together and trading energies. Or like energy
		traversing a newton's cradle. Remember, pressure
		is actually kinetic energy per volume.

3.  Chaotic energy is converted into ordered energy.
		The space accelerates in the direction of the
		gradient of pressure. Theres are a lot of ways
		to think about this : 
	
			a. A particle sliding down an energy wave

			b. The gradient of energy is a force

			c. Pressure is like pushing outwards, 
				if you have an uneven push, there 
				will be an acceleration. 

	
Conclusion : 
	
-	The space moves each frame according to the ordered
	energy in the space. Ordered energy makes change!

-	Some ordered energy is lost to chaos when the the
	geometry of the space is strained.

-	Directional changes in chaos turn into ordered energy

-	Chaos is continuously traded around like a hot potato
	
	
See Buffer A,B,C, or D and see the function "X"
	to see how this looks in code!



:D Wyatt

*/


void mainImage( out vec4 C, in vec2 U )
{
    U = U/iResolution.xy;
    vec4 g = texture(iChannel0,U,1.);
   	C.xyz = cos(.5-3.*g.w*vec3(1,2,3));
    C = C*sqrt(max(C,0.));
}