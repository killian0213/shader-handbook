// Buffer B (buffer) — Fluidic Boids by davidar
// https://www.shadertoy.com/view/fs3XDM

// reintegration tracking code from https://www.shadertoy.com/view/ttBcWm
#define Bi(p) ivec2(mod(p,iResolution.xy))
#define texel(a, p) texelFetch(a, Bi(p), 0)

#define range(i,a,b) for(int i = a; i <= b; i++)

#define dt 1.5

vec3 distribution(vec2 x, vec2 p, float K)
{
    vec4 aabb0 = vec4(p - 0.5, p + 0.5);
    vec4 aabb1 = vec4(x - K*0.5, x + K*0.5);
    vec4 aabbX = vec4(max(aabb0.xy, aabb1.xy), min(aabb0.zw, aabb1.zw));
    vec2 center = 0.5*(aabbX.xy + aabbX.zw); //center of mass
    vec2 size = max(aabbX.zw - aabbX.xy, 0.); //only positive
    float m = size.x*size.y/(K*K); //relative amount
    //if any of the dimensions are 0 then the mass is 0
    return vec3(center, m);
}

//diffusion and advection basically
void Reintegration(sampler2D ch, inout particle P, vec2 pos)
{
    //basically integral over all updated neighbor distributions
    //that fall inside of this pixel
    //this makes the tracking conservative
    range(i, -2, 2) range(j, -2, 2)
    {
        vec2 tpos = pos + vec2(i,j);
        vec4 data = texel(ch, tpos);
       
        particle P0 = getParticle(data, tpos);
       
        P0.X += P0.V*dt; //integrate position

        vec3 D = distribution(P0.X, pos, DIFFUSION);
        //the deposited mass into this cell
        float m = P0.M*D.z;
        
        //add weighted by mass
        P.X += D.xy*m;
        P.V += P0.V*m;
        
        //add mass
        P.M += m;
    }
    
    //normalization
    if(P.M != 0.)
    {
        P.X /= P.M;
        P.V /= P.M;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    particle P;
    Reintegration(iChannel0, P, fragCoord);
    fragColor = saveParticle(P, fragCoord);
}