// Image (image) — galaxy spirals: ellipmod +Perlin by FabriceNeyret2
// https://www.shadertoy.com/view/Ms3czX

// variant of https://shadertoy.com/view/4dcyzX

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define SQR(v) ( (v) * (v) )

float MUL = 1.,    // multiplicative vs additive Perlin
      TEX = 0.;    // unsigned, signed, abs, 1-abs

vec4 t( vec2 U ) { // --- apply chosen turbulence function
    vec4 T = texture(iChannel0,U); // note that this is value noise, so not true Perlin
         if (TEX==0.) return              T ;
    else if (TEX==1.) return          2.* T -1. ;
    else if (TEX==2.) return     abs( 2.* T -1. );
    else              return 1.- abs( 2.* T -1. );
}

vec4 T(vec2 U) {   // --- apply either multiplicative or additive cascade
    U /= 16.;
    if (MUL==1.) return   t(U) * t(2.*U)*2. * t(4.*U)*2. * t(8.*U)*2. ;
    else         return ( t(U) + t(2.*U)/2. + t(4.*U)/4. + t(8.*U)/8. ) / 2. ;
}

void mainImage( out vec4 O, vec2 U )
{
    vec4 K = texelFetch(iChannel3,ivec2(0),0); // keyboard commands
    TEX = K.x; MUL = K.y;

    vec2 R = iResolution.xy;
    U =  1.2* (U+U-R)/R.y;
    O *= 0.;
    
    vec2  r = vec2(.5,.3);              // base ellipse aspect ration
    float a = -3.14/2.,                 // ellipse angle tilt per scaling length
          va, d, l = 1.,                // scaling length
          e = (iMouse.z<=0.) ? .3 : .1; // thickness of each ellipse
    
    for (float l = .1,n=1.; l<3.; l+= .1,n++) 
    {   
     // r = .5*vec2( 1., .6+.4* (l/3.) );     // morphing to circle outside
        vec2 V = 1./vec2(r) * ( rot(a+a*l)* U ) ;
        d = dot (V, V ); // quadratic form of the ellipsoid U.R⁻¹.(1/d²).R.U = l²
        va = iTime*(1.5/l-0.);                // in galaxies, tangential velocity is constant !
        vec4 C = T( rot(va+n) * .5*V/l );     // noise in ellipse frame
        O += smoothstep(e,0.,abs(sqrt(d)-l) ) // ellipse shape
            * C / l;                          // noise + fading
    }  
    
    if (TEX==1.) O = .5+.5*O;                 // signed -> displayable
    
    O = O.rrrr;
         if (TEX == 1.) O = 1.-O;
    else if (MUL == 0.) O = exp(-O/2.);
    else                O = exp(-O/8.);     
}


