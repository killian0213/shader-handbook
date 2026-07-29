// Buffer A (buffer) — Video Gas by michael0884
// https://www.shadertoy.com/view/tdffDN

//particle buffer

int cid;

ivec4 get(int id)
{
    return ivec4(texel(ch0, i2xy(id)));
}

vec4 getParticle(int id)
{
    return texel(ch1, i2xy(id));
}

float F(float d)
{
    return (0.15*exp(-0.1*d) - 2.*exp(-0.2*d));
}

float imageV(vec2 p)
{
    return 1.-2.*texture(ch2, vec2(1., 1.)*p/size).x;
}

vec2 imageF(vec2 p)
{
    vec3 d = vec3(-1,0,1);
    return vec2(imageV(p+d.zy) - imageV(p+d.xy), imageV(p+d.yz) - imageV(p+d.yx));
}

vec2 Fv(vec4 p0, int pid)
{
    if(pid < 0 || pid >= tot_n || pid == cid) return vec2(0); 
   	vec4 p1 = getParticle(pid);
    float d= distance(p0.xy, p1.xy);
    vec2 dv = (p1.zw - p0.zw);
    float dotv = dot(normalize(p1.xy-p0.xy), normalize(dv)); //divergence correction
    vec2 antidivergence = 0.*dv*abs(dotv)*exp(-0.5*d);
    vec2 viscosity = 0.25*dv*exp(-0.1*d);
    vec2 pressure = normalize(p1.xy-p0.xy)*F(d);
    return viscosity + pressure + antidivergence;
}

float irad;

vec2 Fspring(vec4 p0, int pid)
{
    if(pid < 0 || pid >= tot_n || pid == cid) return vec2(0); 
   	vec4 p1 = getParticle(pid);
    vec2 interaction = normalize(p1.xy-p0.xy)*(distance(p1.xy,p0.xy)- 2.*PI*irad/float(tot_n) - 4.*tanh(0.1*iTime));
    return interaction;
}

void mainImage( out vec4 U, in vec2 pos )
{
    ivec2 p = ivec2(pos);
    N = ivec2(prop*iResolution.xy);
    tot_n = N.x*N.y;
    if(p.x < N.x && p.y < N.y)
    {
        irad = 0.3*size.y;
        pos = floor(pos);
        //this pixel value
        U = texel(ch1, pos);
        int id = xy2i(p);
        cid = id;
        
        //this pixel value
        if(iFrame<10)
        {
            float t = 2.*PI*float(id)/float(tot_n);
            U.xy = size*hash22(3.14159*pos);
			U.zw = 1.*(hash22(3.14159*pos) - 0.5);
      		return;
        }
        
        //neighbors
   		ivec4 cp = get(id);
   	  
        vec2 F = Fv(U, cp.x) +
            	 Fv(U, cp.y) +
            	 Fv(U, cp.z) +
                 Fv(U, cp.w) +
            	 -20.*imageF(U.xy);
        
        if(iMouse.z > 0.) 
        {
            float d = distance(iMouse.xy, U.xy);
            F += 2.*normalize(iMouse.xy - U.xy)/(sqrt(d)+2.);
        }
        
        U.zw = 15.*tanh((F*dt + U.zw)/15.) ;
        U.xy += U.zw*dt;
        
        //border conditions
        if(size.x - U.x < 2.) U.z = -abs(U.z);
        if(U.x < 2.) U.z = abs(U.z);
        if(size.y - U.y < 2.) U.w = -abs(U.w);
        if(U.y < 2.) U.w = abs(U.w);
 
        
    }
    else discard;
}