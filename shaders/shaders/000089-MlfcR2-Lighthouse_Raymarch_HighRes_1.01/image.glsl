// Image (image) — Lighthouse Raymarch HighRes 1.01 by ingagard
// https://www.shadertoy.com/view/MlfcR2

//////////////////////////////////////////////////////////////////////////////////////
///////////////////// CREATED BY KIM BERKEBY, SEP 2017 ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////////////////////// SPECIAL THANKS TO Inigo Quilez  ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////// Feel free to mail me at mr.kimb@hotmail.com /////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

#define PI 3.14159265
  #define TAU (2.*PI)
  #define PHI (sqrt(5.)*0.5 + 0.5)
  #define M_NONE -1.0
  #define M_NOISE 1.0
  #pragma optimize(off) 
  const vec3 sunPos = normalize(vec3(5.3, 2.7, -1.));
const vec3 sunColor = vec3(0.80, 0.7, 0.55);         
const vec3 eps = vec3(0.02, 0.0, 0.0);
float winDist=100000.0;
float dekoDist=100000.0;
float steelDist=100000.0;

struct RayHit
{
  bool hit;  
  vec3 hitPos;
  vec3 normal;
  float dist;
  float depth;
  float steps;
  float winDist;
  float dekoDist;
  float steelDist;
  float glassDist;
};


float hash(float h) 
{
  return fract(sin(h) * 43758.5453123);
}

float noise(vec3 x) 
{
  vec3 p = floor(x);
  vec3 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);

  float n = p.x + p.y * 157.0 + 113.0 * p.z;
  return mix(
    mix(mix(hash(n + 0.0), hash(n + 1.0), f.x), 
    mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y), 
    mix(mix(hash(n + 113.0), hash(n + 114.0), f.x), 
    mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

float fbm(vec3 p) 
{
  float f = 0.0;
  f = 0.5000 * noise(p);
  p *= 2.01;
  f += 0.2500 * noise(p);
  p *= 2.02;
  f += 0.1250 * noise(p);
  return f;
}


float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x, p.y);
  return length(q)-t.y;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa, ba)/dot(ba, ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdEllipsoid( vec3 p, vec3 r )
{
  return (length( p/r.xyz ) - 1.0) * r.y;
}

float sdConeSection( vec3 p, float h, float r1, float r2 )
{
  float d1 = -p.y - h;
  float q = p.y - h;
  float si = 0.5*(r1-r2)/h;
  float d2 = max( sqrt( dot(p.xz, p.xz)*(1.0-si*si)) + q*si - r2, q );
  return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.);
}

float fCylinder(vec3 p, float r, float height) {
  float d = length(p.xy) - r;
  d = max(d, abs(p.z) - height);
  return d;
}

float fCylinderH(vec3 p, float r, float height) {
  float d = length(p.xz) - r;
  d = max(d, abs(p.y) - height);
  return d;
}

float fCylinderV(vec3 p, float r, float height) {
  float d = length(p.yz) - r;
  d = max(d, abs(p.x) - height);
  return d;
}

float fOpPipe(float a, float b, float r) {
  return length(vec2(a, b)) - r;
}

float fOpIntersectionChamfer(float a, float b, float r) {
  return max(max(a, b), (a + r + b)*sqrt(0.5));
}

float fOpUnionChamfer(float a, float b, float r) {
  return min(min(a, b), (a - r + b)*sqrt(0.5));
}

vec2 pModPolar(in vec2 p, float repetitions) {
  float angle = 2.*PI/repetitions;
  float a = atan(p.y, p.x) + angle/2.;
  float r = length(p);
  float c = floor(a/angle);
  a = mod(a, angle) - angle/2.;
  p = vec2(cos(a), sin(a))*r;
  if (abs(c) >= (repetitions/2.)) c = abs(c);
  return p;
}

float pModSingle1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  if (p >= 0.)
    p = mod(p + halfsize, size) - halfsize;
  return c;
}

float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p+halfsize, size) - halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}


float SmallWindow( vec3 p)
{
  float d= sdBox(p-vec3(-.65, 1.17, 0.0), vec3(0.08, 0.4, 0.4));

  if(d<1.) // AABB
  {
  d= max(d, -sdBox(p-vec3(-.06, 1.17, 0.0), vec3(0.54, 0.36, .36))); 
  d= max(d, -sdBox(p-vec3(-.22, 1.17, 0.0), vec3(0.54, 0.32, .32))); 
  d= min(d, sdBox(p-vec3(-0.58, 1.65, 0.), vec3(0.165, 0.04, 0.5)));
  steelDist= min(steelDist, sdBox(p-vec3(-.64, 1.17, 0.0), vec3(0.02, 0.30, 0.02))); 
  vec3 winPos = p-vec3(-.64, 1.10, 0.0);
  pModInterval1(winPos.y,0.25,0.,1.0);
  steelDist= min(steelDist, sdBox(winPos, vec3(0.01, 0.02, 0.38))); 
  d= min(d, sdBox(p-vec3(-.59, .71, 0.), vec3(0.13, 0.05, 0.45)));
  d= min(d, sdBox(p-vec3(-.59, 0.69, 0.), vec3(0.18, 0.025, 0.50)));

  // lower decoration 
  d= min(d, sdBox(p-vec3(-0.70, .49, 0.), vec3(0.25, 0.2, 0.07)));   
  d = fOpIntersectionChamfer(d, -fCylinder(p-vec3(-0.32, .25, 0.), 0.23, 1.63), 0.03);
  }
  return d;
}


float Window( vec3 p)
{
  float d= sdBox(p-vec3(-0.58, 1.17, 0.), vec3(0.075, 0.7, 0.4));

    if(d<2.0)
    {
  d = max(d, -sdBox(p-vec3(-0.28, 1.17, 0.), vec3(0.25, 0.67, 0.37)));
  d= fOpIntersectionChamfer(d, -sdBox(p-vec3(-0.21, 1.17, 0.), vec3(1.3, 0.55, 0.22)), 0.09); 
  d= min(d, sdBox(p-vec3(-0.58, 1.7, 0.), vec3(0.325, 0.06, 0.48)));

  steelDist= min(steelDist, sdBox(p-vec3(-0.55, 1.17, 0.), vec3(0.01, 0.60, 0.02))); 
 
  vec3 winPos = p-vec3(-0.55, 0.80, 0.);
  pModInterval1(winPos.y,0.30,0.,2.0);        
  steelDist= min(steelDist, sdBox(winPos, vec3(0.01, 0.02, 0.4))); 

  d=min(d, max(max(fCylinderV(p-vec3(-0.5, 1.74, 0.), 0.42, 0.13), -sdBox(p-vec3(-0.5, 1.49, 0.), vec3(1., 0.27, 1.5))), -fCylinderV(p-vec3(-0.5, 1.74, 0.), 0.38, 0.53)));

  d= min(d, sdBox(p-vec3(-.52, .42, 0.), vec3(0.13, 0.05, 0.45)));
  d= min(d, sdBox(p-vec3(-.52, 0.40, 0.), vec3(0.18, 0.025, 0.50)));

  // lower decoration 
  d= min(d, sdBox(p-vec3(-0.55, .20, 0.4), vec3(0.15, 0.2, 0.05)));   
  d= min(d, sdBox(p-vec3(-0.55, .20, -0.4), vec3(0.15, 0.2, 0.05)));
  d = fOpIntersectionChamfer(d, -fCylinder(p-vec3(-0.3, .0, 0.), 0.23, 1.63), 0.02);

  // upper decoration 
  dekoDist=min(dekoDist, sdBox(p-vec3(-0.55, 2.63, 0.), vec3(0.3, 0.45, 0.12)));    
  dekoDist = fOpIntersectionChamfer(dekoDist, -fCylinder(p-vec3(-0.22, 2.45, -0.1), 0.21, 0.63), 0.03);
    }
  return d;
}


float MapStreeLight(  vec3 p)
{
  float d= fCylinder(p-vec3(0.31, -3.5, 0.), 0.7, 0.01);
  d=fOpPipe(d, fCylinder(p-vec3(.31, -4., 0.), 0.7, 3.0), .05);   
  d=min(d, fCylinderH(p-vec3(.98, -6.14, 0.), 0.05, 2.4));        
  d=fOpUnionChamfer(d, fCylinderH(p-vec3(.98, -8., 0.), 0.1, 1.0), 0.12);  
  d=min(d, sdSphere(p-vec3(-0.05, -3.4, 0.), 0.2));  
  d=min(d, sdSphere(p-vec3(-0.05, -3.75, 0.), 0.4));        
  d=max(d, -sdSphere(p-vec3(-.05, -3.9, 0.), 0.45)); 

  return d;
}

float MapGlass(  vec3 p)
{  
  vec3 checkPos = p;

  float dist = sdCappedCylinder(p-vec3(0.0, 5.0, 0), vec2(1.02, .8));
  checkPos.xz = pModPolar(p.xz, 6.0);
  dist = min(dist, sdBox(checkPos-vec3(1.60, 1.1, 0.), vec3(0.01, .60, 0.35)));   
  checkPos.xz = pModPolar(p.xz, 5.0);
  dist = min(dist, sdBox(checkPos-vec3(1.84, -3.33, 0.), vec3(0.01, 0.30, .3))); 
  return min(dist, sdBox(checkPos-vec3(2.12, -6.83, 0.), vec3(0.01, 0.30, .3)));
}


#define radius 1.6
#define outRad 1.82
#define inRad 1.12
vec3 checkPos;

float Map(  vec3 p)
{
  float  d=100000.0;
  checkPos = p;
  winDist=dekoDist=steelDist=100000.0;

  d=sdCappedCylinder(p-vec3(0.0, -3.0, 0), vec2(4.0, 12.45));
  if(d<1.0)
  {
  
  d = sdCappedCylinder(p-vec3(0.0, 3.7, 0), vec2(inRad, .45));
  d=min(d, sdSphere(p-vec3(0., 4., 0), 0.50));
  d=min(d, fCylinderH(p-vec3(0.0, 1.3, 0), radius, 1.80));
  d=min(d, sdConeSection(p-vec3(0.0, -6.0, 0.), 5.3, 2.4, 1.7));
  d=min(d, sdConeSection(p-vec3(0.0, -13.0, 0.), 1.8, 2.8, 2.6));

  // lamp
  d=min(d, sdSphere(p-vec3(0., 4.9, 0), 0.3));
  d=min(d, sdCappedCylinder(p-vec3(0.0, 4.5, 0), vec2(0.12, 1.2)));

  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, 5.8, 0), vec2(inRad, .15)));                  
  dekoDist =min(dekoDist, sdTorus(p-vec3(0.0, 4., 0), vec2(inRad, .11)));
  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -.35, 0), vec2(radius-0.05, .15)));
  dekoDist=min(dekoDist, fCylinderH(p-vec3(0.0, -.5, 0), radius+0.02, .15));
  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -0.6, 0), vec2(radius+0.15, .15)));
  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -1.65, 0), vec2(radius+0.08, .15))); 
  dekoDist=min(dekoDist, fCylinderH(p-vec3(0.0, 3.18, 0), radius+0.35, 0.15));  
  dekoDist=min(dekoDist, fCylinderH(p-vec3(0.0, 2.7, 0), radius+0.14, .30));
  dekoDist=min(dekoDist, fCylinderH(p-vec3(0.0, 2.85, 0), radius+0.18, .18));
  dekoDist=min(dekoDist, fCylinderH(p-vec3(0.0, 3.1, 0), radius+0.22, .18));
  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -9., 0), vec2(radius+0.6, .25))); 
  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -11.30, 0.), vec2(2.42, 0.25)));     

  // lower border
  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -2.35, 0), vec2(radius+0.25, .15)));

  // deko and windows steel top
  checkPos.xz = pModPolar(p.xz, 12.0);
  steelDist=min(steelDist, sdCappedCylinder(checkPos-vec3(outRad+0.05, 3.6, 0), vec2(0.03, .42)));
  steelDist=min(steelDist, sdCapsule(checkPos-vec3(inRad-0.06, 4.2, 0), vec3(0, 0., 0), vec3(0, 1.45, 0), 0.02));
  steelDist=min(steelDist, sdBox(checkPos-vec3(inRad-0.19, 6.25, 0), vec3(0.25, .3, 0.25)));
  steelDist=fOpIntersectionChamfer(steelDist, -sdBox(checkPos-vec3(inRad+0.20, 6.25, 0), vec3(0.19, 0.24, 0.19)), 0.12);

  // top
  dekoDist=min(dekoDist, sdCappedCylinder(p-vec3(0.0, 6.2, 0), vec2(inRad, .45)));
  dekoDist=min(dekoDist, sdSphere(p-vec3(0., 6.5, 0), 1.10));
  steelDist=min(steelDist, sdCappedCylinder(p-vec3(0.0, 7.5, 0), vec2(0.5, .45)));
  steelDist=min(steelDist, sdSphere(p-vec3(0., 7.9, 0), 0.45));
  steelDist=min(steelDist, sdSphere(p-vec3(0., 8.4, 0), 0.10));   
     
  vec3 pp = p-vec3(0.0, 4.4, 0);
  pModInterval1(pp.y,0.4,0.0,2.);          
  steelDist=min(steelDist, sdTorus(pp, vec2(inRad-0.02, .02)));
      
  pp = p-vec3(0.0, 3.55, 0);
  pModInterval1(pp.y,0.15,0.0,3.);          
  steelDist=min(steelDist, sdTorus(pp, vec2(outRad+0.05, .025)));

  // upper decoration
  checkPos.xz = pModPolar(p.xz, 6.0);
  dekoDist = max(dekoDist, -fCylinderV(checkPos-vec3(0.0, 2.4, 0), 0.6, 2.63));

  // windows cutouts   
  checkPos.xz = pModPolar(p.xz, 6.0);   
  d=max(d, -sdBox(checkPos-vec3(2.20, 1.17, 0.), vec3(3.25, 0.7, 0.4))); 
  checkPos.xz = pModPolar(p.xz, 5.0); 
  pp = checkPos-vec3(2.50, -6.83, 0.);
  pModInterval1(pp.y,3.5,0.0,1.);         
  d= max(d, -sdBox(pp, vec3(1.3, 0.35, 0.35)));  

  // upper windows   
  checkPos.xz = pModPolar(p.xz, 6.0);   
  winDist = min(winDist, Window(checkPos-vec3(2.20, 0, 0.))); 

  // middle windows (upper deco)
  checkPos.xz = pModPolar(p.xz, 5.0); 
  dekoDist=min(dekoDist, sdBox(checkPos-vec3(2.10, -2.44, 0.0), vec3(0.3, 0.4, 0.12)));   
  dekoDist = fOpIntersectionChamfer(dekoDist, -fCylinder(checkPos-vec3(2.40, -2.04, 0.0), 0.21, 0.63), .03); 
  dekoDist = max(dekoDist, -fCylinder(checkPos-vec3(2.50, -2.62, 0.0), 0.51, 0.63));
  
  // middle and lower windows      
   pp = checkPos-vec3(2.78, -8.0, 0.);
  float m=pModInterval1(pp.y, 3.5,0.,1.);
  winDist = min(winDist, SmallWindow(pp+mix(vec3(0.),vec3(0.28,0.0, 0.),m)));   

  // make tower hollow
  d=max(d, -sdConeSection(p-vec3(0.0, -6.0, 0.), 5., 2.3, 1.55));

  dekoDist=min(dekoDist, sdTorus(p-vec3(0.0, -15.2, 0), vec2(2.5, .75))); 
  dekoDist=min(dekoDist, sdBox(p-vec3(-0., -14.3, 2.5), vec3(0.7, 1.4, 0.4)));    
  dekoDist=min(dekoDist, fCylinder(p-vec3(-0., -13., 2.5), 0.7, 0.4)); 

  // create door opening    
  float doorOpening = min(sdBox(p-vec3(-0., -14.3, 2.5), vec3(0.6, 1.3, 4.6)), fCylinder(p-vec3(-0., -13., 2.5), 0.6, 4.6));

  dekoDist = min(fOpPipe(dekoDist, doorOpening, 0.13), max(dekoDist, -doorOpening));

  checkPos.xz = pModPolar(p.xz, 8.0);
  d=fOpIntersectionChamfer(d, -fCylinderH(checkPos-vec3(2.95, -15.4, 0), 0.2, 3.6), 0.5);    
  checkPos.xz = pModPolar(p.xz, 16.0);
  d=fOpUnionChamfer(d, fCylinderH(checkPos-vec3(2.2, -10.3, 0), 0.03, 0.8), 0.4);    

  d=max(d, -sdBox(p-vec3(-0., -14.3, 2.7), vec3(0.6, 1.3, 4.6)));    
  d=max(d, -fCylinder(p-vec3(-0., -13., 2.5), 0.6, 4.6));    

  // door   
  d=min(d, sdBox(p-vec3(-0., -13.6, 2.0), vec3(0.6, 1.3, 0.4))); 
    
  // door cutout     
  pp = p-vec3(-0.28, -13.3, 2.4);
  pModInterval1(pp.x, 0.56,0.,1.);     
  d=max(d, -sdBox(pp, vec3(0.25, 0.25, 0.08)));   
  pp = p-vec3(-0.28, -14.1, 2.4);
  pModInterval1(pp.x, 0.56,0.,1.);     
  d=max(d, -sdBox(pp, vec3(0.25, 0.4, 0.08))); 

  dekoDist=max(dekoDist, -sdBox(p-vec3(-0., -16.2, 0), vec3(6.6, 1.3, 8.6)));  
  }
    
  
  // railing (platform) 
  checkPos.xz = pModPolar(p.xz, 32.0);   
  steelDist=min(steelDist, sdCappedCylinder(checkPos-vec3(radius+8., -14.4, 0), vec2(0.05, .46)));   
  steelDist=min(steelDist, sdTorus(p-vec3(0., -14.2, 0), vec2(radius+8., 0.02)));
  steelDist=min(steelDist, sdTorus(p-vec3(0., -14.35, 0), vec2(radius+8., 0.02)));
  steelDist=min(steelDist, sdTorus(p-vec3(0., -13.9, 0), vec2(radius+8., 0.04)));
  checkPos.xz = pModPolar(p.xz, 7.0); 
  steelDist = min(steelDist, MapStreeLight(checkPos-vec3(radius+6.7, -6.63, 0)));  
  steelDist=max(steelDist, -sdBox(p-vec3(13.3, 0., 0.), vec3(6.6, 22.5, 3.7)));   
  steelDist=max(steelDist, -sdBox(p-vec3(0.0, -16.05, 0), vec3(16.6, 1.2, 16.6)));  
    
  return  min(d, min(steelDist, min(dekoDist, winDist)));
}


vec3 calcNormal(  vec3 pos )
{    
  return normalize( vec3(Map(pos+eps.xyy) - Map(pos-eps.xyy), 0.5*2.0*eps.x, Map(pos+eps.yyx) - Map(pos-eps.yyx) ) );
}

vec3 calcNoiseNormal(  vec3 pos )
{    
  return normalize( vec3(fbm(pos+eps.xyy) - fbm(pos-eps.xyy), 0.5*2.0*eps.x, fbm(pos+eps.yyx) - fbm(pos-eps.yyx) ) );
}

float SoftShadow(  vec3 origin,  vec3 direction )
{
  float res = 2.0, t = 0.0, h;
  for ( int i=0; i<32; i++ )
  {
    h = Map(origin+direction*t);
    res = min( res, 6.5*h/t );
    t += clamp( h, 0.07, 0.6 );
    if ( h<0.0025 ) break;
  }
  return clamp( res, 0.0, 1.0 );
}



RayHit March( vec3 origin,  vec3 direction)
{
  RayHit result;
  float maxDist = 70.0;
  float t = 0.0, glassDist = 10000.0, dist = 0.0;
  vec3 rayPos;

  for ( int i=0; i<200; i++ )
  {
    rayPos =origin+direction*t;
    dist = Map( rayPos);
    glassDist=min(glassDist, MapGlass( rayPos));

    if (abs(dist)<0.001 || t>maxDist )
    {             
      result.hit=!(t>maxDist);
      result.depth = t; 
      result.dist = dist;                              
      result.hitPos = origin+((direction*t));   
      result.steps = float(i);
      result.winDist = winDist;
      result.glassDist = glassDist;
      result.dekoDist = dekoDist;
      result.steelDist = steelDist;
      break;
    }
    t += dist;
  }    
   

  return result;
}
// Copyright © 2015 Inigo Quilez
vec3 CubeMap( sampler2D sam, in vec3 d )
{
    vec3 n = abs(d);

#if 0
    // sort components (small to big)    
    float mi = min(min(n.x,n.y),n.z);
    float ma = max(max(n.x,n.y),n.z);
    vec3 o = vec3( mi, n.x+n.y+n.z-mi-ma, ma );
    return texture( sam, .1*o.xy/o.z ).xyz;
#else
    vec2 uv = (n.x>n.y && n.x>n.z) ? d.yz/d.x: 
              (n.y>n.x && n.y>n.z) ? d.zx/d.y:
                                     d.xy/d.z;
    return texture( sam, uv ).xyz;
    
#endif    
}

mat3 setCamera( vec3 ro,  vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}

// Copyright © 2013 Inigo Quilez
float calcAO( in vec3 pos, in vec3 nor )
{
  float occ = 0.0;
  float sca = 1.0;
  for ( int i=0; i<5; i++ )
  {
    float hr = 0.01 + 0.12*float(i)/4.0;
    vec3 aopos =  nor * hr + pos;
    float dd = Map( aopos );
    occ += -(dd-hr)*sca;
    sca *= 0.95;
  }
  return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}


vec3 GetSceneLight(float specLevel, vec3 normal, RayHit rayHit, vec3 rayDir, vec3 origin)
{        
  vec3 reflectDir = reflect( rayDir, normal );

  float amb = clamp( 0.5+0.5*normal.y, 0.0, 1.0 );
  float dif = clamp( dot( normal, sunPos ), 0.0, 1.0 );
  float bac = clamp( dot( normal, normalize(vec3(-sunPos.x, 0.0, -sunPos.z))), 0.0, 1.0 )*clamp( 1.0-rayHit.hitPos.y, 0.0, 1.0);
  float fre = pow( clamp(1.0+dot(normal, rayDir), 0.0, 1.0), 2.0 );
  specLevel*= pow(clamp( dot( reflectDir, sunPos ), 0.0, 1.0 ), 16.0);

  float skylight = smoothstep( -0.1, 0.1, reflectDir.y );
  vec3 shadowPos = origin+((rayDir*rayHit.depth)*0.99);  
  dif *= SoftShadow( shadowPos, sunPos);
  skylight *=SoftShadow(shadowPos, reflectDir);

  vec3 lightTot = vec3(0.0);

    
    
  lightTot += 1.30*dif*vec3(1.00, 0.80, 0.55);
  lightTot += 0.50*skylight*vec3(0.40, 0.60, 1.00);
      lightTot += 1.20*specLevel*vec3(0.9, 0.8, 0.7)*dif;
  lightTot += 0.50*bac*vec3(0.25, 0.25, 0.25);
  lightTot += 0.25*fre*vec3(1.00, 1.00, 1.00);
  return lightTot +(0.40*amb*vec3(0.40, 0.60, 1.00));
}




vec4 GetMaterial( vec3 rayDir, inout RayHit rayHit)
{
  vec3 col = vec3(0.6);
  float specLevel=1.30;

  // windows
  if (rayHit.winDist==rayHit.dist)
  {
    vec3 dirt =  CubeMap(iChannel3, rayHit.hitPos*.1).rgb*0.8; 
    col = vec3(0.9);
    col = mix(col, dirt, fbm(rayHit.hitPos*1.71)); 
    specLevel = 0.4;
  } 
  // decorations
  else if (rayHit.dekoDist==rayHit.dist)
  {    
    col=vec3(0.6);
    vec3 moss =  CubeMap(iChannel3, rayHit.hitPos*0.22).rgb*vec3(0.356, 0.455, 0.228);
    vec3 dirt =  CubeMap(iChannel3, (rayHit.hitPos*.44)).rgb*1.5; 
    col = mix(col, dirt*0.7, fbm(rayHit.hitPos*10.71)); 
    col = mix(col, moss, pow(fbm(rayHit.hitPos*0.71), 1.5)); 
    col = mix(col, moss, smoothstep(0.55+fbm(rayHit.hitPos*0.51), -.4, rayHit.winDist));
    rayHit.normal = mix(rayHit.normal, (rayHit.normal+calcNoiseNormal(rayHit.hitPos*10.9))*0.5, 0.25);
    specLevel = 2.3;
  } 
  // steel 
  else if (rayHit.steelDist==rayHit.dist)
  {
    vec3 dirt =  CubeMap(iChannel3, (rayHit.hitPos*.44)).rgb*1.5; 
    col = vec3(0.3+(fbm(rayHit.hitPos*1.71)*.5));
    col = mix(col, dirt*0.7, fbm(rayHit.hitPos*10.71));         
    specLevel = 6.0;
  } 
  // tower base texture
  else
  {
    vec3 moss =  texture(iChannel3, vec2(atan(rayHit.hitPos.z,rayHit.hitPos.x)*2.0, rayHit.hitPos.y)*0.22).rgb*vec3(0.356, 0.455, 0.228);
    vec3 dirt =  texture(iChannel3, vec2(atan(rayHit.hitPos.z,rayHit.hitPos.x)*2.0, rayHit.hitPos.y)*.44).rgb*1.5; 
    // top part
    if (rayHit.hitPos.y>-11.1)
    {     
      col=vec3(0.9);
      col = mix(col, dirt*0.7, fbm(rayHit.hitPos*.71)); 
      col = mix(col, moss, smoothstep(-9., -11.01, rayHit.hitPos.y+fbm(rayHit.hitPos*3.71)));  
      col = mix(col, dirt, smoothstep(2.1+fbm(rayHit.hitPos*0.71), -.40, pow(rayHit.dekoDist, 3.00)));   
      col = mix(col, dirt, smoothstep(1.1+fbm(rayHit.hitPos*0.51), -.4, pow(rayHit.winDist, 2.50)));
      col = mix(dirt, col, smoothstep(2.0, 1.3, rayHit.hitPos.y+fbm(rayHit.hitPos*3.71)));  
      rayHit.normal = mix(rayHit.normal, (rayHit.normal+calcNoiseNormal(rayHit.hitPos*10.))*0.5, 0.15);
    } 
    // lower part
    else
    {
      vec3 tex2 =  texture(iChannel3, vec2(atan(rayHit.hitPos.z,rayHit.hitPos.x)*2.0, rayHit.hitPos.y)*0.8).rgb;
      col=mix(moss, tex2, 0.5);
      col = mix(col, dirt*0.7, fbm(rayHit.hitPos*.21));
      col = mix(moss, col, smoothstep(-10., -12.01, rayHit.hitPos.y+fbm(rayHit.hitPos*3.71)));
      col = mix(col, moss, smoothstep(-13., -15.01, rayHit.hitPos.y+fbm(rayHit.hitPos*3.71))); 
      rayHit.normal = mix(rayHit.normal, (rayHit.normal+calcNoiseNormal(rayHit.hitPos*8.))*0.5, 0.15);
    }
  }

  return vec4(col, specLevel);
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{  
  vec2 mo = iMouse.xy/iResolution.xy;
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;

  float camrot = 20.0+(iTime*0.2);
  if (iMouse.w>0.1) camrot+=mo.x*16.; 

  vec3 rayOrigin = vec3(8.*cos(camrot), 1.+12.*sin(camrot*1.8), 13.5 + 24.0*sin(camrot) );
  mat3 ca = setCamera( rayOrigin, vec3(0., -6., 0.5 ), 0.0 );
  vec3 rayDir = ca * normalize( vec3(screenSpace.xy, 2.0) );

  vec3 skyColor = texture(iChannel0, uv).rgb;
  vec3 color = skyColor;

  RayHit marchResult = March(rayOrigin, rayDir);

  if (marchResult.hit)
  {
    marchResult.normal = calcNormal(marchResult.hitPos);  
    vec4 col = GetMaterial(rayDir, marchResult);

    // get lightning based on material
    vec3 light = GetSceneLight(col.a, marchResult.normal, marchResult, rayDir, rayOrigin);   
    // apply lightning
    color = col.rgb*light;
  }

    color = mix(mix(color, skyColor, 0.5),color,step(0.05,marchResult.glassDist));
  

  color = mix(color, skyColor, smoothstep(40., 140., marchResult.depth));  

  float sun = clamp( dot(sunPos, rayDir), 0.0, 1.0 );  
  color += vec3(.9, 0.4, 0.2)*sun*sun*clamp((rayDir.y+0.4)/0.4, 0.0, 0.4);

  fragColor = vec4(pow(color.rgb, vec3(1.0/1.1)), 1.0 ) * (0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.2 ));
}
