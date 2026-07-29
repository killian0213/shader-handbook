// Image (image) — Multistep Fluid Simulation by trirop
// https://www.shadertoy.com/view/MdSczK

// Created by Robert Schuetze - trirop/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// To my knowledge, this is the first adequate divergence-free FDM Navier-Stokes
// fluid simulation on shadertoy (calculated with Jacobi method).
// My multistep-technique with precomputed coefficients (Buf C) allows me to make tens of
// diffusion-steps per frame to better satisfy the incompressible Navier-Strokes-Equation.
// The method has two major flaws:
//    - The computation time increases quadratically with the step count
//    - The pressure is bleeding through thin obstacles

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;
    vec2 uv = (C-r*0.5)/r.y;
    vec2 m = (iMouse.xy-r*0.5)/r.y;
    if(length(iMouse)<0.01){
        m = vec2(-0.5,0.);
    }
    if(length(uv-m)<0.02){
    	fragColor =  vec4(0.3,0.5,0.7,1);
    }else{
    	fragColor = vec4(texture(iChannel0,C/r).z);
    }
}