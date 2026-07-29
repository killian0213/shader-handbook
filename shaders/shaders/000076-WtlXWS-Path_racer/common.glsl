// Common (common) — Path racer by XT95
// https://www.shadertoy.com/view/WtlXWS

// Created by anatole duprat - XT95/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// All data of the game is defined here
// + some usefull functions :)

// Game
struct GameData {
    vec3 shipPos;
    vec3 shipLastPos;
    vec3 shipAccel;
    vec3 shipVelocity;
    vec3 shipDirection;
    float shipTheta;
    vec3 touchStart;
};
GameData readGameData(sampler2D tex, vec2 invRes);
vec4 writeGameData(vec4 col, vec2 fragCoord, GameData data);
float level(vec3 p);
float levelSafe(vec3 p);
vec3 normalLevel( vec3 p, const float eps );
float ship(vec3 p);
float world( vec3 p );
float worldSafe( vec3 p );

// Global
const vec3 sunDir = normalize( vec3(2., 1., .4) );
GameData data;
float time;
vec2 glowAcc; // minimal distance from the reactors and the laser (reset by calling raymarch())

// Math
#define PI 3.141592653589
#define saturate(x) clamp(x,0.,1.)
float hash( vec3 x );
float hash( vec2 p );
float hash( float p );
float hash2Interleaved( vec2 x );
float noise( vec3 x );
mat2 rotate( float t );
vec3 randomSphereDir( vec2 rnd );
vec3 randomHemisphereDir( vec3 dir, float i );

// data IO
float readData1(sampler2D tex, int id); 
vec3 readData3(sampler2D tex, int id);
vec4 readData4(sampler2D tex, int id);
vec4 writeData(vec4 col, vec2 fragCoord, int id, float value);
vec4 writeData(vec4 col, vec2 fragCoord, int id, vec3 value);
vec4 writeData(vec4 col, vec2 fragCoord, int id, vec4 value);



// SDF Toolbox
float box( vec3 p, vec3 b );
float caps( vec3 p, vec3 a, vec3 b, float r );
float torus( vec3 p, vec2 t );
float smin( float a, float b, float k );
vec3 raymarch( vec3 ro, vec3 rd, const vec2 nf, const float eps );
vec3 raymarchFast( vec3 ro, vec3 rd, const vec2 nf, const float eps );
vec3 normal( vec3 p, const float eps );
float ambientOcclusion( vec3 p, vec3 n, float maxDist, float falloff );
float shadow( vec3 ro, vec3 rd, float mint, float tmax );
float shadowFast( vec3 ro, vec3 rd, float mint, float tmax );


// ---------------------------------------------
// Game
// ---------------------------------------------
float level( vec3 p )
{
    float d = p.y ;
    
    // truchet tiles
    vec3 pp = p;
    vec2 pi = floor(pp.xz*.01);
    float rnd = hash(pi);
    pp.xz = mod(pp.xz, vec2(100.))-50.;
    
    
    
    pp.xz = rotate(floor(rnd*2.)*.5*PI) * pp.xz;
    if (rnd>.4) {
        d = p.y-12.+cos(p.z*.2)-length(pp)/10.;//+rnd*10.;
        d = max(d, -torus(pp-vec3(-50., 8.75,-50.), vec2(50.,8.5)));
        d = max(d, -torus(pp-vec3( 50., 8.75, 50.), vec2(50.,8.5)));
        d += sin(p.y)*.3;
        d += sin(p.x*.1)*.5;
        d += sin(p.z*.1)*.5;
        //d = min(d, p.y);
    } else if(rnd>.2){
        vec3 ppp = pp*.15+.5;
        ppp.y -= .5;
        d =  smin(p.y+1.,dot(cos(ppp),sin(ppp.zxy))/.15+length(pp)*.2,10.);
        pp = abs(pp);
    	d = smin(d, box(pp-vec3(31.,0.,48.), vec3(25.,20.,2.)),10.);
    	d = smin(d, box(pp-vec3(48.,0.,31.), vec3(2.,20.,25.)),10.);
    } else { 
        d = p.y-10.;
        d = max(d, -box(pp-vec3(0.,26.,0.),vec3(5.,26.,500.)));
        d = max(d, -box(pp-vec3(0.,26.,0.),vec3(500.,26.,5.)));
        d = min(d, box(pp-vec3(0.,11.,0.),vec3(10.,1.,10.)));
    }
    return d;
}
float levelSafe(vec3 p) {
    float d = level(p);
    
    // hackish way to avoid distance discontinuity on the edges of each tile
    vec3 pp = p;
    pp.xz = mod(pp.xz, vec2(100.))-50.;
    float a = -abs(pp.x)+50.1;
    a = min(a, -abs(pp.z)+50.1);
    a  = max(a, pp.y-20.);
    d = min(d,a);
    return d;
}
float ship(vec3 p) {
    p -= data.shipPos;
    p.xz = rotate(data.shipTheta) * p.xz;
    p.xy = rotate(-data.shipAccel.x*.6) * p.xy;
    
    float y = max(0.,data.shipAccel.y)*.15 + abs(data.shipAccel.x)*.15;
    
    // body
    float d = torus((p-vec3(0.,0.5,-.5)).zxy, vec2(.5,.08));
    d = smin(d, caps(p, vec3(0.0,.4,-.7), vec3(.0, .3, -.7),.1), 0.3);
    
    // reactor
    d = min(d, caps(p, vec3(1.,0.4-y,.8), vec3(1.,0.4+y,1.5), .25));
    d = min(d, caps(p, vec3(-1.,0.4-y,.8), vec3(-1.,0.4+y,1.5), .25));
    d = max(d, -length(p-vec3(-1.,0.4-y,.8))+.3);
    d = max(d, -length(p-vec3(1.,0.4-y,.8))+.3);
    float react = caps(p, vec3(1.,0.4-y,1.), vec3(1.,0.4-y,0.8), .1);
    react = min(react, caps(p, vec3(-1.,0.4-y,1.), vec3(-1.,0.4-y,0.8), .1));
    glowAcc.x = min(glowAcc.x,react);
    
    d = min(d, react);
    
    // lines
    d = smin(d, caps(p, vec3(-1.,0.4-y,1.7), vec3(0.,0.,0.), .05), .3);
    d = smin(d, caps(p, vec3(1.,0.4-y,1.7), vec3(0.,0.,0.), .05), .3);
    
    // laser
    p.y += noise(p*vec3(13.,0.,0.)+vec3(0.,0.,time*10.))*.01;
    float l = caps(p, vec3(-.75,0.4+y,1.3), vec3(.75,0.4+y,1.3), .01);
    glowAcc.y = min(glowAcc.y, l);
    d = min(d, l);
    
    return d;
}
vec3 normalLevel( vec3 p, const float eps ) {
    float d = level(p);
    vec2 e = vec2(eps, 0.);
    
    vec3 n;
    
    n.x = d - level(p-e.xyy);
    n.y = d - level(p-e.yxy);
    n.z = d - level(p-e.yyx);
    
    return normalize(n);
}
float world( vec3 p )
{
    float d = level(p);
    d = min(d, ship(p));
    return d;
}
float worldSafe( vec3 p )
{
    float d = levelSafe(p);
    d = min(d, ship(p));
    return d;
}


// ---------------------------------------------
// Data IO
// ---------------------------------------------
float readData1(sampler2D tex, int id) {
    return texelFetch(tex, ivec2(id,0), 0).r;
}
vec3 readData3(sampler2D tex, int id) {
    return texelFetch(tex, ivec2(id,0), 0).rgb;
}
vec4 readData4(sampler2D tex, int id) {
    return texelFetch(tex, ivec2(id,0), 0);
}
vec4 writeData(vec4 col, vec2 fragCoord, int id, float value) {
    if (floor(fragCoord.x) == float(id))
        col.r = value;
        
    return col;
}
vec4 writeData(vec4 col, vec2 fragCoord, int id, vec3 value) {
    if (floor(fragCoord.x) == float(id))
        col.rgb = value.rgb;
        
    return col;
}
vec4 writeData(vec4 col, vec2 fragCoord, int id, vec4 value) {
    if (floor(fragCoord.x) == float(id))
        col = value;
        
    return col;
}
GameData readGameData(sampler2D tex, vec2 invRes) {
	GameData data;
    
    data.shipPos = readData3(tex, 0);
    data.shipLastPos = readData3(tex, 1);
    data.shipAccel = readData3(tex, 2);
    data.shipVelocity = readData3(tex, 3);
    data.shipTheta = readData1(tex, 4);
    data.shipDirection = vec3(sin(data.shipTheta), 0.f, cos(data.shipTheta));
    data.touchStart = readData3(tex, 5);
    
    return data;
}
vec4 writeGameData(vec4 col, vec2 fragCoord, GameData data) {
    col = writeData(col, fragCoord.xy, 0, data.shipPos);
    col = writeData(col, fragCoord.xy, 1, data.shipLastPos);
    col = writeData(col, fragCoord.xy, 2, data.shipAccel);
    col = writeData(col, fragCoord.xy, 3, data.shipVelocity);
    col = writeData(col, fragCoord.xy, 4, data.shipTheta);
    col = writeData(col, fragCoord.xy, 5, data.touchStart);
    return col;
}
    

// ---------------------------------------------
// Math
// ---------------------------------------------
float hash( vec3 p )
{
    return fract(sin(dot(p,vec3(127.1,311.7, 74.7)))*43758.5453123);
}

float hash( vec2 p )
{
    return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123);
}

float hash( float p ) 
{
    return fract(sin(p)*43758.5453123);
}

float hash2Interleaved( vec2 x )
{
    // between random & dithered pattern
    // good for jittering and blur as well as blue noise :)
    // http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
    vec3 magic = vec3( 0.06711056, 0.00583715, 52.9829189 );
    return fract( magic.z * fract( dot( x, magic.xy ) ) );
}
float noise( vec3 x )
{
	// https://iquilezles.org/articles/gradientnoise
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);

    float a = hash( p+vec3(0,0,0) );
    float b = hash( p+vec3(1,0,0) );
    float c = hash( p+vec3(0,1,0) );
    float d = hash( p+vec3(1,1,0) );
    float e = hash( p+vec3(0,0,1) );
    float f = hash( p+vec3(1,0,1) );
    float g = hash( p+vec3(0,1,1) );
    float h = hash( p+vec3(1,1,1) );

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;
    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
}

mat2 rotate( float t ) {
    float a = cos(t);
    float b = sin(t);
    
    return mat2( a, b, -b, a );
}
vec3 randomSphereDir( vec2 rnd )
{
    float s = rnd.x*PI*2.;
    float t = rnd.y*2.-1.;
    return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}

vec3 randomHemisphereDir( vec3 dir, float i )
{
    vec3 v = randomSphereDir( vec2(hash(i+1.), hash(i+2.)) );
    return v * sign(dot(v, dir));
}

// ---------------------------------------------
// SDF Toolbox
// ---------------------------------------------
float box( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0);
}
float caps( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
float torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
vec3 raymarch( vec3 ro, vec3 rd, const vec2 nf, const float eps ) {
    glowAcc = vec2(999.);
    vec3 p = ro + rd * nf.x;
    float l = 0.;
    for(int i=0; i<128; i++) {
		float d = worldSafe(p);
        l += d;
        p += rd * d;
        
        if(d < eps || l > nf.y)
            break;
    }
    
    return p;
}
vec3 raymarchFast( vec3 ro, vec3 rd, const vec2 nf, const float eps ) {
    glowAcc = vec2(999.);
    vec3 p = ro + rd * nf.x;
    float l = 0.;
    for(int i=0; i<64; i++) {
		float d = world(p);
        l += d;
        p += rd * d*1.2;
        
        if(d < eps || l > nf.y)
            break;
    }
    
    return p;
}

vec3 normal( vec3 p, const float eps ) {
    float d = world(p);
    vec2 e = vec2(eps, 0.);
    
    vec3 n;
    
    n.x = d - world(p-e.xyy);
    n.y = d - world(p-e.yxy);
    n.z = d - world(p-e.yyx);
    
    return normalize(n);
}
float ambientOcclusion( vec3 p, vec3 n, float maxDist, float falloff )
{
	const int nbIte = 8;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv; //Hemispherical factor (self occlusion correction)
    
	float ao = 0.0;
    
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; // mix direction with the normal
        													    // for self occlusion problems!
        
        ao += (l - max(world( p + rd ),0.)) / maxDist * falloff;
    }
	
    return clamp( 1.-ao*nbIteInv, 0., 1.);
}

// https://www.shadertoy.com/view/lsKcDD
float shadow( vec3 ro, vec3 rd, float mint, float tmax )
{
	float res = 1.0;
    float t = mint;
    
    for( int i=0; i<64; i++ )
    {
		float h = worldSafe( ro + rd*t );
		res = min( res, 80.0*h/t );
        t += h;
        
        if( res<0.0001 || t>tmax ) break;
        
    }
    return clamp( res, 0.0, 1.0 );
}

float shadowFast( vec3 ro, vec3 rd, float mint, float tmax )
{
	float res = 1.0;
    float t = mint;
    
    for( int i=0; i<16; i++ )
    {
		float h = world( ro + rd*t );
		res = min( res, 80.0*h/t );
        t += h;
        
        if( res<0.0001 || t>tmax ) break;
        
    }
    return clamp( res, 0.0, 1.0 );
}