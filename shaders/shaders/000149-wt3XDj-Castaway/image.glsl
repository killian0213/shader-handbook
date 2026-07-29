// Image (image) — Castaway by P_Malin
// https://www.shadertoy.com/view/wt3XDj

//     _____             _                                
//    / ____|           | |                               
//   | |      __ _  ___ | |_  __ _ __      __ __ _  _   _ 
//   | |     / _` |/ __|| __|/ _` |\ \ /\ / // _` || | | |
//   | |____| (_| |\__ \| |_| (_| | \ V  V /| (_| || |_| |
//    \_____|\__,_||___/ \__|\__,_|  \_/\_/  \__,_| \__, |
//                                                   __/ |
//                                                  |___/ 

// Castaway by @P_Malin

// https://www.shadertoy.com/view/wt3XDj

// Controls:
// SPACE = Toggle Flycam
// WASD / click + mouse to move
// Shift = Move faster

// YouTube Video Here: https://youtu.be/bSg5nb_UTVM

// ASCII Comments: http://patorjk.com/software/taag/#p=display&h=2&c=c%2B%2B&f=Big&t=My%20Comment

//    _____                               _____ _               _                      _____          _   ______    
//   |_   _|                             / ____| |             | |                    |  __ \        | | |  ____|   
//     | |  _ __ ___   __ _  __ _  ___  | (___ | |__   __ _  __| | ___ _ __   ______  | |__) |__  ___| |_| |____  __
//     | | | '_ ` _ \ / _` |/ _` |/ _ \  \___ \| '_ \ / _` |/ _` |/ _ \ '__| |______| |  ___/ _ \/ __| __|  __\ \/ /
//    _| |_| | | | | | (_| | (_| |  __/  ____) | | | | (_| | (_| |  __/ |             | |  | (_) \__ \ |_| |   >  < 
//   |_____|_| |_| |_|\__,_|\__, |\___| |_____/|_| |_|\__,_|\__,_|\___|_|             |_|   \___/|___/\__|_|  /_/\_\
//                           __/ |                                                                                  
//                          |___/                                                                                   

float Vignette( vec2 uv, float size )
{
    float d = length( (uv - 0.5f) * 2.0f ) / length(vec2(1.0));
    
    d /= size;
    
    float s = d * d * ( 3.0f - 2.0f * d );
    
    float v = mix ( d, s, 0.6f );
    
    return max(0.0, 1.0f - v);
}


vec3 PostProcessColour( vec3 color )
{
#if EQUIRECTANGULAR_PROJECTION
    float exposure = 0.5f;    
    color = color * exposure;
    
    float gamma = 2.2f;    
    color = pow( color, vec3( 1.0f / gamma ) );    
#else
    float exposure = 1.0f;    
    color = color * exposure;
    
    color = 1.0f - exp( -color );    
    float gamma = 2.2f;    
    color = pow( color, vec3( 1.0f / gamma ) );
            
#endif
    return color;
}


#define ENABLE_DOF

float GetCoC( float fDistance, float fPlaneInFocus )
{
#ifdef ENABLE_DOF    
	// http://http.developer.nvidia.com/GPUGems/gpugems_ch23.html

    float fAperture = min(1.0, fPlaneInFocus * fPlaneInFocus * 0.5);
    float fFocalLength = 0.05;
    
	return abs(fAperture * (fFocalLength * (fDistance - fPlaneInFocus)) /
          (fDistance * (fPlaneInFocus - fFocalLength)));  
#else
    return 0.0f;
#endif    
}

vec3 SampleWithDOF( ivec2 pos, float planeInFocus )
{
	vec4 vCenterSample = texelFetch( iChannel0, pos, 0 );    
    
    //return vec3(1) /vCenterSample.w;
    
    float CoC = GetCoC( vCenterSample.w, planeInFocus );
        
	#define DOF_SIZE 6
    #define DOF_SIZE_F float( DOF_SIZE )
    
    #define DOF_BLOOM_STRENGTH 2.0
    
    CoC = CoC * 500.0;
        
    float testRadius = CoC * CoC;
    
    bool bloom = false;
    if ( CoC <= 1.0f )
    {
        testRadius = DOF_SIZE_F;
        bloom = true;
    }
    
	vec3 vResult = vec3(0.0);    
    float fTot = 0.0;
    
    {
        float fY = -DOF_SIZE_F;
        for( int y=-DOF_SIZE; y<=DOF_SIZE; y++ )
        {
            float fX = -DOF_SIZE_F;
            for( int x=-DOF_SIZE; x<=DOF_SIZE; x++ )
            {            
                vec2 vOffset = vec2( fX, fY );
                float r2 = dot( vOffset, vOffset );
                if ( r2 < testRadius )
                {                
                    ivec2 iOffset = ivec2( x,y );
                    vec4 vTapSample = texelFetch( iChannel0, pos + iOffset, 0 );
                    
                    float fWeight = 1.0f;
                    
                    if ( bloom )
                    {
		            	fWeight = exp2( -r2 * DOF_BLOOM_STRENGTH );                        
                    }
                    
                    vResult += vTapSample.rgb * fWeight;
                    fTot += fWeight;
                }
                fX+=1.0f;
            }
            fY+=1.0f;
        }
    }
    
    vResult = vResult / fTot;
    
    return vResult;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;

	vec4 vCenterScreenSample = texelFetch( iChannel0, ivec2(iResolution.xy / 2.), 0 );
    float planeInFocus = vCenterScreenSample.w;
    
#if EQUIRECTANGULAR_PROJECTION
    vec3 sceneColour = texelFetch( iChannel0, ivec2( fragCoord ), 0 ).rgb;
    //vec3 sceneColour = SampleWithDOF( ivec2( fragCoord ), planeInFocus );
    sceneColour*= 0.5;
#else
    vec3 sceneColour = SampleWithDOF( ivec2( fragCoord ), planeInFocus );
    sceneColour.rgb *= 0.2 + 0.8 * Vignette( uv, 1.0 );
#endif
    
    
    vec3 outputColour = PostProcessColour( sceneColour.rgb );    

#if 0
    CameraState cam;
    Cam_LoadState( cam, iChannel3, ivec2(0,0) );
    
    Cam_DebugOverlay( outputColour, cam, uv, planeInFocus );
#endif
        
    fragColor = vec4(outputColour, 1.0);    
}
