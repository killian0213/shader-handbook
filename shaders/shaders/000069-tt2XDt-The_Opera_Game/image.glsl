// Image (image) — The Opera Game by Poita_
// https://www.shadertoy.com/view/tt2XDt

// The Opera Game, by Peter Alexander.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//
// The game is Paul Morphy's famous Opera Game.
//
// https://en.wikipedia.org/wiki/Opera_Game


///////////////////
// Feature flags //
///////////////////

// If performance isn't good enough then you can disable some of these.
// MSAAx4 has the largest perf cost.
#define RENDER_SKY true
#define RENDER_MIST true
#define RENDER_REFLECTIONS true
#define RENDER_SHADOWS true
#define MSAAx4 false

////////////
// Timing //
////////////

const float INTRO_TIME = 5.0;
const float TIME_PER_POSITION = 2.0;
const float OUTRO_TIME = 7.0;
const float INTERMISSION = 1.5;
const int TOTAL_POSITIONS = 34;
const float TOTAL_TIME = INTRO_TIME + TIME_PER_POSITION * float(TOTAL_POSITIONS) + OUTRO_TIME + INTERMISSION;
    
float loopTime() {
    return mod(iTime, TOTAL_TIME);
}

float introTime() {
    return min(1.0, loopTime() / INTRO_TIME);
}

float moveTime() {
	return max(0.0, loopTime() - INTRO_TIME);
}

float outroTime() {
    return clamp(1.0 - (loopTime() - (TOTAL_TIME - INTERMISSION - OUTRO_TIME)) / OUTRO_TIME, 0.0, 1.0);
}

float timeOfMove(float m) {
    return INTRO_TIME + m * TIME_PER_POSITION;
}

///////////
// Noise //
///////////

// Adapted from https://www.shadertoy.com/view/4ts3z2
float tri(float x) {
    return abs(fract(x) - 0.5);
}

vec3 tri3(vec3 p) {
   return abs(fract(p.zzy + abs(fract(p.yxx) - 0.5)) - 0.5);   
}
                                 
float triNoise3D(in vec3 p, float spd) {
    float z = 1.4;
	float rz = 0.0;
    vec3 bp = p;
	for (float i = 0.0; i <= 3.0; i++) {
        vec3 dg = tri3(bp * 2.0);
        p += (dg + iTime * .3 * spd);
        bp *= 1.8;
		z *= 1.5;
		p *= 1.2;    
        rz += tri(p.z + tri(p.x + tri(p.y))) / z;
        bp += 0.14;
	}
	return rz;
}

////////////////////
// SDF primitives //
////////////////////

float sphere(vec3 p, float r) {
	return length(p) - r;
}

float sphere2(vec2 p, float r) {
	return length(p) - r;
}

float ellipse(vec3 p, vec3 r) {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

float ellipse2(vec2 p, vec2 r) {
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

float box3(vec3 p, vec3 r) {
    vec3 d = abs(p) - r;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float box2(vec2 p, vec2 r) {
    vec2 d = abs(p) - r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float roundCone(vec3 p, float r1, float r2, float h) {
    vec2 q = vec2(length(p.xz), p.y);
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, vec2(-b, a));
    if(k < 0.0)
        return length(q) - r1;
    if(k > a * h)
        return length(q - vec2(0.0, h)) - r2;
    return dot(q, vec2(a, b)) - r1;
}

vec2 boxIntersect(vec3 ro, vec3 rd, vec3 rad)  {
    vec3 m = 1.0 / rd;
    vec3 n = m * ro;
    vec3 k = abs(m) * rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
	
    if(tN > tF || tF < 0.0)
        return vec2(-1.0); // no intersection
    return vec2(tN, tF);
}

float blend(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

//////////////////////
// SDF chess pieces //
//////////////////////

float pawn(vec3 p) {
    vec2 p2 = vec2(length(p.xz), p.y);
    float dt = sphere2(vec2(0, 1) - p2, 1.0);
    float dn = ellipse2(vec2(0, -0.15) - p2, vec2(1.0, 0.3));
    float dw0 = ellipse2(vec2(0, 0) - p2, vec2(0.5, 0.8));
    float dw1 = ellipse2(vec2(0, -2.3) - p2, vec2(0.9, 0.3));
    float dw2 = ellipse2(vec2(0, -2.1) - p2, vec2(1.4, 0.3));
    float db0 = ellipse2(vec2(0, -2.3) - p2, vec2(1.2, 0.6));
    float db1 = ellipse2(vec2(0, -3.3) - p2, vec2(2.0, 0.6));
    float db2 = ellipse2(vec2(0, -3.8) - p2, vec2(2.1, 0.5));
    float r = blend(dt, dn, 0.3);
    r = min(r, blend(dw0, dw1, 3.0));
    r = min(r, dw2);
    r = min(r, blend(blend(db0, db1, 1.2), db2, 0.3));
    return r;
}

float base(vec3 p, float rad) {
    vec2 p2 = vec2(length(p.xz), p.y);
    float dn = ellipse2(vec2(0, -1.0) - p2, vec2(1.3 * rad, 1.0));
    float db0 = ellipse2(vec2(0, -2.3) - p2, vec2(1.6 * rad, 0.6));
    float db1 = ellipse2(vec2(0, -3.3) - p2, vec2(2.5 * rad, 0.6));
    float db2 = ellipse2(vec2(0, -3.8) - p2, vec2(2.6 * rad, 0.5));
    float dw = ellipse2(vec2(0, -2.1) - p2, vec2(1.8 * rad, 0.3));
    float r = blend(blend(db0, db1, 1.0), db2, 0.3);
    r = min(r, dw);
    return r;
}

float base1(vec3 p) {
    return base(p, 1.0);
}

float base2(vec3 p) {
    float r = base(p, 1.2);
    vec2 p2 = vec2(length(p.xz), p.y);
    float dn = ellipse2(vec2(0, -1.4) - p2, vec2(1.15, 2.7));
    float dc = ellipse2(vec2(0, 2.0) - p2, vec2(1.6, 0.3));
    float dc1 = ellipse2(vec2(0, 2.2) - p2, vec2(1.5, 0.2));
    float dc2 = ellipse2(vec2(0, 2.8) - p2, vec2(1.2, 0.2));
    float ds = ellipse2(vec2(0, 5.9) - p2, vec2(1.9, 2.8));
    float dcut = box2(vec2(0, 7.2) - p2, vec2(3.0, 2.5));
    r = blend(r, dn, 1.8);
    r = blend(r, dc, 1.8);
    r = min(r, dc1);
    r = blend(r, dc2, 0.55);
    r = blend(r, ds, 1.1);
    return max(r, -dcut);
}

float rook(vec3 p, float base) {
    vec2 p2 = vec2(length(p.xz), p.y);
    float dn = ellipse2(vec2(0, -1.0) - p2, vec2(1.2, 1.3));
    float dc = ellipse2(vec2(0, 0.5) - p2, vec2(1.7, 0.2));
    float r = blend(base, dn, 1.0);
    r = blend(r, dc, 1.4);
    r = min(r, box2(vec2(1.4, 1.1) - p2, vec2(0.2, 0.6)));
    vec3 b3 = p;
    const float ang = 3.141593 * 2.0 / 3.0;
    const mat2 rot = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
    for (int i = 0; i < 3; ++i) {
        r = max(r, -box3(vec3(0, 1.4, 0) - b3, vec3(2.0, 0.6, 0.2)));
        b3.xz = rot * b3.xz;
    }
    return r;
}

float knight(vec3 p, float base) {
    p.x = abs(p.x);
    float ds1 = sphere(vec3(0.0, 2.0, 0.0) - p, 4.0);
    float ds2 = ellipse(vec3(0.0, 2.0, 0.0) - p, vec3(2.0, 5.0, 1.8));
    float dn = roundCone(vec3(-0.3, 1.0, 0.5) - p, 0.8, 2.2, 2.2);
    float dncut = ellipse(vec3(2.2, 0.0, 0.0) - p, vec3(1.5, 2.5, 5.0));
    const float a = 1.3;
    const mat3 rot = mat3(1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a));
    float dh = roundCone(rot * (vec3(0.0, 2.5, 0.5) - p), 1.2, 0.6, 1.9);
    float de = ellipse(vec3(0.5, 3.5, 0.5) - p, vec3(0.4, 0.5, 0.35));
    float dhcut1 = 0.5 - p.x;
    float dhcut2 = sphere(vec3(2.1, 2.8, -1.9) - p, 2.0);
    float dhs = ellipse(vec3(0.0, 2.2, 0.0) - p, vec3(2.0, 1.3, 2.3));
    float r2 = max(dn, -dncut);
    float h = dh;
    h = max(h, -dhcut1);
    h = max(h, -dhcut2);
    h = max(h, dhs);
    h = min(h, max(de, -dhcut1));
    r2 = blend(r2, h, 0.7);
    return min(base, max(max(r2, ds1), ds2));
}

float bishop(vec3 p, float base) {
    vec2 p2 = vec2(length(p.xz), p.y);
    float dn = ellipse2(vec2(0, -1.4) - p2, vec2(1.0, 1.6));
    float dc = ellipse2(vec2(0, 0.7) - p2, vec2(1.6, 0.3));
    float dc1 = ellipse2(vec2(0, 0.9) - p2, vec2(1.5, 0.2));
    float dc2 = ellipse2(vec2(0, 1.5) - p2, vec2(1.2, 0.2));
    float dh = ellipse2(vec2(0, 2.6) - p2, vec2(1.3, 1.5));
    float dt = ellipse2(vec2(0, 4.2) - p2, vec2(0.4, 0.4));
    const float ang = -0.4;
    const mat2 rot = mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
    vec3 c3 = vec3(0.8, 3.7, 0.0) - p;
    c3.xy = rot * c3.xy;
    float cut = box3(c3, vec3(0.2, 1.0, 2.0));
    float r = blend(base, dn, 0.9);
    r = blend(r, dc, 1.5);
    r = min(r, dc1);
    r = blend(r, dc2, 0.55);
    r = min(r, dh);
    r = min(r, dt);
    return max(r, -cut);
}

float king(vec3 p, float base) {
    vec2 p2 = vec2(length(p.xz), p.y);
    float dh = ellipse2(vec2(0, 4.6) - p2, vec2(1.8, 0.4));
    float dt1 = box3(vec3(0, 5.2, 0) - p, vec3(0.3, 1.5, 0.25)); 
    float dt2 = box3(vec3(0, 5.8, 0) - p, vec3(1.0, 0.3, 0.25));    
    float r = min(base, dh);
    r = min(r, dt1);
    return min(r, dt2);
}

float queen(vec3 p, float base) {
    vec2 p2 = vec2(length(p.xz), p.y);
    float dh = ellipse2(vec2(0, 4.0) - p2, vec2(1.3, 1.5));
    float dhcut = box2(vec2(0, 2.0) - p2, vec2(3.0, 2.0));
    float dt = ellipse2(vec2(0, 5.6) - p2, vec2(0.5, 0.5));
    vec3 pc = vec3(abs(p.x), p.y, abs(p.z));
    if (pc.x > pc.z)
        pc = pc.zyx;
    float dccut = sphere(vec3(1.0, 4.7, 2.2) - pc, 1.1);
    float r = min(base, max(dh, -dhcut));
    return max(min(r, dt), -dccut);
}

// State of the board throughout the game.
// Each square is 4 bits (13 possibilities: 6 white, 6 black, or empty)
// Each row is an int (32 bits)
// Each board is 8 ints.
// Total 34 positions.
int board(int m, int r) {
    if (r == 0) {
        if (m < 3) return 591750194;
        if (m < 9) return 541418546;
        if (m < 11) return 541393970;
        if (m < 15) return 537199666;
        if (m < 17) return 537199618;
        if (m < 23) return 537198594;
        if (m < 25) return 536880384;
        if (m < 27) return 536872192;
        if (m < 33) return 9472;
        return 1280;
    }
    if (r == 1) {
        if (m < 1) return 286331153;
        if (m < 5) return 286265617;
        return 286261521;
    }
    if (r == 2) {
     	if (m < 3) return 0;
        if (m < 8) return 3145728;
        if (m < 9) return 10485760;
        if (m < 13) return 6291456;
        if (m < 15) return 96;
        if (m < 19) return 864;
        if (m < 31) return 96;
        return 0;
    }
    if (r == 3) {
        if (m < 1) return 0;
        if (m < 5) return 65536;
        if (m < 6) return 69632;
        if (m < 7) return 167841792;
        if (m < 8) return 167837696;
        if (m < 11) return 65536;
        if (m < 21) return 66560;
        return 65536;
    }
    if (r == 4) {
        if (m < 2) return 0;
        if (m < 7) return 458752;
        if (m < 10) return 65536;
        if (m < 17) return 458752;
        if (m < 18) return 67567616;
        if (m < 19) return 67567728;
        if (m < 20) return 67567664;
        if (m < 21) return 67567728;
        if (m < 29) return 67567680;
        return 67567616;
    }
    if (r == 5) {
        if (m < 4) return 0;
        if (m < 10) return 28672;
        if (m < 12) return 0;
        if (m < 16) return 9437184;
        if (m < 20) return 9438976;
        if (m < 28) return 9437184;
        if (m < 30) return 10223616;
        return 786432;
    }
    if (r == 6) {
        if (m < 2) return 2004318071;
        if (m < 4) return 2003859319;
        if (m < 14) return 2003830647;
        if (m < 16) return 2004617079;
        if (m < 18) return 2004615287;
        if (m < 22) return 2004615175;
        if (m < 25) return 2004652039;
        if (m < 26) return 2004623367;
        if (m < 28) return 2004647943;
        if (m < 29) return 2003861511;
        if (m < 30) return 2003845127;
        if (m < 32) return 2003865607;
        return 2003828743;
    }
    if (m < 6) return -1985230184;
    if (m < 12) return -1985232744;
    if (m < 14) return -2136227688;
    if (m < 22) return -2136276840;
    if (m < 24) return -2136276984;
    if (m < 26) return -2136244224;
    if (m < 31) return -2136276992;
    if (m < 32) return -2136276896;
    if (m < 33) return -2136276848;
    return -2136268656;
}

// Materials.
const float BOARD_MAT = 0.0;
const float WHITE_MAT = 1.0;
const float BLACK_MAT = 2.0;

// Cache of board position.
// Set at the start of mainImage.
int[8] board_cache;

// SDF evaluation of the board.
// Returns (distance, material).
vec2 sdf(vec3 p) {
    // A hack: for efficiency, we only evaluate piece distance for the piece
    // in the current square. If there is no piece in the current square then
    // we return INF distance as a lower-bound distance to pieces in adjacent squares
    // without needing to evaluate them.
    const float INF = 1.0;

    float r = min(INF, p.y + 4.0);
    vec2 res = vec2(r, BOARD_MAT);

    // Discretize coordinates onto board.
    vec2 ip = p.xz / 8.0 + 4.0;
    int ix = int(ip.x) & 7;
    int iy = int(ip.y) & 7;
    int piece = (board_cache[7 - iy] >> (ix * 4)) & 0xF;
    if (piece == 0)
        return vec2(min(res.x, INF), res.y);
    
    vec2 pp2 = mod(p.xz, 8.0) - 4.0;
    vec3 pp3 = vec3(pp2.x, p.y, pp2.y);
    float is_white = piece < 7 ? 1.0 : 0.0;
    piece = (piece - 1) % 6;
    pp3.z *= (is_white * 2.0 - 1.0); // black knight are flipped on z-axis
    
    float d_piece;
    if (piece == 0)
        d_piece = pawn(pp3);
    else if (piece == 1)
        d_piece = rook(pp3, base1(pp3));
    else if (piece == 2)
        d_piece = knight(pp3, base1(pp3));
    else if (piece == 3)
        d_piece = bishop(pp3, base1(pp3));
    else if (piece == 4)
        d_piece = king(pp3, base2(pp3));
    else
        d_piece = queen(pp3, base2(pp3));

    float bound = max(abs(p.x) - 32.0, abs(p.z) - 32.0);
    r = max(bound, d_piece);

    if (r < res.x)
        res = vec2(r, BLACK_MAT - is_white);
    
    return res;
}

vec3 norm(vec3 p) {
    // Tetrahedron technique
    vec3 n = vec3(0.0);
    for(int i = min(0, iFrame); i < 4; i++) {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*sdf(p+0.0005*e).x;
    }
    return normalize(n);
}

/////////////
// Shading //
/////////////

const vec3 SKY = vec3(0.16,0.20,0.28) * 0.1;
const vec3 LIGHT = vec3(1.64, 1.27, 0.99);
const vec3 LIGHT_DIR = normalize(vec3(1.2, -1, 2));
const vec3 INDIRECT = LIGHT * 0.1;
const vec3 INDIRECT_DIR = normalize(-LIGHT_DIR * vec3(-1.0, 0.0, -1.0));

// Ray march for shadows.
float shadowray(vec3 pos) {
    if (!RENDER_SHADOWS)
        return 1.0;

    float res = 1.0;
    float t = 0.2;
    for (int i = 0; i < 50; i++) {
		float h = sdf(pos + -LIGHT_DIR * t).x;
        res = min(res, 16.0 * h / t);
        t += clamp(h, 0.05, 0.4);
        if (res < 0.05)
            break;
    }
    return clamp(res, 0.0, 1.0);
}

vec3 shade(vec3 albedo, vec3 n, vec3 pos, vec3 dir, float ks, bool shadows) {
    float shadow = shadows ? shadowray(pos) : 1.0;
    float light_diffuse = clamp(dot(n, -LIGHT_DIR), 0.0, 1.0);
    vec3 light_half = normalize(-LIGHT_DIR - dir);
    float sky = sqrt(clamp(0.5 + 0.5 * n.y, 0.0, 1.0));
    vec3 ref = reflect(dir, n);
    float frenel = clamp(1.0 + dot(n, dir), 0.0, 1.0);
    float indirect = clamp(dot(n, INDIRECT_DIR), 0.0, 1.0);
    
    vec3 light = vec3(0.0);
    light += light_diffuse * LIGHT * shadow;
    light += sky * SKY;
    light += indirect * INDIRECT;
    vec3 col = light * albedo;
    col += ks * smoothstep(0.0, 0.5, ref.y) * (0.04 + 0.96 * pow(frenel, 4.0)) * SKY;
	col += shadow * ks * pow(clamp(dot(n, light_half), 0.0, 1.0), 8.0) * light_diffuse * (0.04 + 0.96 * pow(clamp(1.0 + dot(light_half, dir), 0.0, 1.0), 3.0)) * LIGHT * 5.0;
	return col;
}

/////////////////
// Mist effect //
/////////////////

float fogDensity(vec3 p) {
    const vec3 fdir = normalize(vec3(10,0,-7));
    float f = clamp(1.0 - 0.5 * abs(p.y - -4.0), 0.0, 1.0);
    f *= max(0.0, 1.0 - length(max(vec2(0.0), abs(p.xz) - 28.0)) / 7.0);
    p += 4.0 * fdir * iTime;
    float d = triNoise3D(p * 0.007, 0.2) * f;
    return d * d;
}

float integrateFog(vec3 a, vec3 b) {
    if (!RENDER_MIST)
        return 0.0;
    vec3 d = normalize(b - a);
    float l = length(b - a);
 	vec2 trange = boxIntersect(a - vec3(0.0, -3.0, 0.0), d, vec3(36.0, 1.0, 36.0));
	if (trange.x < 0.0)
        return 0.0;
    trange = min(trange, vec2(l));
    const float MIN_DIS = 0.2;
    const float MAX_DIS = 2.0;
    const float MIN_SAMPLES = 3.0;
    float tdiff = trange.y - trange.x;
    float samples = max(MIN_SAMPLES, tdiff / MAX_DIS);
    float dis = clamp(tdiff / samples, MIN_DIS, MAX_DIS);
    samples = ceil(tdiff / dis);
    dis = tdiff / (samples + 1.0);
    float visibility = 1.0;
    for (float t = trange.x + 0.5; t < trange.y; t += dis) {
        float density = fogDensity(a + t * d);
        visibility *= pow(3.0, -1.0 * density * dis);
    }
	return 1.0 - visibility;
}

//////////////////
// Ray marching //
//////////////////

// Ray march for reflections.
// Somewhat more simplified than castray for perf.
vec3 castray2(vec3 pos, vec3 dir) {
    if (!RENDER_REFLECTIONS)
        return SKY;
    float tmax = (7.0 - pos.y) / dir.y;
    int i = 0;
	for (float t = 0.1; t < tmax && i < 50; ++i) {
        vec3 p = pos + t * dir;
		vec2 res = sdf(pos + t * dir);
        float d = res.x;
        float mat = res.y;
		if (d < 0.001) {
            vec3 albedo = mat == BLACK_MAT ? vec3(0.02, 0.02, 0.01) : vec3(0.3, 0.22, 0.08);
            return shade(albedo, norm(p), p, dir, 1.0, false);
		}
		t += d;
	}
    return SKY;
}

// Shading for the board.
vec3 floorColor(vec2 p, vec3 ray) {
    // checkerboard color
    float xr = p.x / 16.0;
    float yr = p.y / 16.0;
 	int x = fract(xr) < 0.5 ? 0 : 1;
    int y = fract(yr) < 0.5 ? 0 : 1;
    int w = x ^ y;
    vec3 albedo = (w & 1) == 0 ? vec3(0.2) : vec3(0.04);
    
    const vec3 normal = vec3(0, 1, 0);
    
    // reflection
    vec3 rpos = vec3(p.x, -4.0, p.y);
    vec3 rdir = reflect(ray, normal);
    vec3 rcolor = castray2(rpos, rdir);
    
    // shading
    albedo = mix(albedo, rcolor, 0.2);
    vec3 color = shade(albedo, normal, rpos, ray, 0.1, true);
    
    return color;
}

// Main ray march from eye.
vec3 castray(vec3 pos, vec3 dir) {
    vec3 c = vec3(0.0);
    vec2 trange = boxIntersect(pos - vec3(0, 1.4, 0), dir, vec3(36.0, 5.5, 36.0));
    vec3 p = pos;
    float mat = -1.0;
    if (trange.y > 0.0) {
        int i = 0;
        float t = trange.x;
        for (; t < trange.y && i < 150; ++i) {   
            p = pos + t * dir;
            vec2 res = sdf(p);
            float d = res.x;
            if (d < 0.05) {
                if (max(abs(p.x), abs(p.z)) > 32.0)
                    break;
                mat = res.y;
                if (mat == BOARD_MAT) {
                    c = floorColor(p.xz, dir);
                    break;
                }
                vec3 albedo = mat == BLACK_MAT ? vec3(0.02, 0.02, 0.01) : vec3(0.3, 0.22, 0.08);
                albedo += vec3(.1,.1,.05) * (mat == BLACK_MAT ? 0.5 : 2.2) * (0.2 * sin(15.0 * p.x + 25.0 * sin(2.0 * p.z)));
                c = shade(albedo, norm(p), p, dir, 1.0, true);
                break;
            }
            t += d;
        }
        t = min(t, trange.y);
        p = pos + t * dir;
    }
    if (RENDER_SKY && mat < 0.0) {
        // Sky
        const vec3 C1 = vec3(0.12, 0.08, 0.08);
        const vec3 C2 = vec3(0.04, 0.03, 0.06) * 2.0;
        float y = dir.y + 0.2 * triNoise3D(dir * 2.0, 1.0);
        c = mix(C1, C2, smoothstep(-0.35, 0.0, y));
        float disp = triNoise3D(dir * 0.9, 0.08);
        c += vec3(1.0) * (pow(disp, 5.0) * 3.47);
        
        // Fade to black
        float h = dot(dir - 0.08 * triNoise3D(dir * 0.3, 0.0), vec3(0.02, 1.0, -0.01));
        float hstart = -0.2;
        float hend = -0.5;
        c = mix(c, vec3(0.0), smoothstep(hstart, hend, h));
    }
    
    // Mist
    float fog = integrateFog(pos, p);
    const vec3 FOG_COLOR = vec3(1.5, 1.1, 0.9);
    return mix(c, FOG_COLOR, clamp(fog, 0.0, 1.0));
}

////////////
// Camera //
////////////

vec2 normScreenSpace(vec2 fragCoord) {
    return (fragCoord / iResolution.xy - 0.5) * (iResolution.xy / iResolution.x);
}

mat3 setCamera(vec3 ro, vec3 ta, float cr) {
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 look(vec2 fragCoord) {
	vec2 uv = normScreenSpace(fragCoord);
    vec3 rd = normalize(vec3(uv, 1.5));
    float a = loopTime() * 0.3;
    vec3 ro = vec3(120.0 * -sin(a * 0.5), 45.0 + 10.0 * sin(a - 0.4), 120.0 * cos(a * 0.5));
    vec3 target = vec3(0, 3, 0);
  	mat3 m = setCamera(ro, target, 0.0);
    vec3 c = castray(ro, m * rd);
    return c;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Warp time by position to get a disintegrate move effect.
    float t = moveTime() / TIME_PER_POSITION + 0.8 * triNoise3D(vec3(3.0 * normScreenSpace(fragCoord), 0.0), 0.0);
    int move = min(33, int(t));
    
    // Precache board layout.
    for (int i = 0; i < 8; ++i)
        board_cache[i] = board(move, i);

    // MSAA
	int AA = MSAAx4 ? 4 : 1;
    vec3 c = vec3(0.0);
    vec2 delta = MSAAx4 ? vec2(0.3, 0.4) : vec2(0.0);
    for (int i = min(0, iFrame); i < AA; ++i) {
    	c += look(fragCoord + delta);
        delta = vec2(delta.y, -delta.x);
    }
    c /= float(AA);
    
    float fade = min(1.0, 3.0 * min(introTime(), outroTime()));
    
    c *= vec3(0.95, 0.8, 1.1); // color grade   
    c *= fade;
    c = pow(c, vec3(0.4545)); // gamma
    
	fragColor = vec4(c, 1.0);
}