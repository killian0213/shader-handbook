// Image (image) — perlin + advection + flownoise 2 by FabriceNeyret2
// https://www.shadertoy.com/view/MltGzM

// variant of advection of procedural flownoise https://www.shadertoy.com/view/lltGRN
// with smart blendind of multiple splats https://www.shadertoy.com/view/4dcSDr

#define FLOWNOISE 1  // 0: regular Perlin   1: flownoise
#define MODE 1       // 0: bozo   1: fire   2: cloud
#define DISP 0       // 0: noise = value    1: noise = displacement (better with bozo)  
#define SCALE 1.     // noise wavelength
#define ROT  1       // 1: center fastest   2: center slowest  
#define radius .3    // radius of the vortices orbit
#define MORPH 1      // 1: advection 0: final blend (fire only)

// --- texture advection: 
// from https://www.shadertoy.com/view/XsdXWn
// cf https://hal.inria.fr/inria-00537472  ( also exist in Lagrangian form )
// here, we only do the simple 3-phase version, each fading-in/out before too much distortion.

// --- flow noise:  
// from https://www.shadertoy.com/view/MstXWn
// cf publi http://evasion.imag.fr/~Fabrice.Neyret/flownoise/index.gb.html
//          http://mrl.nyu.edu/~perlin/flownoise-talk/
// The raw principle is trivial: rotate the gradients in Perlin noise.
// Complication: checkboard-signed direction, hierarchical rotation speed (many possibilities).
// Not implemented here: pseudo-advection of one scale by the other.

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define CS(a)  vec2(cos(a),sin(a))

// --- Perlin noise by inigo quilez - iq/2013   https://www.shadertoy.com/view/XdXGW8
vec2 hash( vec2 p )
{
	p = vec2( dot(p,vec2(127.1,311.7)),
			  dot(p,vec2(269.5,183.3)) );

	return -1. + 2.*fract(sin(p)*43758.5453123);
}

// noise with flownoise extension (rotation of gradients)
float level=1.;
float noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*(3.-2.*f);
#if FLOWNOISE
    float t = exp2(level)* .4*iTime;
    mat2  R = rot(t);
#else
    mat2  R = mat2(1,0,0,1);
#endif
    if (mod(i.x+i.y,2.)==0.) R=-R;

    return 2.*mix( mix( dot( hash( i + vec2(0,0) ), (f - vec2(0,0))*R ), 
                        dot( hash( i + vec2(1,0) ),-(f - vec2(1,0))*R ), u.x),
                   mix( dot( hash( i + vec2(0,1) ),-(f - vec2(0,1))*R ), 
                        dot( hash( i + vec2(1,1) ), (f - vec2(1,1))*R ), u.x), u.y);
}

// --- turbulence: non-advected version ( for reference )

float Mnoise( vec2 uv ) {
#  if MODE==0
    return noise(uv);                      // base turbulence
#elif MODE==1
    return -1. + 2.* (1.-abs(noise(uv)));  // flame like
#elif MODE==2
    return -1. + 2.* (abs(noise(uv)));     // cloud like
#endif
}

mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

float turb( vec2 uv )
{ 	float f;
	
 level=1.;
    f  = 0.5000*Mnoise( uv ); uv = m*uv; level++;
	f += 0.2500*Mnoise( uv ); uv = m*uv; level++;
	f += 0.1250*Mnoise( uv ); uv = m*uv; level++;
	f += 0.0625*Mnoise( uv ); uv = m*uv; level++;
	return f/.9375; 
}

// --- turbulence: advected version 

vec4 early_turb( vec2 uv ) // sample a multiscale vector of linear noise to be interpolated
{
    vec4 N;
    level = 1.;
    N[0] = noise(uv); uv = m*uv; level++;
    N[1] = noise(uv); uv = m*uv; level++;
    N[2] = noise(uv); uv = m*uv; level++;
    N[3] = noise(uv); uv = m*uv; level++;
    return N;
}

vec4 Mnoise( vec4 N ) {   // apply non-linearity 1 (per scale) after blending
#  if MODE==0
    return N;                      // base turbulence
#elif MODE==1
    return -1. + 2.* (1.-abs(N));  // flame like
#elif MODE==2
    return -1. + 2.* (abs(N));     // cloud like
#endif
}
    
float deferred_turb( vec4 N ) // apply cascade + optional non-linearity 2 (LUT) after blending
{
    N = Mnoise(N);   
    float f;	
    f  = 0.5000*N[0]; 
	f += 0.2500*N[1];
	f += 0.1250*N[2];
	f += 0.0625*N[3];
	return f/.9375;     
}


// --- custom texture fetch
//#define T(u)  texture(iChannel0, u )     // fetch noise texture
  #define T(u)    early_turb((u)*3./(SCALE)) // fetch flownoise


void mainImage( out vec4 O, in vec2 U )
{
    float t = mod(iTime,6.283)*(MODE==1 ? 2. : 1.), Kt=0.;
	vec2  R = iResolution.xy,
         uv = (U -.5*R ) / R.y, uvl,Pl,
          m = (iMouse.xy -.5*R ) / R.y; if (length(iMouse.xy/R)<.01) m = vec2(0);
    
    O*=0.;
    
    // --- smart blending of splats --------------------------------------
  for (float k=-1.; k<3.; k++) {   // 4 layers: background (k=-1) + 3 vortices
    float l,K,v;
    if (k<0.) { uvl = uv; Pl=vec2(0); K=.3; v=0.;}// k=-1: background motion
    else {                                        // 3 vortices
       Pl  = radius*CS(2.1*k - .5*iTime),   // splat center
       uvl = uv-Pl;                               // local coords in the splat
       l = length(uvl),
       K = exp(-.5*l*l/radius/radius),            // kernel of the splat
   //  K = smoothstep(1.,0.,.7*l/radius),
#if ROT==1
       v = 3./(.01+l);                            // rotation(r) within the splat
#else        
       v = 30.*l;
#endif
    }
      Kt += K*K;
       // --- 3-phased advection --------------------------------------
      for (float i=0.; i<3.; i++) {       // the 3 phases per layer for advection illusion
        float ti = t+ 6.283/3.*i,
              wi = K* (.5-.5*cos(ti))/1.5;

        vec2 uvi = uvl*rot(.3*(-.5+fract(ti/6.283))*v); // NB: we should add an offset per splat
        //if (i>0.) break; else wi=K;  // uncomment to show smearing if naive advection
        //if (i>0.) break;             // uncomment to show advection trick with 1 layer
        if (uv.x < m.x)                // left: result
#if MORPH
            O += T (.5 + uvi )  * wi;
#else
            O += wi * vec4(1,.6,.3,0)* 2.* pow(max(0.,deferred_turb(T (.5 + uvi ))), 2.);
#endif          
	    else                           // right: grid showing the trick
            O[int(i)] += texture(iChannel1, .5 + uvi ).x  * wi;  // show each phase in colors
    }
  }
  O /= sqrt(Kt); // normalisation by the cumulated std-dev, for constant contrast
    
    
// --- only with procedural advection: deferred noise.    
    if (uv.x < m.x && MORPH==1) // rendered side
#if DISP
        uv.x += .9*deferred_turb(O),
        O = .5+.5*vec4 (sin(30.*(uv.x-uv.y)) ); 
#else
#  if   MODE==0
        O = vec4(.5 + deferred_turb(O));
#  elif MODE==1
        O = vec4(1,.6,.3,0)* 2.* pow(max(0.,deferred_turb(O)), 2.); 
#  elif MODE==2
        O = mix(vec4(0,0,.3,1),vec4(2),.5 + .5*deferred_turb(O)); 
#  endif
#endif
}