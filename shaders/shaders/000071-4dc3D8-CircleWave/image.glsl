//  (image) — CircleWave by RenoM
// https://www.shadertoy.com/view/4dc3D8

#define SCALE 20.
#define SPEED 9.
#define FREQUENCY .3

float d;
#define C(p)  min(1., sqrt(10.*abs(length(p-.5)-.4)))
#define D(p,o)  ( (d=length(p-o)*5.)<=.6 ? d:1. )
/*
void mainImage( out vec4 O, in vec2 U )    // compact version by FabriceNeyret2 (having problems with it on windows)
{
    vec2 R = iResolution.xy, 
         p = SCALE*(U+U/R)/R.y,
         i = ceil(p);
    O -= O - C(i-p) * D(i-p, .5 + .4 * sin( iDate.w*SPEED + (i.x+i.y)*FREQUENCY + vec2(1.6,0) ));
}*/

void mainImage( out vec4 O, in vec2 U )
{
    vec2 R = iResolution.xy, 
         p = SCALE*(U+U/R)/R.y,
         f = fract(p);
    p=floor(p);
    float t=(p.x+p.y)*FREQUENCY
           +iTime*SPEED;
    vec2 o=vec2(cos(t),sin(t))*.4+.5;
    O.xyz = vec3(C(f)*D(f,o));
}