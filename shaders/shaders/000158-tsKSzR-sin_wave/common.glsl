// Common (common) — sin_wave by skaplun
// https://www.shadertoy.com/view/tsKSzR

struct Box{ vec3 origin; vec3 bounds;};
struct Ray{ vec3 origin, dir;};
struct HitRecord{vec2 dist;vec3 ptnt[2];};
struct Plane{ vec3 origin; vec3 normal;};


vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.;
    float z = size.y / tan(radians(fieldOfView) / 2.);
    return normalize(vec3(xy, -z));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye),
         s = normalize(cross(f, up)),
         u = cross(s, f);
    return mat4(vec4(s, 0.), vec4(u, 0.), vec4(-f, 0.), vec4(vec3(0.), 1.));
}

mat3 calcLookAtMatrix(in vec3 camPosition, in vec3 camTarget, in float roll) {
  vec3 ww = normalize(camTarget - camPosition);
  vec3 uu = normalize(cross(ww, vec3(sin(roll), cos(roll), 0.0)));
  vec3 vv = normalize(cross(uu, ww));

  return mat3(uu, vv, ww);
}