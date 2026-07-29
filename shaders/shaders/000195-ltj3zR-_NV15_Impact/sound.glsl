//  (sound) — [NV15] Impact by cabbibo
// https://www.shadertoy.com/view/ltj3zR

// Trying to sync by using AND's code from
// https://www.shadertoy.com/view/4sSSWz
#define WARMUP_TIME     (2.0)

const float loopSpeed   = .1;
const float loopTime    = 5.;
const float impactTime  = 1.;
const float impactFade  = .3;
const float fadeOutTime = .1;
const float fadeInTime  = .1;
const float whiteTime   = .3; // fade to white
    

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}



/*
	
	From https://www.shadertoy.com/view/MdfXWX

*/

float n2f(float note)
{
   return 55.0*pow(2.0,(note-3.0)/12.); 
}

vec2 bass(float time, float tt, float note)
{
    if (tt<0.0)
      return vec2(0.0);

    float freqTime = 6.2831*time*n2f(note);
    
    return vec2(( sin(     freqTime
                      +sin(freqTime)*7.0*exp(-2.0*tt)
                     )+
                  sin(     freqTime*2.0
                      +cos(freqTime*2.0)*1.0*sin(time*3.14)
                      +sin(freqTime*8.0)*0.25*sin(1.0+time*3.14)
                    )*exp(-2.0*tt)+
                  cos(     freqTime*4.0
                      +cos(freqTime*2.0)*3.0*sin(time*3.14+0.3)
                    )*exp(-2.0*tt)
                )
                
                *exp(-1.0*tt) );
}


/*
	
	From https://www.shadertoy.com/view/4ts3z2

*/

//Audio by Dave_Hoskins

vec2 add = vec2(1.0, 0.0);
#define MOD2 vec2(.16632,.17369)
#define MOD3 vec3(.16532,.17369,.15787)

//----------------------------------------------------------------------------------------
//  1 out, 1 in ...
float hash11(float p)
{
	vec2 p2 = fract(vec2(p) * MOD2);
    p2 += dot(p2.yx, p2.xy+19.19);
	return fract(p2.x * p2.y);
}
//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p)
{
	//p  = fract(p * MOD3);
    vec3 p3 = fract(vec3(p) * MOD3);
    p3 += dot(p3.xyz, p3.yzx + 19.19);
   return fract(vec2(p3.x * p3.y, p3.z*p3.x))-.5;
}

//----------------------------------------------------------------------------------------
///  2 out, 2 in...
vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3.zxy, p3.yxz+19.19);
    return fract(vec2(p3.x * p3.y, p3.z*p3.x));
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 Noise21(float x)
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return  mix( hash21(p), hash21(p + 1.0), f)-.5;
    
}

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
float Noise11(float x)
{
    float p = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix( hash11(p), hash11(p + 1.0), f)-.5;

}

//----------------------------------------------------------------------------------------
//  2 out, 2 in...
vec2 Noise22(vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 res = mix(mix( hash22(p),          hash22(p + add.xy),f.x),
                    mix( hash22(p + add.yx), hash22(p + add.xx),f.x),f.y);
    return res-.5;
}

//----------------------------------------------------------------------------------------
// Fractal Brownian Motion...
vec2 FBM21(float v)
{
    vec2 r = vec2(0.0);
    vec2 x = vec2(v, v*1.3+23.333);
    float a = .6;
    
    for (int i = 0; i < 8; i++)
    {
        r += Noise22(x * a) / a;
        a += a;
    }
     
    return r;
}

//----------------------------------------------------------------------------------------
// Fractal Brownian Motion...
vec2 FBM22(vec2 x)
{
    vec2 r = vec2(0.0);
    
    float a = .6;
    
    for (int i = 0; i < 8; i++)
    {
        r += Noise22(x * a) / a;
        a += a;
    }
     
    return r;
}


/*

	FROM @LukeXI

*/

#define PI              (3.1415)
#define TWOPI           (6.2832)


float square(float time, float freq) {
    
    return sin(time * TWOPI * freq) > 0.0 ? 1.0 : -1.0;
}

float sine(float time, float freq) {
    
    return sin(time * TWOPI * freq);
}

vec2 sineLoop(float time, float freq, float rhythm) {
    vec2 sig =vec2( 0.);
    float loop = fract(time * rhythm);
    
    float modFreq = freq + (sine(time, 7.0));
    
    sig += vec2( sine(time, freq) * exp(-3.0*loop) );
  //  sig += vec2( square(time, freq/2.0) * exp(-3.0*loop) ) *0.2;
    
    float panfreq = rhythm * 0.3;
    float panSin = sine(time, panfreq);
    float pan = (panSin + 1.0) / 2.0;
    sig.x *= pan;
    sig.y *= (1.0 - pan);
    
    return sig;
}

vec2 chimeTrack(float time) {
    vec2 sig = vec2( 0. );
    sig += sineLoop(time, 1730.0, 0.44) * 0.2;
    sig += sineLoop(time, 880.0, 1.0);
    sig += sineLoop(time, 990.0, 0.3) * 0.4;
    sig += sineLoop(time, 330.0, 0.4);
    sig += sineLoop(time, 110.0, 0.1);
    sig += sineLoop(time, 60.0, 0.05);
    
    sig /= 6.0;
    
    return sig;
}


// Choreography:

// total peace 
// When comet arrives, start ominous music
// ominous music builds
// when fade to white, ominouse


float tone( float freq , float time  ){
    
    return sin(6.2831* freq *time);
    
}

float chord( float base , float time ){
    

    float f = 0.;
    
    f += tone( base , time )           * (1. + .1 * sin( time * 5.2 )) ;
    f += tone( base , time * 1.26  ) * .6 * (1. + .3 * sin( time * 10.02)) ;
    f += tone( base , time * 1.498 ) * .4 * (1. + .3 * sin( time * 23.4)) ;
    f += tone( base , time * 2.* 1.498 ) * .2 * (1. + .3* sin( time * 43.4)) ;
    f += tone( base , time * 2.* 1.26 ) * .2 * (1. + .3* sin( time * 10.4)) ;
    //f += tone( base , time * 4. ) * .3 * (1. + .1 * sin( time * .1)) ;
    //f += tone( base , time * 5. ) * .2 * (1. + .1 * sin( time * .04)) ;
    //f += tone( base , time * 6. ) * .1 * (1. + .1 * sin( time * .08)) ;
    
    return f / 2.;
    
}

vec2 mainSound( in int samp,float time)
{
    
    
 	time = max(0.0, time - WARMUP_TIME);

    float tInput = time;
    float timeInLoop = loopTime - time * loopSpeed;
    

   	float per = ( (loopTime - timeInLoop) / loopTime ); 
    
     // Fading in / fading out
    float fadeIn = ((loopTime - clamp( timeInLoop , loopTime - fadeInTime , loopTime ))) / fadeInTime;
    
    float fadeOut = ((loopTime - clamp( (loopTime- timeInLoop) , loopTime - fadeOutTime , loopTime ))) / fadeOutTime;
    
    
    // Gives us a straight fade to white

    if( timeInLoop < impactTime + whiteTime ){
        
    
    }
    
    
     // TEXT
    if( timeInLoop < impactTime ){ 
        
        float textFade = pow( max( 0. , timeInLoop - (impactTime - impactFade) ) / impactFade , 2. );

    }
    
    
    float peaceTone = 0.;
    float cometTone = 0.;
    float textTone = 0.;
    float explosionTone = 0.;
    float finalTone = 0.;
      
    
    peaceTone = smoothstep( .0 , .1 , per );
    if( per > .6 ){
     peaceTone = smoothstep( .8 , .6 , per);
    }
    
  
    if( per > .41 ){
        cometTone = smoothstep( .41 , .49 , per ); 
        if( per > .49  && per < .75){
          cometTone = 1. +  pow( (per - .49) /  ( .75 - .49 ) , 3.);
        }
        if( per > .75 ){
          cometTone = smoothstep( .84 , .75  , per) * 2.;
        }
    }
    
    
    explosionTone = pow( cometTone , 5. );
    textTone = smoothstep( .76 , .9 , per );
    finalTone = pow( smoothstep( .93 , .96 , per ), 2.) / max( 1. , exp( (per - .96)* 80. ));

  
    
    vec2 noiseT = vec2( rand( vec2(time , 20.51) ) ,  rand( vec2(time*4. , 2.51) ));
    
    vec2 noiseFBM =  FBM22(time*(Noise21(time*.4)+900.0))*abs(Noise21(time*1.5));
    //261.63
    //329.63
    //392.00
    
    //float cornT = 0.;
    vec2 comet = vec2( chord( 55. , time))* cometTone;
    //vec2 comet = vec2( 0. );
    vec2 peace = chimeTrack(  time ) * peaceTone;
    vec2 text  = chimeTrack(time*20.0) * textTone;
   
    vec2 final  =  vec2( chord( 110. , time))* 3.  * finalTone;
      
    vec2 explosion = ( noiseT + noiseFBM * 5. ) * .03  * explosionTone;

    
    vec2 b =  bass( time , 1.7 , 15. );
    b += bass( time , 1.7 , 10.);
    b *= textTone * 3.;
    


    vec2  a = min( fadeOut , fadeIn ) * (b + (comet + peace + text + explosion + final)  * .4);
    //a2 =vec2( pow( a.x , 2. ),pow( a.y , 2. ));
    return clamp( a ,-.8 , .8 );
    
}