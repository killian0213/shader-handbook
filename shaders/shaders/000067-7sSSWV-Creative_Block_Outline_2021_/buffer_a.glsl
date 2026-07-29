// Buffer A (buffer) — Creative Block [Outline 2021] by yx
// https://www.shadertoy.com/view/7sSSWV

#define pi acos(-1.)
#define tau (pi*2.)

float seed;
float hash() {
	float p=fract((seed++)*.1031);
	p+=(p*(p+19.19))*3.;
	return fract((p+p)*p);
}
vec2 hash2(){return vec2(hash(),hash());}


mat2 rotate(float b)
{
    float c = cos(b);
    float s = sin(b);
    return mat2(c,-s,s,c);
}

float sdBox(vec2 p, vec2 b)
{
    vec2 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,q.y),0.0);
}

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0));
}

float sdBox(vec2 p, vec2 b, float r)
{
    return sdBox(p,b-r)-r;
}

float sdRoundedCylinder(vec3 p, float radius, float halfHeight, float bevel)
{
    vec2 p2 = vec2(length(p.xz),p.y);
    return sdBox(p2,vec2(radius,halfHeight),bevel);
}

float hexa(vec2 p, float r1, float r2)
{
    float ang = pi/3.;
    float x= (r1-r2)/tan(ang)+r2;
    vec2 v = vec2(x,r1);
    mat2 rot = rotate(ang);
    float hex1 = sdBox(p,v,r2); p.xy *= rot;
    float hex2 = sdBox(p,v,r2); p.xy *= rot;
    float hex3 = sdBox(p,v,r2);
    return min(hex1,min(hex2,hex3));
}

float sdCone( vec3 p, vec2 c )
{
    // c is the sin/cos of the angle
    vec2 q = vec2( length(p.xz), -p.y );
    float d = length(q-c*max(dot(q,c), 0.0));
    return d * ((q.x*c.y-q.y*c.x<0.0)?-1.0:1.0);
}

int mat = -1;
const int kMatGround = 0;
const int kMatPlasticRed = 1;
const int kMatWood = 2;
const int kMatLead = 3;

bool doWoodDisplacement = true;

float scene(vec3 p)
{
    vec3 op=p;
    
    float ground = p.y - (cos(min(100.,p.z)*.03)-1.)*2.;

    p.y -= 4.;
    p.xz *= rotate(2.1);
    p.z-=10.;
    float a = 0.23;
    float cone = sdCone(p.xzy,vec2(sin(a),cos(a)));
    float paintShell = hexa(p.xy,4.,1.);
    float woodCenter = hexa(p.xy,3.95,.95);
    float leadCore = length(p.xy)-1.1;
    
    paintShell = max(paintShell,max(cone,-woodCenter));
    woodCenter = max(woodCenter,cone);
    
    woodCenter = max(woodCenter,.01-leadCore);
    if (doWoodDisplacement)
        woodCenter += (texture(iChannel1,p.xy*.25).r-.4)*0.1;//*.075;
    leadCore = max(leadCore,cone);
    leadCore = max(leadCore,p.z+1.);
    leadCore = min(leadCore,length(p+vec3(0,0,1.05))-sin(a)*1.);
    leadCore += (texture(iChannel1,vec2(atan(p.x,p.z)*.5)).r-.3)*.05;
    

    float best = ground;
    best=min(best,paintShell);
    best=min(best,woodCenter);
    best=min(best,leadCore);

    
    if(best==ground)
    {
        mat = kMatGround;
    }
    else if (best == leadCore)
    {
        mat = kMatLead;
    }
    else if (best==woodCenter)
    {
        mat = kMatWood;
    }
    else if (best == paintShell)
    {
        mat = kMatPlasticRed;
    }
    
    return best;
}

float flip = 1.;
const float IOR = 1.584;

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
	vec2 r = hash2();
	r.x=r.x*2.*pi;
	r.y=pow(r.y,1.0/(power+1.0));
	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x)*oneminus*o1+sin(r.x)*oneminus*o2+r.y*dir;
}

vec3 getConeSample(vec3 dir, float extent) {
	dir = normalize(dir);
	vec3 o1 = normalize(ortho(dir));
	vec3 o2 = normalize(cross(dir, o1));
	vec2 r =  hash2();
	r.x=r.x*2.*pi;
	r.y=1.0-r.y*extent;
	float oneminus = sqrt(1.0-r.y*r.y);
	return cos(r.x)*oneminus*o1+sin(r.x)*oneminus*o2+r.y*dir;
}

vec3 sky(vec3 sunDir, vec3 viewDir) {
    float softlight = max(0.,dot(normalize(sunDir*vec3(-1,1.,-1)),viewDir)+.2);
    float keylight = pow(max(0.,dot(sunDir,viewDir)-.5),3.);
    
    return vec3(
		softlight*.015 + keylight * 10.
	)*1.5;
    
    /*return vec3(
		softlight*vec3(.03,.06,.1)*2. + keylight * vec3(10,7,4)
	)*1.5;*/

    /*float softlight = max(0.,dot(sunDir,viewDir)+.2);
    float keylight = pow(max(0.,dot(sunDir,viewDir)-.5),3.);
    
    return vec3(
		softlight*.5 + keylight * 10.
	)*1.5;*/
}    

bool trace5(vec3 cam, vec3 dir, float nearClip, out vec3 h, out vec3 n, out float k) {
	float t=nearClip;
    for(int i=0;i<100;++i)
    {
        k = scene(cam+dir*t)*flip;
        if (abs(k) < .001)
            break;
        t += k;
    }

    h = cam+dir*t;
	
    // if we hit something
    if(abs(k)<.001)
    {
        vec2 o = vec2(.001, 0);
        n = normalize(vec3(
            scene(h+o.xyy) - k,
            scene(h+o.yxy) - k,
            scene(h+o.yyx) - k 
        ))*flip;
        return true;
    }
    return false;
}

float floorPattern(vec2 uv)
{
    float kUnit1 = 10.;
    float kUnit2 = 5.;
    float kUnit3 = 1.;
    float kThick1 = 0.1;
    float kThick2 = 0.05;
    float kThick3 = 0.03;

    vec2 uv1 = abs(mod(uv,kUnit1)-kUnit1*.5);
    vec2 uv2 = abs(mod(uv,kUnit2)-kUnit2*.5);
    vec2 uv3 = abs(mod(uv,kUnit3)-kUnit3*.5);
    float lines1 = -max(uv1.x,uv1.y)+kUnit1*.5-kThick1;
    float lines2 = -max(uv2.x,uv2.y)+kUnit2*.5-kThick2;
    float lines3 = -max(uv3.x,uv3.y)+kUnit3*.5-kThick3;
    
    return min(lines1,min(lines2,lines3));
}

vec3 trace2(vec3 cam, vec3 dir, float nearClip)
{
    const vec3 sunDirection = normalize(vec3(-1.,.8,-.7));
    //const vec3 sunDirection = normalize(vec3(1.,.7,-.3));
    //const vec3 sunDirection = normalize(vec3(.5,.3,1));
    //const vec3 sunDirection = normalize(vec3(0,1,0));
    
    vec3 accum = vec3(1);
    for(int ibounce=0;ibounce<10;++ibounce)
    {
        vec3 h,n;
        float k;
        if (trace5(cam,dir,ibounce==0?nearClip:0.,h,n,k))
        {
            cam = h+n*.01;
            if (mat == kMatGround)
            {
            	dir=getSampleBiased(n,1.);
				accum *= mix(vec3(.25,.3,.35),vec3(.8),step(0.,floorPattern(h.xz)));
                if (ibounce==0)
                    doWoodDisplacement=false;
            }
            else if (mat == kMatWood)
            {
            	dir=getSampleBiased(n,1.);
                vec3 col = vec3(211,183,155)/255.;
				accum *= col*col*col;
            }
            else if (mat == kMatPlasticRed)
            {
                float fresnel = pow(1.-min(.99,dot(-dir,n)),5.);
                fresnel = mix(.04,1.,fresnel);
                if (hash() < fresnel)
                {
                	dir=reflect(dir,n);
                }
                else
                {
            		dir=getSampleBiased(n,1.);
                    accum *= vec3(180,2,1)/255.;
                }
            }
            else if (mat == kMatLead)
            {
                float fresnel = pow(1.-min(.99,dot(-dir,n)),5.);
                fresnel = mix(.04,1.,fresnel);
                dir=getConeSample(reflect(dir,n),0.3);
                accum *= .05;
            }
        }
        else if (abs(k) > .1) {
            return sky(sunDirection, dir) * accum;
        } else {
            break;
        }
    }
    
    return sky(sunDirection, dir) * accum;
    
    // deliberately fail the pixel
    return vec3(-1);
}

vec2 bokeh(){
    // hexagon
    vec2 a = hash2();
    a.x=a.x*3.-1.;
    a-=step(1.,a.x+a.y);
	a.x += a.y * .5;
	a.y *= sqrt(.75);
    return a;
}

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
    fragColor = texelFetch(iChannel0,ivec2(fragCoord),0);

    if (iMouse.z > 0.) {
        fragColor = vec4(0.);
    }

	// seed the RNG (again taken from Devour)
    //seed = float(((iFrame*73856093)^int(gl_FragCoord.x)*19349663^int(gl_FragCoord.y)*83492791)%38069);
    seed = float((iFrame*73856093)%38069);

    // get UVs
    vec2 uv = (gl_FragCoord.xy+hash2()-.5)/iResolution.xy-.5;
    
    // correct UVs for aspect ratio
    float aspect = iResolution.x/iResolution.y;
    uv.x*=aspect;
	uv *= max(1.,(16./9.)/aspect);

    // camera params
    const vec3 camPos = vec3(140,60.,60)*1.5;
    const vec3 lookAt = vec3(0,4.,0);
    const float focusDistance=distance(camPos,lookAt)*.99;
    const vec2 apertureRadius=vec2(1)*3.;
    
    // make a camera
    vec3 cam = vec3(0);
    vec3 dir = normalize(vec3(uv,6.5));
    
    // add some bokeh
    vec2 bokehJitter=bokeh();
    cam.xy+=bokehJitter*apertureRadius;
    dir.xy-=bokehJitter*apertureRadius*dir.z/focusDistance;
    
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
	vec3 pixel = trace2(cam,dir,length(camPos)*.7);
    
    fragColor += (!isnan(pixel.r) && pixel.r >= 0.) ? vec4(pixel,1) : vec4(0);
}