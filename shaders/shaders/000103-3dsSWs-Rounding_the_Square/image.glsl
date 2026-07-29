// Image (image) — Rounding the Square by iq
// https://www.shadertoy.com/view/3dsSWs

// Created by inigo quilez - iq/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.


// Converting the unit square into the unit circle. Normalize
// vertices to get rings, and make the radius of the ring
// map to the manhattan distance (square rings).


float maxcomp( in vec2 v ) { return max(v.x,v.y); }

// Map the unit square [-1,1]^2 to the unit disk
vec2 square2disk( in vec2 v )
{
    return maxcomp(abs(v))*normalize(v);
}

// Map the unit dist to the unit square [-1,1]^2
vec2 disk2square( vec2 v )
{
    return v*length(v)/maxcomp(abs(v));
}

//-----------------------------------------------


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // plane coords
    vec2 p = (2.0*fragCoord-iResolution.xy)/iResolution.y;
    float w = 2.0/iResolution.y;
    
    // scale
	p *= 1.15;
	w *= 1.15;
 
    // animation
    float anim = smoothstep(-0.6,0.6,cos(iTime*2.0+0.0));
    float show = smoothstep(-0.1,0.1,sin(iTime*1.0+3.4));
    
    // background
    vec3 col = vec3(1.0);

    // texture
    vec2 uv = 0.5 + 0.5*mix(p,disk2square(p),1.0-anim);
    if( maxcomp(abs(uv-0.5))<0.5 )
    {
        // pattern
        vec2 id = floor(uv*11.0);
        float f = 0.75 + 0.15*mod(id.x+id.y,2.0);
        col = vec3(f,f,f);
        col = mix( col, pow(texture(iChannel0,uv).xyz,vec3(0.75)), show );

        // grid
        vec2 q = fract( uv*11.0+11.0*0.5 )-0.5;
        float d = length(q)-0.1;
        d = min(d,abs(q.y)-0.02);
        d = min(d,abs(q.x)-0.02);
        col *= smoothstep(0.0,0.02,d);
    }
   
    // vignette
    col *= 1.0 - 0.15*length(p);

    // output
    fragColor = vec4(col,1.0);
}