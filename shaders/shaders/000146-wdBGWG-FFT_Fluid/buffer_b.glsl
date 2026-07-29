// Buffer B (buffer) — FFT Fluid by rory618
// https://www.shadertoy.com/view/wdBGWG


void mainImage( out vec4 O, in vec2 I )
{
    setRadix(R);
    O = vec4(0);
    int x = int(I.x);
    int y = int(I.y);
    
    int n = (x/x_N0);
    SUM( cprod((T(iChannel0, (x%x_N0)*x_N1+i, y).xy),W(i*n,x_N1)),i,x_N1 );
    O.xy = (sum);
    
    SUM( cprod((T(iChannel0, (x%x_N0)*x_N1+i, y).zw),W(i*n,x_N1)),i,x_N1 );
    O.zw = (sum);
}