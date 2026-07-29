// Image (image) — Apple (redux) by blackle
// https://www.shadertoy.com/view/ws2cRV

//CC0 1.0 Universal https://creativecommons.org/publicdomain/zero/1.0/
//To the extent possible under law, Blackle Mori has waived all copyright and related or neighboring rights to this work.

uniform int donttouch;

vec3 erot(vec3 p, vec3 ax, float ro) {
  return mix(dot(p,ax)*ax, p, cos(ro)) + sin(ro)*cross(ax,p);
}

float linedist(vec2 p, vec2 a, vec2 b) {
  float k = dot(p-a, b-a)/dot(b-a,b-a);
  return distance(p, mix(a,b,clamp(k,0.,1.)));
}

float linedist(vec3 p, vec3 a, vec3 b) {
  float k = dot(p-a, b-a)/dot(b-a,b-a);
  return distance(p, mix(a,b,clamp(k,0.,1.)));
}

float smin(float a, float b, float k) {
  float h = max(0., k-abs(a-b))/k;
  return min(a,b) - k*h*h*h/6.;
}

float hash(float a, float b) {
  return fract(sin(dot(vec2(a,b), vec2(12.9898, 78.233))) * 43758.5453)*2.-1.;
}

float apple(vec3 p) {
  p.x += sin(dot(p, vec3(4,2,5)))*0.02;
  p.z += sin(dot(p, vec3(2,3,7)))*0.02;
  p.y += sin(dot(p, vec3(2,6,2)))*0.01;
  
  vec2 cords = vec2(sqrt(pow(length(p.xy),2.)+0.005), p.z);
  float sphere1 = length(cords-vec2(0.1,-0.1))-0.85;
  float sphere2 = length(cords-vec2(0.6,0.6))-0.5;
  float sphere3 = length(cords-vec2(0.4,-0.8))-0.3;
  float profile = smin(smin(sphere1, sphere2, 0.9), sphere3, 0.5);
  float linez = -1.2;
  float linesub1 = linedist(p, vec3(0,-5,linez), vec3(0,5,linez)) - 0.2;
  float linesub2 = linedist(p, vec3(-5,0,linez), vec3(5,0,linez)) - 0.2;
  //return linedist(vec2(profile, p.x), vec2(0), vec2(-10,0))-0.1;
  return -smin(-profile, smin(linesub1, linesub2, 0.3), 0.4);
}

vec3 globalstemcoords;
float stem(vec3 p) {
  float rad = 0.8;
  float len = 0.6;
  vec2 torcords = vec2(length(p.xz-vec2(rad,0))-rad, p.y);
  float tor = length(torcords)-(smoothstep(0., len, p.z)*0.03+0.04);
  float stemsurf = -smin(-tor, -length(p)+len, 0.06);
  vec3 stemcords = vec3(atan(torcords.x, torcords.y)*0.1, atan(p.x-rad,p.z), tor);
  globalstemcoords = stemcords;
  return stemsurf;
}

int mat;
float scene(vec3 p) {
  float body = apple(p - vec3(0,0,1.15));
  float stm = stem(erot(p, vec3(0,0,1), -0.8)-vec3(0,0,2));
  float gnd = p.z;
  float appl = min(stm,body);
  if (appl < gnd) {
    mat = 0;
    if (stm < body) {
      mat = 2;
      return stm;
    }
    return appl;
  }
  mat = 1;
  return gnd;
}

float scene_proxy(vec3 p) {
  return min(p.z, min(length(abs(p)-vec3(0,0,1.3))-1., length(abs(p)-vec3(.1,.1,0.5))-0.5));
}

float noise_comp(vec2 p) {
  vec2 id = floor(p);
  p = fract(p);
  float h1 = hash(id.x, id.y);
  float h2 = hash(id.x+1., id.y);
  float h3 = hash(id.x, id.y+1.);
  float h4 = hash(id.x+1., id.y+1.);
  return mix(mix(h1, h2, p.x), mix(h3, h4, p.x), p.y);
}

float noise(vec2 p) {
  float n = 0.;
  for (int i = 0; i < 6; i++) {
    float h1 = hash(float(i), 8.);
    float h2 = hash(h1, float(i));
    float h3 = hash(h2, float(i));
    n += noise_comp(erot(vec3(p*sqrt(float(i+1))/1.5 + vec2(h2, h3)*100.,0), vec3(0,0,1), h1*100.).xy);
  }
  return n/6.;
}

float dots(vec3 p, float scale) {
  float m = 10000.;
  for(int i = 0; i < 10; i++) {
    float ax1 = hash(float(i),68.);
    float ax2 = hash(ax1,float(i));
    float ax3 = hash(ax2,float(i));
    float rot = hash(ax3,float(i));
    float off = hash(rot,float(i));
    vec3 ax = normalize(tan(vec3(ax1, ax2, ax3)));
    vec3 lp = erot(p + off, ax, rot*100.);
    m = min(m, length((fract(lp/scale)-0.5)*scale));
  }
  return m;
}

/*
vec3 norm(vec3 p) {
  mat3 k  = mat3(p,p,p) - mat3(0.001);
  return normalize(scene(p)-vec3(scene(k[0]),scene(k[1]),scene(k[2])));
}*/
// suggested from tdhooper. Thanks!
// improve compilation time & overall fps.
const int NORMAL_STEPS = 6;
vec3 norm(vec3 pos) {
    vec3 eps = vec3(.01, 0, 0);
    vec3 nor = vec3(0);
    float invert = 1.;
    for (int i = 0; i < NORMAL_STEPS; i++) {
        nor += scene(pos + eps * invert) * eps * invert;
        eps = eps.zxy;
        invert *= -1.;
    }
    return normalize(nor);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  vec2 uv = vec2(fragCoord.x / iResolution.x, fragCoord.y / iResolution.y);
  uv -= 0.5;
  uv /= vec2(iResolution.y / iResolution.x, 1);

  vec3 cam = normalize(vec3(2,uv));
  vec3 init = vec3(-9,0,1.1);
  
  float yrot = 0.3;
  float zrot = sin(iTime)*0.4-0.9;
  cam = erot(cam, vec3(0,1,0), yrot);
  init = erot(init, vec3(0,1,0), yrot);
  cam = erot(cam, vec3(0,0,1), zrot);
  init = erot(init, vec3(0,0,1), zrot);
  vec3 p = init;
  bool hit = false;
  for (int i = 0; i < 200 + donttouch; i ++){
    float dist = scene(p);
    if (dist*dist < 1e-6) {
      hit = true;
      break;
    }
    p+=dist*cam;
  }
  vec3 localstemcoords = globalstemcoords;
  int matloc = mat;
  vec3 n = norm(p);
  float ao = sqrt(scene_proxy(p+n*0.5)+0.5);
  ao *= sqrt(scene_proxy(p+n*0.2)/0.2*0.5+0.5);
  ao *= sqrt(scene_proxy(p+vec3(1))/sqrt(2.)*0.5+0.5);
  ao *= sqrt(scene_proxy(p+vec3(.5))/sqrt(2.)+0.55);
  //ao *= smoothstep(0., 0.5, length(p.xy))*0.2+0.8;
  vec3 r = reflect(cam, n);
  float wildness = 3.5;
  float powr = 20.;
  float specmult = 1.5;
  vec3 darkcol;
  vec3 litecol;

  
  float splaty = noise(p.zy*vec2(2,10))*0.3+0.6;
  float splatx = noise(p.zx*vec2(2,10)+100.)*0.3+0.6;
  float splatz = noise(vec2(length(p.xy), atan(p.x,p.y)*5.)+200.)*0.3+0.6;
  float marble = mix(mix(splaty, splatx, abs(n.y)), splatz, abs(n.z));
  if (matloc == 1) {
    darkcol = vec3(0.01);
    litecol = mix(vec3(1.,0.05,0.04), vec3(0.1), smoothstep(-1.2, 1.8, scene_proxy(p+r)/dot(r,n))*0.7+0.5);
  } else if (matloc == 0) {
    litecol = vec3(1.,0.05,0.04);
    litecol = mix(vec3(1.,0.2,0.15), litecol, sqrt(marble*0.5+0.5));
    float d = pow(smoothstep(0.01, 0.06, dots(p, 0.26)), 0.4);
    litecol = mix(vec3(1.1,0.01,0.05), litecol, d);
    litecol = mix(vec3(1.5,0.45,0.2), litecol, pow(d, 0.2));
    litecol *= marble;
    darkcol = litecol*0.02;

    vec3 noffset = vec3(0);
    noffset.x += cos(dot(p, 8.*vec3(3,2,2)));
    noffset.z += cos(dot(p, 8.*vec3(4,1,8)));
    noffset.y += cos(dot(p, 8.*vec3(4,2,2)));
    noffset.z += cos(dot(p, 10.*vec3(5,2,4)));
    noffset.y += cos(dot(p, 10.*vec3(1,1,6)));
    noffset.y += cos(dot(p, 10.*vec3(1,6,2)));
    noffset.x += cos(dot(p, 10.*vec3(2,1,5)));
    noffset.x += cos(dot(p, 10.*vec3(3,6,1)));
    n = normalize(n+noffset*0.01);
  } else {
    float grad = smoothstep(2.56, 2.3, p.z);
    vec2 messscale = vec2(500.,50.);
    float mess = noise(1.5+localstemcoords.xy*messscale);
    float mess2 = noise(1.+localstemcoords.xy*messscale);
    float mess3 = noise(0.5+localstemcoords.xy*messscale);
    float stemmix = cos(localstemcoords.z*90.-0.8)*0.5+0.5;
    n = normalize(n - normalize(tan(vec3(mess,mess2,mess3)))*0.3*(stemmix*0.5+0.5));
    litecol = mix(vec3(0.5,0.07,0.02), vec3(0.4,0.03,0.025), grad);
    litecol = mix(vec3(0.6,0.3,0.2), litecol, stemmix);
    powr = 5.;
    specmult = mix(0.25, 0.1, grad);
    litecol *= marble;
    darkcol = litecol*0.04;
  }
  r = reflect(cam, n);
  float spec = pow(length(sin(r*wildness)*0.5+0.5)/sqrt(3.), powr)*specmult;
  float diff = length(sin(n*wildness)*0.5+0.5)/sqrt(3.)*0.6;
  vec3 diffcol = mix(darkcol, litecol, diff);
  vec3 speccol = vec3(1,0.7,0.7)*spec;
  fragColor.xyz = hit ? ao*(diffcol + speccol) : vec3(0.05);
  fragColor.xyz = sqrt(fragColor.xyz);
  fragColor.xyz = mix(fragColor.xyz, smoothstep(vec3(0),vec3(1), fragColor.xyz), 0.3) + hash(hash(uv.x, uv.y), iTime)*0.02;
}