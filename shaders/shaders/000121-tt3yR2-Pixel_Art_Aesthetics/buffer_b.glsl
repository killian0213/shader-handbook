// Buffer B (buffer) — Pixel Art Aesthetics by ChrisK
// https://www.shadertoy.com/view/tt3yR2

// CONVERTING 3D DATA TO 'PIXEL ART' HAPPENS HERE

// Just dropping the resolution and crushing the colour data would be simple, but making it
// appear 'hand-made' presents a few challenges. I'm attempting to roughly translate my
// thought process when drawing pixel art into code here, so I targeted the following goals:

// 1) NICE, HAND-PICKED COLOURS
// I think a lot of the aesthetic appeal in pixel art (and the fun in making it) comes from
// getting a lot out of very little, so the smaller the palette is, the better. I'm using a
// hand-picked palette of 9 colours here. These colours mostly make up two gradients, which
// correspond to the orange and blue materials at different levels of brightness. Both
// gradients use the same dark outline and specular highlight colours, for simplicity.

// 2) AESTHETICALLY APPEALING BALANCE OF FLATNESS AND DETAIL
// Lighting gradients across flat surfaces are rare in pixel art, even when they are physically
// accurate. For this reason, I differentiate between flat and curved surfaces. The diffuse
// lighting on curved surfaces is dithered with a bayer matrix, but flat surfaces are left
// perfectly flat, with no lighting variation from one side to another. On objects with more
// texture it would be better to replace the bayer matrix with a pattern that better described
// the surface, or maybe a normal map (so that the surface details rotate with the geometry).

// 3) USING DARK OUTLINES TO CLEARLY SEPERATE 'SPRITES' FROM 'BACKGROUND'
// Self-explanatory. On the highlighted sides of the objects, these outlines are coloured to
// match the object material, for a bit of extra visual interest. They are also anti-aliased,
// but very approximately, based off of a set of intuitive rules rather than anything with
// any physical accuracy. For more complicated 'sprites' with overlapping geometry, it would
// also be desirable to have some internal outlines seperating ovelapping elements.

// I think these three things go a long way toward achieving the pixel art look, at least in
// this very simple case.


#define SPEC_DITHER   0.01

#define BG_COL        vec3( 0.6, 0.8, 0.8 )
#define OUTLINE       vec3( 0.2, 0.0, 0.1 )
#define HIGHLIGHT     vec3( 1.0, 1.0, 0.8 )


const vec3 palette_a[5] = vec3[5](OUTLINE,
                                  vec3( 0.6, 0.0, 0.3 ),
                                  vec3( 1.0, 0.2, 0.1 ),
                                  vec3( 1.0, 0.7, 0.2 ),
                                  HIGHLIGHT );
                            
const vec3 palette_b[5] = vec3[5](OUTLINE,
                                  vec3( 0.0, 0.2, 0.5 ),
                                  vec3( 0.1, 0.5, 0.7 ),
                                  vec3( 0.2, 0.7, 1.0 ),
                                  HIGHLIGHT );

const mat4 bayer = mat4( 0,  8,  2, 10,
  						12,  4, 14,  6,
   						 3, 11,  1,  9,
   						15,  7, 13,  5)/16.0;


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 fc = fragCoord.xy;

    vec4 shape = texelFetch(iChannel0,ivec2(fc),0);
    vec4 n = texelFetch(iChannel0,ivec2(fc)+ivec2(0,1),0);
    vec4 s = texelFetch(iChannel0,ivec2(fc)-ivec2(0,1),0);
    vec4 e = texelFetch(iChannel0,ivec2(fc)+ivec2(1,0),0);
    vec4 w = texelFetch(iChannel0,ivec2(fc)-ivec2(1,0),0);
    
    int neighbours      = int(n.x>0.0) + int(s.x>0.0) + int(e.x>0.0) + int(w.x>0.0);
    int lightneighbours = int(n.y>0.0) + int(s.y>0.0) + int(e.y>0.0) + int(w.y>0.0);
    
    vec3 col = BG_COL;
    int br = -1;
    
    if( shape.x <= 0.0 ) {
        // background stripes
        if( sin((fc.x+fc.y)/5.0+iTime*5.0)>0.0 ) col = HIGHLIGHT;
    
        // outlines
        if (neighbours > 0) {
            shape.x = max( max(n.x,s.x), max(e.x,w.x) );
            br = ( lightneighbours == neighbours ) ? 1 : 0;
            
            //when bordering brightest areas:
            if ( max(max(n.y,s.y),max(e.y,w.y)) > 0.5 ) {
                // search diagonals -- if 2/8 or fewer neighbours are occupied, then lighten 1 step more
                // together with a darkened pixel inside the shape, this will improve the AA on the line
                vec4 ne = texelFetch(iChannel0,ivec2(fc)+ivec2( 1, 1),0);
                vec4 nw = texelFetch(iChannel0,ivec2(fc)+ivec2( 1,-1),0);
                vec4 se = texelFetch(iChannel0,ivec2(fc)+ivec2(-1, 1),0);
                vec4 sw = texelFetch(iChannel0,ivec2(fc)+ivec2(-1,-1),0);
                neighbours += int(ne.x>0.0) + int(nw.x>0.0) + int(se.x>0.0) + int(sw.x>0.0);
                if (neighbours<=2) br++;
            }
        }
    } else {
        ivec2 buv = ivec2( mod( fc, 4.0 ) );
        float ba = bayer[buv.x][buv.y];
    
        // face shading
        shape.y -= ba*shape.z;
        //br = int(shape.y) + 1;
        
        br = int( ceil( shape.y*2.0 ) ) + 1;
        
        // specular highlight
        if (shape.w-ba*SPEC_DITHER > 0.001 ) br++;
        if (shape.w-ba*SPEC_DITHER*2.0 > 0.001 ) br++;
        br = min(br,4);
        
        // darken to approximate anti-aliasing on edges of bright area
        if ( br>=3 && lightneighbours<=2 ) br--;
    }
    
    if ( br >= 0 ) {
        col = (shape.x>1.5) ? palette_b[br] : palette_a[br];
    }
    
    fragColor = vec4(col, 1.0);
}