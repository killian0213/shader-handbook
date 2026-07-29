// Buffer C (buffer) — 3D Water Box Particles only by michael0884
// https://www.shadertoy.com/view/dstfRf

#define EMITTER_POS vec3(0.1,0.5,0.5)
#define EMITTER_RAD 4.0
#define EMITTER_VEL vec3(1.0, 0.0, 0.0)
#define EMITTER_NUM 1

#define VOID_POS vec3(0.8,0.5,0.1)
#define VOID_RAD 12.0

const int KEY_SPACE = 32;
const int KEY_LEFT  = 37;
const int KEY_UP    = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN  = 40;
bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,2), 0 ).x > 0.5;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    InitGrid(iResolution.xy);
    fragCoord = floor(fragCoord);
    vec3 pos = dim3from2(fragCoord);

    Particle p0, p1;
    
    //load the particles
    vec4 packed = LOAD3D(ch0, pos);
    unpackParticles(packed, pos, p0, p1);
    
    //load density
    vec2 densities = voxel(ch1, pos).xy;
    p0.density = densities.x;
    p1.density = densities.y;
    
    if(p0.mass + p1.mass > 0u) 
    {
        range(i, -2, 2) range(j, -2, 2) range(k, -2, 2)
        {
            if(i == 0 && j == 0 && k == 0) continue;
            vec3 pos1 = pos + vec3(i, j, k);
            Particle p0_, p1_;
            unpackParticles(LOAD3D(ch0, pos1), pos1, p0_, p1_);
            
            vec2 densities_ = voxel(ch1, pos1).xy;
            p0_.density = densities_.x;
            p1_.density = densities_.y;

            //apply the force
            ApplyForce(p0, p0_);
            ApplyForce(p0, p1_);
            ApplyForce(p1, p0_);
            ApplyForce(p1, p1_);
        }

        ApplyForce(p0, p1);
        ApplyForce(p1, p0);

        IntegrateParticle(p0, pos, iResolution.xy, iMouse, iTime);
        IntegrateParticle(p1, pos, iResolution.xy, iMouse, iTime);
        
        if(isKeyPressed(KEY_UP))
        {
            float void_d = distance(p0.pos, size3d*VOID_POS);
            if(void_d < VOID_RAD)
            {
                p0.mass = 0u;
            }
        }
    
        if(isKeyPressed(KEY_LEFT))
        {
            vec3 dx = normalize(p0.pos - size3d*0.5);
            p0.vel += vec3(dx.y, -dx.x, 0.0)*0.003;
        }
        
        if(isKeyPressed(KEY_RIGHT))
        {
            vec3 dx = normalize(p0.pos - size3d*0.5);
            p0.vel += vec3(-dx.y, dx.x, 0.0)*0.003;
        }
    }
    
        
    if(iFrame < 10)
    {
        if(pos.x < 0.4*size3d.x && pos.x > 0.0*size3d.x && 
           pos.y < 0.85*size3d.y && pos.y > 0.15*size3d.y &&
           pos.z < 0.85*size3d.z && pos.z > 0.15*size3d.z)
        {
            p0.mass = initial_particle_density;
            p1.mass = 0u;
        }

        p0.pos = pos;
        p0.vel = vec3(0.0);
        p1.pos = pos;
        p1.vel = vec3(0.0);
    }

    if(all(equal(p0.pos, p1.pos)))
    {
        p1.pos += 1e-2;
    }
    
    if(isKeyPressed(KEY_SPACE))
    {
    	float emitter_d = distance(pos, size3d*EMITTER_POS);
        if(emitter_d < EMITTER_RAD && int(pos.y) % 2 == 0 && int(pos.z) % 2 == 0 && int(pos.x) % 2 == 0)
        {
            Particle emit;
            emit.pos = pos;
            emit.mass = 1u;
            emit.vel = EMITTER_VEL;
            
            BlendParticle(p0, emit);
        }
    }
    
        
    packed = packParticles(p0, p1, pos);
    fragColor = packed;
}
