// Buf A (buffer) — Smoke remake by Ultraviolet
// https://www.shadertoy.com/view/4lScRG

// Created by Robert Schuetze - trirop/2017
// Modified by Ulysse Vimont - Ultraviolet/2017
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Runge-Kutta 4 backward advection

// Note: Components are attributed as follow:
//   - x : velocity field (X)
//   - y : velocity field (Y)
//   - z : concentration field
//   - w : mouse state (X for left part of screen, Y otherwise)
// The advection of the velocity field makes it non divergent-free, hence the next steps.

#define h 2.

vec2 RK4(vec2 p){
    vec2 r = iResolution.xy;
/*
    vec2 k1 = texture(iChannel0,p/r).xy;
    vec2 k2 = texture(iChannel0,(p-0.5*h*k1)/r).xy;
    vec2 k3 = texture(iChannel0,(p-0.5*h*k2)/r).xy;
    vec2 k4 = texture(iChannel0,(p-h*k3)/r).xy;
    return h/3.*(0.5*k1+k2+k3+0.5*k4);
/*/
    
    vec2 posInit = p;
    for(int i=0; i<10; i++)
    {
        p = posInit - h*texture(iChannel1,  p/r).xy;
    }
    
    return posInit-p;
 //*/
}

void mainImage( out vec4 fragColor, in vec2 C )
{
    vec2 r = iResolution.xy;
    vec2 uv = ((C-r*0.5)/r.y);
    
    // advection
    vec4 buf = texture(iChannel0,(C-RK4(C))/r);
    vec2 v = buf.xy;
    float d = buf.z;
    
    
    //*
    // set boundary velocity
    if(C.x<1.||C.x>r.x-1.){
    	v.x = .0;
    	v.y *= .5;
    }
    if(r.y-1.<C.y||C.y<1.){
    	v.y = .0;
    	v.x *= .5;
    }
	//*/
    
    /*
    if(length(C-r*.5)<r.x*.1){
    	v = vec2(.0);
    }
	*/

    
    // mouse interaction
    vec2 m = (iMouse.xy-r*0.5)/r.y;
    
    if(length(iMouse.xy) < 10.0)
        m = vec2(pow(abs(sin(iTime*1.)), 2.)-0.5, 0.2*sin(iTime*4.)+0.2);
    
    vec2 mv = m-vec2(texture(iChannel1,vec2(0., 1.0)).w,texture(iChannel1,vec2(1.0)).w); // mouse velocity
    if(iFrame<2){
        mv = vec2(0);
        d = 0.0;
    }
    if(texture(iChannel1,vec2(0., 0.49)).w<0.5)
        mv = vec2(0);
    if(length(uv-m)<0.02 && (iMouse.z > 0.5 || length(iMouse.xy) < 10.0)){
        
        float r = length(uv-m)/0.02;
        r = sqrt(1.0 - r*r);
        if(texelFetch( iChannel2, ivec2(83,0), 0 ).x<0.5)
        	d = texelFetch( iChannel2, ivec2(69,0), 0 ).x>0.5 ? d*(1.0-r) : d+r;
        else
            v += mv*100.0*r;
    }
    
    // mouse state backup
    float mxy = 0.;
    if(uv.x<0.){
        if(uv.y>0.){
            mxy = m.x;
        }else{
            mxy = iMouse.z;
            //mxy = m.x;
        }
    }else{
    	mxy = m.y;
    }
    
    fragColor = vec4(v,d,mxy);
}