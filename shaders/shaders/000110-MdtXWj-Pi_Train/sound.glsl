// Sound (sound) — Pi Train by mzadami
// https://www.shadertoy.com/view/MdtXWj

float Puff(float seed, float time)
{
    float t = time / 0.2;
    
    if (t <= 0.0 || t >= 1.0)
    {
        return 0.0;
	}
    
    float p = t;
    float n = 1.0 - t;
    
    float amp = 6.0 * n * p * p;
    
    seed *= 123.456;
    seed  = fract(sin(seed) * 100.0);

    float overall_vol = mix(0.05, 0.25, seed);

    seed += 7.0;
    seed *= 11.0;
    seed  = fract(sin(seed) * 100.0);

    float buzz = seed;
    
    seed *= time;
    seed += 2.39687843;
    seed *= time;
    seed  = fract(seed * 100.0);
    seed  = sin(seed);
    
    return pow(fract(seed * 100.0), mix(1.0, fract(seed), buzz)) * amp * overall_vol;
}

float Click(float seed, float time)
{
    return Puff(seed, time * 5.0);
}


vec2 mainSound( in int samp, float time )
{
    float total = 0.0;
    
    // Mimic time calc in image
    time = (max(0.0, time - 2.0) / 60.0) * 80.0;

    // Extra clicks as we accelerate.
    total += Click(51.6, time - 0.00);
    total += Click(61.5, time - 0.01);
    total += Click(71.4, time - 0.03);
	total += Click(81.3, time - 0.06);

    total += Click(75.6, time - 1.00);
    total += Click(85.5, time - 1.01);
    total += Click(95.4, time - 1.03);

    total += Click(3.9, time - 1.50) * 0.8;
    total += Click(4.8, time - 2.00);
    total += Click(5.7, time - 2.33) * 0.9;
    total += Click(6.6, time - 2.67) * 0.8;
    total += Click(7.5, time - 3.00) * 0.9;
    total += Click(8.4, time - 3.25) * 0.8;
    total += Click(9.2, time - 3.50) * 0.7;
    total += Click(9.1, time - 3.75) * 0.6;
    
    // Engine running...
    float engine_amp = smoothstep(0.0, 2.0, time);
    
    total += Click(1.1 + fract(time), fract(time - 0.0)) * 0.50 * engine_amp;
    total += Click(3.2 + fract(time), fract(time - 0.2)) * 0.45 * engine_amp;
    total += Click(5.3 + fract(time), fract(time - 0.4)) * 0.42 * engine_amp;
    total += Click(7.4 + fract(time), fract(time - 0.6)) * 0.41 * engine_amp;
    total += Click(9.5 + fract(time), fract(time - 0.8)) * 0.40 * engine_amp;
    
	// TIME_TO_START_PUFFING... with a bit of extra anticipation
	float puff_time = time - 2.9;

    if (puff_time > 0.0 && puff_time < 60.0)
    {
        total += Puff(ceil(puff_time) * 1.234, fract(puff_time));
    }

    float final_vol = smoothstep(69.0,65.0,time);
    
	return vec2(total * final_vol);
}

