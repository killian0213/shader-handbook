// Image (image) — FFT Fluid by rory618
// https://www.shadertoy.com/view/wdBGWG

//Four step seperated FFT, factored horizontally, vertically, and over major and minor axis for each of x and y
//Total worst case for 2048*2048 image is 2 (x and y) times 4 (factored into 4) 32pt dft's where each pixel/thread 
//must compute one bin of its corresponding dft. Pipelining through A-B-C-D means fft of the whoe screen only takes one frame.
//Both the x and y of the feild need to be fft'd so it takes up all 4 channels to do an fft, so every other frame
//the fft direction is swapped to compute the inverse, and overall the simulation runs at one step per two frames



void mainImage( out vec4 O, in vec2 I )
{
    O = vec4(0);
    if(FFT_DIR==BACKWARD){
        if(texelFetch(iChannel1,ivec2(32,2),0).x>.5) discard;
        vec4 t0 = texture(iChannel3, fract(I/R.xy));
        O = vec4(.5*log(.5*length(t0)));
    } else {
        if(texelFetch(iChannel1,ivec2(32,2),0).x<.5) discard;
    	O = texture(iChannel3, fract(.5+I/R.xy));
        float l0 = dot2(O.xy);
        O.xy = O.xy/l0*log(1.+l0);
        float l1 = dot2(O.zw);
        O.zw = O.zw/l1*log(1.+l1);
        O.xyz += vec3(1,1,0)*O.w;
        O=abs(O);
    }
}