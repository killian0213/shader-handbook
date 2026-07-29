// Buffer D (buffer) — TV Scene, wall of TV by morimea
// https://www.shadertoy.com/view/4fffR7


// TAA from https://www.shadertoy.com/view/dldGWj

// MODIFIED do not use

#define use_dynamic_TAA

#ifndef use_dynamic_TAA
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    discard;
}
#else

// from https://www.shadertoy.com/view/DsfGWX

void SetCamera(vec2 uv, out vec3 ro, out vec3 rd, vec2 ires);
void SetCamera_prev(vec2 uv, out vec3 ro, out vec3 rd, vec2 ires);
vec2 pos2uv(vec3 pos, vec2 ires);
#define load(P) texelFetch(iChannel1, ivec2(P), 0)
const ivec2 RES_LAST_LAST = ivec2(3, 2);

#define ENABLE_TAA
#define TEMPORAL_REPROJECT

#define VARIANCE_CLIPPING

// debug
//#define SHOW_MOTION
//#define SHOW_DISOCCLUSION

// TAA
// alpha of this shader is unused, it used to store curr_d but hist.a used only in SHOW_DISOCCLUSION

#define EPS 1e-4



#define OFFSET_COUNT 4

const ivec2 off[OFFSET_COUNT] = ivec2[OFFSET_COUNT](
 	ivec2( 1,  0), ivec2( 0, -1), 
	ivec2( 0,  1), ivec2(-1,  0)
);
/*
#define OFFSET_COUNT 8

const ivec2 off[OFFSET_COUNT] = ivec2[OFFSET_COUNT](
    ivec2(-1, -1), ivec2(-1,  1), 
	ivec2( 1, -1), ivec2( 1,  1), 
	ivec2( 1,  0), ivec2( 0, -1), 
	ivec2( 0,  1), ivec2(-1,  0)
);
*/


vec3 rgb2ycocg(in vec3 rgb)
{
return rgb;
    float co = rgb.r - rgb.b;
    float t = rgb.b + co / 2.0;
    float cg = rgb.g - t;
    float y = t + cg / 2.0;
    return vec3(y, co, cg);
}


vec3 ycocg2rgb(in vec3 ycocg)
{
return ycocg;
    float t = ycocg.r - ycocg.b / 2.0;
    float g = ycocg.b + t;
    float b = t - ycocg.g / 2.0;
    float r = ycocg.g + b;
    return vec3(r, g, b);
}

vec3 RGBtoYCoCg(vec3 c)
{
return c;
    //return rgb2ycocg(c);
    return mat3(0.25, 0.5, -0.25, 0.5, 0, 0.5, 0.25, -0.5, -0.25) * c;
}

vec3 YCoCgToRGB(vec3 c)
{
return c;
    //return ycocg2rgb(c);
    return mat3(1, 1, 1, 1, 0, -1, -1, 1, -1) * c;
}

vec4 clipToAABB(in vec4 cOld, in vec4 cNew, in vec4 center, in vec4 halfSize)
{
    vec4 r = cOld - cNew;
    vec4 m = (center + halfSize) - cNew;
    vec4 n = (center - halfSize) - cNew;
    
    if (r.x > m.x + EPS)
		r *= (m.x / r.x);
	if (r.y > m.y + EPS)
		r *= (m.y / r.y);
	if (r.z > m.z + EPS)
		r *= (m.z / r.z);
    if (r.w > m.w + EPS)
		r.w *= (m.w / r.w);

	if (r.x < n.x - EPS)
		r *= (n.x / r.x);
	if (r.y < n.y - EPS)
		r *= (n.y / r.y);
	if (r.z < n.z - EPS)
		r *= (n.z / r.z);
    if (r.w < n.w - EPS)
		r.w *= (n.w / r.w);

	return cNew + r;
}

vec4 SampleTextureCatmullRom(sampler2D tex, vec2 texSize, vec2 uv)
{
    vec2 samplePos = uv * texSize;
    vec2 texPos1 = floor(samplePos - 0.5) + 0.5;

    vec2 f = samplePos - texPos1;

    vec2 w0 = f * ( -0.5 + f * (1.0 - 0.5*f));
    vec2 w1 = 1.0 + f * f * (-2.5 + 1.5*f);
    vec2 w2 = f * ( 0.5 + f * (2.0 - 1.5*f) );
    vec2 w3 = f * f * (-0.5 + 0.5 * f);
    
    vec2 w12 = w1 + w2;
    vec2 offset12 = w2 / w12;

    vec2 texPos0 = texPos1 - vec2(1.0);
    vec2 texPos3 = texPos1 + vec2(2.0);
    vec2 texPos12 = texPos1 + offset12;

    texPos0 /= texSize;
    texPos3 /= texSize;
    texPos12 /= texSize;

    vec4 result = vec4(0.0);
    result += textureLod(tex, vec2(texPos0.x,  texPos0.y), 0.) * w0.x * w0.y;
    result += textureLod(tex, vec2(texPos12.x, texPos0.y), 0.) * w12.x * w0.y;
    result += textureLod(tex, vec2(texPos3.x,  texPos0.y), 0.) * w3.x * w0.y;

    result += textureLod(tex, vec2(texPos0.x,  texPos12.y), 0.) * w0.x * w12.y;
    result += textureLod(tex, vec2(texPos12.x, texPos12.y), 0.) * w12.x * w12.y;
    result += textureLod(tex, vec2(texPos3.x,  texPos12.y), 0.) * w3.x * w12.y;

    result += textureLod(tex, vec2(texPos0.x,  texPos3.y), 0.) * w0.x * w3.y;
    result += textureLod(tex, vec2(texPos12.x, texPos3.y), 0.) * w12.x * w3.y;
    result += textureLod(tex, vec2(texPos3.x,  texPos3.y), 0.) * w3.x * w3.y;

    return result;
}

float distancePixel22( vec2 prevFragCoord, vec3 pos, sampler2D samplerx, vec2 ires, vec3 p_ro, vec3 p_rd){
    if(  min(ires.xy-1., prevFragCoord) != prevFragCoord
      || max(vec2(0.)      , prevFragCoord) != prevFragCoord) return MAX_DIST;
    
    float prev_d = textureLod(samplerx, prevFragCoord/ires.xy,0.).a;
    vec3 prevPos = p_ro + p_rd*prev_d;
    return length(prevPos-pos);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float tmxa = .051;// modified
    
    ivec2 ipx = ivec2(fragCoord);
    
    // adding halton_px_shift to fragCoord not needed
    vec2 uv = (fragCoord)/iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y/iResolution.x;
    
    vec2 halton_px_shift = (halton(iFrame % 360 + 1) - 0.5);
    float curr_d = textureLod(iChannel2, (fragCoord - halton_px_shift) / iResolution.xy, 0.).a;
    vec4 curr_color = textureLod(iChannel2, (fragCoord - halton_px_shift) / iResolution.xy, 0.).rgba;
    bool tba = any(lessThan(curr_color.rgb, vec3(0.)));
    curr_color.rgb = abs(curr_color.rgb); 
    
    vec4 new = vec4(RGBtoYCoCg(curr_color.rgb),curr_color.a);

#ifdef TEMPORAL_REPROJECT

    vec3 ro;
    vec3 rd;
    SetCamera(uv, ro, rd, iResolution.xy);
    
    vec3 pro;
    vec3 prd;
    SetCamera_prev(uv, pro, prd, iResolution.xy);
    
    vec3 pos = ro + rd * curr_d;
    
    // adding prevUv to fragCoord not needed
    vec2 prevUv = pos2uv(pos, iResolution.xy);
    vec2 prevFragCoord = (prevUv * iResolution.y + iResolution.xy/2.0);
    vec2 puv = prevFragCoord/iResolution.xy; 
    
    
    //vec4 hist = texture(iChannel2, puv);
    //vec4 hist = getTextureSmooth(iChannel2, iResolution.xy, puv);
    vec4 hist = SampleTextureCatmullRom(iChannel3, iResolution.xy, puv);
    hist*=step(abs(puv.x-0.5),0.5)*step(abs(puv.y-0.5),0.5);// modified

    vec4 old = vec4(RGBtoYCoCg(hist.rgb),hist.a);
#else
    ivec2 sp = ivec2(fragCoord);
    vec4 old = vec4(RGBtoYCoCg(texelFetch(iChannel3, sp, 0).rgb),texelFetch(iChannel3, sp, 0).a);
#endif

#ifdef VARIANCE_CLIPPING
    vec4 avg = new;
    vec4 var = new * new;
    
    for (int i = 0; i < OFFSET_COUNT; i++)
    {
        vec4 tex_data = texelFetch(iChannel2, ipx + off[i], 0);
        tba = tba||any(lessThan(tex_data.rgb, vec3(0.)));
        tex_data.rgb = abs(tex_data.rgb);
        vec4 tex = vec4(RGBtoYCoCg(tex_data.rgb),tex_data.a);
        
        avg += tex;
        var += tex * tex;
    }
    avg /= float(OFFSET_COUNT + 1);
    var /= float(OFFSET_COUNT + 1);

    vec4 sig = sqrt(max(var - avg * avg, vec4(0)));
    
    const float g = 1.;
    vec4 cmin = avg - sig * g;
    vec4 cmax = avg + sig * g;
    
    #if 0
    vec4 clip = clamp(old, cmin, cmax);
    #else
    vec4 clip = clipToAABB(old, clamp(avg, cmin, cmax), avg, sig);
    #endif
    
    old = mix(old, clip, 0.05+0.645*float(tba)); //1. modified
#endif
    bool res_ch = ivec2(load(RES_LAST_LAST))!=ivec2(iResolution.xy);
    vec4 col = iFrame != 0 && !res_ch ? mix(old, new, tmxa) : new;
    
#ifdef ENABLE_TAA
    fragColor = vec4(YCoCgToRGB(col.rgb), curr_d);
#else
    fragColor = vec4(texelFetch(iChannel2, ivec2(fragCoord), 0).rgb, curr_d);
#endif
    
#ifdef SHOW_DISOCCLUSION

    if (puv.x < 0. || puv.x >= 1. || puv.y < 0. || puv.y >= 1. ||
        distance(pos, (pro+prd*hist.a)) > 2.*0.1*curr_d)
    {
        fragColor = vec4(1, 0, 0, curr_d);
    }
#endif

#ifdef SHOW_MOTION
    fragColor = vec4((fragCoord/iResolution.xy - puv) * 50., 0, curr_d);
#endif
    fragColor.rgb=clamp(fragColor.rgb,0.,100.); // seems color can be little negative

#ifndef SHOW_DISOCCLUSION
    //debug
    //fragColor.a = length(texture(iChannel3,puv).rgb);
#endif
    
}
#endif















// camera
//----------------------------
#define SS(x, y, z) smoothstep(x, y, z)



const ivec2 INIT = ivec2(0, 1);
const ivec2 TARGET = ivec2(0, 2);

const ivec2 tt_st = ivec2(1, 2);
const ivec2 POSITION = ivec2(1, 0);
const ivec2 POSITION_last = ivec2(1, 1);

const ivec2 INPUT = ivec2(3, 0);
const ivec2 PMOUSE = ivec2(3, 1);

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

void SetCamera_prev(vec2 uv, out vec3 ro, out vec3 rd, vec2 ires)
{
    ro = load(POSITION_last).xyz;
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
    
    float ltt = load(tt_st).y;
    rd = rotationMatrix(m,ltt) * rd;
}


//----------------------------






// reprojection
//----------------------------------------------

vec2 pos2uv(vec3 pos, vec2 ires){
    vec3 ro_old = load(POSITION_last).xyz;
    vec2 m_old = vec2(-0.5*3.1415926+0.001, -0.0+0.001);
    m_old.y = -m_old.y;
    vec3 td = pos - ro_old;
    if(length(td)<0.0001)return vec2(-1.);
    
    float ltt = load(tt_st).y;
    vec3 dir = normalize(td) * (rotationMatrix(m_old,ltt));
    
    
    float fov=camera_fov;
    float aspect = ires.x / ires.y;
    float screenSize = (1.0 / (tan(((180.-fov)* (3.1415926 / 180.0)) / 2.0)));
    dir.z+=0.0001*(1.-abs(sign(dir.z)));

#ifdef cam_cyli
    // cylindrical perspective https://www.shadertoy.com/view/ftffWN
    //undone
    float last_sa = atan(dir.x/dir.z);
    vec3 ord = dir;
    ord.z = dir.z*1./cos(last_sa);
    ord.x=last_sa*ord.z;
    dir = ord;
#endif

    return dir.xy * (.5/screenSize) / dir.z ;
}

//----------------------------------------------


