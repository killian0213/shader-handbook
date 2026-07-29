// Common (common) — Reservoir sampling by iq
// https://www.shadertoy.com/view/stVfWc

#define USE_TEMPORAL 1
#define USE_SPATIAL  1


//=====================================================
// rand
//=====================================================

int   seed = 1;
int    rand(void) { seed=seed*0x343fd+0x269ec3; return (seed>>16)&32767; }
float frand(void) { return float(rand())/32767.0; }
void  srand(ivec2 p, int frame)
{
    int n = 0;
    n += frame; n=(n<<13)^n; n=n*(n*n*15731+789221)+1376312589; // hash by Hugo Elias
    n += p.y;   n=(n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    n += p.x;   n=(n<<13)^n; n=n*(n*n*15731+789221)+1376312589;
    seed = n;
}

//=====================================================
// Geometry
//=====================================================

// https://iquilezles.org/articles/intersectors
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.0) return vec2(-1.0);

	return vec2( tN, tF );
}

vec3 cosineDirection( in vec2 uv, in vec3 nor )
{
    float a = 6.2831853*uv.x; float b = 2.0*uv.y-1.0;
    vec3 dir = vec3(sqrt(1.0-b*b)*vec2(cos(a),sin(a)),b);
    return normalize( nor + dir );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

//=====================================================
// Reservoir
//=====================================================

struct Reservoir
{
	float y;       // sample, stored as a fibonacci direction in the sphere
	float wsum;
	float m;
};

Reservoir combineReservoirs( Reservoir a, Reservoir b )
{
    Reservoir s;
    s.y = ( frand()*(a.wsum+b.wsum)<=a.wsum ) ? a.y : b.y;
    s.wsum = a.wsum + b.wsum;
    s.m = a.m + b.m;
    return s;
}

//=====================================================
// find closest Fibonacci points in a sphere
// https://dl.acm.org/doi/10.1145/2816795.2818131
//=====================================================

const float PI = 3.1415926535897932384626433832795;
const float PHI = 1.6180339887498948482045868343656;

float madfrac( float a,float b) { return a*b -floor(a*b); }
vec2  madfrac( vec2  a,float b) { return a*b -floor(a*b); }
const float kConvPrecis = float(1<<21);
float nor_to_id(vec3 p) 
{
    const float n = kConvPrecis;
    float phi = min(atan(p.y, p.x), PI), cosTheta = p.z;
    
    float k  = max(2.0, floor( log(n * PI * sqrt(5.0) * (1.0 - cosTheta*cosTheta))/ log(PHI*PHI)));
    float Fk = pow(PHI, k)/sqrt(5.0);
    
    vec2 F = vec2( round(Fk), round(Fk * PHI) );

    vec2 ka = -2.0*F/n;
    vec2 kb = 2.0*PI*madfrac(F+1.0, PHI-1.0) - 2.0*PI*(PHI-1.0);    
    mat2 iB = mat2( ka.y, -ka.x, -kb.y, kb.x ) / (ka.y*kb.x - ka.x*kb.y);

    vec2 c = floor( iB * vec2(phi, cosTheta - (1.0-1.0/n)));
    float d = 8.0;
    float j = 0.0;
    for( int s=0; s<4; s++ ) 
    {
        vec2 uv = vec2( float(s-2*(s/2)), float(s/2) );
        
        float cosTheta = dot(ka, uv + c) + (1.0-1.0/n);
        
        cosTheta = clamp(cosTheta, -1.0, 1.0)*2.0 - cosTheta;
        float i = floor(n*0.5 - cosTheta*n*0.5);
        float phi = 2.0*PI*madfrac(i, PHI-1.0);
        cosTheta = 1.0 - (2.0*i + 1.0)/n;
        float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
        
        vec3 q = vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, cosTheta);
        float squaredDistance = dot(q-p, q-p);
        if (squaredDistance < d) 
        {
            d = squaredDistance;
            j = i;
        }
    }
    return j;
}

vec3 id_to_nor( float i) 
{
    const float n = kConvPrecis;
    float phi = 2.0*PI*madfrac(i,PHI);
    float zi = 1.0 - (2.0*i+1.0)/n;
    float sinTheta = sqrt( 1.0 - zi*zi);
    return vec3( cos(phi)*sinTheta, sin(phi)*sinTheta, zi);
}

//=====================================================
// SDFs
// https://iquilezles.org/articles/distfunctions/
//=====================================================

float ndot(vec2 a, vec2 b ) { return a.x*b.x - a.y*b.y; }

float sdRhombus( in vec2 p, in vec2 b, in float r ) 
{
    vec2 q = abs(p);
    float h = clamp( (-2.0*ndot(q,b) + ndot(b,b) )/dot(b,b), -1.0, 1.0 );
    float d = length( q - 0.5*b*vec2(1.0-h,1.0+h) );
    d *= sign( q.x*b.y + q.y*b.x - b.x*b.y );
	return d - r;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float opRepLim( in float p, in float s, in float lima, float limb, out float id )
{
    id = round(p/s);
    return p-s*clamp(id,-lima,limb);
}

vec2 opRepLim( in vec2 p, in float s, in vec2 lim, out vec2 id )
{
    id = round(p/s);
    return p-s*clamp(id,-lim,lim);
}

vec2 opRepLim( in vec2 p, in float s, in vec2 limmin, in vec2 limmax, out vec2 id )
{
    id = round(p/s);
    return p-s*clamp(id,-limmin,limmax);
}
float opExtrussion( in float sdf, float z, in float h )
{
    vec2 w = vec2( sdf, abs(z) - h );
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

//=====================================================
// scene data
//=====================================================
float hash1( vec2 p ) { p = 50.0*fract( p*0.3183099 ); return fract( p.x*p.y*(p.x+p.y) ); }
vec2 map( in vec3 p )
{
    vec3 op = p;
    p.y += 2.0;
    float ma = 0.0;

    // columns
    vec2 id;
    vec3 q = p; q.xz = opRepLim( q.xz, 4.0, vec2(4.0,2.0), id );
    float d = length(q.xz) - 0.9 + 0.05*p.y;
    d = max(d,p.y-6.0);
    d = max(d,-p.y-5.0);
    d -= 0.05*pow(0.5+0.5*sin(atan(q.x,q.z)*16.0),2.0);
    d -= 0.15*pow(0.5+0.5*sin(q.y*3.0+0.6),0.12) - 0.15;
    ma = floor(50.0*hash1( id + 11.2*floor(0.25 + (q.y*3.0+0.6)/6.2831) ));
    d *= 0.85;
    vec3 w = vec3(q.x,abs(q.y-0.3)-5.5, q.z );
    d = min( d,  sdBox(w,vec3(1.4,0.2,1.4)+sign(q.y-0.3)*vec3(0.1,0.05,0.1))-0.1 ); // base
    d = max( d, -sdBox(p,vec3(14.0,10.0,6.0)) ); // clip in

    // floor
    p.y -= 0.1;
    float bb1 = op.y+7.0;
    if( bb1<d ) //  bounding plane
    {
        vec2 id0 = round(p.xz/4.0);
        vec2 off = step(vec2(0.0), p.xz/4.0-id0);
        for( int j=0; j<2; j++ )
        for( int i=0; i<2; i++ )
        {
            vec2 id = id0 + vec2(i,j) - off;
            id = clamp( id, -vec2(4.0,3.0), vec2(4.0,3.0) );
            vec2 ce = id*4.0;
            q = p-vec3(ce.x,0.0,ce.y);

            float ra = 1.0*0.05 * hash1(id+vec2(1.0,3.0));
            float b = sdBox( q-vec3(0.0,-6.0-ra,0.0), vec3(2.0,0.5,2.0)-0.1-ra )-0.1;
            if( b<d ) { d = b; ma = floor(20.0*hash1(id)); }
        }
    }

    float bb2 = op.y+8.0;
    if( bb2<d ) //  bounding plane
    {
        p.xz -= 2.0;
        
        vec2 id0 = round(p.xz/4.0);
        vec2 off = step(vec2(0.0), p.xz/4.0-id0);
        for( int j=0; j<2; j++ )
        for( int i=0; i<2; i++ )
        {
            vec2 id = id0 + vec2(i,j) - off;
            id = clamp( id, -vec2(5.0,4.0), vec2(4.0,3.0) );
            vec2 ce = id*4.0;
            q = p-vec3(ce.x,0.0,ce.y);
            
            float ra = 0.15 * hash1(id+vec2(1.0,3.0)+23.1);
            float b = sdBox( q-vec3(0.0,-7.0-ra,0.0), vec3(2.0,0.6,2.0)-0.1-ra )-0.1;
            if( b<d ) { d = b; ma = floor(20.0*hash1( id + 13.5 )); }
        }
        p.xz += 2.0;
    }    
     
    float bb3 = op.y+9.0;
    if( bb3<d ) //  bounding plane
    {
        vec2 id0 = round(p.xz/4.0);
        vec2 off = step(vec2(0.0), p.xz/4.0-id0);
        for( int j=0; j<2; j++ )
        for( int i=0; i<2; i++ )
        {
            vec2 id = id0 + vec2(i,j) - off;
            id = clamp( id, -vec2(5.0,4.0), vec2(5.0,4.0) );
            vec2 ce = id*4.0;
            q = p-vec3(ce.x,0.0,ce.y);

            float ra = 0.15 * hash1(id+vec2(1.0,3.0)+37.7);
            float b = sdBox( q-vec3(0.0,-8.0-ra-1.0,0.0), vec3(2.0,0.6+1.0,2.0)-0.1-ra )-0.1;
            if( b<d ) { d = b; ma = floor(20.0*hash1( id*7.0 + 31.1 )); }
        }
    }

    // roof
    float bb4 = -(op.y-4.0);
    if( bb4<d ) //  bounding plane
    {
        {
        float id1;
        q = vec3(p.x,p.y,abs(p.z))-vec3(0.0,0.0,9.0);
        q.x = opRepLim( q.x, 4.0, 4.0, 4.0, id1 );
        float b = sdBox( q-vec3(0.0,7.0,0.0), vec3(1.95,1.0,0.95)-0.1 )-0.1;
        if( b<d ) { d = b; ma = floor(20.0*(id1+6.0)); }
        }
        {
        float id1;
        q = vec3(abs(p.x)+1.0,p.y,p.z-2.0)-vec3(17.0,0.0,0.0);
        q.z = opRepLim( q.z, 4.0, 2.0, 1.0, id1 );
        float b = sdBox( q-vec3(0.0,7.0,0.0), vec3(1.95,1.0,1.95)-0.1 )-0.1;
        if( b<d ) { d = b; ma = floor(30.0*(id1+6.0)); }
        }

        q = p; q.xz = opRepLim( q.xz+0.5, 1.0, vec2(18,10),vec2(19,11), id );
        float b = sdBox( q-vec3(0.0,8.0,0.0), vec3(0.45,0.2,0.47)-0.05 )-0.05;
        if( b<d ) { d = b; ma = floor(20.0*hash1( id + 7.8 )); }

        b = sdRhombus( p.yz-vec2(8.2,0.0), vec2(3.0,10.8), 0.0 ) ;
        b = opExtrussion( b, p.x, 19.0-0.1 )-0.1;
        q = vec3( mod(p.x+1.0,2.0)-1.0, p.y, mod(p.z+1.0,2.0)-1.0 );
        b = max( b, -sdBox( vec3( abs(p.x)-20.0,p.y,q.z)-vec3(0.0,8.0,0.0), vec3(2.0,5.0,0.1) )-0.05 );
        b = max( b, -p.y+8.2 );
        
        float bma = 13.0;
        float c = sdRhombus( p.yz-vec2(8.2,0.0), vec2(2.25,8.7), 0.05 );
        c = opExtrussion( c, abs(p.x)-19.0, 2.0 );
        if( -c>b ) { b=-c; bma = 12.0; }
        
        b = max( b,-sdBox(p-vec3(0.0,9.5,0.0),vec3(15.0,2.0,9.0)) );
        if( b<d ) { d=b; ma=bma; }
    }

    return vec2( d, ma );
}

vec2 raycast( in vec3 ro, in vec3 rd )
{
    vec2 b = iBox( ro-vec3(0.0,-2.0,0.0), rd, vec3(24.0,12.0,19.0) );
    if( b.y>0.0 )
    {
        b.x = max(0.001,b.x);
        
        float tmax = b.y;
        float t = b.x;
        for( int i=0; i<256; i++ )
        {
            vec3 pos = ro + t*rd;
            vec2 h = map( pos );
            if( h.x<(0.001*t) ) return vec2(t,1.0+h.y);
            t += h.x*0.9;
            if( t>tmax ) break;
        }
    }
    
    return vec2(1e20,-1.0);
}

vec3 calcNormal( in vec3 p, in float t )
{
#if 0
    float e = 0.001*t;

    vec2 h = vec2(1.0,-1.0)*0.5773;
    return normalize( h.xyy*map( p + h.xyy*e ).x + 
					  h.yyx*map( p + h.yyx*e ).x + 
					  h.yxy*map( p + h.yxy*e ).x + 
					  h.xxx*map( p + h.xxx*e ).x );
#else    
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+e*0.001*t).x;
    }
    return normalize(n);
#endif    
}

const float kFocalLength = 2.0;

void raster_to_camera( in vec2 px, in vec2 resolution, in float time, out vec3 ro, out vec3 rd, out mat3 ca )
{
    vec2 p = (2.0*px-resolution) / resolution.y;

    float h = 0.5 - 0.5*cos(time*0.13);
    vec3 ta = vec3(0.0, -5.0*h, 0.0 );
	ro = vec3(38.0*cos(time*0.1), 10.0*h, 25.0*sin(time*0.1) );

    ca = setCamera( ro, ta, 0.0 );
    rd = ca * normalize( vec3(p,kFocalLength));
}

vec2 camera_to_raster( vec3 cpos, vec2 resolution )
{
    // convert camera to ndc
    vec2 npos = kFocalLength * cpos.xy / cpos.z;
    
    // convert ndc to screen space
    vec2 spos = 0.5 + 0.5*npos*vec2(resolution.y/resolution.x,1.0);
    
	// convert screen to raster space
    return spos * resolution;
}    

// note I'm normalizing the ray distance to 60 units so that I can encode
// object ID and ray distance in a single float (as integer and decimal parts)
float tm_to_float( in vec2 tm )
{
    return tm.y + ((tm.y<0.0)?0.0:clamp(tm.x/60.0,0.0,1.0));
}

vec2 float_to_tm( in float f )
{
    return vec2(fract(f)*60.0, floor(f) );
}

vec4 store_gbuffer( Reservoir r, vec2 tm )
{
    return vec4( r.y, r.wsum, r.m, 
                 tm.y + ((tm.y<0.0)?0.0:clamp(tm.x/60.0,0.0,1.0)) );
}

void read_gbuffer( vec4 data, out Reservoir r, out vec2 tm )
{
    r = Reservoir( data.x, data.y, data.z );
    tm = vec2(fract(data.w)*60.0, floor(data.w) );
}