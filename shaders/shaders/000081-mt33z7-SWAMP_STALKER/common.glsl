// Common (common) — SWAMP STALKER by alro
// https://www.shadertoy.com/view/mt33z7

/*
    Copyright (c) 2023 al-ro

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
    SOFTWARE.
*/

const vec3 modelOffset = vec3(-0.5, 0.5, 0);

// Size of canvas that renders interior and is then stretched across the whole view.
// Reduce at full screen
// Between 0 and 1
#define RENDER_SCALE (iResolution.x < 2048.0 ? 1.0 : 0.5)

#define PI 3.14159
#define TWO_PI (2.0 * PI)
#define HALF_PI (0.5 * PI)

#define GAMMA 2.2
#define INV_GAMMA (1.0/GAMMA)

//  Variable iterator initializer to stop loop unrolling
#define ZERO (min(iFrame,0))

// Minimum dot product value
const float minDot = 1e-3;

// Clamped dot product
float dot_c(vec3 a, vec3 b){
	return max(dot(a, b), minDot);
}

vec3 gamma(vec3 col){
	return pow(col, vec3(INV_GAMMA));
}

float saturate(float x){
    return max(0.0, min(x, 1.0));
}

//-------------------------- AABB -------------------------

// Only evaluate the distance function when near a feature or when looking at it.
// This improves performance as we skip complex distance calculations for many pixels.

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

bool testAABB(vec3 org, vec3 dir, vec3 boxMin, vec3 boxMax){
	vec2 intersections = intersectAABB(org, dir, boxMin, boxMax);
	
    if(insideAABB(org, boxMin, boxMax)){
        intersections.x = 1e-4;
    }
    
    return intersections.x > 0.0 && (intersections.x < intersections.y);
}

vec3 getEnvironment(vec3 dir){
    return mix(0.5*vec3(0.5, 0.3, 0.1), 0.5*vec3(0.09, 0.81, 0.35), 0.5+0.5*dir.y);
}


//-------------------------- Lights -------------------------

vec3 getLightPosition(int i){

    float offset = -1.0;

    if(i == 0){
        return vec3(30.0*cos(offset+0.2), 8.0, -30.0*sin(offset+0.2)); 
    }
    return vec3(20.0*cos(3.2+offset), 1.0,  -20.0*sin(3.2+offset));
}

//---------------------------- Camera -----------------------------

vec3 rayDirection(float fieldOfView, vec2 fragCoord, vec2 resolution) {
    vec2 xy = fragCoord - resolution / 2.0;
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

//---------------------------- Operations -----------------------------

float smoothSub( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h); 
}

// https://iquilezles.org/articles/smin
float smoothMin(float a, float b, float k){
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//---------------------- Distance functions ----------------------
//https://iquilezles.org/articles/distfunctions/

float sphereSDF(vec3 p, float radius) {
    return length(p) - radius;
}
