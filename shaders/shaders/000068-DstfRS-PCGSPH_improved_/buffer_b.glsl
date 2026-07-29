// Buffer B (buffer) — PCGSPH (improved) by michael0884
// https://www.shadertoy.com/view/DstfRS

void AddDensity(inout Particle p, in Particle incoming)
{
    float d = distance(p.pos, incoming.pos);
    float irho = float(incoming.mass);
    float rho = irho*GD(d,2.0);
    p.density += rho;
}


//compute particle SPH densities
void mainImage( out vec4 fragColor, in vec2 pos )
{
    pos = floor(pos);
    Particle p0, p1;
    
    //load the particles
    vec4 packed = LOAD(ch0, pos);
    unpackParticles(packed, pos, p0, p1);
    
    if(p0.mass + p1.mass > 0u) 
    {
        range(i, -2, 2) range(j, -2, 2)
        {
            if(i == 0 && j == 0) continue;
            //load the particles 
            vec2 pos1 = pos + vec2(i, j);
            Particle p0_, p1_;
            unpackParticles(LOAD(ch0, pos1), pos1, p0_, p1_);

            AddDensity(p0, p0_);
            AddDensity(p0, p1_);
            AddDensity(p1, p0_);
            AddDensity(p1, p1_);
        }

        AddDensity(p0, p1);
        AddDensity(p0, p0);
        AddDensity(p1, p0);
        AddDensity(p1, p1);
    }

    fragColor = vec4(p0.density, p1.density, 0.0, 0.0);
}
