// Image (image) — PCGSPH (improved) by michael0884
// https://www.shadertoy.com/view/DstfRS

// Fork of "Particle clustering (SPH)" by michael0884. https://shadertoy.com/view/ddcfRB
// 2023-10-14 18:26:55

// Fork of "Particle clustering (LIQUID)" by michael0884. https://shadertoy.com/view/mscBRB
// 2023-10-14 16:17:15

// Fork of "Particle clustering (GAS)" by michael0884. https://shadertoy.com/view/ddcfzS
// 2023-10-14 15:53:28

// Fork of "Particle clustering (MD)" by michael0884. https://shadertoy.com/view/mscfW7
// 2023-10-14 15:02:57

//By having the initial particle count be way larger than what can fit in the simulation domain, 
//the particles are always splitting, meaning they fill the domain like a gas. 
//Here the effective virtual particle count is in the hundreds of millions.
//Naturally the mass is conserved exactly, since we are working with uint particle counts per cluster.
//SPACE to ZOOM in!

vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

	rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing	

	return c.z * mix( vec3(1.0), rgb, c.y);
}

const int KEY_SPACE = 32;
const int KEY_UP    = 38;
bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,2), 0 ).x > 0.5;
}

void ComputeProp(inout float rho, inout vec2 vel, in float prad, in vec2 pos, in Particle p)
{
    float d = length(p.pos - pos);
    float g = smoothstep(prad, 0.0, d) / (prad*prad);
    float m = g*float(p.mass)/float(initial_particle_density);
    vel = (rho * vel + p.vel * m) / max(m + rho, 1e-4); 
    rho += m;
}


#define radius 0.75
#define zoom 0.25
void mainImage( out vec4 col, in vec2 pos )
{    

    float prad = 2.1;
    //zoom in
    if(isKeyPressed(KEY_SPACE))
    {
    	pos = iMouse.xy + pos*zoom - R*zoom*0.5;
        prad = radius;
    }

    //pos = floor(pos);
    //compute the smoothed density
    float rho = 0.00;
    vec2 vel = vec2(0.001);
    range(i, -2, 2) range(j, -2, 2)
    {
        //load the particles 
        vec2 p = floor(pos) + vec2(i, j);
        vec4 packed = LOAD(ch0, p);
        Particle p0, p1;
        unpackParticles(packed, p, p0, p1);

        //compute the density
        ComputeProp(rho, vel, prad, pos, p0);
        ComputeProp(rho, vel, prad, pos, p1);
    }
    
    if(isKeyPressed(KEY_UP))
    {
        col.xyz = vec3(0.0);
        float vel_ang = atan(vel.y, vel.x) / TWO_PI;
        col.xyz += hsv2rgb(vec3(vel_ang, length(vel), rho));
    }
    else
    {
        col.xyz = 1.0 - 0.25*vec3(3,2,1)*(0.25*smoothstep(0.2, 0.25, rho) + 2.0*rho);
    }
}