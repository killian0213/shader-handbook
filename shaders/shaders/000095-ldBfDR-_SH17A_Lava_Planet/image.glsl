// Image (image) — [SH17A] Lava Planet by P_Malin
// https://www.shadertoy.com/view/ldBfDR

// [SH17A] Lava Planet
// @P_Malin
// https://www.shadertoy.com/view/ldBfDR


// There was more potential in this code so I made a variation without the 280 character limit here:
// https://www.shadertoy.com/view/4dBBDD

// Also see the annotated version by @morgan3d explaining what is going on a bit more here:
// https://www.shadertoy.com/view/Mdjfzd

#define T texture(iChannel0,c*.1)

void mainImage( out vec4 f, vec2 c )
{
    vec4 d = vec4( c / iResolution.x, 1, 1 ) - .5, // 'view' (d)irection
        o, // (o)ffset from camera
        g, // (g)low amount
        t, // '(t)exture'
        l; // '(l)andscape'
	
	//d.z += d.y * .5; // More dramatic camera projection
    
    o = f *= 0.; // required for GL
    
    for ( float h=0.; h<.6; h+=.001 ) // terrain slice (h)eight
        f += // accumulate "volumetric lighting" into final output
        	o.y < T.x // loop condition
        		?
                    o = d * h / -abs(d.y), // calculate offset of slice intersection
                    c = o.xz - iTime * .2,
                    l = T, // terrain sample 1
                    t = texture(iChannel1,c), // terrain / lava texture sample
                       //t = textureLod(iChannel1,c, 12. * (T.x-o.y) ), // comment in for better glow
                    g = pow( l*t,t+7. // glow color
                                   //+sin(iTime) // comment in for pulse effect
                                ) * o.y // change color of sky
	        	: g; // should be zero not g but g looks ok
            
            
 	c-=.1; // offset UV for lighting
    l -= T-.4; // terrain lighting
    
    
    f += // f already contains "volumetric lighting"
         t * l // terrain texture * lighting
        + g * 6e2 // add glow,
        	* o.y // fiddle with sky color some more
        +o.z*.03; // "depth fog"
    
    //f = 1. - exp(-f * 1.5); // tonemap    
}

/*
// minified..

#define T texture(iChannel0,c*.1)
void mainImage(out vec4 f, vec2 c){vec4 d=vec4(c/iResolution.x,1,1)-.5,o,g,t,l;o=f*=0.;
for(float h=0.;h<.6;h+=.001)f+=o.y<T.x?o=d*h/-abs(d.y),c=o.xz-iTime*.1,l=T,
t=texture(iChannel1,c),g=pow(l*t,t+7.)*o.y:g;c-=.1;l-=T-.4-d.y;f+=t*l+g*2e2+o.z*.03;}

*/


/*
// New and improved - backup

#define T texture(iChannel0,c*.1)

void mainImage( out vec4 f, vec2 c )
{
    vec4 o = vec4( c / iResolution.x, 1, 1 ) - .5, d=o, g, t, l;
	
    f*=0.;
    for ( float h=0.; h<.6; h+=.001)
        if ( o.y < T.x )
            l = T,
            t = texture(iChannel1,c -= .1),
            f -= g = pow( l*t,t+7. 
                       // +sin(iTime)
                        ) * d.y,
            l -= T-.2,
            o = d * h/-abs(d.y),
            c = o.xz - iTime * .1;
    
    
    f += t * l
        - g * 3e2
        +o.z*.01;
}
*/

/*

#define T texture(iChannel0,c*.07)

void mainImage( out vec4 r, vec2 c )
{
    vec4 o = vec4( c / iResolution.x, 1, 1 ) - .5, d=o, g, l, f;

    for ( float h=0.; h<.6 && o.y < T.x; h+=.001)
		r = T,
        l = texture(iChannel1,c -= .1),
        f += g = pow( r*l,l+8.+sin(iTime) ) * o.y, 
        r -= T-.2,
        o = d * h / -abs(d.y),
        c = o.xz - iTime * .1;
    
    r = l * r
        + g * 3e2 
        + f
        + o.z / 1e2;
}

*/

/*
// Move condition into for loop (thanks lherm)

#define T texture(iChannel0,c*.1)

void mainImage( out vec4 f, vec2 c )
{
    vec3 o = vec3( c / iResolution.x, 1 ) - .5, d=o;
        
    for ( float h=0.; h<.6 &&  o.y < T.x; h+=.001)
        o = d * h / -abs(d.y), // Intersect slice
        c = o.xz - iTime * .1, // Get terrain UV
        f = T; // Sample terrain texture    
    
    f = 1. -exp( - // tonemap
          texture(iChannel1,c+=.1)  // texture (and offet uv for lighting)
        * ( 
              .2 - f + T // terrain lighting - should be max(0., ...
            - exp( vec4(16, 14, 9, 1) * f - 9. + sin(iTime))  // lava glow
            * d.y            
          )
          
          -o.z * .01 // "fog"
                
          //+o.z * f *.1// fog effect 2
                
    );    
}
*/

/*

#define T texture(iChannel0,c*.1)

void mainImage( out vec4 f, vec2 c )
{
    vec3 o = vec3( c / iResolution.x, 1 ) - .5, d=o;
        
	f=T;
    
    for ( float h=0.; h<.6 &&  o.y < f.x; h+=.001)
        o = d * h / -abs(d.y), // Intersect slice
        c = o.xz - iTime * .1, // Get terrain UV
        f = T; // Sample terrain texture    
    
    f = 1. -exp( - // tonemap
          texture(iChannel1,c+=.1)  // texture (and offet uv for lighting)
        * ( 
              .2 - f + T // terrain lighting - should be max(0., ...
            - exp( vec4(16, 14, 9, 1) * f - 9. + sin(iTime))  // lava glow
            * d.y            
          )
          
          -o.z * .01 // "fog"
                
          //+o.z * f *.1// fog effect 2
                
    );    
}
*/

// backup 

/*

#define T texture(iChannel0,c*.1)

// lava pulse

void mainImage( out vec4 f, vec2 c )
{
    vec3 d = vec3( c / iResolution.x, 1 ) - .5, o=d;
	    
    f *= 0.;
    //d.y *=sign(d.y)+2.; f=iDate;
    
    for ( float h=0.; h<.6; h+=.001)
        if ( o.y < f.x) // break out of loop
            o = d * h / d.y, // Intersect slice
            c = o.xz - iTime * .1, // Get terrain UV
            f = T; // Sample terrain texture    
    
    f = 1. -exp( - // tonemap
          texture(iChannel1,c+=.05)  // texture (and offet uv for lighting)
        * ( 
              .2 + f.x -T.x // terrain lighting - should be max(0., ...
            + exp( vec4(16, 13, 9, 1) * f - 9. + sin(iTime)) // lava glow
          )
          -o.z * .01 // "fog"
    );    
}
*/

/*
// plane slices version

#define T texture(iChannel0,c*.1)

void mainImage( out vec4 f, vec2 c )
{
    vec3 d = vec3( c / iResolution.x, 1 ) - .5, o=d;

    f = vec4(0);
    for ( float h=0.; h<.6; h+=.001)
        if ( o.y < f.x) // break out of loop
            o = d * h / d.y, // Intersect slice
            c = o.xz - iTime * .1, // Get terrain UV
            f = T; // Sample terrain texture
    
    
    f = 1. -exp( - // tonemap
          texture(iChannel1,c+=.05)  // texture (and offet uv for lighting)
        * ( 
              max(0., .2 + f.x -T.x) // terrain lighting
            + exp( vec4(16, 13, 9, 1) * f - 9.) // lava glow
          )
          -o.z * .01 // "fog"
        //+ dot(o,o) * .001// "fog"
    );    
}
*/


// first version @ 279

/*
#define T texture(iChannel0,c*.1)

void mainImage( out vec4 f, vec2 c )
{
    vec3 d = vec3( c / iResolution.x, 1 ) - .5, o = d /= 2e2;
    
    do
		o += d, // Step along ray
        c = o.xz + iTime * .1, // Get terrain UV
        f = T; // Sample terrain texture
    while(
        o.z < 8. && // far clip
        o.y > -min(.6,f.x)); // hit terrain

    f = 1. -exp( - // tonemap
          texture(iChannel1,c+=.05)  // texture
        * ( 
              max(0., .2 + f.x -T.x) // terrain lighting
            + exp( vec4(16, 13, 9, 1) * f.x - 9.) // lava glow
          )
        * step(o.z, 8.) // far clip
        + o.z * .03 // "fog"
    );    
}

*/




/*
//hacks

#define T texture(iChannel0,c*.1)

// lava pulse

void mainImage( out vec4 f, vec2 c )
{
    vec4 o = vec4( c / iResolution.x, 1, 0 ) - .5, d=o/1e3/o.y;
    
    o=f=o-o;
    for(int i=0;i<600;i++)
        if ( o.y <= f.x) // break out of loop
            o += d, // Intersect slice
            c = o.xz - iTime * .1, // Get terrain UV
            f = T; // Sample terrain texture    
    
    f = 1. -exp( - // tonemap
          texture(iChannel1,c+=.05)  // texture (and offet uv for lighting)
        * ( 
              .2 + f -T // terrain lighting - should be max(0., ...
            + exp( vec4(16, 13, 9, 1) * f - 9. + sin(iTime)) // lava glow
          )
          -o.z * .01 // "fog"
    );    
}

*/