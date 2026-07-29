// Buf A (buffer) — [Planet] Outer Space by ingagard
// https://www.shadertoy.com/view/4llBD8

//////////////////////////////////////////////////////////////////////////////////////
// DATA BUFFER  -  CAMERA CONTROL AND KEYBOARD CHECKS
//////////////////////////////////////////////////////////////////////////////////////

  // #pragma optimize(off) 
  #define keyClick(ascii)   ( texelFetch(iChannel0, ivec2(ascii, 0), 0).x > 0.)
  #define keyPress(ascii)   ( texelFetch(iChannel0, ivec2(ascii, 1), 0).x > 0.)
  #define read(memPos) (  texelFetch(iChannel2, memPos, 0).a)
  #define readRGB(memPos) (  texelFetch(iChannel2, memPos, 0).rgb)

  // D     ZOOM OUT
  #define ZOOMOUT_KEY 68
  // E     ZOOM IN
  #define ZOOMIN_KEY 69
  // F1     ZOOM OUT (alternative)
  #define ZOOMOUT_KEY_ALT 112
  // F2     ZOOM IN (alternative)
  #define ZOOMIN_KEY_ALT 113

  //#define MANUAL_CAMERA
  #define ROTATING_SUN


  #define pR(p, a) p*=r2(a)

mat2 r2(float r) 
{
  float c=cos(r), s=sin(r);
  return mat2(c, s, -s, c);
}

void ToggleEffects(inout vec4 fragColor, vec2 fragCoord)
{
  // read and save effect values from buffer  
  vec3 effects =  mix(vec3(-1.0, -1.0, -1.0), readRGB(ivec2(120, 0)), step(1.0, float(iFrame)));
  effects.x*=1.0+(-2.*float(keyPress(49))); //1-key  color tint mode
  effects.y*=1.0+(-2.*float(keyPress(50))); //2-key  manual / auto camera mode
  effects.z*=1.0+(-2.*float(keyPress(51))); //3-key  chromatic aberration

  vec3 effects2 =  mix(vec3(1.0, 1.0, 1.0), readRGB(ivec2(122, 0)), step(1.0, float(iFrame)));
  effects2.y*=1.0+(-2.*float(keyPress(52))); //4-key  god Rays
  effects2.x*=1.0+(-2.*float(keyPress(53))); //5-key  lens flare

  fragColor.rgb = mix(effects, fragColor.rgb, step(1., length(fragCoord.xy-vec2(120.0, 0.0))));  
  fragColor.rgb = mix(effects2, fragColor.rgb, step(1., length(fragCoord.xy-vec2(122.0, 0.0))));
}

mat3 setCamera(  vec3 ro, vec3 ta, float cr )
{
  vec3 cw = normalize(ta-ro);
  vec3 cp = vec3(sin(cr), cos(cr), 0.0);
  vec3 cu = normalize( cross(cw, cp) );
  vec3 cv = normalize( cross(cu, cw) );
  return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, vec2 fragCoord )
{ 
  vec2 mo = iMouse.xy/iResolution.xy;
  vec2 uv = fragCoord.xy / iResolution.xy;
  vec2 screenSpace = (-iResolution.xy + 2.0*(fragCoord))/iResolution.y;

  // load data  
  vec3 sunPos = normalize( vec3(-.50, 0.13, .700));
  vec3 camData = mix(vec3(0., 0., 230.), readRGB(ivec2(52, 0)), step(1.0, float(iFrame)));  
  vec2 camRot = mix(vec2(3.73, 0.), readRGB(ivec2(57, 0)).xy, step(1.0, float(iFrame))); 
  vec3 oldOrigin = readRGB(ivec2(62, 0));

  ToggleEffects(fragColor, fragCoord);

  // adding a small amount of camRot.y just to check if the camera has been moved in ANY way when later doing AA pass
  float camrot = 15.+(iTime*0.1);
  vec3 rayOrigin = vec3(230.*cos(camrot), 10.-40.*sin(-camrot*4.)+(0.0001*camRot.y), 230.0*sin(-camrot) );
  mat3 ca = setCamera( rayOrigin, vec3(0., 0., 0. ), 0.0 );
  vec3 rayDir = ca * normalize( vec3(screenSpace.xy, 2.0) );


  // manual camera mode?  2-key
  if (readRGB(ivec2(120, 0)).y>0.)
  {
    if (iMouse.z>0.)
    {
      camRot.x=(mo.x*12.); 
      camRot.y=-64.+((mo.y)*128.);
    }
    camRot.y = clamp(camRot.y, -128., 128.);

    camData.z-=0.3*float(keyClick(ZOOMIN_KEY) || keyClick(ZOOMIN_KEY_ALT));
    camData.z+=0.3*float(keyClick(ZOOMOUT_KEY) || keyClick(ZOOMOUT_KEY_ALT));
    camData.z=clamp(camData.z, 180., 320.);

    rayOrigin = vec3(camData.z*cos(camRot.x), camRot.y, camData.z*sin(camRot.x) );
  }

  // rotate the sun
  #ifdef ROTATING_SUN
    pR(sunPos.xz, -iTime*0.2);
  #endif

  // save date    
  fragColor.rgb = mix(sunPos, fragColor.rgb, step(1., length(fragCoord.xy-vec2(50.0, 0.0))));
  fragColor.rgb = mix(camData, fragColor.rgb, step(1., length(fragCoord.xy-vec2(52.0, 0.0))));
  fragColor.rgb = mix(rayOrigin, fragColor.rgb, step(1., length(fragCoord.xy-vec2(62.0, 0.0))));
  fragColor.rgb = mix(oldOrigin, fragColor.rgb, step(1., length(fragCoord.xy-vec2(60.0, 0.0))));

  fragColor.rgb = mix(vec3(camRot.xy, 0.), fragColor.rgb, step(1., length(fragCoord.xy-vec2(57.0, 0.0))));
}
