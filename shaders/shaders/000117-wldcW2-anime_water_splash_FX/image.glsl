// Image (image) — anime water splash FX by morimea
// https://www.shadertoy.com/view/wldcW2


// Created by Danil (2021+) https://github.com/danilw

// just following youtube video tutroial
// original video https://youtu.be/zZsfr5f273c

// (in this shader just setting voronoi parameters to make it look like on
// video)

// License Mit license

// helper-functions for noise in Common

// using https://www.shadertoy.com/view/ldB3zc
// using https://www.shadertoy.com/view/XdXGW8
// using https://www.shadertoy.com/view/4sfGzS

// using iq's intersectors:
// https://iquilezles.org/articles/intersectors

#define AA 2

#define cloud_steps 16

const vec3 bgcol = vec3(0x06, 0xb6, 0xf3) / float(0xff);
const vec3 white = vec3(0xd1, 0xee, 0xf5) / float(0xff);
const vec3 blue = vec3(0x01, 0x8e, 0xc6) / float(0xff);

// mix two voronoi layers and ring
float get_voronoi_texture(vec2 p, float fade, float time) {
  vec2 op = p;

  // two voronoi
  p = ToPolar(p) * 01.175;
  p.y += -time * 0.51;
  p.x = abs(p.x) * 4.;
  vec2 td = voronoi(p * vec2(2.5, 1.185), 0.51, time * .1);
  vec2 td2 = voronoi(p * vec2(1.5, 1.185), 0.51, time * .05);
  td *= td2;

  // rings
  // adding rings to voronoi
  time += -0.35;
  p = op;
  p *= 0.05;
  float d = noise2(p * 4. + time * 0.51 * 0.05 * 8.);
  d = (fade * 0.235 +
       abs(mod(length(p) + 0.07 * d - time * 0.51 * 0.05 * 2., 0.15) - 0.075));
  float a = 1. - smoothstep(0.4485, 0.4485 + 0.005, td.y * .855 + d);

  td.y = min(td.y + fade * 15., 1.);
  float b = 1. - smoothstep(0.4785, 0.4785 + 0.005, td.y);

  return max(a, b);
}

// rings
// mix voronoy noise and rings
float get_rings(vec2 p, float val, float time, float fade) {
  vec2 op = p;

  // one leayer of voronoi
  p = ToPolar(p) * 01.5;
  p.y += -time * 0.51;
  p.x = abs(p.x) * .125;
  vec2 td = voronoi(p * vec2(2.5, 1.185), 0.51, time * .1);
  td.x = 1. - smoothstep(val, val + 0.005, td.x + fade);

  // rings
  p = op;
  p *= 0.05;
  float d = noise2(p * 4. + time * 0.51 * 0.05 * 8.);
  d = (1. - smoothstep(0.01, 0.015,
                       fade * 0.5 + abs(mod(length(p) + 0.07 * d -
                                                time * 0.51 * 0.05 * 2.,
                                            0.15) -
                                        0.075)));
  return td.x * d;
}

// floor texture
vec4 get_color_floor(vec2 p, vec3 sunDir, vec3 nor) {
  float d = 0.;
  float time = iTime * 2.5;
  float fade = smoothstep(0.3, .845, length(p * 0.05));
  fade = max(fade, 1. - (smoothstep(-0.075, 0.15, length(p * 0.05))));

  d = get_voronoi_texture(p, fade, time);
  d = min(d + get_rings(p, 0.73, time, fade) +
              get_rings(p, 0.3, time * 0.75, fade),
          1.);

  return vec4(mix(blue * (max(dot(nor, sunDir), 0.0) + 0.05), white, d), 1.);
}

// cylinder on middle - blending two 180-rot noises to make seam not visible
vec4 get_colorCylinder(vec3 pos, float heigh) {
  mat2 px;
  px[0] =
      0.5 + vec2(atan(pos.z, pos.x) / (3.1415926 * 2.), pos.y * .5 / heigh);
  px[1] =
      0.5 + vec2(atan(-pos.z, -pos.x) / (3.1415926 * 2.), pos.y * .5 / heigh);
  mat2 dx;vec2 op=px[0];
  for(int i=0;i<2;i++){
      float time = iTime;
      px[i].y += time * 0.51;
      px[i] *= 5.;
      vec2 td = voronoi(px[i] * vec2(2.5, 1.185), 0.51, time * .1);
      px[i].y += time * 0.51;
      vec2 td2 = voronoi(px[i] * vec2(2.5, 1.185), 0.51, (time)*.1);
      td *= td2;
      dx[i].x=td.y;dx[i].y=td2.y;
    }
  vec2 td = mix(dx[0],dx[1],vec2(smoothstep(0.,0.15,abs((op.x-0.5)*2.))));
  //vec2 td = dx[0]; // seam on left from camera start
  float d = max((1. - smoothstep(0.476, 0.476 + 0.005, td.x)),
      (1. - smoothstep(0.685, 0.685 + 0.005, td.y)));
  return vec4(mix(blue, white, d), 1.);
}

// cloud SDF
// this made only for this shader, do not use it in real time, it slow

vec2 sdf(vec3 p) {
  vec3 p2 = p + vec3(0., 1.8, 0.) * iTime;
  
  float plane = dot(p + vec3(0, -0.34, 0), vec3(0., 1., 0.));
  float sphere = length(p * vec3(1., 1.25, 1.) + vec3(0.)) - 1.949;
  float sphere2 = length(p * vec3(1., 2.75, 1.) + vec3(0.)) - 2.1949;
  sphere = min(sphere, sphere2);
  float sphere3 = length(p + vec3(0., -1.5, 0.0)) - 1.219;
  float d =
      max(max(sphere, -sphere3), -plane);

  float f = fbm(p2) - 0.8;
  float td = mix(d, f, .372);
  if (td < sphere3)
    return vec2(td, 1);
  else
    return vec2(td, 2);
}

vec3 materialCloud(float d) {

  float result = 1.;
  float depth = 0.21;
  float minlight = 0.31;
  result = min(result, (d * 2.6 / depth) + minlight);
  if (d < 0.00001) {
    result = minlight;
  }
  return clamp(mix(blue * 0.465, (white)*3.515, result * (result + result)), 0.,
               1.);
}

// ignore AA in sdf
#if AA > 1
bool once = false;
vec4 col_once = vec4(0.);
#endif

vec4 get_colorSphere(vec3 ro, vec3 rd, vec3 bg) {
#if AA > 1
  if (once)
    return col_once;
#endif
  float ratio = 1.0;
  vec3 cloud = bg;

  float depth = 0.;
  for (int I = 0; I < cloud_steps; ++I) {

    vec3 p = ro + rd * depth;
    if (depth > 100.) {
      break;
    }
    vec2 ss = sdf(p);

    if (ss.x < 0.015) {
      if (int(ss.y) == 1) {
        ratio = min(ratio, 0.9);
        vec3 l = materialCloud(ss.x);
        cloud = mix(cloud, l, ratio);
        ratio *= .7;
        if (ratio < 0.0001) {
          break;
        }
        depth += ss.x;
      }
    } else {
      depth += max(ss.x, 0.01);
    }
  }

#if AA > 1
  col_once = vec4(cloud, 1.);
  once = true;
#endif

  return vec4(cloud, 1.);
}



// other code is intersection scene

vec3 l1Pos = vec3(0.0, 5.0, 0.0);

#define MAX_DIST 1000.
#define MIN_DIST 0.

#define OBJ_NONE 0
#define OBJ_SPH 1
#define OBJ_FLOOR 2
#define OBJ_CYL 3

#define load(P) texelFetch(iChannel0, ivec2(P), 0)

const ivec2 RES_LAST = ivec2(0, 0);
const ivec2 INIT = ivec2(0, 1);
const ivec2 TARGET = ivec2(0, 2);

const ivec2 POSITION = ivec2(1, 0);
const ivec2 POSITION_last = ivec2(1, 1);

const ivec2 VMOUSE = ivec2(2, 0);
const ivec2 VMOUSE_last = ivec2(2, 1);

const ivec2 INPUT = ivec2(3, 0);
const ivec2 PMOUSE = ivec2(3, 1);

struct Ray {
  vec3 pos;
  vec3 dir;
};

void SetCamera(vec2 uv, out vec3 ro, out vec3 rd)
{
    ro = load(POSITION).xyz;
    vec2 m = load(VMOUSE).xy;
    m.y = -m.y;
    float fov=70.;
    float aspect = iResolution.x / iResolution.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    rd = vec3(uv*screenSize, 1./aspect);
    
    rd = normalize(rd);
    mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
    mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));

    rd = (rotY * rotX) * rd;
}

bool PlaneIntersect(vec4 Plane, vec3 ro, vec3 rd, out float t, out vec3 norm) {
  norm = vec3(0., 1., 0.);
  t = -1.;
  float dd = dot(rd, Plane.xyz);
  if (dd == 0.0)
    return false;
  float t1 = -(dot(ro, Plane.xyz) + Plane.w) / dd;
  if (t1 < 0.0)
    return false;
  norm = normalize(Plane.xyz);
  t = t1;
  return true;
}

bool SphereIntersect(vec3 SpPos, float SpRad, vec3 ro, vec3 rd, out float t,
                     out vec3 norm) {
  ro -= SpPos;

  float A = dot(rd, rd);
  float B = 2.0 * dot(ro, rd);
  float C = dot(ro, ro) - SpRad * SpRad;
  float D = B * B - 4.0 * A * C;
  t = -1.;
  norm = vec3(0., 1., 0.);
  if (D < 0.0)
    return false;

  D = sqrt(D);
  A *= 2.0;
  float t1 = (-B + D) / A;
  float t2 = (-B - D) / A;
  if (t1 < 0.0)
    t1 = t2;
  if (t2 < 0.0)
    t2 = t1;
  t1 = min(t1, t2);
  if (t1 < 0.0)
    return false;
  norm = ro + t1 * rd;
  t = t1;
  norm = normalize(norm);
  return true;
}

bool CylinderIntersect(in vec3 ro, in vec3 rd, in float ra, in float heigh,
                       out float tN, out vec3 norm) {
  vec3 pa = vec3(0., heigh, 0.);
  vec3 pb = vec3(0., -heigh, 0.);
  vec3 ba = pb - pa;

  norm = vec3(0., 1., 0.);
  tN = -1.;

  vec3 oc = ro - pa;

  float baba = dot(ba, ba);
  float bard = dot(ba, rd);
  float baoc = dot(ba, oc);

  float k2 = baba - bard * bard;
  float k1 = baba * dot(oc, rd) - baoc * bard;
  float k0 = baba * dot(oc, oc) - baoc * baoc - ra * ra * baba;

  float h = k1 * k1 - k2 * k0;
  if (h < 0.0)
    return false;
  h = sqrt(h);
  float t = (-k1 - h) / k2;
  if (t < 0.0)
    return false;

  float y = baoc + t * bard;
  if (y > 0.0 && y < baba) {
    tN = t;
    norm = (oc + t * rd - ba * y / baba) / ra;
    return true;
  }

  t = (((y < 0.0) ? 0.0 : baba) - baoc) / bard;
  if (abs(k1 + k2 * t) < h) {
    tN = t;
    norm = ba * sign(y) / baba;
    return true;
  }

  return false;
}

struct HitInfo {
  float t;
  vec3 norm;
  vec4 color;
  int obj_type;
};

void GroundIntersectMin(vec3 ro, vec3 rd, inout bool result,
                        inout HitInfo hit) {
  float tnew = -1.;
  vec3 normnew = vec3(0., 1., 0.);
  vec4 pp = vec4(0., 1., 0., 0.);
  if (PlaneIntersect(pp, ro, rd, tnew, normnew)) {
    if (tnew < hit.t) {
      hit.t = tnew;
      hit.norm = normnew;
      hit.obj_type = OBJ_FLOOR;
      vec3 p = (ro + rd * tnew);
      if (any(greaterThan(abs(p.xz * 0.05), vec2(.65)))) {

      } else {
        hit.color = get_color_floor(p.xz, normalize(l1Pos - p), hit.norm);
        result = true;
      }
    }
  }
}

void SphereIntersectMin(vec3 SpPos, float SpRad, vec3 ro, vec3 rd,
                        inout bool result, inout HitInfo hit) {
  float tnew;
  vec3 normnew;
  if (SphereIntersect(SpPos, SpRad, ro, rd, tnew, normnew)) {
    if (tnew < hit.t) {
      vec3 p = (ro + rd * tnew);
      hit.color = get_colorSphere(ro, rd, hit.color.rgb);
      hit.obj_type = OBJ_SPH;
      hit.t = tnew;
      hit.norm = normnew;
      result = true;
    }
  }
}

void CylinderIntersectMin(vec3 ro, vec3 rd, float rad, float heigh, vec3 pos,
                          inout bool result, inout HitInfo hit) {
  float tnew;
  vec3 normnew;
  ro -= pos;
  if (CylinderIntersect(ro, rd, rad, heigh, tnew, normnew)) {
    if (tnew < hit.t) {
      hit.t = tnew;
      hit.norm = normnew;
      vec3 pos = (ro + rd * hit.t);
      hit.color = get_colorCylinder(pos, heigh);
      hit.obj_type = OBJ_CYL;
      result = true;
    }
  }
}

bool minDist(vec3 ro, vec3 rd, out HitInfo hit) {
  hit.t = MAX_DIST;
  hit.color = vec4(bgcol.rgb, 1.);
  bool result = false;

  GroundIntersectMin(ro, rd, result, hit);
  CylinderIntersectMin(ro, rd, 1.2, 5., vec3(0., 4.99, 0.), result, hit);
  SphereIntersectMin(vec3(0.), 2.5, ro, rd, result, hit);

  return result;
}

const float eps = 1e-3;

vec3 render(Ray r) {
  vec3 col = vec3(0.0);
  vec3 objectcolor = vec3(1.0);
  vec3 mask = vec3(1.0);
  HitInfo hit;
  {
    if (minDist(r.pos, r.dir, hit)) {
      objectcolor = hit.color.rgb;
      vec3 p = r.pos + r.dir * hit.t + hit.norm * eps;
      // vec3 sunDir = normalize(l1Pos-p);
      col = objectcolor;
      // col = objectcolor * (vec3(max(dot(hit.norm,sunDir),0.0)) + 0.05);
    } else
      col = bgcol;
  }
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec3 ret_col = vec3(0.0);
#if AA > 1
  for (int mx = 0; mx < AA; mx++)
    for (int nx = 0; nx < AA; nx++) {
      vec2 o = vec2(float(mx), float(nx)) / float(AA) - 0.5;
      vec2 uv = (fragCoord + o) / iResolution.xy * 2.0 - 1.0;
#else
  vec2 uv = fragCoord / iResolution.xy * 2.0 - 1.0;
#endif
      uv.y *= iResolution.y / iResolution.x;
      vec3 ro; vec3 rd;
      SetCamera(uv, ro, rd);
      vec3 col = render(Ray(ro, rd));
      ret_col += col;
#if AA > 1
    }
  ret_col /= float(AA * AA);
#endif
  ret_col = pow(ret_col, vec3(0.85));
  fragColor = vec4(ret_col, 1.0);
}
