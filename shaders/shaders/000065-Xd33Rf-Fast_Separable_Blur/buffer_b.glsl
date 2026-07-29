// Buffer B (buffer) — Fast Separable Blur by iq
// https://www.shadertoy.com/view/Xd33Rf

// Created by inigo quilez - iq/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

//
// Horizontal blur pass. 
//


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = (-iResolution.xy + 2.0*fragCoord.xy) / iResolution.y;

    // horizontal blur (since fragCoord samples at pixel centers it has a 0.5 added to it)
    // hence, i added an extra 0.5 to the texel coordinates to sample not at texel centers
    // but right between texels. the bilinear filtering hardware will average two texels
    // in each sample for me).
    vec3 blr = vec3(0.0);
    //blr += 0.013658*samplePremul( iChannel0, (fragCoord+vec2(-19.5,0.0))/iResolution.xy ).xyz;
    //blr += 0.019227*samplePremul( iChannel0, (fragCoord+vec2(-17.5,0.0))/iResolution.xy ).xyz;
    blr += 0.026109*texture( iChannel0, (fragCoord+vec2(-15.5,0.0))/iResolution.xy ).xyz;
    blr += 0.034202*texture( iChannel0, (fragCoord+vec2(-13.5,0.0))/iResolution.xy ).xyz;
    blr += 0.043219*texture( iChannel0, (fragCoord+vec2(-11.5,0.0))/iResolution.xy ).xyz;
    blr += 0.052683*texture( iChannel0, (fragCoord+vec2( -9.5,0.0))/iResolution.xy ).xyz;
    blr += 0.061948*texture( iChannel0, (fragCoord+vec2( -7.5,0.0))/iResolution.xy ).xyz;
    blr += 0.070266*texture( iChannel0, (fragCoord+vec2( -5.5,0.0))/iResolution.xy ).xyz;
    blr += 0.076883*texture( iChannel0, (fragCoord+vec2( -3.5,0.0))/iResolution.xy ).xyz;
    blr += 0.081149*texture( iChannel0, (fragCoord+vec2( -1.5,0.0))/iResolution.xy ).xyz;
    blr += 0.041312*texture( iChannel0, (fragCoord+vec2(  0.0,0.0))/iResolution.xy ).xyz;
    blr += 0.081149*texture( iChannel0, (fragCoord+vec2(  1.5,0.0))/iResolution.xy ).xyz;
    blr += 0.076883*texture( iChannel0, (fragCoord+vec2(  3.5,0.0))/iResolution.xy ).xyz;
    blr += 0.070266*texture( iChannel0, (fragCoord+vec2(  5.5,0.0))/iResolution.xy ).xyz;
    blr += 0.061948*texture( iChannel0, (fragCoord+vec2(  7.5,0.0))/iResolution.xy ).xyz;
    blr += 0.052683*texture( iChannel0, (fragCoord+vec2(  9.5,0.0))/iResolution.xy ).xyz;
    blr += 0.043219*texture( iChannel0, (fragCoord+vec2( 11.5,0.0))/iResolution.xy ).xyz;
    blr += 0.034202*texture( iChannel0, (fragCoord+vec2( 13.5,0.0))/iResolution.xy ).xyz;
    blr += 0.026109*texture( iChannel0, (fragCoord+vec2( 15.5,0.0))/iResolution.xy ).xyz;
    //blr += 0.019227*samplePremul( iChannel0, (fragCoord+vec2( 17.5,0.0))/iResolution.xy ).xyz;
    //blr += 0.013658*samplePremul( iChannel0, (fragCoord+vec2( 19.5,0.0))/iResolution.xy ).xyz;

    blr /= 0.93423; // renormalize to compensate for the 4 taps I skipped
    
    fragColor = vec4( blr, 1.0 );
}