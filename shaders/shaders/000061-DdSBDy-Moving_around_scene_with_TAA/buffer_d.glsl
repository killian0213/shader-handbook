// Buffer D (buffer) — Moving around scene with TAA by morimea
// https://www.shadertoy.com/view/DdSBDy


// TAA from https://www.shadertoy.com/view/DsfGWX


#ifdef add_clouds
void mainImage_cloud( out vec4 fragColor, in vec2 fragCoord);
#endif

#ifndef use_dynamic_TAA
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(0.);
#ifdef add_clouds
    vec4 tcol;
    mainImage_cloud(tcol,fragCoord);
    fragColor.a=pack_Snormfloat3x10(tcol.rgb);
#endif

}
#else

#define ENABLE_TAA
#define TEMPORAL_REPROJECT

#define VARIANCE_CLIPPING

// debug
//#define SHOW_MOTION
//#define SHOW_DISOCCLUSION

// TAA
// alpha of this shader is unused, it used to store curr_d but hist.a used only in SHOW_DISOCCLUSION

// --when define enable_volume set - this Alpha used to filter absorb from BufC - so debug wont work here
// above replaced with - now alpha used to store cloud-sky

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
#ifdef move_rounds
    float l_t = load(LOCAL_T,iChannel0);
    rtimer = l_t;
    float l_t_last = load(LOCAL_T_last,iChannel0);
    rtimer_last = l_t_last;
#endif
    float a = .1;
    
    ivec2 ipx = ivec2(fragCoord);
    
    // adding halton_px_shift to fragCoord not needed
    vec2 uv = fragCoord/iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y/iResolution.x;
    
    vec2 halton_px_shift = vec2(load(HALTON0,iChannel0),load(HALTON1,iChannel0));
    float curr_d = textureLod(iChannel0, (fragCoord - halton_px_shift) / iResolution.xy, 0.).y;
    vec4 curr_color = textureLod(iChannel2, (fragCoord - halton_px_shift) / iResolution.xy, 0.).rgba;
    vec3 curr_texture_col = vec3(1.);
    
#ifdef enable_textures
    //texelFetch because data packed
    curr_texture_col = unpack_Unormfloat3x10(texelFetch(iChannel2, ivec2(fragCoord - halton_px_shift), 0).a);
#endif
    vec4 new = vec4(RGBtoYCoCg(curr_color.rgb*curr_texture_col),curr_color.a);

#ifdef TEMPORAL_REPROJECT

    vec3 ro;
    vec3 rd;
    SetCamera(uv, iChannel0, ro, rd, iResolution.xy);
    
    vec3 pro;
    vec3 prd;
    SetCamera_prev(uv, iChannel0, pro, prd, iResolution.xy);
    
    vec3 pos = ro + rd * curr_d;
    
    // adding prevUv to fragCoord not needed
    vec2 prevUv = pos2uv(pos, iChannel0, iResolution.xy);
    vec2 prevFragCoord = prevUv * iResolution.y + iResolution.xy/2.0;
    vec2 puv = prevFragCoord/iResolution.xy;
    
    
    //vec4 hist = texture(iChannel3, puv);
    //vec4 hist = getTextureSmooth(iChannel3, iResolution.xy, puv);
    vec4 hist = SampleTextureCatmullRom(iChannel3, iResolution.xy, puv);

    vec4 old = vec4(RGBtoYCoCg(hist.rgb),hist.a);
#else
    vec4 old = vec4(RGBtoYCoCg(texelFetch(iChannel3, sp, 0).rgb),texelFetch(iChannel3, sp, 0).a);
#endif

#ifdef VARIANCE_CLIPPING
    vec4 avg = new;
    vec4 var = new * new;
    
    for (int i = 0; i < OFFSET_COUNT; i++)
    {
        vec4 tex_data = texelFetch(iChannel2, ipx + off[i], 0);
        vec3 tex_color = vec3(1.);
#ifdef enable_textures
        tex_color = unpack_Unormfloat3x10(tex_data.a);
#endif
        vec4 tex = vec4(RGBtoYCoCg(tex_data.rgb*tex_color),tex_data.a);
        
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
    
    old = mix(old, clip, 1.);
#endif
    
    bool res_ch = load(RES_CHANGE,iChannel0)<0.5;
    vec4 col = iFrame != 0 || res_ch ? mix(old, new, a) : new;
#ifdef ENABLE_TAA
#ifdef enable_volume
    fragColor = vec4(YCoCgToRGB(col.rgb), col.a);
#else
    fragColor = vec4(YCoCgToRGB(col.rgb), curr_d);
#endif
    float iot = smoothstep(1.5,4.5,load(INPUT0_timer, iChannel0));
    if(iot>0.001){
        curr_color = textureLod(iChannel2, fragCoord / iResolution.xy, 0.).rgba;
        curr_texture_col = vec3(1.);
    #ifdef enable_textures
        //texelFetch because data packed
        curr_texture_col = unpack_Unormfloat3x10(texelFetch(iChannel2, ivec2(fragCoord), 0).a);
    #endif
        fragColor.rgb = mix(fragColor.rgb,curr_color.rgb*curr_texture_col,iot);
    }
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

#ifdef add_clouds
    vec4 tcol;
    mainImage_cloud(tcol,fragCoord);
    fragColor.a=pack_Unormfloat3x10(tcol.rgb);
#endif
    fragColor.rgb=clamp(fragColor.rgb,0.,100.); // seems color can be little negative
}
#endif

























#ifdef add_clouds


// clouds from https://www.shadertoy.com/view/DtBGR1

const int MAX_STEPS = 128;
const float DRAW_DISTANCE = 300.0;


const float INSIDE_STEP_SIZE = 0.6;
const int STEP_OUTSIDE_RATIO = 2;
const float OUTSIDE_STEP_SIZE = INSIDE_STEP_SIZE * float(STEP_OUTSIDE_RATIO);

vec3 renderSky(vec3 rd) {
    rd = rd.xzy;
    float lDotU = dot(rd, upVec);
    float lDotV = dot(rd, lightDir);
    vec3 color = calculateSun(lDotV)*calculateSunColor(lightDir.y);
    color = calculateSky(color, lDotU, lDotV);
    
    float haze = pow(max(1.002 - abs(lDotU),0.002), 6.0) * (lDotV + 1.0) * 0.5;
    
    color = ACESFilm(color);
    color = color*0.35+0.65*mix(color, vec3(0.99, 0.98, 0.96), clamp(haze, 0.0, 1.0));
    
    return color;
}

float hash14(vec4 p4)
{
	p4 = fract(p4  * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.x + p4.y) * (p4.z + p4.w));
}

vec4 alphaOver(vec4 top, vec4 bottom) {
    float A1 = bottom.a * (1.0 - top.a);
    //A1 = bottom.a * exp(-.5-2.*top.a); //+-1.
    float A0 = top.a + A1;
    return vec4(
        (top.rgb * top.a + bottom.rgb * A1) / A0,
        A0
    );
}


float sampleCloudMapDensity(vec3 pos) {
    // Defines where the cloud are. Ideally this function acts a bit
    // like a distance field - the density should not have any sharp edges in it.
    //
    // This function gets called a lot, so try to maximize it's performance.
    
    vec4 cloud_map = textureLod(iChannel1, pos.xy * 0.005, 0.0);
    
    float density = 0.0;
    density = (cloud_map.r - 0.4 - abs((0.5 + pos.z - cloud_map.r * 2.0) * 0.1));
    //density += pow(abs(cloud_map.g - p.z * 0.1), 3.);
    density = max(density, cloud_map.b - 0.1 - abs(1.0 - cloud_map.b * 0.5 + pos.z * 0.1));
    
    density = max(density, 0.0);
    density = pow(density * 2.0, 2.0);
    
    
    density = min(density,0.051*(length(pos.xy)-49.));
    
    return density;
}


vec3 lightMarch(vec3 ro, vec3 rd) {
    // Computes the lighting in the cloud at a given point
    float lighting = 1.0;
    float transmission = 1.0 - dot(lightDir.xzy, rd);
    transmission += 0.1;
    lighting *= clamp(1.0 - sampleCloudMapDensity(ro + lightDir.xzy * 1.0) * 0.2 * transmission, 0.0, 1.0); // Self
    lighting *= clamp(1.0 - sampleCloudMapDensity(ro + lightDir.xzy * 2.0) * 0.2 * transmission, 0.0, 1.0); // Far
    lighting *= clamp(1.0 - sampleCloudMapDensity(ro + lightDir.xzy * 4.0) * 0.2 * transmission, 0.0, 1.0); // Far
    lighting *= clamp(1.0 - sampleCloudMapDensity(ro + lightDir.xzy * 8.0) * 0.2 * transmission, 0.0, 1.0); // Far
    return vec3(lighting);
}


float noise(in vec3 x);
float noise_texture2d(in vec3 x);
float noise_local( in vec3 p ){
    return noise(p*30.); //hash
}
vec4 renderScene(vec3 ro, vec3 rd) {
    ro = ro.xzy;rd = rd.xzy;
    vec4 accumulation = vec4(0.0, 0.0, 0.0, 0.001);
    
    float dist_from_camera = 0.0;
    int steps_outside_cloud = 0;
    
    float noise = hash14(vec4(rd * 1000.0, iTime * 10.0));
    
    vec3 sky = renderSky(rd);
        
    for (int i=0; i<MAX_STEPS; i++) {
        //dist_from_camera = max(dist_from_camera,10.*clamp(length(rd),0.,1.));
        vec3 current_position = ro + (dist_from_camera + noise * INSIDE_STEP_SIZE) * rd;
        float cloud_map = sampleCloudMapDensity(current_position);
        
        if (cloud_map > 0.0) {
            if (steps_outside_cloud != 0) {
                // First step into the cloud;
                steps_outside_cloud = 0;
                dist_from_camera = dist_from_camera - OUTSIDE_STEP_SIZE + INSIDE_STEP_SIZE;
                continue;
            }
            steps_outside_cloud = 0;
        } else {
            steps_outside_cloud += 1;
        }
        
        float step_size = OUTSIDE_STEP_SIZE;
        
        if (steps_outside_cloud <= STEP_OUTSIDE_RATIO && cloud_map > 0.0) {  
            step_size = INSIDE_STEP_SIZE;
            
            float density = cloud_map * 5.0;

            if (accumulation.a < 0.8) {
                // If we are already mostly opaque, there's no point sampling extra-detail.
                float n = noise_local(current_position * 0.05 + vec3(0,iTime * 0.02,0));
                density -= pow(n, 3.0) * 3.0;
            } else {
                density -= 0.5;
            }
            density *= step_size;
            density = clamp(density, 0.0, 1.0);
            
            float fog = pow(1.0 - (dist_from_camera / DRAW_DISTANCE), 0.5);
                        
            vec3 lighting = lightMarch(current_position, rd);
            
            vec3 cloud_color = mix(
                sky,
                lighting,
                clamp(fog, 0.0, 1.0)
            );
            
            accumulation = alphaOver(accumulation, vec4(cloud_color, density));
            
        }
        

        dist_from_camera += step_size;
        
        if (accumulation.a > 0.98 || dist_from_camera > DRAW_DISTANCE) {
            break;
        }
    }
    
    return vec4(alphaOver(accumulation, vec4(sky, 1.0)).rgb, dist_from_camera);
}


void mainImage_cloud( out vec4 fragColor, in vec2 fragCoord)
{
#ifdef move_rounds
    float l_t = load(LOCAL_T,iChannel0);
    rtimer = l_t;
    float l_t_last = load(LOCAL_T_last,iChannel0);
    rtimer_last = l_t_last;
#ifdef move_SUN_circle_inf
    lightDir.xz=lightDir.xz*MD(-rtimer*rspd);
#endif
#endif

#ifdef cloud_render_scale
    fragCoord = floor(fragCoord)*vec2(rscale)+0.5;
    fragColor = vec4(0.);
    if(any(greaterThan(fragCoord,iResolution.xy)))return;
#endif

    vec3 ro; vec3 rd;
    vec2 uv = fragCoord/iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y/iResolution.x;
    
    SetCamera(uv, iChannel0, ro, rd, iResolution.xy);
    //ro.y+=-6.;
    fragColor = renderScene(ro, rd);
    
    fragColor = clamp(fragColor, 0., 1.);
    
}



float hash(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
	p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
	
    return mix(mix(mix( hash(i+vec3(0,0,0)), 
                        hash(i+vec3(1,0,0)),f.x),
                   mix( hash(i+vec3(0,1,0)), 
                        hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(i+vec3(0,0,1)), 
                        hash(i+vec3(1,0,1)),f.x),
                   mix( hash(i+vec3(0,1,1)), 
                        hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

#endif



