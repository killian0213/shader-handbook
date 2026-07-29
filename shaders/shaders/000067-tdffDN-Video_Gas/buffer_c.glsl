// Buffer C (buffer) — Video Gas by michael0884
// https://www.shadertoy.com/view/tdffDN

//4th order voronoi particle tracking 

ivec4 get(ivec2 p)
{
    return ivec4(floor(texel(ch0, p)));
}

vec4 save(ivec4 v)
{
    return vec4(v);
}

ivec4 u; //ids
vec4 d; //distances
vec2 pos; //pixel position

vec4 getParticle(int id)
{
    return texel(ch1, i2xy(id));
}

float particleDistance(int id, vec2 p)
{
    return distance(p, getParticle(id).xy);
}

//insertion sort
void sort(int utemp)
{
    if(utemp <0) return; 
   	float dtemp = particleDistance(utemp, pos);
    //sorting
    if(d.x > dtemp)
    {
        d = vec4(dtemp, d.xyz);
        u = ivec4(utemp, u.xyz);
    }
    else if(d.y > dtemp && dtemp > d.x)
    {
        d.yzw = vec3(dtemp, d.yz);
        u.yzw = ivec3(utemp, u.yz);
    }
    else if(d.z > dtemp && dtemp > d.y)
    {
        d.zw = vec2(dtemp, d.z);
        u.zw = ivec2(utemp, u.z);
    }
    else if(d.w > dtemp && dtemp > d.z)
    {
        d.w = dtemp;
        u.w = utemp;
    }
}

void sortpos(ivec2 p)
{
    ivec4 nb = get(p);
    for(int j = 0; j < 4; j++)
    {
        sort(nb[j]);
    }
}

void mainImage( out vec4 U, in vec2 fragCoord )
{
    pos = fragCoord;
     N = ivec2(prop*iResolution.xy);
    tot_n = N.x*N.y;
    ivec2 p = ivec2(pos);
     
    u = ivec4(-1); d = vec4(1e10); 
   
    //jump flood sorting 
    sortpos(p); //resort this position
    for(int i = 0; i < 8; i++)
    {
        sortpos(p+cross_distribution(i)); 
    }
    
    for(int i = 0; i < 4; i++)
    {
        sort(hash(ivec4(p, iFrame, i)).x%tot_n); //random sort    
    }
    
    if( any(lessThan(u, ivec4(-1))) || any(greaterThan(u, ivec4(tot_n))) )
    {
        u = ivec4(0);
    }
    
    U = save(u);
}