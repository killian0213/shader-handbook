// Sound (sound) — Shiny sphere lights by shaderology
// https://www.shadertoy.com/view/ltjGDd

vec2 mainSound( in int samp,float time)
{
	float sec = mod(time,1.);
    float ech = mod(time,.2);
    float sph = floor( mod(time,27.));
    float rnd = fract( 876.432 * sin( sph ) ) + 5.;
    float hum = sin(400.0*time) * sin(8.0*time) * 0.2;
    float bel = sin(rnd*340.0*sec)*exp(-4.0*sec)*exp(-4.0*ech)*.5;
    return vec2( hum + bel );
}
