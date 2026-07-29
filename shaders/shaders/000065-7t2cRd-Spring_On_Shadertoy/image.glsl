// Image (image) — Spring On Shadertoy by sylvain69780
// https://www.shadertoy.com/view/7t2cRd

/*

    Spring on Shadertoy
    -------------------
    
    Icosahedral symmetry.
        
    You can try to change N1 and N2 
    
    2 n - Dihedral symmetry
    3 3 - Tetrahedral symmetry
    3 4 - Octahedral symmetry
    3 5 - Icosahedral symmetry
    
    Taking parity into account, it is possible to reconstitute a coherent 
    rotation around fundamental region vertices
    so it's a sort of floral truncated icosidodecahedron.
    
    PHI = 2*cos(PI/5)
    this makes the rectangle cos(PI/vec2(3,5)) a golden rectangle
    and explains the construction of the Isosahedron's vertexes using perpendicular golden rectangles.

    Related references:
    
    Wythoff explorer - mattz ♥ 
    https://www.shadertoy.com/view/Md3yRB    
    
    Icosahedral symmetry - Wikipedia
    https://en.wikipedia.org/wiki/Icosahedral_symmetry

*/

//#define AA
#define ROTATION
#define T iTime

const int N1 = 3;
const int N2 = 5;

const float PI    = 3.14159265359;
const float TWOPI = 6.28318530717;
const float PHI = (1. + sqrt(5.))/2.;
const float IPHI = 1./PHI; // PHI-1 

// reduction plane - ensure all points are constrained in the fundamental domain
const vec2 golden = cos(PI/vec2(N1,N2)); // with 3,5, gives a golden rectangle 
const vec3 rplane = vec3(-golden,sqrt(1.0-dot(golden,golden))); 
// corners of the spherical triangle fundamental domain 
// https://www.quora.com/How-is-the-golden-ratio-alternatively-equal-to-2-cos-pi-5
const vec3 VERTEXN1 = normalize(cross(rplane,vec3(1,0,0))); 
// const vec3 VERTEXN1 = normalize(vec3(0,IPHI,PHI)); // dodecahedron vertex coordinates
const vec3 VERTEXN2 = normalize(cross(vec3(0,1,0),rplane));  
// const vec3 VERTEXN2 = normalize(vec3(1,0,PHI));  // icosahedron vertex coordinates
const int MAX_STEPS =100;
const float MAX_DIST  =10.;
const float SURF_DIST =.001;

// Folding to the fundamental domain of Icosahedral symetry, 

vec3 foldp( vec3 p, out float parity)
{ 
    float s = p.x*p.y*p.z;
    p = abs(p);
    for(int i=0;i<3;i++)
    {
        float side = dot(p, rplane);
        if (side >= 0.0) break;
        s=-s;
        p -= 2.*side*rplane;
        if (i==2) break;
        s*=p.x*p.y;
        p.xy = abs(p.xy);        
    }
    parity = sign(s);
    return p;
}    


// From IQ
// List of some other 2D distances: https://www.shadertoy.com/playlist/MXdSRf
float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k) {
	return smin(a, b, -k);
}

float cro(in vec2 a, in vec2 b ) { return a.x*b.y - a.y*b.x; }

// uneven capsule
float sdUnevenCapsuleY( in vec2 p, in float ra, in float rb, in float h )
{
	p.x = abs(p.x);
    
    float b = (ra-rb)/h;
    vec2  c = vec2(sqrt(1.0-b*b),b);
    float k = cro(c,p);
    float m = dot(c,p);
    float n = dot(p,p);
    
         if( k < 0.0   ) return sqrt(n)               - ra;
    else if( k > c.x*h ) return sqrt(n+h*h-2.0*h*p.y) - rb;
                         return m                     - ra;
}
    
float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

mat2 Rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

vec2 opPolar(vec2 p,int n) {
    float angle = TWOPI/float(n);
    float at=atan(p.x,p.y); 
    // IQ video about polar symetry https://youtu.be/sl9x19EnKng?t=1745
    float sector = round(at/angle); 
    p = Rot(-angle*sector) * p;
    return p;
}

vec2 opCheapBend( vec2 p, float k)
{
    float c = cos(k*p.x);
    float s = sin(k*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec2  q = vec2(m*p.xy);
    return q;
}

vec4 flower(vec3 q, int n, float mh, float t) {
    // stem
    float cycle = sin(t);
    float h = 0.7+mh*smoothstep(-1.0,-0.35,cycle);
    float d = length(q-vec3(0.,0.,min(q.z,h)));
    vec4 hit = vec4(d,2.0,q.z-h,d);
    hit.x -= .05;
    if (q.z < h) hit.x -= .002*min(1.0,cos((q.z-h)*150.)+.9);
    // petals
    q.z -= h;
    q.xy-=vec2(0.0,.04);
    q.zy *= Rot(1.55-1.1*smoothstep(-0.5,0.2,cycle));
    float close = smoothstep(-0.25,0.0,cycle);
    q.yz = opCheapBend(q.yz,.05*close);
    q.xz = opCheapBend(q.xz,3.*close);
    float fan = sdUnevenCapsuleY(q.xy-vec2(0.0,.015),.015,.08,.30);
    float fan3d = opExtrussion(q,fan,.0)-.01; 

    if ( fan3d < hit.x ) hit = vec4(fan3d,1.0,q.y,q.z); 
    return hit;
}


vec4 opU(vec4 a, vec4 b)
{
    return a.x < b.x ? a : b;
}

mat2 align(vec2 v)
{
    return mat2(v.x,v.y,-v.y,v.x);
}

float dot2(vec2 a)
{
    return a.x*a.x+a.y*a.y;
}

vec4 map4(vec3 p) {
    p.yz *= Rot(.5*cos(TWOPI*fract(iTime*.03)));
    p.xz *= Rot(TWOPI*fract(iTime*.0234));
    float center = length(p);
    float parity;
    vec3 q = foldp(p,parity);
    vec3 p1 = vec3(q.x*parity,q.y,q.z);
    #ifdef ROTATION
        p1.xy *= Rot(T*.5);
        p1.xy = opPolar(p1.xy,2*4);
    #endif
    vec3 p2 = vec3(q.x*parity,align(VERTEXN1.zy)*q.yz); // align z with vertex, not y
    p2.xy = -p2.xy;
    #ifdef ROTATION
        p2.xy *= Rot(T*.5);
        p2.xy = opPolar(p2.xy,N1*3);
    #endif
    vec3 p3 = vec3(q.y*parity,align(VERTEXN2.zx)*q.xz);
    p3.xy = -p3.xy;
    #ifdef ROTATION
        p3.xy *= Rot(T*.5);
        p3.xy = opPolar(p3.xy,N2*2);
    #endif
    // Stand
    float holes = min(min(length(p1.xy),length(p2.xy)),length(p3.xy))-.12;
    float borders = max(min(min(q.x,q.y),dot(q,rplane)),-holes)-.01;
    float stand  = max(min(max(center-.6,-holes),borders),center-1.0);
    stand = min(stand,max(abs(holes)-.01,center-1.1));
    vec4 hit = vec4(stand,4.0,center,0.0);    
    // Flowers
    float r = .36;
    if ( length(p1.xy) - r < hit.x)
        hit = opU(hit,flower(p1,2*5,0.80,T*.25));
    if ( length(p2.xy) - r < hit.x)
        hit = opU(hit,flower(p2,N1*3,0.65,T*.35+2.));
    if ( length(p3.xy) - r < hit.x)
        hit = opU(hit,flower(p3,N2*2,0.65,T*.45+4.));
    return hit;
}

float map(vec3 p) {
    return map4(p).x;
}

float RayMarch(vec3 ro, vec3 rd) {
	float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
    	vec3 p = ro + rd*dO;
        float dS = map(p);
        dO += dS;
        if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
    }
    
    return dO;
}

vec3 GetNormal(vec3 p) {
	float d = map(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        map(p-e.xyy),
        map(p-e.yxy),
        map(p-e.yyx));
    
    return normalize(n);
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = map( opos );
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

// IQ
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<24; i++ )
    {
		float h = map( ro + rd*t );
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 m = (iMouse.xy-.5*iResolution.xy)/iResolution.y;

    vec3 ro = vec3(0.5, 0, -3.6);

    if ( iMouse.x > 0.0 ) {
        ro.yz *= Rot(-.5*m.y*3.14);
        ro.xz *= Rot(-.5*m.x*6.2831);
    }    
    vec3 tcol = vec3(0);
#ifdef AA
	for (float dx = 0.; dx <= 1.; dx++)
		for (float dy = 0.; dy <= 1.; dy++) {
			vec2 uv = (fragCoord + vec2(dx, dy) * .5 - .5 * iResolution.xy) / iResolution.y;
#else
			vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
#endif
    vec3 rd = GetRayDir(uv, ro, vec3(0,0.,0), 1.);
    vec3 bg =  vec3(0.5, 0.8, 0.9) - max(rd.y,0.0)*0.5; // IQ https://youtu.be/Cfe5UQ-1L9Q?t=13898
    vec2 suv = 20.0*rd.xy;
    float cl = 1.0*(sin(suv.x*1.0+iTime)+sin(suv.y*1.0))+
               0.5*(sin(suv.x*2.0+iTime)+sin(suv.y*2.0));
    vec3 sky_color = vec3(.9,.9,1.0);
    bg = mix(bg,sky_color,0.5*smoothstep(-0.4,0.4,-0.6+cl));
    
    vec3 col = bg;
    float d = RayMarch(ro, rd);

    if(d<MAX_DIST) {
        vec3 p = ro + rd * d;
        vec3 n = GetNormal(p);
        vec3 r = reflect(rd, n);
        vec4 hit = map4(p);
        vec3 objCol = vec3(0);
        if ( hit.y < 1.5 ) {
            // petals
            objCol = mix(vec3(1.000,0.784,0.000),vec3(1.000,0.078,0.525),smoothstep(.05,.2,hit.z));
            objCol = mix(objCol,vec3(1),smoothstep(.005,-.02,hit.w));
        } else if ( hit.y <= 2.5 ) {
            // stem
            objCol = mix(vec3(0.000,1.000,0.251),vec3(0.349,1.000,0.000),smoothstep(-0.25,0.0,hit.z));
        } else if ( hit.y <= 4.5 ) {
            // base
            objCol = mix(.5+.5*vec3(0.933,1.000,0.000),vec3(1),smoothstep(0.93,0.95,hit.z));
            objCol += 0.2 - 0.2 * min(0.,cos(hit.z * 100.));
        }
        vec3 sun_lig = normalize(vec3(1,1,-3));
        float dif = max(0.0,dot(n, sun_lig));
        float spe = pow(clamp(dot(n,normalize( sun_lig-rd )),0.0,1.0),8.0) * dif; // Blinn 
        float occ = 0.5+0.5*calcOcclusion(p,n);
        float sha = .5+.5*calcSoftshadow( p+0.01*n, sun_lig, 0.01, 1.4 );
        float fre = clamp(1.0+dot(rd,n),0.0,1.0); // Fresnel https://youtu.be/beNDx5Cvt7M?t=1510
        // IQ https://www.shadertoy.com/view/3lsSzf
        float bou_dif = sqrt(clamp( 0.1-0.9*n.y, 0.0, 1.0 ))*clamp(1.0-0.1*p.y,0.0,1.0);
        vec3 sun_col = vec3(1.64,1.27,0.99);
        vec3 lin = vec3(0);
        lin += dif * sun_col * .9 * occ * sha;
        lin += bou_dif*vec3(0.239,0.545,0.176) * occ;
        lin += fre * sky_color * occ * sha;
        col = objCol * lin * occ *.6;
        col += spe * occ * .4 * sun_col * sha;
    } 
    col = mix(col,bg,smoothstep(3.0,5.0,d)); // fog
    col = mix(col, smoothstep(0.0,1.0,col),.4); // pop filter - YX - Is This Your Card?  - https://www.shadertoy.com/view/sl2yWK
    tcol+=col;
#ifdef AA
		}
	tcol /= 4.;
#endif
    tcol = pow(tcol, vec3(.4545));	// gamma    
    fragColor = vec4(tcol,1.0);
}
