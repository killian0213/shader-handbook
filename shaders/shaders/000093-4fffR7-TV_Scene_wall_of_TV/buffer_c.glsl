// Buffer C (buffer) — TV Scene, wall of TV by morimea
// https://www.shadertoy.com/view/4fffR7


// Created by Danil (2024+) https://github.com/danilw
// https://mastodon.gamedev.place/@danil

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// using
// https://iquilezles.org/articles/intersectors/
// https://www.shadertoy.com/view/NlycW1



#define AA 0

void SetCamera(vec2 uv, out vec3 ro, out vec3 rd, vec2 ires);
void GroundIntersectMin(vec3 ro, vec3 rd, inout bool result, inout HitInfo hit);

bool minDist(vec3 ro, vec3 rd, out HitInfo hit)
{
    hit.t = MAX_DIST;
    hit.obj_type = OBJ_SKY;
    hit.color=vec4(vec3(0.),1.);
    bool result = false;

    VoxelsIntersectMin(ro.yxz, rd.yxz, result, hit, iChannel0, iChannel1, iTime, iResolution.xy);
    
    // TAA work better with this
    if(hit.obj_type == OBJ_SKY)hit.t = 4.;

    return result;
}

vec4 render(vec3 ro, vec3 rd)
{
    vec3 col = vec3(0.0);
    vec3 objectcolor = vec3(1.0);
    vec3 mask = vec3(1.0);
    HitInfo hit;
    hit.color=vec4(0.);
    {
        if(minDist(ro, rd, hit)){
            objectcolor = hit.color.rgb;
            vec3 p = ro + rd * hit.t + hit.norm*0.0001;
            col = objectcolor;
        }else col = vec3(0.);
    }
    return vec4(col, hit.t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   //discard;
    vec4 ret_col = vec4(0.0);
    vec3 ro; vec3 rd;
    vec2 h1 = (halton(iFrame % 360 + 1) - 0.5);
    #if AA>1
    for( int mx=0; mx<AA; mx++ )
    for( int nx=0; nx<AA; nx++ )
    {
    vec2 o = vec2(float(mx),float(nx)) / float(AA) - 0.5;
    vec2 uv = (fragCoord+o+h1)/iResolution.xy * 2.0 - 1.0;
    #else
    vec2 uv = (fragCoord+h1)/iResolution.xy * 2.0 - 1.0;
    #endif
    uv.y *= iResolution.y/iResolution.x;
    SetCamera(uv, ro, rd, iResolution.xy);
    vec4 col = render(ro, rd);
    ret_col += col;
    #if AA>1
    }
    ret_col /= float(AA*AA);
    #endif
    
    //ret_col.rgb = clamp(ret_col.rgb,0.,1.);
    
    fragColor = ret_col;
}



// camera
//----------------------------
#define load(P) texelFetch(iChannel1, ivec2(P), 0)
#define SS(x, y, z) smoothstep(x, y, z)

const ivec2 RES_LAST = ivec2(0, 0);
const ivec2 INIT = ivec2(0, 1);
const ivec2 TARGET = ivec2(0, 2);

const ivec2 tt_st = ivec2(1, 2);
const ivec2 POSITION = ivec2(1, 0);
const ivec2 POSITION_last = ivec2(1, 1);

const ivec2 INPUT = ivec2(3, 0);
const ivec2 PMOUSE = ivec2(3, 1);

vec3 l1Pos = vec3(2,1,0);

mat3 rotx(float a){float s = sin(a);float c = cos(a);return mat3(vec3(1.0, 0.0, 0.0), vec3(0.0, c, s), vec3(0.0, -s, c));  }
mat3 roty(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, 0.0, s), vec3(0.0, 1.0, 0.0), vec3(-s, 0.0, c));}
mat3 rotz(float a){float s = sin(a);float c = cos(a);return mat3(vec3(c, s, 0.0), vec3(-s, c, 0.0), vec3(0.0, 0.0, 1.0 ));}

mat3 rotationMatrix(vec2 m, float tt){
  mat3 rotX = mat3(1.0, 0.0, 0.0, 0.0, cos(m.y), sin(m.y), 0.0, -sin(m.y), cos(m.y));
  mat3 rotY = mat3(cos(m.x), 0.0, -sin(m.x), 0.0, 1.0, 0.0, sin(m.x), 0.0, cos(m.x));
  return rotY*rotX*rotz(-tt*0.175);
}

void SetCamera(vec2 uv, out vec3 ro, out vec3 rd, vec2 ires)
{
    ro = load(POSITION).xyz;
    vec2 m = vec2(-0.5*3.1415926+0.001, -0.0+0.001);
    m.y = -m.y;
    float fov=camera_fov;
    float aspect = ires.x / ires.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    rd = vec3(uv*screenSize, 1./aspect);
    
#ifdef cam_cyli
    // cylindrical perspective https://www.shadertoy.com/view/ftffWN
      float a = rd.x/rd.z;
      rd.xz = rd.z * vec2(sin(a),cos(a));
#endif
    //rd+=0.000001*(1.-abs(sign(rd)));
    rd = normalize(rd);
    
    
    float ltt = load(tt_st).x;
    rd = rotationMatrix(m,ltt) * rd;
}
//----------------------------









