// Buffer A (buffer) — The Great Gatsby Fractal by Yusef28
// https://www.shadertoy.com/view/lXXSz7

#define LETTER_SIZE 1./16.
#define STEP_SIZE 1./15.
#define FIRST_LETTER 64.
#define FIRST_NUMBER 48.

#define _a 1.
#define _b 2.
#define _c 3.
#define _d 4.
#define _e 5.
#define _f 6.
#define _g 7.
#define _h 8.
#define _i 9.
#define _j 10.
#define _k 11.
#define _l 12.

#define _m 13.
#define _n 14.
#define _o 15.
#define _p 16.
#define _q 17.
#define _r 18.
#define _s 19.
#define _t 20.
#define _u 21.
#define _v 22.
#define _w 23.
#define _x 24.
#define _y 25.
#define _z 26.

vec2 numToCoord(float a){
    return vec2( mod(a,16.), 15.-floor(a/16.) );
}

vec3 C(vec2 uv, vec2 start, inout float moveX,float num){
    moveX -= STEP_SIZE/2.;
    if(uv.x < start.x           || 
       uv.x > start.x+STEP_SIZE || 
       uv.y < start.y           || 
       uv.y > start.y+STEP_SIZE){
       
       return vec3(0.);
    }
    
    uv -= start; uv /= STEP_SIZE; uv *= LETTER_SIZE;
    uv += vec2(LETTER_SIZE*numToCoord(num));
    return textureGrad(iChannel1,uv,dFdx(uv),dFdy(uv)).rrr;
}

//takes a float and prints the first 4 digits
void generateDigits(vec2 uv, vec2 start, float moveX, 
                     float theNumber, float theSign, inout vec3 col){
    
    float s = 1.;
    float count = 0.;
    
    float FN = fract(theNumber)*100.;
    float ones = floor(mod(FN,10.));
    //after decimal
    col += C(uv, vec2(moveX,start.y), moveX, FIRST_NUMBER + ones);
    float tens = floor(FN/10.);
    col += C(uv, vec2(moveX,start.y), moveX, FIRST_NUMBER + tens);
    //decimal point
    col += C(uv, vec2(moveX,start.y), moveX, FIRST_NUMBER -2.);
    FN = floor(theNumber);
    //before decimal
    while(FN >= 1.){
        float n = floor(mod(FN,10.));
        col += C(uv, vec2(moveX,start.y), moveX, FIRST_NUMBER + n);
        FN /= 10.;
    }
    
    //col += C(uv, vec2(moveX,start.y), moveX, FIRST_NUMBER -3. -2.*step(0.,theSign));
    
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord.xy/iResolution.xy;
    vec2 m = iMouse.xy/iResolution.xy;
    vec3 col = vec3(0.);
    generateDigits(uv, vec2(0.,0.4), 0.7, m.x, float(1.), col);
    generateDigits(uv, vec2(0.,0.4), 0.8, m.y, float(1.), col);
    fragColor = vec4(col,1.0);
}