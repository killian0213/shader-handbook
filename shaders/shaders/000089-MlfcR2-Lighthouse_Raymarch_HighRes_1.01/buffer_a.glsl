// Buf A (buffer) — Lighthouse Raymarch HighRes 1.01 by ingagard
// https://www.shadertoy.com/view/MlfcR2

//////////////////////////////////////////////////////////////////////////////////////
///////////////////// CREATED BY KIM BERKEBY, SEP 2017 ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
////////////////////// SPECIAL THANKS TO Inigo Quilez  ///////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
//////////////// Feel free to mail me at mr.kimb@hotmail.com /////////////////////////
//////////////////////////////////////////////////////////////////////////////////////
#define WATER_LOD 0.27
#define PI 3.14159265
  #define TAU (2.*PI)
  #define PHI (sqrt(5.)*0.5 + 0.5)
  #define M_NONE -1.0
  #define M_NOISE 1.0
  #pragma optimize(off) 
  const vec3 sunPos = normalize(vec3(5.3, 2.7, -1.));
const vec3 sunColor = vec3(0.80, 0.7, 0.55);         
const vec3 eps = vec3(0.02, 0.0, 0.0);
float steelDist=100000.0;
float terrainDist=100000.0;
float platformDist=100000.0;
float waterDist=100000.0;

struct RayHit
{
  bool hit;  
  vec3 hitPos;
  vec3 normal;
  float dist;
  float depth;
  float steelDist;
  float terrainDist;
  float platformDist;
  float waterDist;
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
float noise2D( in vec2 pos , float lod)
{
  vec2 f = fract(pos);
  f = f*f*(3.0-2.0*f);
  vec2 rg = textureLod( iChannel1, (((floor(pos).xy+vec2(37.0, 17.0)) + f.xy)+ 0.5)/256.0, lod).yx;  
  return -1.0+2.0*mix( rg.x, rg.y, 0.5 );
}
float noise2D( in vec2 pos )
{
return noise2D(pos,0.0);
}

vec3 calcWaterNormal( vec2 pos, float res )
{   
  return normalize(vec3(noise2D((pos + vec2(-0.001, 0))* res,WATER_LOD)-noise2D((pos + vec2(+0.001, 0))* res,WATER_LOD), noise2D((pos + vec2(0, -0.001))*res,WATER_LOD)-noise2D((pos + vec2(0, +0.001))* res,WATER_LOD), .005)) * 0.5 + 0.5;
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


float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz), p.y)) - h;
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
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

float fHexagonCircumcircle(vec3 p, vec2 h) {
  vec3 q = abs(p);
  return max(q.y - h.y, max(q.x*sqrt(3.)*0.5 + q.z*0.5, q.z) - h.x);
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

vec2 pModPolar(vec2 p, float repetitions) {
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


float MapTerrain( vec3 p)
{
  return   p.y+18.5-mix(
    (textureLod(iChannel0, p.xz*0.001, 0.0).r*1.2) + 
    (textureLod(iChannel0, p.xz*0.01, 0.0).r*.7) + 
    (textureLod(iChannel0, p.xz*0.075, 0.0).r*0.91), 
    0., smoothstep(8.0, 18.0, min(distance(p, vec3(0.0, -17.3, 0.)), distance(p, vec3(10.5, -17.3, 2.))*3.5)));
}

float MapStreeLight(vec3 p)
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


const float radius =1.6;
const float outRad = 1.82;
const float inRad = 1.12;
vec3 checkPos;

float Map(vec3 p)
{
  float  d=100000.0;
  checkPos = p;
  steelDist=platformDist=waterDist=terrainDist=100000.0;

  d=min(d, sdCappedCylinder(p-vec3(0.0, 3.7, 0), vec2(inRad, .45)));
  d=min(d, sdSphere(p-vec3(0., 4., 0), 0.50));
  d=min(d, fCylinderH(p-vec3(0.0, 1.3, 0), radius, 1.80));
  d=min(d, sdConeSection(p-vec3(0.0, -6.0, 0.), 5.3, 2.4, 1.7));
  d=min(d, sdConeSection(p-vec3(0.0, -13.0, 0.), 1.8, 2.8, 2.6));
    
  if(sdCappedCylinder(p-vec3(0.0, -19.0, 0), vec2(22.0, 7.))<10.0)
  {
  // platform 
  platformDist = fHexagonCircumcircle(p-vec3(0.0, -16.05, 0), vec2(radius+8.2, 1.4));  
  platformDist=fOpUnionChamfer(platformDist, fHexagonCircumcircle(p-vec3(0.0, -15.05, 0), vec2(radius+8.7, 0.15)), 0.25);  

  checkPos.xz = pModPolar(p.xz, 12.0);   
  platformDist= min(platformDist, fHexagonCircumcircle(p-vec3(0.0, -16.42, 0), vec2(radius+8.3, 0.2)));  
  platformDist=fOpIntersectionChamfer(platformDist, -sdBox(checkPos-vec3(radius+8.8, -16.55, 0.), vec3(1.0, 1., 1.8)), 0.1); 
  platformDist=fOpIntersectionChamfer(platformDist, -sdCappedCylinder(p-vec3(0., -14.4, 0), vec2(radius+7.4, .25)), 0.5);   

  // railing (platform) 
  checkPos.xz = pModPolar(p.xz, 32.0);   
  steelDist=min(steelDist, sdCappedCylinder(checkPos-vec3(radius+8., -14.4, 0), vec2(0.05, .46)));   
  steelDist=min(steelDist, sdTorus(p-vec3(0., -14.2, 0), vec2(radius+8., 0.02)));
  steelDist=min(steelDist, sdTorus(p-vec3(0., -14.35, 0), vec2(radius+8., 0.02)));
  steelDist=min(steelDist, sdTorus(p-vec3(0., -13.9, 0), vec2(radius+8., 0.04)));

  checkPos.xz = pModPolar(p.xz, 7.0); 
  steelDist = min(steelDist, MapStreeLight(checkPos-vec3(radius+6.7, -6.63, 0)));  
  steelDist=max(steelDist, -sdBox(p-vec3(13.3, 0., 0.), vec3(6.6, 22.5, 3.7)));      
  platformDist=max(platformDist, -sdBox(p-vec3(13.3, -12.5, 0.), vec3(4.6, 12.5, 3.5)));   
       
  terrainDist = MapTerrain(p);
  }
  
  checkPos = p-vec3(11.70, -15.8, 0); 
    
  pModSingle1(checkPos.x, 6.); 
  if(sdBox(checkPos-vec3(0,-1.0, 0), vec3(3.6, 2.3, 4.))<6.0)
  {
  float bridge = sdBox(checkPos-vec3(0, 0.8, 0), vec3(3.0, 0.1, 3.6)); 
  bridge=fOpUnionChamfer(bridge, sdBox(checkPos+vec3(0, 1., 0), vec3(3.0, 1.9, 3.3)), 0.15);   
  bridge=fOpIntersectionChamfer(bridge, -sdBox(checkPos-vec3(0, 0.9, 0), vec3(6.0, 0.2, 3.3)), 0.10); 
  bridge=min(fOpPipe(bridge, -fCylinder(checkPos+vec3(0, 2.65, 0), 3., 4.6), 0.15), max(bridge, -fCylinder(checkPos+vec3(0, 2.65, 0), 3., 4.6)));
  platformDist = min(platformDist, bridge);

    
  // railing (bridge)
  checkPos = p-vec3(9.50, -14.42, 0.); 
  pModSingle1(checkPos.x, 2.); 
  steelDist=min(steelDist, sdCappedCylinder(checkPos-vec3(0, 0, 3.5), vec2(0.05, .45)));              
  steelDist=min(steelDist, fCylinderV(p-vec3(39.0, -14.4, 3.5), 0.02, 29.45));  
  steelDist=min(steelDist, fCylinderV(p-vec3(39.0, -14.55, 3.5), 0.02, 29.45));  
  steelDist=min(steelDist, fCylinderV(p-vec3(38.90, -13.95, 3.5), 0.04, 29.45));  

  steelDist=min(steelDist, sdCappedCylinder(checkPos-vec3(0, 0, -3.5), vec2(0.05, .45)));                    
  steelDist=min(steelDist, fCylinderV(p-vec3(39.0, -14.4, -3.5), 0.02, 29.45));  
  steelDist=min(steelDist, fCylinderV(p-vec3(39.0, -14.55, -3.5), 0.02, 29.45));  
  steelDist=min(steelDist, fCylinderV(p-vec3(38.90, -13.95, -3.5), 0.04, 29.45));  
  }

 
  waterDist = p.y+17.5;

  return  min(d, min(waterDist, min(terrainDist, min(platformDist, steelDist))));
}


vec3 calcNormal(  vec3 pos )
{    
  return normalize( vec3(Map(pos+eps.xyy) - Map(pos-eps.xyy), 0.5*2.0*eps.x, Map(pos+eps.yyx) - Map(pos-eps.yyx) ) );
}
vec3 calcTexNormal(in sampler2D sam, in vec2 pos )
{    
  return normalize(vec3(textureLod(sam, pos + vec2(-0.001, 0),0.0).r-textureLod(sam, pos + vec2(+0.001, 0),0.0).r, textureLod(sam, pos + vec2(0, -0.001),0.0).r-textureLod(sam, pos + vec2(0, +0.001),0.0).r, .03)) * 0.5 + 0.5;
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


RayHit MarchReflection( vec3 origin,  vec3 direction)
{
  RayHit result;
  float maxDist = 90.0;
  float t = 0.0, dist = 0.0;
  vec3 rayPos;
 
  for ( int i=0; i<32; i++ )
  {
    rayPos =origin+direction*t;
    dist = Map( rayPos);
 

    if (abs(dist)<0.05 || t>maxDist )
    {             
      result.hit=!(t>maxDist);
      result.depth = t; 
      result.dist = dist;                              
      result.hitPos = origin+((direction*t));   
      result.steelDist = steelDist;
      result.platformDist = platformDist;
      result.terrainDist =terrainDist;
      result.waterDist =waterDist;
      break;
    }
    t += dist;
  }

  return result;
}

RayHit March( vec3 origin,  vec3 direction)
{
  RayHit result;
  float maxDist = 380.0;
  float t = 0.0, dist = 0.0;
  vec3 rayPos;
 
  for ( int i=0; i<200; i++ )
  {
    rayPos =origin+direction*t;
    dist = Map( rayPos);
 

    if (dist<0.01 || t>maxDist )
    {             
      result.hit=!(t>maxDist);
      result.depth = t; 
      result.dist = dist;                              
      result.hitPos = origin+((direction*t));   
      result.steelDist = steelDist;
      result.platformDist = platformDist;
      result.terrainDist =terrainDist;
      result.waterDist =waterDist;
      break;
    }
    t += dist;
  }

  return result;
}


vec4 CubeMap( sampler2D sam,  vec3 hitPos,  vec3 n,  float k)
{ 
    vec3 m = pow( abs( n ), vec3(k) );
	vec4 x = textureLod( sam, hitPos.yz,2. );
	vec4 y = textureLod( sam, hitPos.zx, 2. );
	vec4 z = textureLod( sam, hitPos.xy, 2. );
	return (x*m.x + y*m.y + z*m.z) / (m.x + m.y + m.z);
}
mat3 setCamera(  vec3 ro,  vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}


vec3 GetSkyColor( vec2 screenSpace,  vec3 rayDir,  vec3 rayOrigin)
{

  vec3 skyColor = mix(vec3(0.6, 0.7, 0.8), vec3(0.9), smoothstep(1.0, -.0, screenSpace.y)); 
  skyColor =  mix(skyColor, vec3(0.6, 0.7, 0.8), smoothstep(-0., -1., screenSpace.y*1.1));
  float sun = clamp( dot(sunPos, rayDir), 0.0, 1.0 );
  skyColor += vec3(.9, 0.4, 0.2)*sun*sun*clamp((rayDir.y+0.4)/0.4, 0.0, 1.0);

  float cloudScale = (200.0-rayOrigin.y)/abs(rayDir.y);
    if(cloudScale>0.05)
    {
  vec2 cloudUV = ((rayOrigin+cloudScale*rayDir).xz+ vec2(iTime*12.4, iTime*7.2))*.00009;
  vec3  cloudNormal = calcTexNormal(iChannel2, cloudUV);
  float cloudShade = clamp( dot( cloudNormal, sunPos ), 0.0, .6 );
  skyColor = mix(skyColor,mix( skyColor, vec3(1.)*cloudShade, pow(texture( iChannel2, cloudUV).x, 3.)),smoothstep(0. ,0.2, abs(distance(0.,rayDir.y))));
            }
    return skyColor;
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
  vec3 shadowPos = origin+((rayDir*rayHit.depth)*0.98);  
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
  
  // steel 
  if (rayHit.steelDist==rayHit.dist)
  {
    vec3 dirt =  CubeMap(iChannel3, (rayHit.hitPos*.44), rayHit.normal, 4.0).rgb*1.5; 
    col = vec3(0.3+(fbm(rayHit.hitPos*1.71)*.5));
    col = mix(col, dirt*0.7, fbm(rayHit.hitPos*10.71));         
    specLevel = 6.0;
  }
  //stones and terrain 
  else if (rayHit.terrainDist==rayHit.dist)
  {
    vec3 moss =  CubeMap(iChannel3, rayHit.hitPos*0.22, rayHit.normal, 4.0).rgb*vec3(0.356, 0.455, 0.228);
    col  =  CubeMap(iChannel3, (rayHit.hitPos*.44), rayHit.normal, 4.0).rgb; 
    col = mix( col, vec3(0.7), reflect( rayDir, rayHit.normal ).x);
    col = mix(col, moss, smoothstep(-16.5, -18., rayHit.hitPos.y));
    specLevel = .90;
  } 

  // platform and bridge  
  else if (rayHit.platformDist==rayHit.dist)
  {
    
    vec3 dirt =  vec3(fbm(rayHit.hitPos*.41)); 
    vec3 dirt2 =  CubeMap(iChannel3, rayHit.hitPos*0.07, rayHit.normal, 4.0).rgb;  
    vec3 dirt3 =  CubeMap(iChannel3, rayHit.hitPos*.002, rayHit.normal, 4.0).rgb;            
    vec3 bNormal = calcNoiseNormal(rayHit.hitPos*15.)*0.55;
    col = mix(mix(dirt2, dirt, 0.3), dirt3, 0.5);
    col = mix(col, vec3(fbm(rayHit.hitPos*2.3)*0.3), smoothstep(-15.5, -18.01, rayHit.hitPos.y));          
    specLevel=col.r*fbm(rayHit.hitPos*20.);       
    rayHit.normal = mix(rayHit.normal, (rayHit.normal+bNormal)*0.5, 0.15);
  
  } 

  return vec4(col, specLevel);
}

void mainImage( out vec4 fragColor,  vec2 fragCoord )
{  
  vec2 mo = iMouse.xy/iResolution.xy;
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;

  float camrot = 20.0+(iTime*0.2);
  if (iMouse.w>0.1) camrot+=mo.x*16.; 

  vec3 rayOrigin = vec3(8.*cos(camrot), 1.+12.*sin(camrot*1.8), 13.5 + 24.0*sin(camrot) );
  mat3 ca = setCamera( rayOrigin, vec3(0., -6., 0.5 ), 0.0 );
  vec3 rayDir = ca * normalize( vec3(screenSpace.xy, 2.0) );

  vec3 skyColor = GetSkyColor(screenSpace, rayDir, rayOrigin);
  vec3 color = skyColor;

  RayHit marchResult = March(rayOrigin, rayDir);

  if (marchResult.hit)
  {
    marchResult.normal = calcNormal(marchResult.hitPos);  

    vec4 col;

    // water
    if (marchResult.waterDist==marchResult.dist)
    {       
      col = vec4(skyColor*0.35, 12.90); 
      vec3 waterNormal = ((calcWaterNormal(marchResult.hitPos.xz + vec2(-iTime*0.4, -iTime*0.2), 1.66))*(calcWaterNormal(marchResult.hitPos.xz + vec2(iTime*0.4, iTime*0.2), 3.61)));      
    marchResult.normal = (vec3(0.0, 1.0, 0.0)+waterNormal)*0.4;

        
      vec3 ref = normalize(reflect(rayDir, marchResult.normal));
      RayHit reflectResult = MarchReflection(marchResult.hitPos + (ref*0.002), ref); 

      // draw reflected objects and mix with water color
      if (reflectResult.hit==true)
      {   
          // advanced reflections

         //  reflectResult.normal = calcNormal(reflectResult.hitPos); 
          // col.rgb = mix(col.rgb, GetMaterial(ref, reflectResult).rgb, 0.5);
    
          // fake reflections
          col.rgb = mix(col.rgb, vec3(0.5).rgb, 0.5);
     
      }
      marchResult.normal=(vec3(0.0, 1.0, 0.0)+waterNormal)*0.5;
    }
    // above water level
    else
    {
      col = GetMaterial(rayDir, marchResult);
    }

    // get lightning based on material
    vec3 light = GetSceneLight(col.a, marchResult.normal, marchResult, rayDir, rayOrigin);   

    // apply lightning
    color = col.rgb*light;
        color = mix(color, skyColor, smoothstep(100., 200., marchResult.depth));  

  }


  float sun = clamp( dot(sunPos, rayDir), 0.0, 1.0 );  
  color += vec3(.9, 0.4, 0.2)*sun*sun*clamp((rayDir.y+0.4)/0.4, 0.0, 0.4);

  fragColor = vec4(pow(color.rgb, vec3(1.0/0.9)), 1.0 ) * (0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.2 ));
}
