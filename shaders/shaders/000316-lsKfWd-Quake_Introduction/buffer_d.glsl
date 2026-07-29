// Buffer D (buffer) — Quake / Introduction by adx
// https://www.shadertoy.com/view/lsKfWd

////////////////////////////////////////////////////////////////
// Buffer D:
// - UV/texture mapping
// - particles (fireball trail, shotgun pellets, teleporter effect)
// - volumetric light shafts
// - demo mode stages
// - GBuffer debug vis
////////////////////////////////////////////////////////////////

// config.cfg //////////////////////////////////////////////////

#define TEXTURE_FILTER				1		// [0=nearest; 1=linear]
#define USE_MIPMAPS					2		// [0=off; 1=derivative-based; 2=depth+slope]
#define LOD_SLOPE_SCALE				0.9		// [0.0=authentic/sharp/aliased - 1.0=smooth]
#define LOD_BIAS					0.0
#define LOD_DITHER					0.0		// 1.0=discount linear mip filtering

// I know, mixing my Marvel and my DC here...
// Note: if you enable UV dithering, make sure to also
// comment out QUANTIZE_SCENE below
// and set LIGHTMAP_FILTER to 2 in Buffer B
#define USE_UV_DITHERING			0
#define UV_DITHER_STRENGTH			1.00

#define QUANTIZE_SCENE				48		// comment out to disable

#define RENDER_PARTICLES			1
#define CULL_PARTICLES				1

#define RENDER_VOLUMETRICS			1
#define RENDER_WINDOW_PROJECTION	1
#define VOLUMETRIC_STRENGTH			0.125
#define VOLUMETRIC_SAMPLES			8		// 4=low..8=medium..16=high
#define VOLUMETRIC_MASK_LOD			1
#define VOLUMETRIC_FALLOFF			400.	// comment out to disable
#define VOLUMETRIC_SOFT_EDGE		64.		// comment out to disable
#define VOLUMETRIC_SUN_DIR			vec3(8, -2, -3)
#define VOLUMETRIC_PLAYER_SHADOW	2		// [0=off; 1=capsule; 2=capsule+sphere]
#define VOLUMETRIC_ANIM				1
#define WINDOW_PROJECTION_STRENGTH	64.

#define DEBUG_DEPTH					0
#define DEBUG_NORMALS				0
#define DEBUG_TEXTURES				0		// aka fullbright mode
#define DEBUG_MIPMAPS				0
#define DEBUG_LIGHTING				0
#define DEBUG_PARTICLE_CULLING		0
#define DEBUG_VOLUMETRICS			0

////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////
////////////////////////////////////////////////////////////////

#define NOISE_CHANNEL				iChannel1
#define SETTINGS_CHANNEL			iChannel3

float g_downscale = 2.;
float g_animTime = 0.;

vec4 load(vec2 address)
{
    return load(address, SETTINGS_CHANNEL);
}

// Texturing ///////////////////////////////////////////////////

vec2 uv_map_axial(vec3 pos, int axis)
{
    return (axis==0) ? pos.yz : (axis==1) ? pos.xz : pos.xy;
}

vec2 tri(vec2 x)
{
    vec2 h = fract(x*.5)-.5;
    return 1.-2.*abs(h);
}

vec3 rainbow(float hue)
{
    return clamp(vec3(min(hue, 1.-hue), abs(hue-1./3.), abs(hue-2./3.))*-6.+2., 0., 1.);
}

vec4 get_balloon_color(const int material, const float current_level)
{
    vec4 color = vec4(vec3(.25),.35);
    float hue = float(material-BASE_TARGET_MATERIAL)*(1./float(NUM_TARGETS));
    hue = fract(hue + current_level * 1./6.);
    color.rgb += rainbow(hue) * .5;
    return color;
}

// iq: https://iquilezles.org/articles/checkerfiltering
float checkersGrad(vec2 uv, vec2 ddx, vec2 ddy)
{
    vec2 w = max(abs(ddx), abs(ddy)) + 1e-4;    // filter kernel
    vec2 i = (tri(uv+0.5*w)-tri(uv-0.5*w))/w;   // analytical integral (box filter)
    return 0.5 - 0.5*i.x*i.y;                   // xor pattern
}

struct SamplerState
{
    vec4 tile;
    float atlas_scale;
    int flags;
};

vec4 texture_lod(SamplerState state, vec2 uv, int lod)
{
    float texel_scale = state.atlas_scale * exp2i(-lod);
    bool use_filter = test_flag(state.flags, OPTION_FLAG_TEXTURE_FILTER);
	if (use_filter)
    	uv += -.5 / texel_scale;
    
    uv = fract(uv / state.tile.zw);
    state.tile *= texel_scale;
    uv *= state.tile.zw;
  
    vec2 mip_base = mip_offset(lod) * ATLAS_SIZE * state.atlas_scale + state.tile.xy + ATLAS_OFFSET;

    if (use_filter)
    {
        ivec4 address = ivec2(mip_base + uv).xyxy;
        address.zw++;
        if (uv.x >= state.tile.z - 1.) address.z -= int(state.tile.z);
        if (uv.y >= state.tile.w - 1.) address.w -= int(state.tile.w);

        vec4 s00 = gamma_to_linear(texelFetch(iChannel3, address.xy, 0));
        vec4 s10 = gamma_to_linear(texelFetch(iChannel3, address.zy, 0));
        vec4 s01 = gamma_to_linear(texelFetch(iChannel3, address.xw, 0));
        vec4 s11 = gamma_to_linear(texelFetch(iChannel3, address.zw, 0));

        uv = fract(uv);
        return linear_to_gamma(mix(mix(s00, s10, uv.x), mix(s01, s11, uv.x), uv.y));
    }
    else
    {
        return texelFetch(iChannel3,  ivec2(mip_base + uv), 0);
    }
}

vec4 sample_tile(GBuffer gbuffer, vec2 uv, float depth, float alignment, int flags, vec2 noise)
{
    int material = gbuffer.material;
    
    vec4 atlas_info = load(ADDR_ATLAS_INFO);
    float atlas_lod = atlas_info.y;
    float atlas_scale = exp2(-atlas_lod);
    
#if USE_MIPMAPS
    int max_lod = clamp(int(round(atlas_info.x)) - 1, 0, MAX_MIP_LEVEL - int(atlas_lod));
    float lod_bias = LOD_BIAS - atlas_lod;
    lod_bias += LOD_DITHER * (noise.y - .5);

    #if USE_MIPMAPS >= 2
    	float deriv = depth*VIEW_DISTANCE * FOV_FACTOR * g_downscale / (iResolution[FOV_AXIS]*.5 * alignment);
	#else
    	float deriv = max(fwidth(uv.x), fwidth(uv.y));
    	if (gbuffer.edge)
    		max_lod = int(max(LOD_BIAS, atlas_lod));
	#endif

    int lod = int(floor(log2(max(1., deriv)) + lod_bias));
    lod = clamp(lod, 0, max_lod);
#else
    const int lod = 0;
#endif // USE_MIPMAPS
    //lod = 0;
    
#if USE_UV_DITHERING
    if (!test_flag(flags, OPTION_FLAG_TEXTURE_FILTER))
    	uv += (noise - .5) * UV_DITHER_STRENGTH * exp2(float(lod)+atlas_lod);
#endif
    
#if DEBUG_MIPMAPS
	return vec4(vec3(float(lod)/6.), 0.);
#endif
    
    return texture_lod(SamplerState(get_tile(material), atlas_scale, flags), uv, lod);
}

vec4 apply_material(GBuffer gbuffer, vec3 surface_point, vec3 surface_normal, vec3 eye_dir, float depth, int flags, vec2 noise)
{
    int material = gbuffer.material;
    int on_edge = int(gbuffer.edge);
    int axis = gbuffer.uv_axis;
    
    if (material == MATERIAL_SHOTGUN_FLASH)
        material = MATERIAL_FLAME;

    GameState game_state;
    LOAD(game_state);
    if (is_material_balloon(material))
    {
        vec4 color = get_balloon_color(material, floor(abs(game_state.level)));
        if (game_state.level < 0.)
        {
            float fraction = linear_step(0., BALLOON_SCALEIN_TIME*.1, fract(-game_state.level));
            color.rgb = mix(vec3(.25), color.rgb, sqr(fraction));
        }
        return color;
    }
    
    if (is_material_viewmodel(material))
    {
        const vec4 SHOTGUN_COLORS[NUM_SHOTGUN_MATERIALS] = vec4[](vec4(.25,.18,.12,.5), vec4(.0,.0,.0,.5), vec4(0));
        vec4 color = SHOTGUN_COLORS[min(material - NUM_MATERIALS, NUM_SHOTGUN_MATERIALS)];
        float light = clamp(dot(vec2(abs(surface_normal.y), surface_normal.z), normalize(vec2(1, 8))), 0., 1.);
        vec2 uv = surface_point.xy * 8.;
#if USE_UV_DITHERING
        uv += (noise - .5) * UV_DITHER_STRENGTH;
#endif
        color.rgb *= .125 + .875*light;
        if (material == MATERIAL_SHOTGUN_BARREL)
        {
            color.rgb = mix(vec3(.14,.11,.06), color.rgb, sqr(sqr(light)));
            color.rgb = mix(color.rgb, vec3(.2,.2,.25), around(.87, .17, light));
            float specular = pow(light, 16.) * .75;
            color.rgb += specular;
        }
        else
        {
        	light = clamp(dot(surface_normal.yz, normalize(vec2(-1, 1))), 0., 1.);
            float highlight = pow(light, 4.) * .125;
            color.rgb *= 1. + highlight;
        }
        if (!test_flag(flags, OPTION_FLAG_TEXTURE_FILTER))
            uv = round(uv);
        float variation = mix(1., .83, smooth_noise(uv));
        return vec4(color.rgb * variation, color.a);
    }
    
    // brief lightning flash when shooting the sky to start a new game
    const float LIGHTNING_DURATION = .125;
    bool lightning =
        game_state.level <= 1.+.1*LEVEL_WARMUP_TIME &&
        game_state.level >= 1.+.1*(LEVEL_WARMUP_TIME - LIGHTNING_DURATION);
    
#if USE_MIPMAPS >= 2
    float alignment = abs(dot(normalize(eye_dir), surface_normal));
    alignment = mix(1., alignment, LOD_SLOPE_SCALE);
#else
    float alignment = 1.;
#endif
    
    vec2 sample_uv[3];
    int material2 = material;
    int num_uvs;
    
    if (material == MATERIAL_SKY1)
    {
    	// ellipsoidal mapping for the sky
        const float SKY_FLATTEN = 4.;
        sample_uv[0] = 512. * normalize(eye_dir*vec3(1.,1.,SKY_FLATTEN)).xy;
        sample_uv[1] = rotate(sample_uv[0] + g_animTime * 24., 30.);
        sample_uv[0] += g_animTime * 12.;
        material2 = MATERIAL_SKY1B;
        
        num_uvs = 2;
        depth = 0.;
        alignment = 1.;
    }
    else if (axis != 3)
    {
        // world brushes, project using dominant axis
        sample_uv[0] = uv_map_axial(surface_point, axis);
        if (is_material_liquid(material))
            sample_uv[0] += sin(g_animTime + sample_uv[0].yx * (1./32.)) * 12.;
        num_uvs = 1;
    }
    else
    {
    	// triplanar mapping (for entities)
        const float SCALE = 2.; // higher res
        vec3 uvw = surface_point * SCALE;
        vec2 uv_bias = vec2(0);
        if (material == MATERIAL_FLAME)
        {
        	float loop = floor(g_animTime * 10.) * .1;
        	uv_bias.y = -fract(loop) * 64.;
        }
        
        sample_uv[0] = uvw.xy + uv_bias;
        sample_uv[1] = uvw.yz + uv_bias;
        sample_uv[2] = uvw.xz + uv_bias;
        num_uvs = 3;
        depth *= SCALE;
    }
    
    vec4 colors[3];
    gbuffer.material = material;
    colors[0] = sample_tile(gbuffer, sample_uv[0], depth, alignment, flags, noise);
    
    gbuffer.material = material2;
    if (num_uvs >= 2)
    	colors[1] = sample_tile(gbuffer, sample_uv[1], depth, alignment, flags, noise);
    
    gbuffer.material = material;
    if (num_uvs >= 3)
    	colors[2] = sample_tile(gbuffer, sample_uv[2], depth, alignment, flags, noise);
    
    vec4 textured;
    if (material == MATERIAL_SKY1)
    {
        //textured = (dot(colors[1].rgb, vec3(1)) + noise.y*.1 < .45) ? colors[0] : colors[1];
        textured = mix(colors[0], colors[1], linear_step(.35, .45, dot(colors[1].rgb, vec3(1))));
        textured.rgb *= mix(1., 2., lightning);
    }
    else if (axis != 3)
    {
        textured = colors[0];
    }
	else
    {
        vec3 axis_weights = abs(surface_normal);
        axis_weights *= 1. / (axis_weights.x + axis_weights.y + axis_weights.z);

        textured =
            colors[0] * axis_weights.z +
            colors[1] * axis_weights.x +
            colors[2] * axis_weights.y ;
    }
    
    // disable AO and reduce shadowing during flash
    textured.a = mix(textured.a, min(textured.a, .35), lightning);
    
    return textured;
}

// Fireball particle trail /////////////////////////////////////

void add_to_aabb(inout vec3 min_point, inout vec3 max_point, vec3 point)
{
    min_point = min(min_point, point);
    max_point = max(max_point, point);
}

void get_fireball_bounds
(
    const Fireball fireball,
    const vec3 camera_pos, const mat3 view_matrix,
    float zslack,
    out vec3 mins, out vec3 maxs
)
{
    float apex_time = fireball.velocity.z * (1./GRAVITY);
    vec3 apex;
    apex.z = sqr(fireball.velocity.z) * (.5/GRAVITY);
    apex.xy = fireball.velocity.xy * apex_time;
    
    vec3 pos = FIREBALL_ORIGIN - camera_pos;
    mins = maxs = project(pos * view_matrix);
    
    vec3 p;
    p = (pos + vec3(fireball.velocity.xy * (apex_time*2.), 0.));
    add_to_aabb(mins, maxs, project(p * view_matrix));

    p = pos + fireball.velocity * fireball.velocity.z * (.5/GRAVITY);
    p.z += zslack;
    add_to_aabb(mins, maxs, project(p * view_matrix));
    
    p = mix(p, pos + vec3(apex.xy, apex.z+zslack), 2.);
    add_to_aabb(mins, maxs, project(p * view_matrix));
}

void add_teleporter_effect(inout vec4 fragColor, vec2 fragCoordNDC, vec3 camera_pos, float teleport_time)
{
    if (teleport_time <= 0.)
        return;
    
    const float TELEPORT_EFFECT_DURATION = .25;

    // at 144 FPS the trajectories are too obvious/distracting
    const float TELEPORT_EFFECT_FPS = 60.;
    float fraction = floor((iTime - teleport_time)*TELEPORT_EFFECT_FPS+.5) * (1./TELEPORT_EFFECT_FPS);
    
    if (fraction >= TELEPORT_EFFECT_DURATION)
        return;
    fraction = fraction * (1./TELEPORT_EFFECT_DURATION);

    const int PARTICLE_COUNT = 96;
    const float MARGIN = .125;
    const float particle_radius = 12./1080.;
    float aspect = min_component(iResolution.xy) / max_component(iResolution.xy);
    float pos_bias = (-1. + MARGIN) * aspect;
    float pos_scale = pos_bias * -2.;

    // this vignette makes the transition stand out a bit more using just visuals
    // Quake didn't have it, but Quake had sound effects...
    float vignette = clamp(length(fragCoordNDC*.5), 0., 1.);
    fragColor.rgb *= 1. - vignette*(1.-fraction);

    int num_particles = NO_UNROLL(PARTICLE_COUNT);
    for (int i=0; i<num_particles; ++i) // ugh... :(
    {
        vec4 hash = hash4(teleport_time*13.37 + float(i));
        float speed = mix(1.5, 2., hash.z);
        float angle = hash.w * TAU;
        float intensity = mix(.25, 1., fract(float(i)*PHI + .1337));
        vec2 direction = vec2(cos(angle), sin(angle));
        vec2 pos = hash.xy * pos_scale + pos_bias;
        pos += (fraction * speed) * direction;
        pos -= fragCoordNDC;
        float inside = step(max(abs(pos.x), abs(pos.y)), particle_radius);
        if (inside > 0.)
            fragColor = vec4(vec3(intensity), 0.);
    }
}

void add_particles
(
    inout vec4 fragColor, vec2 fragCoordNDC,
    vec3 camera_pos, mat3 view_matrix, float depth,
    float attack, float teleport_time
)
{
#if RENDER_PARTICLES
    const float
        WORLD_RADIUS		= 1.5,
    	MIN_PIXEL_RADIUS	= 2.,
    	SPAWN_INTERVAL		= .1,
    	LIFESPAN			= 1.,
    	LIFESPAN_VARIATION	= .5,
    	MAX_GENERATIONS		= ceil(LIFESPAN / SPAWN_INTERVAL),
    	BUNCH				= 4.,
        ATTACK_FADE_START	= .85,
        ATTACK_FADE_END		= .5,
        PELLET_WORLD_RADIUS	= .5;
    const vec3 SPREAD		= vec3(3, 3, 12);
    
    add_teleporter_effect(fragColor, fragCoordNDC, camera_pos, teleport_time);
    
    float depth_scale = MIN_PIXEL_RADIUS * g_downscale/iResolution.x;
    depth *= VIEW_DISTANCE;
    
    // shotgun pellets //
    if (attack > ATTACK_FADE_END)
    {
        // Game stage advances immediately after the last balloon is popped.
        // When we detect a warmup phase (fractional value for game stage)
        // we have to use the previous stage for coloring the particles.

        vec4 game_state = load(ADDR_GAME_STATE);
        float level = floor(abs(game_state.x));
        if (game_state.x != level && game_state.x > 0.)
            --level;

        float fade = sqrt(linear_step(ATTACK_FADE_START, ATTACK_FADE_END, attack));
        vec3 base_pos = camera_pos;
        base_pos.z += (1. - attack) * 8.;

        float num_pellets = ADDR_RANGE_SHOTGUN_PELLETS.z + min(iTime, 0.);
        for (float f=0.; f<num_pellets; ++f)
        {
            vec2 address = ADDR_RANGE_SHOTGUN_PELLETS.xy;
            address.x += f;
            vec2 props = hash2(address);
            if (props.x <= fade)
                continue;
            vec4 pellet = load(address);
            int hit_material = int(pellet.w + .5);
            if (is_material_sky(hit_material))
                continue;
            vec3 pos = pellet.xyz - base_pos;
            float particle_depth = dot(pos, view_matrix[1]) + (-2.*PELLET_WORLD_RADIUS);
            if (particle_depth < 0. || particle_depth > depth)
                continue;
            vec2 ndc_pos = vec2(dot(pos, view_matrix[0]), dot(pos, view_matrix[2]));
            float radius = max(PELLET_WORLD_RADIUS, particle_depth * depth_scale);
            vec2 delta = abs(ndc_pos - fragCoordNDC * particle_depth);
            if (max(delta.x, delta.y) <= radius)
            {
                fragColor = vec4(vec3(.5 * (1.-sqr(props.y))), 0.);
                depth = particle_depth;
			    if (is_material_balloon(hit_material))
                    fragColor.rgb *= get_balloon_color(hit_material, level).rgb * 2.;
            }
        }
    }
    
    Fireball fireball;
    get_fireball_props(g_animTime, fireball);

	#if CULL_PARTICLES
    {
        vec3 mins, maxs;
        get_fireball_bounds(fireball, camera_pos, view_matrix, 40., mins, maxs);
        if (maxs.z <= 0. || mins.z > depth)
            return;

        float slack = 8./mins.z + depth_scale;
        mins.xy -= slack;
        maxs.xy += slack;
        if (mins.z > 0. && is_inside(fragCoordNDC, vec4(mins.xy, maxs.xy - mins.xy)) < 0.)
            return;
    }
	#endif
    
	#if DEBUG_PARTICLE_CULLING
    {
        fragColor.rgb = mix(fragColor.rgb, vec3(1.), .25);
    }
	#endif
    
    float end_time = min(get_landing_time(fireball), g_animTime);
    float end_generation = ceil((end_time - fireball.launch_time) * (1./SPAWN_INTERVAL) - .25);
    
    for (float generation=max(0., end_generation - 1. - MAX_GENERATIONS); generation<end_generation; ++generation)
    {
        float base_time=fireball.launch_time + generation * SPAWN_INTERVAL;
        float base_age = (g_animTime - base_time) * (1./LIFESPAN) + (LIFESPAN_VARIATION * -.5);
        if (base_age > 1.)
            continue;
        
        vec3 base_pos = get_fireball_offset(base_time, fireball) + FIREBALL_ORIGIN;

        for (float f=0.; f<BUNCH; ++f)
        {
            float age = base_age + hash(f + base_time) * LIFESPAN_VARIATION;
            if (age > 1.)
                continue;
            vec3 pos = base_pos - camera_pos;
            pos += hash3(base_time + f*(SPAWN_INTERVAL/BUNCH)) * (SPREAD*2.) - SPREAD;
            pos.z += base_age * 32.;
            float particle_depth = dot(pos, view_matrix[1]);
            if (particle_depth < 0. || particle_depth > depth)
                continue;
            vec2 ndc_pos = vec2(dot(pos, view_matrix[0]), dot(pos, view_matrix[2]));
            float radius = max(WORLD_RADIUS, particle_depth * depth_scale);
            vec2 delta = abs(ndc_pos - fragCoordNDC * particle_depth);
            if (max(delta.x, delta.y) <= radius)
            {
                fragColor = vec4(mix(vec3(.75,.75,.25), vec3(.25), linear_step(.0, .5, age)), 0.);
                depth = particle_depth;
            }
        }
    }
#endif // RENDER_PARTICLES
}

////////////////////////////////////////////////////////////////

const vec3
    VOL_SUN_DIR		= normalize(VOLUMETRIC_SUN_DIR),
    VOL_WINDOW_MINS	= vec3(64, 992, -32),
    VOL_WINDOW_MAXS	= vec3(64, 1056, 160),
    VOL_WALL_POS	= vec3(368, VOL_WINDOW_MINS.y, -72);

#define MAKE_PLANE(dir, point) vec4(dir, -dot(point, dir))

const vec4 VOL_PLANES[7] = vec4[7]
(
	MAKE_PLANE(normalize(cross(vec3(0, 0,-1), VOL_SUN_DIR)), VOL_WINDOW_MINS),
	MAKE_PLANE(normalize(cross(vec3(0, 0, 1), VOL_SUN_DIR)), VOL_WINDOW_MAXS),
	MAKE_PLANE(vec3( 1, 0, 0), VOL_WALL_POS),
	MAKE_PLANE(vec3(-1, 0, 0), VOL_WINDOW_MINS),
	MAKE_PLANE(normalize(cross(vec3(0, 1, 0), VOL_SUN_DIR)), VOL_WINDOW_MINS),
	MAKE_PLANE(normalize(cross(vec3(0,-1, 0), VOL_SUN_DIR)), VOL_WINDOW_MAXS),
	MAKE_PLANE(vec3(0, 0, -1), VOL_WALL_POS)
);

float volumetric_falloff(float dist)
{
#if defined(VOLUMETRIC_FALLOFF)
    float x = clamp(sqr(1. - dist * (1./float(VOLUMETRIC_FALLOFF))), 0., 1.);
    return x;
    return (x * x + x) * .5;
#else
    return 1.;
#endif
}

float volumetric_player_shadow(vec3 p, vec3 rel_cam_pos)
{
#if VOLUMETRIC_PLAYER_SHADOW
    vec3 occluder_p0 = rel_cam_pos;
    vec3 occluder_p1 = occluder_p0 - vec3(0, 0, 48);
#if VOLUMETRIC_PLAYER_SHADOW >= 2
    occluder_p0.z -= 20.;
#endif // VOLUMETRIC_PLAYER_SHADOW >= 2

    float window_dist = p.x * (1. / VOL_SUN_DIR.x);
    float occluder_dist = occluder_p0.x * (1. / VOL_SUN_DIR.x);
    p -= VOL_SUN_DIR * max(0., window_dist - occluder_dist);
    vec3 occluder_point = closest_point_on_segment(p, occluder_p0, occluder_p1);
    float vis = linear_step(sqr(16.), sqr(24.), length_squared(p - occluder_point));

#if VOLUMETRIC_PLAYER_SHADOW >= 2
    vis = min(vis, linear_step(sqr(8.), sqr(12.), length_squared(p - rel_cam_pos)));
#endif // VOLUMETRIC_PLAYER_SHADOW >= 2

    return vis;
#else
    return 1.;
#endif // VOLUMETRIC_PLAYER_SHADOW
}

void add_volumetrics
(
    inout vec4 fragColor,
    vec3 camera_pos, vec3 dir, float depth01,
    vec3 normal, int uv_axis, bool viewmodel,
    int flags, float noise, bool thumbnail
)
{
#if RENDER_VOLUMETRICS
    if (is_demo_mode_enabled(thumbnail))
    {
        if (!is_demo_stage_composite() || g_demo_scene < 2)
            return;
    }
    else
    {
        if (!test_flag(flags, OPTION_FLAG_LIGHT_SHAFTS) || test_flag(flags, OPTION_FLAG_SHOW_LIGHTMAP))
            return;
    }

    dir *= VIEW_DISTANCE;

    float t_enter = 0.;
    float t_leave = depth01;
    for (int i=0; i<7; ++i)
    {
        vec4 plane = VOL_PLANES[i];
        float dist = dot(plane.xyz, camera_pos) + plane.w;
        float align = dot(plane.xyz, dir);
        if (align == 0.)
        {
            if (dist > 0.)
                return;
            continue;
        }
        dist /= -align;
        t_enter = (align < 0.) ? max(t_enter, dist) : t_enter;
        t_leave = (align > 0.) ? min(t_leave, dist) : t_leave;
        if (t_leave <= t_enter)
            return;
    }

    if (t_leave <= t_enter)
        return;
    
#if DEBUG_VOLUMETRICS
    fragColor.rgb = clamp(fragColor.rgb * 4., 0., 1.);
    return;
#endif

    vec4 atlas_info = load(ADDR_ATLAS_INFO);
    float num_mips = atlas_info.x;
    float atlas_lod = atlas_info.y;
    float atlas_scale = exp2(-atlas_lod);
    int mask_lod = clamp(VOLUMETRIC_MASK_LOD - int(atlas_lod), 0, int(num_mips) - 1);

    SamplerState sampler_state;
    sampler_state.tile			= get_tile(MATERIAL_WINDOW02_1);
	sampler_state.atlas_scale	= atlas_scale;
    sampler_state.flags			= flags;
    vec2 uv_offset = -vec2(.5, .5/3.) * sampler_state.tile.zw;

    vec3 relative_cam_pos = camera_pos - VOL_WINDOW_MINS;
    vec3 enter = relative_cam_pos + dir * t_enter;
    vec3 travel = dir * (t_leave - t_enter);

#if RENDER_WINDOW_PROJECTION
    sampler_state.flags = flags | OPTION_FLAG_TEXTURE_FILTER;
    float n_dot_l = dot(-VOL_SUN_DIR, normal);
    if (abs(t_leave - depth01) < 1e-3/VIEW_DISTANCE && n_dot_l > 0.)
    {
        vec3 p = relative_cam_pos + dir * depth01;
        if (uint(uv_axis) < 3u && !test_flag(flags, OPTION_FLAG_TEXTURE_FILTER))
        {
            vec3 snap = .5 - fract(p);
            p += snap * vec3(notEqual(ivec3(uv_axis), ivec3(0, 1, 2)));
        }
        float window_dist = p.x * (1. / VOL_SUN_DIR.x);
        float weight = WINDOW_PROJECTION_STRENGTH * volumetric_falloff(window_dist);
        weight *= clamp(n_dot_l, 0., 1.);
        weight *= volumetric_player_shadow(p, relative_cam_pos);
        weight *= linear_step(0., 2., p.z - (VOL_WALL_POS.z - VOL_WINDOW_MINS.z));
        
        vec2 uv = (p - window_dist * VOL_SUN_DIR).yz + uv_offset;
        vec3 color = gamma_to_linear(texture_lod(sampler_state, uv, 0).rgb);
		
        fragColor.rgb += fragColor.rgb * color * weight;
    }
    sampler_state.flags = flags;
#endif // RENDER_WINDOW_PROJECTION

    const float SAMPLE_WEIGHT = 1. / float(VOLUMETRIC_SAMPLES);
    float base_weight = VOLUMETRIC_STRENGTH * SAMPLE_WEIGHT;

#if defined(VOLUMETRIC_SOFT_EDGE)
    float travel_dist = (t_leave - t_enter) * VIEW_DISTANCE;
    base_weight *= linear_step(0., sqr(VOLUMETRIC_SOFT_EDGE), sqr(travel_dist));
#endif

	for (float f=noise*SAMPLE_WEIGHT; f<1.; f+=SAMPLE_WEIGHT)
    {
        vec3 p = enter + travel * f;
        float window_dist = p.x * (1. / VOL_SUN_DIR.x);
        float weight = base_weight * volumetric_falloff(window_dist);

        vec2 uv = (p - window_dist * VOL_SUN_DIR).yz + uv_offset;
        vec4 sample_color = texture_lod(sampler_state, uv, mask_lod);
        sample_color = gamma_to_linear(sample_color);

#if VOLUMETRIC_ANIM
        float time = g_animTime;
        time += smooth_noise(window_dist * (1./16.));
        uv += time * vec2(7., 1.3);
        uv += sin(uv.yx * (1./15.) + time * .3) * 3.;
        weight *= smooth_noise(uv * (7./64.)) * 1.5 + .25;
#endif // VOLUMETRIC_ANIM

        weight *= volumetric_player_shadow(p, relative_cam_pos);
        
        fragColor.rgb += sample_color.rgb * weight;
    }

    fragColor.rgb = clamp(fragColor.rgb, 0., 1.);
#endif // RENDER_VOLUMETRICS
}

////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    Options options;
    LOAD(options);
    
    g_downscale = get_downscale(options);
    vec2 actual_res = min(ceil(iResolution.xy / g_downscale * .125) * 8., iResolution.xy);
    if (max_component(fragCoord - .5 - actual_res) > 0.)
        DISCARD;
    
    bool is_thumbnail = test_flag(int(load(ADDR_RESOLUTION).z), RESOLUTION_FLAG_THUMBNAIL);
    Lighting lighting;
    LOAD(lighting);
    
	UPDATE_TIME(lighting);
    UPDATE_DEMO_STAGE(fragCoord, g_downscale, is_thumbnail);

    vec4 current = texelFetch(iChannel0, ivec2(fragCoord), 0);
    GBuffer gbuffer = gbuffer_unpack(current);
    if (current.z <= 0.)
    {
        fragColor = vec4(vec3(1./16.), 1);
        return;
    }
    
    Timing timing;
    LOAD(timing);
    g_animTime = timing.anim;
    
    bool is_viewmodel = is_material_viewmodel(gbuffer.material);
    vec4 noise = BLUE_NOISE(fragCoord);
    
	vec4 camera_pos = load_camera_pos(SETTINGS_CHANNEL, is_thumbnail);
    vec3 camera_angles = load_camera_angles(SETTINGS_CHANNEL, is_thumbnail).xyz;
    vec3 velocity = load(ADDR_VELOCITY).xyz;
    Transitions transitions; LOAD(transitions);
    mat3 view_matrix = rotation(camera_angles.xyz);
    if (is_viewmodel)
    {
        float base_fov_y = scale_fov(FOV, 9./16.);
        float fov_y = compute_fov(iResolution.xy).y;
        float fov_y_delta = base_fov_y - fov_y;
        view_matrix = view_matrix * rotation(vec2(0, fov_y_delta*.5));
    }

    vec4 ndc_scale_bias = get_viewport_transform(iFrame, iResolution.xy, g_downscale);
    ndc_scale_bias.xy /= iResolution.xy;
    vec2 fragCoordNDC = fragCoord * ndc_scale_bias.xy + ndc_scale_bias.zw;
    
    vec4 plane;
    plane.xyz = gbuffer.normal;
    if (is_viewmodel)
    	plane.xyz = plane.xyz * view_matrix;
    vec3 dir = view_matrix * unproject(fragCoordNDC);
    vec3 surface_point = dir * VIEW_DISTANCE * current.z;
    plane.w = -current.z * dot(plane.xyz, dir);
    
    if (is_viewmodel)
    {
        float light_level =
            is_demo_mode_enabled(is_thumbnail) ?
            mix(.4, .6, hash1(camera_pos.xy)) :
        	gbuffer_unpack(texelFetch(iChannel0, ivec2(iResolution.xy)-1, 0)).light;
        gbuffer.light = mix(gbuffer.light, 1., .5) * light_level * 1.33;
        surface_point = surface_point * view_matrix;
        surface_point.y -= get_viewmodel_offset(velocity, transitions.bob_phase, transitions.attack);
    }
    else
    {
        surface_point += camera_pos.xyz;
    }
    
    fragColor = apply_material(gbuffer, surface_point, plane.xyz, dir, current.z, options.flags, noise.zw);
	add_particles(fragColor, fragCoordNDC, camera_pos.xyz, view_matrix, current.z, transitions.attack, camera_pos.w);

    if (g_demo_stage == DEMO_STAGE_DEPTH || DEBUG_DEPTH != 0)
        fragColor = vec4(vec3(sqrt(current.z)), 0);
    if (g_demo_stage == DEMO_STAGE_LIGHTING || DEBUG_LIGHTING != 0 || test_flag(options.flags, OPTION_FLAG_SHOW_LIGHTMAP))
        fragColor.rgb = vec3(1);
    if (g_demo_stage == DEMO_STAGE_NORMALS || DEBUG_NORMALS != 0)
        fragColor = vec4(plane.xyz*.5+.5, 0);
    if (g_demo_stage == DEMO_STAGE_TEXTURES || DEBUG_TEXTURES != 0)
        fragColor.a = 0.;
    
    fragColor.rgb *= mix(1., min(2., gbuffer.light), linear_step(.0, .5, fragColor.a));
    fragColor.rgb = clamp(fragColor.rgb, 0., 1.);

#ifdef QUANTIZE_SCENE
    const float LEVELS = float(QUANTIZE_SCENE);
    const int SMOOTH_STAGES = (1<<DEMO_STAGE_DEPTH) | (1<<DEMO_STAGE_LIGHTING) | (1<<DEMO_STAGE_NORMALS);
    if (!test_flag(options.flags, OPTION_FLAG_TEXTURE_FILTER) &&
        !test_flag(SMOOTH_STAGES, 1<<g_demo_stage) &&
        !test_flag(options.flags, OPTION_FLAG_SHOW_LIGHTMAP))
    	fragColor.rgb = round(fragColor.rgb * LEVELS) * (1./LEVELS);
#endif
    
    fragColor.rgb = gamma_to_linear(fragColor.rgb);
    
    add_volumetrics
	(
        fragColor,
        camera_pos.xyz, dir, current.z,
        gbuffer.normal, gbuffer.uv_axis, is_viewmodel,
        options.flags, noise.y, is_thumbnail
    );

    // hack: disable motion blur for the gun model
    fragColor.a = is_viewmodel ? -1. : current.z;
}
