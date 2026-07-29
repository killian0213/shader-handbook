// Common (common) — Adaptive Grid Interpolation by drivenbynostalgia
// https://www.shadertoy.com/view/WsXXRf

// Hard-coded adaptive grid data structure (quadtree)
// Each node has four child nodes, each leaf node is called a cell and holds a data value
// These buffers and constants are supposed to be provided by the host application

const int gNumGrids = 3;
const int gNumNodes = 204; // Traversable nodes of the quadtree / hierarchical data structure
const int gNumCells = 159; // Leaf nodes with data values

const vec2 gOrigin = vec2(-20.0, 20.0); // Application-dependent grid origin in world units
const vec2 gLevel0CellSize = vec2(100.0, 100.0); // Application-dependent largest cell size in world units
const ivec2 gLevel0Dimensions = ivec2(6, 4);

// Cell index of each leaf node (-1 for nodes with children)
const int[gNumNodes] gNodeToCellIndices = int[](
    0, 1, 2, -1, -1, -1, 3, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, 4, -1, -1,
    -1, -1, -1, 5, 6, 7, 12, 13, 8, 9,
    14, -1, 10, 11, 15, 16, 19, 20, 29, 30,
    17, 18, 27, 28, 21, 22, 31, 32, 23, 24,
    33, 34, 25, 26, 35, 36, 37, 38, -1, -1,
    39, -1, 41, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, 40, 42, 43, 44, -1, 47, -1,
    45, -1, 48, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, 46, 49, 50, 51, 52, 53, 54,
    55, 56, 67, 68, 83, 84, 97, 98, 79, 80,
    93, 94, 65, 66, 77, 78, 81, 82, 95, 96,
    107, 108, 121, 122, 57, 58, 69, 70, 63, 64,
    75, 76, 61, 62, 73, 74, 109, 110, 123, 124,
    89, 90, 103, 104, 59, 60, 71, 72, 91, 92,
    105, 106, 137, 138, 149, 150, 135, 136, 147, 148,
    85, 86, 99, 100, 111, 112, 125, 126, 115, 116,
    129, 130, 113, 114, 127, 128, 119, 120, 133, 134,
    87, 88, 101, 102, 117, 118, 131, 132, 139, 140,
    151, 152, 143, 144, 155, 156, 141, 142, 153, 154,
    145, 146, 157, 158);

// Grid index (x, y, level) of each node relative to the grid in its corresponding level
const ivec3[gNumNodes] gNodeToGridIndices = ivec3[](
	ivec3(0, 0, 0), ivec3(1, 0, 0), ivec3(2, 0, 0), ivec3(3, 0, 0), ivec3(4, 0, 0), ivec3(5, 0, 0),
    ivec3(0, 1, 0), ivec3(1, 1, 0), ivec3(2, 1, 0), ivec3(3, 1, 0), ivec3(4, 1, 0), ivec3(5, 1, 0),
    ivec3(0, 2, 0), ivec3(1, 2, 0), ivec3(2, 2, 0), ivec3(3, 2, 0), ivec3(4, 2, 0), ivec3(5, 2, 0),
    ivec3(0, 3, 0), ivec3(1, 3, 0), ivec3(2, 3, 0), ivec3(3, 3, 0), ivec3(4, 3, 0), ivec3(5, 3, 0),
    ivec3(6, 0, 1), ivec3(7, 0, 1), ivec3(6, 1, 1), ivec3(7, 1, 1), ivec3(8, 0, 1), ivec3(9, 0, 1),
    ivec3(8, 1, 1), ivec3(9, 1, 1), ivec3(10, 0, 1), ivec3(11, 0, 1), ivec3(10, 1, 1), ivec3(11, 1, 1),
    ivec3(4, 2, 1), ivec3(5, 2, 1), ivec3(4, 3, 1), ivec3(5, 3, 1), ivec3(2, 2, 1), ivec3(3, 2, 1),
    ivec3(2, 3, 1), ivec3(3, 3, 1), ivec3(6, 2, 1), ivec3(7, 2, 1), ivec3(6, 3, 1), ivec3(7, 3, 1), 
    ivec3(8, 2, 1), ivec3(9, 2, 1), ivec3(8, 3, 1), ivec3(9, 3, 1), ivec3(10, 2, 1), ivec3(11, 2, 1),
    ivec3(10, 3, 1), ivec3(11, 3, 1), ivec3(0, 4, 1), ivec3(1, 4, 1), ivec3(0, 5, 1), ivec3(1, 5, 1),
    ivec3(2, 4, 1), ivec3(3, 4, 1), ivec3(2, 5, 1), ivec3(3, 5, 1), ivec3(4, 4, 1), ivec3(5, 4, 1),
    ivec3(4, 5, 1), ivec3(5, 5, 1), ivec3(6, 4, 1), ivec3(7, 4, 1), ivec3(6, 5, 1), ivec3(7, 5, 1),
    ivec3(8, 4, 1), ivec3(9, 4, 1), ivec3(8, 5, 1), ivec3(9, 5, 1), ivec3(0, 6, 1), ivec3(1, 6, 1),
    ivec3(0, 7, 1), ivec3(1, 7, 1), ivec3(2, 6, 1), ivec3(3, 6, 1), ivec3(2, 7, 1), ivec3(3, 7, 1),
    ivec3(4, 6, 1), ivec3(5, 6, 1), ivec3(4, 7, 1), ivec3(5, 7, 1), ivec3(6, 6, 1), ivec3(7, 6, 1),
    ivec3(6, 7, 1), ivec3(7, 7, 1), ivec3(8, 6, 1), ivec3(9, 6, 1), ivec3(8, 7, 1), ivec3(9, 7, 1),
    ivec3(18, 2, 2), ivec3(19, 2, 2), ivec3(18, 3, 2), ivec3(19, 3, 2), ivec3(6, 8, 2), ivec3(7, 8, 2),
    ivec3(6, 9, 2), ivec3(7, 9, 2), ivec3(6, 10, 2), ivec3(7, 10, 2), ivec3(6, 11, 2), ivec3(7, 11, 2),
    ivec3(0, 10, 2), ivec3(1, 10, 2), ivec3(0, 11, 2), ivec3(1, 11, 2), ivec3(16, 8, 2), ivec3(17, 8, 2),
    ivec3(16, 9, 2), ivec3(17, 9, 2), ivec3(2, 10, 2), ivec3(3, 10, 2), ivec3(2, 11, 2), ivec3(3, 11, 2),
    ivec3(2, 12, 2), ivec3(3, 12, 2), ivec3(2, 13, 2), ivec3(3, 13, 2), ivec3(8, 8, 2), ivec3(9, 8, 2),
    ivec3(8, 9, 2), ivec3(9, 9, 2), ivec3(14, 8, 2), ivec3(15, 8, 2), ivec3(14, 9, 2), ivec3(15, 9, 2),
    ivec3(12, 8, 2), ivec3(13, 8, 2), ivec3(12, 9, 2), ivec3(13, 9, 2), ivec3(6, 12, 2), ivec3(7, 12, 2),
    ivec3(6, 13, 2), ivec3(7, 13, 2), ivec3(12, 10, 2), ivec3(13, 10, 2), ivec3(12, 11, 2), ivec3(13, 11, 2),
    ivec3(10, 8, 2), ivec3(11, 8, 2), ivec3(10, 9, 2), ivec3(11, 9, 2), ivec3(14, 10, 2), ivec3(15, 10, 2),
    ivec3(14, 11, 2), ivec3(15, 11, 2), ivec3(6, 14, 2), ivec3(7, 14, 2), ivec3(6, 15, 2), ivec3(7, 15, 2),
    ivec3(2, 14, 2), ivec3(3, 14, 2), ivec3(2, 15, 2), ivec3(3, 15, 2), ivec3(8, 10, 2), ivec3(9, 10, 2),
    ivec3(8, 11, 2), ivec3(9, 11, 2), ivec3(8, 12, 2), ivec3(9, 12, 2), ivec3(8, 13, 2), ivec3(9, 13, 2),
    ivec3(12, 12, 2), ivec3(13, 12, 2), ivec3(12, 13, 2), ivec3(13, 13, 2), ivec3(10, 12, 2), ivec3(11, 12, 2),
    ivec3(10, 13, 2), ivec3(11, 13, 2), ivec3(16, 12, 2), ivec3(17, 12, 2), ivec3(16, 13, 2), ivec3(17, 13, 2),
    ivec3(10, 10, 2), ivec3(11, 10, 2), ivec3(10, 11, 2), ivec3(11, 11, 2), ivec3(14, 12, 2), ivec3(15, 12, 2),
    ivec3(14, 13, 2), ivec3(15, 13, 2), ivec3(8, 14, 2), ivec3(9, 14, 2), ivec3(8, 15, 2), ivec3(9, 15, 2),
    ivec3(12, 14, 2), ivec3(13, 14, 2), ivec3(12, 15, 2), ivec3(13, 15, 2), ivec3(10, 14, 2), ivec3(11, 14, 2),
    ivec3(10, 15, 2), ivec3(11, 15, 2), ivec3(14, 14, 2), ivec3(15, 14, 2), ivec3(14, 15, 2), ivec3(15, 15, 2));

// The bottom left child index of each node, may be -1 if no child in the quadrant
// Note: Nodes on the highest level cannot have child nodes, so including all these
// -1s is superfluous. But it might help to understand the sample better.
const int[gNumNodes] gChildIndices = int[](
    -1, -1, -1, 24, 28, 32, -1, 40, 36, 44,
    48, 52, 56, 60, 64, 68, 72, -1, 76, 80,
    84, 88, 92, -1, -1, -1, -1, -1, -1, -1,
    -1, 96, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, 108, 116,
    -1, 100, -1, 104, 124, 144, 160, 180, 132, 128,
    140, 148, 112, -1, -1, -1, -1, 120, -1, 156,
    -1, 136, -1, 152, 164, 172, 188, 196, 168, 184,
    192, 200, 176, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1);

const vec2 gInverseLevel0CellSize = 1.0 / gLevel0CellSize;
const vec2 gSmallestCellSize = gLevel0CellSize / float(1 << (gNumGrids - 1));
const vec2 gInverseSmallestCellSize = 1.0 / gSmallestCellSize;
const vec2 gUpper = vec2(gLevel0Dimensions) * gLevel0CellSize + gOrigin;
const vec2 gGridSize = gUpper - gOrigin;
const vec2 gInverseGridSize = 1.0 / gGridSize;

int getChildIndex(int nodeIndex) { return gChildIndices[nodeIndex]; }

int convertNodeToCellIndex(int nodeIndex) { return (nodeIndex < 0) ? -1 : gNodeToCellIndices[nodeIndex]; }

vec2 getCellSizeOfLevel(int level) { return gSmallestCellSize * float(1 << (gNumGrids - level - 1)); }

float getPowerOfTwo(int exponent) { return intBitsToFloat((127 + exponent) << 23); }

vec2 getInverseCellSizeOfLevel(int level) { return gInverseSmallestCellSize * getPowerOfTwo(level + 1 - gNumGrids); }

ivec2 getDimensionsOfLevel(int level) { return gLevel0Dimensions << level; }

ivec2 getLevel0GridIndex(vec2 position) { return ivec2(floor((position - gOrigin) * gInverseLevel0CellSize)); }

vec2 getNodePosition(ivec3 gridIndex) { return getCellSizeOfLevel(gridIndex.z) * (vec2(gridIndex.xy) + vec2(0.5)) + gOrigin; }

ivec2 mixIvec2Bool(ivec2 a, ivec2 b, bvec2 c) { return ivec2(c.x ? b.x : a.x, c.y ? b.y : a.y); }

// Traverses the quadtree to get the node index of the cell that covers the position
int getLeafNodeIndex(vec2 samplePosition, out ivec3 gridIndex)
{
	ivec2 level0GridExtents = gLevel0Dimensions - 1;
	ivec2 level0GridIndex = getLevel0GridIndex(samplePosition);

	if (any(lessThan(ivec4(level0GridIndex, level0GridExtents), ivec4(0, 0, level0GridIndex))))
	{
		return -1;
	}
	else
	{
		ivec3 currentGridIndex = ivec3(level0GridIndex, 0);
		int currentNodeIndex = level0GridIndex.y * gLevel0Dimensions.x + level0GridIndex.x;

		int bottomLeftChildIndex = getChildIndex(currentNodeIndex);

        // Traverse the quadtree from level 0 to the highest level - This traversal can be replaced
		// by a pre-computed lookup table to make sampling a constant-time operation at the cost of
		// additional video memory
		while (bottomLeftChildIndex != -1)
		{
			vec2 currentPosition = getNodePosition(currentGridIndex).xy;
			bvec2 xy = greaterThan(samplePosition, currentPosition);

			currentNodeIndex = bottomLeftChildIndex + (int(xy.y) << 1) + int(xy.x);
			bottomLeftChildIndex = getChildIndex(currentNodeIndex);

			currentGridIndex.xy = (currentGridIndex.xy << 1) + ivec2(xy);
			currentGridIndex.z += 1;
		}

		gridIndex = currentGridIndex;

		return currentNodeIndex;
	}
}

// Traverses the quadtree to get the node index of the cell that covers the node
int getLeafNodeIndex(ivec3 gridIndex, out ivec3 retrievedGridIndex)
{
	ivec2 currentLevelDimensions = getDimensionsOfLevel(gridIndex.z);

	if ((any(lessThan(gridIndex, ivec3(0)))) || (any(greaterThanEqual(gridIndex.xy, currentLevelDimensions))))
	{
		retrievedGridIndex = ivec3(-1);

		return -1;
	}
	else
	{
		ivec2 level0GridIndex = gridIndex.xy >> gridIndex.z;
		int currentNodeIndex = level0GridIndex.y * gLevel0Dimensions.x + level0GridIndex.x;
		retrievedGridIndex = ivec3(level0GridIndex, 0);

		if (gNumGrids > 1)
		{
			int currentLevel = 0;
			int bottomLeftChildIndex = getChildIndex(currentNodeIndex);

			// Traverse the quadtree from level 0 to the highest level - This traversal can be replaced
			// by a pre-computed lookup table to make sampling a constant-time operation at the cost of
			// additional video memory
			while ((bottomLeftChildIndex != -1) && (currentLevel < gridIndex.z))
			{
				currentLevel++;

				retrievedGridIndex = ivec3(gridIndex.xy >> (gridIndex.z - currentLevel), currentLevel);
				ivec2 quadrantOffset = retrievedGridIndex.xy & 1;

				currentNodeIndex = bottomLeftChildIndex + (quadrantOffset.y << 1) + quadrantOffset.x;
				bottomLeftChildIndex = getChildIndex(currentNodeIndex);
			}
		}

		return currentNodeIndex;
	}
}

#define NearestNeighbor 0
#define Bilinear 1
#define Bicubic 2
#define BSpline 3