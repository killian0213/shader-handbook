// Buf B (buffer) — Constellations by anomes
// https://www.shadertoy.com/view/MsjyW3

// --------------------------
// SORT POINTS BY MACRO-BLOCK
// --------------------------


// must be the same as in 'Main Image'
#define POINTS_SIZE 12
#define POINTS_NUMBER POINTS_SIZE*POINTS_SIZE

// 
#define BLOCK_SIZE 10
#define BLOCK_NUMBER BLOCK_SIZE*BLOCK_SIZE

#define DEPTH_OF_FIELD 3.
#define SPACING 2.8
#define POSITION vec2(  1.4  ,  0.7  )
#define SCALE    vec2(  1.1  ,  0.5  )
#define TIME iTime



vec4 pointAtIndex(int index, int blockIndex)
{
    vec2 pos = vec2(  float(index)+0.5  ,  float(blockIndex)+0.5  )  /  iResolution.xy;
    return texture(iChannel0, pos);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 color = vec4(-100.);
    if( fragCoord.x <= float(POINTS_NUMBER) && fragCoord.y < float(BLOCK_NUMBER) )
    {
        int targetIndex = int(fragCoord.x);
        int blockIndex = int(fragCoord.y);
        int k = 0;
        for(int index=0; index<POINTS_NUMBER; index++)
        {
			vec4 point = pointAtIndex(index, blockIndex);
            if( point.w < 0. )
            {
                continue;
            }
            if( k == targetIndex  )
            {
                color = point;
                break;
            }
            k++;
        }
    }
    fragColor = color;
}