// Buf B (buffer) — [Planet] Outer Space by ingagard
// https://www.shadertoy.com/view/4llBD8

//////////////////////////////////////////////////////////////////////////////////////
// BACKGROUND BUFFER -   RENDERS SPACE
//////////////////////////////////////////////////////////////////////////////////////

  #define PI 3.14159265359
  #define PI_TWO 6.28318530718
  #define readRGB(memPos) (  texelFetch(iChannel2, memPos, 0).rgb)
  //#pragma optimize(off) 


  #define COMETS

  vec2 PosToSphere(vec3 pos)
{
  float x = atan(pos.z, pos.x); 
  float y = acos(pos.y / length(pos)); 
  return vec2(2.*x / PI_TWO, 2.*y / PI);
}

float hash(float h)
{
  return fract(sin(h) * 43758.5453123);
} 

vec3 sunPos=vec3(0.);

// by IQ
float noise(vec3 x) 
{
  vec3 p = floor(x);
  vec3 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);

  float n = p.x + p.y * 157.0 + 113.0 * p.z;
  return -1.0+2.0*mix(
    mix(mix(hash(n + 0.0), hash(n + 1.0), f.x), 
    mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y), 
    mix(mix(hash(n + 113.0), hash(n + 114.0), f.x), 
    mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

// by IQ
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

mat3 setCamera(  vec3 ro, vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}
vec4 SphereMap(sampler2D sam, in vec3 p)
{
  vec2 spherePos = PosToSphere(p);
  return textureLod(sam, spherePos, 2.*log2(spherePos.y*2.));
}

// https://www.shadertoy.com/view/MtsGWH
vec4 BoxMap( sampler2D sam, in vec3 p, in vec3 n, in float k, in float LOD)
{
  vec3 m = pow( abs(n), vec3(k) );
  vec4 x = textureLod( sam, p.yz, LOD);
  vec4 y = textureLod( sam, p.zx, LOD);
  vec4 z = textureLod( sam, p.xy, LOD);
  return (x*m.x + y*m.y + z*m.z)/(m.x+m.y+m.z);
}


#define pR(p, a) (p)*=r2(a)
  mat2 r2(float r) {
  float c=cos(r), s=sin(r);
  return mat2(c, s, -s, c);
}


vec3 GetSpaceColor(vec3 rayDir)
{ 
  vec3 stars = BoxMap(iChannel0, rayDir, rayDir, 0.5, 0.0).rgb;
  vec3 stars2 = SphereMap(iChannel0, rayDir).rgb; 

  vec3 starPos = rayDir+vec3(iTime*0.0004, iTime*0.0005, iTime*0.0003);
  float starsDetailS = pow(noise(starPos*450.), 1.);
  float starsDetailM = pow(noise(starPos*150.), 2.);
  float starsDetailL = pow(0.45+noise(starPos*52.), 3.);

  vec3 starColor = vec3(1.0);

  starColor.r += abs(starsDetailS-starsDetailM);
  starColor.g += abs(starsDetailL-starsDetailM);
  starColor.b += abs(starsDetailS-starsDetailL);

  starColor=(starColor*0.5)+(starsDetailL*.5);

  float sun = mix(0., pow( clamp( 0.5 + 0.5*dot(sunPos, rayDir), 0.0, 1.0 ), 2.0 ), smoothstep(.33, .0, rayDir.y));
  float sun2 = clamp( 0.75 + 0.25*dot(sunPos, rayDir), 0.0, 1.0 );

  vec3 col = mix(vec3(0, 0, 164)/255., vec3(0, 0, 150)/255., smoothstep(0.8, 0.00, rayDir.y)*sun2);
  col = mix(col, vec3(100, 0, 169)/255., smoothstep(0.015, .0, rayDir.y)*sun2);
  col = mix(col, vec3(160, 0, 136)/255., smoothstep(0.3, 1.0, sun));
  col = mix(col, vec3(255, 0, 103)/255., smoothstep(0.6, 1.0, sun));

  col=col*stars;
  col = mix(col, vec3(starsDetailS*starColor), smoothstep(0.7, 1., starsDetailS));
  col = mix(col, vec3(starsDetailM*starColor), smoothstep(0.7, 1., starsDetailM));

  vec3 nebula = (vec3(stars.r, 0., 0.)*stars2.r);
  nebula = mix(nebula, nebula*2., pow(stars2.r, 2.));
  nebula = mix(nebula, vec3(1.), pow(stars2.r, 4.));        

  vec3 offset = vec3(iTime, iTime*2., 0.)*0.01;
  vec2 addStep = vec2(-0.04, -0.07)*0.05;
  vec2 pp = PosToSphere(rayDir);

  #ifdef COMETS
    vec3 comet = textureLod(iChannel3, (pp)-offset.xy, 1.).rgb;

  for ( int i=0; i<30*int(step(0.2, comet.r)); i++ )
  {
    col = mix(col, vec3(1.), step(0.4, pow(textureLod(iChannel3, (pp*2.)-offset.xy, 1.).r, 6.))/((float(i)+1.)));
    offset.xy+=addStep;
  }   
  #endif

    nebula = mix(nebula, nebula*vec3(1.2, 0.9, .50), max(0., readRGB(ivec2(120, 0)).x));

  return col+nebula;
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{  
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;
  float alpha=0.;

  sunPos =  readRGB(ivec2(50, 0));
  // setup camera and ray direction
  vec2 camRot = readRGB(ivec2(57, 0)).xy;   
  vec3 rayOrigin =readRGB(ivec2(62, 0));
  mat3 ca = setCamera( rayOrigin, vec3(0., 0., 0. ), 0.0 );
  vec3 rayDir = ca * normalize( vec3(screenSpace.xy, 2.0) );

  vec3 color =  GetSpaceColor(rayDir)*1.5;

  vec2 beltPos = rayDir.xz;
  pR(beltPos, iTime*0.01);
  vec3 noisePos = vec3(iTime*2., iTime*4., iTime*0.5)*0.2;
  vec3 test= textureLod(iChannel0, beltPos*0.4, log2(beltPos.y*2.)).rgb*vec3(1.3, 0.74, 1.);
  color.rgb = mix(color.rgb+test*vec3(1.2, 0.9, .50), color.rgb, smoothstep(0., 0.3, (0.5+(.285*fastFBM(noisePos+(rayDir*122.))))*distance(((rayDir.y)*3.1), 0.)));

  fragColor = vec4(mix(color.rgb, color.rgb*vec3(1., 0.97, 0.40), max(0., readRGB(ivec2(120, 0)).x)), 0.);
}
