// Buffer A (buffer) — FFT Fluid by rory618
// https://www.shadertoy.com/view/wdBGWG

vec4 inp(sampler2D ch,int x, int y);
void mainImage( out vec4 O, in vec2 I )
{
    setRadix(R);
    O = vec4(0);
    int x = int(I.x);
    int y = int(I.y);  
    
    int n = (x/x_N1);
    SUM( cprod((inp(iChannel0, (x%x_N1)+i*x_N1, y).xy),W(i*n,x_N0)),i,x_N0 );
    O.xy = (cprod(sum, W((x%x_N1)*n,int(R.x))));

    SUM( cprod((inp(iChannel0, (x%x_N1)+i*x_N1, y).zw),W(i*n,x_N0)),i,x_N0 );
    O.zw = (cprod(sum, W((x%x_N1)*n,int(R.x))));
}


vec4 inp(sampler2D ch,int x, int y){
    if(FFT_DIR==FORWARD){
        vec2 v = T(ch, x, y).xz;
        return texture(ch, fract((-v + vec2(x, y) + rand2(IHash(x^IHash(y^IHash(iFrame)))))/R.xy));
    } else {
        return T(ch, x, y);
    }
}