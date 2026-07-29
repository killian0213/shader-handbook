// Image (image) — The Infinite City III by fancyzero
// https://www.shadertoy.com/view/NddBDM

//post process

#define T texture(iChannel0, I

//debug
int D(vec2 p, float n) {
    int i=int(p.y), b=int(exp2(floor(30.-p.x-n*3.)));
    i = ( p.x<0.||p.x>3.? 0:
    i==5? 972980223: i==4? 690407533: i==3? 704642687: i==2? 696556137:i==1? 972881535: 0 )/b;
 	return i-i/2*2;
}


 vec4 DrawDigits(vec2 i, float x) 
 {
     vec4 o;
    for (float n=5.; n>=0.; n--) 
    { 
        if ((i.x)<3.) 
        { 
        o = vec4(D(i,floor(mod(x/pow(10.,n),10.)))); 
        break; 
        } 
        i.x -=4.;  
     
    }
    return o;
}
//end of debug

float NoiseSeed;

float randomFloat(){
  NoiseSeed = sin(NoiseSeed) * 84522.13219145687;
  return fract(NoiseSeed);
}

/*
    Fibonacci Bokeh Pass
    
    Based on: https://www.shadertoy.com/view/fljyWd
    -2 chars by FabriceNeyret2
*/
void mainImage(out vec4 O, vec2 I)
{
    //O = texture(iChannel2,I/iResolution.xy);
    //return;
    //Resolution for texel calculation
    vec2 r = iResolution.xy;
    //Sample point starting at vec2(scale, 0)
    
    float rad = abs(I.y/r.y-0.5);
    
    
    #if FREE_CAMERA_MOVE
    rad = rad*2.22;
    #else
    rad = mix(0., rad*1.11, smoothstep(0.6,0.,min(1.,iMouse.y/iResolution.y*2.)))*2.;
    #endif
    vec2 p = vec2(rad, O-=O);
    
    //"i" approximating the sqrt of the number of iterations.
    //So i < 16 means roughly 256 texture samples.
    for(float i=1.; i<8.; i+=1./i)
        //Rotate sample point by golden angle (for even spacing).
        p *= -mat2(.737, .676, -.676, .737),
        //Add samples exponentially (a bit like a "smooth maximum").
        O += exp(log(T/r+p*i/r))/.3);
    //Convert back to linear color (making brighter pixel stand out)
    O = pow(O,.3-O+O);
    //Average by total sample weight via alpha channel.
    O = sqrt(O/O.a);
   
    NoiseSeed = float(iFrame)* .003186154 + I.y * 17.2986546543 + I.x;
    float noise = .9 + randomFloat()*.15;       
    O.xyz*= noise*1.1;  
    
    
    //int width = int(iResolution.x);
    //vec4 randomData = texelFetch(iChannel2, ivec2(width-1,0),0);
    
    
   // O += DrawDigits( I/4., randomData.y);
}
