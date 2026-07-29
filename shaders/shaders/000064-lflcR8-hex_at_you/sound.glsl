// Sound (sound) — hex at you by pb
// https://www.shadertoy.com/view/lflcR8

//sound by me_123

float hash11(float p) {
	uvec2 n = uint(int(p)) * uvec2(1597334673U, 3812015801U);
	uint q = (n.x ^ n.y) * 1597334673U;
	return float(q) * (1.0 / float(0xffffffffU));
}
float smoothfract(in float x, in float s) {
    float k = fract(x)-s;
    return k < 0.0 ? -k/s : k/(1.-s);
}
float noise(in float x) {
    float k = 0.5-0.5*cos(3.141592*fract(x));
    return mix(hash11(floor(x)), hash11(floor(x)+1.0), k)*2.0-1.0;
}
float fbm(in float x) {
    float v = 0.0;
    for (float i = 0.0; i < 5.; i++) {
        v += noise(x*pow(2., i))*pow(2., -i);
        x += 100.;
    }
    return v*0.5;
}
float fr(in float x, in float k) {
    return smoothfract(x, k)*2.0-1.0;
}
float f(in float x, in float time) {
    float k = 1./(mod(time-2./8., 1./8.*20.0*2.0)*10.+1.0);
    return 0.5*(fr(x, k)+fr(x/2.*1.025125, k)+fr(x/3.0*1.015125, k));
}
float f1(in float x, in float time) {
    return fr(x, 0.1);
}
float f2(in float x, in float time) {
    float k = cos(fract(x)*3.141592*2.)*smoothfract(x*0.5, pow(1.-time, 2.0));
    return k/(time+abs(k));
}
float p10(in float x) {
    x *=x;
    float xx = x; //x^2
    x *= x; //x^4
    x *= x; //x^8
    return x*xx; //x^10
}
float drum(in float time){
    float v = 0.0;
        v += hash11(time*88000.)*exp(-fract(time*2.0)*10.);
    v += hash11(time*88000.)*exp(-fract(time*1.0)*20.);
    if (time > 3.0) v += fbm(time*8000.)*exp(-fract(time*2.0+0.5)*8.);
    if (time > 4.0) v += fbm(time*8000.)*exp(-fract(time*2.0+0.75+0.125)*16.);
    if (time > 1.0) v += fbm(time*8000.)*exp(-fract(time*8.0)*16.);
    if (time > 5.0) v += fbm(time*1600.)*exp(-fract(time*8.0+0.5)*5.);
    return v;
}
float n(in float x) {
    return 440.*pow(0.5, x/12.);
}
float[5] k = float[5](0.0,2.0,4.0,6.0,7.0);
vec2 mainSound( int samp, float time )
{
    float v = f1(time*n(k[int(floor(time*4.0)*floor(time*2.0)+floor(time*4.0)*floor(time*2.0))%5])*0.25, time);
    v *= fract(time*2.0);
    v = mix(v, fbm(time*1000.), cos(time*0.915281+1325.152)*0.05+0.05);
    v = mix(v, fbm(time*5000.), cos(time*0.581251)*0.05+0.05);
    v = mix(v, fbm(time*10000.), cos(time*0.692415+16.)*0.05+0.05);
    time *= 0.5;
    v += 0.5*(tanh(time-20./8.*2.0)*0.5+0.5)*f(time*n(k[int(floor(time*4.0)+floor(time*8.0)*floor(time*2.0))%5]), 0.0);
    v += p10(noise(time))*f2(time*n(k[3-int(floor(time*32.0))%4])*8.0, 0.5)*(tanh(time-20./8.*4.0)*0.5+0.5);
    v += p10(noise(time+10.))*f2(time*n(k[4-int(floor(time*16.0))%3])*4.0, 0.5)*(tanh(time-20./8.*4.0)*0.5+0.5);
    if (time > 5.0) v += drum(time-5.0)*0.5;
    return vec2(v*0.5);
}