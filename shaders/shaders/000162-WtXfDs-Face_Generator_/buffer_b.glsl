// Buffer B (buffer) — Face Generator  by Pidhorskyi
// https://www.shadertoy.com/view/WtXfDs

// The MIT License
// Copyright © 2020 Stanislav Pidhorskyi
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


// Taken from https://www.shadertoy.com/view/MlVSzw
// Changed to interpolate between two random values each second
float gaussian_rand(vec2 n, float z)
{
	float t = fract( iTime );
	int t_d = int(iTime) * 13;
	float x1 = hash1(n + 0.07*(float(t_d) + z) );
	float x2 = hash1(n + 0.07*(float(t_d + 13) + z) );
    float x = mix(x1, x2, t);
    
	return inv_error_function(x*2.0-1.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 l_coord, g_coord;
    if (skip(fragCoord, iResolution, 2, l_coord, g_coord))
    {
        fragColor = vec4(0.0);
    	return;
    }

    int zsize = min(ZSIZE, int(iResolution.x));
    
    float[ZSIZE] z;
    float l = 0.;
    for (int i = 0; i < zsize; ++i)
    {
        float x = gaussian_rand(vec2(g_coord), float(i) / float(ZSIZE)) * 1.0;
        z[i] += x;
        l += x * x;
    }
    l = sqrt(l / float(ZSIZE));
    for (int i = 0; i < zsize; ++i)
    {
        z[i] *= 0.6 / l;
    }  
    
    vec4 w[ZSIZE];
    switch (l_coord.x + 4 * l_coord.y)
    {
		case 0: w = w_0_0; break;
		case 1: w = w_0_1; break;
		case 2: w = w_0_2; break;
		case 3: w = w_0_3; break;
		case 4: w = w_1_0; break;
		case 5: w = w_1_1; break;
		case 6: w = w_1_2; break;
		case 7: w = w_1_3; break;
		case 8: w = w_2_0; break;
		case 9: w = w_2_1; break;
		case 10: w = w_2_2; break;
		case 11: w = w_2_3; break;
		case 12: w = w_3_0; break;
		case 13: w = w_3_1; break;
		case 14: w = w_3_2; break;
		case 15: w = w_3_3; break;
    }
    
    vec4 x = bias[l_coord.x + 4 * l_coord.y];
    for (int i = 0; i < zsize; ++i)
    {
        x += z[i] * w[i];
    }
        
    //relu
    fragColor = max(x, 0.2 * x);
}
