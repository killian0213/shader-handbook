// Common (common) — Fractal dimension explorer by michael0884
// https://www.shadertoy.com/view/tld3zn

#define PI 3.14159265
#define SQRT2 1.4142135
#define SQRT3 1.7320508
#define FOV 3.

#define MAX_STEPS 75.
#define MAX_DIST 1024.
#define LOD max(0.003,2./iResolution.x)
#define CAMERA_SPEED 5./60.
#define MOUSE_SENSITIVITY 0.15/60.

#define SPP 1.
#define AVG 0.99
#define MAX_BOUNCE 3.
#define AUTOEXPOSURE
#define reflection 0.55
#define BLOOM 0.01

#define N 6.

#define MOUSE_INDX 0
#define ANGLE_INDX 1
#define POS_INDX   2
#define VEL_INDX   3
#define LIGHT_INDX 4
#define SPEED_INDX 5
#define FRACTAL_ITER 12.

#define overrelax 1.2
/*
 //Building bridges
const float iFracScale = 1.8093;
const float iFracAng1 = -3.165;
const float iFracAng2 = -3.209477;
const vec3 iFracShift = vec3(-1.0939, -0.43495, -3.1113);
const vec3 iFracCol = vec3(5.00, 5.99, 0.1);
*/

//Mega citadel
const float iFracScale = 1.4731;
const float iFracAng1 = 0.0;
const float iFracAng2 = 0.0;
const vec3 iFracShift = vec3(-10.4, 3.28, -1.90);
const vec3 iFracCol = vec3(1.f, 1.f, 1.f);




float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}


vec3 hash33(vec3 p)
{
    return fract(13406.456*sin(p.xyz)*sin(p.zxy));
}

float noise(float t, float seed) {
    float i = floor(t), f = fract(t);
    float u = 0.5 - cos(3.14159*f)*0.5;
    return mix(hash11(i + seed),  hash11(i + 1. + seed), u);
}

float perlin(float t, float seed)
{
    float r = 0.f;
    float f = 1.f;
    float a = 1.f;
    for(float i = 0.; i < 5.; i++)
    {
        r += noise(f*t, f+seed)*a;
        f *= 1.4;
        a *= 0.6;
    }
    return r;
}

vec3 lim_mod(vec3 p, vec3 s)
{
    vec3 lim =  mod(p,s) - s*0.5;
    if(p.z > 1.)
    {
        lim.z = p.z - 1.;
    }
    return lim;
}


mat3 getCamera(vec2 angles)
{
   mat3 theta_rot = mat3(1,   0,              0,
                          0,   cos(angles.y),  sin(angles.y),
                          0,  -sin(angles.y),  cos(angles.y)); 
        
   mat3 phi_rot = mat3(cos(angles.x),   sin(angles.x), 0.,
        		       -sin(angles.x),   cos(angles.x), 0.,
        		        0.,              0.,            1.); 
        
   return theta_rot*phi_rot;
}

vec3 getRay(vec2 angles, vec2 pos)
{
    mat3 camera = getCamera(angles);
    return normalize(transpose(camera)*vec3(FOV*pos.x, 1., FOV*pos.y));
}

float hash(float p)
{  
    return hash11(p);
}

vec2 hash22(vec2 p)
{
    vec2 res;
    res.x = hash(dot(p, vec2(1.,sqrt(2.))));
    res.y = hash(res.x);
    return res;
}

vec2 hash21(float p)
{
    vec2 res;
    res.x = hash(p);
    res.y = hash(res.x);
    return res;
}


vec3 hash31(float x)
{
    vec3 res;
    res.x = hash(x);
    res.y = hash(x+1.);
    res.z = hash(x+2.);
    return res;
}

//normally distributed random numbers
vec3 randn(float p)
{
    vec3 rand = hash31(p);
    vec3 box_muller = sqrt(-2.*min(log(max(rand.x,1e-6)), 0.))*vec3(sin(2.*PI*rand.y),cos(2.*PI*rand.y),sin(2.*PI*rand.z));
    return box_muller;
}

//uniformly inside a sphere
vec3 random_sphere(float p)
{
    return normalize(randn(p))*pow(abs(hash(p+1.)), 0.3333);
}

vec3 perlin31 (float p)
{
   float pi = floor(p);
   float pf = p - pi;
   return hash31(pi)*(1.-pf) +
          hash31(pi + 1.)*pf; 
}

vec3 perlin31(float p, float n)
{
    float frq = 1., amp = 1., norm = 0.;
    vec3 res = vec3(0.);
    for(float i = 0.; i < n; i++)
    {
        res += amp*perlin31(frq*p);
        norm += amp;
        frq *= 2.;
       // amp *= 1;
    }
    return res/norm;
}


vec2 perlin(vec2 p)
{
   vec2 pi = floor(p);
   vec2 pf = p - pi;
   vec2 a = vec2(0.,1.);
   return hash22(pi+a.xx)*(1.-pf.x)*(1.-pf.y) +
          hash22(pi+a.xy)*(1.-pf.x)*pf.y +
          hash22(pi+a.yx)*pf.x*(1.-pf.y) +
          hash22(pi+a.yy)*pf.x*pf.y;   
}

float singrid(vec2 p, float angle)
{
    return 0.5*(sin(cos(angle)*p.x + sin(angle)*p.y)*sin(-sin(angle)*p.x + cos(angle)*p.y) + 1.);
}

//technically this is not a blue noise, but a single freqency noise, the spectrum should look like a gaussian peak around a frequency
float blue(vec2 p, float seed)
{ 
    seed = 100.*hash(seed);
    vec2 shift = 20.*hash21(seed);
    p += shift;
    vec2 pnoise = perlin(p*0.25+seed);
    
    //bilinear interpolation between sin grids
    return singrid(p,0.)*(pnoise.x*pnoise.y+(1.-pnoise.x)*(1.-pnoise.y)) +
           singrid(p,3.14159*0.33*2.)*(1.-pnoise.x)*pnoise.y +
           singrid(p,3.14159*0.66*2.)*(1.-pnoise.y)*pnoise.x;
}

vec3 blue3(vec2 p, float seed)
{
    vec3 res;
    res.x = blue(p, sin(seed));
    res.y = blue(p, sin(2.*seed));
    res.z = blue(p, sin(3.*seed));
    return res;
}

float qntz(float x, float d)
{
    return round(x/d)*d;
}


vec4 sdPlane( vec3 p )
{
	return vec4(vec3(0.25,0.25,0.25) + mod(round(p.x)+round(p.y),2.)*vec3(0.5,0.5,0.5),p.z);
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

vec3 sdSponge(vec3 p)
{
   p.xyz = p.xyz - 2.44*round(clamp(p.xyz/2.44, -2., 0.));
    
   float d = sdBox(p,vec3(1.0));
   vec3 res = vec3( d, 1.0, 0.0 );

   float s = 1.0;
   for( int m=0; m<5; m++ )
   {
      vec3 a = mod( p*s, 2.0 )-1.0;
      s *= 3.0;
      vec3 r = abs(1.0 - 3.0*abs(a));

      float da = max(r.x,r.y);
      float db = max(r.y,r.z);
      float dc = max(r.z,r.x);
      float c = (min(da,min(db,dc))-1.0)/s;

      if( c>d )
      {
          d = c;
          res = vec3( d, 0.2*da*db*dc, (1.0+float(m))/4.0 );
      }
   }
   return res;
}

float light_map(vec3 p, float time)
{
    float sd = sdSphere(p - vec3(-10.*cos(0.0*time),-10.*cos(0.0*time), 5.), 1.);
    //sd = min(sd, sdSphere(p - vec3(5.*cos(0.8*iTime+3.14),5.*sin(0.8*iTime+3.14), 2.), 0.5));
    return sd;
}


float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

void mengerFold(inout vec3 z) {
	float a = smin(z.x - z.y, 0.0, 0.2);
	z.x -= a;
	z.y += a;
	a = min(z.x - z.z, 0.0);
	z.x -= a;
	z.z += a;
	a = min(z.y - z.z, 0.0);
	z.y -= a;
	z.z += a;
}


void rotX(inout vec3 z, float s, float c) {
	z.yz = vec2(c*z.y + s*z.z, c*z.z - s*z.y);
}
void rotY(inout vec3 z, float s, float c) {
	z.xz = vec2(c*z.x - s*z.z, c*z.z + s*z.x);
}
void rotZ(inout vec3 z, float s, float c) {
	z.xy = vec2(c*z.x + s*z.y, c*z.y - s*z.x);
}
void rotX(inout vec3 z, float a) {
	rotX(z, sin(a), cos(a));
}
void rotY(inout vec3 z, float a) {
	rotY(z, sin(a), cos(a));
}
void rotZ(inout vec3 z, float a) {
	rotZ(z, sin(a), cos(a));
}

vec4 sdFractal(vec3 p, float itr, vec2 cell, float sc)
{
    p.xz = p.xz+cell*0.5;
    vec2 cell_i = floor(p.xz/cell);
    p.xz = mod(p.xz, cell) -  cell*0.5;
    float box = sdBox(p.xzy, vec3(cell.xy*0.35,1000.));
    vec3 dp = ((length(cell_i)==0.)?iFracShift:iFracShift*0.9+3.*hash31(dot(cell_i,vec2(1.,sqrt(2.)))));
    float scale = 1.;
    vec3 orbit =  vec3(0.);
    vec3 col = vec3(0.);
    float norm = 0.;
    
    vec2 angl = (cell_i)*0.05 + vec2(iFracAng1,iFracAng2);
    float s1 = sin(angl.x), c1 = cos(angl.x);
    float s2 = sin(angl.y), c2 = cos(angl.y);

	for (float i = 0.; i < itr; i++) 
    {
		p = abs(p);
		rotZ(p, s1, c1);
		mengerFold(p);
		rotX(p, s2, c2);
        scale *= sc;
		p = p*sc + dp;
    	orbit = max(orbit, sin(.9*p*iFracCol));
	}
	return vec4(clamp(1.-0.8*orbit,0.,1.),max(sdBox(p, vec3(6.0))/scale, box));
}

vec4 opU(vec4 a, vec4 b)
{
    return (a.w<b.w)?a:b;
}

vec4 map(vec3 p)
{
    vec4 sd = opU( sdFractal(p.xzy - vec3(14,0,0), FRACTAL_ITER, vec2(35,35),  iFracScale),
                   sdFractal(p.xzy - vec3(0,-30,-60), 5.,  vec2(100,100),  iFracScale*0.5));
    return sd;
}


vec4 calcGrad( in vec3 pos )
{
    vec4 e = vec4(0.0005,-0.0005, 0.25, -0.25);
    return   (e.zwwz*map( pos + e.xyy ).w + 
  			  e.wwzz*map( pos + e.yyx ).w + 
			  e.wzwz*map( pos + e.yxy ).w + 
              e.zzzz*map( pos + e.xxx ).w )/vec4(e.xxx, 1.);
}

//calculate the normal using an already evaluated distance in one point
vec3 calcNormal(in vec3 pos, in float h)
{
    vec4 e = vec4(0.0005,-0.0005, 1., -1);
    pos = pos - e.xxx;
    return normalize(e.zww*map( pos + e.xyy ).w + 
  			 		 e.wwz*map( pos + e.yyx ).w + 
			  		 e.wzw*map( pos + e.yxy ).w + 
              		 e.zzz*h );
}

vec4 trace(vec3 p, vec3 ray, inout float t, inout float i, float angle)
{
    float h = 0., prev_h = 0., avg_h = 0., td = 0.;
    float omega = overrelax;
    float candidate_td = 0.;
    float candidate_error = 1e6;
    float j = i;
    for(; ((t+td) < MAX_DIST) && (i < MAX_STEPS);  i++)
    {
        h = map(p + td*ray).w;
        
        if(prev_h*omega>max(h,0.)+max(prev_h,0.)) //if overtepped
        {
            td += (1.-omega)*prev_h; // step back to the safe distance
            prev_h = 0.;
            omega = (omega - 1.)*0.7 + 1.; //make the overstepping smaller
        }
        else
        {
            if(h/td < candidate_error)
            {
                candidate_error = h/td;
                candidate_td = td; 
                if(h < (t+td)*angle)
                {
                    break;
                }
            }

            
            td += h*omega; //continue marching
            
           /* float avging = 0.8*tanh(0.2*(i-j));
           	avg_h = avg_h*avging + (1. - avging)*h;
            if(abs(h - avg_h) < 0.08*avg_h) //if h is not changing much
            {
                omega = clamp(omega*1.02,1.,2.); //then accelerate marching 
            }*/
            
            prev_h = h;        
        }
    }
    
    t+=td;

    return vec4(p + candidate_td*ray, candidate_error*candidate_td); 
   
}


//Keyboard constants
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
const int KEY_A     = 65;
const int KEY_B     = 66;
const int KEY_C     = 67;
const int KEY_D     = 68;
const int KEY_E     = 69;
const int KEY_F     = 70;
const int KEY_G     = 71;
const int KEY_H     = 72;
const int KEY_I     = 73;
const int KEY_J     = 74;
const int KEY_K     = 75;
const int KEY_L     = 76;
const int KEY_M     = 77;
const int KEY_N     = 78;
const int KEY_O     = 79;
const int KEY_P     = 80;
const int KEY_Q     = 81;
const int KEY_R     = 82;
const int KEY_S     = 83;
const int KEY_T     = 84;
const int KEY_U     = 85;
const int KEY_V     = 86;
const int KEY_W     = 87;
const int KEY_X     = 88;
const int KEY_Y     = 89;
const int KEY_Z     = 90;
