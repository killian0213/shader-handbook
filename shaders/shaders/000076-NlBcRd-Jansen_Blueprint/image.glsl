// Image (image) — Jansen Blueprint by blackle
// https://www.shadertoy.com/view/NlBcRd

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

//antialising
#define AA_SAMPLES 1

float t = 0.;
float ot = 0.;
#define ro(r) mat2(cos(r),-sin(r),sin(r),cos(r))

float linedist(vec2 p, vec2 a, vec2 b) {
  float k = dot(p-a,b-a)/dot(b-a,b-a);
  return distance(p,mix(a,b,clamp(k,0.,1.)));
}

float doodad(vec3 p, vec2 a, vec2 b, float s) {
  s/=2.;
  float wire = max(min(length(p.yz-a)-.04, length(p.yz-b)-.04),abs(p.x)-s-.04);
  return min(max(linedist(p.yz,a,b)-.05,abs(abs(p.x)-s)-.02),wire);
}

vec2 poop(vec2 a, vec2 b, float d1, float d3, float side) {
  float d2 = distance(a,b);
  float p = (d1*d1+d2*d2-d3*d3)/d2/2.;
  float o = side*sqrt(d1*d1-p*p);
  return a + mat4x2(-p,-o,o,-p,p,o,-o,p)*vec4(a,b)/d2;
}

float scene(vec3 p) {
  float dist = 1e4;
  vec2 D = ro(ot*7.)*vec2(.15,0);
  p.x-=0.025;
  {
  float side = 1.;
  vec2 M = vec2(-.4*side,0);
  vec2 a = poop(M,D,.4,.6,side);
  vec2 b = poop(M,D,.4,.6,-side);
  vec2 c = poop(M,a,.4,.5,side);
  vec2 d = poop(b,c,.35,.4,side);
  vec2 e = poop(b,d,.4,.6,side);
  
  dist = min(dist, doodad(p,D,a,.0));
  dist = min(dist, doodad(p,M,a,.1));
  dist = min(dist, doodad(p,D,b,.2));
  dist = min(dist, doodad(p,M,b,.3));
  dist = min(dist, doodad(p,b,d,.0));
  dist = min(dist, doodad(p,M,c,.0));
  dist = min(dist, doodad(p,c,d,.1));
  dist = min(dist, doodad(p,b,e,.1));
  dist = min(dist, doodad(p,c,a,.2));
  dist = min(dist, doodad(p,d,e,.2));
  }
  p.x+=0.05;
  {
  float side = -1.;
  vec2 M = vec2(-.4*side,0);
  vec2 a = poop(M,D,.4,.6,side);
  vec2 b = poop(M,D,.4,.6,-side);
  vec2 c = poop(M,a,.4,.5,side);
  vec2 d = poop(b,c,.35,.4,side);
  vec2 e = poop(b,d,.4,.6,side);
  
  dist = min(dist, doodad(p,D,a,.0));
  dist = min(dist, doodad(p,M,a,.1));
  dist = min(dist, doodad(p,D,b,.2));
  dist = min(dist, doodad(p,M,b,.3));
  dist = min(dist, doodad(p,b,d,.0));
  dist = min(dist, doodad(p,M,c,.0));
  dist = min(dist, doodad(p,c,d,.1));
  dist = min(dist, doodad(p,b,e,.1));
  dist = min(dist, doodad(p,c,a,.2));
  dist = min(dist, doodad(p,d,e,.2));
  }
  return dist;
}

vec3 norm(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(0.001);
  return normalize(scene(p)-vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}
float bpm = 127.;

vec3 pixel_color(vec2 uv) {
  
  uv += texture(iChannel0,uv*2.).x*0.0025;
  
  float m = 2.*60./bpm;
  float rng = floor(m*iTime)/m;
  float w = iTime - rng;
  t =rng + mix(pow( w,3.),w,.8);
  ot =t ;
  t += fract(cos(rng)*456.)*3.;
  
  vec3 cam = normalize(vec3(1.8+cos(rng*45.)*.5,uv));
  vec3 init = vec3(-3,cos(rng*445.)*.3,-.2);
  
  float ry = sin(cos(rng*64.)*100.)*.3;
  cam.xz*=ro(ry);
  init.xz*=ro(ry);
  float rz = t*.5 + cos(rng*64.)*100.;
  cam.xy*=ro(rz);
  init.xy*=ro(rz);
  
  vec3 p = init;
  bool hit = false;
  bool trig = false;
  for (int i = 0; i < 50 && !hit; i++) {
    float dist = scene(p);
    hit = dist*dist < 1e-6;
    if (!trig) trig = dist<0.005;
    p += cam*dist;
  }
  float v = 1.-dot(uv,uv)*.5;
  vec3 n = norm(p);
  vec3 r = reflect(cam,n);
  float fact = dot(cam,r);
  vec2 grid = abs(asin(sin(uv*40.)));
  float g =smoothstep(1.52,1.58,max(grid.x,grid.y));
  float f = smoothstep(.8,.85,fact) + smoothstep(.4,.45,fact)*smoothstep(.5,1.,cos(uv.y*1000.));
  vec3 fragColor = min(vec3(1),hit ? vec3(f) : vec3(trig?1.:g))*.8;
  fragColor.xyz += texture(iChannel1,clamp(ro(ot)*(uv*6.+vec2(4.2,2))+.5,0.,1.)).xyz;
  fragColor*=v;
  return fragColor*fragColor;
}

vec2 weyl_2d(int n) {
    return fract(vec2(n*12664745, n*9560333)/exp2(24.));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    fragColor = vec4(0);
    for (int i = 0; i < AA_SAMPLES; i++) {
        vec2 uv2 = uv + weyl_2d(i)/iResolution.y*1.25;
        fragColor += vec4(pixel_color(uv2), 1.);
    }
	fragColor.xyz = sqrt(fragColor.xyz/fragColor.w);
}
