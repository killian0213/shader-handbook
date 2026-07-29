// Sound (sound) — After... by Dave_Hoskins
// https://www.shadertoy.com/view/3sBGRt

// After...
// by David Hoskins.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//----------------------------------------------------------------------------------------
vec2 bell(float time)
{
    
    float w = floor(time);
    
    float t = mod(time, 5.);
    float p = floor(time / 5.);
    float n = floor(hash11(p*151.0)*48.0)+69.0;
    
    // Random volume. Half the time there is no sound...
    float v = hash11(p*500.0);
   	v = max(v - .5, 0.0) * 2.0;
    
	float freq = pow (2.0, n / 12.0);
    float b = sin(6.2831*freq *t);
    // Pong volume....
    b*= smoothstep(120.,69.,n); // Higher pitch are quieter because "eh - too annoying!"
    b = b*exp(-.7*t)*v* smoothstep(0.0, .05, t);
    // Random stereo position....
    float st = hash11(p*13.0);
    return vec2(b*st, b*(1.0-st));
}

//----------------------------------------------------------------------------------------
vec2 mainSound( in int samp, float time )
{
    // The bells are at regular times and 6 can play at once...
 	vec2 b = bell(time)		+ bell(time+177.);
    b += bell(time+13.) 	+ bell(time+59.);
    b += bell(time+112.5) 	+ bell(time+153.);
    
	// Some pitched backgound noise.
    vec2 noi =  noise2D(vec2(time*110.0))*.4-.2;
    noi *= noise2D(vec2(time*.3));
    noi +=  noise2D(vec2(time*220.0))*.2-.1;
    noi *= noise2D(vec2(time*.3+20.0));
    noi +=  noise2D(vec2(time*440.0))*.1-.05;
    noi *= noise2D(vec2(time*.3+100.0));
    
    // MIDI C2 note hum....
    noi += (sin(6.2831 * 65.4 * time)+sin(6.2831 * 65.41 * time))*.3;
    
    b = b*.5 +noi;
    b *= smoothstep(0.0, 4.0,time) * smoothstep(180.0, 170.0,time);
    return b;
}