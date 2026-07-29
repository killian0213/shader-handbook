// Image (image) — Mobius Maze [331 chars] by Xor
// https://www.shadertoy.com/view/7dVyDh

/*
    "Mobius Maze [331 chars]" by @XorDev

    Tweet: twitter.com/XorDev/status/1534951614271868929
    Twigl: https://t.co/YYUPG2wlLv
    
    Fabrice's Mobius Arrows were helpful here:
    shadertoy.com/view/NltXRl

    -2 Thanks to iapafoto
    -6 Thanks to FabriceNeyret2
    
    <512 Chars playlist: shadertoy.com/playlist/N3SyzR
*/

void mainImage(out vec4 O, vec2 I)
{
    //Clear fragcolor
    O -= O;
    //Loop through layers and initialize vecs
    for(vec2 r = iResolution.xy, z, p=r-r, i=p;
        //Loop 100 times
        i.y++<1e2;
        //Sink holes
        i.y < 1e2 - length(dFdy(p))*r.y*.2 
        //Maze walls
        && abs( fract( p.x+p.y*sign(texture(iChannel0,ceil(p)/2e1 ).r - .5) )
                 -.5 )  >.3
        //Color from layer height
        ? O = i.y*i.yyyy/1e4 : O   
    )
        //Get centered coordinates (scaled for perspective)
        z = p = ( I+I-i - r ) / r.y / vec2(2,1),
        //Offset holes
        z.x++, p.x-=.5,
        //Mobius transform from FabriceNeyret2
        p =   log(length(p = p*mat2(z,-z.y,z)/dot(p,p) +.5 )) *vec2(5,-5)
            + atan(p.y,p.x) / .314  +  iTime;
}


///Original in 337 chars
/*
void mainImage(out vec4 O, vec2 I)
{
    //Clear fragcolor
    O -= O;
    //Loop through layers and initialize
    for(vec2 r=iResolution.xy,p,z,i=r-r;
    //Loop 100 times
    i.y++<1e2;
    //Add procedural maze layer
    O += vec4(abs(fract(texture(iChannel0,ceil(p)/2e1).r>.5?p+p.y:p-p.y).x-.5)>.3
    //Compute sinkholes with derivatives
    && 1e2-i.y>length(dFdy(p))*r.y*.2)
    //Factor brightness from layer height
    * (i.y*i.y/1e4-O))
    
        //Set starting point
        z=p=(I+I-i-r)/r.y/vec2(2,1),
        //Hole offsets
        z.x++, p.x-=.5,
        //Mobius transform from FabriceNeyret2
        p *= mat2(z,-z.y,z)/dot(p,p),
        //Mobius spiral + 10x scaling and scrolling
        p = log(length(p+=.5))*vec2(5,-5)+atan(p.y,p.x)/.314+iTime;
}
*/