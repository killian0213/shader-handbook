// Common (common) — HEAVENLY CREATURE by alro
// https://www.shadertoy.com/view/ddyBRy

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


#define PI 3.14159
#define TWO_PI (2.0 * PI)

// Side length of domain
// Max 184 as we use 4 channnels of a 1024 cubemap
// For single channel data the max would be 293
const uint width = 184u;
const uint maxIdx = width * width * width;
const vec3 scale = vec3(width);

// For light ray density marching
// Restart to see effects after change
const uint lightSteps = 32u;
const float lightRayDistance = float(width);
const float stepL = lightRayDistance / float(lightSteps);
const vec3 sunDirection = normalize(vec3(0, 1, -0.5));


float saturate(float x){
	return clamp(x, 0.0, 1.0);
}

float remap(float x, float low1, float high1, float low2, float high2){
	return low2 + (x - low1) * (high2 - low2) / (high1 - low1);
}

vec3 remap(vec3 x, vec3 low1, vec3 high1, vec3 low2, vec3 high2){
	return low2 + (x - low1) * (high2 - low2) / (high1 - low1);
}

// https://www.shadertoy.com/view/4djSRW
vec3 hash33(vec3 p3){
	p3 = fract(p3 * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);
}

// ----------------- Data lookup -----------------

vec3 idxToPoint(uint idx){
    return min(scale, vec3(idx % width, 
                           uint(float(idx)/float(width)) % width, 
                           uint(float(idx)/float(width * width))));
}

uint pointToIdx(vec3 p){
    p = clamp(p, vec3(0), scale-1.0);
    return uint(p.z * float(width * width) + p.y * float(width) + p.x);
}

vec3 idxToDir(uint idx){
       
    uint face = uint(float(idx)/float(1024u * 1024u));
    vec2 fragCoord = vec2(idx % 1024u, uint(float(idx)/float(1024u)) % 1024u) + 0.5;
    vec2 uv = 2.0 * (fragCoord/1024.0) - 1.0;

    vec3 rayDir;
    switch(face){
        case 0u: rayDir = vec3( 1,  -uv.yx); break;
        case 1u: rayDir = vec3(-1,  -uv.y, uv.x); break;
        case 2u: rayDir = vec3(uv.x,   1,  uv.y); break;
        case 3u: rayDir = vec3(uv.x,  -1,  -uv.y); break;
        case 4u: rayDir = vec3(uv.x, -uv.y,  1); break;
        case 5u: rayDir = vec3(-uv,  -1);  break;
    }

    return rayDir;
}

vec4 getDataInterpolated(vec3 p, samplerCube s){
    p += vec3(0.5 * scale);
    p = clamp(p, vec3(0), scale-1.0);

    vec3 f = fract(p);
    vec3 c = floor(p);
            
    return mix( mix(  mix(texture(s, idxToDir(pointToIdx(c+vec3(0,0,0)))), 
                          texture(s, idxToDir(pointToIdx(c+vec3(1,0,0)))), f.x),
                      mix(texture(s, idxToDir(pointToIdx(c+vec3(0,1,0)))), 
                          texture(s, idxToDir(pointToIdx(c+vec3(1,1,0)))), f.x), f.y),
                 mix( mix(texture(s, idxToDir(pointToIdx(c+vec3(0,0,1)))), 
                          texture(s, idxToDir(pointToIdx(c+vec3(1,0,1)))), f.x),
                      mix(texture(s, idxToDir(pointToIdx(c+vec3(0,1,1)))), 
                          texture(s, idxToDir(pointToIdx(c+vec3(1,1,1)))), f.x), f.y), f.z);
}

vec4 getData(vec3 p, samplerCube s){
    p += vec3(0.5 * scale);
    p = clamp(p, vec3(0), scale-1.0);
    return texture(s, idxToDir(pointToIdx(floor(p))));
}

//-------------------------- AABB -------------------------

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
    return insideAABB(org, boxMin, boxMax);
	vec2 intersections = intersectAABB(org, dir, boxMin, boxMax);
	
    if(insideAABB(org, boxMin, boxMax)){
        intersections.x = 1e-4;
    }
    
    return intersections.x > 0.0 && (intersections.x < intersections.y);
}