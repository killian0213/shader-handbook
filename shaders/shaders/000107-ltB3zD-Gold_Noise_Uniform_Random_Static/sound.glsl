// Sound (sound) — Gold Noise Uniform Random Static by dcerisano
// https://www.shadertoy.com/view/ltB3zD

// Generate Gold Noise sound



vec2 mainSound( in int samp,float time)
{
    return vec2(gold_noise(vec2(iSampleRate*fract(time/100.0)), 1.0));
}