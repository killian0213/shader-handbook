// Buffer B (buffer) — Underwater Boids by michael0884
// https://www.shadertoy.com/view/WdSfzD

//voronoi 3d particle tracking + graph augmented

mat4 rotat; //rotation matrix
mat4 model; //model matrix
mat4 imat;


vec3 ray; vec3 cpos;
float d;
vec3 ip;
int id;
vec2 p; //screen coord
vec2 angles;

float sphere_intersection(vec3 r, vec3 p, vec4 sphere)
{
	p = p - sphere.xyz;
	if(p == vec3(0)) return sphere.w;
	
	float b = dot(p, r);
	float c = sphere.w*sphere.w - dot(p,p);
	float d = b*b + c;
	
	if((d <= 0.)) //if no intersection
	{
		return -length(cross(r, p)); //return closest dist
	}
	else
	{
		return -sqrt(d) - b; //use closest solution in the direction of the ray
	}
}

vec4 ppos(int id)
{
	return vec4(texel(ch0, i2xy(ivec3(id, 0, 0))).xyz,1.);
}

vec3 getRay(vec2 pos)
{
    mat3 rmat = getRot(angles);
    vec2 uv = FOV*(pos - R*0.5)/R.x;
    return normalize(rmat[0]*uv.x + rmat[1]*uv.y + rmat[2]);
}

float zrange(float z)
{
    return clamp(z/range,0.,1.);
}

vec4 point_distance(int id, float r)
{
    vec4 X = ppos(id);
    float cd = sphere_intersection(ray, cpos, vec4(X.xyz,r));
    if(cd > 0.)
    {
        return vec4(cpos + cd*ray, zrange(cd));
    }
    else
    {
        return vec4(cpos + 1e8*ray, 1.+abs(cd));
    }
}

void sort(int utemp)
{
    if(utemp < 0) return; 
   	vec4 dtemp = point_distance(utemp, 1.5);
    if(dtemp.w < d) //sorting
    {
        d = dtemp.w;
        ip = dtemp.xyz;
        id = utemp;
    }
}


void mainImage( out vec4 Q, in vec2 pos )
{
    sN = SN; 
    N = ivec2(R*P/vec2(sN));
    TN = N.x*N.y;
    d = 1e10;
    id = 1;
    p = pos;
    ip = vec3(1e10);
    ivec2 pi = ivec2(floor(pos));
    
   
    //set up camera 
    angles = (iMouse.z>0.)?(iMouse.xy/R)*vec2(2.*PI, PI):vec2(0.15*iTime, PI*0.2+0.5*sin(0.15*iTime));
    ray = getRay(pos); 
    cpos = -camd*getRay(R*0.5);
    
    /// sort pixels
    sort(int(texel(ch1, pi).x));
    
    int ID = id;
    loop(j,12)
    {
        
        int nbid = int(texel(ch1, pi+cross_distribution(j)).x);
        sort(nbid);
    }
    
    loop(j,int(sN.x))
    {
        vec4 nb = texel(ch0, i2xy(ivec3(ID, j, 1)));
        loop(i,4)
    	{ 
            sort(int(nb[i]));  //sort this
        }
    }
    
    loop(i,4) //random sort
    {
        sort(int(float(TN)*hash13(vec3(iFrame, pi.x, pi.y*i))));
    }
    ///
    
    
    //save
   	Q = vec4(id, ip);
}