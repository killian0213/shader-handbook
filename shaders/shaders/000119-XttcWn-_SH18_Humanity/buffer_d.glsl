// Buffer D (buffer) — [SH18] Humanity by davidar
// https://www.shadertoy.com/view/XttcWn

// 2018 David A Roberts <https://davidar.io>

// soil moisture, vegetation, predator, prey, and human colonisation model

#define map(p) texture(iChannel0,fract((p)/iResolution.xy))
#define buf(p) texture(iChannel3,fract((p)/iResolution.xy))

vec2 move(float q) {
    return plate_move(q, iFrame, iTime);
}

vec4 climate(vec2 fragCoord, vec2 pass) {
    vec2 p = fragCoord * MAP_RES / iResolution.xy;
    if (p.x < 0.5) p.x = 0.5;
    vec2 uv = p / iResolution.xy;
    return texture(iChannel1, uv + pass);
}

vec2 offset(vec2 p) {
    vec4 c = map(p);
    vec4 n = map(p + N);
    vec4 e = map(p + E);
    vec4 s = map(p + S);
    vec4 w = map(p + W);
    if(iFrame % 3000 < 10 || c.x < 0.) { // no plate under this point
        return vec2(0);
    } else if (move(n.x) == S) {
        return N;
    } else if (move(e.x) == W) {
        return E;
    } else if (move(s.x) == N) {
        return S;
    } else if (move(w.x) == E) {
        return W;
    } else if (move(c.x) != vec2(0) && map(p - move(c.x)).x >= 0.) { // rift
        return vec2(0);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if (iTime < OCEAN_START_TIME) {
        fragColor = vec4(0);
        return;
    }
    
    float height = MAP_HEIGHT(texture(iChannel0, fragCoord/iResolution.xy).z);
    float temp = climate(fragCoord, PASS3).y;
    float vapour = texture(iChannel2, fragCoord/iResolution.xy).w;
    vec2 p = fragCoord + offset(fragCoord);
    vec4 c = buf(p);
    float moisture = c.w;
    moisture *= 1. - 1e-5 * moisture * clamp(temp, 0., 15.);
    if (iTime > OCEAN_END_TIME) moisture += 3. * clamp(vapour, 0., 0.01);
    moisture = clamp(moisture, 0., 5.);
    if (height == 0.) moisture = 5.;
    
    if (iTime < OCEAN_END_TIME) {
        c.xyz = hash32(fragCoord) * vec3(0.5, 1., 2.);
    } else if(height > 0.) {
        float reproduction = 2. + clamp(temp, -15., 15.)/30.;
        // easier for prey to evade predators at higher altitudes which tend to have more hiding places
        float evasion = clamp(height, 0.5, 1.5);
        float predation = 2. - evasion;
        
        // generalised Lotka-Volterra equations
        float vege = c.x;
        float prey = c.y;
        float pred = max(c.z, 0.);
        float human = max(-c.z, 0.);
        float dvege = plant_growth(moisture, temp) - prey;
        float dprey = reproduction * vege - predation * pred - 0.5;
        float dpred = predation * prey - 1.;
        float dt = 0.1;
        vege += dt * vege * dvege;
        prey += dt * prey * dprey;
        pred += dt * pred * dpred;
        c.xyz = clamp(vec3(vege, prey, pred), 0.01, 5.);

        // diffusion
        vec4 n = buf(p + N);
        vec4 e = buf(p + E);
        vec4 s = buf(p + S);
        vec4 w = buf(p + W);
        c.xyz += dt * (max(n,0.) + max(e,0.) + max(s,0.) + max(w,0.) - 4. * c).xyz * vec3(0.25, 0.5, 1.);
        
        if (iTime > STORY_END_TIME) {
            human = 0.;
        } else if (iTime > HUMAN_START_TIME && iTime < WARMING_START_TIME &&
                   moisture > 4.9 && 5. < temp && temp < 30.) {
            int dir = int(4.*hash13(vec3(p,iFrame)));
            if (length(hash33(vec3(p,iFrame))) < 1e-2) human = 1.;
            if ((dir == 0 && s.z == -1.) ||
                (dir == 1 && w.z == -1.) ||
                (dir == 2 && n.z == -1.) ||
                (dir == 3 && e.z == -1.)) {
                human = 1.;
            }
        } else if (temp > 35.) {
            // approximating the maximum wet-bulb temperature by the average (dry-bulb) air temperature
            // sustained wet-bulb temperature above 35C is fatal for humans:
            // http://www.pnas.org/content/107/21/9552
            // photosynthesis of crops also becomes ineffective at similar temperatures
            human -= 0.01;
        }
        if (human > 0.) c.z = -human;
    } else {
        c.xyz = vec3(0);
    }
    
    fragColor = vec4(c.xyz, moisture);
}