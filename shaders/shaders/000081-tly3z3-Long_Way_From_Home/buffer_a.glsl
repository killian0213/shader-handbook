// Buffer A (buffer) — Long Way From Home by yx
// https://www.shadertoy.com/view/tly3z3

#define pi (acos(-1.))

mat2 rotate(float b)
{
    float c = cos(b);
    float s = sin(b);
    return mat2(c,-s,s,c);
}

vec2 hash2( const float n ) {
	return fract(sin(vec2(n,n+1.))*vec2(43758.5453123));
}

int m;

float footprint(vec2 p)
{
    vec2 h = vec2(0.125,0);
    vec2 q = p - clamp( p, -h, h );
    return length(q.xy);
}

float ridges(vec2 p)
{
    return smoothstep(.5,1.,cos(p.x*10.))*1.5 + sin(p.x*100.)*.5+.5;
}

float scene(vec3 p)
{
    float d = 1e9;
    
    // bounce-light orb
    d=min(d,length(p-vec3(0,5,0))-2.5);
    
    // light direction debug orb
    //d=min(d,length(p-vec3(0,.5,0))-.5);

    // poles
    vec3 r=p;
    r.x=abs(r.x-1.1)-.2;
    float dpole = max(length(r.xz+vec2(0,5.))-.01,r.y-5.);

    vec3 q=p;
    if(p.y <.3){
    	// snow roughness
		p.y += texture(iChannel1,p.xz*.125).r*.0009;
		p.y += texture(iChannel1,p.xz*2.*.125).r*.0011;
		p.y += texture(iChannel1,p.xz*4.*.125).r*.0021;
	    p.y += texture(iChannel1,p.xz*4.*.0625).r*.0051;
	    p.y += texture(iChannel1,p.xz*4.*.03125).r*.01;
        p.y += sin(p.x*2.)*.05;
        
        // gentle curvature
        p.y -= length(sin(p.xz*.5))*.1;

        
        // footprint meandering
        p.z += sin(p.x*.5)*.5;
        
        // footprint zigzag
        p.z += step(.5,mod(p.x,1.))*.3-.15;
        
        // footprints
        float depth = .03;
        p.x = mod(p.x,.5)-.25;
        float dfoot = footprint(p.xz);
        float foot = smoothstep(.1,.13,dfoot);
        p.y += .1- foot*depth;
        
        // raised snow around footprints
        p.y -= smoothstep(.05,.0,abs(dfoot-.16))*.004;
        
        // footprint stripe pattern
        p.y -= (1.-foot)*.01*ridges(p.xz);
        
    }
    
    // extra mounds
    p.y -= smoothstep(2.,0.,length(q.xz+vec2(-1.5,3.5)))*.2;
    p.y -= smoothstep(2.,0.,length(q.xz+vec2(1,-2)))*.2;
    
    // floor
    float ground = p.y;
    d=min(d,ground);
    
    m=(dpole<d)?1:0;
    d=min(d,dpole);
    
    return d*.9;
}

vec2 rv2;

vec3 ortho(vec3 a){
    vec3 b=cross(vec3(-1,-1,-1),a);
    // assume b is nonzero
    return (b);
}

// various bits of lighting code "borrowed" from 
// http://blog.hvidtfeldts.net/index.php/2015/01/path-tracing-3d-fractals/
vec3 getSampleBiased(vec3  dir, float power) {
	dir = normalize(dir);
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));
	vec2 r = rv2;
	r.x=r.x*2.*pi;
	r.y=pow(r.y,1.0/(power+1.0));
	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x)*oneminus*o1+sin(r.x)*oneminus*o2+r.y*dir;
}

vec3 getSample(vec3 dir) {
	return getSampleBiased(dir,0.0);
}

vec3 getCosineWeightedSample(vec3 dir) {
	return getSampleBiased(dir,1.0);
}

vec3 getConeSample(vec3 dir, float extent) {
	dir = normalize(dir);
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));
	vec2 r =  rv2;
	r.x=r.x*2.*pi;
	r.y=1.0-r.y*extent;
	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x)*oneminus*o1+sin(r.x)*oneminus*o2+r.y*dir;
}

vec3 sky(vec3 dir) {
	return vec3(1,2,3)*.2;
}

bool trace(vec3 cam, vec3 dir, out vec3 h, out vec3 n, out float k) {
	float t=0.;
    for(int i=0;i<100;++i)
    {
        k = scene(cam+dir*t);
        t += k;
        if (abs(k) < .004)
            break;
    }

    h = cam+dir*t;
	
    // if we hit something
    if(abs(k)<.004)
    {
        vec2 o = vec2(.001, 0);
        k=scene(h);
        n = normalize(vec3(
            scene(h+o.xyy) - k,
            scene(h+o.yxy) - k,
            scene(h+o.yyx) - k 
        ));
        return true;
    }
    return false;
}

vec3 trace(vec3 cam, vec3 dir)
{
    float mouseX = (iMouse.x/iResolution.x);
    float mouseY = (iMouse.y/iResolution.y);
    
    mouseX = 0.65;
    mouseY = 0.18;
    
    vec3 sunDirection = normalize(vec3(
        (mouseX-.5)*2.,
        mouseY*2.,
        -1
    ));
    const float sunSize = 1e-4;
    const vec3 sunColor = vec3(1.,.6,.2)*2.;
    
    vec3 accum = vec3(1);
    vec3 direct=vec3(0);
    for(int ibounce=0;ibounce<10;++ibounce)
    {
        vec3 h,n;
        float k;
        if (trace(cam,dir,h,n,k))
        {
            #if !SHADING
            return n*.5+.5;
            #endif
            vec3 albedo = vec3(1);
            
            // pole material
            if (m==1) {
                albedo = vec3(0.7);
            }
            
            cam = h+n*.002;
            dir=getSampleBiased(n,1.);
            accum*=albedo;
             
            vec3 sunSampleDir = getConeSample(sunDirection,sunSize);
            float sunLight = dot(n, sunSampleDir);
            vec3 dummy0,dummy1;
            float dummy2;
            if (sunLight>0.0 && !trace(h + n*.002,sunSampleDir,dummy0,dummy1,dummy2)) {
                direct += accum*sunLight*sunColor;
            }
            
            rv2=hash2(rv2.y);
        }
        else if (abs(k) > .1) {
            return direct + sky(dir) * accum;
        } else {
            break;
        }
    }
    
    return vec3(0);
}

vec2 bokeh(){
	vec2 a=rv2;
    if(a.y>a.x)
        a=1.-a;
    a.y*=pi*2./a.x;
    return a.x*vec2(cos(a.y),sin(a.y));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // recover previous frame for iterative rendering
   	fragColor = texelFetch(iChannel0,ivec2(fragCoord),0);	
    
    // get UVs
    vec2 uv = fragCoord.xy/iResolution.xy-.5;
    
    // seed per-pixel
    float seed = iTime+(uv.x+iResolution.x*uv.y)*1.51269341231;
	rv2 = hash2( seed );
  
    // jitter for antialiasing
    uv += (rv2-.5)/iResolution.xy;
    
    // correct UVs for aspect ratio
    uv.x*=iResolution.x/iResolution.y;

    // camera params
    const vec3 camPos = vec3(-4,2,3);
    const vec3 lookAt = vec3(0,0,0);
    const float focusDistance=distance(camPos,lookAt);
    const vec2 apertureRadius=vec2(1,2)*.015;
   
    // make a camera
    vec3 cam = vec3(0);
    vec3 dir = normalize(vec3(uv,2.));
    
    // slight bokeh
    #if BOKEH
    vec2 bokehJitter=bokeh();
    cam.xy+=bokehJitter*apertureRadius;
    dir.xy-=bokehJitter*apertureRadius*dir.z/focusDistance;
    #endif

    // rotate/move the camera
    vec3 lookDir = lookAt-camPos;
    float pitch = -atan(lookDir.y,length(lookDir.xz));
    float yaw = -atan(lookDir.x,lookDir.z);
    cam.yz *= rotate(pitch);
    dir.yz *= rotate(pitch);
    cam.xz *= rotate(yaw);
    dir.xz *= rotate(yaw);
    cam += camPos;
    
    // compute the pixel color
	vec4 pixel = vec4(trace(cam,dir),1);
    
    if (iMouse.z > 0.) {
        fragColor = vec4(0);
    }
    
    if (!isnan(pixel.r) && pixel.r >= 0.)
	    fragColor += pixel;
}