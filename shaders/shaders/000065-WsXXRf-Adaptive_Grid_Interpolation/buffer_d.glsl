// Buffer D (buffer) — Adaptive Grid Interpolation by drivenbynostalgia
// https://www.shadertoy.com/view/WsXXRf

// In this example, Buffer D serves as one level of a multi-level texture, i.e., a mipmap level.
// Buffer D corresponds to level 2 of the quadtree, i.e., the level of the highest resolution.
// It holds all values of level-2 cells as well as all values downsampled from higher-level cells
// that the remaining level-2 nodes cover and all values upsampled from lower-level cells. In a real
// application, this step should be done with a compute shader, but for shadertoy, this will suffice.
// Also, reconstruction in this example is performed for every texel of the texture, which is not
// necessary. When using bilinear interpolation, only the directly neighboring texels of cells on
// that level have to be reconstructed, i.e., the 3x3 neighborhood around each cell. For bicubic
// interpolation or B-spline approximation, the neighbors' direct neighbors also need to be
// reconstructed, i.e., the 5x5 neighborhood around each cell.

// Note: The code for Buffers B, C, and D is almost identical (and should be in an application),
// except for the upsampling step missing on level 0.

#define LEVEL 2

ivec2 cellIndexToTexel(int cellIndex)
{
    ivec2 dataBufferDimensions = textureSize(iChannel0, 0);
    
    return ivec2(cellIndex % dataBufferDimensions.x, cellIndex / dataBufferDimensions.x);
}

float fetchValue(int cellIndex)
{
	return texelFetch(iChannel0, cellIndexToTexel(cellIndex), 0).x;
}

float getDownsampledValue(ivec3 gridIndex, int nodeIndex)
{
    const int highestLevel = gNumGrids - 1;
    int lowestLevel = gridIndex.z + 1;
    
	int coveredCells = 2 << (highestLevel - lowestLevel);
    ivec3 gridIndexOnLevel = ivec3(gridIndex.xy * coveredCells, highestLevel);
    
    float summedValues = 0.0;
    
    for (int y = 0; y < coveredCells; y++)
    {
    	for (int x = 0; x < coveredCells; x++)
        {
            ivec3 currentGridIndex = gridIndexOnLevel + ivec3(x, y, 0);
        	ivec3 retrievedGridIndex;
    		int nodeIndex = getLeafNodeIndex(currentGridIndex, retrievedGridIndex);
        	int cellIndex = convertNodeToCellIndex(nodeIndex);
            
            summedValues += fetchValue(cellIndex);
        }
    }
    
    return summedValues / float(coveredCells * coveredCells);
}

#if (LEVEL > 0)
float getUpsampledValue(ivec3 gridIndex, int cellIndex, int quadrant)
{
	ivec3 quadrantGridIndex = ivec3((gridIndex.xy << 1) + ivec2(quadrant & 1, (quadrant & 2) >> 1), gridIndex.z + 1);

	ivec2 gridExtents = getDimensionsOfLevel(gridIndex.z) - 1;

	ivec3 bottomLeftGridIndex = gridIndex;
	ivec3 bottomRightGridIndex = gridIndex;
	ivec3 topLeftGridIndex = gridIndex;
	ivec3 topRightGridIndex = gridIndex;

	vec2 relativePosition;

	if (quadrant == 0)
	{
		bottomLeftGridIndex.xy = clamp(bottomLeftGridIndex.xy + ivec2(-1, -1), ivec2(0), gridExtents);
		bottomRightGridIndex.xy = clamp(bottomRightGridIndex.xy + ivec2(0, -1), ivec2(0), gridExtents);
		topLeftGridIndex.xy = clamp(topLeftGridIndex.xy + ivec2(-1, 0), ivec2(0), gridExtents);
		topRightGridIndex.xy = clamp(topRightGridIndex.xy + ivec2(0, 0), ivec2(0), gridExtents);

		relativePosition = vec2(0.75, 0.75);
	}
	else if (quadrant == 1)
	{
		bottomLeftGridIndex.xy = clamp(bottomLeftGridIndex.xy + ivec2(0, -1), ivec2(0), gridExtents);
		bottomRightGridIndex.xy = clamp(bottomRightGridIndex.xy + ivec2(1, -1), ivec2(0), gridExtents);
		topLeftGridIndex.xy = clamp(topLeftGridIndex.xy + ivec2(0, 0), ivec2(0), gridExtents);
		topRightGridIndex.xy = clamp(topRightGridIndex.xy + ivec2(1, 0), ivec2(0), gridExtents);

		relativePosition = vec2(0.25, 0.75);
	}
	else if (quadrant == 2)
	{
		bottomLeftGridIndex.xy = clamp(bottomLeftGridIndex.xy + ivec2(-1, 0), ivec2(0), gridExtents);
		bottomRightGridIndex.xy = clamp(bottomRightGridIndex.xy + ivec2(0, 0), ivec2(0), gridExtents);
		topLeftGridIndex.xy = clamp(topLeftGridIndex.xy + ivec2(-1, 1), ivec2(0), gridExtents);
		topRightGridIndex.xy = clamp(topRightGridIndex.xy + ivec2(0, 1), ivec2(0), gridExtents);

		relativePosition = vec2(0.75, 0.25);
	}
	else
	{
		bottomLeftGridIndex.xy = clamp(bottomLeftGridIndex.xy + ivec2(0, 0), ivec2(0), gridExtents);
		bottomRightGridIndex.xy = clamp(bottomRightGridIndex.xy + ivec2(1, 0), ivec2(0), gridExtents);
		topLeftGridIndex.xy = clamp(topLeftGridIndex.xy + ivec2(0, 1), ivec2(0), gridExtents);
		topRightGridIndex.xy = clamp(topRightGridIndex.xy + ivec2(1, 1), ivec2(0), gridExtents);

		relativePosition = vec2(0.25, 0.25);
	}

	float v0 = texelFetch(iChannel1, clamp(bottomLeftGridIndex.xy, ivec2(0), gridExtents), 0).x;
	float v1 = texelFetch(iChannel1, clamp(bottomRightGridIndex.xy, ivec2(0), gridExtents), 0).x;
	float v2 = texelFetch(iChannel1, clamp(topLeftGridIndex.xy, ivec2(0), gridExtents), 0).x;
	float v3 = texelFetch(iChannel1, clamp(topRightGridIndex.xy, ivec2(0), gridExtents), 0).x;

	return mix(mix(v0, v1, relativePosition.x), mix(v2, v3, relativePosition.x), relativePosition.y);
}
#endif

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    ivec2 levelDimensions = getDimensionsOfLevel(LEVEL);
    ivec3 gridIndex = ivec3(ivec2(fragCoord), LEVEL);
    
    if (all(lessThan(gridIndex.xy, levelDimensions)))
    {
    	ivec3 retrievedGridIndex;
    	int nodeIndex = getLeafNodeIndex(gridIndex, retrievedGridIndex);
        int cellIndex = convertNodeToCellIndex(nodeIndex);
        
        float value = 0.0;

        if (cellIndex < 0)
        {
            // The node has child nodes, downsample their values
            
            value = getDownsampledValue(gridIndex, nodeIndex);
        }
        else
        {
#if (LEVEL > 0)
            if (retrievedGridIndex.z == LEVEL)
            {
#endif
                // The node is a leaf node, fetch its data value
                
                value = fetchValue(cellIndex);
#if (LEVEL > 0)
            }
            else
            {
				// The node covering the grid index is on a lower level, upsample the coarser values
                
                int quadrant = 2 * (gridIndex.y & 1) + (gridIndex.x & 1);

				value = getUpsampledValue(retrievedGridIndex, cellIndex, quadrant);
            }
#endif
        }
        
        fragColor = vec4(value, 0.0, 0.0, 1.0);
    }
    else
    {
     	fragColor = vec4(-1.0, 0.0, 0.0, 1.0);   
    }
}