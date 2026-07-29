// Sound (sound) — [SIG15] Midgar by davidbargo
// https://www.shadertoy.com/view/XllXWN

// Created by David Bargo - davidbargo/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

/*
	Song: Aerith's theme slightly modified to fit in the 60s limit
	I'm using the same kind of sequencer iq implemented in https://www.shadertoy.com/view/ldXXDj
*/

float instrument( float freq, float time )
{    
    float y = 0.70*sin(6.2831*freq*time)*exp(-0.0075*freq*time);
    y += 0.20*sin(2.01*6.2831*freq*time)*exp(-0.0055*freq*time);
    y *= clamp( time/0.004, 0.0, 1.0 );
	return y;	
}

float instrument2( float freq, float time )
{    
    float ph = sin(6.2831*freq*time);
    ph *= 0.2+0.8*max(0.0,6.0-0.01*freq);
    ph *= exp(-time*freq*0.2);
   
    float y = 0.70*sin(6.2831*freq*time+ph)*exp(-0.005*freq*time);
    y += 0.20*sin(2.01*6.2831*freq*time+ph)*exp(-0.0055*freq*time);
    y += 0.16*sin(4.01*6.2831*freq*time+ph)*exp(-0.009*freq*time);
    y *= clamp( time/0.004, 0.0, 1.0 );

	return y;	
}

#define D(a) b+=a;x+=step(b,t)*(b-x);

#define tint 0.00184

float doChannel1( float t )
{
    float x = t;
    float y = 0.0;
    float b = 0.0;
     
    D(1280.)D(1340.)D(3076.)D(1536.)D(1536.)D(4608.)D(1536.)
    y += instrument2(369.99, tint*(t-x) );

    x = t; b = 0.0;
    D(4160.)D(6144.)D(1536.)D(4608.)
    y += instrument2(392.0, tint*(t-x) );

    x = t; b = 0.0;
    D(2816.)D(3072.)D(1536.)D(1536.)D(4608.)D(1536.)
    y += instrument2(440.0, tint*(t-x) );

    x = t; b = 0.0;
    D(4352.)D(6144.)D(1536.)D(4608.)
    y += instrument2(493.88, tint*(t-x) );
    
    x = t; b = 0.0;
    D(3008.)D(4608.)D(1536.)D(4608.)D(1536.)
    y += instrument2(554.37, tint*(t-x) );

    x = t; b = 0.0;
    D(1472.)D(3072.)D(1536.)D(4608.)D(1536.)D(4608.)D(14400.)D(384.)
    y += instrument2(587.33, tint*(t-x) );

    x = t; b = 0.0;
    D(31424.)
    y += instrument2(659.26, tint*(t-x) );

    x = t; b = 0.0;
    D(19904.)D(192.)D(10944.)
    y += instrument2(739.99, tint*(t-x) );

    x = t; b = 0.0;
    D(28160.)D(768.)D(1920.)
    y += instrument2(783.99, tint*(t-x) );

    x = t; b = 0.0;
    D(19328.)D(6144.)D(2880.)D(384.)
    y += instrument2(880.0, tint*(t-x) );

    x = t; b = 0.0;
    D(18944.)D(3068.)D(3076.)D(3456.)
    y += instrument2(987.77, tint*(t-x) );

    x = t; b = 0.0;
    D(21632.)D(768.)D(2304.)
    y += instrument2(1108.73, tint*(t-x) );

    x = t; b = 0.0;
    D(18176.)D(384.)D(2688.)D(3072.)D(4800.)
    y += instrument2(1174.66, tint*(t-x) );

    x = t; b = 0.0;
    D(26216.)D(24.)
    y += instrument2(1318.51, tint*(t-x) );

    x = t; b = 0.0;
    D(22976.)D(192.)
    y += instrument2(1479.98, tint*(t-x) );

    x = t; b = 0.0;
    D(896.)
    y += instrument2(246.94, tint*(t-x) );

    x = t; b = 0.0;
    D(2432.)D(4608.)D(1536.)D(4608.)D(1536.)
    y += instrument2(277.18, tint*(t-x) );

    x = t; b = 0.0;
    D(1088.)D(2880.)D(1536.)D(4608.)D(1536.)D(4608.)
    y += instrument2(293.66, tint*(t-x) );

    return y;
}


float doChannel2( float t )
{
    float x = t;
    float y = 0.0;
    float b = 0.0;
    
    D(704.)
    y += instrument(329.63, tint*(t-x) );

    x = t; b = 0.0;
    D(896.)D(1152.)D(4800.)D(1728.)D(4416.)D(1728.)
    y += instrument(369.99, tint*(t-x) );

    x = t; b = 0.0;
    D(2240.)D(2880.)D(5760.)
    y += instrument(392.0, tint*(t-x) );

    x = t; b = 0.0;
    D(2432.)D(3072.)D(192.)D(960.)D(6144.)
    y += instrument(440.0, tint*(t-x) );

    x = t; b = 0.0;
    D(3584.)D(768.)D(1248.)
    y += instrument(493.88, tint*(t-x) );

    x = t; b = 0.0;
    D(3776.)D(30144.)
    y += instrument(554.37, tint*(t-x) );

    x = t; b = 0.0;
    D(3968.)D(15936.)D(192.)D(9024.)D(4416.)
    y += instrument(587.33, tint*(t-x) );

    x = t; b = 0.0;
    D(25472.)D(768.)D(1920.)D(768.)
    y += instrument(659.26, tint*(t-x) );

    x = t; b = 0.0;
    D(19328.)D(3648.)D(192.)D(5184.)D(384.)D(2496.)D(384.)
    y += instrument(739.99, tint*(t-x) );

    x = t; b = 0.0;
    D(18944.)D(3072.)D(3072.)D(3456.)D(2880.)
    y += instrument(783.99, tint*(t-x) );

    x = t; b = 0.0;
    D(18560.)D(3072.)D(768.)D(2304.)D(6336.)
    y += instrument(880.0, tint*(t-x) );

    x = t; b = 0.0;
    D(18176.)D(3072.)D(3072.)D(6528.)
    y += instrument(987.77, tint*(t-x) );
    
    x = t; b = 0.0;
    D(12416.)
    y += instrument(246.94, tint*(t-x) );
    
    x = t; b = 0.0;
    D(7040.)D(2304.)D(3840.)D(2304.)
    y += instrument(277.18, tint*(t-x) );

    x = t; b = 0.0;
    D(512.)D(9600.)D(1536.)D(4608.)
    y += instrument(293.66, tint*(t-x) );

    return y;
}


float doChannel3( float t )
{
    float x = t;
    float y = 0.0;
    float b = 0.0;
    
    D(2240.)
    y += instrument(329.63, tint*(t-x) );

    x = t; b = 0.0;
    D(936.)D(1112.)D(3456.)D(7680.)
    y += instrument(369.99, tint*(t-x) );

    x = t; b = 0.0;
    D(3968.)
    y += instrument(392.0, tint*(t-x) );

    x = t; b = 0.0;
    D(22400.)
    y += instrument(92.5, tint*(t-x) );

    x = t; b = 0.0;
    D(22016.)
    y += instrument(98.0, tint*(t-x) );

    x = t; b = 0.0;
    D(23168.)
    y += instrument(103.83, tint*(t-x) );

    x = t; b = 0.0;
    D(20864.)D(2688.)D(3456.)
    y += instrument(110.0, tint*(t-x) );

    x = t; b = 0.0;
    D(21248.)D(2688.)D(576.)
    y += instrument(123.47, tint*(t-x) );

    x = t; b = 0.0;
    D(24704.)
    y += instrument(138.59, tint*(t-x) );

    x = t; b = 0.0;
    D(10112.)D(10368.)D(4608.)
    y += instrument(146.83, tint*(t-x) );

    x = t; b = 0.0;
    D(25472.)
    y += instrument(164.81, tint*(t-x) );
    
    x = t; b = 0.0;
    D(20096.)
    y += instrument(185.0, tint*(t-x) );
    
    x = t; b = 0.0;
    D(9344.)D(576.)D(5568.)
    y += instrument(220.0, tint*(t-x) );
    
    x = t; b = 0.0;
    D(8576.)D(1152.)D(4992.)D(1152.)
    y += instrument(246.94, tint*(t-x) );
    
    x = t; b = 0.0;
    D(2432.)D(5376.)D(6144.)D(2112.)
    y += instrument(277.18, tint*(t-x) );

    x = t; b = 0.0;
    D(16256.)
    y += instrument(293.66, tint*(t-x) );

    return y;
}

vec2 mainSound( in int samp, float time )
{
    float t = time/tint;
    vec2 y = vec2(0.5,0.5)*doChannel1(t);
    y += vec2(0.25,0.75)*doChannel2(t);
    y += vec2(0.75,0.25)*doChannel3(t);
    return y*.8;
}
