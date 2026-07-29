// Image (image) — Simplified Trefoil by iq
// https://www.shadertoy.com/view/lfSBzt

// Copyright Inigo Quilez, 2024 - https://iquilezles.org/
// I am the sole copyright owner of this Work. You cannot host, display,
// distribute or share this Work neither as it is or altered, here on
// Shadertoy or anywhere else, in any form including physical and digital.
// You cannot use this Work in any commercial or non-commercial product,
// website or project. You cannot sell this Work and you cannot mint an
// NFTs of it, and you cannot use it to train a Machine Learning model.
// I share this Work for educational purposes, and you can link to it,
// through an URL, proper attribution and unmodified screenshot, as part
// of your educational material. If these conditions are too restrictive
// please contact me and we'll definitely work it out.

// The experiment here was to crate a Trefoil shape with an implicit field
// that is a polynomial of the lowest degree possible. Of course, once can
// put some quadratic or cubic bezier segments together, but that would be
// just a piecewise solution, not a simple implicit function.
//
// I followed https://en.wikipedia.org/wiki/Trefoil_knot, and modified the
// the stereographic projection (broke it really), so the final polynomial
// is only of degree 8. See also https://www.shadertoy.com/view/fdyXWK


// make higher for a cleaner image
#define AA 2

// randoms
int   seed = 1;
void  srand(int s ) { seed = s; }
int   rand(void) { seed = seed*0x343fd+0x269ec3; return (seed>>16)&32767; } // oldschool rand() from Visual Studio
float frand(void) { return float(rand())/32767.0; }
int   hash( int n ) { n=(n<<13)^n; return n*(n*n*15731+789221)+1376312589; }// hash to initialize the random sequence (copied from Hugo Elias)

// intersect sphere (https://iquilezles.org/articles/intersectors/)
vec2 iSphere( in vec3 ro, in vec3 rd, in vec4 sph )
{
	vec3  ce = ro - sph.xyz;
	float b = dot( rd, ce );
	float c = dot( ce, ce ) - sph.w*sph.w;
	float h = b*b - c;
	if( h<0.0 ) return vec2(-1.0);
	h = sqrt(h);
    return vec2(-b-h,-b+h);
}

#define ZERO (min(iFrame,0))
//===============================================================================================

vec3 texture_3d( sampler2D sam, in vec3 q )
{
    q *= 0.5;
    return max(max(textureLod(sam,q.xy,1.0).xyz,
                   textureLod(sam,q.yz,1.0).xyz ),
                   textureLod(sam,q.zx,1.0).xyz );
}

vec3 transform( in vec3 p )
{
    float an = 6.283185*(iTime-0.0)/40.0;
    p.xz *= mat2(cos(an),-sin(an),sin(an),cos(an));
    return p.yxz;
}

//===============================================================================================

const float kBound = 2.2;

// The inverse stereographic projection has the following form:
// (see https://en.wikipedia.org/wiki/Stereographic_projection)
//
// q = { 2p, |p|²-1 } / (|p|²+1);
//
// But the following simplification, while distorting a bit too
// much, does the trick too and reduces the degree of the final
// implicit by half.
//
// q = { p, |p|²-1 }
//
// From there nthe rest goes just like in this previous shader:
// https://www.shadertoy.com/view/fdyXWK. I don't think there's
// getting around the complex cube and square to make the curve
// turn 3 times in one direction and 2 in the other.
//
// float x = p.x;
// float y = p.y;
// float z = p.z;
// float w = x*x + y*y + z*z - 1.0;
//    
// float s =  x*x*x - 3.0*x*y*y + z*z - w*w;
// float t = -y*y*y + 3.0*x*x*y + 2.0*z*w;

float map( in vec3 p )
{
    // rotate
    p = transform(p);
   
    float x = p.x;
    float y = p.y;
    float z = p.z;
    
    float s =  
    - 1.0*x*x*x*x 
    - 1.0*y*y*y*y
    - 1.0*z*z*z*z 
    - 2.0*x*x*y*y 
    - 2.0*x*x*z*z 
    - 2.0*y*y*z*z 
    + 1.0*x*x*x 
    - 3.0*x*y*y
    + 2.0*x*x 
    + 2.0*y*y 
    + 3.0*z*z
    - 1.0;
    float t = 
    - 1.0*y*y*y 
    + 3.0*x*x*y 
    + 2.0*z*x*x 
    + 2.0*z*y*y 
    + 2.0*z*z*z 
    - 2.0*z;

    float u = s*s + t*t;
    
// s is degree 4 and t is degree 3, so u is degree 8. The field
// map(p) is f(x,y,z) = u - r = 0, our degree 8 polynomial; for
// example we could do r = 0.1. But to make rendering easier, I
// "linearize" the field by taking its 8th root. Also, I expand
// the radius r to compensate for the inverse projection.
    
    float d = pow(u,1.0/8.0) - 0.75 - 0.12*dot(p,p);
    
    // aesthetics - displace a bit
    if( d<0.02 ) d -= 0.01*(texture_3d(iChannel0,p).x-0.5);
    
    return d;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos, in float eps )
{
#if 0
    vec2 e = vec2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*map( pos + e.xyy ) + 
					  e.yyx*map( pos + e.yyx ) + 
					  e.yxy*map( pos + e.yxy ) + 
					  e.xxx*map( pos + e.xxx ) );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*eps);
       //if( n.x+n.y+n.z>100.0 ) break;
    }
    return normalize(n);
#endif   
}

// https://iquilezles.org/articles/rmshadows
float shadow( in vec3 ro, in vec3 rd, float k )
{
    vec2 bb = iSphere( ro, rd, vec4(0.0,0.0,0.0,kBound) );

    float tmax = bb.y;
    float t = 0.001;
    float sh = 1.0;
    for( int i=0; i<256; i++ )
    {
        vec3 pos = ro + rd*t;
        float d = map(pos);
        sh = min( sh, clamp(k*d/t,0.0,1.0) );
        if( sh<0.001 ) break;
        t += clamp(d,0.01,0.1);
        if( t>tmax ) break;
    }
    return sh*sh;
}

// https://iquilezles.org/articles/nvscene2008/
float calcAO( in vec3 pos, in vec3 nor )
{
	float ao = 0.0;
    const int num = 32;
	for( int i=ZERO; i<num; i++ )
	{
		float h = frand();
        vec3 kv = normalize( vec3(frand(), frand(), frand()) );
        kv *= sign(dot(kv,nor));
		ao += clamp( map(pos+nor*0.001+kv*h*kBound), 0.0, 1.0 );
        if( ao>float(num) ) break;
	}
	ao /= float(num);
	
	return clamp( ao*1.1-0.1, 0.0, 1.0 );
}

// regular SDF raymarching within a bounding sphere
float raycast( in vec3 ro, in vec3 rd )
{
    float res = -1.0;
    
    vec2 bs = iSphere( ro, rd, vec4(0.0,0.0,0.0,kBound) ); // bounding sphere
    if( bs.y>0.0 )
    {
        float t = max(bs.x,0.0);
        for( int i=0; i<512; i++ )
        {
            vec3 pos = ro + rd*t;
            float d = map(pos);
            if( abs(d)<0.0002 ) { res=t; break; }
            t += 0.45*d;
            if( t>bs.y ) break;
        }
    }
    
    return res;
}

const vec3  kLigPos[2] = vec3[2]( 4.0*normalize(vec3(1.0,0.6,0.1)), 4.0*normalize(vec3(-1.0,0.3,-0.5)) );
const vec3  kLigCol[2] = vec3[2]( 1.5*vec3(16.0,12.0,8.0), 0.6*vec3(8.0,12.0,16.0) );
const float kLigSpe[2] = float[2]( 3.0, 1.5 );


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // init random seed
    ivec2 q = ivec2(fragCoord);
    srand( hash(q.x+hash(q.y+hash(iFrame))));

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(fragCoord+o)-iResolution.xy)/iResolution.y;
#else    
        vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
#endif
        // camera movement	
        float an = 0.0*iTime/20.0;
        vec3  ta = vec3( 0.0, 0.20, 0.0 );
        vec3  ro = ta + 5.5*vec3( sin(6.283185*an), 0.1, cos(6.283185*an) );

        // camera matrix
        vec3 ww = normalize( ta - ro );
        vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
        vec3 vv = normalize( cross(uu,ww));

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 3.0*ww );
        
        // dof
        vec3 fp = ro + rd * 4.75;
        float ra = 6.283185*frand();
        ro += sqrt(frand())*(uu*cos(ra)+vv*sin(ra))*0.03;
        rd = normalize( fp - ro );

        // background
        vec3 col = 0.0*vec3(0.0,0.004,0.02)/(1.0+4.0*dot(p,p));
 
        // raycast
        float t = raycast( ro, rd );
        if( t>0.0 )
        {
            // material
            vec3  pos = ro + rd*t;
            vec3  nor = calcNormal( pos, 0.0001 );
            float occ = calcAO( pos+nor*0.001, nor );

            vec3 opos = transform(pos);
            vec3 mate = texture_3d(iChannel0,opos);
            occ *= 0.2 + 0.8*mate.x;            
            float ks = 0.2+0.8*mate.x;
            mate *= 0.35;

            // lighting
            col = vec3(0.0);

            // 2 lamps
            for( int i=ZERO; i<2; i++ )
            {
                vec3 ligPos = kLigPos[i];
                vec3 lig = normalize(ligPos-pos);

                float dif = 1.0;
                dif *= clamp(dot(nor,lig),0.0,1.0);
                dif *= pow( dot( lig, normalize(ligPos) ), 12.0 );
                dif *= 5.0/dot(ligPos-pos,ligPos-pos);
                if( dif>0.001 )
                dif *= shadow(pos+nor*0.001, lig, 4.0);
                col += mate*dif*kLigCol[i];

                vec3 hal = normalize(lig-rd);
                float spe = pow(clamp(dot(nor,hal),0.0,1.0),48.0);
                spe *= 0.04 + 0.96*pow( clamp(1.0-max(dot(hal,rd),0.0), 0.0, 1.0), 5.0 );
                col += spe*dif*ks*kLigSpe[i];
            }

            // bounce
            col += 0.02*vec3(1.2,0.7,0.5)*mate*occ*max(0.0,0.5-0.5*nor.y);
            // top
            col += 0.05*vec3(1.0,1.0,1.0)*mate*occ*pow(0.5+0.5*nor.y,4.0);
            
            col = pow( col, vec3(0.9,0.95,1.0) );
        }

        // glare
        col += 0.0002*kLigCol[0]*pow( max(0.0,dot(normalize(kLigPos[0]-ro),rd)), 48.0 );
        col += 0.0002*kLigCol[1]*pow( max(0.0,dot(normalize(kLigPos[1]-ro),rd)), 48.0 );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif
    // gain
    tot = tot*1.5/(1.0+tot);

    // to gamma space
    tot = pow( tot, vec3(0.4545) );

    // remove color banding through dithering
    tot += (1.0/255.0)*frand();
 
    fragColor = vec4( tot, 1.0 );
}