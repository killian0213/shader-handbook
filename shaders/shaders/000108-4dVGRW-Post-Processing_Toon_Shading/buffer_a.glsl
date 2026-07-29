// Buf A (buffer) — Post-Processing: Toon Shading by hughsk
// https://www.shadertoy.com/view/4dVGRW

float sdBox( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

vec2 mirror(vec2 p, float v) {
  float hv = v * 0.5;
  vec2  fl = mod(floor(p / v + 0.5), 2.0) * 2.0 - 1.0;
  vec2  mp = mod(p + hv, v) - hv;
    
  return fl * mp;
}

vec2 rotate2D(vec2 p, float a) {
  return p * mat2(cos(a), -sin(a), sin(a),  cos(a));
}

float map(vec3 p) {
  float r = iMouse.z > 0.0 ? iMouse.x / 100.0 : iTime * 0.9;
  p.xz = mirror(p.xz, 4.);
  p.xz = rotate2D(p.xz, r);
  float d = sdBox(p, vec3(1));
  d = min(d, sdBox(p, vec3(0.1, 0.1, 3)));
  d = min(d, sdBox(p, vec3(3, 0.1, 0.1)));
  return d;
}

mat3 calcLookAtMatrix(vec3 origin, vec3 target, float roll) {
  vec3 rr = vec3(sin(roll), cos(roll), 0.0);
  vec3 ww = normalize(target - origin);
  vec3 uu = normalize(cross(ww, rr));
  vec3 vv = normalize(cross(uu, ww));

  return mat3(uu, vv, ww);
}

vec3 getRay(vec3 origin, vec3 target, vec2 screenPos, float lensLength) {
  mat3 camMat = calcLookAtMatrix(origin, target, 0.0);
  return normalize(camMat * vec3(screenPos, lensLength));
}

float calcRayIntersection(vec3 rayOrigin, vec3 rayDir, float maxd, float precis) {
  float latest = precis * 2.0;
  float dist   = +0.0;
  float type   = -1.0;
  float res    = -1.0;

  for (int i = 0; i < 30; i++) {
    if (latest < precis || dist > maxd) break;

    float result = map(rayOrigin + rayDir * dist);

    latest = result;
    dist  += latest;
  }

  if (dist < maxd) {
    res = dist;
  }

  return res;
}

vec2 squareFrame(vec2 screenSize, vec2 coord) {
  vec2 position = 2.0 * (coord.xy / screenSize.xy) - 1.0;
  position.x *= screenSize.x / screenSize.y;
  return position;
}

vec3 calcNormal(vec3 pos, float eps) {
  const vec3 v1 = vec3( 1.0,-1.0,-1.0);
  const vec3 v2 = vec3(-1.0,-1.0, 1.0);
  const vec3 v3 = vec3(-1.0, 1.0,-1.0);
  const vec3 v4 = vec3( 1.0, 1.0, 1.0);

  return normalize( v1 * map( pos + v1*eps ) +
                    v2 * map( pos + v2*eps ) +
                    v3 * map( pos + v3*eps ) +
                    v4 * map( pos + v4*eps ) );
}

vec3 calcNormal(vec3 pos) {
  return calcNormal(pos, 0.002);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 uv = squareFrame(iResolution.xy, fragCoord.xy);
  vec3 ro = vec3(sin(iTime * 0.2), 1.5, cos(iTime * 0.2)) * 5.;
  vec3 ta = vec3(0, 0, 0);
  vec3 rd = getRay(ro, ta, uv, 2.0);
    
  float t = calcRayIntersection(ro, rd, 20.0, 0.001);
  vec3 pos = ro + rd * t;
  vec3 nor = calcNormal(pos);
    
  fragColor = vec4(nor, t);
}