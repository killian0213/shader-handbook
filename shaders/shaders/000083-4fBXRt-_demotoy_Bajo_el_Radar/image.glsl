// Image (image) — [demotoy] Bajo el Radar by Kali
// https://www.shadertoy.com/view/4fBXRt

//        ___.                       ___            .___ ___________
// ,___ _\(   |._____________ __. __\(__/___. ______\|_  \\          )_. ________,
// |%%% |     ||            //  |/          |/        /                | %%%%%%%%|
// |%%% |    _||                |           |        _                 | %%%%%%%%|
// |'_ _|    \                 _|          _|        |                 |_ _ `%%%%|
//  .\)\_______________________)|__________)|________|__________________/(/.
// <------------------------------------------------------------------------diP->>
//         l a t i t u d e  i n d e p e n d e n t  a s s o c i a t i o n
// <<---------------------------------------------------------------------------->
// 
//                                     L.I.A.
// 
//                                    presents
// 
//                                 "Bajo el Radar"
// 
// 
//                                a Shadertoy demo
// 
// 
// --------------------------------- Release Info --------------------------------
// 
// 
//   For the final task of the Genuary 2024 event, Kali coded a demo on Shadertoy 
//   that encompasses the prompts of skeuomorphism, SDFs, shaders, and generative 
//   music (days 28, 29, 30, and 31 respectively).
//
//   Press rewind button if music doesn't play or is out of sync
//
//   What's Genuary? check genuary.art
//
// 
// ------------------------------------ Members -----------------------------------
// 
//      Bitnenfer - Foco - Kali - Shining Monster - Riq - Uctumi - Mr. Roboto
// 
// ---------------------------------- Greetings ----------------------------------
// 
//   Thanks to Piter Pasma for Genuary, his support and contributions to the 
//   generative art community.
//                                                                     
// -------------------------------------------------------------------------------
// 
//  
//                         Signing off... The LIA crusaders



#define PI 3.14159
#define resolution iResolution.xy
#define time iTime
#define vTexCoord (gl_FragCoord.xy/iResolution.xy)
#define tx iChannel0

const float max_rad=.03;
const float it=100.;

uniform float force ;

#define time iTime


mat2 rot(float a){
	float s=sin(a);
    float c=cos(a);
    return mat2(c,s,-s,c);
}

float hash(vec2 p)
{
    p*=1342.;
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float rnd(float p)
{
    p*=123.;
    p = fract(p * .1031);
    p *= p + 33.33;
    return fract(2.*p*p);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord/iResolution.xy;
	mat2 spin=rot(2.39996);
    vec2 p=vec2(0.,1.);
    vec3 res=vec3(0.);
    float ti=mod(time*.5,10.);
    float rad_step=max_rad/it+hash(uv+ti)*.0003;
	float rad=0.;
    float ru=step(18.,time)*smoothstep(21.,20.,time);
    vec4 col=texture(iChannel0,uv+sin(time*20.)*ru*.03);
    for (float i=0.;i<it; i++) {
        rad+=rad_step;
        p*=spin;
        vec4 col=texture(iChannel0,uv+p*rad);
        res+=smoothstep(.2,1.,max(col.r,max(col.g,col.b)))*col.rgb;
    };
    res/=it;
    vec4 ff = vec4(col.rgb*.5+res*1.3,1.0)*1.4; 
    if (ru>0.) {
        ff.rgb=ff.rrr*vec3(.5,1.,.3);
        ff+=(hash(vTexCoord+(ti*20.))-.5)*.5;
    }
    ff+=step(21.,time)*smoothstep(21.5,21.0,time);
    ff.rgb=mix(length(ff.rgb)*vec3(.5),ff.rgb,.8);
    ff.rgb=clamp(ff.rgb,0.,1.);
    fragColor = ff*min(1.,iTime*.2)*smoothstep(58.,54.,time);
}