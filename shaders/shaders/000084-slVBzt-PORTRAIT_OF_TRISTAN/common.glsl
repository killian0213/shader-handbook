// Common (common) — PORTRAIT OF TRISTAN by alro
// https://www.shadertoy.com/view/slVBzt

/*
    Copyright (c) 2024 al-ro

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE. THE SOFTWARE.
*/

#define FOV 40.0
#define CAMERA_DIST 3.5

#define PI 3.14159
#define TWO_PI 6.283185
#define FOUR_PI 12.56637
#define HALF_PI 1.570795

// Minimum dot product value
const float minDot = 1e-3;

// Clamped dot product
float dot_c(vec3 a, vec3 b){
	return max(dot(a, b), minDot);
}

float saturate(float x){
	return clamp(x, 0.0, 1.0);
}


vec3 saturate(vec3 x){
	return clamp(x, 0.0, 1.0);
}

float remap(float x, float low1, float high1, float low2, float high2){
	return low2 + (x - low1) * (high2 - low2) / (high1 - low1);
}


// https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
// Compute the near and far intersections using the slab method.
// No intersection if tNear > tFar.
vec2 intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return vec2(tNear, tFar);
}

bool insideAABB(vec3 p, vec3 boxMin, vec3 boxMax){
    float eps = 1e-4;
	return  (p.x > boxMin.x-eps) && (p.y > boxMin.y-eps) && (p.z > boxMin.z-eps) && 
			(p.x < boxMax.x+eps) && (p.y < boxMax.y+eps) && (p.z < boxMax.z+eps);
}

bool testAABB(vec3 org, vec3 dir, vec3 boxMin, vec3 boxMax, out float distToStart){
	vec2 intersections = intersectAABB(org, dir, boxMin, boxMax);
	
    if(insideAABB(org, boxMin, boxMax)){
        intersections.x = 1e-4;
    }
    
    bool hitsAABB = intersections.x > 0.0 && (intersections.x < intersections.y);
    
    distToStart = hitsAABB ? intersections.x : 1e10;
    return hitsAABB;
}

//-------------------------------- Camera --------------------------------

vec3 rayDirection(float fieldOfView, vec2 fragCoord, vec2 resolution) {
    vec2 xy = fragCoord - resolution.xy / 2.0;
    float z = (0.5 * resolution.y) / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

// https://www.geertarien.com/blog/2017/07/30/breakdown-of-the-lookAt-function-in-OpenGL/
mat3 lookAt(vec3 camera, vec3 at, vec3 up){
  vec3 zaxis = normalize(at-camera);    
  vec3 xaxis = normalize(cross(zaxis, up));
  vec3 yaxis = cross(xaxis, zaxis);

  return mat3(xaxis, yaxis, -zaxis);
}

mat4 lookAt4(vec3 camera, vec3 at, vec3 up){
  vec3 zaxis = normalize(at-camera);    
  vec3 xaxis = normalize(cross(zaxis, up));
  vec3 yaxis = cross(xaxis, zaxis);
  
  return mat4(vec4(xaxis, 0.0), vec4(yaxis, 0.0), vec4(-zaxis, 0.0), vec4(camera, 1.0));
}

//-------------------------------- Rotations --------------------------------

vec3 rotate(vec3 p, vec4 q){
  return 2.0 * cross(q.xyz, p * q.w + cross(q.xyz, p)) + p;
}
vec3 rotateX(vec3 p, float angle){
    return rotate(p, vec4(sin(angle/2.0), 0.0, 0.0, cos(angle/2.0)));
}
vec3 rotateY(vec3 p, float angle){
	return rotate(p, vec4(0.0, sin(angle/2.0), 0.0, cos(angle/2.0)));
}
vec3 rotateZ(vec3 p, float angle){
	return rotate(p, vec4(0.0, 0.0, sin(angle), cos(angle)));
}

//---------------------------- Operations ----------------------------

vec4 opElongate( in vec3 p, in vec3 h ){ 
    vec3 q = abs(p)-h;
    return vec4( max(q,0.0), min(max(q.x,max(q.y,q.z)),0.0) );
}

float opSmoothSub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}
    
float opSmoothIntersection( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h); 
}

float opSmoothMin(float a, float b, float k){
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//---------------------------- Distance functions ----------------------------

// https://iquilezles.org/articles/distfunctions
float sdRoundCone( vec3 p, float r1, float r2, float h ){
  vec2 q = vec2( length(p.xz), p.y );
    
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(q,vec2(-b,a));
    
  if( k < 0.0 ) return length(q) - r1;
  if( k > a*h ) return length(q-vec2(0.0,h)) - r2;
        
  return dot(q, vec2(a,b) ) - r1;
}

float sdCapsule( vec3 p, float r, float h ){
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

float sdBox( vec3 p, vec3 b ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdEllipsoid( vec3 p, vec3 r ){
  float k0 = length(p/r);
  float k1 = length(p/(r*r));
  return k0*(k0-1.0)/k1;
}

float sdCappedTorus(vec3 p, vec2 sc, float ra, float rb){
  p.x = abs(p.x);
  float k = (sc.y*p.x>sc.x*p.y) ? dot(p.xy,sc) : length(p.xy);
  return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}

float getPupilSDF(vec3 p){
    vec3 q = p;
    q.x += 0.92;
    q.z = abs(q.z);
    q.z -= 0.255;
    q.y += 0.279;
    return sphereSDF(q, 0.057);
}

float getEyeballSDF(vec3 p){
    
    vec3 q = p;
    
    q.x += 0.74;
    q.z = abs(q.z);
    q.z -= 0.255;
    q.y += 0.258;
    
    float d = sphereSDF(q, 0.14);
    
    d = opSmoothSub(getPupilSDF(p), d, 0.015);
    
    return d;
    
}

float getEyesSDF(vec3 p, float dist){
    // Top lid
    float dist_t = 100.0;
    vec3 q = p;
    q.z = abs(q.z);
    q += vec3(0.7, 0.245, -0.25);

    q = rotateY(q, -0.15);
    dist_t = sphereSDF(q, 0.19);
    
    q += vec3(0.22, 0.25, 0.01);
    dist_t = opSmoothSub(sphereSDF(q, 0.25), dist_t, 0.01);
    q += vec3(0.0, -0.13, 0.015);
    dist_t = opSmoothSub(sphereSDF(q, 0.13), dist_t, 0.015);
    
    // Bottom lid
    float dist_b = dist_t;
    q = p;
    q.z = abs(q.z);
    q += vec3(0.695, 0.25, -0.245);
    q = rotateY(q, -0.1);
    q = rotateX(q, 0.09);
    dist_b = sphereSDF(q, 0.195);
    
    q.x += 0.1;
    q.y -= 0.115;
    
    dist_b = opSmoothSub(sphereSDF(q, 0.2), dist_b, 0.012);
    
    // Combine
    dist_t = opSmoothMin(dist_t, dist_b, 0.005);

    // Space for eyeball
    q = p;
    q.x += 0.74;
    q.z = abs(q.z);
    q.z -= 0.255;
    q.y += 0.258;
    
    dist_t = opSmoothSub(sphereSDF(q, 0.14), dist_t, 0.0025);
    
    // Add to scene
    dist = opSmoothMin(dist_t, dist, 0.01);
    
    // Tear duct
    q = p;
    q.z = abs(q.z);
    q += vec3(0.835, 0.3, -0.12);
    q = rotateX(q, -0.4 * PI);
    q = rotateZ(q, -0.0 * PI);
    dist = opSmoothSub(sdCapsule(q, 0.001, 0.05), dist, 0.035);
    
    q = p;
    q.z = abs(q.z);
    q += vec3(0.795, 0.3, -0.12);
    q = rotateX(q, -0.4 * PI);
    q = rotateZ(q, -0.1 * PI);
    dist = opSmoothMin(sdCapsule(q, 0.015, 0.05), dist, 0.01);
    
    return dist;
}



//------------------------- Collar -------------------------

vec2 radialRepetition(vec2 p, float cells){
    float an = TWO_PI/cells;
    float fa = (atan(p.y,p.x)+an*0.5)/an;
    float sym = an*floor(fa);
    p.xy = mat2(cos(sym),-sin(sym), sin(sym), cos(sym))*p.xy;
    return p;
}

float collarSDF(vec3 p){

    float dist = 1e5;
    vec3 q = p;
    
    q.y += 1.5;
    q.x -= 0.2;
    q = rotateZ(q, -0.2);

    q.xz = radialRepetition(q.xz, 64.0);
    
    q = rotateZ(q, 0.5);
    
    q.y -= 0.7;
    q = rotateZ(q, 0.9);
    dist = opSmoothMin(dist, sdRoundCone(q, 0.07, 0.1, 0.5), 0.0);
    
    return dist;
}
