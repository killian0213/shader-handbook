// Buffer C (buffer) — Thousands of indexed particles by morimea
// https://www.shadertoy.com/view/tstSz7

// base on https://www.shadertoy.com/view/wdG3Wd
// thanks to https://www.shadertoy.com/user/capsadmin for making BufC little better

vec2 GRID_POS;

vec4 loadval(ivec2 ipx) {
    return texelFetch(iChannel0, ipx, 0);
}

// data (used 0xffffff INT without conversion to uint)
// in [x,y,z,w]
// x-0xfffff-posx, 0xf-data
// y-0xfffff-posy, 0xf-data
// z-0xffff-velx, 0xff-data
// w-0xffff-vely, 0xff-data
// data used to store particle IDs

// get [pos,vel]

vec2 get_particle_pos(in vec2 p) {
    if(p.x < 0.001 || p.y < 0.001)
        return vec2(0);

    float max_pos = abs(SETTING_RESOLUTION.x);
    vec4 tval = texelFetch(iChannel2, ivec2(p), 0);
    float p1 = decodeval_pos(int(tval.x)) * max_pos;
    float p2 = decodeval_pos(int(tval.y)) * max_pos;

    return vec2(p1, p2);
}

vec2 get_particle_vel(in vec2 p) {
    if(p.x < 0.001 || p.y < 0.001)
        return vec2(0);

    vec4 tval = texelFetch(iChannel2, ivec2(p), 0);
    float v1 = decodeval_vel(abs(int(tval.z)));
    float v2 = decodeval_vel(abs(int(tval.w)));
    float si = 1.;
    if(tval.z < 0.)
        si = -1.;
    float si2 = 1.;
    if(tval.w < 0.)
        si2 = -1.;
    vec2 unp = vec2(si * v1, si2 * v2);
    return unp.xy;
}

ivec2 extra_dat_vel(vec2 p) {
    vec4 tval = texelFetch(iChannel2, ivec2(p), 0);
    return ivec2(abs(int(tval.z)) & 0xff, abs(int(tval.w)) & 0xff);
}

ivec2 extra_dat_pos(vec2 p) {
    vec4 tval = texelFetch(iChannel2, ivec2(p), 0);
    return ivec2(int(tval.x) & 0xf, int(tval.y) & 0xf);
}

// get saved unique ID
int get_particle_uid(vec2 p) {
    ivec2 v1 = extra_dat_pos(p);
    ivec2 v2 = extra_dat_vel(p);
    int iret = (v1[0] << 20) | (v1[1] << 16) | (v2[0] << 8) | (v2[1] << 0);
    return iret;
}

ivec4 encode_particle_uid(int id) {
    int a = (id >> 20) & 0xf;
    int b = (id >> 16) & 0xf;
    int c = (id >> 8) & 0xff;
    int d = (id >> 0) & 0xff;
    return ivec4(a, b, c, d);
}

vec2 pack_pos(vec2 pos, ivec2 extra_val, float max_pos) {
    int v1 = max(int((pos.x / max_pos) * float(0xfffff)), 0);
    int v2 = max(int((pos.y / max_pos) * float(0xfffff)), 0);
    float px = float(encodeval_pos(ivec2(v1, extra_val.x)));
    float py = float(encodeval_pos(ivec2(v2, extra_val.y)));
    return vec2(px, py);
}

vec2 pack_vel(vec2 vel, ivec2 extra_val) {
    int v1 = abs(int(vel.x * float(0xffff)));
    int v2 = abs(int(vel.y * float(0xffff)));
    float vx = float(encodeval_vel(ivec2(v1, extra_val.x)));
    float vy = float(encodeval_vel(ivec2(v2, extra_val.y)));
    float si = 1.;
    if(vel.x < 0.)
        si = -1.;
    float si2 = 1.;
    if(vel.y < 0.)
        si2 = -1.;
    return vec2(vx * si, vy * si2);
}

// save everything to pixel color
vec4 encode_particle(vec2 pos, vec2 vel, int id) {
    ivec4 tid = encode_particle_uid(id);
    ivec2 extra_data_pos = tid.xy;
    ivec2 extra_data_vel = tid.zw;
    float max_pos = abs(SETTING_RESOLUTION.x);
    vec2 pos_ret = pack_pos(pos, extra_data_pos, max_pos);
    vec2 vel_ret = pack_vel(vel, extra_data_vel);
    return vec4(pos_ret, vel_ret);
}

bool should_apply_mouse_force() {
    return SETTING_MOUSE_MODE_FORCE || SETTING_MOUSE_MODE_SPAWN;
}

bool is_spawning_particles() {
    return SETTING_MOUSE_MODE_SPAWN && iMouse.z > 0.0;
}

bool should_reset() {
    bool mouseReset = (SETTING_IS_RESET) || (SETTING_IS_CLEAN);
    return iFrame <= 10 || mouseReset;
}

vec2 get_particle_gravity() {
    return SETTING_GRAVITY * maxG * M;
}

vec2 get_world_mouse_position() {
    vec2 cam_pos = SETTING_VIEW_POS - vec2(0.015);
    float cam_scale = max(0.001, SCALE_size_non_linear(SETTING_ZOOM));

    float mn = 1.0;
    if(cam_scale > 0.95)
        cam_scale = 1.0;

    if(SETTING_ZOOM > 0.95)
        mn = 0.0;

    return (iMouse.xy + mn * iResolution.y * cam_pos / cam_scale) * cam_scale;
}

vec2 get_mouse_force(vec2 pos) {
    vec2 mouseDir = pos - get_world_mouse_position();
    float d2 = dot(mouseDir, mouseDir);

    return M * MOUSE_F *
        clamp(iMouse.z, 0.0, 1.0) * // mouse clicked outside zoom region
        mouseDir * BALL_SIZE / max(d2, 0.01);
}

vec4 reset_sim() {
    if(SETTING_IS_CLEAN) {
        return vec4(0);
    }

    ivec2 iv = ivec2(GRID_POS);
    float max_posy = abs(SETTING_RESOLUTION.y);

    if((iv.x + iv.y) % 2 == 0 && iv.y % 2 == 0 && iv.y < int(max_posy * H)) {

        int id = int(floor(GRID_POS.x) + floor(GRID_POS.y - GRID_POS.y / 2.) * iResolution.x) / 2;
        vec2 pos = (GRID_POS + (rand(GRID_POS) - 0.5) * 0.25);
        vec2 vel = vec2(0.);

        return encode_particle(pos, vel, id);

    }

    return vec4(0);
}

vec3 do_collisions(vec2 pos) {
    vec2 force = vec2(0);
    float stress = 0.0;

    for(int x = -2; x <= 2; x++) {
        for(int y = -2; y <= 2; y++) {
            if(x != 0 || y != 0) {
                vec2 other_pos = get_particle_pos(GRID_POS + vec2(x, y));
                if(other_pos.x <= 0.0)
                    continue;

                vec2 dir = pos - other_pos;
                float len = length(dir);
                float f = BALL_D - len;
                if(len >= 0.001 * BALL_SIZE && f > 0.0) {
                    float f2 = f / (BALL_D);
                    f2 += SQ_K * f2 * f2;
                    f2 *= BALL_D;
                    vec2 force_part = E_FORCE * normalize(dir) * f2;
                    force += force_part;
                    stress += abs(force_part.x) + abs(force_part.y);
                }
            }
        }
    }

    return vec3(force, stress);
}

vec4 spawn_particles() {
    if(iFrame % 3 == 0) {
        // don't spawn too fast
        return vec4(0);
    }

    if((length(trunc(GRID_POS) - trunc(get_world_mouse_position())) < SPAWN_point_size)) {

        int uid = iFrame;
        vec2 pos = (GRID_POS + (rand(GRID_POS) - 0.5) * 0.25);
        vec2 vel = vec2(0);

        return encode_particle(pos, vel, uid);
    }

    // spawn nothing outside of the mouse point
    return vec4(0);
}

struct Particle {
    int uid;
    vec2 pos;
    vec2 vel;
};

bool load_particle(out Particle particle) {
    particle.uid = 0;
    particle.pos = vec2(0.0);
    particle.vel = vec2(0.0);

    for(int x = -1; x <= 1; x++) {
        for(int y = -1; y <= 1; y++) {
            vec2 grid_pos_offset = GRID_POS + vec2(x, y);
            vec2 pos = get_particle_pos(grid_pos_offset);

            if(trunc(GRID_POS) == trunc(pos)) {
                particle.uid = get_particle_uid(trunc(grid_pos_offset));
                particle.pos = pos;
                particle.vel = get_particle_vel(grid_pos_offset);

                return true;
            }
        }
    }

    return false;
}

vec4 sim_step() {
    Particle particle;

    if(!load_particle(particle)) {
        if(is_spawning_particles()) {
            return spawn_particles();
        }

        return vec4(0);
    }

    vec3 res = do_collisions(particle.pos);
    vec2 direction = res.xy;

    if(should_apply_mouse_force()) {
        float stress = res.z;
        direction += get_mouse_force(particle.pos) * max(stress, 1.0);
    }

    direction += get_particle_gravity();

    // don't apply damping to freely flying balls
    float damp_k = length(direction) > 0.001 ? DAMP_K : 1.0;

    particle.vel = damp_k * particle.vel + direction / M;
    particle.vel = clamp(particle.vel, vec2(-1.0), vec2(1.0));

    // what's this?
    if(SETTING_LAST_MOUSE.y < 0.0) {
        if((particle.pos.x <= 1.) || (particle.pos.x >= iResolution.x - 2.))
            particle.vel = vec2(0.);
        if((particle.pos.y <= 1.) || (particle.pos.y >= iResolution.y - 2.))
            particle.vel = vec2(0.);
    }

    particle.pos += particle.vel * VEL_LIMIT * SETTING_SPEED_SCALE;
    particle.pos = clamp(particle.pos, vec2(BALL_SIZE * (1.0 + sin(particle.pos.y) * 0.1), BALL_SIZE), iResolution.xy - vec2(BALL_SIZE));

    return encode_particle(particle.pos, particle.vel, particle.uid);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord_) {
    // this is used all over the place so lets make it a global
    GRID_POS = fragCoord_;

    if(should_reset()) {
        fragColor = reset_sim();
    } else {
        fragColor = sim_step();
    }
}
