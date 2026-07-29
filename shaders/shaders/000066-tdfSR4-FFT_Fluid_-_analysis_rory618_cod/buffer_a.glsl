// Buffer A (buffer) — FFT Fluid - analysis rory618 cod by FabriceNeyret2
// https://www.shadertoy.com/view/tdfSR4

// apply advection and proceed 1st step of block-FFTx

vec4 inp(int x, int y);
void mainImage( out vec4 O, vec2 I ) // --- block-FFTx
{
    SUM( x, x_N1, x_N0, inp( x+i*x_N1, y ) );
    
    O.xy = (cprod(O.xy, W(x*n,iR.x)));
    O.zw = (cprod(O.zw, W(x*n,iR.x)));
}


vec4 inp(int x, int y){
    if(FFT_DIR==FORWARD){ // space domain: --- apply advection 
        vec2 v = T(x, y).xz;                  // rand: stochastic interpolation better for low velocity
        return texture(iChannel0,( vec2(x, y) -v + rand2(Ihash3(x,y,iFrame)) ) / R.xy );
    } else
        return T(x, y);
}