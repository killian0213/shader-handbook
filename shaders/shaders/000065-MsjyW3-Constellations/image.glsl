// Image (image) — Constellations by anomes
// https://www.shadertoy.com/view/MsjyW3

// -----------------------------------------
// RENDER POINTS, CONNECTIONS AND BACKGROUND
// -----------------------------------------


// must be the same as in 'Buf A'
#define POINTS_SIZE 12
#define POINTS_NUMBER POINTS_SIZE*POINTS_SIZE

//
#define BLOCK_SIZE 10
#define BLOCK_NUMBER BLOCK_SIZE*BLOCK_SIZE

// improve quality but also calculations
#define SELECTION_SIZE 20

#define ZOOM min(2.  ,  1.+0.*iMouse.y/iResolution.y  )
#define POINT_RADIUS 0.025*ZOOM
#define CONNECTION_DISTANCE 0.2*ZOOM
#define GLOW 4.
#define GLOW_INTENSITY 0.15



// #########################



vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

//
// Description : GLSL 2D simplex noise function
//      Author : Ian McEwan, Ashima Arts
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : 
//  Copyright (C) 2011 Ashima Arts. All rights reserved.
//  Distributed under the MIT License. See LICENSE file.
//  https://github.com/ashima/webgl-noise
// 
float snoise(vec2 v) {

    // Precompute values for skewed triangular grid
    const vec4 C = vec4(0.211324865405187,
                        // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  
                        // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  
                        // -1.0 + 2.0 * C.x
                        0.024390243902439); 
                        // 1.0 / 41.0

    // First corner (x0)
    vec2 i  = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);

    // Other two corners (x1, x2)
    vec2 i1 = vec2(0.0);
    i1 = (x0.x > x0.y)? vec2(1.0, 0.0):vec2(0.0, 1.0);
    vec2 x1 = x0.xy + C.xx - i1;
    vec2 x2 = x0.xy + C.zz;

    // Do some permutations to avoid
    // truncation effects in permutation
    i = mod289(i);
    vec3 p = permute(
            permute( i.y + vec3(0.0, i1.y, 1.0))
                + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(
                        dot(x0,x0), 
                        dot(x1,x1), 
                        dot(x2,x2)
                        ), 0.0);

    m = m*m ;
    m = m*m ;

    // Gradients: 
    //  41 pts uniformly over a line, mapped onto a diamond
    //  The ring size 17*17 = 289 is close to a multiple 
    //      of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt(a0*a0 + h*h);
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0+h*h);

    // Compute final noise value at P
    vec3 g = vec3(0.0);
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * vec2(x1.x,x2.x) + h.yz * vec2(x1.y,x2.y);
    return 130.0 * dot(m, g);
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}

int blockIndexForPosition(vec2 pos)
{
	vec2 p2 = vec2(  (pos.x*iResolution.y/iResolution.x+1.)/2.  ,  (pos.y+1.)/2.  );
    float size = 1./float(BLOCK_SIZE);
    return int(p2.x/size) + int(p2.y/size)*BLOCK_SIZE;
}

vec4 pointAtIndex(int index, int blockIndex)
{
    vec2 pos = vec2(  float(index)+0.5  ,  float(blockIndex)+0.5  )  /  iResolution.xy;
    return texture(iChannel1, pos);
}

vec3 colorForIndex(int index)
{
    index = index%12;
    if( index == 0 )
    {
         return vec3(1., 0., 0.);
    }
    else if( index == 1 )
    {
         return vec3(0., 1., 0.);
    }
    else if( index == 2 )
    {
         return vec3(0., 0., 1.);
    }
    else if( index == 3 )
    {
         return vec3(1., 1., 0.);
    }
    else if( index == 4 )
    {
         return vec3(0., 1., 1.);
    }
    else if( index == 5 )
    {
         return vec3(1., 0., 1.);
    }
    else if( index == 6 )
    {
         return vec3(1., 1., 1.);
    }
    else if( index == 7 )
    {
         return vec3(1., 0.5, 0.5);
    }
    else if( index == 8 )
    {
         return vec3(0.5, 1., 0.5);
    }
    else if( index == 9 )
    {
         return vec3(1., 0.5, 0.);
    }
    else if( index == 10 )
    {
         return vec3(0., 0.5, 1.);
    }
    else
    {
         return vec3(0.5, 0.5, 1.);
    }
}





void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if( false )
    {
    	vec2 pos = fragCoord/iResolution.xy;
    	fragColor = texture(iChannel1, pos);
    	return;
    }
	vec2 p = (2.0*fragCoord.xy-iResolution.xy)/iResolution.y;
    vec2 p2 = vec2(  (p.x*iResolution.y/iResolution.x+1.)/2.  ,  (p.y+1.)/2.  );
    int blockIndex = blockIndexForPosition(p);
    
    // selection
    int k = 0;
    vec2 selectionPoints[SELECTION_SIZE];
    float selectionLengths[SELECTION_SIZE];
    float selectionBlurs[SELECTION_SIZE];
    vec3 selectionTints[SELECTION_SIZE];
    for(int i=0; i<POINTS_NUMBER && k<SELECTION_SIZE; i++)
    {
        vec4 a = pointAtIndex(i, blockIndex);
        if( a.w < 0. )
        {
            break;
        }
		vec2 pa = p - a.xy;
        float d = length(pa);
        if( d < CONNECTION_DISTANCE )
        {
            selectionPoints[k] = a.xy;
            selectionLengths[k] = d;
            selectionBlurs[k] = abs(a.z);
            /*if( a.w < 0.34 )
            {
            	selectionTints[k] = vec3(0.8, 0.9, 1.); // blue
            }
            else if( a.w < 0.67 )
            {
            	selectionTints[k] = vec3(1., 1., 1.); // white
            }
            else
            {
            	selectionTints[k] = vec3(0.9, .9, .9); // gray
            }*/
            k++;
        }
    }
    
    
    // connections
    float h = 2.0/iResolution.y;
    float col = 0.0;
    float glow = 0.0;
    for(int i=0; i<k; i++)
    {
        vec2 a = selectionPoints[i];
        for(int j=0; j<k; j++)
        {
            vec2 b = selectionPoints[j];
            if( a == b )
            {
                continue;
            }
            vec2 ba = b - a;
            float d = length(ba);
            d = smoothstep(CONNECTION_DISTANCE, CONNECTION_DISTANCE-0.1, d);
    		float blur = (selectionBlurs[i]+selectionBlurs[j])/2.;
            float sd = sdSegment(p,a,b);
            col = max(  col  ,  d*(1.0-smoothstep(h/2.,max(blur*2.,1.)*h,sd)) 
                     	/ max(blur*1.5 , 1.)
                     );
            glow = max( glow,  (d*(1.0-smoothstep(0.,3.*GLOW*h,sd)) / max(blur*1.5 , 1.) )*GLOW_INTENSITY );
        }
    }
    col = min(col+glow, 1.0);
    
    // points
    vec3 tint = vec3(0.8, 0.9, 1.);
    if( 0. < iMouse.z )
    {
    	tint = colorForIndex(blockIndex);
    }
    for(int i=0; i<k; i++)
    {
        float d = selectionLengths[i];
        float value = (1.0-smoothstep(0.,POINT_RADIUS*max(selectionBlurs[i]/2.,1.)/3.,d))
                 	/ max(selectionBlurs[i]/1.5 , 1.);
        value += (  1.0-smoothstep(0.,GLOW*POINT_RADIUS*max(selectionBlurs[i]/2.,1.)/3.,d)  )*GLOW_INTENSITY;
        col = max(  col  ,  value  );
        //tint = mix(tint, selectionTints[i], col);
    }
 
    // background
    vec2 vel = vec2(iTime*.1);
    float background = snoise(2.*fragCoord.xy/iResolution.y+vel)*.25+.25;
    float a = snoise(2.*fragCoord.xy/iResolution.y*vec2(cos(iTime*.08),sin(iTime*0.1))*0.1)*3.1415;
    vel = vec2(cos(a),sin(a));
    background += snoise(2.*fragCoord.xy/iResolution.y+vel)*.25+.25;
    background *= 0.33*fragCoord.y/iResolution.y;
    col += background;
    if( 0. < iMouse.z )
    {
    	col += 0.25;
    }
    
	fragColor = vec4( col*tint.r, col*tint.g, col*tint.b, 1.0 );
}