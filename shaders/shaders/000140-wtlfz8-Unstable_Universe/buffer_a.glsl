// Buffer A (buffer) — Unstable Universe by julianlumia
// https://www.shadertoy.com/view/wtlfz8


#define MAX_STEPS 64
#define MAX_DIST 50.
#define SURF_DIST .001



vec2 condmin(in vec2 d1, in vec2 d2) {
return vec2(min(d1.x, d2.x), mix(d1.y, d2.y, step(d2.x, d1.x)));
}

float sdOctahedron( vec3 p, float s)
{
 p = abs(p);
 return (p.x+p.y+p.z-s)*0.57735027;
}

mat2 Rot(float a) {
 float s = sin(a);
 float c = cos(a);
 return mat2(c, -s, s, c);
}



float displacement(vec3 p, float scale)
{
    return sin(scale*p.x)*sin(scale*p.y)*sin(scale*p.z);
}


float smin( float a, float b, float k ) {
 float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
 return mix( b, a, h ) - k*h*(1.0-h);
}

float sdSphere(vec3 p, float s)
{
 return length(p) - s;
}

float sdBox(vec3 p, vec3 s) {
 p = abs(p)-s;
 return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float g1;
float g2;
float g3;
float g4;
float g8;

mat3 rotate( in vec3 v, in float angle)
{
	float c = cos(radians(angle));
	float s = sin(radians(angle));
	
	return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}

const float PI = 3.14159265;

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
  vec3 pa = p - a, ba = b - a;
  float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
  return length( pa - ba*h ) - r;
}

vec3 spherepos2;

vec3 spherepos;
vec2 GetDist(vec3 p) {
 vec2 d;
 d = vec2(p.y +1.,7);
 vec3 size3 = vec3(1.);
 vec3 pos = vec3(0,0.,.5);
 vec3 p4 = p;
 p4 -=vec3(-0.,2.,.5);
 float the = iTime *.5;
 p4.xy *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 p4.yz *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 vec2 box10 = vec2((sdOctahedron(p4, 2.)),5.);
 vec2 octabox = vec2(sdBox(p4, vec3( 1.5)),5);
 vec2    box25 = vec2(sdBox(p+vec3(-0,3.,0.), vec3(1.,2.5,1.)),3);
 float displacement = sin(1.5*p.x+ iTime*1.4)*sin(1.2*p.y+ iTime)*cos(1.5*p.z+ iTime);
 box25.x += displacement;
 spherepos = vec3(-10,8,6);
 the = iTime*0.25;
 spherepos.xz *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 float box9 = (sdSphere(p-spherepos, 1.2));
 vec2 box;
 vec3 p2 = p;
 float two = ((dot(sin(p2.zzy+iTime*0.2)*5., cos(p2.zxy*6.+iTime))));
 d.x = mix(d.x,two,sin(p.x*0.5+iTime)*0.06);
 d.x *= 0.8;
 vec3 size = size3;
 p2.xz *= -mat2(cos(the), -sin(the), sin(the), cos(the));
 box = vec2(sdSphere(p2+vec3(3,-1.2,cos(iTime)*2.), 1.),3);
 vec2    box2 = vec2(sdSphere(p2+vec3(-3,-0.5,sin(iTime)*3.), .75),3);
 
 box.x = min(box.x,box2.x); 
 //teken lichtpunt
 box.x = min(box.x,box9);//box9
  if( box.x < d.x)
  {
   d = condmin(d,box);
  }
 box10.x = mix(octabox.x,box10.x,0.5);
 d.x = smin(d.x,box10.x,2.);
 g2 +=.04/(.05+pow(abs(box.x),6.));
 g4 +=1./(.4+pow(abs(box10.x),10.));
//zon
 g8 +=2./(.04+pow(abs(box9),3.));
 g3 +=1./(1.+box9*box9);
 d.x =smin(d.x,box25.x,1.);//box9
 d = condmin(d,box10);
 return d;
}


vec2 RayMarch(vec3 ro, vec3 rd) {
vec2 h, t=vec2( 0.);   
for (int i=0; i<MAX_STEPS; i++) 
{   
h = GetDist(ro + t.x * rd);
if(h.x<SURF_DIST||abs(t.x)>MAX_DIST) break;
t.x+=h.x *1.;
t.y=h.y;
}
if(t.x>MAX_DIST) 
t.x=100.;
t.x +=h.x*1.;
return t;
}
float marchCount;


float traceRef(vec3 o, vec3 r){
    
 float t = 0.0;
 marchCount = 0.0;
 float dO = 0.;  
 for (int i = 0; i < 60; i++)
 {
  vec3 p = o + r * t;   
  float d = GetDist (p).x;
  if(d<.001 || (t)>100.) break;
  t += d * .12;
  marchCount+= 1./d*1.;
 }    
 return t;
}


vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
 vec3 f = normalize(l-p),
 r = normalize(cross(vec3(0,1,0), f)),
 u = cross(f,r),
 c = p+f*z,
 i = c + uv.x*r + uv.y*u,
 d = normalize(i-p);
 return d;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ){
 vec3 cw = normalize(ta-ro);
 vec3 cp = vec3(sin(cr), cos(cr),0.0);
 vec3 cu = normalize( cross(cw,cp) );
 vec3 cv = cross(cu,cw);
 return mat3( cu, cv, cw );
}

vec3 GetNormal(vec3 p){
vec2 e = vec2(.00035, -.00035); 
return normalize(
 e.xyy * GetDist(p + e.xyy).x + 
 e.yyx * GetDist(p + e.yyx).x + 
 e.yxy * GetDist(p + e.yxy).x + 
 e.xxx * GetDist(p + e.xxx).x);
}

const float PI2 = 3.14159265359;
#define HASHSCALE1 .1031
float hash(float p)
{
	vec3 p3  = fract(vec3(p) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 randomSphereDir(vec2 rnd)
{
	float s = rnd.x*PI*2.;
	float t = rnd.y*2.-1.;
	return vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
}
vec3 randomHemisphereDir(vec3 dir, float i)
{
	vec3 v = randomSphereDir( vec2(hash(i+1.), hash(i+2.)) );
	return v * sign(dot(v, dir));
}

float ambientOcclusion( in vec3 p, in vec3 n, in float maxDist, in float falloff )
{
	const int nbIte = 32;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv; //Hemispherical factor (self occlusion correction)
    
	float ao = 0.0;
    
    for( int i=0; i<nbIte; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; // mix direction with the normal
        													    // for self occlusion problems!
        
        ao += (l - max(GetDist( p + rd ),0.).x) / maxDist * falloff;
    }
	
    return clamp( 1.-ao*nbIteInv, 0., 1.);
}


float shadow(vec3 r0, vec3 rd, float maxDist)
{
    float d = .001;
    float shadow = 1.0;
    while(d < maxDist)
    {
        float t = GetDist(r0 + d * rd).x;
        if(t < 0.05) return 0.0;
        d += t;
        shadow = min(shadow,50.0 * (t / d));
    }
    return shadow;
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(spherepos);
    vec3 l = normalize(lightPos-p);
    vec3 n = GetNormal(p);
    
    float dif = clamp(dot(n, l)*.5+.5, 0., 1.);
    float d = RayMarch(p+n*SURF_DIST*1., l).x;
    return dif;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
vec2 uv =( 2. * fragCoord.xy - iResolution.xy ) / iResolution.y;
/*
//motion blurr algorithm // by noby:   https://www.shadertoy.com/view/wljSz1
 const float tm = 2.5;
 const int samples = 1;
 float T = iTime*tm / 4.5;
 float ot = T;
 for(int y = 0; y < samples; ++y)
 for(int x = 0; x < samples; ++x)
 {
  vec2 p = -1.0 + 3.0 * (uv + (-0.5+(vec2(x, y)/float(samples)))/iResolution.xy);
  p.x *= iResolution.x/iResolution.y;  
  float r = texelFetch(iChannel0, ivec2(mod(fragCoord*float(samples)+vec2(x,y),1024.)),0).r;
  T = ot+(tm*r)/46.0;
 };
     
*/
vec2 m = iMouse.xy/iResolution.xy;

vec3 eye = 1.0*vec3(0.,0.,6.5);
       float the = -(iTime*.35);
        eye.xz *= -mat2(cos(the), -sin(the), sin(the), cos(the));

vec3 col;
vec2 d;
vec3 hoek = vec3(0,-0.,0.);  
//float   the = (iTime*1.);
mat3 camera = setCamera( eye, hoek,0.);
float fov = .8;
vec3 dir = camera * normalize(vec3(uv, fov));

    
    
vec3 p;
vec3 n;
vec3 focalPoint = eye + (dir * 1.);
 
 
      
    
vec3 shiftedRayOrigin = eye;
      
       
      
      
vec3 shiftedRay = (focalPoint - shiftedRayOrigin);
 d = RayMarch(shiftedRayOrigin, shiftedRay);
float t =d.x *1.;
vec3  shiftedRayOrigin2 = shiftedRayOrigin;
      
vec3  shiftedRay2= shiftedRay;
if(t<MAX_DIST) {
    
 shiftedRayOrigin2 += shiftedRay2 * t;
 vec3 sn = GetNormal(shiftedRayOrigin2);
    
//        if(d.y==5.) col+= vec3(1.,3,2);

 shiftedRay2 = reflect(shiftedRay2, sn);
 if(d.y==3.) traceRef(shiftedRayOrigin2 +  shiftedRay2*.9, shiftedRay2);
  if(d.y==5.) traceRef(shiftedRayOrigin2 +  shiftedRay2*.9, shiftedRay2);
  if(d.y==7.) traceRef(shiftedRayOrigin2 +  shiftedRay2*.9, shiftedRay2);
    //if(d.y==7.) col*= vec3(.25,.3,2.);

    if(d.y==5.) col+= vec3(1.,3,2);
        if(d.y==7.) col+= vec3(2.,3,2);

    //sn *= GetNormal(shiftedRayOrigin2);   
 //if(d.y==3.) col *= sn;

 p = shiftedRayOrigin + shiftedRay * t;
    
  n= GetNormal(p.xyz);
 float a = ambientOcclusion(p,n, 5.5,5.);

 vec3 lp =    spherepos*1.;
 const int numIter = 60;
 vec3 vD = shiftedRay;
 vD = normalize(vD);
    
    
 float stepSize = length(p - shiftedRayOrigin) / float(numIter);
 vec3 vO = shiftedRayOrigin + stepSize * vD;
 float accum = 0.0;

 for(int i = 0; i  < numIter; ++i)
  {
	vec3 ld = normalize(lp - vO);
	float shad = shadow(vO, ld, 5.);
	float d = dot(vO, vO);
	accum += (.001 / d ) * shad;
	vO += stepSize * vD;
   }
col*= a+0.; 
 vec3   color= vec3(1., 1., 1.);
 col +=g2*vec3(0.05)*vec3(.2,.5,.6)*5.;    
 col +=g4*vec3(0.03)*vec3(1.,.6,0.6)*.9;    
 col +=g8*vec3(5.)*vec3(1.,.4,0.0)*1.; 
 col *= marchCount * vec3(.4, .4,0.4) * 0.0007;
 float dif = GetLight(p);
 col *= vec3(dif)+2.;
 vec3 sky = vec3(5.9, 3., 10.);
 col *= mix(sky, col, 1./(t*t/1./3.*.1+1.5));   
 col += g3 * color;
 col *= accum * color *3.;
 }    
 col*=1.;
 col=smoothstep(0.0,1.,col);
 col=pow(col, vec3(0.4545));
 fragColor = vec4(col,t);
}