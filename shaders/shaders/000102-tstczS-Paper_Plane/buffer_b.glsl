// Buffer B (buffer) — Paper Plane by zduny
// https://www.shadertoy.com/view/tstczS

INCLUDE_TEXTURE_GRID_WIDTH

const float pi = 3.1416;
const float epsilon = 0.00001;
const vec3 right = vec3(1.0, 0.0, 0.0);
const vec3 up = vec3(0.0, 1.0, 0.0);
const vec3 forward = vec3(0.0, 0.0, -1.0);

const vec3[] points =
    vec3[](vec3(0.0, -1.3, 0.0), vec3(-1.0, 1.0, 0.0), vec3(-0.21, 1.0, 0.0),
           vec3(0.0, 0.92, -0.4), vec3(0.21, 1.0, 0.0), vec3(0.9, 1.0, 0.0));
const ivec3[] triangles =
    ivec3[](ivec3(0, 1, 2), ivec3(2, 3, 0), ivec3(3, 4, 0), ivec3(4, 5, 0));
const ivec2[] lines =
    ivec2[](ivec2(0, 1), ivec2(0, 2), ivec2(0, 3), ivec2(0, 4), ivec2(0, 5),
            ivec2(1, 2), ivec2(2, 3), ivec2(3, 4), ivec2(4, 5));
const int lengthTriangles = 4;
const int lengthLines = 9;

struct Ray {
  vec3 origin;
  vec3 direction;
};
    
struct Sphere {
  vec3 origin;
  float radius;
};
    
mat4 rotationMatrix(in vec3 axis, in float angle) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;

  return mat4(
      oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,
      oc * axis.z * axis.x + axis.y * s, 0.0, oc * axis.x * axis.y + axis.z * s,
      oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
      oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s,
      oc * axis.z * axis.z + c, 0.0, 0.0, 0.0, 0.0, 1.0);
}

mat4 translationMatrix(in vec3 translation) {
  return mat4(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0,
              translation.x, translation.y, translation.z, 1.0);
}

Ray createRayOrthographic(in vec2 screenPosition) {
  return Ray(vec3(screenPosition, 0.0), vec3(0.0, 0.0, -1.0));
}

vec3 positionOnRay(in Ray ray, in float t) {
  return ray.origin + ray.direction * t;
}

void transformRay(inout Ray ray, mat4 matrix) {
  ray.origin = (matrix * vec4(ray.origin, 1.0)).xyz;
  ray.direction = normalize(matrix * vec4(ray.direction, 0.0)).xyz;
}

bool rayIntersectsSphere(in Ray ray, in Sphere sphere, out float t0,
                         out float t1) {
  float a = dot(ray.direction, ray.direction);
  vec3 s0_r0 = ray.origin - sphere.origin;
  float b = 2.0 * dot(ray.direction, s0_r0);
  float c = dot(s0_r0, s0_r0) - (sphere.radius * sphere.radius);
  float delta = b * b - 4.0 * a * c;
  float a_2 = 2.0 * a;

  if (delta < 0.0) {
    return false;
  }

  float delta_sqrt = sqrt(delta);

  t0 = (-b - delta_sqrt) / a_2;
  t1 = (-b + delta_sqrt) / a_2;

  return true;
}

bool rayIntersectsTriangle(in Ray ray, in vec3 v0, in vec3 v1, in vec3 v2,
                           out float t) {
  vec3 edge1, edge2, h, s, q;
  float a, f, u, v;

  edge1 = v1 - v0;
  edge2 = v2 - v0;

  h = cross(ray.direction, edge2);
  a = dot(edge1, h);

  if (a > -epsilon && a < epsilon)
    return false;

  f = 1.0 / a;
  s = ray.origin - v0;
  u = f * dot(s, h);

  if (u < 0.0 || u > 1.0)
    return false;

  q = cross(s, edge1);
  v = f * dot(ray.direction, q);

  if (v < 0.0 || u + v > 1.0)
    return false;

  // At this stage we can compute t to find out where the intersection point is
  // on the line.
  t = f * dot(edge2, q);
  if (t > epsilon) // ray intersection
  {
    return true;
  }

  // This means that there is a line intersection but not a ray intersection.
  return false;
}

bool rayIntersectsCylinder(in Ray ray, in vec3 pa, in vec3 pb, in float radius, 
                           out float t0, out float t1) {
  vec3 ro = ray.origin;
  vec3 rd = ray.direction;

  vec3 cc = 0.5 * (pa + pb);
  float ch = length(pb - pa);
  vec3 ca = (pb - pa) / ch;
  ch *= 0.5;

  vec3 oc = ro - cc;

  float card = dot(ca, rd);
  float caoc = dot(ca, oc);

  float a = 1.0 - card * card;
  float b = dot(oc, rd) - caoc * card;
  float c = dot(oc, oc) - caoc * caoc - radius * radius;
  float h = b * b - a * c;
  if (h < 0.0)
    return false;
  h = sqrt(h);
  t0 = (-b - h) / a;
  t1 = (-b + h) / a; // exit point

  float y = caoc + t0 * card;

  // body
  if (abs(y) < ch) {
    return true;
  }

  return false;
}

bool rayIntersectsLine(in Ray ray, in vec3 pa, in vec3 pb, in float radius, out float t) {
  float t0, trash;

  t = 100000.0;

  bool i = false;
  if (rayIntersectsSphere(ray, Sphere(pa, radius), t0, trash)) {
    t = t0;
    i = true;
  }

  if (rayIntersectsSphere(ray, Sphere(pb, radius), t0, trash) && t0 < t) {
    t = t0;
    i = true;
  }

  if (rayIntersectsCylinder(ray, pa, pb, radius, t0, trash) && t0 < t) {
    t = t0;
    i = true;
  }

  return i;
}


vec4 trace(in Ray ray, int i) {
  vec4 color = vec4(0.0);  
    
  float total = float(textureGridWidth * textureGridWidth - 2);
  float angle = float(i - 1) / total - 0.5;  
    
  mat4 transform = rotationMatrix(up, 0.0) *
                   rotationMatrix(forward, angle * 2.2) *
                   rotationMatrix(right, -0.6) *
                   translationMatrix(vec3(0.0, 0.0, 12.0));
  transformRay(ray, transform);  
    
  float t0 = 100000.0;
  for (int i = 0; i < lengthTriangles; i++) {
    ivec3 triangle = triangles[i];
    vec3 a = points[triangle[0]];
    vec3 b = points[triangle[1]];
    vec3 c = points[triangle[2]];

    float t;
    if (rayIntersectsTriangle(ray, a, b, c, t) && t < t0) {
      t0 = t - 0.0;
      color = vec4(1.0);
    }
  }

  for (int i = 0; i < lengthLines; i++) {
    ivec2 line = lines[i];
    vec3 a = points[line[0]];
    vec3 b = points[line[1]];

    float t;
    vec3 normal;
    if (rayIntersectsLine(ray, a, b, 0.04, t) && t < t0) {
      t0 = t;
      color = vec4(vec3(0.0), 1.0);
    }
  } 
    
  return color;
}

vec4 drawPipe(in vec2 position) {
  float offset = position.x < 0.0 ? 0.17 : 0.0;
 
  if (position.x > 0.8) {
    return vec4(0.0);
  }
 
  if (abs(position.y) < 0.9 - offset) {
    if ((abs(position.y) < 0.8 - offset) && 
        !(position.x > 0.0 && position.x < 0.1) && 
        (position.x < 0.7)) {
      float y = position.y + offset * 0.97;
      vec3 color = vec3(0.458, 0.835, 0.184);
      color = y > 0.57 && y < 0.73 ? vec3(0.803, 0.964, 0.505) : color;
      color = y > 0.45 && y < 0.53 ? vec3(0.740, 0.940, 0.442) : color;
      color = y > 0.37 && y < 0.4 ? vec3(0.658, 0.935, 0.284) : color;
      y = position.y - offset * 0.9;
      color = y < -0.55 && y > -0.8 ? vec3(0.380, 0.734, 0.145) : color;
      color = y < -0.7 && y > -0.8 ? vec3(0.280, 0.634, 0.145) : color;
      
      return vec4(toLinear(color), 1.0);
    }
    
    return vec4(toLinear(vec3(0.233, 0.227, 0.247)), 1.0);
  }
  
  return vec4(0.0);
}

vec4 takeSample(in vec2 position) {
  float size = iResolution.y / float(textureGridWidth);
  ivec2 xy = ivec2(position / size);
  position = mod(position, size); 
  position -= vec2(0.5 * size);
  position /= size * 0.33;
    
  int i = xy.x + xy.y * textureGridWidth;
  if (i == 0) {
    position *= 1.2;
    return drawPipe(position);
  } else {
    Ray ray = createRayOrthographic(position);
    return trace(ray, i);
  }
}

bool resolutionChanged() {
  vec4 resolutionData = loadVariable(resolutionLocation);
  return resolutionData.xy != resolutionData.zw;
}


INCLUDE_SUPER_SAMPLE_FUNCTION(superSample, AA_16, takeSample)

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  if (iFrame > 0 && !resolutionChanged()) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel1, uv);
    return;
  }   
    
  if (fragCoord.x > iResolution.y) {
    fragColor = vec4(0.0);
    return;
  }
    
  fragColor = superSample(fragCoord);
}