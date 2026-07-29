// Buffer B (buffer) — Cathode by nimitz
// https://www.shadertoy.com/view/4lXcDH

//Cathode by nimitz (twitter: @stormoid)
//2017 nimitz All rights reserved

#define A 0.0
#define B 1.0
#define C 2.0
#define D 3.0
#define E 4.0
#define F 5.0
#define G 6.0
#define H 7.0
#define I 8.0
#define J 9.0
#define K 10.0
#define L 11.0
#define M 12.0
#define N 13.0
#define O 14.0
#define P 15.0


#define Encode(a,b,c,d,e,f) (a+16.0*(b+16.0*(c+16.0*(d+16.0*(e+f*16.0)))))


//Sprite render
vec3 sprite(in ivec2 p) {

    float sum = 0.;
    
    //Sprite data (3 blocks per line, allowing for a 16 color palette)
    if (p.y == 0)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 11) 	sum = Encode(A, A, B, B, B, B);
        else if(p.x <= 17) 	sum = Encode(B, A, A, A, A, A);
        else if(p.x <= 23) 	sum = Encode(B, B, B, C, B, B);
        else if(p.x <= 29) 	sum = Encode(B, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 1)
    {
        if(p.x <= 5) 		sum = Encode(A, C, C, C, C, C);
        else if(p.x <= 11) 	sum = Encode(C, B, C, D, D, C);
        else if(p.x <= 17) 	sum = Encode(C, C, B, C, C, B);
        else if(p.x <= 23) 	sum = Encode(C, E, E, C, D, C);
        else if(p.x <= 29) 	sum = Encode(C, B, B, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 2)
    {
        if(p.x <= 5) 		sum = Encode(C, F, G, E, E, G);
        else if(p.x <= 11) 	sum = Encode(G, C, C, D, D, D);
        else if(p.x <= 17) 	sum = Encode(D, C, C, C, D, C);
        else if(p.x <= 23) 	sum = Encode(G, G, F, C, M, D);
        else if(p.x <= 29) 	sum = Encode(C, B, C, B, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 3)
    {
        if(p.x <= 5) 		sum = Encode(C, F, F, G, G, F);
        else if(p.x <= 11) 	sum = Encode(C, B, C, D, H, D);
        else if(p.x <= 17) 	sum = Encode(D, D, C, D, D, E);
        else if(p.x <= 23) 	sum = Encode(F, F, I, C, I, D);
        else if(p.x <= 29) 	sum = Encode(C, B, D, C, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 4)
    {
        if(p.x <= 5) 		sum = Encode(A, C, I, I, F, D);
        else if(p.x <= 11) 	sum = Encode(D, B, B, C, D, D);
        else if(p.x <= 17) 	sum = Encode(D, D, D, D, M, C);
        else if(p.x <= 23) 	sum = Encode(I, I, G, G, C, M);
        else if(p.x <= 29) 	sum = Encode(D, B, D, C, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 5)
    {
        if(p.x <= 5) 		sum = Encode(A, A, C, C, D, M);
        else if(p.x <= 11) 	sum = Encode(C, C, D, B, C, D);
        else if(p.x <= 17) 	sum = Encode(D, C, D, C, C, B);
        else if(p.x <= 23) 	sum = Encode(E, G, F, I, F, C);
        else if(p.x <= 29) 	sum = Encode(G, C, M, B, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 6)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, C);
        else if(p.x <= 11) 	sum = Encode(E, C, D, D, B, B);
        else if(p.x <= 17) 	sum = Encode(B, B, B, H, H, D);
        else if(p.x <= 23) 	sum = Encode(B, F, I, C, C, I);
        else if(p.x <= 29) 	sum = Encode(F, C, C, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 7)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, G);
        else if(p.x <= 11) 	sum = Encode(F, C, C, D, B, C);
        else if(p.x <= 17) 	sum = Encode(C, H, D, B, H, H);
        else if(p.x <= 23) 	sum = Encode(D, B, B, G, F, C);
        else if(p.x <= 29) 	sum = Encode(C, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 8)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, F);
        else if(p.x <= 11) 	sum = Encode(F, E, C, B, B, B);
        else if(p.x <= 17) 	sum = Encode(E, C, D, B, C, C);
        else if(p.x <= 23) 	sum = Encode(C, D, D, C, C, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 9)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, F);
        else if(p.x <= 11) 	sum = Encode(F, E, C, J, J, B);
        else if(p.x <= 17) 	sum = Encode(B, E, E, G, E, C);
        else if(p.x <= 23) 	sum = Encode(C, C, C, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 10)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, F);
        else if(p.x <= 11) 	sum = Encode(G, E, C, H, J, J);
        else if(p.x <= 17) 	sum = Encode(B, D, D, D, D, C);
        else if(p.x <= 23) 	sum = Encode(C, A, A, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 11)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, F);
        else if(p.x <= 11) 	sum = Encode(G, E, C, H, H, J);
        else if(p.x <= 17) 	sum = Encode(B, M, M, D, C, C);
        else if(p.x <= 23) 	sum = Encode(H, C, A, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 12)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, G);
        else if(p.x <= 11) 	sum = Encode(F, G, E, C, H, J);
        else if(p.x <= 17) 	sum = Encode(B, M, I, M, C, C);
        else if(p.x <= 23) 	sum = Encode(J, C, A, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 13)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, B);
        else if(p.x <= 11) 	sum = Encode(F, G, G, C, J, B);
        else if(p.x <= 17) 	sum = Encode(M, I, I, I, C, J);
        else if(p.x <= 23) 	sum = Encode(C, C, C, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 14)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, B);
        else if(p.x <= 11) 	sum = Encode(F, I, G, C, J, B);
        else if(p.x <= 17) 	sum = Encode(M, I, I, I, C, J);
        else if(p.x <= 23) 	sum = Encode(C, E, E, C, C, C);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 15)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, B);
        else if(p.x <= 11) 	sum = Encode(F, I, G, E, J, B);
        else if(p.x <= 17) 	sum = Encode(D, M, M, I, B, H);
        else if(p.x <= 23) 	sum = Encode(C, G, G, E, E, E);
        else if(p.x <= 29) 	sum = Encode(C, C, C, C, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 16)
    {
        if(p.x <= 5) 		sum = Encode(A, A, B, A, A, B);
        else if(p.x <= 11) 	sum = Encode(C, F, G, J, B, B);
        else if(p.x <= 17) 	sum = Encode(C, C, D, B, H, C);
        else if(p.x <= 23) 	sum = Encode(F, F, F, F, G, G);
        else if(p.x <= 29) 	sum = Encode(E, D, C, E, C, C);
        else if(p.x <= 35) 	sum = Encode(C, A, A, A, A, A);
    }
    if (p.y == 17)
    {
        if(p.x <= 5) 		sum = Encode(A, A, B, B, A, B);
        else if(p.x <= 11) 	sum = Encode(H, C, E, J, C, F);
        else if(p.x <= 17) 	sum = Encode(G, G, B, H, J, C);
        else if(p.x <= 23) 	sum = Encode(C, C, G, I, F, F);
        else if(p.x <= 29) 	sum = Encode(D, M, E, G, E, C);
        else if(p.x <= 35) 	sum = Encode(E, C, A, A, A, A);
    }
    if (p.y == 18)
    {
        if(p.x <= 5) 		sum = Encode(A, B, L, K, B, A);
        else if(p.x <= 11) 	sum = Encode(B, H, H, C, F, G);
        else if(p.x <= 17) 	sum = Encode(J, I, E, B, C, A);
        else if(p.x <= 23) 	sum = Encode(A, A, C, C, C, C);
        else if(p.x <= 29) 	sum = Encode(H, E, G, F, C, C);
        else if(p.x <= 35) 	sum = Encode(E, C, A, A, A, A);
    }
    if (p.y == 19)
    {
        if(p.x <= 5) 		sum = Encode(A, B, L, K, B, A);
        else if(p.x <= 11) 	sum = Encode(B, C, C, G, F, F);
        else if(p.x <= 17) 	sum = Encode(G, G, J, C, A, A);
        else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(C, C, F, I, F, G);
        else if(p.x <= 35) 	sum = Encode(C, C, A, A, A, A);
    }
    if (p.y == 20)
    {
        if(p.x <= 5) 		sum = Encode(B, K, L, L, K, B);
        else if(p.x <= 11) 	sum = Encode(G, C, E, G, I, B);
        else if(p.x <= 17) 	sum = Encode(G, G, E, B, A, A);
        else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(A, A, C, G, E, C);
        else if(p.x <= 35) 	sum = Encode(C, A, A, A, A, A);
    }
    if (p.y == 21)
    {
        if(p.x <= 5) 		sum = Encode(A, C, K, K, L, B);
        else if(p.x <= 11) 	sum = Encode(E, C, C, E, H, B);
        else if(p.x <= 17) 	sum = Encode(G, E, B, B, B, B);
        else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(A, A, A, C, F, C);
        else if(p.x <= 35) 	sum = Encode(G, C, A, A, A, A);
    }
    if (p.y == 22)
    {
        if(p.x <= 5) 		sum = Encode(A, A, C, C, K, L);
        else if(p.x <= 11) 	sum = Encode(C, C, C, K, E, B);
        else if(p.x <= 17) 	sum = Encode(C, C, J, J, J, H);
        else if(p.x <= 23) 	sum = Encode(B, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(A, A, A, C, F, C);
        else if(p.x <= 35) 	sum = Encode(E, G, C, A, A, A);
    }
    if (p.y == 23)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, C, C);
        else if(p.x <= 11) 	sum = Encode(H, J, H, C, C, C);
        else if(p.x <= 17) 	sum = Encode(J, J, J, H, C, C);
        else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(A, A, A, A, C, F);
        else if(p.x <= 35) 	sum = Encode(C, F, C, A, A, A);
    }
    if (p.y == 24)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 11) 	sum = Encode(C, J, J, J, J, J);
        else if(p.x <= 17) 	sum = Encode(H, H, C, C, A, A);
        else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(A, A, A, A, C, I);
        else if(p.x <= 35) 	sum = Encode(C, C, A, A, A, A);
    }
    if (p.y == 25)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 11) 	sum = Encode(C, J, J, J, H, H);
        else if(p.x <= 17) 	sum = Encode(H, H, H, C, A, A);
        else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, C);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 26)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 11) 	sum = Encode(A, C, C, J, J, J);
        else if(p.x <= 17) 	sum = Encode(H, H, C, A, A, A);
        //else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    if (p.y == 27)
    {
        if(p.x <= 5) 		sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 11) 	sum = Encode(A, A, A, C, C, C);
        else if(p.x <= 17) 	sum = Encode(C, C, A, A, A, A);
        //else if(p.x <= 23) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 29) 	sum = Encode(A, A, A, A, A, A);
        //else if(p.x <= 35) 	sum = Encode(A, A, A, A, A, A);
    }
    
    //p.x = int(fract(float(p.x)/6.)*6.);
    if (p.x > 5) p.x -= 6;
    if (p.x > 5) p.x -= 6;
    if (p.x > 5) p.x -= 6;
    if (p.x > 5) p.x -= 6;
    if (p.x > 5) p.x -= 6;

	//decode
    float g = mod( floor(sum/pow(16.0,float(p.x))), 16.0 );
    
    
    //background
    vec3 col = vec3(0.63,0.63,0.64)*0.5;
    
    
    //palette
    //if (g > 12.) col = vec3(0);
    if (g > 11.) col = vec3(200./255., 168./255., 104./255.);
    else if (g > 10.) col = vec3(136./255., 64./255., 0./255.);
    else if (g > 9.) col = vec3(208./255., 112./255., 0./255.);
    else if (g > 8.) col = vec3(248./255., 240./255., 176./255.);
    else if (g > 7.) col = vec3(248./255., 248./255., 232./255.);
    else if (g > 6.) col = vec3(192./255., 160./255., 112./255.);
    else if (g > 5.) col = vec3(208./255., 144./255., 64./255.);
    else if (g > 4.) col = vec3(248./255., 216./255., 128./255.);
    else if (g > 3.) col = vec3(136./255., 80./255., 16./255.);
    else if (g > 2.) col = vec3(128./255., 96./255., 48./255.);
    else if (g > 1.) col = vec3(72./255., 40./255., 0./255.);
    else if (g > 0.) col = vec3(24./255., 16./255., 8./255.);
    
    return col;
}

vec3 dither(in ivec2 p) {
    vec3 col1 = vec3(.5,0.2,.7);
    vec3 col2 = vec3(0.7,0.2,0.5);
    float g = mod(gl_FragCoord.x + gl_FragCoord.y,2.);
    return mix(col1,col2, g);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord;
    p += vec2(0.0, -5.0);
    vec3 col = sprite(ivec2(p)-ivec2(15,10));
    //col = mix(col, dither(ivec2(p)-ivec2(30,7)), step(abs(p.x-60.),7.) * step(abs(p.y-25.),7.));
    fragColor = vec4(col, 1.0);
}