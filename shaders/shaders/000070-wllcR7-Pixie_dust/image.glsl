// Image (image) — Pixie dust by rory618
// https://www.shadertoy.com/view/wllcR7

//Draw 16 thousand dynamic bokeh dots and volumetric lights
//See:
//https://www.shadertoy.com/view/WssfDn
//https://www.shadertoy.com/view/Wdlfz7
//https://www.shadertoy.com/view/tdlBz7
//https://www.shadertoy.com/view/wdsBRn
//https://shadertoy.com/view/ttXyR8
//for all the utilities and algorithm leading up to this,
//and the paper: https://devblogs.nvidia.com/wp-content/uploads/2012/11/karras2012hpg_paper.pdf


vec4 F(vec2 p, vec2 r)
{
    vec4 t = texture(iChannel2, (p+r)/R.xy);
    return 0.01*exp(-.03*dot(r,r))*(exp(2.*t)-1.);
}

void mainImage( out vec4 O, in vec2 I )
{   
    O = max(texture(iChannel2, I/R.xy), 0.);
    for (float i = 0.; i < 7.; i+=1.1) {
    	O += F(I,+vec2(-i,i));
    	O += F(I,+vec2(i,i));
    	O += F(I,-vec2(-i,i));
    	O += F(I,-vec2(i,i));
    }
    O/=2.;
}