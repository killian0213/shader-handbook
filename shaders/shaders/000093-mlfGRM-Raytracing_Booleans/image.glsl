// Image (image) — Raytracing Booleans by iq
// https://www.shadertoy.com/view/mlfGRM

// The MIT License
// Copyright © 2022 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Raytracing boolean operations on shapes.
//
// Top: intersection of some shapes (box, sphere and plane)
// Bottom: subtraction of same shapes
//
// This works by doing boolean operations in "ray space" (ie,
// manipulating intervals of ray distances). I'm only tracking one
// segment, more should be added for deeper boolean trees.
//
// When intersecting two solid intervals A and B, there are 6 possible
// scenarios for their combination:
//
// 1     x---x  |             |
// 2     x------|---x         |
// 3     x------|-------------|--x
// 4            |   x-----x   |
// 5            |   x---------|--x
// 6            |             |  x---x 
//
// Subtraction in scenario 4 produces TWO segments, but I'm only tracking
// ONE segment at a time in this shader, so I've got to take an arbitrary
// decision as to what to do in that case (line 58).


Intersection opIntersection( Intersection a, Intersection b, out int r )
{
    if( a.a.x<b.a.x )
    {
        /* 1 */ if( a.b.x<b.a.x ) return kEmpty;
        /* 2 */ if( a.b.x<b.b.x ) { r=1; return Intersection(b.a,a.b); }
        /* 3 */ { r=1; return b; }
    }
    else if( a.a.x<b.b.x )
    {
        /* 4 */ if( a.b.x<b.b.x ) { r=0; return a; }
        /* 5 */ { r=0; return Intersection(a.a,b.b); }
    }
    else
    {
        /* 6 */ return kEmpty;
    }
}

Intersection opSubtraction( Intersection b, Intersection a, out int r )
{
    if( a.a.x<b.a.x )
    {
        /* 1 */ if( a.b.x<b.a.x ) { r=0; return b; }
        /* 2 */ if( a.b.x<b.b.x ) { r=1; return Intersection(a.b,b.b); }
        /* 3 */ return kEmpty;
    }
    else if( a.a.x<b.b.x )
    {
        /* 4 */ if( a.b.x<b.b.x ) { r=0; return Intersection(b.a,a.a); } // hm.... difficult to choose
        /* 5 */ { r=0; return Intersection(b.a,a.b); }
    }
    else
    {
        /* 6 */ { r=0; return b; }
    }
}

vec4 raycast( in Ray r, ivec2 id, out int objID )
{   
    const vec4 pl = vec4(normalize(-vec3(1,1,1)),-0.1);

    // transform one of the primitives
   	mat4 rot = rotationAxisAngle( normalize(vec3(1.0,1.0,0.0)), 0.5*iTime );
	mat4 tra = translate( 0.0, 0.0, 0.2*sin(iTime) );
	mat4 txx = tra * rot; 

    // by transforming the ray with its inverse
    Ray rt = transform( r, inverse(txx) );

    // intersect primitives
    Intersection a, b;
    
    if( id.x==0 )
    {
        a = iSphere(r.o,r.d,0.3);
        b = iPlane(rt.o,rt.d,pl);
    }
    else if( id.x==1 )
    {
        a = iSphere(r.o,r.d,0.3);
        b = iBox(rt.o,rt.d,vec3(0.4,0.2,0.1) );
    }
    else if( id.x==2 )
    {
        a = iBox(r.o,r.d,vec3(0.3,0.2,0.1) );
        //b = iPlane(rt.o,rt.d,pl);
        b = iSphere(rt.o,rt.d,0.3);
    }
    else
    {
        a = iBox(r.o,r.d,vec3(0.4,0.1,0.2) );
        b = iBox(rt.o,rt.d,vec3(0.3,0.3,0.2) );
    }
    
    // bottom row subtraction, top row intersection
    int o;
    Intersection i;
    if( id.y==0 ) i = opSubtraction( a,b,o);
    else          i = opIntersection(a,b,o);
    
    // no intersection
    if( isEmpty(i) ) { objID=-1; return vec4(-1.0); }

    // intersection
    objID = o; return vec4(i.a.x,i.a.yzw);
}

#define AA 2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // camera movement	
	float an = 1.0 + 0.0 * 0.8*sin(0.1*iTime);
	vec3 ro = vec3( 0.9*sin(an), 0.2+0.2*sin(1.0*an), 0.9*cos(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    // global normalize coordinates
    vec2 gp = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    // 4x2 screen tiles
    ivec2 id = ivec2(vec2(4,2)*fragCoord/iResolution.xy);
    vec2 res = iResolution.xy/vec2(4,2);
    vec2 q   = mod(fragCoord,res);

    // render
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(q+o)-res.xy)/res.y;
        #else    
        vec2 p = (2.0*q-res.xy)/res.y;
        #endif
        
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );
        
        // background
	    vec3 col = vec3(0.07) * (1.0-0.3*length(gp));
        //col += 0.1*cos( float(5*id.y+id.x)+vec3(0,2,4));

        // raycast
        int obj = -1;
        vec4 tnor = raycast( Ray(ro,rd), id, obj);
        if( tnor.x>0.0 )
        {
            float t = tnor.x;
            vec3  pos = ro + t*rd;
            vec3  nor = tnor.yzw;

            // material
            #if 1
            vec3 pa = cos(60.0*pos); 
            vec3 mate = vec3(0.1,0.5,0.7) + vec3(0.9,0.5,0.3)*smoothstep(-1.0,1.0,pa.x+pa.y+pa.z); 
            #else
            vec3 mate = vec3(0.0,0.5,0.5);
            #endif
            if( obj==1 ) mate =vec3(0.9,0.4,0.0);

            // lighting
            vec3  lig = normalize(vec3(0.7,0.5,-0.4));
            vec3  hal = normalize(-rd+lig);
            float dif = clamp( dot(nor,lig), 0.0, 1.0 );
            float amb = clamp( 0.5 + 0.5*nor.y, 0.0, 1.0 );
            
            col  = mate*vec3(0.20,0.25,0.30)*amb;
            col += mate*vec3(1.00,0.90,0.70)*dif;
            col += 0.2*pow(clamp(dot(hal,nor),0.0,1.0),24.0)*dif;
            //col = pow(0.5 + 0.5*nor,vec3(2.2));
        }

        // gamma
        col = pow( col, vec3(1.0/2.2) );
	
	    tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // dither to remove banding in the background
    tot += fract(sin(fragCoord.x*vec3(13,17,11)+fragCoord.y*vec3(1,7,5))*158.391832)/255.0;

    fragColor = vec4( tot, 1.0 );
}