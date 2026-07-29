// Buffer C (buffer) — PCGSPH (improved) by michael0884
// https://www.shadertoy.com/view/DstfRS

void mainImage( out vec4 fragColor, in vec2 pos )
{
    pos = floor(pos);
    Particle p0, p1;
    
    //load the particles
    vec4 packed = LOAD(ch0, pos);
    unpackParticles(packed, pos, p0, p1);
    
    //load density
    vec2 densities = LOAD(ch1, pos).xy;
    p0.density = densities.x;
    p1.density = densities.y;
    
    if(p0.mass + p1.mass > 0u) 
    {
        range(i, -2, 2) range(j, -2, 2)
        {
            if(i == 0 && j == 0) continue;
            //load the particles 
            vec2 pos1 = pos + vec2(i, j);
            Particle p0_, p1_;
            unpackParticles(LOAD(ch0, pos1), pos1, p0_, p1_);
            
            vec2 densities_ = LOAD(ch1, pos1).xy;
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

        IntegrateParticle(p0, pos, iResolution.xy, iMouse);
        IntegrateParticle(p1, pos, iResolution.xy, iMouse);
    }

    packed = packParticles(p0, p1, pos);
    fragColor = packed;
}
