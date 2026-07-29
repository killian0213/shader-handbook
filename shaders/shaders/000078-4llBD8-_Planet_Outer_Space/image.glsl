// Image (image) — [Planet] Outer Space by ingagard
// https://www.shadertoy.com/view/4llBD8

////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2017 Kim Berkeby (email: mr.kimb@hotmail.com)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
////////////////////////////////////////////////////////////////////////////////////////////
/*

 Toggle effects by pressing folloving keys:
 ------------------------------------------
 1-key  = Change color tint mode  

 2-key  = Switch manual/auto camera mode         (default auto)

 ------------------  NOTICE    ------------------------------------
 Using manual camera allows you to use mouse to control the camera.
 This also allows you to use D and E keys to zoom (alternative F1 and F2 keys)
 -------------------------------------------

 3-key  = Chromatic aberration  on/off           (default on)    
 4-key  = God Rays  on/off                       (default on)
 5-key  = Lens flare  on/off                     (default on)

 --------------------------------------------------------
 --------------------------------------------------------

  TO INCREASE PERFORMANCE OR QUALITY:
  --------------------------------
  
  Turn on/off one or several defines in Buf C:
 
  #define CLOUDS
  #define QUALITY_CLOUDS

  #define SHADOWS
  #define ROTATING_MOON
  #define ROTATING_PLANET
  #define SPACE_CLOUDS
  #define HIGH_QUALITY_BELT

  Enable for full experience (can crash some machines):
 

  #define HIGH_QUALITY    <-----


 --------------------------------------------------------
 
 This shader was made by using distance functions found in HG_SDF:
 http://mercury.sexy
 
 Special thanks to Inigo Quilez for his great tutorials on:
 https://iquilezles.org/

 Music by chamberlain:
 https://soundcloud.com/chamberlainyeah/path-to-shangri-la-1

 Last but not least, thanks to all the nice people here at ShaderToy! :-D

*/


//////////////////////////////////////////////////////////////////////////////////////
// POST EFFECTS BUFFER
//////////////////////////////////////////////////////////////////////////////////////

  #define FastNoise(posX) (  textureLod(iChannel1, (posX+0.5)/iResolution.xy, 0.0).r)
  #define readAlpha(memPos) (  textureLod(iChannel2, memPos, 0.0).a)
  #define readRGB(memPos) (  texelFetch(iChannel0, memPos, 0).rgb)
  #define PI acos(-1.)
  #pragma optimize(off) 

mat3 cameraMatrix;

vec3 sunPos=vec3(0.);

float CalcSum(vec2 uvPos) 
{
    vec4 col = textureLod(iChannel2, uvPos,0.);
    float sum = (col.r+col.g+col.b)*0.333;
    return mix(0.,sum,step(0.65,sum-col.a));
}

#define VOLUMESAMPLES 32
float GetVolumetrics(vec2 pos, vec2 uv)
{
    float sum 	 = 0.;
    float weight = 1. / float(VOLUMESAMPLES);
    vec2 dir = pos-uv;
    
    for(int i = 0; i < VOLUMESAMPLES; i++)
    {
        sum += CalcSum(uv)*(1.-(float(i)*weight));
        uv += dir * .01;
    }
    
    return sum * weight;
}

mat3 setCamera(  vec3 ro, vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}

vec2 GetScreenPos(vec3 pos)
{
  return vec2(PI*dot( pos, cameraMatrix[0].xyz ), PI* dot( pos, cameraMatrix[1].xyz ));
}

vec3 CalculateSunFlare(vec3 rayDir, vec3 rayOrigin, vec2 screenSpace, float alpha, float enableFlare, vec2 uv)
{

  float visibility = pow(max(0., dot(sunPos, rayDir)), 5.0);  
  if (visibility<=0.006) return vec3(0.);

  vec2 sunScreenPos = GetScreenPos(sunPos);

  vec2 uvT = screenSpace-sunScreenPos;  
  vec2 offSetCol = (uvT.xy-1.)/iResolution.xy*14.5;  
     
  float sunIntensity = (1.0/(pow(length(uvT)*4.0+1.0, 1.30)))*visibility;

  vec3 flareColor = vec3(0.);
  vec2 offSet = uvT;
  vec2 offSetStep=  0.4*sunScreenPos;
  float size=.0, dist=0.;
  
  if(enableFlare>0.)
  {
  // check if center of sun is covered by any object. MATH IS OFF AT SCREEN CHECK POS! sunScreenPos/2.0 +0.5 IS NOT EXACTLY SUN MIDDLE!
  // only draw if not covered by any object
  if (readAlpha( sunScreenPos/2.0 +0.5)<0.50)
  {
    // create flare rings
    for (float i =1.; i<8.; i++)
    {
      offSet += offSetStep;

      size = 0.006+((1.-sin(i*0.54))*0.2);
      dist = pow(length(sunScreenPos+offSetCol-offSet), 1.20);
      flareColor.r += mix(0., sunIntensity*(18.*size), smoothstep(size, size-dist, dist))/(1.0-size);
      dist = pow(length(sunScreenPos-offSet), 1.20);
      flareColor.g += mix(0., sunIntensity*(18.*size), smoothstep(size, size-dist, dist))/(1.0-size);
      dist = pow(length(sunScreenPos-offSetCol-offSet), 1.20);
      flareColor.b += mix(0., sunIntensity*(18.*size), smoothstep(size, size-dist, dist))/(1.0-size);   
    }

  }
      flareColor = mix(flareColor,flareColor*.1, max(0.,visibility));
      flareColor += vec3(1.0, .7, .0)  * pow(visibility, 2.);
}
  flareColor*=mix(2., .2, smoothstep(0., 1., visibility)); 
    
  // flare star shape
  vec3 sunSpot = vec3(1.30, 1., .80)*sunIntensity*(sin(FastNoise((sunScreenPos.x+sunScreenPos.y)*2.3+atan(uvT.x, uvT.y)*15.)*5.0)*.12);
  
  // sun glow
  sunSpot+=vec3(1.0, 0.9,0.8)*sunIntensity*2.5;
    
     float d = length(uvT*vec2(4.,.2))*50.;
	sunSpot += vec3(1.0, 0.776, 0.620)/pow(d,2.);
	d = length(uvT*vec2(.2,4.))*50.;
	sunSpot += vec3(1.0, 0.776, 0.620)/pow(d,2.);
 
  return flareColor+(sunSpot*(1.0-alpha));
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{  
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;

  // read values from buffer
  vec3 effects = readRGB(ivec2(120, 0));  
  vec3 effects2 = readRGB(ivec2(122, 0)); 

  sunPos = readRGB(ivec2(50, 0));
    
  // setup camera and ray direction
  vec2 camRot = readRGB(ivec2(57, 0)).xy;
  vec3 rayOrigin =readRGB(ivec2(62, 0));
  cameraMatrix  = setCamera( rayOrigin, vec3(0., 0., 0. ), 0.0 );
  vec3 rayDir = cameraMatrix * normalize( vec3(screenSpace.xy, 2.0) );

  vec4 color = vec4(0.);

  // chromatic aberration?
  if (effects.z>0.)
  {
    vec2 offSet = (uv.xy*3.-1.)/iResolution.xy*1.5;
    color.rgb = vec3(texture(iChannel2, uv + offSet).r, texture(iChannel2, uv).g, texture(iChannel2, uv - offSet).b);   
  }
  // no chromatic aberration 
  else
  {
      color.rgb = texture(iChannel2, uv).rgb;
  }

  color.a=textureLod(iChannel2, uv, 0.).a;

  // add sun with lens flare effect
  color.rgb += CalculateSunFlare(rayDir, rayOrigin, screenSpace, clamp(color.a, 0., 1.0),effects2.x,uv);

    
  // perform volumetric light ray pass if looking into the sun
  if (effects2.y>0.)
  { 
    vec2 sunScreenPos = GetScreenPos(sunPos);
    float sunVisibility = max(0.,dot(sunPos, rayDir));
         
    if(length(sunScreenPos)<2.3)
    {
      color.rgb += mix(0.,GetVolumetrics(sunScreenPos/2.0 +0.5, uv),pow(sunVisibility,6.));
    }
  } 
    
  // gamma correction and edge fade
  fragColor =  vec4(pow(color.rgb, vec3(1.0/1.1)), 1.0 ) * (0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.32 ));
}
