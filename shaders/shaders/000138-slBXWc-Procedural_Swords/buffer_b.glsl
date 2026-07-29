// Buffer B (buffer) — Procedural Swords by SnoopethDuckDuck
// https://www.shadertoy.com/view/slBXWc

float random ( vec2 st ) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float Cell( in vec2 p )
{
    if (p.x <= dimHandle.x && p.y <= dimHandle.y)
        return texelFetch(iChannel0, ivec2(p), 0 ).x;    
    return 0.;
}

float CA ( vec2 px, float e ) {
    float k = Cell(px+vec2(-1,-1)) + 1.5 * Cell(px+vec2(0,-1)) + Cell(px+vec2(1,-1))
      + 1.5 * Cell(px+vec2(-1, 0))                       + 1.5 * Cell(px+vec2(1, 0))
            + Cell(px+vec2(-1, 1)) + 1.5 * Cell(px+vec2(0, 1)) + Cell(px+vec2(1, 1));
    
    if ( e == 1. && k < 4.5 )
        e = 0.;
    else if ( e == 0. && k > 6. )
        e = 1.;      
        
    return e;
}

float sumNeighbours ( vec2 px ) {
    return Cell(px+vec2(0, -1)) + Cell(px+vec2(-1, 0)) +
           Cell(px+vec2(0, 1))  + Cell(px+vec2(1, 0));
}

float prodNeighbours ( vec2 px ) {
    return (Cell(px+vec2(0, -1)) + Cell(px+vec2(0, 1))) * 
           (Cell(px+vec2(-1, 0)) + Cell(px+vec2(1, 0)));
}

bool hasWhiteNeighbour ( vec2 px ) {   
    return sumNeighbours(px) > 0.;
}

bool isInteriorCorner ( vec2 px, float e ) {
    return e == 0.5 && prodNeighbours(px) >= 2.25;     
}

bool isExteriorCorner ( vec2 px, float e ) {
    return e == 0.5 && sumNeighbours(px) == 1.;
}

bool isBlackOutlined( vec2 px, float e ) {
    return e == 0. && sumNeighbours(px) == 2.;
}

bool wasInDiagCorner( vec2 px, float e ) {
    // this shouldn't work but somehow it does
    return e == 1. && prodNeighbours(px) < 2.; 
}

bool isIsolated ( vec2 px ) {
    return sumNeighbours(px) == 0.;
}


void mainImage( out vec4 fragColor, in vec2 coord )
{
    setDimHandle(iFrame);
    
    vec2 px = coord;    
    float e = Cell(px);
    
    // reset staff after a number of frames
    int frame = iFrame % reset;
      
    // initial state - generate noise
    if ( frame == 0 && coord.x <= dimHandle.x && coord.y <= dimHandle.y ) {
      
        // get symmetric rand value (random works best with low iTime values)
        float d = abs(0.5 * dimHandle.x - coord.x);    
        float rand = random(vec2(d , coord.y) + mod(iTime,201.315));
        
        // likely horizontal at top
        if ( coord.y > dimHandle.y - 4.)
            e = step(0.18, rand);
            
        // guarantee exposed "pole"
        else if ( coord.y > 6. && coord.y < 12.)
            e = 0.;
            
        // 50% rand noise in other regions   
        else
            e = step(0.5, rand);
                                
        // centre cells are 1. ( insert a "pole" ) 
        // ( maybe cut out the side values? )
        e = max(e, step(d, 1.));
        
        // cut off edges, so outline will work
        e *= step(coord.x, dimHandle.x - 2.) * step(2., coord.x) * 
             step(coord.y, dimHandle.y - 2.) * step(2., coord.y);          
    }
    
    // run cellular automata on noise
    else if ( frame < 5 ) {
        e = CA(px, e);                 
    }
    
    // reinsert noise at top, so horizontal bit is more likely
    else if ( frame < 6 && coord.y > dimHandle.y - 4. 
              && coord.x <= dimHandle.x && coord.y <= dimHandle.y) {
              
        float d = abs(0.5 * dimHandle.x - coord.x);    
        float rand = random(vec2(d , coord.y) + mod(iTime,201.315));
        
        e = step(0.18, rand);
        
        // cut off edges, so outline will work
        e *= step(coord.x, dimHandle.x - 2.) * step(2., coord.x) * 
             step(coord.y, dimHandle.y - 2.) * step(2., coord.y);    
    }
    
    // run cellular automata on noise again
    else if ( frame < 10 ) {
        e = CA(px, e);                 
    }
        
    // re-insert centre cells so a "pole" definitely exists
    else if ( frame < 11 ) {
        e = min(1., 
            e + step(coord.y, dimHandle.y) 
            * step(2., coord.y) 
            * max(e, step(abs(0.5 * dimHandle.x - coord.x), 1.)));
    } 
    
    // generate outline
    else if ( frame < 12 )
        e = (e == 0. && hasWhiteNeighbour(px)) ? .5 : e;
    
    // remove interior outlines + interior (axis-aligned) corners
    else if ( frame < 17 )
        e = (isInteriorCorner(px, e) || isBlackOutlined(px, e)) ? 1. : e;
    
    // remove exterior (diagonal) corner outlines
    else if ( frame < 18 )
        e = isExteriorCorner(px, e) ? 0. : e;
    
    // turn newly exposed bits into outlines
    else if ( frame < 19)
        e = wasInDiagCorner(px, e) ? 0.5 : e;
    
    // remove any corners formed from deleting diagonal corners
    else if ( frame < 20 ) 
        e = isExteriorCorner(px, e) ? 0. : e;
    
    // one more for good luck ( remove pixels without any neighbours )
    else if ( frame < 21 ) 
        e = isIsolated(px) ? 0. : e;
    
    // remove artifacts ( sloppy )
    else if ( frame == reset - 1 )
        e = 0.;
        
  fragColor = vec4(e);
}