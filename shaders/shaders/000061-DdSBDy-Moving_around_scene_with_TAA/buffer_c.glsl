// Buffer C (buffer) — Moving around scene with TAA by morimea
// https://www.shadertoy.com/view/DdSBDy



// using https://www.shadertoy.com/view/3dlSW7
// using https://www.shadertoy.com/view/WdjcDd

// this pathtracer template https://www.shadertoy.com/view/dldGWj

// fragColor = vec4(color, absorb); // absorb for volumetric, volumetric rendered in Image

//----------------------------------------------


float get_scene_intersect(vec3 ro, vec3 rd, vec3 norm){
    HitInfo hit;
    //0.002 is light leak
    return (minDist(ro+0.002*norm, rd, hit)?0.:1.);
}

float get_scene_bounce_light(vec3 ro, vec3 rd, vec3 innorm, out vec3 ndir, out vec3 albedo, out vec3 emission, out vec3 norm){
    HitInfo hit;
    bool d = minDist(ro+innorm*0.002, rd, hit);
    ndir=vec3(0.0001);
    albedo=vec3(0.0);
    emission=vec3(0.0);
    norm = vec3(0.0001);
    if(d){
        ndir=ro+rd*hit.t;
        albedo=hit.color.rgb;
        emission=hit.emisson;
        norm = hit.norm;
    }
    
    return d?0.:1.;
}

void get_scene_material(bool d, vec3 pos, vec3 norm, int obj_id, out vec3 albedo, out vec3 emission, 
                        out float roughness, out float metalness){
    albedo=vec3(0.0);
    emission=vec3(0.0);
    roughness=0.0001;
    metalness=0.0001;
    // pos+= objpos todo
    if(d){
        if(obj_id==OBJ_FLOOR||obj_id==OBJ_FLOOR3)
            material_OBJ_FLOOR(pos, norm, albedo, emission, roughness, metalness);
        else if(obj_id==OBJ_FLOOR2)
            material_OBJ_FLOOR2(pos, norm, albedo, emission, roughness, metalness);
        else if(obj_id==OBJ_FLOOR4)
            material_OBJ_FLOOR4(pos, norm, albedo, emission, roughness, metalness);
        else if(obj_id==OBJ_CYL1||obj_id==OBJ_CYL2||obj_id==OBJ_CYL3||obj_id==OBJ_CYL4||obj_id==OBJ_CYL5||obj_id==OBJ_CYL6)//||obj_id==OBJ_CYL_top||obj_id==OBJ_CYL_bot)
            material_OBJ_CYL(pos, norm, albedo, emission, roughness, metalness, obj_id);
        else if(obj_id==OBJ_RR_CYL)
            material_OBJ_RRT(pos, OBJ_RR_CYL, norm, albedo, emission, roughness, metalness);
        else if(obj_id==OBJ_RR_CYL2)
            material_OBJ_RRT(pos, OBJ_RR_CYL2, norm, albedo, emission, roughness, metalness);
        else if(obj_id==OBJ_RR_CYL3)
            material_OBJ_RRT(pos, OBJ_RR_CYL3, norm, albedo, emission, roughness, metalness);
    }
}

//----------------------------------------------





// pathtracing functions
//----------------------------------------------

float calculateFresnel(float cosTheta, float f0){
    cosTheta = 1.0 - cosTheta;
	cosTheta = cosTheta * cosTheta * cosTheta * cosTheta * cosTheta;
    
    return cosTheta * (1.0 - f0) + f0;
}

#ifdef enable_reflections
vec3 calculateReflection(vec3 ro, vec3 rd, vec3 normal, float percentSpecular, float roughness, vec3 totalLighting, float noise){	
#ifdef use_ConeVector
    mat3 tbn = calculateTangentMatrix(normal);
#endif
    vec3 reflection = vec3(0.0);
    float rReflectionRays = 1.0 / float(reflectionRays);
    float fresnel = 0.0;

    for (int i = 0; i < reflectionRays+ANGLE_loops; ++i){
#ifdef use_ConeVector
        vec3 dir = tbn * calculateRoughSpecular(fract((float(i) + noise) * rReflectionRays), reflectionRays, roughness);
#else
        vec3 dir = normalize(normal + 3.5*roughness*roughness*getCosineWeightedSample(normal,0.1+0.4*roughness));
#endif
        dir = reflect(rd, dir);

        float lDotN = dot(dir, normal);
        float f = lDotN;
        if (lDotN <= 0.0) continue;

        float lDotU = dot(dir, upVec);
        float lDotV = dot(dir, lightDir);

        fresnel += calculateFresnel(f, percentSpecular);

        vec3 light = calculateSky(vec3(0.0), lDotU, lDotV);
        
#ifdef reflection_color_emi
        vec3 bouncePos;
        vec3 bounceNormal;
        vec3 bouncedAlbedo;
        vec3 bouncedEmissive;
        float rayHit = get_scene_bounce_light(ro, dir, normal, bouncePos, bouncedAlbedo, bouncedEmissive, bounceNormal);
        reflection += rayHit * light;
        reflection += (1.-rayHit) * bouncedEmissive;
#else
        float rayHit = get_scene_intersect(ro, dir, normal);
        reflection += rayHit * light;
#endif
    }
    
    reflection = reflection * rReflectionRays;
    fresnel = fresnel * rReflectionRays;

    totalLighting = mix(totalLighting, reflection, fresnel);
	
	return totalLighting;
}
#endif
//----------------------------------------------



void mainImage(out vec4 fragColor, in vec2 fragCoord) {
#ifdef move_rounds
    float l_t = load(LOCAL_T,iChannel0);
    rtimer = l_t;
    float l_t_last = load(LOCAL_T_last,iChannel0);
    rtimer_last = l_t_last;
#ifdef move_SUN_circle_inf
    lightDir.xz=lightDir.xz*MD(-rtimer*rspd);
#endif
#endif
#ifndef use_ConeVector
    seed = hash12(fragCoord.xy+hash21(float(iFrame%10000)*0.333)*1234.123);
#endif
    vec2 fc=fragCoord.xy;
    vec2 halton_px_shift = vec2(load(HALTON0,iChannel0),load(HALTON1,iChannel0));
    fragCoord.xy += halton_px_shift;

    vec2 screen_uv = fc.xy / iResolution.xy;
    vec2 uv = fragCoord/iResolution.xy * 2.0 - 1.0;
    uv.y *= iResolution.y/iResolution.x;
    vec3 ro;
    vec3 rd;
    SetCamera(uv, iChannel0, ro, rd, iResolution.xy);
    
    
    float noise=0.; 
    
#ifdef use_ConeVector
    // noise for ConeVector
    
    ivec2 ipx = ivec2(fc);
    ivec2 reserv = ivec2(5,MEMORY_BOUNDARY.y+5);
    ipx=ipx%(ivec2(textureSize(iChannel0,0).xy)-reserv);
    float n0 = texelFetch(iChannel0, textureSize(iChannel0,0).xy-ipx-1, 0).a;
    noise = fract(n0 + 0.75*float(iFrame % 264) * c_goldenRatioConjugate);

    // test hash12 as noise
    //vec2 tfc = fc.xy+hash21(float(iFrame%10000)*0.333)*iResolution.y*2.;
    //noise = hash12(tfc);
    
#endif

    vec2 this_id_d = texelFetch(iChannel0, ivec2(fc), 0).xy;
    int obj_id = int(this_id_d.x);
    vec3 pos=ro+rd*this_id_d.y;
    
    bool rayHit = obj_id>0;
    vec3 normal;
    vec3 albedo;
    vec3 emission;
    float rough;
    float metal;
    
    
    // restore normals from obj_id
    vec3 box=-vec3(-4.0, 0.0, -7.0);
    vec3 box2=-vec3(-1.8, 0.0, -5.0);
    vec3 sphere3=-vec3(-3.0, -2.0, -5.51);
    vec3 sphere2=-vec3(-7.0, -0.5, -5.51);
    vec3 sphere=-vec3(-4.4, -0.25, -4.51);
    vec3 quadratic_pos=vec3(1.,2.,6.);
    
    if(obj_id==OBJ_FLOOR||obj_id==OBJ_FLOOR2||obj_id==OBJ_FLOOR3||obj_id==OBJ_FLOOR4)normal=get_normal_OBJ_FLOOR(pos,ro);
    if(obj_id==OBJ_CYL1)normal=get_normal_OBJ_CYL(pos-vec3(0.), 44.2, 1.);
    if(obj_id==OBJ_CYL2)normal=get_normal_OBJ_CYL(pos-vec3(0.), 46.2, 1.);
    if(obj_id==OBJ_CYL3)normal=get_normal_OBJ_CYL(pos-vec3(0.), 46.1, -1.);
    if(obj_id==OBJ_CYL4)normal=get_normal_OBJ_CYL(pos-vec3(0.), 45.4, 1.);
    if(obj_id==OBJ_CYL5)normal=get_normal_OBJ_CYL(pos-vec3(0.), 45.3, -1.);
    if(obj_id==OBJ_CYL6)normal=get_normal_OBJ_CYL(pos-vec3(0.), 47.3, -1.);
    //if(obj_id==OBJ_CYL_top)normal=get_normal_OBJ_CYL_top();
    //if(obj_id==OBJ_CYL_bot)normal=get_normal_OBJ_CYL_bot();
    if(obj_id==OBJ_RR_CYL){
        vec3 rrt = RayTracing_Radial_Repetition(ro+RR1pos, rd, normal, RR1prm, RREP_rtc1);
    }
    if(obj_id==OBJ_RR_CYL2){
        vec3 rrt = RayTracing_Radial_Repetition(ro+RR2pos, rd, normal, RR2prm, RREP_rtc2);
    }
    if(obj_id==OBJ_RR_CYL3){
        vec3 rrt = RayTracing_Radial_Repetition(ro+RR3pos, rd, normal, RR3prm, RREP_rtc3);
    }
    
    get_scene_material(rayHit, pos, normal, obj_id, albedo, emission, rough, metal);
    
    vec3 sunColor = calculateSunColor(lightDir.y);
    vec3 color = texelFetch(iChannel1, ivec2(fc), 0).rgb;
#ifdef enable_reflections
    color = calculateReflection(pos, rd, normal, metal, rough, color, noise);
#endif
    
	float lDotU = dot(rd, upVec);
	float lDotV = dot(rd, lightDir);
	
    if (!rayHit) 
    {
        color = vec3(0.0);
        color += calculateSun(lDotV)*calculateSunColor(lightDir.y);
        color = calculateSky(color, lDotU, lDotV);
#ifdef add_clouds
        bool res_ch = load(RES_CHANGE,iChannel0)<0.5;
#ifdef cloud_render_scale
        if(iFrame==0||res_ch){}
        else{
            color = texture_Bilinear(iChannel3, fragCoord/iResolution.xy);
            color = ACES_Inv(color);
        }
#else
        if(iFrame==0||res_ch){}
        else{color = unpack_Unormfloat3x10(texelFetch(iChannel3, ivec2(fragCoord), 0).a);}
#endif
#endif
    }
    float absorb = 0.;
    
#ifdef enable_textures
    absorb = texelFetch(iChannel1, ivec2(fc), 0).a;
#else
#ifdef enable_volume
    float depth = length(ro-pos);
    absorb = exp(-depth * volume_fogDensity);
    absorb = clamp(absorb,.25,1.);
    absorb = 1.-(1.-smoothstep(MAX_DIST-MAX_DIST*0.1,MAX_DIST,depth))*(1.-absorb);
#endif
#endif
    
    color = max(color, 0.0);
    bool input_registered = load(INPUT0,iChannel0)>1.;
    fragColor = vec4(color, absorb);
    //protection when camera go inside of shape and intersection function may return inf or nan
    fragColor.rgb=clamp(fragColor.rgb,0.,100.); 
#ifdef use_reproject_TAA
    // reprojection TAA
    bool res_ch = load(RES_CHANGE,iChannel0)<0.5;
    if(input_registered||res_ch){
        vec4 oldCol = previousSample(ro, pos,iChannel0, iChannel0, iChannel2, iResolution.xy);
        float factor = (oldCol.a == 0.||res_ch) ? 0. : (rayHit ? .90 : 0.01);//limit sky reproject trails
        fragColor.rgb = mix(fragColor.rgb, oldCol.rgb, factor);
#ifndef enable_textures
        fragColor.a = mix(fragColor.a, oldCol.a, factor*0.75); 
#endif
        //fragColor.a=absorb; // to disable reproj for volumtertic shadow
    }else
#endif
    // default TAA
    {
        vec4 backColor = texture(iChannel2, screen_uv);
        float iot = smoothstep(5.5,12.5,load(INPUT0_timer, iChannel0));
        fragColor.rgb = mix(fragColor.rgb, backColor.rgb, (0.905+0.08*iot) * (1.-float(input_registered)));
#ifndef enable_textures
        fragColor.a = mix(fragColor.a, backColor.a, (0.905+0.08*iot) * (1.-float(input_registered)));
#else
        fragColor.a = fragColor.a; //copy BufB texture color
#endif
    }
#ifndef enable_textures
    fragColor.a=max(fragColor.a,0.00001); // reprojection flag for previousSample in Comon, it return alpha 0. when no reprojection
#endif
    
}

