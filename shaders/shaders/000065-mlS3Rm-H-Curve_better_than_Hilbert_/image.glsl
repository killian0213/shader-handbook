// Image (image) — H-Curve (better than Hilbert?) by MartyMcFly
// https://www.shadertoy.com/view/mlS3Rm

// The MIT License
// Copyright © 2023 Pascal Gilcher
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

//
// Efficient implementation of the H-Curve
//
// "Towards Optimal Locality in Mesh-Indexings" (1997)
// Rolf Niedermeier, Klaus Reinhardt and Peter Sanders
// 
// The H-Curve is a relatively obscure space filling curve with a superior
// locality property than the Hilbert curve (2 vs sqrt(6)) which is conjectured
// to be optimal.
//
// The original publication source code is completely unintelligible and the only
// other third party implementation creates the pattern but does not produce indices.
//
// ________________________________________________________________________________
//
//
// This algorithm works in 2 steps:
//
// 1) construct the basic H shape in a 4x4 grid. As it is cyclic, the start is arbitrary
//    but I found it convenient having it start at the bottom right. This is the indexing
//    used at the start (why it doesn't start at the bottom right, see 2))
//
//                        2---1    14--13
//                        |   |    |    |
//                        3   0----15  12 
//                        |             |
//                        4   7----8   11 
//                        |   |    |    |
//                        5---6    9---10 
// 2) for each cascade:
//
//        - toroidal wrap to place the start at the bottom right of the current pattern 
//          to make connecting easier
//        - repeat the pattern 2x2 times
//        - toroidal wrap for each quadrant so indices 0 and N-1 of the quadrants 
//          that will connect now are adjacent
//        - connect the blocks by adding 0/1/2/3x n^2
//

#define LEVELS 3

#if 1 //unoptimized

uint H_curve(uvec2 p, uint logN)
{
        uint N = 1u << logN;
        
        p &= N - 1u;           
        uint i = (p.x&2u)<<2u|((p.x^p.y)&2u)<<1u|(p.y^(~p.x<<1u))&2u|(p.x^p.y)&1u; //modulo 16 is done inside the loop, can skip

        p *= 4u; 
        uvec2 t;        
        for(uint k = 16u; k < N*N; k *= 4u)
        {  
            t = p & k;            
            t = 2u * t + t.x ^ t.y;        
            i = ((i + ((3u * k) >> 3u) + (t.y >> 2u)) & (k - 1u)) | t.x;  
            p *= 2u; 
        }
        return i;
}


#else 

//longer, annotated version.
uint H_curve(uvec2 pos, uint logN)
{
        pos &= (1u << logN) - 1u;//since it's cycling, I have to make it tileable somehow
        uint x = pos.x & 3u;
        uint y = pos.y & 3u;
        pos >>= 1u;
        
        uint i = (x&2u)<<2u|((y^x)&2u)<<1u|(y^(~x<<1u))&2u|(x^y)&1u; //initial D, I mean H  
        
        //uint idx = x * 4u + y;        
        //uint H = 0xBB44B14Eu;        
        //i = ((H>>(idx&0xEu)+16u)<<2u)|((H>>2u*(idx&7u))&3u);
      
        for(uint s = 2u; s < logN; s++)
        {
            uint n = 1u << s;
            uint n2 = n * n;

            //first, shift indices in the base blocks so 0 is at bottom right (when wrapped around)
            
            i += (3u * n2) >> 3u; //i %= n*n; //done later again so skip it                       
            
            pos >>= 1u;
            x = pos.x & 1u;
            y = pos.y & 1u;           
            
            uint permute = x ^ y + (y << 1u);                    
            uint shift   = x ^ y + (x << 1u); 
            
            //offset indices within each quadrant so start and exit connect
            i = (i + permute * (n2 >> 2u)) & (n2 - 1u);    
            //offset indices by block count, i.e. 0123 0123 becomes 0123 4567
            i += shift * n2;  
        }
        return i;
}

#endif

//thanks IQ
vec3 hsv2rgb(in vec3 c)
{
    vec3 rgb=clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
	return c.z*mix(vec3(1.0),rgb,c.y);
}

vec3 gradient(float t) 
{
    float h = 0.6666 * (1.0 - t*t);
    float s = 0.75;
    float v = 1.0 - 0.9*(1.0 - t) * (1.0 - t);
	return hsv2rgb(vec3(h,s,v));    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    uint logN = uint(LEVELS + 2);    
    uint N = 1u << logN;  
    
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;    
    
    float r = max(0.0, 1.0 - dot(uv, uv) * 0.3);   
    fragColor = vec4(r);   
     
     
    uv.x *= iResolution.x / iResolution.y;
    uv *= 1.3;
    
    float fade = max(abs(uv.x), abs(uv.y)) - 1.0;
    
    fragColor *= fade / (0.005 + fade);
     
    if(abs(uv.x) < 1.0 && abs(uv.y) < 1.0)
    {
        uv = uv * 0.5 + 0.5;
  
        
        uvec2 pos = uvec2(uv * float(N));
        uint i = H_curve(pos, logN);
        
        float t = float(i) / float(N * N);
        t = fract(-t - iTime * 0.25 + 0.125);
        fragColor = vec4(gradient(t), 1.0); 
        
    }  
  
}