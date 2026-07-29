// Image (image) — 2d Procedural Pattern by gPlatl
// https://www.shadertoy.com/view/4dfyzf


//---------------------------------------------------------
// Shader: 2dProceduralPattern.glsl  by gPlatl
//
//         https://www.shadertoy.com/view/4dfyzf
//
// A collection of 2d procedural pattern types.
// Press mouse button and select pattern in x direction & zoom in y direction.
//
//   v1.0  2017-02-22  initial release
//   v1.1  2017-02-24  changed mod(x,1.) => fract(x)
//   v1.2  2017-03-15  pattern menu added
//   v1.3  2017-04-11  sine pattern added
//   v1.4  2017-04-30  brick wall pattern added
//   v1.5  2017-05-07  GearPattern added
//   v1.6  2017-05-30  HexagonalTruchetPattern added
//   v1.7  2017-06-10  QCirclePattern added
//   v1.8  2017-08-05  StarPattern added
//   v1.9  2017-09-02  Basketwork Pattern added
//   v1.10 2018-07-14  Diamond Pattern added
//   v1.11 2018-09-15  RosettePattern added
//   v1.12 2018-10-11  Wallpaper70sPattern added
//   v1.13 2018-10-11  MinimalWeavePattern added
//   v1.14 2019-05-16  GridPattern added
//
// tags:   procedural, pattern, 2d, basic, texture, collection
// note:   procedural pattern routines will return values from 0.0 .. 1.0
//
//   Procedural Patterns          https://www.shadertoy.com/view/7tcXWM
//                                http://slideplayer.com/slide/6400090/
//   Antialiasing Proc. Textures  http://www.yaldex.com/open-gl/ch17lev1sec4.html
//---------------------------------------------------------

#define patternCount 23.0

#define PI 3.141592

bool ANIMATE = true;   // false if mousePressed

#define RandomSign sign(cos(1234.*cos(h.x+9.*h.y)));  // random -1 or 1

//---------------------------------------------------------
// return test pattern
//---------------------------------------------------------
float TestPattern(in vec2 uv)
{
  uv *= 8.0;
  return clamp(88.*sin(uv.x)* sin(uv.y), 0.0, 1.0);
}
//---------------------------------------------------------
// return chess board pattern with AA
//---------------------------------------------------------
float ChessPattern(in vec2 uv)
{
//return clamp(88.*sin(uv.x)* sin(uv.y), 0.0, 1.0);
  return 1. / sin(uv.x) / sin(uv.y);
}
//---------------------------------------------------------
// return checker board pattern with AA
//---------------------------------------------------------
float KaroPattern(in vec2 uv)
{
  return 0.5*clamp(10.*sin(PI*uv.x), 0.0, 1.0)
       + 0.5*clamp(10.*sin(PI*uv.y), 0.0, 1.0);
}
//---------------------------------------------------------
// return grid pattern 1 with AA
//---------------------------------------------------------
float Grid1Pattern(in vec2 uv)
{
  float col = max(sin(uv.x*10.1), sin(uv.y*10.1));
  return smoothstep(0.5,1.,col);
}
//---------------------------------------------------------
// return grid pattern 2 with AA
//---------------------------------------------------------
float Grid2Pattern(in vec2 uv)
{
  return 0.5*clamp(10.*sin(PI*uv.x), 0.0, 1.0)
       / 0.5*clamp(10.*sin(PI*uv.y), 0.0, 1.0);
}
//---------------------------------------------------------
// return rounded square holes grid with AA
//---------------------------------------------------------
float SquareHolePattern(in vec2 uv)
{
  float thickness = 0.8;
  float t = cos(uv.x*2.0) * cos(uv.y*2.0) / thickness;
  return smoothstep(0.1, 0.0, t*t);
}
//---------------------------------------------------------
// return lighted square pattern
//---------------------------------------------------------
float SquarePattern(in vec2 uv)   // no AA
{
  return fract(uv.x)*fract(uv.y);
}
//---------------------------------------------------------
float CheckerPattern(in vec2 uv)   // no AA
{
  uv = 0.5 - fract(uv);
  return 0.5 + 0.5*sign(uv.x*uv.y);
}
//---------------------------------------------------------
float TrianglePattern(in vec2 uv)   // no AA
{
  uv.y = uv.y * 0.866 + uv.x * 0.5;
  if(fract(uv.y) > fract(uv.x)) return 1.0;
  return 0.0;
}
//---------------------------------------------------------
float Rhomb1Pattern(in vec2 uv)   // no AA
{
  uv.y = uv.y * 0.866 + uv.x * 0.5;
  float t = fract(uv.y) - fract(uv.x);
  return smoothstep(.50, 0.0, t*t);
}
//---------------------------------------------------------
// return antialiased hexagonal grid color
//---------------------------------------------------------
float HexagonalGrid (in vec2 position
                    ,in float gridSize
                    ,in float gridThickness)
{
  vec2 pos = position / gridSize;
  pos.x *= 0.57735 * 2.0;
  pos.y += 0.5 * mod(floor(pos.x), 2.0);
  pos = abs(fract(pos) - 0.5);
  float d = abs(max(pos.x*1.5 + pos.y, pos.y*2.0) - 1.0);
  return smoothstep(0.0, gridThickness, d);
}
//---------------------------------------------------------
// return hexagonal grid pattern with 3 colors
//---------------------------------------------------------
float Hexagonal3Pattern(in vec2 p)   // no AA
{
  p.y = p.y * 0.866 + p.x*0.5;
  p = mod(p, vec2(3.0));

  if(p.y < p.x+1.0 && p.y > 0.0 && p.x > 0.0
  && p.y > p.x-1.0 && p.x < 2.0 && p.y < 2.0)
    return 0.0;
  else if(p.y > 1.0 && (p.y < p.x || p.x < 1.0))
    return 0.5;
  return 1.0;
}
//---------------------------------------------------------
// return antialiased hexagonal grid color
//---------------------------------------------------------
float HexagonalGrid2 (in vec2 position
	                 ,in float gridSize
	                 ,in float gridThickness)
{
  vec2 pos = position / gridSize;
  pos.x *= 1.1;
  pos.y += 0.5 * mod(floor(pos.x), 2.0);
  pos = abs(fract(pos) - 0.5);
  float d = abs(max(pos.x*2.5 + pos.y, pos.y*3.0) - 1.0);
  return smoothstep(0.30, gridThickness, d);
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/Xdt3D8 by FabriceNeyret2
//---------------------------------------------------------
float HexagonalTruchetPattern(vec2 p)
{
  vec2 h = p + vec2(0.58, 0.15)*p.y;
  vec2 f = fract(h);
  h -= f;
  float v = fract((h.x + h.y) / 3.0);
  (v < 0.6) ? (v < 0.3) ?  h : h++ : h += step(f.yx,f);
  p += vec2(0.5, 0.13)*h.y - h;        // -1/2, sqrt(3)/2
  v = RandomSign;
  return 0.06 / abs(0.5 - min (min
    (length(p - v*vec2(-1., 0.00)  ),  // closest neighbor (even or odd set, dep. s)
     length(p - v*vec2(0.5, 0.87)) ),  // 1/2, sqrt(3)/2
     length(p - v*vec2(0.5,-0.87))));
}

//---------------------------------------------------------
// return sinus wave pattern
//---------------------------------------------------------
float SinePattern(in vec2 p)
{
  return sin(p.x * 20.0 + cos(p.y * 12.0 ));
}
//---------------------------------------------------------
// return sinus wave pattern
//---------------------------------------------------------
float Sine2Pattern(in vec2 p)
{
  return 0.5+sin(p.x * 20.0 + cos(p.y * 10.0 ))
            *sin(p.y * 20.0 + cos(p.x * 10.0 ));
}
//---------------------------------------------------------
// return antialiased brick wall pattern
//---------------------------------------------------------
float BrickPattern(in vec2 p)
{
  p *= vec2 (1.0, 2.8);  // scale
  vec2 f = floor (p);
  if (2. * floor (f.y * 0.5) != f.y)
    p.x += 0.5;  // brick shift
  p = smoothstep (0.03, 0.08, abs (fract (p + 0.5) - 0.5));
  return 1. - 0.9 * p.x * p.y;
}
//---------------------------------------------------------
// return brick wall pattern
//---------------------------------------------------------
float BrickPattern2(in vec2 p)    // no AA
{
  const float vSize = 0.10;
  const float hSize = 0.05;
  p.y *= 2.5;    // scale y
  if(mod(p.y, 2.0) < 1.0) p.x += 0.5;
  p = p - floor(p);
  if((p.x+hSize) > 1.0 || (p.y < vSize)) return 1.0;
  return 0.0;
}
//---------------------------------------------------------
// return pattern of rotating gears
//---------------------------------------------------------
float GearPattern(in vec2 uv     // coordinates
                 ,in float wn    // vertical wheel count
                 ,in int tn      // tooth count
                 ,in float time) // rotation time
{
  float g = (step(1.0, uv.x * wn) - 0.5) * time;
  uv = fract(uv * wn) - 0.5;
  float r = clamp(0.48, 0.4, 0.45 + 0.12*sin(atan(uv.x,uv.y) * float(tn) + g));
  return smoothstep(r, r + 0.01, 1.1*length(uv));
}
//---------------------------------------------------------
// return rounded square circle pattern
//---------------------------------------------------------
float lengthN(in vec2 v, in float n)
{
  return pow(pow(abs(v.x), n)+pow(abs(v.y), n), 0.89/n);
}
//---------------------------------------------------------
float QCirclePattern(in vec2 p)
{
  vec2 p2 = mod(p*8.0, 4.0)-2.0;
  return sin(lengthN(p2, 4.0)*16.0);
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/4sKXzy by aiekick
//---------------------------------------------------------
float StarPattern(in vec2 p)
{
  p = abs(fract(p*1.5)-0.5);
  return max(max(p.x, p.y), min(p.x, p.y)*2.);
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/llfyDn by FabriceNeyret2
//---------------------------------------------------------
#define S1(x,y) abs(fract(x))<0.8 ? 0.65 +0.35* sin(3.1415*(y-ceil(x))) : 0.0
#define S2(x,y) abs(fract(x))<0.8 ? 0.65 +0.35* sin(1.5707*(y-ceil(x))) : 0.0

float Basketwork1Pattern(in vec2 uv)
{
  vec2 p = uv * 4.0;
  return max (S1(p.x, p.y), S1(p.y+1.0, p.x));
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/ltXcDn by FabriceNeyret2
//---------------------------------------------------------
float Basketwork2Pattern(in vec2 uv)
{
  vec2 p = uv * 4.0;
  return max (S2( p.x, p.y), S2(p.y, p.x+1.) );
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/lsVczV by FabriceNeyret2
//---------------------------------------------------------
float DiamondPattern(in vec2 uv)
{
  vec2 dp = abs (fract(uv*2.) - 0.5);
  return 0.3 - cos (19. * max(dp.x, dp.y));
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/4lGyz3 by FabriceNeyret2
//---------------------------------------------------------
#define D(U) .004/abs(length(mod(U,d+d)-d)-d.x)
float RosettePattern(in vec2 p)
{
  vec2 d = vec2(0.58,1);
  vec4 O = vec4(0);
  for (; O.a++ < 4.; O += D(p) +D(p += d*.5)) p.x += d.x;
  return O.x;
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/ls33DN by Shane
//---------------------------------------------------------
float Wallpaper70sPattern(vec2 p, float time)
{
  p.x *= sign(cos(length(ceil(p))*time));
  return cos(min(length(p = fract(p)), length(--p))*44.);
}
//---------------------------------------------------------
// https://www.shadertoy.com/view/XttBWn by xentrac
//---------------------------------------------------------
float MinimalWeavePattern(vec2 coord)
{
  vec3 bg = vec3(0),  warp = vec3(.5),  weft = vec3(1);
  ivec2 uv = ivec2(floor(coord*8.));
  int mask = (int(iTime / 2.) & 7) << 2;
  vec3 col = (((uv.x ^ uv.y) & mask) == 0
   ? 1 == ((uv.x ^ uv.x >> 1) & 1) ? warp : bg
   : 1 == ((uv.y ^ uv.y >> 1) & 1) ? weft : bg);
  return col.r;
}
//---------------------------------------------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  float aspect = iResolution.y / iResolution.x;
  vec2 mpos = iMouse.xy / iResolution.y;
  vec2 uv = fragCoord.xy / iResolution.y - vec2(0.5);

  float time = iTime;

  ANIMATE = iMouse.z < 1.0;

  // get pattern
  int pType = int( mpos.x * patternCount * aspect);
  if (uv.y < -0.4)           // pattern menu ?
  {
    pType = int(fragCoord.xy / iResolution.y * patternCount * aspect);
    uv *= 28.0;
  }
  else
  {
    uv *= (0.2 + mpos.y) * 10.0;
    if (ANIMATE)
    {
      // rotate and scale position
      float ra = time*0.12;
      float cost = cos(ra);   // rotate
      float sint = sin(ra);
      uv = vec2(cost*uv.x + sint*uv.y, sint*uv.x - cost*uv.y);
      uv *= (1.2+0.3*sin(0.5*time));   // scale
    }
  }

  float p; // = HexagonalGrid(uv, 0.5, 0.1);
  if      (pType == 0) p = HexagonalGrid (uv, 0.8, 0.2);
  else if (pType == 1) p = HexagonalGrid2(uv, 0.8, 0.2);
  else if (pType == 2) p = Hexagonal3Pattern(uv*2.0);
  else if (pType == 3) p = HexagonalTruchetPattern (uv*3.);
  else if (pType == 4) p = CheckerPattern(uv);
  else if (pType == 5) p = ChessPattern(uv*8.0);
  else if (pType == 6) p = TrianglePattern(uv);
  else if (pType == 7) p = Rhomb1Pattern(uv);
  else if (pType == 8) p = KaroPattern(uv);
  else if (pType == 9) p = Grid1Pattern(uv);
//else if (pType == 9) p = Grid2Pattern(uv);
  else if (pType ==10) p = SquareHolePattern(uv);
  else if (pType ==11) p = SquarePattern(uv);
  else if (pType ==12) p = SinePattern(uv);
  else if (pType ==13) p = BrickPattern(uv);
//else if (pType ==13) p = BrickPattern2(uv);
  else if (pType ==14) p = GearPattern(uv, 1.5, 12, iTime * 6.5);
  else if (pType ==15) p = QCirclePattern(uv);
  else if (pType ==16) p = StarPattern(uv);
  else if (pType ==17) p = Basketwork1Pattern(uv);
  else if (pType ==18) p = Basketwork2Pattern(uv);
  else if (pType ==19) p = DiamondPattern(uv);
  else if (pType ==20) p = RosettePattern(uv);
  else if (pType ==21) p = Wallpaper70sPattern(uv, iTime*0.1);
  else if (pType ==22) p = MinimalWeavePattern(uv);
  else                 p = TestPattern(uv);

  vec4 color1 = vec4 (0.2+0.2*sin(time)
                     ,0.2+0.2*sin(time*0.789)
                     ,0.2+0.2*sin(time*0.665), 1.0);

  vec4 color2 = vec4 (0.9);

  fragColor = mix(color1, color2, p);
  fragColor = vec4(p);   // B+W
}