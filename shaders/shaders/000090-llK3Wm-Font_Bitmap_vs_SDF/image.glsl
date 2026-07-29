// Image (image) — Font: Bitmap vs SDF by MichaelPohoreski
// https://www.shadertoy.com/view/llK3Wm

/*
   Signed Distance Field (SDF) Font Rendering Comparison
   By: Michaelangel007
   Created: Sept. 28, 2016
   Last updated: Sept. 22, 2024, v2.6
   (2.6 Added new link for Viktor Chlumsky's Thesis)

References:

Whitepapers
* https://github.com/Michaelangel007/game_dev_pdfs/blob/master/graphics/signed_distance_field/SIGGRAPH2007_AlphaTestedMagnification.pdf
* New Thesis:
  * https://github.com/Chlumsky/msdfgen/files/3050967/thesis.pdf
* Old Thesis:
  * https://dspace.cvut.cz/bitstream/handle/10467/62770/F8-DP-2015-Chlumsky-Viktor-thesis.pdf

Introduction
* https://forum.libcinder.org/topic/signed-distance-field-font-rendering

Advanced (Sharp Corners)
* http://computergraphics.stackexchange.com/questions/306/sharp-corners-with-signed-distance-fields-fonts
* https://github.com/Chlumsky/msdfgen

Libs
* https://github.com/libgdx/libgdx/wiki/Distance-field-fonts
* https://github.com/behdad/glyphy
* https://groups.google.com/forum/#!forum/glyphy

Alternative Rendering

* https://medium.com/@evanwallace/easy-scalable-text-rendering-on-the-gpu-c3f4d782c5ac#.z5mtsrx99
"Easy Scalable Text Rendering on the GPU"
Implementation: XOR Triangles -> "Invert" Stencil Buffer -> Additive Blending 1/255.

* http://jcgt.org/published/0002/01/04/paper.pdf
"Higher Quality 2D Text Rendering"
Implementation: Texture Atlas

Contour Textures (Stefan Gustavson)
* http://contourtextures.wikidot.com/

fwidth()
* https://developer.mozilla.org/en-US/docs/Web/API/OES_standard_derivatives
* https://github.com/KhronosGroup/WebGL/blob/master/sdk/tests/conformance/ogles/GL2ExtensionTests/fwidth/fwidth_frag.frag
* http://computergraphics.stackexchange.com/questions/61/what-is-fwidth-and-how-does-it-work

Partial Derivaites
* http://www.essentialmath.com/blog/?p=151&cpage=1

SDF Textures

* Otavio Good 
  * https://www.shadertoy.com/media/a/08b42b43ae9d3c0605da11d0eac86618ea888e62cdd9518ee8b9097488b31560.png

* msdfgen
  32x32 SDF monochrome / achromatic
  * https://cloud.githubusercontent.com/assets/18639794/14770361/251a4406-0a70-11e6-95a7-e30e235ac729.png

  16x16 SDF monochrome
  * https://cloud.githubusercontent.com/assets/18639794/14770360/20c51156-0a70-11e6-8f03-ed7632d07997.png

  16x16 SDF polychrome / chromatic 
  * https://cloud.githubusercontent.com/assets/18639794/14770355/14cda9f8-0a70-11e6-8346-2bd14b5b832f.png


History:
   2.6 Added new link for Viktor Chlumsky's Thesis
   2.5 Updated implementation for Alternative Rendering
   2.4 Added SDF Texture Links
   2.3 Added Viktor Chlumsky's link "Shape Decomposition for Multi-channel Distance Fields"
   2.2 Added paulhoux's SDF func() as SMOOTH_2, changed optimized to SMOOTH_3
   2.1 Changed default smoothstep() from 1/3,2/3 to 1/2,1/2
   2.0 Added reference links
   1.9 Change default gamma to 1.0 for extra contrast.
   1.8 Center 1:1 images in their respective sides
   1.7 Darken SDF background
   1.6 Added note about smoothstep() sharp / blurry params
   1.5 Changed foreground color to be sky blue to emphasize correct blending. (Thanks FabriceNeyret2)
   1.4 Cleanup instructions and unused vars
   1.3 Change default gamma to 2.0
   1.2 Cleanup blending background / foreground
   1.1 Add hold mouse button and Y = gamma between 1.0 and 2.5
   1.0 Initial
*/

//#define SMOOTH_1 // version 1 of sharpening

// paulhoux's version: float w = fwidth( d ); a = smoothstep( 0.5 - w, 0.5 + w, d );
//#define SMOOTH_2 

// optimized (1) aa:   float v = s / fwidth( s ); a = clamp( v + 0.5, 0.0, 1.0 );
#define SMOOTH_3 

// Glyph Width
#define GLYPH_W 7.0
#define GLYPH_H GLYPH_W

vec4 glyph( vec2 p, int iChannel )
{
    vec4 back  = vec4( .1, .2, .5, 1.0 ); // Royal Blue background color

    float scale = (2.25 * 16.0) / iResolution.x;

    if (iChannel >= 2 )
    {
        scale *= 2.0; // 16x16 same area as 8x8
        back *= 0.5; // darken SDF background so it is more obvious
    }
    
    p *= scale;
    p /= iResolution.xy;
    
    float d;
    float a;
    
    if (iChannel == 0)
        a = texture( iChannel0, p ).a;
    if (iChannel == 1)
        a = texture( iChannel1, p ).a;
    if (iChannel == 2)
        a = texture( iChannel2, p ).a;
    if (iChannel == 3)
    {
        d = texture( iChannel2, p ).a;
        
        // w = 0.0 Sharp
        // w = 0.5 Blury
        //float w = 0.5 - 1.0/3.0; // 0.5 - (0.5-1/3) = 0.333, 0.5+(0.5-1/3) = 0.666
        float w = 0.0; // 0.5, 0.5
        if (iMouse.z > 0.0)
            w = (iMouse.x / iResolution.x)*0.5; // [0,1] -> [0.0,0.5]

        a = smoothstep( 0.5 - w, 0.5 + w, d ); // smoothstep() is slightly blurry
    }
    if (iChannel == 4) // sharper
    {
               d = texture( iChannel2, p ).a;
        float  s = d - 0.5;
        float _2 = 0.70710678118; // SQRT2_DIV_2

#ifdef SMOOTH_1
        float  dx = dFdx( s );
        float  dy = dFdy( s );
        float  g  = _2 * length( vec2( dx, dy ) );     
        a  = smoothstep( -g, g, s );
#endif
        
#ifdef SMOOTH_2
        // paulhoux's version: float w = fwidth( d ); a = smoothstep( 0.5 - w, 0.5 + w, d );
        float w = fwidth( d );
        a = smoothstep( 0.5 - w, 0.5 + w, d );
#endif
        
#ifdef SMOOTH_3
        // optimized (1) aa:   float v = s / fwidth( s ); a = clamp( v + 0.5, 0.0, 1.0 );
        // Does anyone know where this comes from?
        // Detheroc mentioned it in http://computergraphics.stackexchange.com/questions/306/sharp-corners-with-signed-distance-fields-fonts
        float v = s / fwidth( s );
        a = clamp( v + 0.5, 0.0, 1.0 );
#endif
    }
    
    vec4 fore  = vec4( 0., .5, 1., 1.0 ); // Sky Blue
    vec4 color = mix( back, fore, a );

    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord;
    p.y = iResolution.y - p.y; // Move texture origin from bottom left to top right
    vec2 uv    = p / iResolution.xy;

    float scale = iResolution.x / (2.25 * 16.0);
    float edge  = scale * GLYPH_W;
    float r1    = 1.0 * edge;
    float r2    = 2.0 * edge;
    float r3    = 3.0 * edge;
    float r4    = 4.0 * edge;
    float r5    = 5.0 * edge;
    
    float headerH = max( GLYPH_H, 16.0 ); // SDF is 16x16

    if (p.y <= headerH)
    {
        vec4 c;

        if (p.x > r2) // iResolution.x*0.5) // SDF "A" 1:1
        {
            // Center in right side
            p.x -= r2;
            p.x -= (r5 - r2)*0.5;
            p /= iResolution.xy;
            c = texture( iChannel2, p );
        }
        else
        if (p.x > 0.0) // Bitmap "A" 1:1
        {
            // Center in left side
            p.x -= (r2 * 0.5);
            p /= iResolution.xy;
            c = texture( iChannel0, p );
        }
        fragColor = c;  
    }
    else
    {
        p.y -= headerH; // top header row has 1:1 glyph

        if (p.x < r1)
        {
            fragColor = glyph( p, 0 ); // Nearest  
        }
        else
        if (p.x < r2)
        {
            p.x -= r1;
            fragColor = glyph( p, 1 ); // Bilinear
        }
        else
        if (p.x < r3)
        {
            p.x -= r2;
            fragColor = glyph( p, 2 ); // SDF Bilinear
        }
        else
        if (p.x < r4)
        {
            p.x -= r3;
            fragColor = glyph( p, 3 ); // SDF smoothstep
        }
        else
        if (p.x < r5)
        {
            p.x -= r4;
            fragColor = glyph( p, 4 );  // SDF partial derivative via fwidth()
        }
    }

    float gamma = 1.0;
    if (iMouse.z > 1.0 )
        gamma = 1.0 + 1.5*((iMouse.y / iResolution.y )); // [0,1] = [1.0,2.5]

    fragColor.rgb = pow( fragColor.rgb, vec3( 1.0/gamma ) );
}