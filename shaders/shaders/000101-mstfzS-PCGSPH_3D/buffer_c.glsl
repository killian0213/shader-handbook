// Buffer C (buffer) — PCGSPH 3D by michael0884
// https://www.shadertoy.com/view/mstfzS

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
    vec2 densities = LOAD3D(ch1, pos).xy;
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
            
            vec2 densities_ = LOAD3D(ch1, pos1).xy;
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
    }
    
        
    if(iFrame < 10)
    {
        if(pos.x < 0.5*size3d.x && pos.x > 0.0*size3d.x && 
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

    packed = packParticles(p0, p1, pos);
    fragColor = packed;
}
