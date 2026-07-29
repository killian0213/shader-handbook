// Sound (sound) — Music - Harry Potter by iq
// https://www.shadertoy.com/view/lssXWS

// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 mainSound( in int samp, float time )
{
  time = mod( time, 40.0 );

  // do 3 echo/reverb bounces
  vec2 tot = vec2(0.0);
  float hh = 1.0;
  for( int i=0; i<6; i++ )
  {
    float h = float(i)/(6.0-1.0);

    // compute note	
    float t = (time - 0.7*h)/0.18;
    float n = 0.0, b = 0.0, x = 0.0;
    #define D(u,v)   b+=float(u);if(t>b){x=b;n=float(v);}
    D(10,71)D(2,76)D(3,79)D(1,78)D( 2,76)D( 4,83)D(2,81)D(6,78)D(6,76)D(3,79)
    D( 1,78)D(2,74)D(4,77)D(2,71)D(10,71)D( 2,76)D(3,79)D(1,78)D(2,76)D(4,83)
    D( 2,86)D(4,85)D(2,84)D(4,80)D( 2,84)D( 3,83)D(1,82)D(2,71)D(4,79)D(2,76)
    D(10,79)D(2,83)D(4,79)D(2,83)D( 4,79)D( 2,84)D(4,83)D(2,82)D(4,78)D(2,79)
    D( 3,83)D(1,82)D(2,70)D(4,71)D( 2,83)D(10,79)D(2,83)D(4,79)D(2,83)D(4,79)
    D( 2,86)D(4,85)D(2,84)D(4,80)D( 2,84)D( 3,83)D(1,82)D(2,71)D(4,79)D(2,76) 
        
    // calc frequency and time for note	  
    float noteFreq = 440.0*pow( 2.0, (n-69.0)/12.0 );
    float noteTime = 0.18*(t-x);
	
    // compute instrument	
    float y  = 0.5*sin(6.2831*1.00*noteFreq*noteTime)*exp(-0.0015*1.0*noteFreq*noteTime);
	      y += 0.3*sin(6.2831*2.01*noteFreq*noteTime)*exp(-0.0015*2.0*noteFreq*noteTime);
	      y += 0.2*sin(6.2831*4.01*noteFreq*noteTime)*exp(-0.0015*4.0*noteFreq*noteTime);
          y += 0.1*y*y*y;	  
          y *= 0.9 + 0.1*cos(40.0*noteTime);
	      y *= smoothstep(0.0,0.01,noteTime);
          
    // accumulate echo	  
    tot += y * vec2(0.5+0.1*h,0.5-0.1*h)*hh;
    hh *= 0.5;
  }
  
  // master volume
  tot *= 0.35*smoothstep( 0.0, 8.0, time );
	
  return tot;
}
