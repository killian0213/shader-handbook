// Image (image) — Interactive Fluid Simulation by wyatt
// https://www.shadertoy.com/view/XtGcDK

// see buffer A to learn how it works, this just makes it pretty

vec4 t (vec2 v) {return texture(iChannel0,v/iResolution.xy);}
void mainImage( out vec4 C, in vec2 U )
{
    vec4 me = t(U);
    me.z-=1.;
    
    C = 1.-3.*me.wwww;
    vec3 d = vec3(t(U+vec2(1,0)).w-t(U-vec2(1,0)).w,t(U+vec2(0,1)).w-t(U-vec2(0,1)).w ,2.);
    
    C.xyz -= max(vec3(0),sin(vec3(100.*length(me.xy),-5.*me.z,368.*d.y)*me.w));
    
}