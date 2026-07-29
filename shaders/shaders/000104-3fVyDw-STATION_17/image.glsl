// Image (image) — STATION 17 by Zerofile
// https://www.shadertoy.com/view/3fVyDw

#define rgb(r,g,b) vec3(r,g,b) / 255.0
#define grgb(r,g,b) vec3(r,g,b) * vec3(r,g,b) / 65025.0

vec3 sunDir() {
    
    float t = mod((iTime + 1.0) / 15.0, 4.0);
    
    if (t > 3.0) return normalize(vec3(-0.1, 0.0, 1.0));
    if (t > 2.0) return normalize(vec3(3.0, 0.0, 0.0));
    if (t > 1.0) return normalize(vec3(-1.0, 1.0, 0.7));
    if (t > 0.0) return normalize(vec3(2.0, 3.0, 0.7));
}

/*
noise
*/

float noise(float seed) {
    return fract( sin(seed) * 753.5453 );
}

float sNoise(vec3 position) {

    vec3 pi = floor(position);
    vec3 pm = fract(position);

    pm *= pm * (3.0 - 2.0 * pm);

    float vx = dot(pi, vec3(1.0, 157.0, 113.0));

    return mix(
        mix(
            mix(noise(vx         ), noise(vx + 1.0   ), pm.x),
            mix(noise(vx + 157.0 ), noise(vx + 158.0 ), pm.x),
            pm.y
        ),
        mix(
            mix(noise(vx + 113.0 ), noise(vx + 114.0 ), pm.x),
            mix(noise(vx + 270.0 ), noise(vx + 271.0 ), pm.x),
            pm.y
        ),
        pm.z
    );

}

// worley-sphere
// same principle as: https://www.shadertoy.com/view/t32yzd
float wsNoise(vec3 dir, float rad) {
    dir *= rad;
	vec3 pi = floor(dir);
    vec3 pm = fract(dir);

    float mx = 1.732;

    for (int i = -1; i <= 1; i++) {
    	for (int j = -1; j <= 1; j++) {
    		for (int k = -1; k <= 1; k++) {
    			float rng = dot(pi + vec3(i, j, k), vec3(1.0, 157.0, 113.0));
    			rng = noise(rng);
    			vec3 cell = vec3(rng, fract(rng * 16.0), fract(rng * 256.0));
    			cell += vec3(i, j, k) + pi;
                float l = length(cell);
                if (abs(l - rad) < 0.4) {
                cell = cell / l * rad;
    			mx = min(length(cell - dir), mx);}
    		}
    	}
    }

    return mx / 1.732;
}


/*
rendering
*/

void space(vec3 dir, vec3 pos, inout vec3 col) {
    
    // stars 
    
    float star = wsNoise(dir, 20.0);
    star *= 250.0; star = exp(-(star * star));
    col = star * grgb(252, 198, 3) * 8.0;
    
    // wisps
    
    vec3 s = dir * 0.2;
    s += texture(iChannel0, s).brg * 0.04;
    float l = texture(iChannel0, s).r;
    s += 1.618; s *= 2.0; 
    l += texture(iChannel0, s).r * 0.5;
    s += 1.618; s *= 2.0; 
    l += texture(iChannel0, s).r * 0.25;
    s += 1.618; s *= 2.0; 
    l += texture(iChannel0, s).r * 0.125;
    l /= 1.875; l *= l; l *= l;
    
    col *= exp(-l * 8.0);
    
    col += (l * 8.0 + 0.2) * grgb(2, 64, 19) * 0.2;
    col += l *l * grgb(237, 172, 21);
    

}

float airmass(float s, float e, float a, float b) {
    float o = 0.0;
    float t = s;
    float dt = (e - s) / 40.0;
    for (int i = 0; i < 40; i++) {
        o += exp(-b * sqrt(a + t*t)) * dt;
        t += dt;
    }
    
    return o;
}

void planetSurface(vec3 dir, inout vec3 albedo) {
    albedo = grgb(242, 230, 160);
    
    // cloud
    
    vec3 s = dir * vec3(5.0, 20.0, 5.0);
    s += texture(iChannel0, dir * 5.0).rgb * 0.65;
    s += texture(iChannel0, dir * 2.0).rgb * 0.25;
    s += texture(iChannel0, dir * 1.0).rgb * 0.5;
    s += texture(iChannel0, s * 0.003).rgb * 5.0;
    s += texture(iChannel0, s * 0.014 + vec3(0.618)).rgb * 2.5;
    s += texture(iChannel0, s * 0.047 + 2.0 * vec3(0.618)).rgb * 3.0;
    s += texture(iChannel0, dir * 1.0).rgb * 1.0;
    s += texture(iChannel0, dir * 2.0).rgb * 0.5;
    
    float c = sNoise(s * 0.5  + iTime * 0.3 + 0.4 );
    albedo = mix(albedo, vec3(1.0) * (0.5 + c*c * 0.6), 
    clamp(c * 3.0 - 1.0, 0.0, 1.0) * 0.5);

}

const vec3 plPos = vec3(-0.8, -0.3, 1.5);
const float plRad = 0.7;

void planet(vec3 dir, vec3 pos, inout vec3 col) {
    
    float proj = dot(plPos - pos, dir);
    vec3 o = plPos - pos - dir * proj;
    float a2 = plRad * plRad - dot(o,o);
    
    vec3 hit; vec3 norm;
    if (a2 > 0.0) {
    
        hit = plPos - o - sqrt(a2) * dir;
        norm = normalize(hit - plPos);
        
        vec3 albedo; planetSurface(norm, albedo);
        col = albedo * 2.5;
        
        col *= max(dot(norm, sunDir()), 0.0);
        
    }
    
    // atmosphere
    // uses approx 'e^(-d)' distribution for absorbtion
    // with single-sample approximation for contributed lighting
    
    float alpha_l = exp(25.0); float alpha_u = exp(4.0);
    float beta_l = 32.0; float beta_u = 6.0;
    
    float r = dot(o,o);
    
    float end = 10.0;
    if (a2 > 0.0) end = -sqrt(a2);
    
    float A = exp(-airmass(-proj, end, r, beta_l) * alpha_l
                  -airmass(-proj, end, r, beta_u) * alpha_u);
    col *= A;
    
    // contribute lighting (approx)
    
    vec3 exC = normalize(pos - plPos); // extreme contribution angle
    if (proj > 0.0) exC = -normalize(o);
    if (a2 > 0.0) exC = norm;
    float l = dot(exC, sunDir());
    vec3 l2 = 0.5 + 0.5 * tanh(4.0 * l - vec3(-0.2, 0.5, 0.8));
    
    col += (1.0 - A) * l2 * grgb(197, 250, 234) * 0.56;
    
}

const vec3 stPos = vec3(0.025, -0.001, 0.05);
const vec3 upAxis = normalize(vec3(-0.3, 1.0, 0.3));
const float stScale = 0.01;

vec3 toStationSpace(vec3 pos) {
    
    const vec3 tangent = normalize(cross(upAxis, vec3(1.0, -2.0, 0.0))); 
    const vec3 bitangent = normalize(cross(tangent, upAxis));
    const mat3 rot = mat3(tangent, upAxis, bitangent);
    
    pos -= stPos;
    pos = transpose(rot) * pos;
    pos /= stScale;
    
    float t = iTime * 0.1;
    pos.xz = mat2(cos(t), sin(t), -sin(t), cos(t)) * pos.xz;

    return pos;
}
    
float stationDF(vec3 pos) {

    pos = toStationSpace(pos);
    
    vec2 rpos = vec2(length(pos.xz), pos.y);
    float d, df;
    
    // top dome
    d = length(rpos - vec2(0.0, 1.0)) - (3.0 - sqrt(5.0));
    if (rpos.y < 1.0) {
        d = 1.0 - rpos.y;
        if (rpos.x > 3.0 - sqrt(5.0)) d = length(vec2(3.0 - sqrt(5.0),1.0) - rpos);
    }
    
    df = d;
    // pin
    d = 3.0 - length(rpos - vec2(3.0,-1.0));
    if (rpos.x > 3.0 - sqrt(5.0)) d = max(d,  rpos.x - (3.0 - sqrt(5.0)));
    if (rpos.y >  1.0) d = max(d, rpos.y - 1.0);
    if (rpos.y < -0.87) d = max(d,-rpos.y + 0.87);
    df = min(df, d);
    // ring 1
    d = length(rpos - vec2(1.0, 0.5)) - 0.1;
    df = min(df, d);
    // ring 2
    d = length(rpos - vec2(0.75, -0.1)) - 0.1;
    df = min(df, d);
    
    float a = atan(pos.z, pos.x); a = mod(a, 3.141592 / 3.0) - 3.141592 / 6.0;
    vec2 hpos = vec2(cos(a), sin(a)) * length(pos.xz);
    // beams
    d = length(vec3(clamp(hpos.x,0.0,1.0) - hpos.x, hpos.y, pos.y - 0.5)) - 0.015;
    df = min(df, d);
    d = length(vec3(clamp(hpos.x,0.0,0.75) - hpos.x, hpos.y, pos.y + 0.1)) - 0.015;
    df = min(df, d);
    
    return df * stScale;
}

void lightWindows(vec3 pos, float rad, float lower, float upper, inout vec3 light) {
    if (pos.y < lower || pos.y > upper) return;
    float div = round((upper - lower) / 0.015);
    if (abs(fract((pos.y - lower) / (upper - lower) * div) - 0.5) > 0.3) return;
    if (abs(length(pos.xz) / rad - 1.0) > 0.15) return;
    float segments = rad * 20.0;
    float a = atan(pos.z, pos.x);
    float b = fract(a / (3.141592 * 2.0) * segments);
    if (abs(b - 0.5) > 0.45) return;
    b = fract(a / (3.141592 * 2.0) * segments * 10.0);
    if (abs(b - 0.5) > 0.4) return;
    
    if (abs(fract((b - 0.1) / 0.8 * 3.0) - 0.5) > 0.4) return;
    
    float id = floor(a / (3.141592 * 2.0) * segments * 10.0);
    float rand = sNoise(vec3(id, pos.y * 40.0, rad) * 4.0);
    
    light += grgb(252, 198, 3) * rand * 1.6;
}

void stationSurface(vec3 pos, inout vec3 albedo, inout vec3 light) {

    pos = toStationSpace(pos);
    
    light = vec3(0.0);
    albedo = grgb(230, 228, 202);
    
    if (abs(pos.y - 1.1) < 0.04) albedo = grgb(181, 179, 156);
    if (abs(pos.y - 1.16) < 0.01) albedo = grgb(181, 179, 156);
    
    lightWindows(pos, 0.05, -0.47, -0.42, light);
    lightWindows(pos, 0.25, 0.19, 0.25, light);
    lightWindows(pos, 0.33, 0.36, 0.4, light);
    lightWindows(pos, 0.62, 0.83, 0.84, light);
    
    lightWindows(pos, 1.1, 0.51, 0.54, light);
    lightWindows(pos, 0.85, -0.09, -0.07, light);
    
}

void station(vec3 dir, vec3 pos, inout vec3 col) {
    vec3 ray = pos;
    bool intersection = false;
    
    for (int i = 0; i < 200; i++) {
        float d = stationDF(ray);
        if (d < 0.000001) {intersection = true; break;}
        if (d > 4.0) break; // exit if too far
        ray += d * dir;
    }
    
    if (intersection) {
        
        vec2 e = vec2(0.000001,0.0);
        vec3 norm = vec3(stationDF(ray + e.xyy),
                         stationDF(ray + e.yxy),
                         stationDF(ray + e.yyx))
                  - vec3(stationDF(ray));
        norm = normalize(norm);
        
        vec3 albedo, light;
        stationSurface(ray, albedo, light);
        
        vec3 diffuse = max(dot(norm, sunDir()), 0.0) * vec3(2.5);
        
        
        // shadows
        
        ray += 0.00001 * norm;
        bool intersection = false;
        vec3 sd = sunDir();
        for (int i = 0; i < 200; i++) {
            float d = stationDF(ray);
            if (d < 0.000001) {intersection = true; break;}
            if (d > 4.0) break;
            ray += d * sd;
        }
        if (intersection) diffuse = vec3(0.0);
        
        // re-bound from planet
        vec3 plDiffuse = max(dot(norm, normalize(plPos - stPos)), 0.0) 
                       * (grgb(242, 230, 160) * 0.4 + grgb(197, 250, 234)) * 0.2;
        diffuse += plDiffuse;
        
        col = albedo * diffuse + light;
    }
}

void render(vec2 uv, inout vec3 col) {
    
    vec3 dir = normalize(vec3(uv, 1.0));
    vec3 pos = vec3(0.0);
    
    col = vec3(0.0);
    
    space(dir, pos, col);
    planet(dir, pos, col);
    station(dir, pos, col);
    
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    uv -= 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    vec3 col = rgb(0, 0, 0);
    
    // 4xAA
    vec3 tmp;
    for (float x = 0.0; x < 2.0; x+=1.0) {
        for (float y = 0.0; y < 2.0; y+=1.0) {
            render(uv + vec2(x,y) / iResolution.xy * 0.5, tmp);
            col += tmp * 0.25;
        }
    }
    
    // tone
    col = sqrt(tanh(col + dot(col, col) * vec3(0.05)));
    
    // fade
    float t = mod((iTime + 1.0) / 15.0, 4.0);
    t = fract(t + 0.5);
    col *= clamp(abs(t - 0.5) * 16.0,0.0, 1.0);
    
    // mark
    
    float f = length(fragCoord / iResolution.xy - vec2(0.5)) / 0.71;
    f *= f; f *= f; f *= 0.2;
    col.rg *= 1.0 - f; f *= 1.5;
    ivec2 i = ivec2(fragCoord * 0.5);
    if (((i.x ^ i.y) ^ (i.x + i.y)) % 5 == 0) {
        col = col * (1.0 - f) + f;
    }
    
    fragColor = vec4(col,1.0);
}