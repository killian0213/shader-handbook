// Buffer C (buffer) — FFT Fluid - analysis rory618 cod by FabriceNeyret2
// https://www.shadertoy.com/view/tdfSR4

// proceed 1st step of block-FFTy

void mainImage( out vec4 O, vec2 I )
{
    SUM( y, y_N1, y_N0, T( x, y+i*y_N1 ) );
    
    O.xy = (cprod(O.xy, W(y*n,iR.y)));
    O.zw = (cprod(O.zw, W(y*n,iR.y)));
}