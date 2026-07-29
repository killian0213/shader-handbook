// Image (image) — Dutch Windmill [173 Chars] by SnoopethDuckDuck
// https://www.shadertoy.com/view/dlycDt

// -3 by xor! [173] 🐠
void mainImage(out vec4 o, vec2 u)
{
    u *= 4. / iResolution.y;
    for(float i; i++<9.; o = tan(.1*(i+u--.yxxx+u.yyxx)))
        u += tanh(13./i*sin(i*u.yx-iTime-19.*atan(u.x,u.y)))/i;    
    o = exp(-++o*o*o);
}


// Honorable mention: [163] Myth0genesis 🐠 and shadertoyjiang 🐠
/*
void mainImage( out vec4 o, vec2 u )
{
    u *= 4. / iResolution.y;
    for(float i; i++<9.; o = 1.+tan(1.8-.08*(u--.yxxx+u.yyxx)))
        u += tanh(13./i*sin(i*u.yx-iTime-19.*atan(u.x,u.y)))/i
           ;
}
//*/

// Original [176]
/*
void mainImage( out vec4 o, vec2 u )
{
    u *= 4. / iResolution.y;
    for(float i; i++<9.; o = 1.+tan(1.+.1*(u.yxxx+u.yyxx)))
        u += tanh(13./i*sin(i*u.yx-iTime-19.*atan(u.x,u.y)))/i
           -1.;    
    o = exp(-o*o*o);
}
//*/