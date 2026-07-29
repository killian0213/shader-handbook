// Buffer D (buffer) — Meta CRT by P_Malin
// https://www.shadertoy.com/view/4dlyWX

// Meta CRT - @P_Malin
// https://www.shadertoy.com/view/4dlyWX#
// In which I add and remove aliasing

// Temporal Anti-aliasing Pass

#define ENABLE_TAA

#define iChannelCurr iChannel0
#define iChannelHistory iChannel1

vec3 Tonemap( vec3 x )
{
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}

vec3 TAA_ColorSpace( vec3 color )
{
    return Tonemap(color);
}


void mainImage( out vec4 vFragColor, in vec2 vFragCoord )
{
    CameraState camCurr;
	Cam_LoadState( camCurr, iChannelCurr, ivec2(0) );
    
    CameraState camPrev;
	Cam_LoadState( camPrev, iChannelHistory, ivec2(0) );

    vec2 vUV = vFragCoord.xy / iResolution.xy;
 	vec2 vUnJitterUV = vUV - camCurr.vJitter / iResolution.xy;    
    
    vFragColor = textureLod(iChannelCurr, vUnJitterUV, 0.0);
    
    
#ifdef ENABLE_TAA
    vec3 vRayOrigin, vRayDir;
    Cam_GetCameraRay( vUV, iResolution.xy, camCurr, vRayOrigin, vRayDir );    
    float fDepth;
    int iObjectId;
    vec4 vCurrTexel = texelFetch( iChannelCurr, ivec2(vFragCoord.xy), 0);
    fDepth = DecodeDepthAndObjectId( vCurrTexel.w, iObjectId );
    vec3 vWorldPos = vRayOrigin + vRayDir * fDepth;
    
    vec2 vPrevUV = Cam_GetUVFromWindowCoord( Cam_WorldToWindowCoord(vWorldPos, camPrev), iResolution.xy );// + camPrev.vJitter / iResolution.xy;
        
    if ( all( greaterThanEqual( vPrevUV, vec2(0) )) && all( lessThan( vPrevUV, vec2(1) )) )
	{
        vec3 vMin = vec3( 10000);
        vec3 vMax = vec3(-10000);
        
	    ivec2 vCurrXY = ivec2(floor(vFragCoord.xy));    
        
        int iNeighborhoodSize = 1;
        for ( int iy=-iNeighborhoodSize; iy<=iNeighborhoodSize; iy++)
        {
            for ( int ix=-iNeighborhoodSize; ix<=iNeighborhoodSize; ix++)
            {
                ivec2 iOffset = ivec2(ix, iy);
		        vec3 vTest = TAA_ColorSpace( texelFetch( iChannelCurr, vCurrXY + iOffset, 0 ).rgb );
                                
                vMin = min( vMin, vTest );
                vMax = max( vMax, vTest );
            }
        }
        
        float epsilon = 0.001;
        vMin -= epsilon;
        vMax += epsilon;
        
        float fBlend = 0.0f;
        
        //ivec2 vPrevXY = ivec2(floor(vPrevUV.xy * iResolution.xy));
        vec4 vHistory = textureLod( iChannelHistory, vPrevUV, 0.0 );

        vec3 vPrevTest = TAA_ColorSpace( vHistory.rgb );
        if( all( greaterThanEqual(vPrevTest, vMin ) ) && all( lessThanEqual( vPrevTest, vMax ) ) )
        {
            fBlend = 0.9;
            //vFragColor.r *= 0.0;
        }
        
        vFragColor.rgb = mix( vFragColor.rgb, vHistory.rgb, fBlend);
    }  
    else
    {
        //vFragColor.gb *= 0.0;
    }

#endif
    
    vFragColor.rgb += (hash13( vec3( vFragCoord, iTime ) ) * 2.0 - 1.0) * 0.03;
    
	Cam_StoreState( ivec2(0), camCurr, vFragColor, ivec2(vFragCoord.xy) );    
	Cam_StoreState( ivec2(3,0), camPrev, vFragColor, ivec2(vFragCoord.xy) );    
}
