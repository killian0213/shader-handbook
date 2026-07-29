// Buffer D (buffer) — FFT Fluid - analysis rory618 cod by FabriceNeyret2
// https://www.shadertoy.com/view/tdfSR4

// proceed 2nd step of block-FFTy
// and apply forces, viscosity, mass conservation, 
// See http://www.dgp.toronto.edu/people/stam/reality/Research/pdf/jgt01.pdf

void mainImage( out vec4 O, vec2 I )
{
    SUM( y, y_N0, y_N1, T( x, y*y_N1+i ) );  // --- block-FFTy
    
    O /= sqrt(R.x*R.y);
    
    
    vec2 C = mod(I+R.xy/2.,R.xy)-R.xy/2.;    // --- forces+conservation
    
    if(FFT_DIR==FORWARD){
        if (!keypressed(88))                 // X
            // apply viscosity 
        	O*=exp(-dot2( C )*viscosity);
        if( /* length(C)>0. && */ !keypressed(90) ){ // Z
            // mass conservation: reprojection on circle
            float lx = length(O.xz),
                  ly = length(O.yw);
            // Oxy = ^Vx , O.zw = ^Vy , C = ^(x,y) 
            // ^( div(V)=0 ) <=> ^x.^Vx + ^y.^Vy = 0
            // -> reproj: ^V -= dot(^V,^(x,y)). ^(x,y) / ||^2
            // do it for real part, then imaginary part:
        	O.xz -= dot(C,O.xz) *C /dot(C,C);
        	O.yw -= dot(C,O.yw) *C /dot(C,C);
            if (!keypressed(67)) {              // C
                // restore length
            	O.xz *= lx / (1e-3+length(O.xz));
           	    O.yw *= ly / (1e-3+length(O.yw));
            }
         }
        if( dot(C,C) < 1. ) O *= 0.; // no DC: kills global drift
    } else {
        // apply forces
      //O.xz += .01*(iMouse.xy-iMouse.zw)*exp(-10.*length(iMouse.xy-I)/R.y); // true forces
        O.xz += .01*(iMouse.xy-R.xy*.5)*exp(-.1/(1.+length(I-R.xy*.5))*dot2(I-R.xy*.5));
    }
    
    if(iFrame<6 && FFT_DIR==BACKWARD) // --- init
        O=vec4(0);
}