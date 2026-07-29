// Image (image) — Photoreal Clouds by TekF
// https://www.shadertoy.com/view/tlcSzs

// Tone Mapping by Hazel Quantock
// This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License. https://creativecommons.org/licenses/by-sa/4.0/

const float exposure = .75;

// Exposure curve parameters
//#define SHOW_CURVE 1
const vec3 gradient = vec3(1.4,1.5,1.6);
const vec3 whiteSoftness = vec3(.5);
const vec3 blackClip = vec3(.0,.1,.2);
const vec3 blackSoftness = vec3(.65,.5,.35);

vec3 LinearToSRGB ( vec3 col )
{
    return mix( col*12.92, 1.055*pow(col,vec3(1./2.4))-.055, step(.0031308,col) );
}

vec3 SRGBToLinear ( vec3 col )
{
    return mix( col/12.92, pow((col+.055)/1.055,vec3(2.4)), step(.04045,col) );
}

vec3 HDRtoLDR( vec3 col )
{
    col *= exposure;

#if (1)
#if (1)
    // soft cut off near black to enhance contrast
   	// this is good for correcting for atmospheric fog
	col = max(col-blackClip,0.); 
    col = sqrt(col*col+blackSoftness*blackSoftness)-blackSoftness;

    col *= gradient;
    
    // soft clamp to white (oh this is so good)
    vec3 w2 = whiteSoftness*whiteSoftness;
    col += w2;
    col = (1.-col)*.5;
    col = 1. - (sqrt(col*col+w2) + col);
#else
    // skip tone mapping
	col*=.4;
#endif
    
	return LinearToSRGB(col);

#else

    // much simpler and more natural look - reinhard
    col /= (1.+dot(col,vec3(0.2126,0.7152,0.0722))); // preserve saturation
    col *= 1.35; // let the clouds blow out the whites
    return col;

#endif
}

void mainImage( out vec4 fragColour, in vec2 fragCoord )
{
#if defined(RESOLUTION_REDUCTION) && RESOLUTION_REDUCTION > 1
    fragCoord /= vec2(RESOLUTION_REDUCTION);
    // smooth out the transition between pixels
//    fragCoord -= 1.*sin(fragCoord*6.283185)/6.283185;
    fragColour = SampleTextureCatmullRom4Samples(iChannel0,fragCoord/iResolution.xy,iResolution.xy);
#else    
    ivec2 ifragCoord = ivec2(fragCoord);
    fragColour = texelFetch(iChannel0,ifragCoord,0);

#ifdef MOSAIC_PREVIEW
    const float targetCount = 256.;
    if ( fragColour.a < targetCount*.2 )
    {
        // blend a square big enough to hit targetCount
        int kernelSize = int(ceil(sqrt(targetCount/fragColour.a)));
        const int maxKernel = 16;
        kernelSize = min(kernelSize,maxKernel);
        ivec2 blockuv = (ifragCoord/kernelSize)*kernelSize;
        for ( int i=0; i < maxKernel; i++ )
        {
            if ( i > kernelSize ) break;
            for ( int j=0; j < maxKernel; j++ )
            {
                if ( j > kernelSize ) break;
                fragColour += texelFetch(iChannel0,blockuv+ivec2(i,j),0);
            }
        }
    }
#endif
#endif
    fragColour /= fragColour.a;
 
    fragColour.rgb = HDRtoLDR( fragColour.rgb );
    
#ifdef SHOW_CURVE
    vec2 uv = fragCoord.xy/iResolution.xy;
    vec3 f = HDRtoLDR(vec3( uv.x*3. ));
    f = SRGBToLinear(f); // show curve without gamma correction (comment this out to see actual HDR->colour value mapping)
    f -= (uv.y*1.04-.02);
    fragColour.rgb = SRGBToLinear(fragColour.rgb);
    fragColour.rgb = mix( vec3(1), fragColour.rgb, smoothstep( 0., 1.4, abs(f)/max(dFdx(f),vec3(1)/iResolution.y) ) );
    fragColour.rgb = LinearToSRGB(fragColour.rgb);
#endif
}
