// Buffer D (buffer) — FFT Fluid by rory618
// https://www.shadertoy.com/view/wdBGWG

void mainImage( out vec4 O, in vec2 I )
{
    setRadix(R);
    O = vec4(0);
    int x = int(I.x);
    int y = int(I.y);
    
    int n = (y/y_N0);
    SUM( cprod((T(iChannel0, x, (y%y_N0)*y_N1+i).xy),W(i*n,y_N1)),i,y_N1 );
    O.xy = (sum/sqrt(R.x*R.y));
    
    SUM( cprod((T(iChannel0, x, (y%y_N0)*y_N1+i).zw),W(i*n,y_N1)),i,y_N1 );
    O.zw = (sum/sqrt(R.x*R.y));
    
    vec2 C = mod(I.xy+R.xy/2.,R.xy)-R.xy/2.;
    if(FFT_DIR==FORWARD){
        if(texelFetch(iChannel2,ivec2(88,2),0).x<.5)
        	O*=exp(-dot2( C )*2e-7);
        if(length(C)>0. && texelFetch(iChannel2,ivec2(90,2),0).x<.5){
            float l = length(O.xz);
        	O.xz-=dot(normalize(C),O.xz)*normalize(C);
            if(texelFetch(iChannel2,ivec2(67,2),0).x<.5)
            	O.xz *= (l/(1e-3+length(O.xz)));
        }
        if(length(C)<1.) O*=0.;
        if(length(C)>0. && texelFetch(iChannel2,ivec2(90,2),0).x<.5){
            float l = length(O.yw);
        	O.yw-=dot(normalize(C),O.yw)*normalize(C);
            if(texelFetch(iChannel2,ivec2(67,2),0).x<.5)
            	O.yw *= (l/(1e-3+length(O.yw)));
        }
        
    } else {
        O.xz += .01*vec2(iMouse.xy-R.xy*.5)*exp(-.1/(1.+length(I-R.xy*.5))*dot2(I-R.xy*.5));
    }
    
    if(iFrame<6 && FFT_DIR==BACKWARD){
        O=vec4(0);
    }
}