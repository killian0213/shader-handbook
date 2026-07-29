// Image (image) — Smoke remake by Ultraviolet
// https://www.shadertoy.com/view/4lScRG

// Created by Robert Schuetze - trirop/2017
// Modified by Ulysse Vimont - Ultraviolet/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Note: Buffers are used for the following purposes:
//  - Buf A performs advection (U*, C)
//  - Buf B computes the divergence of the velocity field ( D = ∇.U*)
//  - Buf C solves the Poisson equation ( ∇²P = ∇.U* )
//  - Buf D substracts the pressure gradient ( U = U* - ∇.P )
// The main image computes a visualisation of the data:
//  - the default view is a fake-3D visu of the concentration field
//  - press CTRL for switching to regular concentration visu
//  - press SPACE for visualising the velocity field
//  - press CTRL (after SPACE) for visualizing the pressure field (in fake 3D)

// from iq at https://www.shadertoy.com/view/MsS3Wc
// Smooth HSV to RGB conversion 
vec3 hsv2rgb_smooth( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;
    vec2 uv = (C-r*0.5)/r.y;
    vec2 m = (iMouse.xy-r*0.5)/r.y;
    if(length(iMouse)<0.01){
        m = vec2(-0.5,0.);
    }
    
    float concentration = texture(iChannel0,C/r).z;
    float pressure = texture(iChannel3,C/r).x;
    float amplitude = length(texture(iChannel0,C/r).xy);
    float phase = atan(texture(iChannel0,C/r).y,texture(iChannel0,C/r).x)/2./3.1415972;
    
    vec3 col;
    
    if(texelFetch( iChannel2, ivec2(32,2), 0 ).x<0.5) {
        
        if(texelFetch( iChannel2, ivec2(17,2), 0 ).x>0.5) {
            
            //----------------------------
            // visualize concentration
        	col = vec3(concentration);
        }
        else {
            
            //----------------------------
            // visualize concentration (shaded)
            float pl = texture(iChannel0,(C-vec2(-1, 0))/r).z;
            float pr = texture(iChannel0,(C-vec2( 1, 0))/r).z;
            float pt = texture(iChannel0,(C-vec2( 0,-1))/r).z;
            float pb = texture(iChannel0,(C-vec2( 0, 1))/r).z;
            vec2 grad = vec2(pr-pl,pb-pt);
            //grad = vec2(dFdx(concentration), dFdy(concentration));
        	col = clamp(concentration, 0.0, 1.0)*vec3(0.2+0.8*max(dot(normalize(vec3(0.0, 1.0, 1.0)), normalize(vec3(grad.x, .05, grad.y))), 0.0));
        }
    }
    else {
        
        if(texelFetch( iChannel2, ivec2(17,2), 0 ).x>0.5) {
            
            //----------------------------
            // visualize pressure
            //col = 0.1*vec3(pressure,-pressure, 0.0);
            
            float pl = texture(iChannel3,(C-vec2(-1, 0))/r).x;
            float pr = texture(iChannel3,(C-vec2( 1, 0))/r).x;
            float pt = texture(iChannel3,(C-vec2( 0,-1))/r).x;
            float pb = texture(iChannel3,(C-vec2( 0, 1))/r).x;
            vec2 grad = vec2(pr-pl,pb-pt);
            //grad = vec2(dFdx(pressure), dFdy(pressure));
            col = vec3(0.2+0.8*max(dot(normalize(vec3(0.0, 1.0, 1.0)), normalize(vec3(grad.x, .4, grad.y))), 0.0));
        }
        else {
            
            
            //----------------------------
            // visualize speed
        	col = hsv2rgb_smooth(vec3(phase, 0.5, 1.0-exp(-amplitude)));
        }
    }
    
    fragColor = vec4(col, 1.0);
}