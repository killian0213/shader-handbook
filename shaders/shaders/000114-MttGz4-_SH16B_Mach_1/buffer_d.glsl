// Buffer D (buffer) — [SH16B] Mach 1 by P_Malin
// https://www.shadertoy.com/view/MttGz4

// Bloom

///////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 gBloomSize = min( vec2(320.0, 240.0), iResolution.xy );
    
	vec2 vUV = fragCoord.xy / gBloomSize;
    
    if ( vUV.x > 1.0 ) discard;
    if ( vUV.y > 1.0 ) discard;

    // output linear color
    //fragColor = texture( iChannel0, vUV );
    //return;
    
    #define KERNEL_SIZE 8
    #define BLOOM_STRENGTH 6.0
    #define KERNEL_SIZE_F float(KERNEL_SIZE)    
    
	vec3 vResult = vec3(0.0);
    
    float fTot = 0.0;
    
    float fY = -KERNEL_SIZE_F;
    for( int y=-KERNEL_SIZE; y<=KERNEL_SIZE; y++ )
    {
        float fX = -KERNEL_SIZE_F;
	    for( int x=-KERNEL_SIZE; x<=KERNEL_SIZE; x++ )
        {            

            vec2 vOffset = vec2( fX, fY );
            vec2 vTapUV =  (fragCoord.xy + vOffset + 0.5) / gBloomSize;

            vec4 vTapSample = textureLod( iChannel0, vTapUV, 0.0 ).rgba;
	        if( vTapUV.y < 1.0 / iResolution.y )
            {
               vTapSample = vec4(0.0);
            }
            
            vec2 vDelta = vOffset / KERNEL_SIZE_F;
            
            float f = dot( vDelta, vDelta );
            float fWeight = exp2( -f * BLOOM_STRENGTH );
            vResult += vTapSample.xyz * fWeight;
            fTot += fWeight;
            
	        fX += 1.0;
        }
        
        fY += 1.0;
    }
    vResult /= fTot; 
    
    vec4 vPrevSample = textureLod( iChannel1, vUV* gBloomSize / iResolution.xy, 0.0 ).rgba;
    vResult = max( vResult, vPrevSample.xyz * 0.3 );
    //vResult += vPrevSample.xyz * 0.9;
    
	fragColor = vec4(vResult, 1.0);
}
