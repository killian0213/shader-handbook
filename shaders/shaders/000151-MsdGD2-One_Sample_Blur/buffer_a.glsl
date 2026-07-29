// Buffer A (buffer) — One Sample Blur by iq
// https://www.shadertoy.com/view/MsdGD2

// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Trick: take one single texture sample at the corner of a given texel, right where it 
// meets three of its neighbors, so that the bilinear filtering hardware averages those
// four texels for you. This basically lets you downsample or box-blur the texture
// without fetching and averaging the four texels by hand.
//
// This shader shows the technique by blurring an image repeatedly with only ONE texture
// sample.
//
// A more advanced use of this for gaussian blurs here: https://www.shadertoy.com/view/Xd33Rf



vec4 createTexture( in vec2 p );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // blur    
    vec2 s = vec2(float(iFrame&1))-0.5;             // generate -0.5 or +0.5 alternativelly
  //vec2 s = vec2(iFrame&1,(iFrame>>1)&1)-0.5;      // touch four corners alternativelly
    fragColor = textureLod( iChannel0, (fragCoord+s) / iResolution.xy, 0.0 );

    // initial image
    if( iFrame==0 ) fragColor = createTexture(fragCoord/iChannelResolution[0].xy);
}



// ---------------------------------------------------------------------------------------------

vec4 createTexture( in vec2 p )
{
    vec2 cc = vec2( -0.1, 0.68 );

	vec4 dmin = vec4(1000.0);
    float w = 0.0;
    vec2 z = 1.1*(-1.0 + 2.0*p)*vec2(iChannelResolution[0].x/iChannelResolution[0].y,1.0);
    for( int i=0; i<80; i++ )
    {
        z = cc + vec2( z.x*z.x - z.y*z.y, 2.0*z.x*z.y );

		dmin=min(dmin, vec4(length( z-0.5), 
							abs(-0.5+z.x + 0.2*sin(5.0*z.y)), 
							dot(z,z),
						    length( fract(z/8.0)-0.5) ) );
        if( dot(z,z)>4.0 ) w=1.0;
    }
   
    vec3 col = vec3(0.6,0.6,0.6);
    col * 0.4+0.6*w;
    col *= mix( vec3(1.0,0.45,0.1), vec3(1.0), w );
    col *= 0.65 + dmin.w;
    col = mix( col, 1.5*vec3(0.7,0.7,0.7),1.0-clamp(dmin.y*15.0,0.0,1.0) );
    col = mix( col, vec3(1.1,1.1,1.0),1.0-clamp(dmin.x*2.0,0.0,1.0) );
	col *= 0.5 + 0.5*clamp(dmin.z*50.0,0.0,1.0);


    return vec4( col, 1.0 );
}
