// Buffer A (buffer) — Anisotropic surface reconstruct by michael0884
// https://www.shadertoy.com/view/csdfD2

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    InitGrid(iResolution.xy);
    fragCoord = floor(fragCoord);
    vec3 pos = dim3from2(fragCoord);
    
    Particle p0, p1;

    //advect neighbors and accumulate + clusterize density if they fall into this cell
    range(i, -1, 1) range(j, -1, 1) range(k, -1, 1)
    {
        //load the particles 
        vec3 pos1 = pos + vec3(i, j, k);
        if(!all(lessThanEqual(pos1, size3d)) || !all(greaterThanEqual(pos1, vec3(0.0))))
        {
            continue;
        }
        Particle p0_, p1_;
        unpackParticles(LOAD3D(ch0, pos1), pos1, p0_, p1_);
        
        if(p0_.mass > 0u)
        {
            p0_.pos += p0_.vel*dt;
            Clusterize(p0, p1, p0_, pos);
        }
   
        if(p1_.mass > 0u)
        {
            p1_.pos += p1_.vel*dt;
            Clusterize(p0, p1, p1_, pos);
        }
    }
    
    if(p1.mass == 0u && p0.mass > 0u)
    {
        SplitParticle(p0, p1);
    }

    if(p0.mass == 0u && p1.mass > 0u)
    {
        SplitParticle(p1, p0);
    }
    
    vec4 packed = packParticles(p0, p1, pos);
    fragColor = packed;
}