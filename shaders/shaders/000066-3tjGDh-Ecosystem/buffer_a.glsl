// Buffer A (buffer) — Ecosystem by wyatt
// https://www.shadertoy.com/view/3tjGDh

// FLUID DYNAMICS
// FORCE on FLUID = (PARTICLE)*(GRADIENT OF BUFFER D)

#define R iResolution.xy
#define A(U) texture(iChannel0, (U)/R)
#define B(U) texture(iChannel1, (U)/R)
vec4 T (vec2 U) {return A(U-A(U).xy);}
void mainImage( out vec4 Q, in vec2 U)
{
    Q = T(U);
    vec4 // neighborhood
        n = T(U+vec2(0,1)),
        e = T(U+vec2(1,0)),
        s = T(U-vec2(0,1)),
        w = T(U-vec2(1,0));
   // FLUID DYNAMICS
   Q.x -= (0.25*(e.z-w.z-Q.w*(n.w-s.w)));
   Q.y -= (0.25*(n.z-s.z-Q.w*(e.w-w.w)));
   Q.z += (0.25*((s.y-n.y+w.x-e.x)+(n.z+e.z+s.z+w.z))-Q.z);
   Q.w += (0.25*(s.x-n.x+w.y-e.y)-Q.w);
   Q.xy *= 0.995;
   // COMPUTE HORMONE FEILD
   n = C(U+vec2(0,1));
   e = C(U+vec2(1,0));
   s = C(U-vec2(0,1));
   w = C(U-vec2(1,0));
   // THIS PARTICLE
   vec4 b = B(U);
   // COMPUTE HORMONE SIGNATURE
   vec4 h = hash(b.w);
   // SUM HORMONE FORCE
   vec2 v = vec2(0);
   v += h.x*vec2(e.x-w.x,n.x-s.x);
   v += h.y*vec2(e.y-w.y,n.y-s.y);
   v += h.z*vec2(e.z-w.z,n.z-s.z);
   v += h.w*vec2(e.w-w.w,n.w-s.w);
   // APPLY HORMONE FORCE TO THIS PARTICLE
   Q.xy += v*smoothstep(1.,0.,length(U-b.xy));
   // BOUNDARY CONDITIONS
   if (U.x<1.||U.y<1.||R.x-U.x<1.||R.y-U.y<1.||iFrame<1)
       Q.xyw = vec3(0);
   
}