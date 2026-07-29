// Common (common) — PCGSPH (improved) by michael0884
// https://www.shadertoy.com/view/DstfRS

#define ch0 iChannel0
#define ch1 iChannel1
#define ch2 iChannel2
#define ch3 iChannel3

#define LOAD(ch, pos) texelFetch(ch, ivec2(pos), 0)

#define PI 3.1415926535
#define TWO_PI 6.28318530718

#define surface_tension 1.5
#define surface_tension_rad 4.0
#define initial_particle_density 2u
#define dt 0.6
#define rest_density 2.0
#define gravity 0.005
#define force_k 0.2
#define force_coef_a -4.0
#define force_coef_b 0.0
#define force_mouse 0.005
#define force_mouse_rad 40.0
#define force_boundary 5.0
#define viscosity 3.0
#define boundary_h 5.0
#define max_velocity (2.0/dt)
#define cooling 0.0

#define R iResolution.xy

#define GD(x, R) exp(-dot(x/R,x/R))/(R*R)
#define GS(x) exp(-dot(x,x))
#define DIR(phi) vec2(cos(TWO_PI*phi),sin(TWO_PI*phi))

#define loop(i,x) for(int i = 0; i < x; i++)
#define range(i,a,b) for(int i = a; i <= b; i++)


struct Particle 
{
    uint mass;
    vec2 pos;
    vec2 vel;
    vec2 force;
    float density;
};

//5 bits for shared exponent, 9 bits for each component
uint packvec3(vec3 v)
{
    //get the exponent
    float maxv = max(abs(v.x), max(abs(v.y), abs(v.z)));
    int exp = clamp(int(ceil(log2(maxv))), -15, 15);
    float scale = exp2(-float(exp));
    vec3 sv = v*scale;
    sv = round(clamp(sv, -1.0, 1.0) * 255.0);
    sv = sv + 255.0;
    uint packed = uint(exp + 15) | (uint(sv.x) << 5) | (uint(sv.y) << 14) | (uint(sv.z) << 23);
    return packed;
}

vec3 unpackvec3(uint packed)
{
    int exp = int(packed & 0x1Fu) - 15;
    vec3 sv = vec3((packed >> 5) & 0x1FFu, (packed >> 14) & 0x1FFu, (packed >> 23) & 0x1FFu);
    vec3 v = (sv - 255.0) / 255.0;
    v *= exp2(float(exp));
    return v;
}

vec4 packParticles(Particle p0, Particle p1, vec2 pos)
{
    // 1. Mass
    uint mass0 = p0.mass; 
    uint mass1 = p1.mass;
    uint packedMass = (mass0 << 16) | mass1;
    float massFloat = uintBitsToFloat(packedMass);

    // 2. Position
    p0.pos -= pos;
    p1.pos -= pos;
    
    uint pos0x = uint(round(clamp(p0.pos.x, 0.0, 1.0) * 255.0)); // Assuming pos range [0, 1] in a cell
    uint pos0y = uint(round(clamp(p0.pos.y, 0.0, 1.0) * 255.0));
    uint pos1x = uint(round(clamp(p1.pos.x, 0.0, 1.0) * 255.0));
    uint pos1y = uint(round(clamp(p1.pos.y, 0.0, 1.0) * 255.0));
    uint packedPos = (pos0x << 24) | (pos0y << 16) | (pos1x << 8) | pos1y;
    float posFloat = uintBitsToFloat(packedPos);

    // 3. Velocity
    uint vel0Packed = packvec3(vec3(p0.vel, 0.0));
    uint vel1Packed = packvec3(vec3(p1.vel, 0.0));

    float vel0Float = uintBitsToFloat(vel0Packed);
    float vel1Float = uintBitsToFloat(vel1Packed);

    return vec4(massFloat, posFloat, vel0Float, vel1Float);
}

void unpackParticles(vec4 packed, vec2 pos, out Particle p0, out Particle p1)
{
    // 1. Unpack Mass
    uint packedMass = floatBitsToUint(packed.x);
    p0.mass = (packedMass >> 16) & 0xFFFFu;
    p1.mass = packedMass & 0xFFFFu;

    // 2. Unpack Position
    uint packedPos = floatBitsToUint(packed.y);
    p0.pos.x = float((packedPos >> 24) & 0xFFu) / 255.0;
    p0.pos.y = float((packedPos >> 16) & 0xFFu) / 255.0;
    p1.pos.x = float((packedPos >> 8) & 0xFFu) / 255.0;
    p1.pos.y = float(packedPos & 0xFFu) / 255.0;

    p0.pos += pos;
    p1.pos += pos;

    // 3. Unpack Velocity
    uint vel0Packed = floatBitsToUint(packed.z);
    uint vel1Packed = floatBitsToUint(packed.w);
    p0.vel = unpackvec3(vel0Packed).xy;
    p1.vel = unpackvec3(vel1Packed).xy;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

int ClosestCluster(Particle p0, Particle p1, Particle incoming)
{
    //first try to choose the particle with significantly smaller mass
    if(float(p0.mass) < 0.01*float(p1.mass) || float(p1.mass) < 0.01*float(p0.mass))
    {
        return p0.mass < p1.mass ? 0 : 1;
    }

    //otherwise choose the closest one
    float d0 = length(p0.pos - incoming.pos);
    float d1 = length(p1.pos - incoming.pos);
    return d0 < d1 ? 0 : 1;
}

void BlendParticle(inout Particle p, in Particle incoming)
{
    uint newMass = p.mass + incoming.mass;
    vec2 weight = vec2(p.mass, incoming.mass) / float(newMass);
    p.pos = p.pos*weight.x + incoming.pos*weight.y;
    p.vel = p.vel*weight.x + incoming.vel*weight.y;
    p.mass = newMass;
}

void Clusterize(inout Particle p0, inout Particle p1, in Particle incoming, vec2 pos)
{
    //check if the incoming particle is in the cell
    if(!all(equal(pos, floor(incoming.pos))))
    {
        return;
    }

    int closest = ClosestCluster(p0, p1, incoming);
    if(closest == 0)
    {
        BlendParticle(p0, incoming);
    }
    else
    {
        BlendParticle(p1, incoming);
    }
}

void SplitParticle(inout Particle p1, inout Particle p2)
{
    float hash = fract(sin(p1.pos.x*54352354.5 + p1.pos.y*473594.5));
    uint newMass = p1.mass;
    p1.mass = newMass/2u;
    p2.mass = newMass - p1.mass;
    vec2 pos = p1.pos;
    vec2 weight = vec2(p1.mass, p2.mass)/float(newMass);
    vec2 dir = DIR(hash);
    p2.pos = p1.pos + dir*5e-3;
    p1.pos = p1.pos - dir*5e-3;
    p2.vel = p1.vel;
}


float border(vec2 p, vec2 iR)
{
    float bound = -sdBox(p+0.001 - iR*0.5, iR*vec2(0.49, 0.49)); 
    return bound;
}

#define h 1.
vec3 bN(vec2 p, vec2 iR)
{
    vec3 dx = vec3(-h,0,h);
    vec4 idx = vec4(-1./h, 0., 1./h, 0.25);
    vec3 r = idx.zyw*border(p + dx.zy, iR)
           + idx.xyw*border(p + dx.xy, iR)
           + idx.yzw*border(p + dx.yz, iR)
           + idx.yxw*border(p + dx.yx, iR);
    return vec3(normalize(r.xy), r.z + 1e-4);
}


void ApplyForce(inout Particle p, in Particle incoming)
{
    float d = distance(p.pos, incoming.pos);
    vec2 dir = (incoming.pos - p.pos)/max(d, 1e-5);
    vec2 dvel = incoming.vel - p.vel;
    float f = force_coef_a*GD(d, 1.5);
    float irho = float(incoming.mass);
    float rho = 0.5*(p.density + incoming.density);
    float pressure = max(rho / rest_density - 1.0,-0.0);
    float SPH_F = f *  pressure;
    float F = surface_tension*GD(d, surface_tension_rad);
    float Friction = viscosity * dot(dir, dvel) * GD(d, 2.5);
    p.force += force_k * dir * (F + SPH_F + Friction) * irho / rest_density;
    
}

void IntegrateParticle(inout Particle p, vec2 pos, vec2 iR, vec4 iM)
{
    p.force = p.force ;/// max(0.0001, float(p.mass));
    p.force += vec2(0.0, -gravity); //gravity
    
    vec3 BORD = bN(p.pos, iR);
    p.force += force_boundary * smoothstep(0., boundary_h, -BORD.z) * BORD.xy;
    
    p.force += vec2(0.0, 0.0)*GS(distance(p.pos, iR*vec2(0.2,0.5))/force_mouse_rad);
 
    if(iM.z > 0.)
    {
        vec2 dx = pos - iM.xy;
        p.force -= force_mouse*dx*GS(dx/force_mouse_rad);
    }
        
    p.vel += p.force * dt;
    p.pos += cooling * p.force * dt;

    //velocity limit
    float v = length(p.vel)/max_velocity;
    p.vel /= (v > 1.)?v:1.;
}