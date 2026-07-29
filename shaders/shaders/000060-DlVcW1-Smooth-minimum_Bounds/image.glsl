// Image (image) — Smooth-minimum Bounds by iq
// https://www.shadertoy.com/view/DlVcW1

// The MIT License
// Copyright © 2024 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Comparison of most smin() pressented in this article:
// https://iquilezles.org/articles/smin/
//
// ** Note that all smooth minimum functions are normalized so
//    that the blending parameter k corresponds to the maximum
//    thickness of the blended region. This makes them more or
//    less interchangeable and allows for easy bounding volume
//    computation (in cyan).
//
// ** Mouse click - shows in dark the areas in the plane where
//    the smin() has taken over the regular union/min() of the
//    two source SDFs, a and b. This means that a ray marching
//    through the dark orange regions will travel at a reduced
//    speed compared to speed of a perfect SDF raymarcher (the
//    "Speed of Light").
//
// ** The Circular Geometrical smin (bottom right) is the only
//    locally supported smin(), which is great. But it is also
//    the only smin() over-estimating distances, making it not
//    the best candidate for vanilla raymarching and collision
//    detection.

float smin( float a, float b, float k, int type )
{
    // Quadratic
    if( type==0 )
    {
        k *= 4.0;
        float h = max(k-abs(a-b),0.0);
        return min(a, b) - h*h*0.25/k;
    }
    // Cubic
    if( type==1 )
    {
        k *= 6.0;
        float h = max( k-abs(a-b), 0.0 )/k;
        return min( a, b ) - h*h*h*k*(1.0/6.0);
    }
    // Quartic
    if( type==2 )
    {
        k *= 16.0/3.0;
        float h = max( k-abs(a-b), 0.0 )/k;
        return min( a, b ) - h*h*h*(4.0-h)*k*(1.0/16.0);
    }
    // Circular
    if( type==3 )
    {
        k *= 1.0/(1.0-sqrt(0.5));
        float h = max( k-abs(a-b), 0.0 )/k;
        return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
    }
    // Exponential
    if( type==4 )
    {
        return -k*log2( exp2( -a/k ) + exp2( -b/k ) );
    }
    // Sigmoid
    if( type==5 )
    {
        k *= log(2.0);
        float x = b-a;
        return a + x/(1.0-exp2(x/k));
    }
    // SquareRoot
    if( type==6 )
    {
        k *= 2.0;
        float x = b-a;
        return 0.5*( a+b-sqrt(x*x+k*k) );
    }
    // Circular Geometrical
    if( type==7 )
    {
        k *= 1.0/(1.0-sqrt(0.5));
        return max(k,min(a,b))-length(max(vec2(k-a,k-b), 0.0));
    }
}

// primitives
float sdBox(  in vec2 p, in vec2  b ) { vec2 q = abs(p)-b; return min(max(q.x,q.y),0.0) + length(max(q,0.0)); }
float sdDisk( in vec2 p, in float r ) { return length(p)-r; }

// return SDF, non-smooth SDF, and difference
vec3 map( in vec2 p, float w, int type )
{
    float d1 = sdBox( p-vec2(0.4,0.3), vec2(0.1,0.3) );
    float d2 = sdDisk(p-vec2(-0.3,-0.2+0.25*sin(iTime)), 0.25 );
    
    return vec3( smin(d1,d2,w,type), min(d1,d2), d1-d2 );
}    

float print( in float sdf, inout vec2 p, in int str[12])
{
    if( p.y<0.0|| p.y>1.0 ) return sdf;
    float d = 1e20;
    for( int i=0; i<str.length(); i++ )
    {
        int c = str[i];
        if( c==0 ) break;
        if( p.x>0.0 && p.x<1.0 )
        {
            vec2 q = p/16.0;
            d = min(d,textureGrad( iChannel0, vec2(c,15-c/16)/16.0+q, dFdx(q), dFdy(q) ).w);
        }
        p.x -= 0.5;
    }
    return min(d,sdf);
}

bool isNotLowerBound( in vec2 p, float d, float blend_width, int tile )
{
    float ss = sign(d);
    const int num = 512;
    for( int i=0; i<num; i++ )
    {
        float an = 6.283185*float(i)/float(num);
        vec2 cs = vec2(cos(an),sin(an));
        if( map( p+cs*d*0.99, blend_width, tile ).x*ss<0.0 )
        {
            return true;
        }
    }
    return false;
}
    
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    bool interact = iMouse.z>0.001;
    
    // 4x2 tiling of space
    vec2 res = vec2(iResolution.x/4.0,iResolution.y/2.0);
    vec2 fpid = floor(fragCoord/res);
    vec2 fmid = floor(iMouse.xy/res);
    vec2 px = fragCoord - fpid*res;
    vec2 mx = iMouse.xy - fmid*res;
    int  tile = (1-int(fpid.y))*4 + int(fpid.x);

    // blend thickness
    float blend_width = 0.2;
    
    // normalized pixel coordinates
    vec2 p = (2.0*px-res)/res.y;
    vec2 m = (2.0*mx-res)/res.y;
    
    // distance
    vec3 d = map( p, blend_width, tile );
   
    // coloring
    vec3 col = (d.x>0.0) ? vec3(0.9,0.6,0.3) : vec3(0.6,1.0,1.3)/1.3;
    if( interact && d.x < d.y ) col -= 0.1;
    if( !interact && d.y < 0.0 ) col.y += 0.2;
    if( interact && isNotLowerBound(p,d.x, blend_width, tile) ) 
    col = vec3(1.0,0.0,0.5);
    col *= 1.0 - exp2(-16.0*abs(d.x));
    col *= 0.75 + 0.25*smoothstep(-0.5,0.5,cos( ((d.x>0.0)?100.0:200.0)*d.x));
    if( !interact )
    col = mix( col, vec3(0.8), 1.0-smoothstep(0.002*res.y, 0.005*res.y, abs(d.y)/fwidth(d.y)) );
    col = mix( col, vec3(1.0), 1.0-smoothstep(0.002*res.y, 0.005*res.y, abs(d.x)/fwidth(d.x)) );

    // interactivity
    if( interact )
    {
        float md = map( m, blend_width, tile ).x;
        col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.0, 0.005, abs(length(p-m)-abs(md))-0.005));
        col = mix(col, vec3(1.0,1.0,0.0), 1.0-smoothstep(0.0, 0.005, length(p-m)-0.015));
    }

    // draw voronoi regions
    if( false )
    {
        col = mix( col, vec3(1,1,0), 1.0-smoothstep( 0.008, 0.012, abs(d.z)) );
    }

    // draw bounding box expansion isoline
    if( !interact )
    {
        float bd = d.y - blend_width;
        col = mix(col, vec3(0.0,1.0,1.0), 1.0-smoothstep(0.005, 0.010,abs(bd)) );
    }

    // draw text
    {
        const float text_scale = 0.15;
        vec2 q = (p-vec2(-0.85,-0.95))/text_scale;
        float text = 1e20;
             if( tile==0 ){text = print(text,q,int[](81,117, 97,100,114,97,116,105,99,0,0,0));}
        else if( tile==1 ){text = print(text,q,int[](67,117, 98,105,99,0,0,0,0,0,0,0));}
        else if( tile==2 ){text = print(text,q,int[](81,117, 97,114,116,105,99,0,0,0,0,0));}
        else if( tile==3 ){text = print(text,q,int[](67,105,114,99,117,108,97,114,0,0,0,0));}
        else if( tile==4 ){text = print(text,q,int[](69,120,112,111,110,101,110,116,105,97,108,0));}
        else if( tile==5 ){text = print(text,q,int[](83,105,103,109,111,105,100,0,0,0,0,0));}
        else if( tile==6 ){text = print(text,q,int[](83,113,117,97,114,101,32,114,111,111,116,0));}
        else if( tile==7 ){text = print(text,q,int[](67,105,114,99,117,108,97,114,32,0,0,0));
                           text = print(text,q,int[](71,101,111,109,101,116,114,105,99,97,108,0));}
        col = mix(col,vec3(0.0),1.0-smoothstep( 0.06,0.08,text-0.5));
        col = mix(col,vec3(1.0),1.0-smoothstep(-0.01,0.01,text-0.5));
    }
 
    // draw grid
    vec2 grid = smoothstep( 0.005, 0.010, abs(px)/res.y );
    col *= min(grid.x,grid.y);

	fragColor = vec4(col, 1.0);
}