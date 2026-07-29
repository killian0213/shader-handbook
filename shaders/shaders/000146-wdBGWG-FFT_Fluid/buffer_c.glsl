// Buffer C (buffer) — FFT Fluid by rory618
// https://www.shadertoy.com/view/wdBGWG

void mainImage( out vec4 O, in vec2 I )
{
    setRadix(R);
    O = vec4(0);
    int x = int(I.x);
    int y = int(I.y);
    
    int n = (y/y_N1);
    SUM( cprod((T(iChannel0, x, (y%y_N1)+i*y_N1).xy),W(i*n,y_N0)),i,y_N0 );
    O.xy = (cprod(sum, W((y%y_N1)*n,int(R.y))));
    
    SUM( cprod((T(iChannel0, x, (y%y_N1)+i*y_N1).zw),W(i*n,y_N0)),i,y_N0 );
    O.zw = (cprod(sum, W((y%y_N1)*n,int(R.y))));
}