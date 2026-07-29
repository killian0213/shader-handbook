// Buffer B (buffer) — Screen Bubbles by wyatt
// https://www.shadertoy.com/view/tsBSWh

#define R iResolution.xy
vec4 A (vec2 U) {return texture(iChannel0,U/R);}
vec4 B (vec2 U) {return texture(iChannel1,U/R);}
vec4 C (vec2 U) {return texture(iChannel2,U/R);}
vec4 D (vec2 U) {return texture(iChannel0,U/R);}
void swap (vec2 U, inout vec4 A, vec4 B) {if (length(U-B.xy)-B.z < length(U-A.xy)-A.z) A = B;}
void mainImage( out vec4 Q, in vec2 U )
{
    Q = B(U);
    
    swap(U,Q,B(U+vec2(0,1)));
    swap(U,Q,B(U+vec2(1,0)));
    swap(U,Q,B(U-vec2(0,1)));
    swap(U,Q,B(U-vec2(1,0)));
    swap(U,Q,B(U+vec2(2,2)));
    swap(U,Q,B(U+vec2(2,-2)));
    swap(U,Q,B(U-vec2(2,-2)));
    swap(U,Q,B(U-vec2(2,2)));
    
    Q.xyw += A(Q.xy).xyw*vec3(1,1,6.2);
    
    if (R.x-U.x < 1. && mod(float(iFrame) , 20.) == 1.) {
        float y = round((U.y+5.)/10.)*10.-5.;
        Q = vec4(
            R.x,y,
        0.5+0.5*sin(y+(y+.45)*mod(float(iFrame),1e3)),0.
       );
       Q.z = -1.5*log(1e-4+Q.z);
    }
    
    
   if (iFrame < 1) {
       Q = vec4(0);
   }
}