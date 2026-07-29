// Common (common) — Path Racers by friol
// https://www.shadertoy.com/view/3s2BzV


const float globalTempo=130.0; // global, song tempo dancing


vec2 oldRand(inout vec2 seed,float time) 
{
    seed+=vec2(-0.001,0.001);
    return vec2(fract(cos(dot(seed.xy ,vec2(123.4+sin(time),234.5))) * 43758.5453),
		fract(cos(dot(seed.xy ,vec2(4.898,7.23))) * 133421.631));
}

vec2 rand2n(vec2 co,float time){
    return vec2(
        fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453),
        fract(cos(dot(co.xy ,vec2(32.9898,78.233))) * 13758.5453)
    );
}

float hash21(vec2 p) {
  return fract(sin(dot(p, vec2(425.215, 714.388)))*45758.5453);
}
