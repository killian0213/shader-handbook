// Image (image) — Accelerated two pass raymarching by Psycho
// https://www.shadertoy.com/view/XdycWy

// Illustrative example of my new tile based ray marching acceleration
// First used in the 8kb intro One Of Those Days - http://www.pouet.net/prod.php?which=75790 

// Red: iteration count primary rays
// Green: iteration count shadow rays

// The main discovery is that the additional stepping into the object looking for a 
// negative sdf value large enough to fully cover (and thus terminate) the tile
// cone/beam, can give us:
// a) occlusion in our scene mask determination
// b) a tile bounding sphere from which to run a similar shadow beam trace for masking/maxdistance
// c) which may also determine the whole tile as shadowed

// It is not worth measuring performance on this scene and setup, instead look at 
// the iteration counts and masking.

// In One Of Those Days (which doesn't have that many objects on screen and 
// with the trees overextending) it renders a good twice as fast with the prepass.
// Similar iteration shot from the actual intro:
// http://misc.loonies.dk/oneofthosedays_iterations.jpg
// http://misc.loonies.dk/oneofthosedays_iterations_nopre.jpg


/////////////////// Scene setup shared between passes //////////
vec3 lightdir=vec3(-1,.7,1), campos=vec3(5,3.5,5);
float viewrange=50.;
vec3 color=vec3(1,0,0);

vec3 rotatey(vec3 r, float v)
{
	return vec3(r.x*cos(v)+r.z*sin(v),r.y,r.z*cos(v)-r.x*sin(v)); 
}

float box( vec3 p, vec3 b )
{
	vec3 d = abs(p) - b;
	return min(max(d.x,max(d.y,d.z)),0.) +
	length(max(d,0.));
}

float sdf(vec3 p, int mask) 
{
	p= rotatey(p,iTime);
	float r = 100.;
    
    if ((mask&1)>0)
    {
        r = p.y;
        color = vec3(.7,.7,.7);
    }
    
    if ((mask&2)>0)
    {
        float r2 = box(p-vec3(2,2,0),vec3(1));
        if (r2<r)
        {
            r=r2;
            color = vec3(1,0,0);
        }
    } 
    
    if ((mask&4)>0)
    {
        float r2 = length(p-vec3(-2,3,0))-1.;
        if (r2<r)
        {
            r=r2;
            color = vec3(0,0,1);
        }
    }  
	return r;
}

void setup(in vec2 fragCoord, out vec3 vdir)
{
    vec2 p = fragCoord.xy / iResolution.xy-.5;
	vdir= normalize(rotatey(rotatey(
        vec3(p.y,p.x*iResolution.x/iResolution.y,1)
		,-.3).yxz,3.65));
}
///////////////////////////////////////////////////////////


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // 0: visual, 1: iterations optimized, 2: iterations without prepass, 3: primary mask
    int mode = int(mod(iTime,4.));
   
    vec3 vdir, vpos= campos, e=vec3(.01,0,0), res = vec3(.7,.7,.9);
    setup(fragCoord, vdir);
    
    // parse info from pre pass
    vec4 pass1 = texture(iChannel0, vec2((fragCoord.x-4.)/iResolution.x/8., (fragCoord.y-4.)/iResolution.y/8.));
    int mask = int(pass1.y), shadowmask=int(pass1.w);
  	float primary_tmin= pass1.x, shadow_tmax=pass1.z; 

    if (mode==2)
    {
        mask=shadowmask=255;
        primary_tmin=0.;
        shadow_tmax=viewrange;
    }

    // ordinary raymarching using the values from above...
    float t=primary_tmin, stp=0.;
    vec2 iterations = vec2(0,0);
  	do
  	{
        iterations.x++;
        t+=stp;
		stp = sdf(vpos+vdir*t,mask);
  	} 
    while (t<viewrange && stp>.001*t);
    
  	if (t<viewrange) 
  	{ 
    	vpos+= vdir*t;  
        vec3 m = color,
		n= normalize(vec3(sdf(vpos+e.xyy,mask),sdf(vpos+e.yxy,mask),sdf(vpos+e.yyx,mask))-stp);
        vpos+=n*.02;
        
        t = 0.;
        float ph=1e10, shadow=.3;
        if (shadowmask<1024)
        {
            // simple hard shadows for the example - otherwise shadow beam in prepass should be widened
            do
            {
                iterations.y++; 
                stp = sdf( vpos + normalize(lightdir)*t, shadowmask );
                t += stp;
            }
            while (t<shadow_tmax && stp>.01); 

           if (t>shadow_tmax)
                shadow=1.;
    	}
        
		res =clamp(dot(normalize(lightdir),n),.0,1.) * m * shadow;
	}
    
    if (mode>0) 
        res = vec3(iterations.xy*.03,0.);
    if (mode==3)
        res = vec3((mask&1)>0,(mask&2)>0,(mask&4)>0);
    fragColor.xyz= res;
}