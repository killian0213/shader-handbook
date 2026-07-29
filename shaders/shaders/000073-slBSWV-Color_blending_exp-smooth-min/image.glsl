// Image (image) — Color blending exp-smooth-min by iq
// https://www.shadertoy.com/view/slBSWV

// The MIT License
// Copyright © 2021 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Shows one possible way to blend materials when using
// exponential-smooth-blend to merge SDF primitives together.


// https://iquilezles.org/articles/smin
vec2 smin( in float a, in float b, in float k )
{
    float f1 = exp2( -k*a );
    float f2 = exp2( -k*b );
    return vec2(-log2(f1+f2)/k,f2);
}

// iquilezles.org/articles/distfunctions2d
float sdBox( in vec2 p, in vec2 b ) 
{
    vec2 q = abs(p)-b;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // pixel coordinates
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;

    // background color
    vec3 col = vec3( 0.1+0.05*mod(floor(p.x*4.0)+floor(p.y*4.0),2.0) );

    // compute SDF and its color
    float dmin = 1e20;
    vec4  dcol = vec4(0.0,0.0,0.0,0.0);
    for( int i=0; i<10; i++ ) // 10 boxes
    {
        float h = float(i);
        
        // new box position and color
        vec2 ce = vec2(1.5,1.0)*cos(0.1*iTime*vec2(1.3+0.1*h,1.7+(7.0-h)*h*0.3)+h*vec2(11.1,28.7)+vec2(0.0,2.0));
        vec3 co = 0.5 + 0.5*cos(h*1.0+vec3(0.0,2.0,4.0)); co = co*co;
        
        // distance to box
        float dis = sdBox(p-ce,vec2(0.4,0.2));

        // smoothly blend SDFs
        vec2 db = smin( dmin, dis, 10.0 );
        dmin = db.x;

        // smoothly blend colors
        float w = db.y;
        dcol += vec4(co*w,w);
    }
    // resolve color
    dcol.xyz /= dcol.w;
    
    // draw SDF on top
    col = mix( col, dcol.xyz, 1.0-smoothstep(0.0,0.01,dmin) );
    
    // gamma
    col = sqrt(col);
    
    // output to screen
    fragColor = vec4(col,1.0);
}