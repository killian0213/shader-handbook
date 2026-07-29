// Buffer B (buffer) — Where the River Goes (+ PostFX) by P_Malin
// https://www.shadertoy.com/view/XdG3zd

// Where the River Goes (+PostFX)
// @P_Malin

// Depth of field

#define BLUR_TAPS 32

float fGolden = 3.141592 * (3.0 - sqrt(5.0));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
    vec4 vSample = textureLod( iChannel0, vUV, 0.0 ).rgba;
	float fCoC = abs(vSample.w);
	        
	vec3 vResult = vec3(0.0);
    float fTot = 0.0;
        
    vec2 vangle = vec2(0.0,fCoC); // Start angle
    
    vResult.rgb = vSample.rgb * fCoC;
    fTot += fCoC;
    
    float fBlurTaps = float(BLUR_TAPS);
    
    float f = 0.0;
    float fIndex = 0.0;
    for(int i=1; i<BLUR_TAPS; i++)
    {
        vec2 vTapUV = vUV;
                
        float fRand = f;
        
        // http://blog.marmakoide.org/?p=1
        
        float fTheta = fRand * fGolden * fBlurTaps;
        float fRadius = fCoC * sqrt( fRand * fBlurTaps ) / sqrt( fBlurTaps );        
        
        vTapUV += vec2( sin(fTheta), cos(fTheta) ) * fRadius;
        
        vec4 vTapSample = textureLod( iChannel0, vTapUV, 0.0 ).rgba;
        if( sign(vTapSample.a) == sign(vSample.a) )
        {
            float fWeight = max( 0.001, abs(vTapSample.a) );

            vResult += vTapSample.rgb * fWeight;
        	fTot += fWeight;
        }
        f += 1.0 / fBlurTaps;
        fIndex += 1.0;
    }
    vResult /= fTot;
        
	fragColor = vec4(vResult, 1.0);
}

