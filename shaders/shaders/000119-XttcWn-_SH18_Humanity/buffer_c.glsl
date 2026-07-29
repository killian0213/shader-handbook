// Buffer C (buffer) — [SH18] Humanity by davidar
// https://www.shadertoy.com/view/XttcWn

// 2018 David A Roberts <https://davidar.io>

// wind flow map, atmospheric water vapour, and air pollution model

float map(vec2 fragCoord) {
    return MAP_HEIGHT(texture(iChannel0, fragCoord/iResolution.xy).z);
}

vec2 getVelocity(vec2 uv) {
    vec2 p = uv * MAP_RES;
    if (p.x < 0.5) p.x = 0.5;
    vec2 v = texture(iChannel1, p/iResolution.xy + PASS4).xy;
    if (length(v) > 1.) v = normalize(v);
    return v;
}

vec2 getPosition(vec2 fragCoord) {
    for(int i = -1; i <= 1; i++) {
        for(int j = -1; j <= 1; j++) {
            vec2 uv = (fragCoord + vec2(i,j)) / iResolution.xy;
            vec2 p = texture(iChannel2, fract(uv)).xy;
            if(p.x == 0.) {
                if (hash13(vec3(fragCoord + vec2(i,j), iFrame)) > 1e-4) continue;
                p = fragCoord + vec2(i,j) + hash21(float(iFrame)) - 0.5; // add particle
            } else if (hash13(vec3(fragCoord + vec2(i,j), iFrame)) < 8e-3) {
                continue; // remove particle
            }
            vec2 v = getVelocity(uv);
            p = p + v;
            p.x = mod(p.x, iResolution.x);
            if(abs(p.x - fragCoord.x) < 0.5 && abs(p.y - fragCoord.y) < 0.5)
                return p;
        }
    }
    return vec2(0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    if (iFrame < 10) {
        fragColor = vec4(0);
        return;
    }
    
    vec4 c = texture(iChannel2, fragCoord/iResolution.xy);
    float particle = (c.x > 0.) ? 1. : 0.9 * c.y;
    vec2 p = getPosition(fragCoord);
    fragColor.xy = (p == vec2(0)) ? vec2(0., particle) : p;
    
    vec2 uv = fragCoord/iResolution.xy;
    
    vec2 v = getVelocity(uv);
    vec2 vn = getVelocity(uv + N/iResolution.xy);
    vec2 ve = getVelocity(uv + E/iResolution.xy);
    vec2 vs = getVelocity(uv + S/iResolution.xy);
    vec2 vw = getVelocity(uv + W/iResolution.xy);
    float div = (ve - vw).x/2. + (vn - vs).y/2.;
    
    float height = map(fragCoord);
    float hn = map(fragCoord + N);
    float he = map(fragCoord + E);
    float hs = map(fragCoord + S);
    float hw = map(fragCoord + W);
    vec2 hgrad = vec2(he - hw, hn - hs)/2.;
    
    vec4 climate = texture(iChannel1, uv * MAP_RES / iResolution.xy + PASS3);
    float mbar = climate.x;
    float temp = climate.y;
    c = texture(iChannel2, fract((fragCoord - v) / iResolution.xy));
    
    // water vapour advection
    float w = c.w;
    float noise = clamp(3. * FBM(vec3(5. * fragCoord/iResolution.xy, iTime)) - 1., 0., 1.);
    if (iTime < OCEAN_END_TIME) w += 0.08 * noise * (1. - smoothstep(OCEAN_START_TIME, OCEAN_END_TIME, iTime));
    if (height == 0.) w += noise * clamp(temp + 2., 0., 100.)/32. * (0.075 - 3. * div - 0.0045 * (mbar - 1012.));
    w -= 0.005 * w; // precipitation
    w -= 0.3 * length(hgrad); // orographic lift
    fragColor.w = clamp(w, 0., 3.);
    
    // pollution advection
    float co2 = c.z;
    vec4 d = texture(iChannel3, fragCoord/iResolution.xy);
    bool human = d.z == -1.;
    float moisture = d.w;
    if (human) {
        co2 += 0.015;
    } else {
        co2 -= 0.01 * plant_growth(moisture, temp);
    }
    fragColor.z = clamp(co2, 0., 3.);
}