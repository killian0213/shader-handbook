// Image (image) — Adaptive Grid Interpolation by drivenbynostalgia
// https://www.shadertoy.com/view/WsXXRf

//=================================================================================================
/**
*	C1-continuous interpolation of scalar and vector fields defined on adaptive grids.
*
*	This code is part of the paper "Interactive Visualization of Flood and Heavy Rain Simulations"
*	by Daniel Cornel^1, Andreas Buttinger-Kreuzhuber^{1,2}, Artem Konev^1, Zsolt Horváth^{1,2},
*	Michael Wimmer^2, Raimund Heidrich^3, and Jürgen Waser^1, presented at EuroVis 2019.
*
*	^1 VRVis Zentrum für Virtual Reality und Visualisierung Forschungs-GmbH, Vienna, Austria
*	^2 TU Wien, Vienna, Austria
*	^3 RIOCOM Ingenieurbüro für Kulturtechnik und Wasserwirtschaft, Vienna, Austria
*
*	Paper preprint: http://visdom.at/media/pdf/publications/Interactive_Visualization_of_Flood_and_Heavy_Rain_Simulations.pdf
**/
//=================================================================================================




//=================================================================================================
/**
*	Shadertoy parameters
**/
//=================================================================================================

// Switch between interpolation modi

//#define CurrentInterpolationMode NearestNeighbor
//#define CurrentInterpolationMode Bilinear
//#define CurrentInterpolationMode Bicubic
#define CurrentInterpolationMode BSpline

// Show/hide cell grid

#define SHOW_GRID

// Use discrete/continuous transfer function

#define DISCRETE_TRAFO




//=================================================================================================
/**
*	Helper functions
**/
//=================================================================================================

// Returns the missing quadrants in the current level for the interpolation patch
// defined by the provided bottom left grid index
int getMissingQuadrants(ivec3 bottomLeftGridIndex)
{
	ivec2 gridExtents = getDimensionsOfLevel(bottomLeftGridIndex.z) - 1;

	ivec4 gridIndices = ivec4(clamp(bottomLeftGridIndex.xyxy + ivec4(0, 0, 1, 1), ivec4(0), gridExtents.xyxy));
	ivec3 retrievedGridIndex;

	int nodeIndex0 = getLeafNodeIndex(ivec3(gridIndices.xy, bottomLeftGridIndex.z), retrievedGridIndex);
	int missingQuadrants = ((nodeIndex0 != -1) && (retrievedGridIndex.z < bottomLeftGridIndex.z)) ? 1 : 0;

	int nodeIndex1 = getLeafNodeIndex(ivec3(gridIndices.zy, bottomLeftGridIndex.z), retrievedGridIndex);
	missingQuadrants |= ((nodeIndex1 != -1) && (retrievedGridIndex.z < bottomLeftGridIndex.z)) ? 2 : 0;

	int nodeIndex2 = getLeafNodeIndex(ivec3(gridIndices.xw, bottomLeftGridIndex.z), retrievedGridIndex);
	missingQuadrants |= ((nodeIndex2 != -1) && (retrievedGridIndex.z < bottomLeftGridIndex.z)) ? 4 : 0;

	int nodeIndex3 = getLeafNodeIndex(ivec3(gridIndices.zw, bottomLeftGridIndex.z), retrievedGridIndex);
	missingQuadrants |= ((nodeIndex3 != -1) && (retrievedGridIndex.z < bottomLeftGridIndex.z)) ? 8 : 0;

	return missingQuadrants;
}

// Returns the missing quadrants in the current and the next coarser levels
// for the interpolation patch defined by the provided bottom left grid index
ivec2 getMissingQuadrantsFineAndCoarse(ivec3 bottomLeftGridIndex)
{
	ivec2 gridExtents = getDimensionsOfLevel(bottomLeftGridIndex.z) - 1;
	ivec4 gridIndices = ivec4(clamp(bottomLeftGridIndex.xyxy + ivec4(0, 0, 1, 1), ivec4(0), gridExtents.xyxy));

	ivec3 quadrantGridIndices[4];
	ivec4 quadrantNodeIndices;

	quadrantNodeIndices.x = getLeafNodeIndex(ivec3(gridIndices.xy, bottomLeftGridIndex.z), quadrantGridIndices[0]);
	quadrantNodeIndices.y = getLeafNodeIndex(ivec3(gridIndices.zy, bottomLeftGridIndex.z), quadrantGridIndices[1]);
	quadrantNodeIndices.z = getLeafNodeIndex(ivec3(gridIndices.xw, bottomLeftGridIndex.z), quadrantGridIndices[2]);
	quadrantNodeIndices.w = getLeafNodeIndex(ivec3(gridIndices.zw, bottomLeftGridIndex.z), quadrantGridIndices[3]);

	ivec4 quadrantLevels = ivec4(quadrantGridIndices[0].z, quadrantGridIndices[1].z, quadrantGridIndices[2].z, quadrantGridIndices[3].z);
	bvec4 levelLess = lessThan(quadrantLevels, ivec4(bottomLeftGridIndex.z));
	bvec4 levelGreaterEqual = greaterThanEqual(quadrantLevels, ivec4(bottomLeftGridIndex.z));
	bvec4 validNodeIndex = notEqual(quadrantNodeIndices, ivec4(-1));

	ivec2 missingQuadrants = ivec2(((validNodeIndex.x) && (levelLess.x)) ? 1 : 0, ((validNodeIndex.x) && (levelGreaterEqual.x)) ? 1 : 0);
	missingQuadrants |= ivec2(((validNodeIndex.y) && (levelLess.y)) ? 2 : 0, ((validNodeIndex.y) && (levelGreaterEqual.y)) ? 2 : 0);
	missingQuadrants |= ivec2(((validNodeIndex.z) && (levelLess.z)) ? 4 : 0, ((validNodeIndex.z) && (levelGreaterEqual.z)) ? 4 : 0);
	missingQuadrants |= ivec2(((validNodeIndex.w) && (levelLess.w)) ? 8 : 0, ((validNodeIndex.w) && (levelGreaterEqual.w)) ? 8 : 0);

	return missingQuadrants;
}

const ivec3 quadrantMasks[4] = ivec3[](ivec3(4, 2, 1), ivec3(8, 1, 2), ivec3(1, 8, 4), ivec3(2, 4, 8));

// Returns weights for bilinear blending within the blending region
// based on the arrangement of cells of different levels
vec4 getBlendingWeights(bvec3 neighborFlags, ivec2 bottomLeftOffset)
{
	// Given the restriction that neighboring cells must not differ by more than one level,
	// all possible arrangements of cells can be enumerated to precompute the weights in the
	// corners of the transition region. This is just an efficient way of saying "zero if
	// the corner is covered by a coarser-level cell, else 1".

	const int[] weightBitsArray = int[](
		14, 11, 13, 7, 6, 9, 9, 6,
		10, 10, 5, 5, 2, 8, 1, 4,
		12, 3, 12, 3, 4, 1, 8, 2,
		8, 2, 4, 1, 0, 0, 0, 0);

	int i = (int(neighborFlags.x) << 4) + (int(neighborFlags.y) << 3) + (int(neighborFlags.z) << 2) + ((bottomLeftOffset.x + 1) << 1) + (bottomLeftOffset.y + 1);
	int weightBits = int(weightBitsArray[i]);

	return vec4((weightBits & 8) >> 3, (weightBits & 4) >> 2, (weightBits & 2) >> 1, weightBits & 1);
}

// Calculates a transition region between cells of two different resolutions
// and linearly combines the interpolated values of both levels with a
// Hermite spline weight, which makes the result C1-continuous
float smoothCombine(
	vec2 position,
	ivec3 fineLevelGridIndex,
	ivec3 fineLevelBottomLeftGridIndex,
	ivec2 fineLevelBottomLeftOffset,
	int fineLevelMissingQuadrants,
	float valueFine,
	float valueCoarse,
	bool fineToCoarse)
{
	ivec3 quadrantMask = quadrantMasks[(fineLevelBottomLeftOffset.y << 1) + fineLevelBottomLeftOffset.x + 3];
	bvec3 neighborFlags = equal(fineLevelMissingQuadrants & quadrantMask, quadrantMask);

	if (fineToCoarse)
	{
		neighborFlags = not(neighborFlags);
	}

	vec4 blendingWeights = getBlendingWeights(neighborFlags, fineLevelBottomLeftOffset);

	if (fineToCoarse)
	{
		blendingWeights = 1.0 - blendingWeights;
	}

	vec2 relativePosition = (position - gOrigin) * getInverseCellSizeOfLevel(fineLevelGridIndex.z) - vec2(fineLevelBottomLeftGridIndex.xy) - 0.5;

	vec2 horizontalWeights = mix(blendingWeights.xz, blendingWeights.yw, relativePosition.x);

	float t = mix(horizontalWeights.x, horizontalWeights.y, relativePosition.y);

	return mix(valueCoarse, valueFine, smoothstep(0.0, 1.0, t));
}

// Fetches the (possibly reconstructed) data value from the "multi-level texture",
// the Buffers B, C, and D
float getDataValue(int x, int y, int level)
{
    ivec2 gridIndex = clamp(ivec2(x, y), ivec2(0), getDimensionsOfLevel(level) - 1);
    
    if (level == 0)
    {
    	return texelFetch(iChannel0, gridIndex, 0).x;
    }
    else if (level == 1)
    {
    	return texelFetch(iChannel1, gridIndex, 0).x;
    }
    else if (level == 2)
    {
    	return texelFetch(iChannel2, gridIndex, 0).x;
    }
    else
    {
        return -1.0;
    }
}

// Usual B-spline interpolation on a single level. For simplicity,
// the texture lookups are very naive and therefore quite inefficient.
// If only using scalar fields, they should be replaced by textureGather.
float interpolateBSpline(vec2 samplePosition, ivec3 bottomLeftGridIndex)
{
    int level = bottomLeftGridIndex.z;
	ivec4 xIndices = bottomLeftGridIndex.xxxx + ivec4(-1, 0, 1, 2);
	ivec4 yIndices = bottomLeftGridIndex.yyyy + ivec4(-1, 0, 1, 2);

	float v0 = getDataValue(xIndices.x, yIndices.x, level);
	float v1 = getDataValue(xIndices.y, yIndices.x, level);
	float v2 = getDataValue(xIndices.z, yIndices.x, level);
	float v3 = getDataValue(xIndices.w, yIndices.x, level);

	float v4 = getDataValue(xIndices.x, yIndices.y, level);
	float v5 = getDataValue(xIndices.y, yIndices.y, level);
	float v6 = getDataValue(xIndices.z, yIndices.y, level);
	float v7 = getDataValue(xIndices.w, yIndices.y, level);

	float v8 = getDataValue(xIndices.x, yIndices.z, level);
	float v9 = getDataValue(xIndices.y, yIndices.z, level);
	float v10 = getDataValue(xIndices.z, yIndices.z, level);
	float v11 = getDataValue(xIndices.w, yIndices.z, level);

	float v12 = getDataValue(xIndices.x, yIndices.w, level);
	float v13 = getDataValue(xIndices.y, yIndices.w, level);
	float v14 = getDataValue(xIndices.z, yIndices.w, level);
	float v15 = getDataValue(xIndices.w, yIndices.w, level);

	vec2 relativeSamplePosition = (samplePosition - gOrigin) * getInverseCellSizeOfLevel(level);
	vec2 relativeCellCenter = vec2(bottomLeftGridIndex.xy) + 0.5;
	vec2 f = relativeSamplePosition - relativeCellCenter;
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;

	vec2 oneMinusF = 1.0 - f;
	vec2 oneMinusF2 = oneMinusF * oneMinusF;
	vec2 oneMinusF3 = oneMinusF2 * oneMinusF;

	const vec2 ONE_OVER_SIX_VEC2 = vec2(1.0 / 6.0);
	const vec2 ONE_OVER_TWO_VEC2 = vec2(1.0 / 2.0);
	const vec2 TWO_OVER_THREE_VEC2 = vec2(2.0 / 3.0);

	vec2 w0 = ONE_OVER_SIX_VEC2 * oneMinusF3;
	vec2 w1 = ONE_OVER_TWO_VEC2 * f3 - f2 + TWO_OVER_THREE_VEC2;
	vec2 w2 = ONE_OVER_TWO_VEC2 * oneMinusF3 - oneMinusF2 + TWO_OVER_THREE_VEC2;
	vec2 w3 = ONE_OVER_SIX_VEC2 * f3;

	return w0.y * (w0.x * v0 + w1.x * v1 + w2.x * v2 + w3.x * v3) +
		w1.y * (w0.x * v4 + w1.x * v5 + w2.x * v6 + w3.x * v7) +
		w2.y * (w0.x * v8 + w1.x * v9 + w2.x * v10 + w3.x * v11) +
		w3.y * (w0.x * v12 + w1.x * v13 + w2.x * v14 + w3.x * v15);
}

// Usual Catmull-Rom interpolation on a single level. For simplicity,
// the texture lookups are very naive and therefore quite inefficient.
// If only using scalar fields, they should be replaced by textureGather.
float interpolateBicubic(vec2 samplePosition, ivec3 bottomLeftGridIndex)
{
	int level = bottomLeftGridIndex.z;
	ivec4 xIndices = bottomLeftGridIndex.xxxx + ivec4(-1, 0, 1, 2);
	ivec4 yIndices = bottomLeftGridIndex.yyyy + ivec4(-1, 0, 1, 2);

	float v0 = getDataValue(xIndices.x, yIndices.x, level);
	float v1 = getDataValue(xIndices.y, yIndices.x, level);
	float v2 = getDataValue(xIndices.z, yIndices.x, level);
	float v3 = getDataValue(xIndices.w, yIndices.x, level);

	float v4 = getDataValue(xIndices.x, yIndices.y, level);
	float v5 = getDataValue(xIndices.y, yIndices.y, level);
	float v6 = getDataValue(xIndices.z, yIndices.y, level);
	float v7 = getDataValue(xIndices.w, yIndices.y, level);

	float v8 = getDataValue(xIndices.x, yIndices.z, level);
	float v9 = getDataValue(xIndices.y, yIndices.z, level);
	float v10 = getDataValue(xIndices.z, yIndices.z, level);
	float v11 = getDataValue(xIndices.w, yIndices.z, level);

	float v12 = getDataValue(xIndices.x, yIndices.w, level);
	float v13 = getDataValue(xIndices.y, yIndices.w, level);
	float v14 = getDataValue(xIndices.z, yIndices.w, level);
	float v15 = getDataValue(xIndices.w, yIndices.w, level);

	vec2 relativeSamplePosition = (samplePosition - gOrigin) * getInverseCellSizeOfLevel(level);
	vec2 relativeCellCenter = vec2(bottomLeftGridIndex.xy) + 0.5;
	vec2 f = relativeSamplePosition - relativeCellCenter;
	vec2 f2 = f * f;
	vec2 f3 = f2 * f;

	vec2 w0 = -0.5 * (f3 + f) + f2;
	vec2 w1 = 1.5 * f3 - 2.5 * f2 + 1.0;
	vec2 w2 = -1.5 * f3 + 2.0 * f2 + 0.5 * f;
	vec2 w3 = 0.5 * (f3 - f2);

	return w0.y * (w0.x * v0 + w1.x * v1 + w2.x * v2 + w3.x * v3) +
		w1.y * (w0.x * v4 + w1.x * v5 + w2.x * v6 + w3.x * v7) +
		w2.y * (w0.x * v8 + w1.x * v9 + w2.x * v10 + w3.x * v11) +
		w3.y * (w0.x * v12 + w1.x * v13 + w2.x * v14 + w3.x * v15);
}

// Usual bilinear interpolation on a single level. If your underlying
// data structure is an actual OpenGL texture, this can be done by
// hardware filtering.
float interpolateBilinear(vec2 samplePosition, ivec3 bottomLeftGridIndex)
{
	int level = bottomLeftGridIndex.z;
    
	float v0 = getDataValue(bottomLeftGridIndex.x, bottomLeftGridIndex.y, level);
	float v1 = getDataValue(bottomLeftGridIndex.x + 1, bottomLeftGridIndex.y, level);
	float v2 = getDataValue(bottomLeftGridIndex.x, bottomLeftGridIndex.y + 1, level);
	float v3 = getDataValue(bottomLeftGridIndex.x + 1, bottomLeftGridIndex.y + 1, level);

	vec2 relativeSamplePosition = (samplePosition - gOrigin) * getInverseCellSizeOfLevel(level);
	vec2 relativeCellCenter = vec2(bottomLeftGridIndex.xy) + 0.5;
	vec2 f = relativeSamplePosition - relativeCellCenter;

	return mix(mix(v0, v1, f.x), mix(v2, v3, f.x), f.y);
}

//=================================================================================================
/**
*	The adaptive interpolation function you came here to see
**/
//=================================================================================================

// If all values required for interpolation are defined on the same grid level,
// this function is equivalent to interpolation on a regular grid.
// If the interpolation patch spans over a level discontinuity, it is necessary
// to interpolate twice for the two different levels and then combine the
// results to a single value. The combination is done by blending with a
// Hermite spline weight, which makes the result C1-continuous.
float sampleField(ivec3 gridIndex, vec2 position)
{
    int level = gridIndex.z;

#if (CurrentInterpolationMode == NearestNeighbor)
    ivec2 gridDimensions = getDimensionsOfLevel(level);

	return getDataValue(gridIndex.x, gridIndex.y, level);
#else
	vec2 fineNodePosition = getNodePosition(gridIndex);
	ivec2 fineBottomLeftOffset = mixIvec2Bool(ivec2(0), ivec2(-1), lessThanEqual(position, fineNodePosition));
	ivec3 fineBottomLeftGridIndex = ivec3(gridIndex.xy + fineBottomLeftOffset, level);

	ivec2 missingQuadrants = getMissingQuadrantsFineAndCoarse(fineBottomLeftGridIndex);
	int fineMissingQuadrants = missingQuadrants.x;

    // Regular interpolation on the first grid

#if (CurrentInterpolationMode == Bilinear)
	float valueFine = interpolateBilinear(position, fineBottomLeftGridIndex);
#elif (CurrentInterpolationMode == Bicubic)
	float valueFine = interpolateBicubic(position, fineBottomLeftGridIndex);
#elif (CurrentInterpolationMode == BSpline)
	float valueFine = interpolateBSpline(position, fineBottomLeftGridIndex);
#endif

	bool hasMissingCoarseQuadrants = (fineMissingQuadrants != 0);
	bool hasMissingFineQuadrants = (level < gNumGrids - 1) && (missingQuadrants.y != 0);
	bool coarseToFine = (!hasMissingCoarseQuadrants) && (hasMissingFineQuadrants);
	bool noBlending = (!hasMissingCoarseQuadrants) && (!hasMissingFineQuadrants);

	if (noBlending)
	{
        // No values have been missing, return regularly interpolated result
        
		return valueFine;
	}
	else
	{
        // Some values have been missing, interpolate at the same position on the second grid as well
        
		ivec3 fineGridIndex = gridIndex;
		ivec3 otherLevelGridIndex;
		float valueCoarse;

		if (coarseToFine)
		{
			valueCoarse = valueFine;

			ivec2 fineCellQuadrantOffset = mixIvec2Bool(ivec2(0), ivec2(1), greaterThan(position, fineNodePosition));

			otherLevelGridIndex = ivec3(gridIndex.xy << 1, level + 1) + ivec3(fineCellQuadrantOffset, 0);
		}
		else
		{
			otherLevelGridIndex = ivec3(gridIndex.xy >> 1, level - 1);
		}

		vec2 otherLevelCenterPosition = getNodePosition(otherLevelGridIndex);
		ivec2 otherLevelBottomLeftOffset = mixIvec2Bool(ivec2(0), ivec2(-1), lessThanEqual(position, otherLevelCenterPosition));
		ivec3 otherLevelBottomLeftGridIndex = ivec3(otherLevelGridIndex.xy + otherLevelBottomLeftOffset, otherLevelGridIndex.z);

		if (coarseToFine)
		{
			fineGridIndex = otherLevelGridIndex;
			fineBottomLeftOffset = otherLevelBottomLeftOffset;
			fineBottomLeftGridIndex = otherLevelBottomLeftGridIndex;
			fineMissingQuadrants = getMissingQuadrants(otherLevelBottomLeftGridIndex);
		}
        
        // Regular interpolation on the second grid

#if (CurrentInterpolationMode == Bilinear)
		float otherValue = interpolateBilinear(position, otherLevelBottomLeftGridIndex);
#elif (CurrentInterpolationMode == Bicubic)
		float otherValue = interpolateBicubic(position, otherLevelBottomLeftGridIndex);
#elif (CurrentInterpolationMode == BSpline)
		float otherValue = interpolateBSpline(position, otherLevelBottomLeftGridIndex);
#endif

		if (coarseToFine)
		{
			valueFine = otherValue;
		}
		else
		{
			valueCoarse = otherValue;
		}
        
        // Smoothly combine the two interpolated values within the transition region

		return smoothCombine(
			position,
			fineGridIndex,
			fineBottomLeftGridIndex,
			fineBottomLeftOffset,
			fineMissingQuadrants,
			valueFine,
			valueCoarse,
			!coarseToFine);
	}
#endif
}

// Transfer function
vec4 mapToRGB(float value)
{
    // Color map generated with ColorBrewer
    // http://colorbrewer2.org/#type=sequential&scheme=YlGnBu&n=9
    const vec4[] colors = vec4[](
        vec4(255.0, 255.0, 217.0, 255.0) / 255.0,
        vec4(237.0, 248.0, 177.0, 255.0) / 255.0,
        vec4(199.0, 233.0, 180.0, 255.0) / 255.0,
        vec4(127.0, 205.0, 187.0, 255.0) / 255.0,
        vec4(65.0, 182.0, 196.0, 255.0) / 255.0,
        vec4(29.0, 145.0, 192.0, 255.0) / 255.0,
        vec4(34.0, 94.0, 168.0, 255.0) / 255.0,
        vec4(37.0, 52.0, 148.0, 255.0) / 255.0,
        vec4(8.0, 29.0, 88.0, 255.0) / 255.0);
    
    int intervals = colors.length() - 1;
    
    float t = clamp(value, 0.0, 1.0) * float(intervals);
    int interval = clamp(int(t), 0, intervals);

    if (value == -1.0)
    {
        return vec4(1.0, 0.5, 0.5, 1.0);
    }

#ifdef DISCRETE_TRAFO
    t = smoothstep(0.48, 0.52, fract(t));
#else
    t = fract(t);
#endif
    
	return mix(colors[interval], colors[interval + 1], t);
}

// This function determines whether the current fragment is at a cell border
// in the most inefficient way, traversing the quadtree twice more.
float gridIntensity(vec2 fragCoord, int nodeIndex)
{
    if ((any(lessThanEqual(ivec2(fragCoord), ivec2(0)))) ||
        (any(greaterThanEqual(ivec2(fragCoord), ivec2(iResolution.xy - 1.0)))))
    {
        return 1.0;
    }
    else
    {
        ivec3 temp;
        ivec2 neighborNodeIndices = ivec2(
			getLeafNodeIndex(mix(gOrigin, gUpper, vec2(fragCoord.x - 1.0, fragCoord.y) / iResolution.xy), temp),
            getLeafNodeIndex(mix(gOrigin, gUpper, vec2(fragCoord.x, fragCoord.y - 1.0) / iResolution.xy), temp));
                
        return (any(notEqual(neighborNodeIndices, ivec2(nodeIndex)))) ? 1.0 : 0.0;
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 worldSpacePosition = mix(gOrigin, gUpper, uv);
    
    ivec3 gridIndex;
	int nodeIndex = getLeafNodeIndex(worldSpacePosition, gridIndex);
	int cellIndex = convertNodeToCellIndex(nodeIndex);
    
    if (cellIndex < 0)
    {
        // In a real application, traversal with getLeafNodeIndex will not succeed
        // if sampling outside the grid, so this case has to be handled somehow.
        
        fragColor = vec4(1.0, 0.5, 0.5, 1.0);
    }
    else
    {
    	float interpolatedValue = sampleField(gridIndex, worldSpacePosition);

    	fragColor = mapToRGB(interpolatedValue);

#ifdef SHOW_GRID
        fragColor = mix(fragColor, vec4(0.0, 0.0, 0.0, 1.0), 0.5 * gridIntensity(fragCoord, nodeIndex));
#endif        
	}
}