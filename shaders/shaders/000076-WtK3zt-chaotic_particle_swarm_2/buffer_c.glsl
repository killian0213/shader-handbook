// Buffer C (buffer) — chaotic particle swarm 2 by FabriceNeyret2
// https://www.shadertoy.com/view/WtK3zt

void mainImage(out vec4 col, in vec2 _pos) 
{
    // col = content closest to pos within neighborhood (2-length cross around pos)
    swapN(_pos,col);
}
