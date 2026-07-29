// Common (common) — Tiny Hideout by _pwd_
// https://www.shadertoy.com/view/DlKBDh

//////////////////////////////////////////////////////////////////////////////////////
// defines & constants
//////////////////////////////////////////////////////////////////////////////////////

#define ANIMATE_WATER 1

//Bloom
#define BLOOM_SIZE (0.5)
#define BLOOM_THRESHOLD (1.01)
#define BLOOM_RANGE (0.3)
#define BLOOM_FRAME_BLEND (0.2)

//utility defines
#define ZERO   (min(1,0))
#define X_AXIS vec3(1,0,0)
#define Y_AXIS vec3(0,1,0)
#define Z_AXIS vec3(0,0,1)

#define PI 3.14159265
#define TAU (2*PI)
#define PHI (sqrt(5)*0.5 + 0.5)

// Materials
#define MAT_WOOD  101
#define MAT_LEAFS 102
#define MAT_UNDERWATER 301
#define MAT_PLANT 701
#define MAT_STONE 801

#define MAT_GROUNDPLATE 203
#define MAT_GROUNDPLATE_TOP 204
#define MAT_BASEPLATE 205
#define MAT_WALLS 206
#define MAT_ROOF 207
#define MAT_ENTRANCE 208
#define MAT_WINDOW 209
#define MAT_DUST 210



//////////////////////////////////////////////////////////////////////////////////////
// utility functions
//////////////////////////////////////////////////////////////////////////////////////

mat3 rotation(vec3 axis, float angle)
{
    //axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return inverse(mat3(oc * axis.x * axis.x + c, 
                        oc * axis.x * axis.y - axis.z * s,  
                        oc * axis.z * axis.x + axis.y * s, 
                        oc * axis.x * axis.y + axis.z * s,  
                        oc * axis.y * axis.y + c,           
                        oc * axis.y * axis.z - axis.x * s,  
                        oc * axis.z * axis.x - axis.y * s,  
                        oc * axis.y * axis.z + axis.x * s,  
                        oc * axis.z * axis.z + c));
}

vec3 rotateX(vec3 pos, float alpha) {
    mat4 trans= mat4(1.0, 0.0, 0.0, 0.0, 0.0, cos(alpha), -sin(alpha), 0.0, 0.0, sin(alpha), cos(alpha), 0.0, 0.0, 0.0, 0.0, 1.0);
    return vec3(trans * vec4(pos, 1.0));
}


vec3 rotateY(vec3 pos, float alpha) {
    mat4 trans2= mat4(cos(alpha), 0.0, sin(alpha), 0.0, 0.0, 1.0, 0.0, 0.0,-sin(alpha), 0.0, cos(alpha), 0.0, 0.0, 0.0, 0.0, 1.0);
    return vec3(trans2 * vec4(pos, 1.0));
}



//////////////////////////////////////////////////////////////////////////////////////
// sdf blend & domain repetition (
//////////////////////////////////////////////////////////////////////////////////////

//HG
float fOpUnionRound(float a, float b, float r) 
{
	vec2 u = max(vec2(r - a,r - b), vec2(0));
	return max(r, min (a, b)) - length(u);
}

float pModPolar(inout vec2 p, float repetitions) 
{
	float angle = 2.*PI/repetitions;
	float a = atan(p.y, p.x) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = mod(a,angle) - angle/2.;
	p = vec2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2.)) c = abs(c);
	return c;
}

// Repeat in two dimensions
vec2 pMod2(inout vec2 p, vec2 size) {
	vec2 c = floor((p + size*0.5)/size);
	p = mod(p + size*0.5,size) - size*0.5;
	return c;
}

// Same, but mirror every second cell so all boundaries match
vec2 pModMirror2(inout vec2 p, vec2 size) {
	vec2 halfsize = size*0.5;
	vec2 c = floor((p + halfsize)/size);
	p = mod(p + halfsize, size) - halfsize;
	p *= mod(c,vec2(2))*2.0 - vec2(1.0);
	return c;
}

float fOpIntersectionRound(float a, float b, float r)
{
	vec2 u = max(vec2(r + a,r + b), vec2(0));
	return min(-r, max (a, b)) + length(u);
}

float fOpDifferenceRound (float a, float b, float r)
{
	return fOpIntersectionRound(a, -b, r);
}

//IQ
float opSmoothUnion( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

//IQ
float opSubtraction( float d1, float d2 )
{
    return max(-d1,d2);
}

// min/max polynomial
float smin( float a, float b, float k )
{
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}
float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}

float smoothDiff(float d2, float d1, float k) {
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0 );
    return mix(d2, -d1, h ) + k * h * (1.0 - h);
}



//////////////////////////////////////////////////////////////////////////////////////
// basic sdf shapes
//////////////////////////////////////////////////////////////////////////////////////

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdRoundBaseBox( vec3 p, vec3 b, float r )
{
    float b1 = sdRoundBox(p,b,r);
    float b2 = sdRoundBox(p + vec3(-0.08,0.0,0.3),vec3(0.07, 0.005, 0.05),r);
    
    return min(b1,b2);
}

float sdCone(vec3 p, vec3 a, vec3 b, float ra, float rb)
{
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;
    float x = sqrt( papa - paba*paba*baba );
    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;
    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );
    float cbx = x-ra - f*rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(cax*cax + cay*cay*baba,
                       cbx*cbx + cby*cby*baba) );
}

float sdEllipsoid( in vec3 p, in vec3 r ) // approximated
{
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float dot2( in vec2 v ) { return dot(v,v); }
float dot2( in vec3 v ) { return dot(v,v); }
float ndot( in vec2 a, in vec2 b ) { return a.x*b.x - a.y*b.y; }
float udTriangle( vec3 p, vec3 a, vec3 b, vec3 c )
{
  vec3 ba = b - a; vec3 pa = p - a;
  vec3 cb = c - b; vec3 pb = p - b;
  vec3 ac = a - c; vec3 pc = p - c;
  vec3 nor = cross( ba, ac );

  return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(ac,nor),pc))<2.0)
     ?
     min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(ac*clamp(dot(ac,pc)/dot2(ac),0.0,1.0)-pc) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}



//////////////////////////////////////////////////////////////////////////////////////
// sdf shape combinations
//////////////////////////////////////////////////////////////////////////////////////

float gTime = 0.0;

// Draws chimney´s edges
float chimneyEdges(vec3 p) 
{
    
    float b = sdRoundBox(p + vec3(0.25, -0.44, -0.1), vec3(0.049, 0.005, 0.049), 0.008);
    float c = sdRoundBox( p + vec3(0.25, -0.46, -0.1), vec3(0.011, 0.017, 0.011), 0.011);
    float d = smoothDiff(b, c, .02);

    return d;
}

// Draws rooftop
float roofTop(vec3 p, vec3 r)
{
	vec3 b = r;
	p.x = abs(p.x);
  	p.y += p.x*.4;
	return length(max(abs(p)-b,0.0))-.03;
}

// Draws house´s walls and fit walls with rooftop 
float wallsAndRoof(vec3 p, vec3 dim, float r)
{
    float v = 0.0;
    float c = 0.0;

    c = roofTop(p + vec3(0.0, -0.23, 0.0), vec3(0.366, .03, 0.366));
    v = sdRoundBox(p, dim, r);

    return max(v,-c);
}

float treeTrunk(vec3 pos)
{
    float r = 1e10;

    r = sdCone(pos, vec3(0.73,0.0,0.35), vec3(0.73,0.23,0.35), 0.02, 0.02 );
    r += sin(30.*pos.x)*sin(50.*pos.y)*sin(30.*pos.z) * 0.01;

    r = min(r, sdCone(pos, vec3(-0.25,0.0,0.61), vec3(-0.25,0.18,0.61), 0.017, 0.018 ));
    r += sin(30.*pos.x)*sin(30.*pos.y)*sin(30.*pos.z) * 0.01;  
    
    return r;
}


vec3 cellpos;
vec3 signvec;
vec3 subpos;
float fsign;

float cf(vec3 pos) {
	
	cellpos=pos-floor(pos);
	
	signvec=2.0*step(0.5,cellpos)-1.0;
	fsign=signvec.x*signvec.y*signvec.z;
	
	subpos=abs(abs(cellpos-0.5)-0.25);
	
	return fsign*(max(max(subpos.x,subpos.y),subpos.z)-0.25);
	
}


float treeLeafs(vec3 pos)
{
    float r = 1e10;

    vec3 leafsDomainL = pos - vec3(0.53, 0.42, 0.);
    vec3 leafsDomainR = pos - vec3(-0.53, 0.42, 0.);

    r = min(r, sdRoundBox(leafsDomainL - vec3(0.20, -0.19, 0.35), vec3(0.07, 0.08, 0.07), 0.029));
    r = min(r, sdRoundBox(leafsDomainL - vec3(0.28, -0.10, 0.35), vec3(0.02, 0.025, 0.02), 0.029));
    r = min(r, sdRoundBox(leafsDomainL - vec3(0.23, -0.08, 0.40), vec3(0.024, 0.024, 0.024), 0.029));
    r = min(r, sdRoundBox(leafsDomainL - vec3(0.13, -0.16, 0.29), vec3(0.02, 0.02, 0.02), 0.029));
    
    r = min(r, sdRoundBox(leafsDomainR - vec3(0.29, -0.24, 0.61), vec3(0.048, 0.058, 0.048), 0.029));
    r = min(r, sdRoundBox(leafsDomainR - vec3(0.24, -0.23, 0.65), vec3(0.02, 0.02, 0.02), 0.029));
        
    return r + 0.02;
}



float g1=0.,g2=0.,g3=0.;

void rot(inout vec3 p,vec3 a,float t){
	a=normalize(a);
	vec3 u=cross(a,p),v=cross(a,u);
	p=u*sin(t)+v*cos(t)+a*dot(a,p);   
}

void rot(inout vec2 p,float t){
    p=p*cos(t)+vec2(-p.y,p.x)*sin(t);
}

// rewrote 20/12/01
void sFold45(inout vec2 p)
{
	vec2 v=normalize(vec2(1,-1));
	float g=dot(p,v);
	p-=(g-sqrt(g*g+5e-5))*v;
}

float stella(vec3 p, float s)
{
    p=sqrt(p*p+0.00005); // https://iquilezles.org/articles/functions
    sFold45(p.xz);
	sFold45(p.yz);
    return dot(p,normalize(vec3(1,1,-1)))-s;
}


#define seed 2576.
#define hash(p)fract(sin(p*12345.5))
float stellas(vec3 p)
{
    p.y-= gTime;
    float c=5.;
    vec3 e=floor(p/c);
    e = sin(11.0*(2.5*e+3.0*e.yzx+1.345)); 
    p-=e*.5;
    p=mod(p,c)-c*.5;
    rot(p,hash(e+66.887)-.5,gTime*1.5);
    return min(.7,stella(p,.06));
}

float rand(vec2 co)
{
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float rand(float n)
{
    return fract(sin(n * 12.9898) * 43758.5453);
}

vec2 rand2(vec2 p)
{
	float r = 523.0*sin(dot(p, vec2(53.3158, 43.6143)));
	return vec2(fract(15.32354 * r), fract(17.25865 * r));
}


//////////////////////////////////////////////////////////////////////////////////////
// main sdf
//////////////////////////////////////////////////////////////////////////////////////

vec2 map(in vec3 pos)
{
    vec2 res = vec2( 1.0, 0.0 );
    #define opMin(_v, _m)    res = (_v < res.x) ? vec2(_v, _m) : res
    
    float bottomGround = sdRoundBox(pos + vec3(0.0, 0.13, 0.0), vec3(0.6, 0.05, 0.6), 0.05);
    float topGround = sdRoundBox(pos + vec3(0.0, 0.0, 0.0), vec3(0.6, 0.005, 0.6), 0.05);
    float basePlate = sdRoundBaseBox(pos + vec3(0.1, -0.034, -0.15), vec3(0.28, 0.005, 0.28), 0.03);
    float walls = wallsAndRoof(pos + vec3(0.1, -0.20, -0.15), vec3(0.25, 0.15, 0.25), 0.025);
    float roof = roofTop(pos + vec3(0.1, -0.40, -0.15), vec3(0.286, .005, 0.266));
    float entrance = sdRoundBox(pos + vec3(0.02, -0.15, 0.125), vec3(0.044, 0.08, 0.0035), 0.015);
    float window = sdRoundBox(pos + vec3(0.20, -0.20, 0.1145), vec3(0.033, 0.033, 0.0035), 0.015);
    float chimney = sdRoundBox(pos + vec3(0.25, -0.39, -0.1), vec3(0.03, 0.035, 0.03), 0.015);
    float chimneyEdge = chimneyEdges(pos);

    float waterCavity = sdEllipsoid(pos - vec3(-0.425, 0.01, -0.49), vec3(0.1, 0.2, 0.2));
          waterCavity -= sin(20.*pos.x)*sin(30.*pos.y)*sin(20.*pos.z) * 0.012;
          
    bottomGround = fOpDifferenceRound(bottomGround, waterCavity, 0.07);
    topGround = fOpDifferenceRound(topGround, waterCavity, 0.07);

    opMin(bottomGround, MAT_GROUNDPLATE);
    opMin(topGround, MAT_GROUNDPLATE_TOP);
    opMin(basePlate, MAT_BASEPLATE);
    opMin(walls, MAT_WALLS);
    opMin(roof, MAT_ROOF);
    opMin(entrance, MAT_ENTRANCE);
    opMin(window, MAT_WINDOW);
    opMin(chimney, MAT_WALLS);
    opMin(chimneyEdge, MAT_ROOF);
    
    float rock = sdEllipsoid(pos - vec3(-0.05, 0.051, -0.32), vec3(0.08, 0.028, 0.06));
    rock = min(rock, sdEllipsoid(pos - vec3(0.06, 0.048, -0.39), vec3(0.04, 0.021, 0.04)));
    rock = min(rock, sdEllipsoid(pos - vec3(-0.04, 0.049, -0.45), vec3(0.06, 0.023, 0.055)));
    rock = min(rock, sdEllipsoid(pos - vec3(-0.14, 0.049, -0.41), vec3(0.04, 0.023, 0.065)));
    rock = min(rock, sdEllipsoid(pos - vec3( 0.028, 0.050, -0.54), vec3(0.043, 0.025, 0.059)));
    rock = min(rock, sdEllipsoid(pos - vec3(-0.074, 0.049, -0.585), vec3(0.065, 0.030, 0.045)));
    rock += sin(15.*pos.x)*sin(10.*pos.y + 15.5)*sin(28.*pos.z) * 0.02;
    opMin(rock, MAT_STONE);
    
    vec3 treePos = pos - vec3( -0.3, 0.028, -0.3);
    float treeTrunkDist = treeTrunk( treePos );
    opMin(treeTrunkDist, MAT_WOOD);
    float leafsDist = treeLeafs( treePos );
    opMin(leafsDist, MAT_LEAFS);

    float underWater = max(res.x , waterCavity - 0.03 );
    res = (underWater < (res.x + 0.0001)) ? vec2(underWater, MAT_UNDERWATER) : res;
    
    float stellas = stellas(pos);
    opMin(stellas, MAT_WINDOW);
    
    float d, d1;
    d = 10000.0;
    vec3 tempPos = pos + vec3(0.18, -0.39, -0.15);
    
    for(int i = 0; i < 20; i++)
	{
        vec3 pos1;
        float ltime = gTime*0.09 + float(i)*20.134;

        float r = rand(float(i)*2.33);
        float y = 0.08+mod(ltime*(r + 0.5), 1.0);

        float r1 = rand(float(i)*12.33);
        r1 *= 0.01;


        pos1 = vec3(0.010*mod(float(i), 4.0) - 0.08, y, 0.010*floor(float(i)/5.0) - 0.08);
        d1 = sdRoundBox(tempPos - pos1, vec3(0.005 + r1, 0.005 + r1, 0.005 + r1), 0.005);
        if (d1 < d)
        {
            d = d1;

        }       
    }
         
    opMin(d, MAT_DUST);
    return res;
}


float mapWaterVolume(vec3 pos)
{   
    vec3 rPosX = rotateX(pos, -1.5707);

    float baseBox = sdBox( pos - vec3( -0.42, -0.09, -0.155), vec3(0.1,0.10,0.498) );
    float wv = baseBox;
    //animate water
#if defined(ANIMATE_WATER) && ANIMATE_WATER
    vec3 offset = vec3(-gTime * 0.04 - 0.02, 0.0, gTime * 0.06 + 0.1);
#else
    vec3  offset = vec3(0.1);
#endif
    wv += (1.0 - clamp((pos.y / -0.15), 0.0, 1.0)) // affect mostly on top of the water surface
        *( 1.0
         * sin(-22.*(pos.x+offset.x))
         * sin(23.*(pos.z + offset.z))
         + sin(20.*(pos.z + offset.z + 12.5)) * 0.3
         + cos(15.*(pos.z + 2.1 +offset.x)) * 0.2
         + cos(-21.*(pos.x+offset.z)) *0.5
         )* 0.011;
    wv -= 0.004;
    wv = max(wv, sdBox( pos - vec3( -0.42, -0.09, -0.155), vec3(0.1,0.13,0.498) ));
    wv -= 0.004;
    
    float baseBox2 = sdBox( rPosX - vec3( -0.415, 0.63, -0.45), vec3(0.09,0.02,0.42) );
    float wv2 = baseBox2;
    //animate water
#if defined(ANIMATE_WATER) && ANIMATE_WATER
    vec3 offset2 = vec3(-gTime * 0.04 - 0.02, 0.0, gTime * 0.06 + 0.1);
#else
    vec3  offset2 = vec3(0.1);
#endif
    wv2 += (1.0 - clamp((rPosX.y / -0.15), 0.0, 1.0)) // affect mostly on top of the water surface
        *( 1.0
         * sin(-22.*(rPosX.x+offset2.x))
         * sin(23.*(rPosX.z + offset2.z))
         + sin(20.*(rPosX.z + offset2.z + 12.5)) * 0.3
         + cos(15.*(rPosX.z + 12.1 +offset2.x)) * 0.2
         + cos(-21.*(rPosX.x+offset2.z)) *0.5
         )* 0.011;
    wv2 -= 0.004;
    wv2 = max(wv2, sdBox( rPosX - vec3( -0.415, 0.63, -0.45), vec3(0.09,0.02,0.42) ));
    wv2 -= 0.004;
    
    return min(wv,wv2);
}



//////////////////////////////////////////////////////////////////////////////////////
// raymarching softshadows (https://iquilezles.org/articles/rmshadows)
//////////////////////////////////////////////////////////////////////////////////////

float calcSoftshadow( in vec3 ro, in vec3 rd, in float tmin, in float tmax )
{
    // bounding volume
    //float tp = (maxHei-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = tmin;
    for( int i=ZERO; i<22; i++ )
    {
		float h = map( ro + rd*t ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}



//////////////////////////////////////////////////////////////////////////////////////
// https://iquilezles.org/articles/normalsSDF
//////////////////////////////////////////////////////////////////////////////////////

vec3 calcNormal( in vec3 pos )
{
#if 0
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
					  e.yyx*map( pos + e.yyx ).x + 
					  e.yxy*map( pos + e.yxy ).x + 
					  e.xxx*map( pos + e.xxx ).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).x;
    }
    return normalize(n);
#endif    
}

vec3 calcNormalWater( in vec3 pos )
{
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*mapWaterVolume(pos+0.0005*e);
    }
    return normalize(n); 
}

float calcAO( in vec3 pos, in vec3 nor )
{
	float occ = 0.0;
    float sca = 1.00;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 calcSkyColor(vec3 aDirection)
{
    float t = smoothstep(0.1, 0.6, 0.7f*(aDirection.y + 1.0f));
    return mix(vec3(1.0f, 1.0f, 0.2f), vec3(0.1f, 0.1f, 1.0f), t);
}

vec4 calcColor(int matId, vec3 pos, vec3 normal, float diffuse, float fresnel)
{
    vec4 FinalColor = vec4(0.1, 0.1, 0.1, 1) * diffuse;
    if(matId == MAT_WOOD)
    {
        vec3 WoodBrown = vec3(0.287, 0.11882, 0.04) * 1.5;
        vec3 WoodBrownShadow = vec3(0.1847, 0.0482, 0.016) * 1.2;
        FinalColor.rgb = mix(WoodBrownShadow, WoodBrown, diffuse);
        FinalColor.rgb += WoodBrown * fresnel * 2.0;
    }
    else if(matId == MAT_LEAFS)
    {
        vec3 Leafs = vec3(0.0882, 0.447, 0.04);
        vec3 LeafsShadow = vec3(0.00582, 0.247, 0.02);
        FinalColor.rgb = mix(LeafsShadow, Leafs, diffuse) * 0.7;
        FinalColor.rgb += Leafs * fresnel * 2.5;
    }
    else if(matId == MAT_STONE)
    {
        vec3 Stone = vec3(0.4, 0.4, 0.4);
        vec3 StoneShadow = vec3(0.2, 0.2, 0.3);
        FinalColor.rgb = mix(StoneShadow, Stone, diffuse);
        FinalColor.rgb += Stone * fresnel * 0.5;
    }
    else if(matId == MAT_GROUNDPLATE)
    {
        vec3 g = vec3(0.929,0.733,0.063);
        vec3 g1 = vec3(0.90, 0.733,0.063);
        FinalColor.rgb = mix(g1, g, diffuse);
        FinalColor.rgb += vec3(0.929,0.411,0.033) * fresnel * 0.8;
    }
    else if(matId == MAT_GROUNDPLATE_TOP)
    {
        FinalColor.rgb = mix( vec3(0.9, 0.8, 0.04), vec3(1.0, 0.9, 0.04), diffuse);
        FinalColor.rgb += vec3(0.95,0.85,0.033) * fresnel * 1.1;
    }  
    else if(matId == MAT_BASEPLATE)
    {
        FinalColor.rgb = mix( vec3(0.418,0.598,0.608), vec3(0.758,0.708,0.608), diffuse);
        FinalColor.rgb +=  vec3(0.418,0.598,0.608) * fresnel * 0.9;
    }  
    else if(matId == MAT_WALLS)
    {
        FinalColor.rgb = mix( vec3(0.818,0.098,0.628), vec3(0.858,0.908,0.758), diffuse);
        FinalColor.rgb +=  vec3(0.818,0.898,0.808) * fresnel * 0.9;
    }  
    else if(matId == MAT_ROOF)
    {
        FinalColor.rgb = mix( vec3(2.996,0.0,0.296), vec3(3.996,0.0,0.286), diffuse * 0.5);
        FinalColor.rgb +=  vec3(2.996,0.0,0.296) * fresnel * 0.5;
    }  
    else if(matId == MAT_ENTRANCE)
    {
        FinalColor.rgb = mix( vec3(0.459,0.263,0.157), vec3(0.459,0.463,0.057),  diffuse * 0.3);
        FinalColor.rgb +=  vec3(0.459,0.263,0.157) * fresnel * 2.5;
    }  
    else if(matId == MAT_WINDOW)
    {
        FinalColor.rgb = mix( vec3(0.818,0.198,0.108), vec3(0.758,0.708,0.608), diffuse);
        FinalColor.rgb +=  vec3(0.459,0.263,0.157) * fresnel * 2.5;
    }    
    else if(matId == MAT_DUST)
    {
        FinalColor.rgb = mix( vec3(0.980, 0.980, 0.980), vec3(1.980,1.980,1.980), diffuse);
        FinalColor.rgb +=  vec3(1.880,1.880,1.880) * fresnel * 0.5;
    }    
    else if(matId == MAT_UNDERWATER)
    {
        vec3 Sand = vec3(0.447, 0.447, 0.04);
        vec3 SandShadow = vec3(0.347, 0.247, 0.02);
        FinalColor.rgb = mix(SandShadow, Sand, diffuse);
    }
    
    return FinalColor;
}

vec3 castRay(vec3 ro, vec3 rd)
{
    vec3 res = vec3(0.0, 1e10, 0.0);
    float tmin = 1.0;
    float tmax = 20.0;
    float t = tmin;
    for( int i=0; i<120 && t<tmax; i++ )
    {
        vec2 h = map( ro+rd*t );
        if( abs(h.x)<(0.0001*t) )
        { 
            res = vec3(t, h.x, h.y); 
            return res;
        }
        t += h.x;
    }
    
    return res;
}

vec4 applyWaterVolume(vec3 ro, vec3 rd, float depth, vec4 color)
{
    float tmin = 1.0;
    float tmax = 20.0;
    float t = tmin;
    float hit = 0.0;
    float h = 0.0;
    float distInsideWater = 0.0;
    for( int i=0; i<70 && t<tmax; i++ )
    {
        h = mapWaterVolume( ro+rd*t );
        if( abs(h)<(0.0001*t) )
        { 
            distInsideWater += h;
            hit = 1.0;
            break;
        }
        else if(hit > 0.0)
        {
            break;
        }
        t += h;
        if(depth > 0.0 && ((t + 0.0011) > depth))
        {
            break;
        }
    }
    
    depth = (depth > 0.0) ? depth : t*2.5;
    
    vec4 WaterBlue = vec4(0.1, 0.4, 1.0, color.a);
    
    vec3 pos = ro + rd * t;
    vec3 lightDir = normalize( vec3(-0.5, 1.1, 0.9) );
    float shadow = calcSoftshadow( pos, lightDir, 0.02, 2.5 );
    vec3 normal = calcNormalWater(pos);
    float NdL = clamp( dot( normal, lightDir ), 0.0, 1.0 );
    vec3  hal = normalize( lightDir-rd );
    float spe = pow( clamp( dot( normal, hal ), 0.0, 1.0),40.0)
                    //*mix(0.5, 1.0, NdL* shadow)  //shadow
                    //*(0.04 + 2.5*pow( clamp(1.0+dot(hal, rd),0.0,1.0), 1.0 ));
                    ;
    spe = smoothstep(0.5, 0.9, spe);
    //light affecting water
    WaterBlue = mix(WaterBlue * 0.5, WaterBlue, NdL * shadow);
    
    //all inside water is bluiedish
    color = mix(color, WaterBlue * 0.8 + color * WaterBlue * 0.5, hit * 0.3);
    
    //distance to closest point
    float nearest = clamp(map(pos).x, 0.0, 1.0);
    color = mix(color, WaterBlue, clamp(pow(nearest * hit, 1.3) * 5.0, 0.0, 1.0));
    
    //distance to center of the diorama hack
    color = mix(color, WaterBlue , clamp(pow(length(pos) * hit, 2.0) * 1.2, 0.0, 1.0));
    //color = mix(color, WaterBlue * 0.5, ((t / depth)) * hit * 0.7);
    //return vec4(mix(color.rgb, normal * 0.5 + 0.5, hit), 1.0);

#define WATER_OPACITY_INIT 0.3
#define WATER_OPACITY_COEFF 2.5

    float fresnel = pow( clamp(1.0+dot(normal,rd),0.0,1.0), 2.4 );
    color.rgb += hit*2.00*spe*vec3(1.);
    color += mix(vec4(0.0), fresnel*color*3.0, hit * mix(0.2, 1.0, shadow));
    return color;
}

vec4 render( vec2 uv, in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy )
{ 
    vec4 finalColor = vec4(calcSkyColor(rd), 0.0);
    vec3 res = castRay(ro,rd);
    
    if(res.y < 0.002)
    {
        vec3 lightDir = normalize( vec3(-0.5, 1.1, -0.6) );
        vec3 pos = ro + rd * res.x;
        vec3 normal = calcNormal(pos);
        
        float ao = calcAO(pos, normal);
        float shadow = calcSoftshadow( pos, lightDir, 0.02, 2.5 );
        float NdL = clamp( dot( normal, lightDir ), 0.0, 1.0 );
        float fresnel = pow( clamp(1.0+dot(normal,rd),0.0,1.0), 2.4 );
        
        float diffuse  = shadow * NdL * 12.0;

        vec4 color = calcColor(int(res.z), pos, normal, diffuse, fresnel) * mix(0.22, 1.0, ao);
        finalColor = vec4(color.rgb, res.x);
        finalColor.rgb = finalColor.rgb * 0.4 + 0.6 * finalColor.rgb * calcSkyColor(normal);
    }
    
    finalColor = applyWaterVolume(ro, rd, res.x, finalColor);
    return finalColor;
}
