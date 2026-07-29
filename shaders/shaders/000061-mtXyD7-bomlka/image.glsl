// Image (image) — bomlka by lamogui
// https://www.shadertoy.com/view/mtXyD7


const float dLimit = 0.00001;
const float dFar = 80.;

#define PI 3.14159265

#define M_SKY        0.
#define M_FLOOR      1.
#define M_B          2.
#define M_BFOOT  	 3.
#define M_BEYE  	 4.
#define M_BHAT  	 5.
#define M_BFIL  	 6.
#define M_BKEY  	 7.
#define M_TER  		 8.

#define mmin( d, n, m ) ( n < d.x ) ? vec2( n, m ) : d;

float beat1 = 0.0;
float beat2 = 0.0;

float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}

float rand(float n){return fract(sin(n) * 43758.5453123);}
vec3 noise3( float n ) {
	return vec3( rand( n ), rand(n*.520 + 1.546), rand(n*3.10 - 0.56) );
}
vec3 noise33( vec3 n ) {
	return vec3( rand( n.x ), rand(n.y), rand(n.z) );
}

float box( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

mat2 rot( float a ) {
	float c = cos( a );
	float s = sin( a );
	return mat2( c, s, -s, c );
}

float ell( vec3 p, vec3 r )
{
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}



float rc( vec3 p, float r1, float r2, float h )
{
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  vec2 q = vec2( length(p.xz), p.y );
  float k = dot(q,vec2(-b,a));
  if( k<0.0 ) return length(q) - r1;
  if( k>a*h ) return length(q-vec2(0.0,h)) - r2;
  return dot(q, vec2(a,b) ) - r1;
}

float cyl( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 map(vec3 p); 

vec3 grad( in vec3 p )
{
	vec3 e = vec3(0.01, 0.0, 0.0);
	return normalize( vec3(
		map(p+e.xyy).x-map(p-e.xyy).x,
		map(p+e.yxy).x-map(p-e.yxy).x,
		map(p+e.yyx).x-map(p-e.yyx).x
	) );
}

vec4 rm(vec3 ro, vec3 rd, out float st)
{
	vec3 p = ro;
	float d;
	vec2 dmat = vec2( 100000.0, M_SKY);
	st = 1.;
	for (float i = 0.; i < 150.; i++)
	{
		dmat = map(p);
		d = distance(ro, p);
		if (abs(dmat.x) < dLimit || d > dFar)
		{
			st = i/150.;
			break;
		}
		p += rd * dmat.x;
	}
	return vec4(p, dmat.y);
}


vec3 fogged( vec3 c, float f ) {
	return mix( c, vec3(.529, .808, .922 ), f );
}
float foggedR( float r, float f ) {
	return mix( r, 0.0, f );
}


float shade( out vec3 c, float m, vec3 o, vec3 p, float st, vec3 n, vec3 rd ) {
	
	float f = 1.0 - exp( - 0.1 * distance(o,p) );

	if ( m < M_SKY + 0.5) {
		c = fogged( vec3( .529, .808, .922 ), f );
		return foggedR( .0, f);
	} else if (  m < M_FLOOR + 0.5) {
		c = fogged( vec3( .5, .5, .5 ), f);
		return foggedR( 0.5, f);
	} else if ( m < M_B +0.5) {
		c = fogged( vec3( .01, .01, .01 ), f );
		c *=st;
		//if ( track_time < 69.05 ) {
			return foggedR( 0.2, f);
		//} else {
		//	c = mix( c, n * .5 + .5, 0.1);
		//	return foggedR( 0.05, f);
		//}
	} else if ( m < M_BFOOT +0.5) {
		c = .8*(1.-st)*fogged( vec3( 1., .5, .0 ), f );
		return 0.;
	}  else if ( m < M_BEYE +0.5) {
		c = fogged( vec3( 1., 1., 1.0 ), f );
		return foggedR( 0.05, f );
	} else if ( m < M_BHAT +0.5) {
		c = fogged( vec3( 0., .5, 1.0 ), f );
		return foggedR( 0.5, f);
	} else if ( m < M_BFIL +0.5) {
		c = fogged( sqrt(st)*mix(vec3( 0., 0., 0. ), vec3( 1., 1., 1. ), 11.-pow(p.y,2.) ), f );
		return 0.;
	} else if ( m < M_BKEY +0.5) {
		c = fogged( vec3( 1., .5, .0 ), f );
		return foggedR( 0.22, f);
	} else if (  m < M_TER + 0.5) {
		c = fogged( st*vec3( .5, .5, .5 ), f);
		return foggedR( 0.5, f);
	}
	return .0;
}


vec2 bomb( vec3 p, float e, float m, float f1, float f2, float r, float kr ) {


	vec2 d = vec2( 10., M_SKY);

	p.y -= 1.5;


	float c = ell( p, vec3(1.,1.,1.));

	vec3 g = p;
	g.yz *= rot(-.2 * r);

	// fesses 
	//if( track_time > 69.05 ) {
	//	vec3 pc = g;
	//	pc.y += .5;
	//	pc.z += .6;
	//	pc.x += .2;
	//	c = smin(c, ell( pc, vec3(.35,.4,.2)), .2);
	//	pc.x -= .2*2.;
	//	c = smin(c, ell( pc, vec3(.35,.4,.2)), .2);
	//}
	d = mmin(d, c ,M_B);

	vec3 pe = g;
	pe.x = -abs(pe.x);
	pe.yz *= rot( -0.5);
	pe.zx *= rot( -0.4);
	pe = pe - vec3(0.0, 0.0, .92);
	d = mmin( d, ell( pe, vec3(0.25,0.4 + 0.1 * e,0.1) ), M_BEYE);

	// foots
	vec3 pf = p;
	float f = (pf.x > 0.) ? f1 : f2;
	float del = PI/5.;
	float af = max(-PI/2., -(f+del*f) + del );
	pf.yz *= rot( af );
	pf.x = abs( -pf.x );
	pf.y += 1.0;
	pf.x -= 0.6 - pow(-pf.y,3.)*.2;
	float df = cyl( pf , .5, 0.2);
	pf.y += .5;
	pf.yz *= rot(1.5);
	if ( af > .0 ) {
		pf.yz *= rot(.3 * (1.-pow( p.y, 2. )));
	}
	df = smin( df, rc( pf, 0.25, 0.3, 0.5), 0.1 );
	df = max(df, -0.1 + pf.z);
	d = mmin( d, df, M_BFOOT);	
	
	// key
	vec3 pk = g;

	pk.yz *= rot(1.5);

	pk.zx *= rot( -kr * 2.*PI );
	pk.y += 1.;
	float k = cyl(pk, .15, 0.2);
	//pk.z = abs(-pk.z);
	pk.z +=.3;
	pk.y +=0.5;
	pk.xy *= rot(1.5);
	k = smin(k, max( cyl( pk, .1, .4), -cyl( pk, .3, .2) ), 0.2 );
	pk.z -=2.*0.3;
	k = smin(k, max( cyl( pk, .1, .4), -cyl( pk, .3, .2) ), 0.2 );

	d = mmin( d, k, M_BKEY );
	

	// Hat
	vec3 ph = g;
	ph.y -= .95;
	d = mmin( d, cyl( ph , .1, .45), M_BHAT);	

	vec3 pi = ph;
	d = mmin( d, cyl( ph + 0.1*vec3( ph.y*cos(ph.y * 10.0), .0, (m*3.+2.)*pi.y*pi.y*pi.y) , 1., .1 + 0.01 * pow(cos(200.*pi.y),2.)), M_BFIL);	

	return d;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{



    vec3 color = vec3(1.);
	vec2 uv = fragCoord/vec2(iResolution);
    uv.x *= float(iResolution.x)/float(iResolution.y);
    uv = uv *.5-.5;
    float camTime= iTime *.3;
   float camAmpl = 12.+2.*sin(iTime);
	vec3 ro = vec3(camAmpl*cos(-camTime),5.5+2.*sin(iTime),camAmpl*sin(-camTime));
	vec3 rd = normalize(vec3(uv, 0.5));//rotate_dir(cam_rotation, normalize(vec3(uv,2.0 * cam_fov)));
    rd.xz *=rot(-PI/2.+camTime);
    rd.xy *=rot(0.3*sin(iTime));
	vec3 n;
	vec4 pmat;

	float period = 0.5;

	//for ( float n = 40.0; n < 45.; ++n ) {
	//	beat1 = max(beat1, getNoteVelocity(n,5.) );
	//}

    beat1 = exp( - 3.0 * mod( iTime, period ) / period );
	//beat1 = pow( beat1*2., 2.0);
	//if ( track_time > 28.1 ) {
	//	for ( float n = 35.0; n < 40.; ++n ) {
	//		beat2 = max(beat2, getNoteVelocity(n,5.) );
	//	}
	//	beat2 = pow( beat2*1.5, 2.0);		
	//}


//exp( - 10.0 * mod( sequence_time, period ) / period );
	beat2 = exp( - 3.0 * mod( iTime + period*0.5, period ) / period );
	//beat2 = pow( beat2*1.5, 2.0);
	//snare = max(
	//				 max(
	//					max(getNoteVelocity(81.,4.),getNoteVelocity(74.,4.)),
	//				 getNoteVelocity(62.,4.)),
	//				getNoteVelocity(86.,4.));
	
  
  float r = 1.;
  for (int i = 0; i < 3; i++)
	{
		float st;
		pmat = rm(ro,rd, st);
	  n = grad(pmat.xyz);
		vec3 cr = n * 0.5 + 0.5;
		r *= shade(cr, pmat.w, ro, pmat.xyz, st, n, rd);

		color *= ( ( 1.-r) * cr.xyz * (1.-st*(r)) );
		
		if ( r > 0.01 ) {
			ro = pmat.xyz + n*4.*dLimit;
			rd = reflect(rd, n);
		} else {
			break;
		}

	}


	color = pow(color, vec3(1./2.2));
	//color *= 1.0 - smoothstep(71.5, 72.5, track_time);
//color= vec3(uv,1.);
    fragColor = vec4(color,1.0);
}

float ter( vec3 p ) {
	float per = 6.;
	vec3 g = p;
	vec3 n = vec3( ivec3( (g / per) ) );
	g.xz =	mod( g.xz, per ) - per * .5;

float t = per*.5; 

t= cyl(g,10.* rand(n.x), .25*per*rand(n.y+n.x));
		g = p;
		g.xz *= rot( .351 );
		 n = vec3( ivec3( (g / per) ) );

	g.xz =	mod( g.xz, per ) - per * .5;
		t = min(t,box(g, vec3(.5,2.,.1) + .25 * per * noise3(n .x+n.y ), 0.21 * beat1));

g = p;
		g.xz *= rot( -.787 );
		 n = vec3( ivec3( (g / per) ) );
	g.xz =	mod( g.xz, per ) - per * .5;
		t = min(t,box(g, vec3(.5,2.,.1) + .25 * per * noise3(-n.x+n.y), 0.21 * beat2));
		t = max( t, 13.-length( p));
		return t;
}

vec2 map(vec3 p) {

	vec2 d = vec2( 10., M_SKY);

	d = mmin( d, p.y, M_FLOOR );
	d = mmin( d, ter(p), M_TER);

	vec3 g = p;
	//if ( track_time > 36.0 ) {
		g.xz *= rot(iTime * .8);
	//}

	float per = PI/4.0;
	float a = mod( atan(g.z, g.x), per) - .5 * per;
	float l = length(g.zx) ;

	g.x = l * cos( a );
	g.z = l * sin( a );
	//if ( track_time < 28.1 || track_time > 36.1) {
		g.x -= 7.;
	//} else if ( track_time < 32. ){
	//	g.x -= 7. + 3. * cos(sequence_time*.8);
	//} else {
	//	g.x -= 7. - 3. * cos(sequence_time*.8);
	//}

//if ( track_time < 36.1 ) {
//	g.zx *= rot(-PI/2.);
//}
	vec2 b = bomb( g, beat1, beat2, beat1, beat2, max(beat1, beat2), iTime );
	d =	mmin( d, b.x, b.y );

	return d;
}