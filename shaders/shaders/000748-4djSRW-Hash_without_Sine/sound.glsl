// Sound (sound) — Hash without Sine by Dave_Hoskins
// https://www.shadertoy.com/view/4djSRW

// Hash without Sine
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Created by David Hoskins.

// https://www.shadertoy.com/view/4djSRW
// Trying to find a Hash function that is the same on all systems
// and doesn't rely on trigonometry functions that lose accuracy with high values. 
// New one on the left, sine function on the right.



#define ITERATIONS 8.0


// * NB: As you can see the hash is multplied by the sample rate to bring it into the
//    	 integer stepped range.


//----------------------------------------------------------------------------------------
vec2 mainSound( in int samp,float time)
{
    vec2 audio = vec2(0.0);
    for (float v = 0.0; v < ITERATIONS; v++)
    {
		audio += hash22(iSampleRate * vec2(time + v, time*1.423 + v)) * 2.0 - 1.0;
    }
    audio /= float(ITERATIONS);

    return audio*.2 * smoothstep(0.0, 2.0, time) * smoothstep(60.0, 50.0, time);
}