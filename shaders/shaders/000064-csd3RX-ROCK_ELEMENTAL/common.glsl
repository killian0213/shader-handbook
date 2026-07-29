// Common (common) — ROCK ELEMENTAL by alro
// https://www.shadertoy.com/view/csd3RX

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

// Get orthonormal basis from surface normal
// https://graphics.pixar.com/library/OrthonormalB/paper.pdf
void pixarONB(vec3 n, out vec3 b1, out vec3 b2){
	float sign_ = n.z >= 0.0 ? 1.0 : -1.0;
	float a = -1.0 / (sign_ + n.z);
	float b = n.x * n.y * a;
	b1 = vec3(1.0 + sign_ * n.x * n.x * a, sign_ * b, -sign_ * n.x);
	b2 = vec3(b, sign_ + n.y * n.y * a, -n.y);
}

vec3 gamma(vec3 col){
	return pow(col, vec3(INV_GAMMA));
}

float saturate(float x){
    return max(0.0, min(x, 1.0));
}

float remap(float x, float low1, float high1, float low2, float high2){
	return low2 + (x - low1) * (high2 - low2) / (high1 - low1);
}

// Debug code
/*
    if(showAABB){
        // Core
        if(testAABB(cameraPos, rayDir, vec3(-1.1, -1.2, -0.9) + modelOffset, 
                                       vec3(0.9, 1.1, 0.9) + modelOffset)){
            col += 0.1*vec3(1,0,0);
        }
        
        // Head
        if(testAABB(cameraPos, rayDir, vec3(0.6, -0.55, -0.4)  + modelOffset, 
                                       vec3(1.3, 0.1, 0.4) + modelOffset)){
            col += 0.1*vec3(0,1,0);
        }

        // Hands
        if(testAABB(cameraPos, rayDir, vec3(-0.3, -1.6, 0.6) + modelOffset, 
                                       vec3(1.1, 0.1, 1.75) + modelOffset) ||
           testAABB(cameraPos, rayDir, vec3(-0.3, -1.6, -1.75) + modelOffset, 
                                       vec3(1.1, 0.1, -0.6) + modelOffset)){
           col += 0.1*vec3(0,0,1);
        }
        
        // Middle
        if(testAABB(cameraPos, rayDir, vec3(-0.6, -1.9, -0.6) + modelOffset, 
                                       vec3(0.6, -1.0, 0.6) + modelOffset)){
            col += 0.1*vec3(0,1,1);
        }
        
        // Bottom
        if(testAABB(cameraPos, rayDir, vec3(-0.5, -2.2, -0.5) + modelOffset, 
                                       vec3(0.5, -1.7, 0.5) + modelOffset)){
            col += 0.1*vec3(1,0,1);
        }
    }
    
    if(partID == 0){
        col = vec3(1,0,0);
    }
    
    if(partID == 1){
        col = vec3(0,1,0);
    }
    
    if(partID == 2){
        col = vec3(0,0,1);
    }
    
    if(partID == 3){
        col = vec3(0,1,1);
    }
    
    if(partID == 4){
        col = vec3(1,0,1);
    }
     */ 