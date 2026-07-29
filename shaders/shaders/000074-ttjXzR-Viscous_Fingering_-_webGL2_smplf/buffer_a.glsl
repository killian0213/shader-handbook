// Buffer A (buffer) — Viscous Fingering - webGL2 smplf by FabriceNeyret2
// https://www.shadertoy.com/view/ttjXzR

float _K0 = -20./6., // center weight
      _K1 =   4./6., // edge-neighbors
      _K2 =   1./6., // vertex-neighbors
       cs =  .25,    // curl scale
       ls =  .24,    // laplacian scale
       ps = -.06,    // laplacian of divergence scale
       ds = -.08,    // divergence scale
      pwr =  .2,     // power when deriving rotation angle from curl
      amp = 1.,      // self-amplification
      sq2 =  .7;     // diagonal weight

void mainImage( out vec4 O, vec2 U )
{
    // 3x3 neighborhood coordinates
    vec4 uv = T( ),
          n = T(vec2( 0,  1 )),
          e = T(vec2( 1,  0 )),
          s = T(vec2( 0, -1 )),
          w = T(vec2(-1,  0 )),
         nw = T(vec2(-1,  1 )),
         sw = T(vec2(-1     )),
         ne = T(vec2( 1     )),
         se = T(vec2( 1, -1 ));
    
    // uv.x and uv.y are our x and y components, uv.z is divergence 

    // laplacian of all components
    vec4 lapl  = _K0*uv + _K1*(n + e + w + s) 
                        + _K2*(nw + sw + ne + se);
    float sp = ps * lapl.z;
    
    // calculate curl
    // vectors point clockwise about the center point
    float curl = n.x - s.x - e.y + w.y 
        + sq2 * (nw.x + nw.y + ne.x - ne.y + sw.y - sw.x - se.y - se.x);
    
    // compute angle of rotation from curl
    float a = cs * sign(curl) * pow(abs(curl), pwr);
    
    // calculate divergence
    // vectors point inwards towards the center point
    float div  = s.y - n.y - e.x + w.x 
        + sq2 * (nw.x - nw.y - ne.x - ne.y + sw.x + sw.y + se.y - se.x);
    float sd = ds * div;

    vec2 norm = normalize(uv.xy);
    
    // temp values for the update rule
     vec2 t = (amp * uv + ls * lapl + uv * sd).xy + norm * sp;
    t *= mat2(cos(a), -sin(a), sin(a), cos(a) );
    if(iFrame<10)
        O = -.5 + texture(iChannel1, U/R), O.a=0.;
     else 
        O = clamp(vec4(t,div,0), -1., 1.);
}