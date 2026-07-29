// Buffer A (buffer) — Penrose Pathtraced by yx
// https://www.shadertoy.com/view/ttXGWr

#define pi (acos(-1.))

vec2 rotate(vec2 a, float b)
{
    float c = cos(b);
    float s = sin(b);
    return vec2(
        a.x * c - a.y * s,
        a.x * s + a.y * c
    );
}

float sdBox( vec3 p, vec3 b )
{
    p=abs(p)-b;
    return max(max(p.x,p.y),p.z);
}

vec2 hash2( const float n ) {
	return fract(sin(vec2(n,n+1.))*vec2(43758.5453123));
}

// hacky parameter to control the size
float T=4.;

// distance function
float scene(vec3 p)
{
    float d = 1e9;
    
    float fl=p.y+T+1.;
    
    // left beam
    d=min(d,sdBox(p+vec3(0,T,0),vec3(T,0,0)+1.));
    
    // vertical beam
	d=min(d,sdBox(p-vec3(T,0,0),vec3(0,T-2.,0)+1.));
    
    // the magic seam that moves over time so it's not in one place
    float plane = p.x+p.z-(T-2.)+fract(iTime)*(T*2.-6.);
    
    // back beam
    d=min(d, max(plane-1., sdBox(p+vec3(T,T,-T+1.),vec3(1.,1.,T))));
    
    // top beam
    d=min(d, max(-plane, sdBox(p-vec3(T,T,1.-T),vec3(1.,1.,T))));
    
    // intersect with a field of smaller boxes
    p=mod(p+vec3(1,1,1),2.)-1.;
    d = max(d,sdBox(p,vec3(.8)));
    
    d=min(d,fl);
    
    return d;
}

// ray bouncing function "borrowed" from I can't remember where
vec2 rv2;
vec3 B( vec3 i, vec3 n ) {
	vec3  uu = normalize( cross( n, vec3(0.0,1.0,1.0) ) );
	vec3  vv = cross( uu, n );
	
	float ra = sqrt(rv2.y);
	float rx = ra*cos(6.2831*rv2.x); 
	float ry = ra*sin(6.2831*rv2.x);
	float rz = sqrt( 1.0-rv2.y );
	vec3  rr = vec3( rx*uu + ry*vv + rz*n );

    return normalize( rr );
}

vec3 trace(vec3 cam, vec3 dir)
{
    vec3 accum = vec3(1);
    for(int bounce=0;bounce<4;++bounce)
    {
        // near-clip plane, can't remember why I did this
        float t=(bounce==0)?5.:0.;
        float k;
        for(int i=0;i<100;++i)
        {
            k = scene(cam+dir*t);
            t += k;
            if (abs(k) < .001)
                break;
        }

        // if we hit something
        if(abs(k)<.001)
        {
			vec3 h = cam+dir*t;
			vec2 o = vec2(.001, 0);
			vec3 n = normalize(vec3(
				scene(h+o.xyy)-scene(h-o.xyy),
				scene(h+o.yxy)-scene(h-o.yxy),
				scene(h+o.yyx)-scene(h-o.yyx)
			));

            // bounce the ray in a random direction
			cam = h+n*.02;
            dir = B(gl_FragCoord.xyz/iResolution.xyz,n);
            accum /= pi;

            h.xz+=vec2(-1,1);
            
            // depth-of-field hack by jittering the floor UVs
            h.xz+= (rv2-.5) * max(0.,abs(h.x-h.z)-5.) * .01;

            // grid lines
            float gridscale=2.;
            vec3 a = 1.-step(.49,abs(fract(h*gridscale)-.5));
            float f=min(a.z,a.x);
            
            // checkerboard
            gridscale=.25;
			h.xz++;
            f*=.8-step(.0,(fract(h.x*gridscale)-.5)*(fract(h.z*gridscale)-.5))*.3;
            
            if(h.y<-T-.99)
            	accum *= f;
        }
    }
    
    vec3 lightdir = vec3(0,1,0);
    return accum * max(0.,dot(dir,lightdir)) * 3.;
}

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
    // grab the previous color so we can iteratively render.
    // in the actual executable I just rendered additively to a single framebuffer instead
   	fragColor = texture(iChannel0,fragCoord/iResolution.xy);
    
    vec2 uv = fragCoord.xy/iResolution.xy-.5;

    // random function borrowed from I can't remember where
    float seed = iTime+(uv.x+iResolution.x*uv.y)*1.51269341231;
	rv2 = hash2( 24.4316544311+iTime+seed );
    
    // jitter camera for antialiasing
    uv += (rv2-.5)/iResolution.xy;
    
    // correct UVs for aspect ratio
    uv.x*=iResolution.x/iResolution.y;

    // make an orthographic camera
	vec3 cam = vec3(uv*15.,-20.);
    cam.y-=5./3.;
    cam.x+=.75;
    vec3 dir = vec3(0,0,1);

    // spin it to an isometric angle
    cam.yz = rotate(cam.yz, atan(1.,sqrt(2.)));
    dir.yz = rotate(dir.yz, atan(1.,sqrt(2.)));
    
    // debug camera rotation
    if (iMouse.z > 0.) {
        float a = .5-(iMouse.y/iResolution.y);
    	cam.yz = rotate(cam.yz, a);
    	dir.yz = rotate(dir.yz, a);
    }

    // spin it to an isometric angle
    cam.xz = rotate(cam.xz, pi/4.);
    dir.xz = rotate(dir.xz, pi/4.);
    
    // debug camera rotation
    if (iMouse.z > 0.) {
        float a = 1.-2.*(iMouse.x/iResolution.x);
    	cam.xz = rotate(cam.xz, a);
    	dir.xz = rotate(dir.xz, a);
    }
    
    // compute the pixel color, with some vignette I'd forgotten I put there
	vec4 pixel = vec4(trace(cam,dir)*(1.-dot(uv,uv)*.5),1);
    
    // reset buffer if we're clicking
    if (iMouse.z > 0.) fragColor *= 0.;

    // accumulate the pixel
    fragColor += pixel;
}