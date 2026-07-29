// Image (image) — Liquid glass by OliverSchaff
// https://www.shadertoy.com/view/3dBSRG

// Based on a shader by Shane
// https://www.shadertoy.com/view/ll2SRy
// almost all the code comes from his shader. It's a very good resource!

#define PI 3.14159265359
#define grad_step 0.01
#define time iTime+2.31

// Spectrum colour palette
// IQ https://www.shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 spectrum(float n) {
    //return pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
    return pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.0,0.5),vec3(1.0,1.0,1.0),vec3(0.2,0.33,0.67) );

}

// iq's distance functions
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

float sdUnion_s( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec3 carToPol(vec3 p) {
    float r = length(p);
    float the = acos(p.z/r);
    float phi = atan(p.y,p.x);
    return vec3(r,the,phi);
}

// 2D rotation : pitch, yaw
mat3 rotationXY( vec2 angle ) {
	vec2 c = cos( angle );
	vec2 s = sin( angle );
	
	return mat3(
		c.y      ,  0.0, -s.y,
		s.y * s.x,  c.x,  c.y * s.x,
		s.y * c.x, -s.x,  c.y * c.x
	);
}


float map( vec3 pos ){
    
    
    
    vec3 p2 = vec3(1.0*cos(-0.3*time),1.4*sin(time)*cos(-0.4*time),1.7*sin(time)*sin(-0.3*time));
    float d2 = sdSphere( pos-p2, 0.2);
    vec3 p3 = vec3(1.4*sin(0.3*time),0.2,-1.6*sin(0.3*time+0.3));
    float d3 = sdSphere( pos-p3, 0.2);
    vec3 p4 = vec3(0);
    float d4 = sdSphere( pos-p4, 0.2);
    float d00 = sdUnion_s(d2,d3,0.2);
    
    float d0 = sdUnion_s(d00,d4,0.2);

    vec3 pol = carToPol(pos);
    
    float d1 = sdSphere( pos, 1.0 );
    float wave = 0.07*sin(20.*(pol.y));
    d1 = opOnion(d1+wave, 0.001);
    
    return sdUnion_s(d1,d0,0.3);
    
}

// get gradient in the world
vec3 gradient( vec3 pos ) {
	const vec3 dx = vec3( grad_step, 0.0, 0.0 );
	const vec3 dy = vec3( 0.0, grad_step, 0.0 );
	const vec3 dz = vec3( 0.0, 0.0, grad_step );
	return normalize (
		vec3(
			map( pos + dx ) - map( pos - dx ),
			map( pos + dy ) - map( pos - dy ),
			map( pos + dz ) - map( pos - dz )			
		)
	);
}

vec3 selfColor(vec3 pos) {
    vec3 pol = carToPol(pos);
    return spectrum(1.0*pol.z/PI/2.0+0.5*pol.y/PI);
}

mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

float rCoeff(in vec3 p, in vec3 rd){
    vec3 g = gradient(p);
    g = rotationXY(vec2(2.0,1.0))*g;
    float refl = 1.0-dot(g,rd);
    return refl;
}

void mainImage( out vec4 fragColor, vec2 fragCoord ) {
    
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy)/iResolution.y;
//    vec3 ro = vec3( -5.0*cos(0.2*iTime+0.0), 0.0, 5.0*sin(0.2*iTime+0.0));
    vec3 ro = vec3( 0.0, 5.0*cos(0.3*time), 5.0*sin(0.3*time));
    vec3 ta = vec3( 0. , 0. , 0. );
    
    float aa = 1.0/min(iResolution.y,iResolution.x);
    
    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 1.5);  // 0.0 is the camera roll
    
	// create view ray
	vec3 rd = normalize( camMat * vec3(p.xy, 3.0) ); // 3.0 is the lens length
    
    // rotate camera with mouse
	mat3 rot = rotationXY( ( iMouse.xy - iResolution.xy * 0.5 ).yx * vec2( 0.01, -0.01 ) );
	rd = rot * rd;
	ro = rot * ro;
    vec3 col = vec3(1), sp;
    
	// Ray distance, bail out layer number, surface distance and normalized accumulated distance.
	float t=0., layers=0., d, aD;
    
    // Surface distance threshold. Smaller numbers give a sharper object. Antialiased with aa
    float thD = .5*sqrt(aa); 
    
    // Only a few iterations seemed to be enough. Obviously, more looks better, but is slower.
	for(int i=0; i<80; i++)	{
        
        // Break conditions. Anything that can help you bail early usually increases frame rate.
        if(layers>10. || col.x<0. || t>8.) break;
        
        // Current ray postion
        sp = ro + rd*t;
		
        d = map(sp); // Distance to nearest point in the cube field.
        
        // If we get within a certain distance of the surface, accumulate some surface values.
        // Values further away have less influence on the total.
        //
        // aD - Accumulated distance. I interpolated aD on a whim (see below), because it seemed 
        // to look nicer.
        //
        // 1/.(1. + t*t*.25) - Basic distance attenuation. Feel free to substitute your own.
        
         // Normalized distance from the surface threshold value to our current isosurface value.
        aD = (thD-abs(d))/thD;
        
        // If we're within the surface threshold, accumulate some color.
        // Two "if" statements in a shader loop makes me nervous. I don't suspect there'll be any
        // problems, but if there are, let us know.
        if(aD>0.) { 
            // Smoothly interpolate the accumulated surface distance value, then apply some
            // basic falloff (fog, if you prefer) using the camera to surface distance, "t."
            // selfColor is the color of the object at the point sp
            vec3 sc = selfColor(sp);
            float refl = 0.1*pow(exp(-4.0*rCoeff(sp,rd)),2.0);
            col -= sc*(aD*aD*(3. - 2.*aD)/(1. + t*t*2.25)*7.5);
            col += refl;
            layers++;
        }

		
        // Kind of weird the way this works. I think not allowing the ray to hone in properly is
        // the very thing that gives an even spread of values. The figures are based on a bit of 
        // knowledge versus trial and error. If you have a faster computer, feel free to tweak
        // them a bit.
        t += max(abs(d)*.5, thD*0.8); 
	}
    
    // I'm virtually positive "col" doesn't drop below zero, but just to be safe...
    col = max(col, 0.);
    
	fragColor = vec4(clamp(col, 0., 1.), 1);
 }
