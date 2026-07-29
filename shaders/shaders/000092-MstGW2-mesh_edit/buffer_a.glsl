// Buf A (buffer) — mesh edit by FabriceNeyret2
// https://www.shadertoy.com/view/MstGW2

// each pixel of BufA encodes a pair of vertex coordinates.
// It's Image shader responsability to pick and connect some of these.


void mainImage( out vec4 O,  vec2 uv )
{
    vec2 U = uv/iResolution.xy;
    
    O = texture(iChannel0,U);
  //if (iFrame==0) {
    if (length(O.xy)==0.) {   // better if further increase of window size
        O.xy = uv + 10.*(2.*texture(iChannel1,U).xy-1.);  // initial jittered coords
        return;
    }
    else  {
        float a = 10.*iTime + uv.x+117.1*uv.y; // decorelates rotation angle
        O.xy += .2* vec2(cos(a),sin(a));       // shake coords
    }
    
    if ( length(iMouse.xy-O.xy) < 10. )        // edit coords
        O.xy = iMouse.xy;
}