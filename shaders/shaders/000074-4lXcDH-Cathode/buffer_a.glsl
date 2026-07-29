// Buffer A (buffer) — Cathode by nimitz
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
        if(p.x <= 5) 		sum = Encode(N, N, N, N, N, N);
        else if(p.x <= 11) 	sum = Encode(A, A, A, A, N, N);
        else if(p.x <= 15) 	sum = Encode(N, N, N, N, A, A);
    }
    if (p.y == 1)
    {
        if(p.x <= 5) 	   	sum = Encode(N, C, M, M, M, N);
        else if(p.x <= 11) 	sum = Encode(A, A, A, A, N, M);
        else if(p.x <= 15) 	sum = Encode(M, M, C, N, A, A);
    }
    if (p.y == 2)
    {
        if(p.x <= 5) 	   	sum = Encode(A, N, M, M, M, N);
        else if(p.x <= 11) 	sum = Encode(A, A, A, A, N, M);
        else if(p.x <= 15) 	sum = Encode(M, M, N, A, A, A);
    }
    if (p.y == 3)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, J, J, J, J);
        else if(p.x <= 11) 	sum = Encode(A, A, A, A, J, J);
        else if(p.x <= 15) 	sum = Encode(J, J, J, A, A, A);
    }
    if (p.y == 4)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, J, I, I, I);
        else if(p.x <= 11) 	sum = Encode(J, A, A, A, J, I);
        else if(p.x <= 15) 	sum = Encode(I, I, J, A, A, A);
    }
    if (p.y == 5)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, J, I, H, H);
        else if(p.x <= 11) 	sum = Encode(I, J, J, J, J, I);
        else if(p.x <= 15) 	sum = Encode(H, I, J, A, A, A);
    }
    if (p.y == 6)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, J, I, H, H);
        else if(p.x <= 11) 	sum = Encode(H, I, I, I, I, H);
        else if(p.x <= 15) 	sum = Encode(H, I, J, A, A, A);
    }
    if (p.y == 7)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, A, J, H, H);
        else if(p.x <= 11) 	sum = Encode(H, H, H, H, H, H);
        else if(p.x <= 15) 	sum = Encode(I, J, N, A, A, A);
    }
    if (p.y == 8)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, A, J, H, B);
        else if(p.x <= 11) 	sum = Encode(B, H, H, H, H, B);
        else if(p.x <= 15) 	sum = Encode(B, J, B, N, A, A);
    }
    if (p.y == 9)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, A, J, H, B);
        else if(p.x <= 11) 	sum = Encode(B, H, H, H, H, B);
        else if(p.x <= 15) 	sum = Encode(B, J, B, N, A, A);
    }
    if (p.y == 10)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, A, F, J, I);
        else if(p.x <= 11) 	sum = Encode(H, H, H, H, H, H);
        else if(p.x <= 15) 	sum = Encode(I, B, B, N, A, A);
    }
    if (p.y == 11)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, G, F, E, E);
        else if(p.x <= 11) 	sum = Encode(I, H, G, G, H, I);
        else if(p.x <= 15) 	sum = Encode(F, N, N, A, A, A);
    }
    if (p.y == 12)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, G, E, E, E);
        else if(p.x <= 11) 	sum = Encode(I, I, F, F, I, I);
        else if(p.x <= 15) 	sum = Encode(E, G, A, A, A, A);
    }
    if (p.y == 13)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, G, E, F, M);
        else if(p.x <= 11) 	sum = Encode(M, M, M, M, M, E);
        else if(p.x <= 15) 	sum = Encode(G, A, A, A, A, A);
    }
    if (p.y == 14)
    {
        if(p.x <= 5) 	   	sum = Encode(A, G, E, F, F, G);
        else if(p.x <= 11) 	sum = Encode(D, D, D, D, D, M);
        else if(p.x <= 15) 	sum = Encode(M, A, A, A, A, A);
    }
    if (p.y == 15)
    {
        if(p.x <= 5) 	   	sum = Encode(A, G, E, F, G, C);
        else if(p.x <= 11) 	sum = Encode(N, N, N, N, N, N);
        else if(p.x <= 15) 	sum = Encode(C, M, A, A, A, A);
    }
    if (p.y == 16)
    {
        if(p.x <= 5) 	   	sum = Encode(A, G, E, F, G, N);
        else if(p.x <= 11) 	sum = Encode(N, N, N, N, N, N);
        else if(p.x <= 15) 	sum = Encode(N, C, M, A, A, A);
    }
    if (p.y == 17)
    {
        if(p.x <= 5) 	   	sum = Encode(A, G, E, F, G, N);
        else if(p.x <= 11) 	sum = Encode(N, D, D, D, D, N);
        else if(p.x <= 15) 	sum = Encode(N, C, N, D, A, A);
    }
    if (p.y == 18)
    {
        if(p.x <= 5) 	   	sum = Encode(A, G, G, G, G, C);
        else if(p.x <= 11) 	sum = Encode(D, C, C, C, C, D);
        else if(p.x <= 15) 	sum = Encode(C, N, N, D, A, A);
    }
    if (p.y == 19)
    {
        if(p.x <= 5) 	   	sum = Encode(N, B, B, B, B, N);
        else if(p.x <= 11) 	sum = Encode(B, N, C, C, N, B);
        else if(p.x <= 15) 	sum = Encode(C, C, N, D, A, A);
    }
    if (p.y == 20)
    {
        if(p.x <= 5) 	   	sum = Encode(N, N, N, N, B, N);
        else if(p.x <= 11) 	sum = Encode(B, N, C, C, N, B);
        else if(p.x <= 15) 	sum = Encode(C, D, N, D, A, A);
    }
    if (p.y == 21)
    {
        if(p.x <= 5) 	   	sum = Encode(N, B, N, B, B, N);
        else if(p.x <= 11) 	sum = Encode(B, B, D, D, B, B);
        else if(p.x <= 15) 	sum = Encode(N, N, G, A, A, A);
    }
    if (p.y == 22)
    {
        if(p.x <= 5) 	   	sum = Encode(N, B, B, N, N, N);
        else if(p.x <= 11) 	sum = Encode(N, N, N, N, N, N);
        else if(p.x <= 15) 	sum = Encode(N, N, G, A, A, A);
    }
    if (p.y == 23)
    {
        if(p.x <= 5) 	   	sum = Encode(A, N, N, N, B, N);
        else if(p.x <= 11) 	sum = Encode(N, N, N, N, N, N);
        else if(p.x <= 15) 	sum = Encode(N, F, G, A, A, A);
    }
    if (p.y == 24)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, N, B, B, N);
        else if(p.x <= 11) 	sum = Encode(N, N, N, N, N, N);
        else if(p.x <= 15) 	sum = Encode(E, F, G, A, A, A);
    }
    if (p.y == 25)
    {
        if(p.x <= 5) 	   	sum = Encode(A, N, B, N, B, N);
        else if(p.x <= 11) 	sum = Encode(E, L, B, B, L, E);
        else if(p.x <= 15) 	sum = Encode(F, G, A, A, A, A);
    }
    if (p.y == 26)
    {
        if(p.x <= 5) 	   	sum = Encode(A, N, N, A, N, N);
        else if(p.x <= 11) 	sum = Encode(G, E, L, K, E, G);
        else if(p.x <= 15) 	sum = Encode(G, A, A, A, A, A);
    }
    if (p.y == 27)
    {
        if(p.x <= 5) 	   	sum = Encode(A, A, A, A, A, A);
        else if(p.x <= 11) 	sum = Encode(A, G, G, G, G, A);
        else if(p.x <= 15) 	sum = Encode(A, A, A, A, A, A);
    }
    
    //p.x = int(fract(float(p.x)/6.)*6.);
    if (p.x > 5) p.x -= 6;
    if (p.x > 5) p.x -= 6;

	//decode
    float g = mod( floor(sum/pow(16.0,float(p.x))), 16.0 );
    
    
    //background
    vec3 col = vec3(0.63,0.63,0.64)*0.5;
    
    
    //palette
    if (g > 12.) col = vec3(0);
    else if (g > 11.) col = vec3(136./255., 88./255., 24./255.);
    else if (g > 10.) col = vec3(216./255., 160./255., 56./255.);
    else if (g > 9.) col = vec3(248./255., 216./255., 112./255.);
    else if (g > 8.) col = vec3(32./255., 48./255., 136./255.);
    else if (g > 7.) col = vec3(64./255., 128./255., 152./255.);
    else if (g > 6.) col = vec3(128./255., 216./255., 200./255.);
    else if (g > 5.) col = vec3(80./255., 0./255., 0./255.);
    else if (g > 4.) col = vec3(176./255., 40./255., 96./255.);
    else if (g > 3.) col = vec3(248./255., 64./255., 112./255.);
    else if (g > 2.) col = vec3(248./255., 112./255., 104./255.);
    else if (g > 1.) col = vec3(248./255., 208./255., 192./255.);
    else if (g > 0.) col = vec3(248./255., 248./255., 248./255.);
    
    return col;
}

vec3 dither(in ivec2 p) {
    vec3 col1 = vec3(.2,0.7,0.0)*0.75;
    vec3 col2 = vec3(0.7,0.3,0.3)*1.1;
    float g = mod(gl_FragCoord.x + gl_FragCoord.y,2.);
    return mix(col1,col2, g);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord;
    vec3 col = sprite(ivec2(p)-ivec2(21,35));
    //col = mix(col, dither(ivec2(p)), step(abs(p.x-30.),10.) * step(abs(p.y-30.),10.));
    fragColor = vec4(col, 1.0);
}