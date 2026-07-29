// Buffer A (buffer) — GameOfLife by iq
// https://www.shadertoy.com/view/XstGRf

// I implemented three variants of Conway's Game of Life with
// three different interpretations: the regular one, as low
// pass filter and as a high pass filter. Tweak line 11 to see
// them all. More info here:
// https://iquilezles.org/articles/gameoflife/


// VARIANT = 0: traditional
// VARIANT = 1: as a convolution (low pass fiter)
// VARIANT = 2: as a convolution (high pass fiter)
#define VARIANT 1


int cell( in ivec2 p )
{
    ivec2 r = ivec2(textureSize(iChannel0, 0));
    p = (p+r) % r;
    return (texelFetch(iChannel0, p, 0 ).x > 0.5 ) ? 1 : 0;
}

float hash1( float n )
{
    return fract(sin(n)*138.5453123);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec2 px = ivec2( fragCoord );
    
    // traditional
    #if VARIANT==0
	int k =   cell(px+ivec2(-1,-1)) + cell(px+ivec2(0,-1)) + cell(px+ivec2(1,-1))
            + cell(px+ivec2(-1, 0))                        + cell(px+ivec2(1, 0))
            + cell(px+ivec2(-1, 1)) + cell(px+ivec2(0, 1)) + cell(px+ivec2(1, 1));
    int e = cell(px);
    float f = ( ((k==2)&&(e==1)) || (k==3) || (k==7)) ? 1.0 : 0.0;
    #endif

    // convolution (low pass filter)
    #if VARIANT==1
	int k =   cell(px+ivec2(-1,-1)) + cell(px+ivec2(0,-1)) + cell(px+ivec2(1,-1))
            + cell(px+ivec2(-1, 0)) + cell(px)*9           + cell(px+ivec2(1, 0))
            + cell(px+ivec2(-1, 1)) + cell(px+ivec2(0, 1)) + cell(px+ivec2(1, 1));
    float f = (k==3 || k==11 || k==12) ? 1.0 : 0.0;
    #endif
    
    // convolution (high pass filter)
    #if VARIANT==2 
	int k = cell(px+ivec2(-1,-1)) +   cell(px+ivec2(0,-1)) + cell(px+ivec2(1,-1))
          + cell(px+ivec2(-1, 0)) - 9*cell(px)             + cell(px+ivec2(1, 0))
          + cell(px+ivec2(-1, 1)) +   cell(px+ivec2(0, 1)) + cell(px+ivec2(1, 1));
    float f = (k==-7 || k==-6 || k==3) ? 1.0 : 0.0;
    #endif
    

    if( iFrame<2 ) f = step(0.9, hash1(fragCoord.x*13.0+hash1(fragCoord.y*71.1)));
	
	fragColor = vec4( f, 0.0, 0.0, 0.0 );
}