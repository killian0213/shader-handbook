// Buffer B (buffer) — Fully ray traced water by michael0884
// https://www.shadertoy.com/view/w3sXzs

bool isKeyPressed(int KEY)
{
	return texelFetch( iChannel3, ivec2(KEY,2), 0 ).x > 0.5;
}

void AddDensity(inout Particle p, in Particle incoming, float rad)
{
    if(incoming.mass == 0u) return;
    float d = distance(p.pos, incoming.pos);
    float mass = float(incoming.mass);
    p.density += mass*GD(d,rad);
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
        int dist = i*i + j*j + k*k;
        if(dist == 0 || dist > 16) continue;
        vec3 pos1 = pos + vec3(i, j, k);
        Particle p0_, p1_;
        unpackParticles(LOAD3D(ch0, pos1), pos1, p0_, p1_);

        if(p0.mass > 0u)
        {
            AddDensity(p0, p0_, KERNEL_RADIUS);
            AddDensity(p0, p1_, KERNEL_RADIUS);
        }
        if(p1.mass > 0u)
        {
            AddDensity(p1, p0_, KERNEL_RADIUS);
            AddDensity(p1, p1_, KERNEL_RADIUS);
        }
        
        AddDensity(pV, p0_, RENDER_KERNEL_RADIUS);
        AddDensity(pV, p1_, RENDER_KERNEL_RADIUS);
    }

    if(p0.mass > 0u)
    {
        AddDensity(p0, p0, KERNEL_RADIUS);
        AddDensity(p0, p1, KERNEL_RADIUS);
    }
    if(p1.mass > 0u)
    {
        AddDensity(p1, p0, KERNEL_RADIUS);
        AddDensity(p1, p1, KERNEL_RADIUS);
    }
    AddDensity(pV, p0, RENDER_KERNEL_RADIUS);
    AddDensity(pV, p1, RENDER_KERNEL_RADIUS);
    
    if(any(lessThan(pos, vec3(1.0))) || any(greaterThan(pos, size3d - 2.0))) pV.density = 0.0;

    fragColor = vec4(p0.density, p1.density, pV.density, 0.0);
}
