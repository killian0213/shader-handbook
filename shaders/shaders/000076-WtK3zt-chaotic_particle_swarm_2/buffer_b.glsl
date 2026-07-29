// Buffer B (buffer) — chaotic particle swarm 2 by FabriceNeyret2
// https://www.shadertoy.com/view/WtK3zt

void mainImage(out vec4 col, in vec2 _pos) 
{
    // col = content closest to pos within neighborhood (2-length cross around pos)
    swapN(_pos,col);

    // move fluid
    fluidStep(col.xy);
   
    // create particle from time to time when too far to pos (i.e. region empty of partic)
    if ( fract(hash3i1f(uvec3(pos,iFrame))) < npartchance
         && mindist < length(col.xy - _pos - 1.) 
       ) 
       col = vec4(_pos, hash3i1f(uvec3(pos,iFrame+1000)), 0);
    
    
}
