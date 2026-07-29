// Buf A (buffer) — Multistep Fluid Simulation by trirop
// https://www.shadertoy.com/view/MdSczK

// Created by Robert Schuetze - trirop/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Runge-Kutta 4 backward advection

#define h 2.

vec2 RK4(vec2 p){
    vec2 r = iResolution.xy;
    vec2 k1 = texture(iChannel0,p/r).xy;
    vec2 k2 = texture(iChannel0,(p-0.5*h*k1)/r).xy;
    vec2 k3 = texture(iChannel0,(p-0.5*h*k2)/r).xy;
    vec2 k4 = texture(iChannel0,(p-h*k3)/r).xy;
    return h/3.*(0.5*k1+k2+k3+0.5*k4);
}

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;
    vec2 uv = ((C-r*0.5)/r.y);
    vec4 buf = texture(iChannel0,(C-RK4(C))/r); // advect
    vec2 v = buf.xy;
    float d = buf.z;
    
    // set boundary velocity
    if(C.x<2.||C.x>r.x-2.||r.y-2.<C.y||C.y<2.){
    	v = vec2(1,0);
    }
    
   	// set density
    if(0.<C.x&&C.x<2.){
        if(cos(uv.y*130.)>0.6){
        	d = 1.;
        }else{
    		d = 0.;    
        }
	}
    
    // mouse interaction
    vec2 m = (iMouse.xy-r*0.5)/r.y;
    if(length(iMouse)<0.01){
        m = vec2(-0.5,0.);
    }
    vec2 mv = m-vec2(texture(iChannel1,vec2(0.)).w,texture(iChannel1,vec2(r.x)).w); // mouse velocity
    if(iFrame<2){
        v.x = 1.;
        mv = vec2(0);
    }
    if(length(uv-m)<0.02){
    	v = 100.*mv;
        d = min(1.,length(mv)*100.);
    }
    float mxy = 0.;
    if(uv.x<0.){
    	mxy = m.x;
    }else{
    	mxy = m.y;
    }
    
    fragColor = vec4(v,d,mxy);
}