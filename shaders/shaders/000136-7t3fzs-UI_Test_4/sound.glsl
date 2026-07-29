// Sound (sound) — UI Test 4 by yasuo
// https://www.shadertoy.com/view/7t3fzs

vec2 mainSound( in int samp,float time) {
    float t = fract(sin(time*100.0))*0.1;
    vec2 result = vec2(sin(float(samp)*2.5*t));
    float volume = 0.01;    
    return result*volume;
}