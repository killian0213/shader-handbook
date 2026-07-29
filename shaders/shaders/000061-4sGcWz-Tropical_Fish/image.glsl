// Image (image) — Tropical Fish by rigel
// https://www.shadertoy.com/view/4sGcWz

/**
	Author: Rigel rui@gil.com
	licence: https://creativecommons.org/licenses/by/4.0/
	link: https://www.shadertoy.com/view/4sGcWz
	------------------------------------------------------

	My goal with this shader was to learn about the voronoi algorithm.
	The algorithm in itself is pretty straighforward, but the distance
	to edges is a bit more tricky.

	So I started with this reference article by IQ.
	https://iquilezles.org/articles/voronoilines

	And then searching Shadertoy I stumbled on Shane quest for the perfect 
	round borders voronoi and his interactions with FabriceNeyret2, DR2 and Tomkh.
	It was quite fun to follow the breadcrumbs and I learned a lot :)

	Shane - https://www.shadertoy.com/view/4dsfDl
	DR2 - https://www.shadertoy.com/view/Xsyczh
	FabriceNeyret2 - https://www.shadertoy.com/view/4dKSDV
	Tomkh - https://www.shadertoy.com/view/llG3zy
	
	The voronoi algorithm is constant time, because it's based on a grid.
	But that makes the feature points evenly distributed, wich can be kind of
	limitied from an artistic perspective...
	I wanted to have a variable point density, so I needed a way to distort the grid.
	
	Luckly complex functions have this tendency of distorting space around zeros
	and poles (infinity), so I decided to try that.

	There is a way to visualize complex functions called Domain Coloring 
	https://en.wikipedia.org/wiki/Domain_coloring

	This shader is nothing more than Domain Coloring taken literaly.
	I use the domain as a kind coloring book, and then apply the transform.

	The complex function is the Lambert Series https://en.wikipedia.org/wiki/Lambert_series
	That I used in my shader about Domain Coloring https://www.shadertoy.com/view/ltjczK
	I already thought at that time, that it looked like a fish, so I only needed to make it so. :)
*/

// uncomment if you want to see the domain without the transform
//#define DOMAIN 

// uncomment to see the grid, and visualize the distortion
//#define GRID


// a few utility functions
// smoothstep antialias with fwidth
float ssaa(float v) { return smoothstep(-1.,1.,v/fwidth(v)); }
// stroke an sdf 'd', with a width 'w', and a fill 'f' 
float stroke(float d, float w, bool f) {  return abs(ssaa(abs(d)-w*.5) - float(f)); }
// fills an sdf 'd', and a fill 'f'. false for the fill means inverse 
float fill(float d, bool f) { return abs(ssaa(d) - float(f)); }
// a signed distance function for a rectangle 's' is size
float sdfRect(vec2 uv, vec2 s) { vec2 auv = abs(uv); return max(auv.x-s.x,auv.y-s.y); }
// a signed distance function for a circle, 'r' is radius
float sdfCircle(vec2 uv, float r) { return length(uv)-r; }
// hash function for pseudorandom numbers
vec2 hash2( vec2 p ) { return fract(sin(vec2(dot(p,vec2(1275.1,3131.7)),dot(p,vec2(269.5,183.3))))*43758.5453); }
// a cosine palette with domain d between 0-1
vec3 pal(float d) { return .5 * ( cos(d*6.283*vec3(2.,2.,1.) + vec3(.0,1.4,.4)) + 1. ); }
// a simple square grid, you can control the scale and the width
float grid(vec2 uv, float scale, float w) { vec2 guv = fract((uv*scale)-.5)-.5; return max(stroke(guv.x,w,true),stroke(guv.y,w,true)); }
// conversion from cartesian to polar
vec2 toPolar(vec2 uv) { return vec2(length(uv),atan(uv.y,uv.x)); }
// conversion from polar to cartesian
vec2 toCarte(vec2 z) { return z.x*vec2(cos(z.y),sin(z.y)); }
// complex division in polar form z = vec2(radius,angle)
vec2 zdiv(vec2 z1, vec2 z2) { return vec2(z1.x/z2.x,z1.y-z2.y); }
// complex pow in polar form z = vec2(radius,angle)
vec2 zpow(vec2 z, float n) { return vec2(exp(log(z.x)*n),z.y*n); }
// complex sub in polar form z = vec2(radius,angle)
vec2 zsub(vec2 z1, vec2 z2) { return toPolar(toCarte(z1) - toCarte(z2)); }


// This is the Lambert series transform
// https://en.wikipedia.org/wiki/Lambert_series
vec2 lambert(vec2 uv, float m) {
    vec2 z = toPolar(uv);
    vec2 sum = vec2(.0);
    vec2 offset = vec2(1.+m * cos(iTime*3.),.2*cos(iTime*(2.+m*2.)));
    for (float i=1.; i<7.; i++)
        sum += toCarte(zdiv(zpow(z,i),zsub(offset,zpow(z,i))));
   return sum;
}

// IQ's smooth minimum function.
// https://iquilezles.org/articles/smin
float smin(float a, float b, float k) {
    float h = clamp(.5 + .5*(b - a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1. - h);
}

// Classic voronoi algorithm taken from tomkh
// https://www.shadertoy.com/view/llG3zy
vec3 voronoi( in vec2 x, float m) {
    vec2 n = floor(x);
    vec2 f = fract(x);

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
	vec2 mr;

    float md = 8.0;
    for( float j=-1.; j<=1.; j++ )
        for( float i=-1.; i<=1.; i++ ) {
            vec2 g = vec2(i,j);
	    	vec2 seed = hash2( n + g );
            seed = .5 + .3 * cos(iTime*m * 6.283 * seed);
            vec2 r = g + seed - f;
            float d = dot(r,r);
            if( d<md ) {
                md = d;
                mr = r;
            }
    }
    //----------------------------------
    // second pass: distance to borders,
    //----------------------------------
    md = 8.0;
    for( float j=-1.; j<=1.; j++ )
        for( float i=-1.; i<=1.; i++ ) {
            vec2 g = vec2(i,j);
	    	vec2 seed = hash2( n + g );
            seed = .5 + .3 * cos(iTime*m * 6.283 * seed);
		    vec2 r = g + seed - f;

            if( dot(mr-r,mr-r)>.0001 ) { // skip the same cell 
                // smooth minimum for rounded borders
                // apparently I need the max(,.0) to filter out weird values
                md = max(smin(md,dot( 0.5*(mr+r), normalize(r-mr) ),.25),.0);
            }
        }
    

    return vec3( mr, sqrt(md));
}

// The scene
vec3 TropicalFish(vec2 uv) {

    vec2 z = uv;
    bool dom = false;

    #ifdef DOMAIN
        z = uv*15.-vec2(4.,.0); dom = true;
    #else
        // transform uv with the complex lambert series
        z = lambert(uv*4., iMouse.z > 0. ? .4 : .0);
    #endif

    // the voronoi tesselation is "pulled back" by the complex map
    // this means that we pick a color from the domain after the transform
    vec3 vvz = voronoi(z, iMouse.w > 0. ? .7 : .2);

    // a few helpers for the domain coloring
    vec2 zv = floor(z + vvz.xy); // voronoi feature point center
    float phase = atan(uv.y,uv.x); // phase in untransformed space to apply some masks

    // the scales and back fin
	vec3 colorphase = pal(atan(z.y,z.x)/6.283);
    vec3 c = mix(colorphase*.8,pal(.4+vvz.z*.7)*.7,smoothstep(0.,.2,vvz.z)); // mixin the fins with the ocean
    c = mix(c,pal(vvz.z+.3)*.8*.5*(sin(vvz.z*6.283*8.)+1.), step(.2,vvz.z) ); // scales in the fin
    // the center of the back fin
    c = mix(c,colorphase*(sin(6.5*log(1.+length(zv+vec2(4.,.0)))))*.7,fill(sdfCircle(zv.xy+vec2(4.,.0),7.),false));

    // scales mouth
    vec3 mouth = mix(pal(.47+z.y*.05)*.8,pal(.5+vvz.z*.15)*.9, step(.4,vvz.z) )*smoothstep(18.,7.,length(z));
    // kind of cheating here. It is not domain coloring, because the scales in the mouth are the same
    // that the scales in in the back fin, so I apply the mask in the untransformed space to break the symmetry.
    c = mix(c,mouth,smoothstep(radians(130.),radians(170.),abs(phase)) ); // phase mask
    
    // ocean mask
    float ocmask = step(sdfRect(zv.xy+vec2(6.,.5),vec2(1.,1.)),.0);
    c = mix(c,pal(.1+z.x*.05)*.6,ocmask); // ocean

    // dorsal fins
    vec3 dorsalFin = mix(pal(.47+z.y*.15),pal(.5+vvz.z*.5)*.4,.5*cos(z.y*6.283*4.));
    float fpm = dom ? 1. : smoothstep(radians(30.),radians(17.),abs(abs(phase)-radians(100.))); // fin phase mask
    c = mix(c,dorsalFin,fill(sdfRect(zv+vec2(4.5,.5),vec2(.5,.5)),true)*fpm);

    // bubbles mask
    float bubble = max(stroke(sdfCircle(vvz.xy,.05),.01,true),fill(sdfCircle(vvz.xy+vec2(.01),.02),true));
    c = mix(c,pal(.8+vvz.z*.2),bubble*ocmask);  // bubles

    // body
    c = mix(c,pal(.47+z.y*.15),fill(sdfRect(zv.xy+vec2(.5,.5),vec2(.5,.5)),true)); 
    
    // eye mask
    float eye = max(fill(sdfCircle(z-vec2(-.33,-.14)+.05*vec2(cos(iTime),sin(iTime*2.)),.05),true),stroke(sdfCircle(z-vec2(-.33,-.14),.17),.03,true));
    // if you remove this mask you will get a multieye monster ! :)
    float epm = dom ? 1. : float(abs(phase-radians(150.)) < radians(30.)); // eye phase mask
    c = mix(c,mix(pal(.8+z.x),vec3(.0),eye),fill(sdfCircle(z-vec2(-.33,-.14),.17),true)*epm); // eye

	// vignette
	c *= exp(-.5*dot(uv,uv));

    #ifdef GRID
        c = mix(c,vec3(1.),grid(z,1.,.05));
    #endif

    return c;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = ( fragCoord.xy - iResolution.xy * .5) / iResolution.y;

	fragColor = vec4( TropicalFish(uv), 1.0 );
}