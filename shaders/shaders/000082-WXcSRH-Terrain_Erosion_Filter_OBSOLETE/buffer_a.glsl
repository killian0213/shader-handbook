// Buffer A (buffer) — Terrain Erosion Filter OBSOLETE by runevision
// https://www.shadertoy.com/view/WXcSRH

// Copyright 2020 Clay John

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
// and associated documentation files (the "Software"), to deal in the Software without restriction, 
// including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
// and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
// so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or 
// substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT 
// NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

/*
==========================================================================================

Buffer A generates the heightmap (X), normals (YZ) and erosion mask used for coloring (W)

==========================================================================================
*/

// Produce ridges (height and slope) orthogonal to the input slope.
// Steeper slopes produce more high frequency ridges.
// Ridges is a type of noise with strong directionality produced by blending between
// sine wave patterns contributed by each Voronoi-like cell.
// The sine waves of all cells are along the same direction (orthogonal to the slope),
// but the phase is relative to the cell center, so that small changes in direction
// only produce small changes in output.
//
// Pieced together from a variety of sources:
// - Terrain Erosion Filter by runevision : https://www.shadertoy.com/view/WXcSRH
//   (verbose variable names and curl computed inside the Ridges function itself)
// - Terrain Erosion Noise by Fewes : https://www.shadertoy.com/view/7ljcRW
//   (simplify analytical derivatives calculation)
// - Eroded Terrain Noise by clayjohn : https://www.shadertoy.com/view/MtGcWh
//   (analytic derivatives and favour direction quite a bit)
// - Gavoronoise by guil : https://www.shadertoy.com/view/llsGWl
//   (exp based distance function, cosine wave per cell)
// - Gabor 4: normalized by FabriceNeyret2 : https://www.shadertoy.com/view/XlsGDs
//   (noise function with high directionality)
// - Voronoise by iq : https://www.shadertoy.com/view/Xd23Dh
//   (noise function that generalizes cell-noise, perlin-noise and voronoi)
vec3 Ridges(in vec2 p, vec2 slope)
{
    vec2 sideDir = slope.yx * vec2(-1.0, 1.0);
    vec2 ip = floor(p);
    vec2 fp = fract(p);
    float revolution = 2.0 * PI;
    vec3 va = vec3(0.0);
    float weightSum = 0.0;
    for (int i=-2; i<=1; i++)
    {
        for (int j=-2; j<=1; j++)
        {
            vec2 gridOffset = vec2(i, j);

            // Calculate a cell point by starting off with a point in an integer grid.
            vec2 gridPoint = ip - gridOffset;

            // Calculate a random offset for the cell point between -0.5 and 0.5.
            // The final cell point is the gridPoint plus the randomOffset.
            vec2 randomOffset = hash(gridPoint) * 0.5;

            // vectorToCellPoint is a vector representing the cell point relative to the input point:
            // (gridPoint + randomOffset) - p
            // = ((ip - gridOffset) + randomOffset) - (fp + ip)
            // = ip - gridOffset + randomOffset - fp - ip
            // = randomOffset - gridOffset - fp
            vec2 vectorToCellPoint = randomOffset - gridOffset - fp;

            // Bell-shaped weight function which is 1 at dist 0 and nearly 0 at dist 1.5.
            float sqrDist = dot(vectorToCellPoint, vectorToCellPoint);
            float weight = exp(-sqrDist * 2.0);

            // Keep track of total sum of weights.
            weightSum += weight;

            // The wave input is the distance along sideDir (so sideways along the terrain slope).
            float waveInput = dot(vectorToCellPoint, sideDir) * revolution;

            // Add a wave along dir. The longer dir is, the higher frequency the wave.
            // This means we get more high-frequency creases on steeper slopes.
            // Note that the fact we use cos() for the height (and not sin()) has a significant effect
            // on mountain peaks. Since the slope and hence the frequency is zero there, cos() ensures
            // this evaluates to the maximum values in the wave, meaning peaks "get no erosion".
            // In contrast, negating the contribution creates holes at would-be peaks and trenches at would-be ridges.
            va += vec3(cos(waveInput), sin(waveInput) * sideDir) * weight;
        }
    }
    return va / weightSum;
}

// Apply an erosion filter inspired by fbm type noise.
// erosion is a type of noise with a strong directionality
// we pass in the direction based on the slope of the terrain
// erosion also returns the slope. we add that to a running total
// so that the direction of successive layers are based on the
// past layers
vec3 Erosion(in vec2 p, vec3 heightAndSlope, float a, int octaves)
{
    // Adjust slope sensitivity by mixing in a normalized version of the slope.
    float slopeMag = length(heightAndSlope.yz);
    heightAndSlope.yz /= mix(slopeMag, 1.0 / EROSION_SLOPE_STRENGTH, EROSION_SLOPE_SENSITIVITY);

    float f = 1.0;
    for (int i = 0; i < octaves; i++)
    {
        heightAndSlope += Ridges(
            p * EROSION_TILES * f,
            heightAndSlope.yz 
        ) * a * vec3(1.0, f * EROSION_BRANCH_STRENGTH, f * EROSION_BRANCH_STRENGTH);
        a *= EROSION_GAIN;
        f *= EROSION_LACUNARITY;
    }
    
    return heightAndSlope;
}

vec2 Heightmap(vec2 uv)
{
    vec2 p = uv * HEIGHT_TILES;
    
    // FBM terrain
    vec3 n = vec3(0.0);
    float nf = 1.0;
    float na = HEIGHT_AMP;
    for (int i = 0; i < HEIGHT_OCTAVES; i++)
    {
        n += noised(p * nf) * na * vec3(1.0, nf, nf);
        na *= HEIGHT_GAIN;
        nf *= HEIGHT_LACUNARITY;
    }
    
    // [-1, 1] -> [0, 1]
    n.x = n.x * 0.5 + 0.5;
    
    // Store eroded version of n in h:
    vec3 h = n;
    float a = 0.5;

    // Smooth valleys
    //a *= (smoothstep(0.0, 1.0, n.x));

    a *= smoothstep(WATER_HEIGHT - 0.07, WATER_HEIGHT + 0.2, n.x);
    
    int octaves = EROSION_OCTAVES;
    
#ifdef COMPARISON_SLIDER
    if (iMouse.z > 0.5 && (iMouse.x / iResolution.x - 0.5) * 1.5 < (0.5 - uv.y) || iMouse.z < 0.5 && 1.0 - uv.y > (-cos(iTime) * 1.0 + 0.5))
    {
        octaves = 0;
        h.x += 0.5;
    }
#endif

    h = Erosion(p, h, a, octaves);

    return vec2(n.x + (h.x - n.x - 0.5) * EROSION_STRENGTH, h.x - n.x);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (fragCoord.x >= BUFFER_SIZE.x || fragCoord.y >= BUFFER_SIZE.y)
    {
        return;
    }

    vec2 uv = fragCoord / BUFFER_SIZE;
    uv.x += TIME_SCROLL_OFFSET;
    
    float s = 0.1;//scaling factor for heightmap
    
    vec2 h = Heightmap(uv);
    
    // Calculate an accurate normal from neighbouring points
    vec2 uv1 = uv + vec2(1.0, 0.0) / 512.0;
    vec2 uv2 = uv + vec2(0.0, 1.0) / 512.0;
    vec2 h1 = Heightmap(uv1);
    vec2 h2 = Heightmap(uv2);
    vec3 v1 = vec3(uv1 - uv, (h1.x - h.x));
    vec3 v2 = vec3(uv2 - uv, (h2.x - h.x));
    vec3 normal = normalize(cross(v1, v2)).xzy;
    
    fragColor = vec4(h.x, normal.xz, h.y);
}