// Image (image) — Multiple Transparency by P_Malin
// https://www.shadertoy.com/view/XtyGWD

// Multiple Transparency - @P_Malin
// @P_Malin


vec3 Tonemap( vec3 x )
{
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}

vec3 ColorGrade( vec3 vColor )
{
    vec3 vHue = vec3(1.0, .7, .2);
    
    vec3 vGamma = 1.0 + vHue * 0.6;
    vec3 vGain = vec3(.9) + vHue * vHue * 8.0;
    
    vColor *= 2.0;
    
    float fMaxLum = 100.0;
    vColor /= fMaxLum;
    vColor = pow( vColor, vGamma );
    vColor *= vGain;
    vColor *= fMaxLum;  
    return vColor;
}

// Depth of field pass

#define BLUR_TAPS 32

float fGolden = 3.141592 * (3.0 - sqrt(5.0));

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;

    vec4 vSample = textureLod( iChannel0, vUV, 0.0 ).rgba;
	float fCoC = vSample.w;
    	
	vec3 vResult = vSample.rgb;
    float fTot = 0.0;
        
    vec2 vangle = vec2(0.0, fCoC); // Start angle
    
    if ( abs(fCoC) > 0.0 )
    {
        vResult.rgb  *= fCoC;
        fTot += fCoC;

        float fBlurTaps = float(BLUR_TAPS);

        for(int i=1; i<BLUR_TAPS; i++)
        {
            // http://blog.marmakoide.org/?p=1
            float t = float(i) / fBlurTaps;
            float fTheta = t * fBlurTaps * fGolden;
            float fRadius = fCoC * sqrt( t * fBlurTaps ) / sqrt( fBlurTaps );        

            vec2 vTapUV = vUV + vec2( sin(fTheta), cos(fTheta) ) * fRadius;

            vec4 vTapSample = textureLod( iChannel0, vTapUV, 0.0 ).rgba;
            {
                float fCoC2 = vTapSample.w;
                float fWeight = max( 0.001, fCoC2 );

                vResult += vTapSample.rgb * fWeight;
                fTot += fWeight;
            }
        }
        vResult /= fTot;
    }
        
	fragColor = vec4(vResult, 1.0);    
    
    float fExposure = 3.0;    
    
    fragColor.rgb = fragColor.rgb * fExposure;
    
    fragColor.rgb = ColorGrade( fragColor.rgb );
        
    fragColor.rgb = Tonemap( fragColor.rgb );
}