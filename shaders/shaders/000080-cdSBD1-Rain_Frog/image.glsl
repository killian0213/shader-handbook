// Image (image) — Rain Frog by tristanantonsen
// https://www.shadertoy.com/view/cdSBD1

// Ray marching constants
#define MAX_STEPS 300
#define SURF_DIST 0.001
#define MAX_DIST 100.0
#define PI 3.141592653592
#define TAU 6.283185307185


////////////////////////////////////////////////////////////////
// Noise
////////////////////////////////////////////////////////////////

// Hash & voronoi from iq: https://www.shadertoy.com/view/ldl3Dl
vec3 hash( vec3 x )
{
	x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
			  dot(x,vec3(269.5,183.3,246.1)),
			  dot(x,vec3(113.5,271.9,124.6)));

	return fract(sin(x)*43758.5453123);
}
vec3 voronoi( in vec3 x )
{
    vec3 p = floor( x );
    vec3 f = fract( x );

	float id = 0.0;
    vec2 res = vec2( 100.0 );
    for( int k=-1; k<=1; k++ )
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec3 b = vec3( float(i), float(j), float(k) );
        vec3 r = vec3( b ) - f + hash( p + b );
        float d = dot( r, r );

        if( d < res.x )
        {
			id = dot( p+b, vec3(1.0,57.0,113.0 ) );
            res = vec2( d, res.x );			
        }
        else if( d < res.y )
        {
            res.y = d;
        }
    }

    return vec3( sqrt( res ), abs(id) );
}

////////////////////////////////////////////////////////////////
// Signed Distance Functions
////////////////////////////////////////////////////////////////
// From or adapted from iq: https://iquilezles.org/articles/distfunctions/

float sdPlane( vec3 p, vec3 n, float h )
{
  return dot(p,normalize(n)) + h;
}

float sdSphere( vec3 p, vec3 c, float r )
{
    return length(p-c) - r;
}

float sdEllipsoid( vec3 po, vec3 c, vec3 r )
{
    vec3 p = po-c;

    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

////////////////////////////////////////////////////////////////
// SDF Operations
////////////////////////////////////////////////////////////////
// Also from or adapted from iq: https://iquilezles.org/articles/distfunctions/

float opUnion(float d1, float d2 ) { return min(d1,d2); }

float opSubtraction(float d1, float d2) {
    //NOTE: Flipped order because it makes more sense to me
    return max(-d2, d1);
}
float opIntersection(float d1, float d2) {
    return max(d1, d2);
}

float opSmoothUnion(float d1, float d2, float k) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}
float opSmoothSubtraction(float d1, float d2, float k) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d1, -d2, h ) + k*h*(1.0-h);
}
float opSmoothIntersection(float d1, float d2, float k){
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

////////////////////////////////////////////////////////////////
// Rotations
////////////////////////////////////////////////////////////////

vec3 rotX(vec3 p, float a) {
    float s = sin(a);
    float c = cos(a);
    mat3 m = mat3(
        1., 0., 0.,
        0., c, -s,
        0., s, c
        );
    return m * p;
}

vec3 rotY(vec3 p, float a) {
    float s = sin(a);
    float c = cos(a);
    mat3 m = mat3(
        c, 0., s,
        0., 1., 0.,
        -s, 0., c
        );
    return m * p;
}

vec3 orbitControls(vec3 po) {
    vec2 m = (vec2(iMouse.x, iMouse.y) / iResolution.xy) + 0.5;
    vec3 p = po;
    p = rotY(po, -(m.x+1.)*TAU + PI * 0.95);
    return p;
}


////////////////////////////////////////////////////////////////
// Ray Marching Functions
////////////////////////////////////////////////////////////////

vec2 map(vec3 po) {

    float f = 0.06; // ribbet frequency
    vec3 p = orbitControls(vec3(po.x, po.y, po.z)); // track mouse
    vec3 pSym = vec3(abs(p.x),p.y,p.z);
    
    vec2 res = vec2(1.0);
    
    // ribbet timing
    float w = 1.5;
    float rt = sin(w * iTime);
    rt = max(rt, sin(w * iTime + PI/3.));
    rt = rt * 0.5 + 1.;
    
    // Body
    float body = sdEllipsoid(p, vec3(0.), vec3(0.7, 0.5, 0.7) * 1. + (0.025 * rt));
    body = opSmoothUnion(body,sdEllipsoid(p, vec3(0.,-0.1,0.025), vec3(0.8, 0.5, 0.75)), 0.1);
    
    // Head
    vec3 pr = rotX(p+vec3(0., -0.25, 0.4), -PI/3.);
    float head = sdEllipsoid(pr, vec3(0.), vec3(0.38, 0.325, 0.4));
    res.x = opSmoothUnion(body, head, 0.3);
    res.x += 0.0 * sin(50.*head) * smoothstep(1.,0.,5.*head);

    // eyelid
    float lid = sdEllipsoid(pSym, vec3(0.24,0.444 + (0.01 * rt), -0.525), vec3(0.16, 0.14, 0.16));
    res.x = opSmoothUnion(res.x, lid, 0.04);
    
    // eye
    float eye = sdSphere(pSym, vec3(0.27,0.43 + (0.012 * rt),-0.58),0.115);
    res.x -= 0.02 * sin(60.*eye) * smoothstep(1.,0.,20.*eye);
    if (eye-0.005 < res.x) {res.y = 2.0;};
    res.x = opSmoothUnion(res.x, eye, 0.006);

    //nose
    float nose = sdSphere(p, vec3(0.,0.45,-0.67),0.01);
    res.x = opSmoothUnion(res.x, nose, 0.25);


    // mouth/face
    pr = rotX(p+vec3(0., -0.12, 0.655), -0.35);
    float face = sdEllipsoid(pr, vec3(0.), vec3(0.27, 0.3, 0.1));
    float faceBool = sdEllipsoid(pr+vec3(0.,0. + (0.032 * rt),0.02), vec3(0.), vec3(0.26, 0.4, 0.04));
    res.x = opSmoothSubtraction(res.x, faceBool, 0.02);
    res.x = opSmoothUnion(res.x, face, 0.01);

    // Ribbet
    float rb = sdSphere(p, vec3(0.,0.0,-0.6),0.16);
    res.x = opSmoothUnion(res.x,rb,0.2 * rt);
    
    // Arms
    vec3 elbow = vec3(0.62,-0.3,-0.4);
    vec3 shoulder = vec3(0.5,-0.1,-0.4);
    vec3 wrist = vec3(0.57,-0.45,-0.45);
    float upperArm = sdCapsule(pSym, shoulder,elbow, 0.08);
    res.x = opSmoothUnion(res.x, upperArm, 0.1);
    res.x += 0.01 * sin(40.*upperArm) * smoothstep(1.,0.,5.*upperArm);
    float foreArm = sdCapsule(pSym, elbow+vec3(0.,-0.05,0.), wrist, 0.08);
    res.x = opSmoothUnion(res.x, foreArm, 0.05);

    // Fingers
    float f1 = sdCapsule(pSym, wrist-vec3(0.,0.03,0.03), wrist-vec3(0.15,0.02,0.005), 0.04);
    float f2 = sdCapsule(pSym, wrist-vec3(0.,0.03,0.03), wrist-vec3(0.2,0.04,0.06), 0.04);
    float f3 = sdCapsule(pSym, wrist-vec3(0.,0.03,0.03), wrist-vec3(0.15,0.05,0.12), 0.04);

    res.x = opSmoothUnion(res.x, f1, 0.04);
    res.x = opSmoothUnion(res.x, f2, 0.04);
    res.x = opSmoothUnion(res.x, f3, 0.04);
    
    // Legs
    vec3 knee = vec3(0.55,-0.45,0.425);
    float upperLeg = sdCapsule(pSym, vec3(0.4,-0.2,.475),knee, 0.07);
    res.x = opSmoothUnion(res.x, upperLeg, 0.1);
    res.x += 0.01 * sin(40.*upperLeg) * smoothstep(1.,0.,5.*upperLeg);

    // Butt
    float c = sdSphere(pSym, vec3(0.15,-0.15,.65),0.115);
    res.x = opSmoothUnion(res.x, c, 0.15);

    // Toes
    float t1 = sdCapsule(pSym, knee-vec3(0.,0.03,0.), knee-vec3(-0.18, 0.05,0.12), 0.04);
    float t2 = sdCapsule(pSym, knee-vec3(0.,0.03,0.), knee-vec3(-0.13, 0.05,0.18), 0.04);
    float t3 = sdCapsule(pSym, knee-vec3(0.,0.03,0.), knee-vec3(-0.06, 0.05,0.18), 0.04);
    
    res.x = opSmoothUnion(res.x, t1, 0.04);
    res.x = opSmoothUnion(res.x, t2, 0.04);
    res.x = opSmoothUnion(res.x, t3, 0.04);

    // Ground
    float gnd = sdRoundedCylinder(po+vec3(0.,0.78,0.) , 0.8, 0.1, 0.15);
    if (gnd-0.005 < res.x) {res.y = 3.0;};
    res.x = opUnion(res.x, gnd);    
        
    return res;
}

vec2 rayMarch(vec3 ro, vec3 rd) {
    float d = 0.0;
    float mat = 1.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        if (i >= MAX_STEPS ) break;
        vec3 p = ro + rd * d;
        vec2 ds = map(p);
        d += ds.x;
        mat = ds.y;
        if (d >= MAX_DIST || ds.x < SURF_DIST) break;
        i++;
    }
    return vec2(d, mat);
}

// from iq: https://iquilezles.org/articles/rmshadows/
float softShadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = map(ro + rd*t).x;
        if( h<0.001 )
            return 0.0;
        res = min( res, k*h/t );
        t += h;
    }
    return res;
}


vec3 gradient(vec3 p) {
    float epsilon = 0.0001;
    vec3 dx = vec3(epsilon, 0., 0.0);
    vec3 dy = vec3(0., epsilon, 0.0);
    vec3 dz = vec3(0., 0.0, epsilon);

    float ddx = map(p + dx).x - map(p - dx).x;
    float ddy = map(p + dy).x - map(p - dy).x;
    float ddz = map(p + dz).x - map(p - dz).x;
    
    return normalize(vec3(ddx, ddy, ddz));
}

vec3 rayDirection(vec2 p, vec3 ro, vec3 rt) {

    // screen orientation
    vec3 vup = vec3(0., 1.0, 0.0);
    float aspectRatio = iResolution.x / iResolution.y;
    
    // camera orientation from https://raytracing.github.io/books/RayTracingInOneWeekend.html
    vec3 vw = normalize(ro - rt);
    vec3 vu = normalize(cross(vup, vw));
    vec3 vv = cross(vw, vu);
    float theta = radians(30.); // half FOV
    float viewport_height = 2. * tan(theta);
    float viewport_width = aspectRatio * viewport_height;
    vec3 horizontal = -viewport_width * vu;
    vec3 vertical = viewport_height * vv;
    float focus_dist = length(ro - rt);
    vec3 center = ro - vw * focus_dist;

    vec3 rd = center + p.x * horizontal + p.y * vertical - ro;

    return normalize(rd);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord / iResolution.xy - 0.5) * 2.0; // normalizing

    // Ray Marching
    vec3 rt = vec3(-0.4 + 0.01 * sin(0.5*iTime), -0.2, 2.);
    vec3 ro = vec3(-0.4 + 0.1 * cos(0.5*iTime), 0.5, -5.);

    vec3 rd = rayDirection(uv, ro, rt);
    vec2 d = rayMarch(ro, rd);

    // Background
    float v = length(uv) * .75;
    vec3 col = mix(vec3(0.8, 0.8, 0.55), vec3(0.45, 0.55, 0.35), smoothstep(0.0, 1.0, uv.y));
    fragColor = vec4(col, 1.);
	fragColor += mix(vec4(0.1), vec4(0.0, 0.15, 0.0, 1.0), v); // vignette
    fragColor *= mix(vec4(0.5,0.6,0.6,1.), vec4(1.), smoothstep(-1.,1.,uv.x)); // darken left
    
    float vb = voronoi( 2. * vec3(2.,1.,1.) * vec3(uv, 1.)).x;
    fragColor.xyz *= mix(0.7,1.,smoothstep(0.,1.,vb));


    if (d.x <= 100.0) {
        vec3 p = ro + rd * d.x;
        vec3 pr = orbitControls(p);
        vec3 N = gradient(p);

        // Simple surface texture
        if (d.y == 1.) N += voronoi( 50.*pr).x * 0.13;
        
        // Lighting (partial phong shading)
        vec3 lightPos1 = vec3(1, 1,-1);
        float light1 = dot(N, normalize(lightPos1))*.5+.5;
        light1 *= 1.5;
        vec3 L1 = vec3(1, 1,-1);
        float light2 = dot(N, normalize(vec3(-1, 1,-1)))*.5+.5;
        vec3 lightVal = 0.5 * vec3(light1) + 0.5 * vec3(light2);
        
        // Specular highlights
        vec3 R = reflect(L1, N);
        vec3 specular = vec3(1.0) * pow(max(dot(R, rd), 0.0),10.0);
        vec3 color;

        // Color assignment
        // Color assignment method adapted from iq: https://www.youtube.com/watch?v=Cfe5UQ-1L9Q&t=8470s
        // A breakdown in my other shader: https://www.shadertoy.com/view/cdlBDl
        if (d.y == 1.) color = vec3(0.3, 0.5, 0.2) + specular * 0.0006; // body
        if (d.y == 2.) color = vec3(0.05) + specular * 0.004; // eyes
        if (d.y == 3.) color = vec3(0.15, 0.25, 0.1);
        
        // Skin colors
        float c = 1. - voronoi( 10.*pr).x;
        // blended based on distance from a point above the frog
        float tFac = mix(0., 1., smoothstep(0.,1., length(p-vec3(0.,0.7,0.5))-0.5));
        color = mix(color, vec3(0.16, 0.16, 0.1), c * (1.-tFac));
        
        // shadows
        float res = softShadow(p+N*0.01, normalize(lightPos1-p), 0.01, 5., 2.);
        
        if (p.y <= -0.525) {
            float res2 = softShadow(p+N*0.01, vec3(0.,1.,0.), 0.01, 5., 2.);
            color *= 1.0 - mix(0.4,0.,smoothstep(0.,1., res2));;
        }
        
        color *= 1.0 - mix(0.3,0.,smoothstep(0.,1., res));
        
        // fake fresnel
        float nDotV = dot(N, rd) + 1.;
        color += nDotV * nDotV * 0.35 * res;
        
        
        fragColor = vec4(lightVal*color, 1.0);
    }
   
   
}