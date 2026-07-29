// Buffer B (buffer) — Video Gas by michael0884
// https://www.shadertoy.com/view/tdffDN

//sorting closest 4 particles in axis directions that make a bounding box
//only in particle space, texture buffer not needed

ivec4 get(int id)
{
    return ivec4(floor(texel(ch0, i2xy(id))));
}

vec4 save(ivec4 v)
{
    return vec4(v);
}

ivec4 u; //ids
vec4 d; //distances
vec2 pos; //this particle position
int tid;

vec4 getParticle(int id)
{
    return texel(ch1, i2xy(id));
}

//insertion sort
void sort(int utemp)
{
    if(utemp == tid || utemp < 0) return;
     
   	vec4 part = getParticle(utemp);
    vec2 dx = part.xy - pos;
    float dtemp = length(dx);
    //sorting
    if(dx.x > abs(dx.y))
    {
        if(d.x > dtemp) 
        {
            d.x = dtemp;
        	u.x = utemp;
        }
    }
    else if(dx.x < -abs(dx.y))
    {
        if(d.y > dtemp) 
        {
            d.y = dtemp;
        	u.y = utemp;
        }
    }
    else if(dx.y > abs(dx.x))
    {
        if(d.z > dtemp) 
        {
            d.z = dtemp;
        	u.z = utemp;
        }
    }
    else if(d.w > dtemp) 
    {
        d.w = dtemp;
        u.w = utemp;
    }
}

void sortneighbor(int id)
{
    ivec4 nb = get(id);
    for(int j = 0; j < 4; j++)
    {
        sort(nb[j]);
    }
}

void mainImage( out vec4 U, in vec2 fragCoord )
{  
    ivec2 p = ivec2(fragCoord);
    N = ivec2(prop*iResolution.xy);
    tot_n = N.x*N.y;
    if(p.x > N.x || p.y > N.y) discard;
    
    int id = xy2i(p);
     
    u = ivec4(-1); d = vec4(1e10); 
   
    tid = id;
    pos = getParticle(id).xy;
    
    sortneighbor(id); 
    
    for(int i = 0; i < 8; i++)
    {
        sort(hash(ivec4(p, iFrame, i)).x%tot_n); //random sort    
    }
    
    ivec4 nb = get(id);
    for(int i = 0; i < 4; i++)
    {
        sortneighbor(nb[i]); 
    }
    
    if( any(lessThan(u, ivec4(-1))) || any(greaterThan(u, ivec4(tot_n))))
    {
        u = ivec4(0);
    }
    
    
    U = save(u);
}