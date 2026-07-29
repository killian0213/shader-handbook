// Buffer A (buffer) — Alien Tunnel by lz
// https://www.shadertoy.com/view/X3ySRc

const vec2 vhex = normalize(vec2(1., 0.5));
const float hexh = 0.8660254037; // = sqrt(3) / 2;
const float inv_hexh = 1.15470053837;
const vec2 hexGrid = vec2(3., sqrt(3.));

vec4 hexgrid(in vec2 _uv)
{
  vec4 res;
  vec2 a = mod(_uv + 0.5 * hexGrid, hexGrid) - 0.5 * hexGrid;
  vec2 b = mod(_uv, hexGrid) - hexGrid * 0.5;
  
  vec2 fa = vec2(dot(abs(a), vhex), abs(a.y));
  vec2 fb = vec2(dot(abs(b), vhex), abs(b.y));
  
  float ma = max(fa.x, fa.y);
  float mb = max(fb.x, fb.y);
  
  vec2 bord;
  vec2 id;
  
  if (ma < mb)
  {
    bord = fa;
    id = floor((_uv + 0.5 * hexGrid) / hexGrid);
  }
  else
  {
    bord = fb;
    id = floor(_uv/hexGrid) + vec2(123., 273.);
  }
  
  res.x = min(ma, mb);
  res.y = min(1. - bord.x, 1. - bord.y);
  res.zw = id;
  
  return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (2.*fragCoord - iResolution.xy)/iResolution.y;
    vec2 ouv = uv*0.5;
    //uv.y += 2.*sin(uv.x);
    vec2 grid = uv;
    //grid = vec2(0.25*log(length(grid)), pow(atan(grid.y, grid.x), 1.));
    //uv = vec2(atan(uv.y, abs(uv.x)), length(uv)).yx;
    //uv = vec2(atan(uv.y, abs(uv.x)), length(uv)).yx;
    float time = iTime + 180.;
    uv.y += time * 0.1;
    float ht = time*0.01;
    float gridFactor = 1. + 2.*mix(hash(floor(ht)), hash(floor(ht) + 1.), fract(ht));
    uv.x += sin(fbm(vec3(uv*1.2, time * 0.05))) + time*0.01;
    vec2 fgridy = fract(vec2(uv.x * gridFactor, uv.y));
    vec2 igridy = floor(vec2(uv.x * gridFactor, uv.y));
    
    float f0 = fbm(vec3(grid, time * 0.15));
    float fl = smoothstep(0.5*f0, 0.5, fgridy.x) - smoothstep(0.5, 1.0 - 0.5*f0, fgridy.x);
    float f2 = 2.*fbm(vec3(uv, time*0.01));
    
    vec4 hx = hexgrid(grid*10.);
    
    float xpulse = mod(iTime, 10.);
    float lb = -0.001 * PULSE_T(xpulse, 1.5, 1.5, 8.5);
    float ub = 0.001 * PULSE_T(xpulse, 1.5, 1.5, 8.5);
    ouv *= 2.5;
    ouv = vec2(0.3*log(length(ouv)), abs(atan(ouv.y, ouv.x))).yx;
    ouv.y += 0.1 + 0.1*sin(ouv.x*5.);
    float xmask = PULSE_T(ouv.x*2., 0.1, xpulse - 3., xpulse - 3. + 0.5);
    float cf = PULSE_T(ouv.y, 0.01, lb*0.5, 0.5*ub) * xmask;
    
    fragColor = vec4(fl*f2, max(hx.x, 0.), cf,1.0);
}