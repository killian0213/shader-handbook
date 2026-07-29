// Buf C (buffer) — [Planet] Outer Space by ingagard
// https://www.shadertoy.com/view/4llBD8

//////////////////////////////////////////////////////////////////////////////////////
// PLANET BUFFER -   RENDERS PLANETS, RING AND SPACE-CLOUDS
//////////////////////////////////////////////////////////////////////////////////////

#define readRGB(memPos) (  texelFetch(iChannel2, memPos, 0).rgb)
  #define PI 3.14159265359
  #define PI_TWO 6.28318530718
  //#pragma optimize(off) 

  // Delete on or several of below defines to increase performance
  #define CLOUDS
  #define QUALITY_CLOUDS
  #define SHADOWS
  #define ROTATING_MOON
  #define ROTATING_PLANET
  #define SPACE_CLOUDS
  #define HIGH_QUALITY_BELT

  //enable for full experience (can crash some machines)
  //#define HIGH_QUALITY


  float hash(float h)
{
  return fract(sin(h) * 43758.5453123);
} 

struct RayHit
{
  bool hit;  
  vec3 hitPos;
  vec3 normal;
  vec4 dist;
  float depth;
};

vec3 sunPos=vec3(0.);

vec2 PosToSphere(vec3 pos)
{
  float x = atan(pos.z, pos.x); 
  float y = acos(pos.y / length(pos)); 
  return vec2( x / (2.0 * PI), y / PI);
}

// by afl_ext (achlubek)
//*****************************************************************
float oct(vec3 p) {
  return fract(4768.1232345456 * sin((p.x+p.y*43.0+p.z*137.0)));
}
float oct(vec2 p) {
  return fract(4768.1232345456 * sin((p.x+p.y*43.0)));
}

float noise2D(vec2 x) {
  vec2 p = floor(x);
  vec2 fr = fract(x);
  vec2 LB = p;
  vec2 LT = p + vec2(0.0, 1.0);
  vec2 RB = p + vec2(1.0, 0.0);
  vec2 RT = p + vec2(1.0, 1.0);

  float LBo = oct(LB);
  float RBo = oct(RB);
  float LTo = oct(LT);
  float RTo = oct(RT);

  float noise1d1 = mix(LBo, RBo, fr.x);
  float noise1d2 = mix(LTo, RTo, fr.x);

  float noise2d = mix(noise1d1, noise1d2, fr.y);

  return -1.0+2.0*noise2d;
}

float noise(vec3 x) { 
  vec3 p = floor(x);
  vec3 fr = fract(x);
  vec3 LBZ = p + vec3(0.0, 0.0, 0.0);
  vec3 LTZ = p + vec3(0.0, 1.0, 0.0);
  vec3 RBZ = p + vec3(1.0, 0.0, 0.0);
  vec3 RTZ = p + vec3(1.0, 1.0, 0.0);

  vec3 LBF = p + vec3(0.0, 0.0, 1.0);
  vec3 LTF = p + vec3(0.0, 1.0, 1.0);
  vec3 RBF = p + vec3(1.0, 0.0, 1.0);
  vec3 RTF = p + vec3(1.0, 1.0, 1.0);

  float l0candidate1 = oct(LBZ);
  float l0candidate2 = oct(RBZ);
  float l0candidate3 = oct(LTZ);
  float l0candidate4 = oct(RTZ);

  float l0candidate5 = oct(LBF);
  float l0candidate6 = oct(RBF);
  float l0candidate7 = oct(LTF);
  float l0candidate8 = oct(RTF);

  float l1candidate1 = mix(l0candidate1, l0candidate2, fr[0]);
  float l1candidate2 = mix(l0candidate3, l0candidate4, fr[0]);
  float l1candidate3 = mix(l0candidate5, l0candidate6, fr[0]);
  float l1candidate4 = mix(l0candidate7, l0candidate8, fr[0]);


  float l2candidate1 = mix(l1candidate1, l1candidate2, fr[1]);
  float l2candidate2 = mix(l1candidate3, l1candidate4, fr[1]);


  float l3candidate1 = mix(l2candidate1, l2candidate2, fr[2]);

  return -1.0+2.0*l3candidate1;
} 
//*****************************************************************
// by IQ
//*****************************************************************

float fastFBM(vec3 p)
{
  vec3 ip=floor(p);
  p-=ip; 
  vec3 s=vec3(7, 157, 113);
  vec4 h=vec4(0., s.yz, s.y+s.z)+dot(ip, s);
  p=p*p*(3.-2.*p); 
  h=mix(fract(sin(h)*43758.5), fract(sin(h+s.x)*43758.5), p.x);
  h.xy=mix(h.xz, h.yw, p.y);
  return mix(h.x, h.y, p.z);
}

//*****************************************************************


#define pR(p, a) (p)*=r2(a)
  mat2 r2(float r) {
  float c=cos(r), s=sin(r);
  return mat2(c, s, -s, c);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
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

float pModInterval1(inout float p, float size, float start, float stop)
{
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



vec4 TraceSpaceClouds( vec3 origin, vec3 direction, int steps)
{
  vec4 col = vec4(.7, 0.7, 1., 0.);

  float precis = 0.0, t = 0.0;
  vec3 rayPos = vec3(0.);
  vec3 texPos = vec3(0.);
  float density=0.;

  for ( int i=0; i<steps+min(0, iFrame); i++ )
  {
    rayPos =origin+direction*t; 

    if (sdSphere(rayPos, 70.)<0.01) break;

    vec3 texPos = (rayPos+vec3(iTime*27.3, iTime*2.3, -iTime*13.3));

    density = pow(fastFBM(texPos*0.002), 4.);
    density *= pow(fastFBM(texPos*0.007 ), 6.);
    density *= pow(fastFBM(texPos*0.05), 1.);

    if (density>0.0)
    {        
      col.a+=(1.-col.a)*density;
    }

    if (col.a>0.999) break;

    t+=9.;
  }
  return col;
}



float MapRing(vec3 p, float inRadius, float outRadius, float height)
{
  pR(p.xy, 0.15);
  return max(sdCappedCylinder(p, vec2(outRadius, height)), -sdCappedCylinder(p, vec2(inRadius, 15.)));
}

vec4 GetRingHitPos( vec3 origin, vec3 direction)
{
  float dist = 1000000.;
  float precis = 0.0, t = 0.0;
  vec3 rayPos = vec3(0.);
  for ( int i=0; i<48+min(0, iFrame); i++ )
  {
    rayPos =origin+direction*t; 
    dist = MapRing( rayPos, 110., 155., 5.);
    precis =0.01*t;
    if (dist<precis || t>500.)
    {       
      break;
    }
    t+=dist;
  }

  return vec4(rayPos, dist);
}

vec4 TraceRing( vec3 origin, vec3 direction, int steps, float scale, float densLimit, float rotSpeed, float inRad, float outRad)
{
  vec4 ringColor = vec4(0.12, 0.12, 0.17, 0.);
  float dist = 1000000.;
  float precis = 0.0, t = 0.0, density=0., densAdd=0., sunDensity=0.;
  vec3 rayPos = vec3(0.);
  vec3 texPos = vec3(0.);
    float planetDist=10000.;
  for ( int i=0; i<steps+min(0, iFrame); i++ )
  {
    rayPos =origin+direction*t; 
    rayPos.y+=cos((rayPos.x+rayPos.z)*0.23)*.25;

    dist = MapRing( rayPos, inRad, outRad, 3.4);
    precis =0.001*t;
    planetDist = sdSphere(rayPos, 70.);
    dist = min(dist,planetDist);
      
    if (dist!=planetDist)
    {

    texPos = rayPos;
    pR(texPos.xz, -iTime*rotSpeed);
    density = pow((fastFBM(texPos*scale)), 8.);

    if (dist<precis && density>densLimit)
    {       
      densAdd = 0.35;
      sunDensity = pow(fastFBM((texPos+sunPos*.7)*scale), 8.); 
      ringColor.rgb += max(0., density-sunDensity)*(1.-ringColor.a)*densAdd*0.8;
      ringColor.a+=(1.-ringColor.a)*densAdd*0.5;
    }
    }
    if (ringColor.a>0.999) break;

    t+=max(.04, dist);
  }
  return ringColor;
}

#define calcNormal( pos ) normalize( vec3(MapPlanet(pos+vec3(0.02, 0.0, 0.0).xyy).x - MapPlanet(pos-vec3(0.02, 0.0, 0.0).xyy).x, 0.5*2.0*0.02, MapPlanet(pos+vec3(0.02, 0.0, 0.0).yyx).x - MapPlanet(pos-vec3(0.02, 0.0, 0.0).yyx).x ) )
  #define calcNormalRocks( pos ) normalize( vec3(MapRocks(pos+vec3(0.02, 0.0, 0.0).xyy) - MapRocks(pos-vec3(0.02, 0.0, 0.0).xyy), 0.5*2.0*0.02, MapRocks(pos+vec3(0.02, 0.0, 0.0).yyx) - MapRocks(pos-vec3(0.02, 0.0, 0.0).yyx) ) )
  #define calcNormalGlobe( pos ) normalize( vec3(sdSphere(pos+vec3(0.02, 0.0, 0.0).xyy, 70.) - sdSphere(pos-vec3(0.02, 0.0, 0.0).xyy, 70.), 0.5*2.0*0.02, sdSphere(pos+vec3(0.02, 0.0, 0.0).yyx, 70.) - sdSphere(pos-vec3(0.02, 0.0, 0.0).yyx, 70.) ) )

  RayHit GetDistancePlanet( vec3 origin, vec3 direction, int steps, float maxDist, inout vec3 hitPos)
{
  RayHit result;
  float dist = 1000000.;
  float precis = 0.0, t = 0.0;
  vec3 rayPos;

  for ( int i=0; i<steps+min(0, iFrame); i++ )
  {
    rayPos =origin+direction*t; 
    hitPos = rayPos;
    dist = min(dist, sdSphere(rayPos, 70.));
    t += dist;
  }

  result.hit=(dist<1.);
  result.depth = t; 
  result.dist.x = dist;  
  result.hitPos = origin+((direction*t)); 

  return result;
}

float GetTerrainHeight( vec3 p)
{   
  p*=0.0032;

  float terrainHeight =fastFBM(p)*14.; 
  p*=3.0;      
  pR(p.xz, 3.14);
  terrainHeight -= fastFBM(p)*10.2;
  p*=3.0;      
  pR(p.xz, 3.14);   
  terrainHeight -= fastFBM(p)*5.2;
  p*=3.0;      
  pR(p.xz, 3.14);
  return terrainHeight - (fastFBM(p)*1.5);
}

void GetPlanetRotation(inout vec3 p)
{
  #ifdef ROTATING_PLANET
    pR(p.xz, (0.08*-iTime));
  #endif
}
void GetMoonRotation(inout vec3 p)
{
  #ifdef ROTATING_MOON
    pR(p.xz, 2.65-(0.005*-iTime)); 
  #else
    pR(p.xz, 2.65);
  #endif
}

vec3 GetMoonPosition(vec3 p)
{
  vec3 pos = vec3(-430., 180., -430);
  GetMoonRotation(pos);
  return pos;
}


vec4 MapPlanet(vec3 p)
{
  vec3 moonPos = p-GetMoonPosition(p);
  vec2 mapPos = PosToSphere(moonPos);
  float heightMap = -fastFBM((moonPos*0.5)*.4);
  float moon = sdSphere(moonPos, 40.+heightMap);
  GetPlanetRotation(p);  
  mapPos = PosToSphere(p);
  heightMap = ((GetTerrainHeight(8.*p)*0.35))*textureLod(iChannel3, 2.*mapPos, log2(mapPos.y*2.)).z*1.5;
  return vec4(min(moon, sdSphere(p, 70.-min(2., (1.-heightMap)))), heightMap, moon, 0.);
}

RayHit TracePlanet( vec3 origin, vec3 direction, int steps, float maxDist)
{
  RayHit result;
  vec4 dist = vec4(1000000.);
  float precis = 0.0, t = 0.0;
  vec3 rayPos;

  for ( int i=0; i<steps+min(0, iFrame); i++ )
  {
    rayPos =origin+direction*t; 
    dist = MapPlanet( rayPos);
    precis =0.00001*t;

    if (dist.x<precis || t>maxDist)
    {             
      result.hit=!(t>maxDist);
      result.depth = t; 
      result.dist = dist;  
      result.hitPos = origin+((direction*t));    
      break;
    }

    t += dist.x*0.55;
  }

  return result;
}


void GetRockRotation(inout vec3 p)
{
  pR(p.xy, 0.15); 
  pR(p.xz, -iTime*0.052);
}

float MapRocks(vec3 p)
{
  GetRockRotation(p);
  vec3 checkPos = p;
  checkPos.xz = pModPolar(checkPos.xz, 230.0);
  checkPos-=vec3(124, 0., 0.);
  pModInterval1(checkPos.x, 6., 0., 4.);
  return sdSphere(checkPos, pow(0.5+noise(p*0.44), 2.)*1.5);
}

RayHit TraceRocks( vec3 origin, vec3 direction, int steps, float maxDist)
{
  RayHit result;
  float dist = 1000000.;
  float precis = 0.0, t = 0.0;
  vec3 rayPos;

  for ( int i=0; i<steps+min(0, iFrame); i++ )
  {
    rayPos =origin+direction*t; 
    rayPos.y+=cos((rayPos.x+rayPos.z)*0.23)*.5;
    dist = MapRocks( rayPos);
    float planetDist = sdSphere(rayPos, 70.) ;
    dist=min(dist, planetDist);

    if (dist!=planetDist) 
    {
      precis =0.001*t;

      if (dist<precis || t>maxDist)
      {             
        result.hit=!(t>maxDist);
        result.depth = t; 
        result.dist.x = dist;  
        result.hitPos = origin+((direction*t));    
        break;
      }
    }

    t += dist*0.6;
  }

  return result;
}


float GetCloudDensitySimple(vec3 p)
{
      vec2 cloudPos = vec2(iTime*.036, 0.006*iTime);
      vec2 cPos = PosToSphere(p);

      vec3 clouds1 = textureLod(iChannel1, (cPos+cloudPos), 4.0*log2(cPos.y*2.)).rrr+0.25;
      cPos = PosToSphere(p-vec3(10., 10, 10));
      vec3 clouds2 = textureLod(iChannel1, (cPos+(0.55*cloudPos)), 4.0*log2(cPos.y*2.)).rgb;

     return pow(clouds1.r*clouds2.g, 2.);
}

#define calcNormalClouds( pos ) normalize( vec3(GetCloudDensitySimple(pos+vec3(0.02, 0.0, 0.0).xyy) - GetCloudDensitySimple(pos-vec3(0.02, 0.0, 0.0).xyy), 0.5*2.0*0.02, GetCloudDensitySimple(pos+vec3(0.02, 0.0, 0.0).yyx) - GetCloudDensitySimple(pos-vec3(0.02, 0.0, 0.0).yyx) ) )
 

vec4 TraceClouds( vec3 origin, vec3 direction, vec3 skyColor, int steps)
{ 
  vec4 cloudCol=vec4(.52, 0.31, 0.31, 0.);
  float density = 0.0, t = .0;
  vec3 rayPos = vec3(0.);
  float densAdd=0.;
  float sunDensity=0.;

  for ( int i=0; i<steps; i++ )
  {
    rayPos = origin+direction*t;
    density = GetCloudDensitySimple(rayPos);          

    if (density>0.001)
    {    
      densAdd = density*0.35;
      sunDensity = GetCloudDensitySimple(rayPos+(sunPos*3.));          
      cloudCol.rgb += max(0., density-sunDensity)*densAdd;
      cloudCol.a+=(1.-cloudCol.a)*densAdd*0.4;
    }
    if (cloudCol.a > 0.99) break; 

    t+=.25;
  }

  cloudCol.a = clamp(cloudCol.a, 0., 1.);
  return cloudCol;
}


mat3 setCamera(  vec3 ro, vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}
float SoftShadowRing( in vec3 origin, in vec3 direction )
{
  float res =1., t = 0.0, h=0.;
  vec3 rayPos = vec3(origin+direction*t);    

    for ( int i=0; i<10+min(0, iFrame); i++ )
    {
      h = MapPlanet(rayPos).x;
      res = min( res, 8.5*h/t );
      t += clamp( h, 0.01, 100.1);
      if ( h<0.005 ) break;
      rayPos = vec3(origin+direction*t);
    }
  return clamp( res, 0.0, 1.0 );
}


float SoftShadow( in vec3 origin, in vec3 direction )
{
  float res =1., t = 0.0, h=0.;
  vec3 rayPos = vec3(origin+direction*t);    
  #ifdef HIGH_QUALITY
    for ( int i=0; i<30+min(0, iFrame); i++ )
  {
    h = MapPlanet(rayPos).x;
    #ifdef HIGH_QUALITY_BELT
    h = min(h, MapRocks(rayPos));
    #endif
      
    res = min( res, 3.5*h/t );
    t += clamp( h, 0.01, 250.1);
    if ( h<0.005 ) break;
    rayPos = vec3(origin+direction*t);
  }
  #else
    for ( int i=0; i<10+min(0, iFrame); i++ )
    {
      h = MapPlanet(rayPos).x;
      res = min( res, 8.5*h/t );
      t += clamp( h, 0.01, 100.1);
      if ( h<0.005 ) break;
      rayPos = vec3(origin+direction*t);
    }
  #endif


    return clamp( res, 0.0, 1.0 );
}


vec3 GetLight(float specLevel, vec3 normal, RayHit rayHit, vec3 rayDir, vec3 origin, float illuminance)
{                
  vec3 reflectDir = reflect( rayDir, normal );
  vec3 shadowPos = origin+((rayDir*rayHit.depth)*0.98);

  vec3 lightTot = vec3(0.0);
  float amb = clamp( 0.5+0.5*normal.y, 0.0, 1.0 );
  float dif = clamp( dot( normal, sunPos ), 0.0, 1.0 );
  float dif2 =max(0., dot( normal, normalize(vec3(1.5, 0., -3.5)) ));

  float fre = clamp(1.0+dot(normal, rayDir), 0.0, 1.0);
  specLevel*= pow(clamp( dot( reflectDir, sunPos ), 0.0, 1.0 ), 2.0);
  float skylight = smoothstep( -0.1, 0.1, reflectDir.y );

  float shadow=1.;
  #ifdef SHADOWS
    shadow = SoftShadow(shadowPos, sunPos);
  dif*=shadow;
  #endif

    const vec3 sunColor = vec3(1.1, 1.1, 1.1); 
  lightTot += 2.*dif*sunColor;
  lightTot +=0.5*dif2*vec3(.6, .35, 1.5);
  lightTot += 1.0*amb*vec3(0.2, 0.25, 0.4);  
  lightTot += 0.40*skylight*vec3(0.4, 0.6, 1.0);
  lightTot += 2.*specLevel*vec3(1., 0.85, 0.75)*dif;  
  fre = pow( 1.0-abs(dot(rayHit.normal, rayDir)), 3.0);
  lightTot = mix( lightTot, lightTot*2.5, fre );

  return clamp(lightTot, 0.1, 10.);
}


void mainImage( out vec4 fragColor, vec2 fragCoord )
{  
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;

  sunPos =  readRGB(ivec2(50, 0));

  // setup camera and ray direction
  vec2 camRot = readRGB(ivec2(57, 0)).xy;
  vec3 rayOrigin =readRGB(ivec2(62, 0));
  mat3 ca = setCamera( rayOrigin, vec3(0., 0., 0.), 0.0 );
  vec3 rayDir = ca * normalize( vec3(screenSpace.xy, 2.0) );


  // create sky color fade
  vec4 color = texture(iChannel0, uv);
  color.a=0.;

  vec3 hitPos = vec3(0.);
  RayHit plametDistResult = GetDistancePlanet(rayOrigin, rayDir, 32, 400., hitPos);


  RayHit marchResult = TracePlanet(rayOrigin, rayDir, 200, 1000.);

  // is terrain hit?
  if (marchResult.hit)
  { 

    vec3 col= vec3(0.); 

    // moon hit
    if (length(marchResult.dist.x-marchResult.dist.z)<0.05)
    {
      vec3 pp = marchResult.hitPos;
      GetMoonRotation(pp);

      vec2 texPos = PosToSphere(pp);
      vec4 tex = textureLod(iChannel1, texPos*2., log2(texPos.y*2.));
      col = tex.rgb;
      marchResult.normal = calcNormal(marchResult.hitPos); 
      vec3 light = GetLight(1., marchResult.normal, marchResult, rayDir, rayOrigin, 0.0)*0.35;   
      col = (col*light)+vec3(0.1, 0., 0.1);
    }
    // planet hit
    else
    {
      vec3 pp = marchResult.hitPos;     
      GetPlanetRotation(pp);

      float specLevel = 1.;
      if (marchResult.dist.y>-0.5) // land
      {
        vec2 texPos = PosToSphere(pp);
        vec3 tex = textureLod(iChannel1, 2.*texPos, log2(texPos.y*2.)).rgb;

        col = vec3(1., 0.32, 0.2)*tex;

        col=mix(tex.rgb*vec3(0.9, 0.8, 0.76)*0.3, vec3(.29, 0.1, 0.1)*2.25*(0.6+(tex)), smoothstep(-0.83, -.10, marchResult.dist.y));
        col=mix(col, vec3(.5, 0.3, 0.3), smoothstep(-.10, .39, marchResult.dist.y));
        col*=0.5;
        marchResult.normal = calcNormal(marchResult.hitPos);
      } else   // liqid
      {  
        specLevel=4.;
        col=mix(vec3(0.2, 0., 0.)*0.23, vec3(0.2, 0., 0.)*1.15, smoothstep(-1.615, .15, marchResult.dist.y));

        marchResult.normal = calcNormalGlobe(marchResult.hitPos)+(0.2*fastFBM((pp*6.+vec3(iTime*0.4))));
      } 

      vec3 light = GetLight(specLevel, marchResult.normal, marchResult, rayDir, rayOrigin, 0.0);   
      col = col*light;   

      float sunDot = dot( marchResult.normal, sunPos);

      #ifdef CLOUDS
      plametDistResult.normal = calcNormalGlobe(plametDistResult.hitPos);
      float sunAmount = 0.15+(0.85*max(0., dot( plametDistResult.normal, sunPos )));

      #ifdef QUALITY_CLOUDS
        vec4 cloudColor=TraceClouds(rayOrigin+((rayDir*plametDistResult.depth)*0.97), rayDir, vec3(.3), 30);   
      col.rgb = mix(col.rgb, col+(cloudColor.rgb*sunAmount)*0.5, smoothstep(0.24, 0.37, cloudColor.a*cloudColor.a));
      #endif

     float cloudDensity = GetCloudDensitySimple(plametDistResult.hitPos);
     vec3 cloudNormal = calcNormalClouds(plametDistResult.hitPos);

        float cDif = max(0.,dot(cloudNormal, sunPos));
           col.rgb += mix(0., (0.2+cDif)*max(0., dot( plametDistResult.normal, sunPos )), smoothstep(0.15, 0.45, cloudDensity));   
      #endif

        // add atmosphere
        float fre = 0.5+max(0., (0.5*(1.0+dot(marchResult.normal, rayDir))));
      col= mix(col, vec3(.6, 0.7, .9)*2.5, pow(fre, 6.0)*max(0.62, sunDot));
    }

    color.rgb = col; 
    color.a+=1.;
  } 

  if (!marchResult.hit || length(marchResult.dist.x-marchResult.dist.z)<0.05)
  { 
    vec3 nPos = rayDir;

    color.rgb = mix(vec3(.3, .4, .6), color.rgb, smoothstep(-6., 7., plametDistResult.dist.x));

    color.rgb = mix(mix(color.rgb+vec3(2.), color.rgb, smoothstep(-0., 0.50, plametDistResult.dist.x)), color.rgb, step(1., plametDistResult.dist.x));

    pR(nPos.xy, iTime*0.016);
    pR(nPos.zx, iTime*0.01);
    float atNoise = max(0., noise((nPos*13.)*1.75));

    color.rgb = mix(color.rgb+vec3(.2, 0.45, .642), color.rgb, pow(smoothstep(-2., 20., plametDistResult.dist.x+(22.*atNoise)), .50));
  }


  vec3 background = color.rgb;

  // get distance to ring bounding shape. Only draw content of ring if raytrace hit the ring. VEC4(hitpos.xyz,distance)
  vec4 ringHitPos = GetRingHitPos(rayOrigin, rayDir);

  float shadow =1.;

  #ifdef SHADOWS
    shadow = max(0.5, SoftShadowRing(ringHitPos.xyz, sunPos));
  #endif

    #ifdef HIGH_QUALITY_BELT
    // trace rock belt
    RayHit rockMarch = TraceRocks(rayOrigin, rayDir, 100, 500.);   

  // is rock belt hit?
  if (rockMarch.hit)
  { 
    vec3 pp = rockMarch.hitPos;
    GetRockRotation(pp);

    vec3 rockCol= vec3(0.5)+(0.4*abs(noise(pp*3.))); 
    rockMarch.normal = calcNormalRocks(rockMarch.hitPos); 
    vec3 rockLight = GetLight(1., rockMarch.normal, rockMarch, rayDir, rayOrigin, 0.0)*0.4; 
    rockCol = rockCol*rockLight;
    //rockCol = mix(rockCol,mix(rockCol,rockCol+background,0.35),smoothstep(100.,500.,rockMarch.depth));  
    color.rgb = rockCol;
  }
  #endif 

    //vec3 origin, vec3 direction, int steps, float scale, float densLimit, float rotSpeed, float inRad, float outRad)

    vec4 ringColor = TraceRing(rayOrigin, rayDir, 40, 1.1, .15, 0.04, 120., 150.);    
  color.rgb =mix( color.rgb, clamp(ringColor.rgb*shadow, 0., 0.8), ringColor.a );   

  ringColor = TraceRing(rayOrigin, rayDir, 40, 1.65, 0.12, 0.06, 120., 150.);      
  color.rgb =mix( color.rgb, clamp(ringColor.rgb*shadow, 0., 0.8), ringColor.a );

  ringColor = TraceRing(rayOrigin, rayDir, 30, 1., 0.12, 0.07, 120., 145.);      
  color.rgb =mix( color.rgb, clamp(ringColor.rgb*shadow, 0., 0.8), ringColor.a );


  #ifdef SPACE_CLOUDS
  vec4 cColor = TraceSpaceClouds(rayOrigin, rayDir, 90);      
  color.rgb =mix( color.rgb, cColor.rgb, cColor.a );  
  #endif

  fragColor = color;
}
