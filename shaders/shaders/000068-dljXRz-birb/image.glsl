// Image (image) — birb by A_Toaster
// https://www.shadertoy.com/view/dljXRz

#define EPS 0.0005
#define NORM_EPS (EPS)
#define SHADOW_BIAS (EPS * 10.)
#define MAX_DIST 10.

#define PI 3.1415926535

const vec3 cam_origin = vec3(-0.7, 0.7, 0.);

const vec3 ambient_boost = vec3(0.2, 0.25, 0.3);

float head_dir;
float head_bob;
float body_bob;

// Function prototypes
vec3 calcNormal( in vec3 pos);


// From https://www.shadertoy.com/view/XdsGDB
// Set up a camera looking at the scene.
void CamPolar( out vec3 pos, out vec3 ray, in vec3 origin, in vec2 rotation, in float distance, in float zoom, in vec2 fragCoord )
{
	// get rotation coefficients
	vec2 c = vec2(cos(rotation.x),cos(rotation.y));
	vec4 s;
	s.xy = vec2(sin(rotation.x),sin(rotation.y)); // worth testing if this is faster as sin or sqrt(1.0-cos);
	s.zw = -s.xy;

	// ray in view space
	ray.xy = fragCoord.xy - iResolution.xy*.5;
	ray.z = iResolution.y*zoom;
	ray = normalize(ray);
	
	// rotate ray
	ray.yz = ray.yz*c.xx + ray.zy*s.zx;
	ray.xz = ray.xz*c.yy + ray.zx*s.yw;
	
	// position camera
	pos = origin - distance*vec3(c.x*s.y,s.z,c.x*c.y);
}


// Noise functions
// -----------------------------------------------------------------
float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
	vec2 uv = (i.xy+vec2(37.0,17.0)*i.z) + f.xy;
	vec2 rg = textureLod( iChannel3, (uv+0.5)/256.0, 0.0).yx;
	return mix( rg.x, rg.y, f.z );
}


// SDF Functions
// -----------------------------------------------------------------
float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdBoxFrame( vec3 p, vec3 b, float e )
{
       p = abs(p  )-b;
  vec3 q = abs(p+e)-e;
  return min(min(
      length(max(vec3(p.x,q.y,q.z),0.0))+min(max(p.x,max(q.y,q.z)),0.0),
      length(max(vec3(q.x,p.y,q.z),0.0))+min(max(q.x,max(p.y,q.z)),0.0)),
      length(max(vec3(q.x,q.y,p.z),0.0))+min(max(q.x,max(q.y,p.z)),0.0));
}

float dot2(vec3 p) {
    return dot(p,p);
}

float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2)
{
  // sampling independent computations (only depend on shape)
  vec3  ba = b - a;
  float l2 = dot(ba,ba);
  float rr = r1 - r2;
  float a2 = l2 - rr*rr;
  float il2 = 1.0/l2;
    
  // sampling dependant computations
  vec3 pa = p - a;
  float y = dot(pa,ba);
  float z = y - l2;
  float x2 = dot2( pa*l2 - ba*y );
  float y2 = y*y*l2;
  float z2 = z*z*l2;

  // single square root!
  float k = sign(rr)*rr*rr*x2;
  if( sign(z)*a2*z2>k ) return  sqrt(x2 + z2)        *il2 - r2;
  if( sign(y)*a2*y2<k ) return  sqrt(x2 + y2)        *il2 - r1;
                        return (sqrt(x2*a2*il2)+y*rr)*il2 - r1;
}

float sdVerticalCapsule( vec3 p, float h, float r )
{
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

// Bezier SDF adapted from https://www.shadertoy.com/view/4slSWf
float det( vec2 a, vec2 b ) { return a.x*b.y-b.x*a.y; }

vec3 getClosest( vec2 b0, vec2 b1, vec2 b2 , vec2 ends) 
{
    float a =     det(b0,b2);
    float b = 2.0*det(b1,b0);
    float d = 2.0*det(b2,b1);
    float f = b*d - a*a;
    vec2  d21 = b2-b1;
    vec2  d10 = b1-b0;
    vec2  d20 = b2-b0;
    vec2  gf = 2.0*(b*d21+d*d10+a*d20); gf = vec2(gf.y,-gf.x);
    vec2  pp = -f*gf/dot(gf,gf);
    vec2  d0p = b0-pp;
    float ap = det(d0p,d20);
    float bp = 2.0*det(d10,d0p);
    float t = clamp( (ap+bp)/(2.0*a+b+d), ends.x, ends.y );
    return vec3( mix(mix(b0,b1,t), mix(b1,b2,t),t), t );
}

vec2 sdBezier( vec3 a, vec3 b, vec3 c, vec3 p, in vec3 thickness )
{
	vec3 w = normalize( cross( c-b, a-b ) );
	vec3 u = normalize( c-b );
	vec3 v = normalize( cross( w, u ) );

	vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
	vec2 b2 = vec2( 0.0 );
	vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
	vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

	vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy, vec2(0., 1.) );
    // Thickness at point
    float t = mix(mix(thickness.x, thickness.y, cp.z), mix(thickness.y, thickness.z, cp.z), cp.z);
	return vec2( 0.85*(sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z) - t), cp.z );
}

// Bezier with extended end points
vec2 sdBezierEnds( vec3 a, vec3 b, vec3 c, vec3 p, in vec3 thickness, in vec2 ends)
{
	vec3 w = normalize( cross( c-b, a-b ) );
	vec3 u = normalize( c-b );
	vec3 v = normalize( cross( w, u ) );

	vec2 a2 = vec2( dot(a-b,u), dot(a-b,v) );
	vec2 b2 = vec2( 0.0 );
	vec2 c2 = vec2( dot(c-b,u), dot(c-b,v) );
	vec3 p3 = vec3( dot(p-b,u), dot(p-b,v), dot(p-b,w) );

	vec3 cp = getClosest( a2-p3.xy, b2-p3.xy, c2-p3.xy, ends);
    // Thickness at point
    float t = mix(mix(thickness.x, thickness.y, cp.z), mix(thickness.y, thickness.z, cp.z), cp.z);

	return vec2( 0.85*(sqrt(dot(cp.xy,cp.xy)+p3.z*p3.z) - t), cp.z );
}

float sdEllipsoid( in vec3 p, in vec3 r ) 
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}


float opS( float d1, float d2 ) { return max(-d1,d2); }

float opI( float d1, float d2 ) { return max(d1,d2); }

float opU( float d1, float d2 ) { return min(d1, d2); }

vec2 opUMix(vec2 d1, vec2 d2){
    return (d1.x < d2.x) ? d1 : d2;
}

// polynomial smooth min
float opSU( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
    
// Smooth min returning mix factor
vec2 opSUMix( float a, float b, float k ) {
    float h = max( k-abs(a-b), 0.0 )/k;
    float m = h*h*0.5;
    float s = m*k*(1.0/2.0);
    return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}

vec2 opSUMix( vec2 a, vec2 b, float k ) {
    float h = clamp( 0.5 + 0.5*(a.x-b.x)/k, 0.0, 1.0 );
    
    float d =  mix( a.x, b.x, h ) - k*h*(1.0-h);
    
    return vec2(d, mix(a.y, b.y, h));
}

float opSS( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); }

float opSI( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); }

vec3 opMirrorZ(vec3 p){
    return vec3(p.x, p.y, abs(p.z));
}


vec3 opRotY(vec3 p, float a) {
    mat3 m = mat3(
        cos(a),  0, sin(a),
        0,       1, 0,
        -sin(a), 0, cos(a));
    return p * m;
}

vec3 opRotZ(vec3 p, float a) {
    mat3 m = mat3(
        cos(a), -sin(a), 0,
        sin(a),  cos(a), 0,
        0,       0,      1);
    return p * m;
}

vec3 opRotX(vec3 p, float a) {
    mat3 m = mat3(
        1, 0,       0,
        0, cos(a), -sin(a),
        0, sin(a),  cos(a));
    return p * m;
}
// Pedestal SDF
// -----------------------------------------------------------------

float pedestal_ridges(vec3 p) {
    p.xz = abs(p.xz);
    return min(
        sdVerticalCapsule(p - vec3(0.7, -3.5, 1.), 3., 0.15),
        sdVerticalCapsule(p - vec3(1., -3.5, 0.7), 3., 0.15)
    );
}


float ground_displacement(vec3 p) {
    const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );
    vec3 q2 = p * 40.;
    float f2 = noise( q2 ); q2 = m*q2*2.03;
    f2 += 0.5*noise( q2 ); q2 = m*q2*2.04;
    f2 += 0.25*noise( q2 ); q2 = m*q2*2.05;
    f2 += 0.125*noise( q2 );
    //f2 = f2 * f2 * (2. - f2);
    
    return f2 * 0.125;
}


float ground(vec3 p) {
    vec3 q = p + vec3(0., 0.10, 0.);
    float d = opSU(
        opSU(
            sdBox(q, vec3(1.01, 0.1, 1.01)),
            sdBox(q + vec3(0., 0.15, 0.), vec3(.95, 0.1, .95)),
            0.05
        ),
        opSU(
            sdBox(q + vec3(0., 2., 0.), vec3(0.85, 2., 0.85)),
            opSS(
                pedestal_ridges(q),
                sdBoxFrame(q + vec3(0., 2., 0.), vec3(0.9, 2., 0.9), 0.2),
                0.005
            ),
            0.03
        ),
        0.09
    );
    
    // Calculate displacement if very close
    if(d < 0.1)
        d -= 0.002 * ground_displacement(p) + 0.01;
    // Otherwise decrease distance a bit to avoid overshoot
    else d -= .02;
    return d;
}

// Bird SDF
// -----------------------------------------------------------------
float feather(vec3 p) {
    float d1 = noise(p * 20.);
    
    const mat3 m = mat3( 0.00,  0.80,  0.60,
                -0.80,  0.36, -0.48,
                -0.60, -0.48,  0.64 );
                    
    vec3 q2 = p + vec3(0., 0.2, 0.);
    q2 *= mat3(-1., 1., 0.,
              1., 1., 0.,
              0., 0., 1.);
    float sf = q2.y * q2.y + q2.z * q2.z;
    
    q2 = vec3(q2.x * 20., atan(q2.y, q2.z) * 80., 0.);
    
    float f0 = fract(q2.x * -0.2 + q2.y * -0.05 + d1 * 0.4);
    float f1 = fract(q2.x * -0.2 + q2.y * 0.05 + d1 * 0.7);
    
    float f2 = noise( q2 ); q2 = m*q2*2.03;
    f2 += 0.5*noise( q2 ); q2 = m*q2*2.04;
    
    float f = f0 - smoothstep(0.9, 1., f0) + f1 - smoothstep(0.9, 1., f1);
    return (f2 * (f + 0.1) * 8. + f) * sqrt(sf) ;
}



// Fast voronoi-ish, credit to https://www.shadertoy.com/view/4lSXzh
float voronesque( in vec3 p ) {
    // Skewing the cubic grid, then determining the first vertex.
    vec3 i  = floor(p + dot(p, vec3(.333333)) );  p -= i - dot(i, vec3(.166666)) ;

    // Breaking the skewed cube into tetrahedra with partitioning planes, then determining which side of the 
    // intersecting planes the skewed point is on. Ie: Determining which tetrahedron the point is in.
    vec3 i1 = step(p.yzx, p), i2 = max(i1, 1. - i1.zxy); i1 = min(i1, 1. - i1.zxy);    
    
    // Using the above to calculate the other three vertices. Now we have all four tetrahedral vertices.
    vec3 p1 = p - i1 + .166666, p2 = p - i2 + .333333, p3 = p - .5;
    
    vec3 rnd = vec3(7, 157, 113); // I use this combination to pay homage to Shadertoy.com. :)
    
    // Falloff values from the skewed point to each of the tetrahedral points.
    vec4 v = max(0.5 - vec4(dot(p, p), dot(p1, p1), dot(p2, p2), dot(p3, p3)), 0.);
    
    // Assigning four random values to each of the points above. 
    vec4 d = vec4( dot(i, rnd), dot(i + i1, rnd), dot(i + i2, rnd), dot(i + 1., rnd) ); 
    
    // Further randomizing "d," then combining it with "v" to produce the final random falloff values. 
    // Range [0, 1]
    d = fract(sin(d)*262144.)*v*2.; 
 
    // Reusing "v" to determine the largest, and second largest falloff values. Analogous to distance.
    v.x = max(d.x, d.y), v.y = max(d.z, d.w), v.z = max(min(d.x, d.y), min(d.z, d.w)), v.w = min(v.x, v.y); 
   
    // Maximum minus second order, for that beveled Voronoi look. Range [0, 1].
    return  max(v.x, v.y) - max(v.z, v.w);  
}

vec2 neck(vec3 p){
    return sdBezierEnds(
        vec3(-1.25, 0.75, 0.), 
        vec3(-1.35, 1.00, 0.), 
        vec3(-1.35, 1.20, 0.),
        p * vec3(1., 1., 1.15),
        vec3(0.2, 0.18, 0.05), vec2(-0.15, 1.15)
        );
}

float leg_displacement( in vec3 p ){
    return smoothstep(0., 0.2, voronesque(p * 35.));
}


vec2 legs(vec3 p) {
    vec3 q = opMirrorZ(p);
    // leg
    float d = sdRoundCone(q, vec3(-0.9, 0.125, 0.1), vec3(-0.98, 0.03, 0.15), 0.02, 0.015);
    
    // First toe segment
    
    // middle toe
    d = opSU(d, sdRoundCone(q, vec3(-0.98, 0.03, 0.15), vec3(-1.05, 0.015, 0.15), 0.013, 0.012), 0.01);
    
    // inner toe
    d = opSU(d, sdRoundCone(q, vec3(-0.98, 0.03, 0.15), vec3(-1.04, 0.01, 0.10), 0.013, 0.010), 0.01);
    
    // outer toe
    d = opSU(d, sdRoundCone(q, vec3(-0.98, 0.03, 0.15), vec3(-1.04, 0.01, 0.20), 0.011, 0.010), 0.01);
    
    // rear toe
    d = opSU(d, sdRoundCone(q, vec3(-0.98, 0.03, 0.15), vec3(-0.94, 0.025, 0.14), 0.010, 0.011), 0.01);
    
    // Remainder of toes
    
    // middle toe
    d = opU(d, sdRoundCone(q, vec3(-1.05, 0.015, 0.15), vec3(-1.06, -0.025, 0.15), 0.010, 0.010));
    d = opU(d, sdRoundCone(q, vec3(-1.06, -0.025, 0.15), vec3(-1.05, -0.05, 0.15), 0.009, 0.011));
    // inner toe
    d = opU(d, sdRoundCone(q, vec3(-1.04, 0.01, 0.10), vec3(-1.05, -0.02, 0.090), 0.008, 0.010));
    d = opU(d, sdRoundCone(q, vec3(-1.05, -0.02, 0.090), vec3(-1.04, -0.04, 0.087), 0.008, 0.010));
    // outer toe
    d = opU(d, sdRoundCone(q, vec3(-1.04, 0.01, 0.20), vec3(-1.05, -0.02, 0.209), 0.008, 0.010));
    d = opU(d, sdRoundCone(q, vec3(-1.05, -0.02, 0.209), vec3(-1.04, -0.04, 0.213), 0.008, 0.010));
    //rear toe
    d = opU(d, sdRoundCone(q, vec3(-0.94, 0.025, 0.14), vec3(-0.91, 0.024, 0.135), 0.010, 0.011));
    
    // thigh
    vec2 d_mix = opSUMix(sdEllipsoid(q - vec3(-0.9, 0.25, 0.12), vec3(0.15, 0.1, 0.05)), d, 0.05);
    
    float displacement = leg_displacement(p);
    d_mix.x -= displacement * smoothstep(0.9, 1., d_mix.y) * 0.001;
    return d_mix;
}

float claws(vec3 p){
    vec3 q = opMirrorZ(p);
    // front middle
    float d = sdBezier(
            vec3(-1.05, -0.05, 0.15), vec3(-1.05, -0.07, 0.15), vec3(-1.03, -0.08, 0.15), 
            q, 
            vec3(0.008, 0.008, 0.0005)
        ).x;
    // Front inner
    d = opU(d, sdBezier(
            vec3(-1.04, -0.04, 0.087), vec3(-1.04, -0.055, 0.087), vec3(-1.02, -0.065, 0.087), 
            q, 
            vec3(0.008, 0.008, 0.0005)
        ).x);
    
    // Front outer
    d = opU(d, sdBezier(
            vec3(-1.04, -0.04, 0.213), vec3(-1.04, -0.055, 0.213), vec3(-1.02, -0.065, 0.213), 
            q, 
            vec3(0.008, 0.008, 0.0005)
        ).x);
    
    // Rear
    d = opU(d, sdBezier(
            vec3(-0.91, 0.024, 0.135), vec3(-0.885, 0.024, 0.135), vec3(-0.87, 0.005, 0.135), 
            q, 
            vec3(0.008, 0.008, 0.0005)
        ).x);
    
    return d;
}

float beak(vec3 p){

    //return sdEllipsoid(opRotZ(p - vec3(-1.53, 1.2, 0.), -0.4), vec3(0.1, 0.03, 0.02));
    float d = sdBezier(
            vec3(-1.53, 1.2, 0.), vec3(-1.60, 1.17, 0.), vec3(-1.62, 1.14, 0.), 
            p * vec3(1., 1., 1.5), 
            vec3(0.025, 0.03, 0.001)
        ).x;
    // Subtract nostrils
    d = opSS(sdEllipsoid(opRotZ(opMirrorZ(p) - vec3(-1.58, 1.19, 0.015), -0.4), vec3(0.01, 0.005, 0.005)),
        d, 0.005);
    
    float line = sdBezier(
            vec3(-1.53, 1.2, 0.), vec3(-1.60, 1.17, 0.), vec3(-1.62, 1.135, 0.), 
            p * vec3(1., 1., 0.1), 
            vec3(0.01, 0.01, 0.01)
        ).x;
    line = smoothstep(0.001, 0.02, -line);
    
    return d + line * 0.01;
}

float cere(vec3 p){
    return sdEllipsoid(opRotZ(opMirrorZ(p) - vec3(-1.54, 1.212, 0.010), -0.3), vec3(0.04, 0.02, 0.02));
}

vec3 eye_xform(vec3 p) {
    return opRotX(opRotY(opRotZ(opMirrorZ(p) - vec3(-1.46, 1.27, 0.061), -0.4), 0.25), 0.1);
}

float eyes(vec3 p){
    return sdEllipsoid(eye_xform(p), vec3(0.035, 0.035, 0.02));
}

vec2 sdFeather(vec3 p, float l) {
    return vec2(sdEllipsoid(p, vec3(l, 0.03, 0.1)), p.x);
}

vec2 tail(vec3 p){
    vec3 q = opRotZ(opMirrorZ(p), 0.43);
    
    vec2 d = sdFeather(opRotX(opRotY(q, 0.1), -0.25) - vec3(-0.35, 0.2, 0.06), 0.5);
    d = opUMix(d, sdFeather(opRotX(opRotY(q, 0.05), -0.125) - vec3(-0.3, 0.21, 0.04), 0.5));
    d = opUMix(d, sdFeather(q - vec3(-0.28, 0.22, 0.02), 0.5));
    return d;
}

vec2 wings(vec3 p){
    vec3 q = opRotZ(opMirrorZ(p), 0.33);
    // offset
    q.y -= 0.1;
    //bend
    q = vec3(q.x, q.y, q.z + 1.1 * q.y * q.y);
    
    // base of wing
    float d = sdEllipsoid(q - vec3(-1.15, 0.12, 0.24), vec3(0.35, 0.30, 0.08));
    
    q = opRotY(q, -0.05);
    // first set of feathers
    d = opSU(d, sdEllipsoid(q - vec3(-0.98, 0.10, 0.205), vec3(0.35, 0.25, 0.05)), 0.05);
    
    q = opRotY(q, -0.05);
    // second set of feathers
    d = opSU(d, sdEllipsoid(q - vec3(-0.8, 0.12, 0.18), vec3(0.25, 0.18, 0.04)), 0.05);

    // final pointy feathers
    float d2 = sdEllipsoid(opRotZ(q, -0.1) - vec3(-0.6, 0.18, 0.17), vec3(0.6, 0.11, 0.04));
    d2 = opSU(d2, sdEllipsoid(opRotZ(q, -0.25) - vec3(-0.5, 0.18, 0.17), vec3(0.6, 0.07, 0.03)), 0.02);
    
    vec2 d_co = opSUMix(vec2(d, q.x), vec2(d2, 0.), 0.005);
    
    return d_co;
}

float birb(vec3 p){
    // Neck/head
    float d = neck(p).x;
    
    d = opSU(d, sdEllipsoid(p - vec3(-1.31, 0.80, 0.), vec3(0.18, 0.28, 0.18)), 0.07);
    
    // Body
    float body = sdBezierEnds(
            vec3(-0.15, 0.25, 0.), vec3(-0.45, 0.3, 0.), vec3(-0.85, 0.45, 0.), 
            p * vec3(1., 1., 1.15), 
            vec3(0.05, 0.27, 0.3), vec2(-0.1, 1.1)
        ).x;
    body = opSU(body, sdBezierEnds(
            vec3(-0.85, 0.45, 0.), vec3(-1.15, 0.55, 0.), vec3(-1.25, 0.90, 0.), 
            p * vec3(1., 1., 1.25), 
            vec3(0.3, 0.4, 0.15), vec2(-0.5, 1.2)
        ).x, 0.07);
    
    
    d = opSU(d, body, 0.1);
    
    
    // Head
    d = opSU(d, sdEllipsoid(opRotZ(p - vec3(-1.33, 1.15, 0.), -0.1), vec3(0.12, 0.18, 0.09)), 0.1);
    d = opSU(d, sdEllipsoid(p - vec3(-1.41, 1.25, 0.), vec3(0.14, 0.12, 0.10)), 0.07);
    // Depressions on head for eyes
    d = opSS(
        sdEllipsoid(opRotY(opRotZ(opMirrorZ(p) - vec3(-1.42, 1.28, 0.13), -0.4), 0.25), vec3(0.1, 0.02, 0.03)),
        d, 0.07);
        
    // Eye socket
    d = opSS(
        sdEllipsoid(opRotY(opRotZ(opMirrorZ(p) - vec3(-1.46, 1.27, 0.085), -0.4), 0.25), vec3(0.035, 0.030, 0.02)),
        d, 0.005);
        
        
    // Tail feathers
    d = opSU(d, tail(p).x, 0.05);
    
    // wings - attached more smoothly at top
    d = opSU(d, wings(p).x, 0.04 * smoothstep(0.65, 0.9, p.y));
    
    float f = feather(p);
    d -= f * 0.0002;
    
    // Beak
    d = opSU(d, beak(p), 0.04);
    //cere
    d = opSU(d, cere(p), 0.005);
    

   
    //eyes
    d = opU(d, eyes(p));
    
    // Legs
    d = opSU(d, legs(p).x, 0.1);
    
    //claws
    d = opU(d, claws(p));
    
    return d;
}

vec3 head_twist(vec3 p, float twist, float bob, float breath) {
    vec3 neck_origin = vec3(-1.30, 1.20, 0.);
    vec3 q = p - neck_origin;
    float twist_fac = smoothstep(-0.33, -0.05, q.y);
    float breath_fac = clamp((p.y - 0.04) * 10., 0., 1.);
    twist_fac = 0.1 * breath_fac + 0.9 * twist_fac;
    q = opRotY(q, twist_fac * twist);
    q -= vec3(0., bob * twist_fac + breath * breath_fac, 0.);
    return q + neck_origin;
}

float map(vec3 p) {
    return min(
        ground(p),
        birb(head_twist(p, head_dir, head_bob, body_bob))
    );
}


float marble(vec3 p) {
    const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );
                    
    vec3 q1 = p;
    
    float f1 = 0.5000*noise( q1 ); q1 = m*q1*2.01;
    f1 += 0.2500*noise( q1 ); q1 = m*q1*2.02;
    f1 += 0.1250*noise( q1 ); q1 = m*q1*2.03;
    f1 = smoothstep(0.5, 0.6, f1);
    f1 = pow(4.0*f1*(1.0-f1), 2.);
    
    return f1;
}

vec3 eye_albedo(vec3 p){
    vec2 q = eye_xform(p).xy;
    
    float r = length(q);
    float t = atan(q.x, q.y);
    
    float pupil = smoothstep(-0.015, -0.01, -r);
    float iris = smoothstep(-0.03, 0., -r);
    
    vec3 iris_col = mix(vec3(0.1, 0.05, 0.), vec3(0.3, 0.2, 0.), iris);
    
    return mix(iris_col, vec3(0.02), pupil);
}

void material(in vec3 p, out vec3 albedo, out float roughness, out float ao, out float metallic, out float film_thickness, out float sss, out vec3 normal) {
    
    normal = calcNormal(p);
    
    float ground = ground(p);
    
    vec3 p2 = head_twist(p, head_dir, head_bob, body_bob);
    float birb = birb(p2);
    
    if(ground < birb) {
        // Ground material
        float d = clamp(ground_displacement(p) * 5., 0., 1.);
        d = pow(1. - d, 2.);
        float c = marble(p * vec3(2., 0.5, 2.))
            + marble(p * vec3(5., 1., 5.));
        c = clamp(c, 0., 1.);
        albedo = vec3(0.23, 0.23, 0.23);
        roughness = mix(0.65, 0.6, c);
        ao = mix(1., 0.7, d);
        metallic = c * 0.3;
        film_thickness = 0.;
        sss = 0.;
    } else {
        // birb material
        sss = 0.2;
        float neck_dist = neck(p2).y;
        //float neck_dist = clamp(p.y - 0.75, 0., 1.);
        float irridescent = smoothstep(0.0, 0.4, neck_dist) * (1. - smoothstep(0.7, 0.9, neck_dist));
        
        // head material factor
        float head = smoothstep(0.66, 0.8, p2.y);
        // legs material factor
        float legs = smoothstep(0.9, 1., legs(p2).y);
        float leg_d = leg_displacement(p2);
        vec3 leg_albedo = mix(vec3(0.3, 0.22, 0.22), vec3(0.3, 0.15, 0.08), leg_d);
        float leg_roughness = mix(0.9, 0.65, leg_d);
        
        // beak material factor (Also claw material)
        float beak = smoothstep(-0.01, 0., -beak(p2));
        beak += smoothstep(-0.001, 0., -claws(p2));
        vec3 beak_albedo = vec3(0.04, 0.04, 0.04);
        float beak_roughness = 0.72;
        
        float cere = smoothstep(-0.002, 0., -cere(p2));
        vec3 cere_albedo = vec3(0.21,0.2,0.2);
        float cere_roughness = 0.9;
        
        float eyes = smoothstep(-0.001, -0.0009, -eyes(p2));
        vec3 eye_albedo = eye_albedo(p2);
        float eye_roughness = 0.0;
        
        vec3 dark_feather_albedo = mix(vec3(0.04), vec3(0.025), p2.y * 2.);
        
        vec2 tail = tail(p2);
        tail = vec2(smoothstep(-0.08, -0.01, -tail.x), smoothstep(0.2, 0.3, tail.y));
        vec3 tail_albedo = mix(vec3(0.08,0.10,0.13), dark_feather_albedo, tail.y);
        
        vec2 wing = wings(p2);
        wing.x = smoothstep(-0.02, 0., -wing.x);
        
        
        float f = abs(sin(p2.y * 25.)) - 0.5;
        float py2 = p2.y * p2.y;
        float b1 = wing.y + 0.5 * py2 - 0.65 * p2.y - 0.01 * f;
        float b2 = wing.y + 0.5 * py2 - 0.65 * p2.y - 0.05 * f;
        float b3 = wing.y - 1.3 * p2.y + 1. * py2 - 0.01 * f;
        float b4 = wing.y - 1.6 * p2.y + 1. * py2 - 0.05 * f;
    
        
        
        wing.y = smoothstep(-0.1, -0.0, wing.y);
        wing.y += smoothstep(-1.4, -1.38, b3) - smoothstep(-1.45, -1.4, b4);
        wing.y += smoothstep(-1.02, -1., b1) - smoothstep(-0.9, -0.85, b2);
        
        wing.y = smoothstep(0., 1., wing.y);
        
        vec3 wing_albedo = mix(vec3(0.13,0.16,0.16), dark_feather_albedo, wing.y);
        
        
        albedo = mix(vec3(0.11,0.14,0.15), vec3(0.037, 0.06, 0.08), head);
        albedo = mix(albedo, leg_albedo, legs);
        albedo = mix(albedo, beak_albedo, beak);
        albedo = mix(albedo, cere_albedo, cere);
        albedo = mix(albedo, cere_albedo, cere);
        albedo = mix(albedo, eye_albedo, eyes);
        albedo = mix(albedo, tail_albedo, tail.x);
        albedo = mix(albedo, wing_albedo, wing.x);
        
        roughness = mix(0.82, leg_roughness, legs);
        roughness = mix(roughness, beak_roughness, beak);
        roughness = mix(roughness, cere_roughness, cere);
        roughness = mix(roughness, eye_roughness, eyes);
        
        
        sss += 0.3 * beak + 0.3 * cere;
        
        
        ao = 1.;
        metallic = irridescent * 0.7;
        film_thickness = mix(13.5, 7.5, neck_dist);
    }
    
}

// Raymarching functions
// -----------------------------------------------------------------
bool intersect( in vec3 ro, in vec3 rd, out float dist )
{
	float h = 1.0;
	dist = 0.0;
    for( int i=0; i<128; i++ )
    {
		if( h < EPS * dist) return true;
		h = map(ro + rd * dist);
        dist += h * 0.9;
		if( dist > MAX_DIST) return false;
    }
	return false;
}

float softShadow( in vec3 ro, in vec3 rd, float mint, float k )
{
    float res = 1.0;
    float t = mint;
	float h = 1.0;
    for( int i=0; i<32; i++ )
    {
        h = map(ro + rd*t);
        res = min( res, k*h/t );
		t += clamp( h, 0.005, 0.5 );
    }
    return clamp(res,0.0,1.0);
}


// From https://iquilezles.org/articles/normalsSDF/
vec3 calcNormal( in vec3 pos)
{
    const float h = NORM_EPS;
    #define ZERO (min(iFrame,0)) // non-constant zero
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*h);
    }
    return normalize(n);
}


float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos + h*nor );
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 1.0*occ, 0.0, 1.0 ) * (0.8+0.2*nor.y);
}


//Tonemapping
// -----------------------------------------------------------------

// linear to tonemapped
vec3 ACES(vec3 x) {
    return x*(2.51*x + .03) / (x*(2.43*x + .59) + .14); // https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
}

// tonemapped to linear
vec3 ACES_Inv(vec3 x) {
    return (sqrt(-10127.*x*x + 13702.*x + 9.) + 59.*x - 3.) / (502. - 486.*x); // thanks to https://www.wolframalpha.com/input?i=2.51y%5E2%2B.03y%3Dx%282.43y%5E2%2B.59y%2B.14%29+solve+for+y
}



// Rendering functions
// -----------------------------------------------------------------
// https://learnopengl.com/PBR/Theory

// Irridescent thin film interference effect
vec3 thinFilm(float ndotv, float thickness, float metallic) {
    // Relative wavelengths of each component
    const vec3 freqs = vec3(700./435., 565./435., 1.);
    const float ior = 2.;
    float n2 = sin(acos(ndotv)) / ior;
    float cos2 = cos(asin(n2));
    float dist = thickness / cos2;
    
    // Strength of thin film effect is controlled by reflection angle
    // and mettalicity of material.
    // Power to make irridescence stronger
    float strength = pow(metallic * ndotv, 0.2);
    
    vec3 rgb = (cos(dist * freqs) *strength * 0.5) + vec3(0.5);
    return rgb;
}

float DistributionGGX(vec3 N, vec3 H, float roughness)
{
    float a      = roughness*roughness;
    float a2     = a*a;
    float NdotH  = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;
	
    float num   = a2;
    float denom = (NdotH2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
	
    return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;

    float num   = NdotV;
    float denom = NdotV * (1.0 - k) + k;
	
    return num / denom;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2  = GeometrySchlickGGX(NdotV, roughness);
    float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	
    return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

vec3 light(
    vec3 light_dir, vec3 light_col, vec3 normal, vec3 rd, float attenuation,
    vec3 albedo, float roughness, float metallic, vec3 F0, float film_thickness, float sss
) {
        // Shading calculations
        vec3 V = -rd; // Camera direction
        vec3 H = normalize(light_dir - rd);
        
        float ndotl = max(dot(normal, light_dir), 0.);
        float hdotv = max(dot(H, V), 0.);
        float ndotv = max(dot(normal, V), 0.);
        
        vec3 radiance = light_col * attenuation;
        
        vec3 F = fresnelSchlickRoughness(hdotv, F0, roughness);
        F *= thinFilm(ndotv, film_thickness, metallic);
        
        
        float NDF = DistributionGGX(normal, H, roughness);
        float G   = GeometrySmith(normal, V, light_dir, roughness);
        
        vec3 numerator    = NDF * G * F;
        float denominator = 4.0 * ndotv * ndotl  + 0.0001;
        vec3 specular     = numerator / denominator; 
        
        vec3 kS = F;
        vec3 kD = vec3(1.0) - kS;

        kD *= 1.0 - metallic;
        
        return (kD * albedo / PI + specular) * radiance * max((dot(normal, light_dir) + sss) / (1. + sss), 0.);;
}

vec3 ambient(
    vec3 normal, vec3 rd, float ao,
    vec3 albedo, float roughness, float metallic, vec3 F0, float film_thickness
) {
    vec3 V = -rd;
    vec3 F = fresnelSchlickRoughness(max(dot(normal, V), 0.0), F0, roughness);
    
    vec3 R = reflect(-V, normal);
    
    F *= thinFilm(dot(V, normal), film_thickness, metallic);
    // Diffuse
    vec3 kS = F;
    vec3 kD = 1.0 - kS;
    vec3 irradiance = textureLod(iChannel1, normal.zyx, 4.8).rgb + ambient_boost;
    vec3 diffuse    = irradiance * albedo;
    
    //Specular
    const float MAX_REFLECTION_LOD = 16.0;
    vec3 prefilteredColor = textureLod(iChannel0, R.zyx,  roughness * MAX_REFLECTION_LOD + 1.).rgb;  
    
    
    vec2 envBRDF  = texelFetch(iChannel2, ivec2(vec2(max(dot(normal, V), 0.0), roughness) / vec2(255.)), 0).rg;
    vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y) * albedo;
    
    return (kD * diffuse + specular) * ao;
}

// -----------------------------------------------------------------

// Animation functions
float gain(float x, float k) 
{
    float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}

float parabola( float x, float k )
{
    return pow( 4.0*x*(1.0-x), k );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    vec3 ro, rd;
    
    vec2 camRot = vec2(2.,3.5)+vec2(-4.,7.)*(iMouse.yx/iResolution.yx);
    if(iMouse.xy == vec2(0., 0.)){
        camRot = vec2(-0.2 + 0.05 * cos(iTime * 0.3), 0.9 + 0.08 * sin(iTime * 0.5));
    }
    
    CamPolar(ro, rd,
             cam_origin, // Origin
             camRot, // Rotation
             3., // Distance
             1.2, //Zoom
             fragCoord);
    
    head_dir = 0.01 * sin(iTime * 2.5);
    
    float st = sin(iTime * 0.3);
    st = st * st * st * st;
    
    
    head_dir += (gain(st, 30.) - 0.5) * 1.;
    
    head_bob = -0.05 * parabola(st, 80.);
    body_bob = 0.005 * sin(iTime * 2.);
    
    vec3 sun_dir = normalize(vec3(-0.25, 1., -1.));
    vec3 sun_color = vec3(25., 22., 20.);
    
    float dist;
    
    vec3 color;
    if (intersect(ro, rd, dist)) {
        //Foreground object
        vec3 hit_pt = ro + rd * dist;
        
        // Get material
        vec3  albedo; // Subsurface color
        float roughness;
        float ao;          // Microsurface AO
        float metallic;
        float film_thickness;
        float sss; // Subsurf. scattering
        vec3 normal;
        
        material(hit_pt, albedo, roughness, ao, metallic, film_thickness, sss, normal);
        
        // Square roughness
        roughness = roughness * roughness;
        
        vec3 F0 = mix(vec3(0.04), albedo, metallic);
        
        // Calculate AO and shadows
        
        ao = ao * calcAO(hit_pt, normal);
        float shadow = softShadow(hit_pt + normal * dist * SHADOW_BIAS, sun_dir, 0.01, 6.);
        float attenuation = shadow * ao;
        
        
        // Shading calculations
        vec3 Lo = light(sun_dir, sun_color, normal, rd, attenuation, albedo, roughness, metallic, F0, film_thickness, sss);
        vec3 ambient = ambient(normal, rd, ao, albedo, roughness, metallic, F0, film_thickness);
        
        color = Lo + ambient * 3.;
        color = ACES(color);

        fragColor = vec4(color, 1.);
    } else {
        //Background
        fragColor.rgb = textureLod(iChannel0, rd.zyx, 1.4).rgb;
    }
    
    
}