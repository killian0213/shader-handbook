// Image (image) — [SH18] Visage by P_Malin
// https://www.shadertoy.com/view/4lcyD8

//    ___ _____ _    _ __  ___ ___  __      ___                      
//   |  _/ ____| |  | /_ |/ _ \_  | \ \    / (_)                     
//   | || (___ | |__| || | (_) || |  \ \  / / _ ___  __ _  __ _  ___ 
//   | | \___ \|  __  || |> _ < | |   \ \/ / | / __|/ _` |/ _` |/ _ \
//   | | ____) | |  | || | (_) || |    \  /  | \__ \ (_| | (_| |  __/
//   | ||_____/|_|  |_||_|\___/_| |     \/   |_|___/\__,_|\__, |\___|
//   |___|                    |___|                        __/ |     
//                                                        |___/                                                                                                          
// https://www.shadertoy.com/view/4lcyD8
// [SH18] Visage - by @P_Malin

// Entry for the 2018 Shadertoy Competition 
// https://www.shadertoy.com/events/competition2018
// Theme "Human"

// Video Here: https://youtu.be/tuKlyJv2JEI

// Most of the interesting bits like scene rendering and materials are in Buffer A.

// Audio: https://soundcloud.com/silas-neptune/aqualight
// ASCII Comments: http://patorjk.com/software/taag/#p=display&h=2&c=c%2B%2B&f=Big&t=My%20Comment

// Controls:
// R - Use Reduced Resolution Rendering (a little faster)
// Space - flymode.
// When in flymode:
// WASD - move
// mouse - rotate
// shift - move faster 
// F - toggle look at camera
// G - toggle head turning

//    _____                               _____                                _ _   _             
//   |_   _|                             / ____|                              (_) | (_)            
//     | |  _ __ ___   __ _  __ _  ___  | |     ___  _ __ ___  _ __   ___  ___ _| |_ _  ___  _ __  
//     | | | '_ ` _ \ / _` |/ _` |/ _ \ | |    / _ \| '_ ` _ \| '_ \ / _ \/ __| | __| |/ _ \| '_ \ 
//    _| |_| | | | | | (_| | (_| |  __/ | |___| (_) | | | | | | |_) | (_) \__ \ | |_| | (_) | | | |
//   |_____|_| |_| |_|\__,_|\__, |\___|  \_____\___/|_| |_| |_| .__/ \___/|___/_|\__|_|\___/|_| |_|
//                           __/ |                            | |                                  
//                          |___/                             |_|                                  


#define iChannelSceneImage 	iChannel0
#define iChannelBloom 		iChannel1

#define SHOW_CAMERA_COORDS 0


///////////////////////////////////////////////

vec3 Tonemap( vec3 x )
{
    float a = 0.010;
    float b = 0.132;
    float c = 0.010;
    float d = 0.163;
    float e = 0.101;

    return ( x * ( a * x + b ) ) / ( x * ( c * x + d ) + e );
}


vec3 ApplyGrain( vec2 vUV, vec3 col, float amount )
{
    float h = hash13( vec3(vUV, iTime) );
    
    col *= (h * 2.0 - 1.0) * amount + (1.0f -amount);
    
    return col;
}


float GetVignetting( const in vec2 vUV, float fScale, float fPower, float fStrength )
{
	vec2 vOffset = (vUV - 0.5) * sqrt(2.0) * fScale;
	
	float fDist = max( 0.0, 1.0 - length( vOffset ) );
    
	float fShade = 1.0 - pow( fDist, fPower );
    
    fShade = 1.0 - fShade * fStrength;

	return fShade;
}

vec3 ColorGrade( vec3 vColor )
{
    vec3 vHue = vec3(1.0, .7, .2);
    
    vec3 vGamma = 1.0 + vHue * 0.6;
    vec3 vGain = vec3(.9) + vHue * vHue * 8.0;
    
    vColor *= 1.5;
    
    float fMaxLum = 100.0;
    vColor /= fMaxLum;
    vColor = pow( vColor, vGamma );
    vColor *= vGain;
    vColor *= fMaxLum;  
    return vColor;
}

vec4 SampleBloom( vec2 vUV )
{
    vec2 vBloomSize = iResolution.xy / 4.0;//min( vec2(320.0, 240.0), iResolution.xy );
    
    vec2 vBloomCoord = vUV * vBloomSize;
    vBloomCoord.y += 1.0; // bottom row of bloom is used for data
    
	vec4 vBloomSample = textureLod( iChannelBloom, vBloomCoord / iResolution.xy, 0.0 ).rgba;
    
    return vBloomSample;
}

vec3 SampleImage( vec2 vUV, int image )
{
    if ( image >= 0 )
    {
        vUV.x *= 0.5;
    }
    
    if (image > 0 )
    {
        vUV.x += 0.5;
    }
    
	vec4 vImageSample = textureLod( iChannelSceneImage, vUV, 0.0 ).rgba;

    vec4 vBloomSample = SampleBloom( vUV );    
    const float fBloomAmount = 0.1;  
    return mix( vImageSample.rgb, vBloomSample.rgb, fBloomAmount );    
    
    //return vImageSample.rgb;
}

vec2 DistortUV( vec2 vUV, float f )
{
    vUV -= 0.5;

    float fScale = 0.0075;
    
    float r1 = 1. + f * fScale;
    
    vec3 v = vec3(vUV, sqrt( r1 * r1 - dot(vUV, vUV) ) );
    
    v = normalize(v);
    vUV = v.xy;
    
    
    vUV += 0.5;
    
    return vUV;
}

vec3 SampleImage2( vec2 vUV, vec2 vScreen, int image )
{
    //return SampleImage( vUV, image );
    
    vec3 a = SampleImage( DistortUV( vUV, 1.0 ), image );
    vec3 b = SampleImage( DistortUV( vUV, 0.0 ), image );
    vec3 c = SampleImage( DistortUV( vUV, -1.0 ), image );
    
    vec3 vResult = vec3(0);
    
    vec3 wa = vec3(1., .5, .1);
    vec3 wb = vec3(.5, 1., .5);
    vec3 wc = vec3(.1, .5, 1.);
    
    vResult += a * wa;
    vResult += b * wb;
    vResult += c * wc;
    
    vResult /= wa + wb + wc;
    
    return vResult;
}


void Process( out vec4 fragColor, vec2 vUV, vec2 vScreen, int image )
{
    vec3 vResult = SampleImage2( vUV, vScreen, image );
    
    //vResult = texelFetch( iChannel0, ivec2( fragCoord.xy ), 0 ).rgb;
    
    float fShade = GetVignetting( vUV, 0.8, 1.0, 1.0 );
    
    vResult *= fShade;
    
	vResult = ApplyGrain( vUV, vResult, 0.15 );      
    
    vec3 vFlare = vec3(0.0)
        + SampleBloom((vScreen)).rgb * 0.1
        + SampleBloom((vScreen - 0.5)*-0.5 + 0.5).rgb * 0.005
        + SampleBloom((vScreen - 0.5)*-.9 + 0.5).rgb * 0.0025
        + SampleBloom((vScreen - 0.5)*0.2 + 0.5).rgb * 0.00125
        ;
    
    float flareTex = texture(iChannel2, vUV ).r;
    flareTex = (flareTex * flareTex * 0.75 + 0.25) * 1.5;
    //flareTex = 1.0;
    vResult += vFlare * flareTex;
    
    vResult = vResult;
    
    //if ( vUV.x > sin(iTime)*0.5+0.5 )
    {
    	vResult = ColorGrade( vResult );
    }
    
    // fade in
    vResult = vResult * min( 1.0, iTime / 10.0 );
    
    vResult = Tonemap( vResult );
    fragColor.rgb = vResult;
    fragColor.a = 1.0;      
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 vUV = fragCoord.xy / iResolution.xy;
    
    Process( fragColor, vUV, vUV, -1 );   
        
#if SHOW_CAMERA_COORDS  
    CameraState cam;
    
    Cam_LoadState( cam, iChannel1, ivec2(0,0) );
    
    vec2 vFontUV = vUV * 32.0 * vec2(2.0, 1.0);
    vFontUV -= vec2( 0.0, 1.5 * 3.0 );
    if ( PrintValue( vFontUV, cam.vPos.x, 4.0, 4.0 ) > 0.0 )fragColor = vec4(1);vFontUV += vec2(0.0, 1.5);
    if ( PrintValue( vFontUV, cam.vPos.y, 4.0, 4.0 ) > 0.0 )fragColor = vec4(1);vFontUV += vec2(0.0, 1.5);
    if ( PrintValue( vFontUV, cam.vPos.z, 4.0, 4.0 ) > 0.0 )fragColor = vec4(1);vFontUV += vec2(0.0, 1.5);
#endif     
    
}
