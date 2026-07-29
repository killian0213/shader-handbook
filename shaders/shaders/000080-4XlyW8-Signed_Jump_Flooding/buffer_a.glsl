// Buffer A (buffer) — Signed Jump Flooding by iq
// https://www.shadertoy.com/view/4XlyW8


// some binary shape (0=inside, 1=outside)
float shape( in vec2 p )
{
    // circle
    // return length(p)<0.5?0.0:1.0;
    
    // mandelbrot set
    vec2 z = vec2(0.0);
    vec2 c = p - vec2(0.75,0.0);
    for( int i=0; i<32; i++ )
    {
        z = vec2(z.x*z.x-z.y*z.y,2.0*z.x*z.y) + c;
        if( dot(z,z)>4.0 ) return 1.0;
    }
    return 0.0;
}


//------------------------------------------------------------------------------------------
// 32 bit buffer layout. Each entry stores the closest point and some metadata:
//
// 00-14 : x coordinate, from 0 to 32,767
// 15    : set (1=interior, 0=exterior)
// 16-31 : y coordinate, from 0 to 65,534. Value FFFF is reserved to signal unresolved pixel
//------------------------------------------------------------------------------------------

// (x, y, set, resolved)
ivec4 unpack( uint d )
{
    uint x = d & 0x7fffu;
    uint y = d >> 16;
    uint s = d & 0x8000u;
    uint r = (y==0xffffu)?0u:1u;
    return ivec4(x,y,s,r);
}

// we only pack resolved pixels
uint pack( ivec2 p, int s )
{
    return uint(p.x)|uint(s)|(uint(p.y)<<16);
}

// initialize buffer (d>=0 is the interior set, d<1 is the exterior set)
uint init( float d ) 
{
    return d<0.5 ? 0xffffffffu : 0xffff7fffu;
}

//------------------------------------------------------------------------------------------

// this could be done in pure integer arithmetic if we had uin64_t available to us
float dot2( in ivec2 x ) { return dot(vec2(x),vec2(x)); }

int computeNumPasses( in ivec2 resolution )
{
    int dim = max( resolution.x, resolution.y );
    
    // would be easier if we could ise findMSB() from GLSL 4.0.
    // but for now this will do (I want to stay in integer land)
    #if 1
        dim = max(dim-1,0);
        int r = 0;
        if( dim > 0xFFFF ) { dim >>= 16; r |= 16; }
        if( dim > 0x00FF ) { dim >>=  8; r |=  8; }
        if( dim > 0x000F ) { dim >>=  4; r |=  4; }
        if( dim > 0x0003 ) { dim >>=  2; r |=  2; }
        if( dim > 0x0001 ) { dim >>=  1; r |=  1; }
        return r+1;
    #else
        if( dim>=32768 ) return 16;
        if( dim>=16384 ) return 15;
        if( dim>= 8192 ) return 14;
        if( dim>= 4096 ) return 13;
        if( dim>= 2048 ) return 12;
        if( dim>= 1024 ) return 11;
        if( dim>=  512 ) return 10;
        if( dim>=  256 ) return  9;
        if( dim>=  128 ) return  8;
        if( dim>=   64 ) return  7;
        if( dim>=   32 ) return  6;
        if( dim>=   16 ) return  5;
        if( dim>=    8 ) return  4;
        if( dim>=    4 ) return  3;
        if( dim>=    2 ) return  2;
                         return  1;
    #endif
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int frame = iFrame; // & 255;
    
    int numPasses = computeNumPasses( ivec2(iResolution.xy) );
    
    //---------------------------------------------------------------------------------
    // First frame we mark the interior and exterior pixel sets
    //---------------------------------------------------------------------------------
    if( frame==0 )
    {
        vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
        float d = shape(p);
        
        // initialize 32 bit buffer
        fragColor.x = uintBitsToFloat(init(d));
    }
    //---------------------------------------------------------------------------------
    // Next "numPasses" number of frames, perform one Jump Flood algorithm pass
    //---------------------------------------------------------------------------------
    else if( (frame>=1) && (frame<=numPasses) )
    {
        // read 32 bits from buffer
        ivec2 p_pixl = ivec2(fragCoord);
        uint p_data_packed = floatBitsToUint(texelFetch(iChannel0, p_pixl, 0).r);
        ivec4 p_data = unpack(p_data_packed);
        
        // distance to closest known pixel on the complementary set (interior vs exterior)
        float currdis = (p_data.w==1) ? dot2( p_pixl-p_data.xy ) : 1e20;
        
        int width = (1<<(numPasses-frame));

        // pre-clip scan window (removes in-loop conditionals)
        int minx = p_pixl.x-width < 0                    ? 0 : -1;
        int miny = p_pixl.y-width < 0                    ? 0 : -1;
        int maxx = p_pixl.x+width > int(iResolution.x)-1 ? 0 :  1;
        int maxy = p_pixl.y+width > int(iResolution.y)-1 ? 0 :  1;
        
        for( int y=miny; y<=maxy; y++ )
        for( int x=minx; x<=maxx; x++ )
        {
            // 1. gather a distant pixel
            ivec2 q_offs = ivec2(x,y)*width;
            ivec2 q_pixl = p_pixl + q_offs;
            ivec4 q_data = unpack(floatBitsToUint(texelFetch(iChannel0,q_pixl,0).x));
        
            // 2. does it belong to the complementary set?
            if( q_data.z != p_data.z ) 
            {
                // if so, is it closer than the closest known pixel so far?
                float dis = dot2(q_offs);
                if( dis < currdis )
                {
                    // if so, update our record
                    currdis = dis;
                    p_data_packed = pack(q_pixl.xy,p_data.z);
                }     
           }
           
           // 3. or is it maybe an already resolved pixel?
           else if( q_data.w==1 )
           {
                // if so, is its closest known pixel closer than the closest known pixel so far?
                float dis = dot2(q_data.xy-p_pixl);
                if( dis < currdis )
                {
                    // if so, update our record
                    currdis = dis;
                    p_data_packed = pack(q_data.xy,p_data.z);
                }
            }
        }
        
        // write 32 bits to buffer
        fragColor.r = uintBitsToFloat(p_data_packed);
    }
    //---------------------------------------------------------------------------------
    // then copy content (because Shadertoy ping-pongs two textures per pass)
    //---------------------------------------------------------------------------------
    else if( frame==numPasses+1 )
    {
        fragColor = texelFetch(iChannel0,ivec2(fragCoord),0);
    }
    //---------------------------------------------------------------------------------
    // Rest of frames do nothing, we are done here
    //---------------------------------------------------------------------------------
    else
    {
        discard;
    }
}