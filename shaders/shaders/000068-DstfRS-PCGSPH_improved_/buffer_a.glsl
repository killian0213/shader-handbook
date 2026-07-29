// Buffer A (buffer) — PCGSPH (improved) by michael0884
// https://www.shadertoy.com/view/DstfRS

void mainImage( out vec4 fragColor, in vec2 pos )
{
    pos = floor(pos);
    Particle p0, p1;

    p0.mass = 0u;
    p0.pos = vec2(0.0, 0.0);
    p0.vel = vec2(0.0, 0.0);

    p1.mass = 0u;
    p1.pos = vec2(0.0, 0.0);
    p1.vel = vec2(0.0, 0.0);

    //advect neighbors and accumulate + clusterize density if they fall into this cell
    range(i, -2, 2) range(j, -2, 2)
    {
        //load the particles 
        vec2 pos1 = pos + vec2(i, j);
        Particle p0_, p1_;
        unpackParticles(LOAD(ch0, pos1), pos1, p0_, p1_);
        
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
    
    if(iFrame < 10)
    {
        if(pos.x < 0.65*R.x && pos.x > 0.35*R.x && pos.y < 0.65*R.y && pos.y > 0.35*R.y)
        {
            p0.mass = initial_particle_density;
            p1.mass = 0u;
        }

        p0.pos = pos+vec2(0.2, 0.2);
        p0.vel = vec2(0., 0.);
        p1.pos = pos+vec2(0.75, 0.75);
        p1.vel = vec2(0.25, 0.25);
    }

    vec4 packed = packParticles(p0, p1, pos);
    fragColor = packed;
}