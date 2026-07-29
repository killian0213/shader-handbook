// Image (image) — Super SPH  by michael0884
// https://www.shadertoy.com/view/tdXBRf

void mainImage( out vec4 fragColor, in vec2 pos )
{
    sN = SN; 
    N = ivec2(R*P/vec2(sN));
    TN = N.x*N.y;
    ivec2 pi = ivec2(floor(pos));
    
    fragColor = texel(ch2, pi);
}