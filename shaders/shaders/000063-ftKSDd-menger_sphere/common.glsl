// Common (common) — menger sphere by jorge2017a2
// https://www.shadertoy.com/view/ftKSDd

//----------common
struct TObj
{
    float id_color;
    float id_objeto;
    float id_material;
    float dist;
    vec3 normal;
    vec3 ro;
    vec3 rd;
    vec2 uv;
    vec3 color;
    vec3 p;
    vec3 phit; //22-mar-2021
    vec3 rf;
    float marchCount;
    bool blnShadow;
    bool hitbln;
};

    
TObj mObj;
vec3 glpRoRd;
vec2 gres2;
float itime;

#define PI 3.14159265358979323846264
#define MATERIAL_NO -1.0
#define COLOR_NO -1.0
#define COLORSKY vec3(0.1, 0.1, 0.6)



///Gracias a SHane...16-jun-2020
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){    
    n = max(n*n - .2, .001); // max(abs(n), 0.001), etc.
    n /= dot(n, vec3(1)); 
    vec3 tx = texture(tex, p.yz).xyz;
    vec3 ty = texture(tex, p.zx).xyz;
    vec3 tz = texture(tex, p.xy).xyz;
    return mat3(tx*tx, ty*ty, tz*tz)*n; 
}


vec3  Arrcolores[] = vec3[] (
vec3(0,0,0),  //0
vec3(1.,1.,1.), //1
vec3(1,0,0),  //2
vec3(0,1,0),   //3
vec3(0,0,1),   //4
vec3(1,1,0),  //5
vec3(0,1,1),  //6 
vec3(1,0,1),   //7
vec3(0.7529,0.7529,0.7529),  //8
vec3(0.5,0.5,0.5),  //9
vec3(0.5,0,0),   //10
vec3(0.5,0.5,0.0),  //11
vec3(0,0.5,0),   //12
vec3(0.5,0,0.5),  //13
vec3(0,0.5,0.5),  //14
vec3(0,0,0.5),    //15
vec3(1.0, 0.8, 0.737),  //16
vec3(0.8, 0.8, 0.8),  //17
vec3(0.5, 0.5, 0.8),  //18
vec3(1, 0.5, 0),      //19
vec3(1.0, 1.0, 1.0),  //20
vec3(0.968,0.6588,  0.721),  //21
vec3(0, 1, 1),                           //22 
vec3(0.333, 0.803, 0.988),    //23
vec3(0.425, 0.56, 0.9)*vec3( 0.3, 0.2, 1.0 ),  //24 
vec3(0.8,0.8,0.8)*vec3( 0.3, 0.2, 1.0 ),       //25  
vec3(1.0,0.01,0.01)*vec3( 0.3, 0.2, 1.0 ),     //26
vec3(0.1, 0.5, 1.0),                           //27   
vec3(0.0, 0.6, 0.0),                       //28 
vec3(0.1,0.1,0.7),                          //29
vec3(0.99, 0.2, 0.1), //30
vec3(.395, .95, 1.), //31
vec3(0.425, 0.56, 0.9) 
);

vec3 getColor(int i)
{    
    if (i==-2 ) {return mObj.color; }       
    if (i>-1 ) 
		return Arrcolores[i];
}

