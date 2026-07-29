// Buffer A (buffer) — Underwater Boids by michael0884
// https://www.shadertoy.com/view/WdSfzD

//L1 particle buffer - simulation
//L2 directional neighbor graph 4x - sort

int ID;
obj O; //this object

//sort arrays
vec4 lnk0, lnk1;
vec4 d0, d1;

//L3
vec4 EA[SN.x]; //element array

void insertion_sort(float t, int id);
obj getObj(int id); vec4 saveObj(int i);
bool iscoincidenceEA(int id);
void sort0(int idtemp, int D); void sort1(int idtemp, int D);

float Kernel(float d, float h)
{
    return exp(-sqr(d/h))/(PI*sqr(h));
}

float KernelGrad(float d, float h)
{
    return 2.*d*Kernel(d,h)/sqr(h);
}

vec2 borderF(vec2 p)
{
    
    float d = min(min(p.x,p.y),min(R.x-p.x,R.y-p.y));
    return exp(-max(d,0.)*max(d,0.))*((d==p.x)?vec2(1,0):(
    		(d==p.y)?vec2(0,1):(
            (d==R.x-p.x)?vec2(-1,0):vec2(0,-1))));
}

void UpdateParticle()
{
    vec3 g = -5e-9*O.X*length(O.X); 
    vec3 F = g; 
    
    float scale = 0.14*pow(density,-0.333); //radius of smoothing
    float Rho = Kernel(0., scale);
    float avgP = 0.;
	vec3  avgC = vec3(O.Color);

    loop(j,6)
    {
        vec4 nb = texel(ch0, i2xy(ivec3(ID, j, 1)));
        loop(i,3)
        {
            if(nb[i] < 0. || nb[i] > float(TN)) continue;
            obj nbO = getObj(int(nb[i]));

            float d = distance(O.X, nbO.X);
            vec3 dv = (nbO.V - O.V); //delta velocity
            vec3 dx = (nbO.X - O.X); //delta position 
            vec3 ndir = dx/(d+1e-3); //neighbor direction
            //SPH smoothing kernel
            float K = Kernel(d, scale);

            vec3 pressure = -0.5*( nbO.Pressure/sqr(nbO.Rho) + 
                                     O.Pressure/sqr(O.Rho) )*ndir*K;//pressure gradient
            vec3 viscosity = 0.6*ndir*dot(dv,ndir)/(d+1.);
           
            Rho += K;
            avgC += nbO.Color;
            avgP += nbO.Pressure*K;

            F += pressure + viscosity;
        }
    }

    O.Rho = Rho;
    
    //O.Scale = scale; //average distance
    
    float r = 1.;
    float D = 1.;
    float waterP = 0.02*(pow(abs(O.Rho/density), r) - D);
    O.Pressure = min(waterP,1.);

    O.V += F*dt;
    O.V = 0.15*normalize(O.V);
    O.X += O.V*dt; //advect

    //color diffusion

    //O.Color = ;
}

void mainImage( out vec4 Q, in vec2 pos )
{
    //4 pix per layer, 3 layers
    sN = SN; 
    N = ivec2(R*P/vec2(sN));
    TN = N.x*N.y;
    int S = 3; //log2(sN.x)
    
    ivec2 p = ivec2(floor(pos));
    if(any(greaterThan(p, sN*N-1))) discard;
   
    ivec3 sid = xy2i(p); ID = sid.x;
    O = getObj(ID);
    d0 = vec4(1e6); d1 = vec4(1e6);
    lnk0 = vec4(-1); lnk1 = vec4(-1);
    
    switch(sid.z)
    {
    case 0: //particle
        if(sid.z >= 3) discard;
        float sk = 0.;
        
        UpdateParticle();
        
        if(iFrame<10 || O.Scale != 5.)
        {
            O.X = 300.*(hash32(pos) - 0.5);
			O.V = 0.1*(hash32(3.14159*pos) - 0.5);
            O.Color = hash32(3.14159*pos);
            O.Pressure = 0.;
            O.Scale = 5.;
            O.Rho = 5.;
        }

        Q = saveObj(sid.y);
        return;
        
    case 1: //dir graph
        //sort neighbors and neighbor neighbors
        vec4 nb0 = texel(ch0, i2xy(ivec3(ID, sid.y, 1)));
        loop(i,4)
        {
            sort0(int(nb0[i]), sid.y);  //sort this
            //use a sudorandom direction of the neighbor
            vec4 nb1 = texel(ch0, i2xy(ivec3(nb0[i], (iFrame+ID)%4, 1)));
            loop(j,2)
            {
                sort0(int(nb1[j]), sid.y);  
            }
        }
        
        //random sorts
        loop(i,4) sort0(int(float(TN)*hash13(vec3(iFrame, ID, i))), sid.y);
        
        Q = lnk0;
        return;
    }
     
}

vec4 saveObj(int i)
{
    switch(i)
    {
    case 0:  
        return vec4(O.X, O.Rho);
    case 1:
        return vec4(O.V, O.Pressure);
    case 2:
        return vec4(O.Color, O.Scale);
    }
}

obj getObj(int id)
{
    obj o;
    
    vec4 a = texel(ch0, i2xy(ivec3(id, 0, 0))); 
    o.X = a.xyz; o.Rho = a.w;
    a = texel(ch0, i2xy(ivec3(id, 1, 0))); 
    o.V = a.xyz; o.Pressure = a.w; 
    a = texel(ch0, i2xy(ivec3(id, 2, 0))); 
    o.Color = a.xyz; o.Scale = a.w;
 
    o.id = id;
    return o;
}

void insertion_sort(float t, int id)
{
	if(d0.x > t)
    {
        d0 = vec4(t, d0.xyz);
        lnk0 = vec4(id, lnk0.xyz);
    }else if(d0.y > t && d0.x < t)
    {
        d0.yzw = vec3(t, d0.yz);
        lnk0.yzw = vec3(id, lnk0.yz);
    }else if(d0.z > t&& d0.y < t)
    {
        d0.zw = vec2(t, d0.z);
        lnk0.zw = vec2(id, lnk0.z);
    }else if(d0.w > t && d0.z < t)
    {
        d0.w = t;
        lnk0.w = float(id);
    }
}

bool iscoincidence(int id)
{
    return (id < 0) || 
      	   (id == ID) ||
           any(equal(lnk0,vec4(id)));
}

void sort0(int idtemp, int D) //sort closest objects in sN.x directions
{
    if(iscoincidence(idtemp)) return; //particle already sorted
    
    vec3 nbX = texel(ch0, i2xy(ivec3(idtemp, 0, 0))).xyz; 
   
    vec3 dx = nbX - O.X;
    int dir = int(inverseSF(dx, float(sN.x)).x);
    
    if(dir != D) return; //not in this sector
    
    float t = length(dx);
   
    insertion_sort(t, idtemp);
}