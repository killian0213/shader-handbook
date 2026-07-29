// Buf A (buffer) — Accelerated two pass raymarching by Psycho
// https://www.shadertoy.com/view/XdycWy

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
	return min(max(d.x,max(d.y,d.z)),0.0) +
	length(max(d,0.0));
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


#define BITS 8

// adapted from hlsl and unwrapped/expanded/commented, 
// but probably still looks too much like size coding for some ;)

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 vdir, vpos= campos;
    if (fragCoord.x*8.<iResolution.x && fragCoord.y*8.<iResolution.y)
    {
		setup(fragCoord*8.+4., vdir);
        
        // bitmasks to record in
		int primarymask = 0, shadowmask = 255; // set shadow mask for the case where we don't run part 2
		float tmax = viewrange, tmin = tmax, shadowmax = tmax, 
              conewidth = 4. / iResolution.y; // sufficient width of tile cone for our test setup

        // run for each object(mask) in our sdf 
        for (int mask = 1; mask < BITS; mask *= 2)
        {
            float stp = .1, t1 = 0., t2;
            // step until the cone intersects something
            while (t1<tmax && stp> .04+t1*conewidth)
            {
                t1 += stp-t1*conewidth;
                stp = sdf(vpos + vdir * t1, mask);
            }
            if (t1 < tmax)
            {
                t2 = t1;
                // step further on until cone is completely inside (if ever)
                // a very large bounding sphere isn't useful so we stop at t1*1.5+1
                while (t2<min(tmax,t1*1.5 + 1.) && stp>-t2*conewidth)
                {	
                    t2 += max(.01, stp) + t2*conewidth;
                    stp = sdf(vpos + vdir * t2, mask);            
                }

                if (stp < -t2*conewidth)
                {
                    // clear earlier results if they are occluded and set new max for next bit
                    if (t2 < tmin) primarymask = 0; 
                    tmax = min(t2, tmax);
                }
                primarymask |= mask;		
                tmin = min(t1, tmin);
            }
        }
        // do we have a useful situation for shadow optimization?
        if (primarymask>0 && tmax < tmin*1.5+1.)
        {
            shadowmask = 0; shadowmax = 0.;
            vec3 dir = normalize(lightdir), 
            // set up the bounding sphere for visible pixels in our tile    
            center = vpos + vdir * (tmin + tmax)*.5;;
            conewidth = (tmax - tmin)*.5+.05;     

            for (int m = 1; m < BITS; m *= 2)
            {
                //find first intersection
                float stp = conewidth+.1, t = viewrange;
                while (t>0. && stp>conewidth)
                {
                    t -= stp - conewidth+.02;
                    stp = sdf(center + dir * t, m);                
                }         
                
                // if we got a hit, record in shadow mask
                if (stp<conewidth) shadowmask |= m; 
                // and update the maximum distiance (from primary hitpoint) we have to trace shadows
                shadowmax = max(t + .01, shadowmax);

                // step further into object searching for total occlusion
                for (int i = 0; i<30 && stp>-conewidth && t > conewidth; i++)
                    stp = sdf(center + dir * (t -= max(stp + conewidth, .1)), m);

                // our whole tile is shadowed so no need to continue, mark with special value 1024.
                if (stp < -conewidth && t>conewidth) { shadowmask = 1024; break; }
            }
        }
        fragColor = vec4(tmin, primarymask, shadowmax, shadowmask); 
    }
}