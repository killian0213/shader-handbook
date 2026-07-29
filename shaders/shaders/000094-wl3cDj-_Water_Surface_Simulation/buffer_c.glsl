// Buffer C (buffer) —  Water Surface Simulation by TinyTexel
// https://www.shadertoy.com/view/wl3cDj

// License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

/*
    pre-filter pass (prepares height field for rendering)
    https://www.shadertoy.com/view/WtsBDH ("Bicubic C2 cont. Interpolation")
*/

#define FETCH(uv) (texelFetch(iChannel0, uv, 0).r)

void mainImage( out vec4 fragColor, in vec2 uv0 )
{    
    if(uv0.x > GridSize || uv0.y > GridSize) return;

    ivec2 uv = ivec2(uv0 - 0.5);
    
    vec4 col = vec4(0.0);
    
    // ======================================================= GENERALIZED CUBIC BSPLINE =======================================================
    
    float kernD0[3];
    float kernD1[3];
    
    kernD0[0] = 2.0/3.0; kernD0[1] = 1.0/6.0; kernD0[2] = 0.0;
    kernD1[0] =     0.0; kernD1[1] =    -0.5; kernD1[2] = 0.0;
    
    float sw;// side lobes weight

    sw = 0.0;// cubic BSpline
    
   #if 0
   
    sw = 0.25;// similar to 1/3 but less ringing
    
   #elif 0
   
    sw = 1.0/3.0;// kernD0[0] == 1
    
   #elif 0
    
    sw = 0.186605;// max abs derivative == 1
    
   #elif 0
    
    sw = 1.0/6.0;// maximaly flat pass band
    
   #elif 1
    
    sw = -0.25;// spectrum falls off to 0 at Nyquist frequency
    
   #endif
    
    // add a pair of side lobes:
    kernD0[0] += 1.0 * sw; kernD0[1] += -1.0/3.0 * sw; kernD0[2] += -1.0/6.0 * sw;
    	                   kernD1[1] += -1.0     * sw; kernD1[2] +=  0.5     * sw;
    
    int r = sw == 0.0 ? 1 : 2;
    for(int j = -r; j <= r; ++j)
    for(int i = -r; i <= r; ++i)
    {
    	float f = FETCH(uv + ivec2(i, j));
        
        int x = abs(i);
        int y = abs(j);
        
        float kAx = kernD0[x];
        float kAy = kernD0[y];
        
        float kBx = kernD1[x] * (i > 0 ? -1.0 : 1.0);
        float kBy = kernD1[y] * (j > 0 ? -1.0 : 1.0);
        
        col += f * vec4(kBx * kAy, 
                        kAx * kBy, 
                        kBx * kBy,
                        kAx * kAy);
    }
    
    // col = vec4(df/dx, df/dy, d^2f/dxy, f)
    fragColor = col;
}

