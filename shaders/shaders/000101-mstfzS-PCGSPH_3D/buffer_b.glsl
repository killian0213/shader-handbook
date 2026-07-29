// Buffer B (buffer) — PCGSPH 3D by michael0884
// https://www.shadertoy.com/view/mstfzS

void AddDensity(inout Particle p, in Particle incoming, float rad)
{
    if(incoming.mass == 0u) return;
    float d = distance(p.pos, incoming.pos);
    float irho = float(incoming.mass);
    float rho = 0.25*irho*GD(d,rad);
    p.density += rho;
}

//compute particle SPH densities
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    InitGrid(iResolution.xy);
    fragCoord = floor(fragCoord);
    vec3 pos = dim3from2(fragCoord);
    
    Particle p0, p1, pV;
    pV.pos = pos + 0.5;
    
    //load the particles
    vec4 packed = LOAD3D(ch0, pos);
    unpackParticles(packed, pos, p0, p1);
    
    range(i, -2, 2) range(j, -2, 2) range(k, -2, 2)
    {
        if(i == 0 && j == 0 && k == 0) continue;
        vec3 pos1 = pos + vec3(i, j, k);
        Particle p0_, p1_;
        unpackParticles(LOAD3D(ch0, pos1), pos1, p0_, p1_);

        if(p0.mass > 0u)
        {
            AddDensity(p0, p0_, 1.5);
            AddDensity(p0, p1_, 1.5);
        }
        if(p1.mass > 0u)
        {
            AddDensity(p1, p0_, 1.5);
            AddDensity(p1, p1_, 1.5);
        }
        
        AddDensity(pV, p0_, 1.2);
        AddDensity(pV, p1_, 1.2);
    }

    if(p0.mass > 0u)
    {
        AddDensity(p0, p0, 1.5);
        AddDensity(p0, p1, 1.5);
    }
    if(p1.mass > 0u)
    {
        AddDensity(p1, p0, 1.5);
        AddDensity(p1, p1, 1.5);
    }
    AddDensity(pV, p0, 1.2);
    AddDensity(pV, p1, 1.2);

    fragColor = vec4(p0.density, p1.density, pV.density, 0.0);
}
