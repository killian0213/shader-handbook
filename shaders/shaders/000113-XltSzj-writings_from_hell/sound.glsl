// Sound (sound) — writings from hell by flockaroo
// https://www.shadertoy.com/view/XltSzj

// created by florian berger (flockaroo) - 2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

vec2 mainSound( in int samp, float time )
{
    float t=.1*time;
    vec4 r=texture(iChannel0,fract(vec2(t,t*.01)));
    t=time/iChannelResolution[0].x*iSampleRate*.015;
    vec4 r2=texture(iChannel0,fract(vec2(t,.5/256.+t/200.)))-.5;
    bool penta=mod(time+5.,37.7)>18.;
    return .3*clamp(vec2(
        // some higher pitch when pentagram is painted
        + (penta?1.5:1.)*r.xy*sin(6.2831*(penta?333.0:220.)*time)
        // some low pitch sines modulated with some random loudness
        + r.yz*sin(6.2831*140.0*time)
        + r.yz*sin(6.2831*20.0*time)
        // some low pitch grumbling noise
        + 3.*r2.xy 
	),-1.,1.)*clamp(time*.1,0.,1.);
}