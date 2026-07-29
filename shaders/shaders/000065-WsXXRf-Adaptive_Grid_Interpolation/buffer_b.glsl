// Buffer B (buffer) — Adaptive Grid Interpolation by drivenbynostalgia
// https://www.shadertoy.com/view/WsXXRf

// In this example, Buffer B serves as one level of a multi-level texture, i.e., a mipmap level.
// Buffer B corresponds to level 0 of the quadtree, i.e., the level of the coarsest resolution.
// It holds all values of level-0 cells as well as all values downsampled from higher-level cells
// that the remaining level-0 nodes cover. In a real application, this step should be done with a
// compute shader, but for shadertoy, this will suffice.
// Also, reconstruction in this example is performed for every texel of the texture, which is not
// necessary. When using bilinear interpolation, only the directly neighboring texels of cells on
// that level have to be reconstructed, i.e., the 3x3 neighborhood around each cell. For bicubic
// interpolation or B-spline approximation, the neighbors' direct neighbors also need to be
// reconstructed, i.e., the 5x5 neighborhood around each cell.

// Note: The code for Buffers B, C, and D is almost identical (and should be in an application),
// except for the upsampling step missing on level 0.

#define LEVEL 0

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
        	// The node is a leaf node, fetch its data value
                
            value = fetchValue(cellIndex);
        }
        
        fragColor = vec4(value, 0.0, 0.0, 1.0);
    }
    else
    {
     	fragColor = vec4(-1.0, 0.0, 0.0, 1.0);   
    }
}