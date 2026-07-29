// Image (image) — Two Tweets (244 chars) by iq
// https://www.shadertoy.com/view/MsfGzM

// Copyright Inigo Quilez, 2013 - https://iquilezles.org/
// I am the sole copyright owner of this Work.
// You cannot host, display, distribute or share this Work neither
// as it is or altered, here on Shadertoy or anywhere else, in any
// form including physical and digital. You cannot use this Work in any
// commercial or non-commercial product, website or project. You cannot
// sell this Work and you cannot mint an NFTs of it or train a neural
// network with it without permission. I share this Work for educational
// purposes, and you can link to it, through an URL, proper attribution
// and unmodified screenshot, as part of your educational material. If
// these conditions are too restrictive please contact me and we'll
// definitely work it out.


//---------------------
// 255 chars
//---------------------

#define f (length(cos(o)+.05*cos(9.*o.y*o.x)-.1*cos(9.*(.3*o.x-o.y+o.z)))-1.)

void mainImage( out vec4 c, in vec2 p )
{
    vec3 d = .5-vec3(p,1)/iResolution.x, o = d;
        
    //for( p.y=0.,o.z=iTime; p.y++<2e2; o+=f*d );
    for( p.y=2e2,o.z=iTime; p.y-->0.; o+=f*d );
    
    o -= d;    p.x = f;
    o += d-.6; p.y = f;
    
    c = (p.yxxx+p.yyxx)*exp(.2*(iTime-o.z));
}


/*
//---------------------
// 244 chars (can't publish, infinite loop at some resolutions)
//---------------------

#define f (length(cos(o)+.05*cos(9.*o.y*o.x)-.1*cos(9.*(.3*o.x-o.y+o.z)))-1.)

void mainImage( out vec4 c, in vec2 p )
{
    vec3 d = .5-vec3(p,1)/iResolution.x, o = d;
    
    for( o.z=iTime; f>.01; o+=f*d );
    
    o -= d;    p.x = f;
    o += d-.6; p.y = f;
    
    c = (p.yxxx+p.yyxx)*exp(.2*(iTime-o.z));
}
*/

/*
//---------------------
// 261 chars (-3 by Fabryce)
//---------------------

float f( vec3 p )
{ 
	p.z += iTime;
    return length(      cos(p)
                  + .05*cos(9.*p.y*p.x)
                  - .1 *cos(9.*(.3*p.x-p.y+p.z))
                  ) - 1.; 
}

void mainImage( out vec4 c, in vec2 p )
{
    vec3 d = .5-vec3(p,1)/iResolution.x, o = d;
    
    for( c=vec4(0,1,2,0); c.w++<2e2; o+=f(o)*d );
    
    c = abs( f(o-d)*c + f(o-.6)*c.zyxw )*(1.-.1*o.z);
}
/*
//---------------------
// 265 chars
//---------------------

float f( vec3 p )
{ 
	p.z += iTime;
    return length(      cos(p)
                  + .05*cos(9.*p.y*p.x)
                  - .1 *cos(9.*(.3*p.x-p.y+p.z))
                  ) - 1.; 
}

void mainImage( out vec4 c, in vec2 p )
{
    vec3 d = .5-vec3(p,1)/iResolution.x, o = d;
    
    for( c=vec4(0,1,2,0); c.w<256.; c.w++ ) o += f(o)*d;
    
    c = abs( f(o-d)*c + f(o-.6)*c.zyxw )*(1.-.1*o.z);
}
*/


/* 
//---------------------
// 268 chars
//---------------------

float f( vec3 p )
{ 
	p.z += iTime;
    return length(      cos(p)
                  + .05*cos(9.*p.y*p.x)
                  - .1 *cos(9.*(.3*p.x-p.y+p.z))
                  ) - 1.; 
}

void mainImage( out vec4 c, in vec2 p )
{
    vec3 d = .5-vec3(p,1)/iResolution.x, o = d;
    
    for( int i=0; i<256; i++ )
        o += f(o)*d;
        
    c = vec4(0,1,2,3);
    c = abs( f(o-d)*c + f(o-.6)*c.zyxw )*(1.-.1*o.z);
}

*/