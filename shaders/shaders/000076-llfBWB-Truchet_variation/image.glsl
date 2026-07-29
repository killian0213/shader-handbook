// Image (image) — Truchet variation by XT95
// https://www.shadertoy.com/view/llfBWB

// ---------------------------------------------------------------------------------------
//	Created by anatole duprat - XT95/2017
//	License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
//  Truchet variation with Mondrian color style 
//  Idea by Samuel Monnier : http://algorithmic-worlds.net
//
//  Looks better in fullscreen !
//
// ---------------------------------------------------------------------------------------



// we need 3 cells to do this effect
const vec2 dir[3] = vec2[]( vec2(0.,0.), vec2(1.,0.), vec2(0.,1.)); 

// color palette
const vec3 palette[7] = vec3[]( vec3(.8,0.,0.), vec3(0.,.4,1.), vec3(1.,1.,1.),
        					  vec3(1.,.8,0.), vec3(1.,.9,.9), vec3(.7,.8,1.),
        					  vec3(1.,.9,.8) );


void Mondrian( vec2 uv, float res, inout vec4 col, inout int currentPalette )
{
    uv *= res;
	float lw = max(0.001*res,0.02); // line width
    
    
    // cell tiling
    vec2 iuv = floor(uv);
    vec2 fuv = fract(uv);

	// random number for each cell
    vec2 v[3];
    for(int i=0; i<3; i++)
        v[i] = (texture(iChannel0, (iuv+dir[i])/256.).rg)*(1.-exp(-iTime));
    
    
    // draw segments in the four directions
    float l = 1.;
    l = min(l, abs(fuv.y-v[0].y) + step( max(v[2].x,v[0].x)+lw, fuv.x ) );
    l = min(l, abs(fuv.y-v[1].y) + step( fuv.x+lw, min(v[2].x,v[0].x) ) );
    l = min(l, abs(fuv.x-v[0].x) + step( max(v[1].y, v[0].y), fuv.y ) );
    l = min(l, abs(fuv.x-v[2].x) + step( fuv.y, min(v[1].y,v[0].y) ) );
    
    
    // get random color if we are in the box of the four segments
    if( step( fuv.x, max(v[2].x,v[0].x) ) * step( min(v[2].x,v[0].x), fuv.x ) *
        step( fuv.y, max(v[1].y,v[0].y) ) * step( min(v[1].y,v[0].y), fuv.y )  > .1 )
    {
        
        currentPalette = int( mod(v[0].y*42.+float(currentPalette), 7.) );
        col.rgb = palette[currentPalette];
    }
    
    // line are done in a separate channel to simplify the blending
    col.a *= step(lw, l);
}


// classic hash function for jittering
vec2 hash2( float n ) { return fract(sin(vec2(n,n+1.0))*vec2(43758.5453123,22578.1459123)); }


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    const int nbSample = 12;
    vec3 c = vec3(0.);
    
    
    for(int s=0; s<nbSample; s++)
    {
    	vec2 uv = (-iResolution.xy + 2.0*(fragCoord+(hash2( float(s) )-0.5)))/ iResolution.y;
    
    	int currentPalette = 2;
    	vec4 col = vec4(1.);
        for(int i=0; i<5; i++)
        {
            vec2 p = uv + vec2(i) + vec2(3.5,4.8);
            float res = float(i*i)*2.+1.;
       		Mondrian(p, res, col, currentPalette);
        }
        
		c += col.rgb*col.a;
    }
    
    c /= float(nbSample);
	fragColor = vec4(c, 1.0);
}