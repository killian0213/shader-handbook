// Image (image) — gravity field - 2 by FabriceNeyret2
// https://www.shadertoy.com/view/4slSWN

#define POINTS 100  		 // number of stars

// --- GUI utils

float t;

bool keyToggle(int ascii) {
	return (texture(iChannel2,vec2((.5+float(ascii))/256.,0.75)).x > 0.);
}


// --- math utils

float dist2(vec2 P0, vec2 P1) { vec2 D=P1-P0; return dot(D,D); }

float hash (float i) { return 2.*fract(sin(i*7467.25)*1e5) - 1.; }
vec2  hash2(float i) { return vec2(hash(i),hash(i-.1)); }
vec4  hash4(float i) { return vec4(hash(i),hash(i-.1),hash(i-.3),hash(i+.1)); }
	


// === main ===================

// motion of stars
vec2 P(float i) {
	vec4 c = hash4(i);
	return vec2(   cos(t*c.x-c.z)+.5*cos(2.765*t*c.y+c.w),
				 ( sin(t*c.y-c.w)+.5*sin(1.893*t*c.x+c.z) )/1.5	 );
}

// ---

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    t = iTime;
	vec2 uv    = 2.*(fragCoord.xy / iResolution.y - vec2(.8,.5));
	float m = (iMouse.z<=0.) ? .1*t/6.283 : .5*iMouse.x/iResolution.x;
	float my = (iMouse.z<=0.) ? .5*pow(.5*(1.-cos(.1*t)),3.) : iMouse.y/iResolution.y;
	int MODE = int(mod( (iMouse.z<=0.) ? 100.*m : 6.*m ,3.));
	float fMODE = (1.-cos(6.283*m))/2.;

	const int R = 1;
	
	float v=0.; vec2 V=vec2(0.);
	for (int i=1; i<POINTS; i++) { // sums stars
		vec2 p = P(float(i));
		for (int y=-R; y<=R; y++)  // ghost echos in cycling universe
			for (int x=-R; x<=R; x++) {
				vec2 d = p+2.*vec2(float(x),float(y)) -uv; // pixel to star
				float r2 = dot(d,d);
				r2 = clamp(r2,5e-2*my,1e3);
				V +=  d / r2;  // gravity force field
			}
		}
	
	v = length(V);
	v *= 1./(9.*float(POINTS));
	//v = clamp(v,0.,.1);
	
	v *= 2.+100.*fMODE;
	if (MODE==0) fragColor = vec4(.2*v)+smoothstep(.05,.0,abs(v-5.*my))*vec4(1,0,0,0);
	if (MODE==1) fragColor = vec4(.5+.5*sin(2.*v));
	if (MODE==2) fragColor = vec4(sin(v),sin(v/2.),sin(v/4.),1.);


}