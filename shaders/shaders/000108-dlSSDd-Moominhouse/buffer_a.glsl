// Buffer A (buffer) — Moominhouse by ytt
// https://www.shadertoy.com/view/dlSSDd

// MIT License

// Buffer A - Model and navigation
// Inputs: Buffer A, Keyboard

#define keyboardTexture(coord) texture(iChannel1, (coord) / vec2(256.0, 3.0))

// steps view values
int marchSteps = 0;
int marchTransparentSteps = 0;
int marchReflectionSteps = 0;
int marchShadowSteps = 0;

// Consts
const vec3 WELL_POSITION = vec3(-7.0, -0.1, -5.5);
const vec3 HAT_POSITION = vec3(133.1, 0.0, 32.3);
const float HOUSE_HEIGHT = 14.0;
const float HILL_HEIGHT = 10.0;

const mat2 rotation_0 = mat2(1.0, 0.0, 0.0, 1.0);
const mat2 rotation_1 = mat2(0.9998476, 0.0174524, -0.0174524, 0.9998476);
const mat2 rotation_7_5 = mat2(0.9914448, 0.1305261, -0.1305261, 0.9914448);
const mat2 rotation_10 = mat2(0.9848077, 0.1736481, -0.1736481, 0.9848077);
const mat2 rotation_15 = mat2(0.9659258, 0.258819, -0.258819, 0.9659258);
const mat2 rotation_20 = mat2(0.9396926, 0.342020, -0.342020, 0.9396926);
const mat2 rotation_25 = mat2(0.9063077, 0.422618, -0.422618, 0.9063077);
const mat2 rotation_30 = mat2(0.8660254, 0.5, -0.5, 0.8660254);
const mat2 rotation_45 = mat2(0.7071067, 0.7071067, -0.7071067, 0.7071067);
const mat2 rotation_60 = mat2(0.5, 0.8660254, -0.8660254, 0.5);
const mat2 rotation_90 = mat2(0.0, 1.0, -1.0, 0.0);
const mat2 rotation_93 = mat2(-0.0523359, 0.9986295, -0.9986295, -0.0523359);
const mat2 rotation_120 = mat2(-0.5, 0.8660254, -0.8660254, -0.5);
const mat2 rotation_145 = mat2(-0.8191520, 0.5735764, -0.5735764, -0.8191520);
const mat2 rotation_180 = mat2(-1.0, 0.0, 0.0, -1.0);


const mat2 rotation_n1 = mat2(0.9998476, -0.0174524, 0.0174524, 0.9998476);
const mat2 rotation_n7_5 = mat2(0.9914448, -0.1305261, 0.1305261, 0.9914448);
const mat2 rotation_n10 = mat2(0.9848077, -0.1736481, 0.1736481, 0.9848077);
const mat2 rotation_n15 = mat2(0.9659258, -0.258819, 0.258819, 0.9659258);
const mat2 rotation_n20 = mat2(0.9396926, -0.342020, 0.342020, 0.9396926);
const mat2 rotation_n25 = mat2(0.9063077, -0.422618, 0.422618, 0.9063077);
const mat2 rotation_n30 = mat2(0.8660254, -0.5, 0.5, 0.8660254);
const mat2 rotation_n36 = mat2(0.8090169, -0.5877852, 0.5877852, 0.8090169);
const mat2 rotation_n45 = mat2(0.7071067, -0.7071067, 0.7071067, 0.7071067);
const mat2 rotation_n60 = mat2(0.5, -0.8660254, 0.8660254, 0.5);
const mat2 rotation_n90 = mat2(0.0, -1.0, 1.0, 0.0);
const mat2 rotation_n93 = mat2(-0.0523359, -0.9986295, 0.9986295, -0.0523359);
const mat2 rotation_n120 = mat2(-0.5, -0.8660254, 0.8660254, -0.5);
const mat2 rotation_n145 = mat2(-0.8191520, -0.5735764, 0.5735764, -0.8191520);
const mat2 rotation_n180 = mat2(-1.0, -0.0, 0.0, -1.0);

float getGrassShade(vec2 pos)
{
    pos.x += 4.0 * fbm(pos);
    float x = 0.99 * fbm(pos * vec2(1.0, 0.8) * 0.3);
    x = x * x;
    x = x * (2.0 - x);
    return x;
}

vec3 getRiverMask(float x) // (width, depth, center-z)
{
    float mask = smoothstep(1.0, 10.0, abs(x));

    float width = 3.2;
    width += mask * 0.8 * sin(0.2 * x);
    width += mask * 0.2 * sin(2.0 * x);

    float offset = 0.0;
    offset += 8.0 * sin(0.07 * x + PI05);
    offset += mask * 0.3 * sin(0.5 * x);

    float depth = 1.6;
    depth -= 0.3 * (1.0 + sin(0.2 * x));
    depth -= 0.02 * (2.0 + sin(3.0 * x) + sin(4.0 * x));

    return vec3(width, depth, 42.0 + offset);
}

vec3 getPathwayMask(float z) //(center-x, depth, width)
{
    const float z0 = 10.0; // entrance segment start
    const float z1 = 40.0; // bridge segment end
    const float z2 = 50.0; // bridge
    const float z3 = 100.0; // bridge segment start
    const float depth1 = 0.1;

    float center = 6.0 * (sin(z * 0.138 + 0.97) - 1.0);

    center *= smoothstep(z2, z1, z) + smoothstep(z2, z3, z);
    center *= smoothstep(0.0, z0, z);
    float width = 1.0 + 0.1 * (sin(z * 2.0) + 0.5 * sin(z * 5.0));
    width = z < 0.0 ? 0.0 : width;

    float depth = depth1;

    return vec3(center, 0.1, width);
}

float getGroundBaseHeight(vec3 pos)
{
    const float h1 = 0.5; // base ground height
    const float r1 = 6.0; // hill inner flat radius
    const float r2 = 45.0; // hill outer radius

    float r = length(pos.xz);

    return mix(h1, HILL_HEIGHT, pow(smoothstep(r2, r1, r), 0.8));
}

float getGroundHeight(vec3 pos, float baseHeight)
{
    const float h1 = 0.5; // bumps height
    const float r1 = 30.0; // hill bumps start radius 1
    const float r2 = 40.0; // hill bumps start radius 2
    const float s1 = 5.0; // bumps size

    vec3 pos1 = pos;
    pos1 /= s1;
    pos1.xz *= mat2(0.93, 0.34, -0.34, 0.93);

    float bump = 1.0 +
        0.7 * (sin(1.2 * pos1.x) + sin(1.5 * pos1.z)) +
        0.3 * (sin(2.7 * pos1.x) + sin(3.5 * pos1.z));

    vec3 riverMask = getRiverMask(pos.x);

    float d1 = length(pos.xz);
    float d2 = abs(pos.z - riverMask.z);
    bump *= smoothstep(2.0, 8.0, d2); // flatten river banks
    bump *= smoothstep(r1, r2, d1); // flatten hill center
    baseHeight += bump * h1;

    // river
    baseHeight -= riverMask.y * smoothstep(1.0, 0.0, abs(pos.z - riverMask.z) / riverMask.x);

    // well
    baseHeight -= length(pos.xz - WELL_POSITION.xz) < 0.6 ? 1.6 : 0.0;

    return baseHeight;
}

float getGroundHeight(vec3 pos)
{
    return getGroundHeight(pos, getGroundBaseHeight(pos));
}

vec3 getWindForce(vec3 pos, float time)
{
    float phase = -sin(pos.x * 0.2) - pos.z; // phase direction
    float an = 1.0; // force direction

    phase += 0.2 * (sin(2.0 * pos.x + time) + sin(3.0 * pos.z + time)); // noise

    phase = sin(1.5 * time + phase);
    an += phase; // change direction

    float stength = 0.1 + 2.0 * map11_01(phase);

    stength *= 0.6 + 0.4 * sin(0.2 * pos.z + 0.5 * time); // pulse

    return stength * vec3(cos(an), 0.0, sin(an));
}


// --- Moomin ---

vec3 sdEye(vec3 pos, float side, vec2 eyesDirection, float lookDistance, float time)
{
    float bounds = sdBoxApprox(pos, vec3(0.05));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    const float s1 = 0.038; // eyeball size
    const float s2 = s1 * 0.45; // pupil size
    const float s3 = s1 + 0.002; // eye lids size
    const float y1 = 0.6 * s3; // eye lids opening

    const float eyelidsOffset = 0.0;

    float blink = smoothstep(0.99, 1.0, max(sin(time * 0.25), sin(time * 0.5)));

    float eyesOpen = 0.8 * (1.0 - blink);

    vec3 pos1 = pos;

    float d1 = sdSphere(pos1, s3); // eyelids

    vec3 pos2 = pos1;
    pos2.y -= y1; // opening start
    pos2.yz *= rotation(eyelidsOffset);

    vec3 pos3 = pos2;
    pos3.yz *= rotation(PI05 - eyesOpen * (PI05 + eyelidsOffset));
    float d2 = smax(d1, pos3.y, eyesOpen * 0.02); // upper eyelid

    pos3 = pos2;
    pos3.yz *= rotation(-PI05 + eyesOpen * (PI05 - eyelidsOffset));
    float d3 = smax(d1, pos3.y, eyesOpen * 0.02); // lower eyelid

    d1 = min(d2, d3);

    float edge = 0.5 * (sign(pos2.z) + 3.0);
    vec3 dm1 = vec3(d1, MATERIAL_SKIN, edge);

    pos2 = pos1;
    d1 = sdSphere(pos2, s1); // eyeball

    pos2.xy *= rotation(lookDistance - side * eyesDirection.x);
    pos2.yz *= rotation(eyesDirection.y);

    pos2.y -= s1;
    d2 = sdSphere(pos2, s2); // pupil

    vec3 dm2 = vec3(d1, d2 > 0.0 ? MATERIAL_EYE : MATERIAL_PUPIL, 0.0);
    dm1 = minx(dm1, dm2);

    return dm1;
}

vec3 sdEar(vec3 pos)
{
    float bounds = sdBoxApprox(pos, vec3(0.055), vec3(0.0, 1.0, -0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d1, d2;

    vec3 pos1 = pos;
    pos1.y += 0.1;
    d1 = sdEllipsoid(pos1, vec3(0.05, 0.2, 0.06));

    pos1.y -= 0.11;
    pos1.z += 0.18;
    d2 = sdSphere(pos1, 0.2);
    d1 = smax(d1, d2, 0.02);

    pos1 = pos;
    pos1.z -= 0.02;
    pos1.y -= 0.04;
    d2 = sdEllipsoid(pos1, vec3(0.02, 0.06, 0.02));
    d1 = smax(d1, -d2, 0.02);

    d1 = smax(d1, -pos.y - 0.05, 0.1);

    float hue = d2 < 0.001 ? 1.0 : 0.0;
    float edge = d2 < 0.001 ? 2.0 : 1.0;

    return vec3(d1, MATERIAL_SKIN, edge + 0.5 * hue);
}

vec3 sdHead(vec3 pos, vec2 eyesDirection, float lookDistance, float time)
{
    const float eyebrowsHeight = 0.0;
    const float mouthHeight = 0.0;
    const float mouthOpen = 0.0;

    float bounds = sdBoxApprox(pos, vec3(0.8, 0.25, 0.3), vec3(0.0, -0.2, 0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1, pos2;
    float d1, d2, d3;

    pos.z -= 0.05;
    pos.yz *= rotation_60;

    pos1 = pos;
    pos1.xz *= rotation_90;
    pos1.xy *= rotation_n90;
    d1 = sdArc(pos1, 0.18, -0.4, 0.14, -0.11); // head arc
    pos1.y -= 0.02;
    d2 = sdSphere(pos1, 0.144);
    d1 = smin(d1, d2, 0.01); // smooth arc

    pos1 = pos;
    float rcurve = 0.3;
    pos1 -= vec3(0.0, 0.22 - rcurve, 0.07);
    d2 = sdCircle(pos1.xy, rcurve); // flatten head arc top
    d2 = length(vec2(d2, pos1.z)) - 0.055;

    d1 = smax(d1, -d2, 0.22);

    float merge = smoothstep(0.15, -0.05, pos1.z) * 0.15 + 0.0005;

    // eyes
    vec3 eyesPos = pos;
    float eyeSide = sign(eyesPos.x);
    eyesPos.x = abs(eyesPos.x);
    eyesPos -= vec3(0.053, 0.085, 0.081);
    eyesPos.xy *= rotation_n15;

    pos1 = eyesPos;
    pos1 -= vec3(0.0, 0.02, -0.005);
    d2 = sdSphere(pos1, 0.035); // eyes socket
    d1 = smax(d1, -d2, 0.04);

    // eyes top outline group
    pos1 = eyesPos;
    pos1 -= vec3(0.004, 0.03, -0.015);
    d2 = sdSphere(pos1, 0.025);

    float edge = d2 < 0.0 ? 3.0 : 0.0; // eyes top outline

    // eyebrows
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1.yz *= rotation(0.15 - eyebrowsHeight * 0.35);
    pos1.xy *= rotation_n30;

    pos2 = pos1;
    pos2.z += 0.025;
    d2 = sdCircle(pos2.xz, 0.025); // eyebrow size
    d2 = max(d2, -pos2.y);

    pos2 = pos1;
    pos2.z -= 0.05;
    pos2.x += 0.03; // eyebrow angle
    d3 = sdCircle(pos2.xz, 0.08); // eyebrow curve
    d3 = max(d3, -pos2.y);

    edge = d2 > 0.0 ? edge :
           d3 > 0.0 ? 1.0 : 3.0;

    vec3 dm1 = vec3(d1, MATERIAL_SKIN, edge);

    // fever hue
    pos1 = pos;
    pos1 -= vec3(0.0, 0.155, 0.11);
    d1 = sdEllipsoid(pos1, 0.08 * vec3(1.0, 0.5, 0.5));
    dm1.z += 0.99 * smoothstep(0.0, -0.04, d1);// smoothstep(-0.0, -0.1, d1);

    pos1 = eyesPos;
    vec3 dm2 = sdEye(pos1, eyeSide, eyesDirection, lookDistance, time);
    dm1 = smin(dm1, dm2, 0.04);

    pos1 = pos;
    pos1.yz *= rotation_n45;
    pos1.x = abs(pos1.x);
    pos1.xy *= rotation_n15;
    pos1 -= vec3(0.04, 0.09, -0.01);
    pos1.xz *= rotation_n15;
    pos1.y -= 0.02;
    dm2 = sdEar(pos1);
    dm1 = smin(dm1, dm2, 0.02);

    // mouth
    pos1 = pos;
    pos1 += vec3(0.0, 0.06 + mouthHeight, -0.25 + mouthHeight);
    d1 = sdEllipsoid(pos1, vec3(0.03, 0.02, 0.015) * clamp(mouthOpen, 0.001, 4.0));
    dm1.xyz = maxx(dm1, vec3(-d1, MATERIAL_MOUTH, 0.0));


    return dm1;
}


vec3 sdArm(vec3 pos)
{
    float bounds = sdBoxApprox(pos + vec3(0.0, -0.02, 0.05), vec3(0.1, 0.07, 0.15));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.xz *= rotation_90;
    pos1.xy *= rotation_60;
    float d1 = sdArc(pos1, 0.2, -0.6, 0.04, -0.1);

    // fingers
    pos1 = pos;
    pos1.z -= 0.04;

    pos1.x = abs(pos1.x);
    pos1.yz *= rotation_60;
    pos1 += vec3(-0.008, 0.008, -0.005);

    vec3 pos2 = pos1;
    pos2.z = stretchAxis(pos2.z, 0.03);
    float d2 = sdSphere(pos2, 0.008);

    pos2 = pos1;
    pos2 += vec3(-0.019, 0.008, 0.005);
    pos2.z = stretchAxis(pos2.z, 0.03);
    float d3 = sdSphere(pos2, 0.008);
    d2 = min(d2, d3);

    // thumb
    pos2 = pos;
    pos2.x += 0.037;
    pos2.xy *= rotation_45;
    pos2.xz *= rotation_n30;
    pos2.x = stretchAxis(pos2.x, 0.04);
    d3 = sdSphere(pos2, 0.009);
    d2 = min(d2, d3);
    d1 = smin(d1, d2, 0.015);

    return vec3(d1, MATERIAL_SKIN, 0.0);
}

vec3 sdLeg(vec3 pos)
{
    float bounds = sdBoxApprox(pos, vec3(0.1));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.xy *= rotation_n7_5;
    vec3 pos2 = pos1;
    pos2.yz *= rotation_30;
    pos2.y = stretchAxis(pos2.y, 0.14);
    float d1 = sdSphere(pos2, 0.06);

    pos2 = pos1;
    pos2.y += 0.13;
    pos2.z -= 0.03;
    float d2 = sdSphere(pos2, 0.06);
    d1 = smin(d1, d2, 0.05);

    pos1 = pos;
    pos1.y += 0.11;
    d1 = max(d1, -pos1.y);

    return vec3(d1, MATERIAL_SKIN, 0.0);
}

vec3 sdTail(vec3 pos)
{
    float bounds = sdBoxApprox(pos + vec3(0.0, 0.2, 0.4), vec3(0.01, 0.15, 0.2));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y += 0.31;
    pos1.z += 0.5;

    pos1 = pos1.yzx;
    float d1 = sdArc(pos1, 0.4, 0.7, 0.01, -0.03);

    pos1.y = -pos1.y;
    float d2 = sdArc(pos1, 0.1, 0.6, 0.04, 0.4);
    d1 = smin(d1, d2, 0.02);

    return vec3(d1, MATERIAL_SKIN, 0.0);
}

vec3 sdBody(vec3 pos)
{
    float bounds = sdBoxApprox(pos - vec3z(-0.1), vec3(0.25, 0.3, 0.6));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // body
    vec3 pos1 = pos;
    pos1 += vec3(0.0, 0.05, 0.03);
    pos1.xz *= rotation_90;
    pos1.xy *= rotation_n45;
    vec3 d1 = vec3(sdArc(pos1, 0.35, -0.5, 0.2, 0.25), MATERIAL_SKIN, 0.0);

    // arms
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1 -= vec3(0.13, 0.0, 0.3);
    pos1.xz *= rotation_n7_5;
    vec3 d2 = sdArm(pos1);
    d1 = smin(d1, d2, 0.05);

    // legs
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1 -= vec3(0.08, -0.25, -0.15);
    d2 = sdLeg(pos1);
    d1 = smin(d1, d2, 0.05);

    pos1 = pos;
    d2 = sdTail(pos1);
    d1 = smin(d1, d2, 0.05);

    return d1;
}

vec3 sdScarf(vec3 pos)
{
    vec3 pos1 = pos;
    float d1 = sdCircle(pos1.xz, 0.15);
    d1 = length(vec2(d1, stretchAxis(pos1.y, 0.08)));

    pos1 = pos;
    pos1.xz *= rotation_60;
    pos1.z -= 0.06 * sin(10.0 * pos1.y + 1.7);
    pos1 -= vec3(0.0, -0.17, -0.21);
    float d2 = sdLine(pos1.yz, 0.2);
    d2 = length(vec2(d2, stretchAxis(pos1.x, 0.1)));
    d1 = smin(d1, d2, 0.01);

    // bumps
    pos1 *= 100.0;
    d1 -= 0.015 + 0.005 * (sin(pos1.x) * sin(pos1.y) * sin(pos1.z));

    float hue = pos.y < -0.25 ? 0.0 : 0.99;
    return vec3(d1, MATERIAL_SCARF + hue, 0.0);
}

vec3 sdMoomin(vec3 pos, vec3 lookOffset, float time)
{
    float bounds = sdBoxApprox(pos - vec3(0.0, 0.6, -0.1), vec3(0.25, 0.6, 0.6));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;

    pos1.y -= 0.65;
    pos1.z += 0.05;
    vec3 d1 = sdBody(pos1);

    pos1 = pos;
    pos1.y -= 0.95;

    vec2 an = vec2(-0.6 * (atan(lookOffset.x, lookOffset.z) - 1.0),
                   -atan(lookOffset.y, length(lookOffset.xz)) + 0.2);

    an.x = an.x * smoothstep(0.7, 0.4, abs(an.x));

    pos1.xz *= rotation(clamp(an.x, -0.8, 0.8));
    pos1.yz *= rotation(clamp(an.y, -2.0, 0.0));

    vec2 eyesDirection = vec2(-0.3 * an.x, 0.1 * an.y);
    float lookDistance = clamp(0.5 - 0.5 * length(state.origin - vec3y1), 0.0, 0.2);

    vec3 d2 = sdHead(pos1, eyesDirection, lookDistance, time);
    float merge = 0.1 * clamp(1.0 - pos1.z / 0.1, 0.0, 1.0); // smooth merge only the neck area
    d1 = smin(d1, d2, 0.001 + merge);

    pos1 = pos;
    pos1.y -= 0.78;
    pos1.yz *= rotation_20;
    d2 = sdScarf(pos1);
    d1 = minx(d1, d2);

    return d1;
}

// --- House ---

float sdRoofBounds(vec2 pos)
{
    const float r = 4.2;
    const float h = 6.0;
    const float slope1 = r / h;
    const float slope2 = sqrt(1.0 + slope1 * slope1);

    vec2 pos1 = pos;
    pos1.y -= h - 0.02;
    float d = pos1.y > 0.0 ? length(pos1) : ((pos1.x + slope1 * pos1.y) / slope2);
    d = max(d, -pos.y);

    return d;
}

vec3 sdRoof(vec3 pos)
{
    const float r = 4.2;
    const float h = 6.0;
    const float seed = 0.3;
    const float h2 = 0.7; // relative ceiling height

    float bounds = sdBoxApprox(pos, vec3(r, h * 0.5, r) * 1.1, vec3y(0.8));
    if (bounds > BOUNDS_MARGIN_LARGE)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 p = vec2(length(pos.xz), pos.y);
    vec2 a = vec2(0.0, h);
    vec2 b = vec2(r, 0.0);

    float t = lineIntersection(p, a, b);
    vec2 c = a + clamp(t, 0.0, 1.0) * (b - a); // closest point
    vec3 d1 = vec3(length(p - c), MATERIAL_TILE, 1.0);

    // top ceiling
    vec3 d2 = vec3(length(vec2(max(0.0, p.x - (1.0 - h2) * r + 0.05), p.y - h2 * h)) - 0.02, MATERIAL_PAINTED_WOOD, 0.0);
    d1 = minx(d1, d2);

    if (d1.x - 0.7 > BOUNDS_MARGIN)
    {
        return vec3(d1.x - 0.7, 0.0, 0.0);
    }

    // side ceiling
    d2 = vec3(length(p - c + 0.01) - 0.01, MATERIAL_PAINTED_WOOD, 0.0);
    d2.x = max(d2.x, -pos.y + 0.5);
    d1 = minx(d1, d2);

    float rows = 12.0;
    float columnWidth = 0.6;

    vec2 slope = (length(b - a) / rows) * normalize(vec2(r, -h)); // tile base direction

    float an = atan(pos.z, pos.x);

    float overlap = 1.0; // rows overlap
    float row = clamp(t, 0.0, 1.0) * rows;

    // individual tiles
    for (float row1 = max(row - overlap, 0.0); row1 <= rows; row1 += 1.0)
    {
        float r1 = r * floor(row1 + 1.0) / rows; // tiles row radius
        float columns1 = round(PI2 * r1 / columnWidth); // number of columns at current row
        float column1 = columns1 * (an + PI * hash(floor(row1) + seed)) / PI2; // tile column

        float h1 = hash(vec2(floor(row1), mod(floor(column1) + columns1, columns1)) + seed); // row+column hash

        vec2 slope1 = slope * (1.2 - pow2((fract(column1) - 0.5) * 2.0)); // tile length from current slice
        slope1 *= rotation(-0.1 * h1); // tile direction

        vec2 c1 = a + (floor(row1) / rows) * (b - a); // tile base position
        float t1 = lineIntersection(p, c1, c1 + slope1);
        t1 = clamp(t1, 0.0, 1.0);
        float m1 = h1 * sqrt(t1); // material varience
        vec2 c2 = c1 + t1 * slope1; // closest point on tile

        float edge = floor(h1 * 3.0); // material edge group variation
        edge = t1 > 0.1 ? edge : 0.0; // exclude top edge

        d2 = vec3(length(p - c2), MATERIAL_TILE + 0.99 * m1, edge);
        d1 = minx(d1, d2);
    }

    d1.x = d1.x < 1.0 ? d1.x * 0.5 : d1.x; // compansate approximation
    d1.x -= 0.01;

    return d1;
}

vec3 sdTiles(vec3 pos, vec3 tileSize, vec2 count, float seed)
{
    const float boundsDepth = 0.2;

    float h = tileSize.y;
    float w = tileSize.x;
    float depth = tileSize.z;
    float bevel = 0.5 * tileSize.z;
    float ext = 0.3 * h; // tile overlap

    vec2 size = vec2(count.x * w, count.y * h + ext);
    pos.y += size.y;

    vec3 bounds = vec3(sdBoxApprox(pos - vec3y(size.y * 0.5), vec3(size * 0.5, boundsDepth)), 0.0, 0.0);
    if (bounds.x > BOUNDS_MARGIN)
    {
        return bounds;
    }

    bounds.y = MATERIAL_TILE;

    float cellsBounds = sdBoxApprox(pos - vec3y((size.y + ext) * 0.5), vec3(size.x * 0.5, (size.y - ext) * 0.5, boundsDepth));

    float rows = count.y;

    pos.y -= ext;
    float row = pos.y / h;
    row = clamp(row, 0.0, rows - 1.0);

    // base
    float d = sdRectangleApprox(pos.xy - vec2y((rows + 1.0) * h * 0.5), vec2(size.x, (rows - 1.0) * h) * 0.5 + 0.001); // exclude last row
    d = max(0.0, d); // fill
    d = length(vec2(d, stretchAxis(pos.z + depth * 0.5, depth)));
    vec3 d1 = vec3(d, MATERIAL_TILE, 1.0);

    pos.x += mod(count.x, 2.0) > 0.0 ? 0.5 * w : 0.0; // middle tile offset

    // overlapping tiles
    for (int i = 0; i < 2; i++)
    {
        float row1 = row + float(i);
        float row2 = row1;
        row1 = clamp(row1, 0.0, rows - 1.0);
        vec3 pos1 = pos;
        pos1.xy -= vec2(w, h) * 0.5;

        pos1.x += row1 >= 1.0 ? w * hash(floor(row1) + seed) : 0.0; // exclude first row offset

        float column1 = pos1.x / w + 0.5;

        pos1.x -= floor(column1) * w;
        pos1.y -= floor(row1) * h;

        // cell bounds
        float cellBounds = sdRectangle(pos1.xy, 0.55 * vec2(w, h));
        cellBounds = length(vec2(cellBounds, stretchAxis(pos1.z, boundsDepth)));
        cellBounds = max(cellBounds, cellsBounds); // clip bounds at the plane edges
        cellBounds = i > 0 ? max(cellBounds, MAX_DIST) : cellBounds; // remove bounds for overlapping rows

        // tile
        float h1 = hash(vec2(floor(row1), floor(column1)) + seed);
        pos1.y -= h * 0.5;
        pos1.yz *= rotationApprox(-0.05 - 0.1 * h1); // rotate

        float d = sdEllipse(pos1.xy, vec2(w * 0.5, h + ext) - bevel);
        d = max(pos1.y, d); // clip top part
        d = max(0.0, d); // fill shape
        d = length(vec2(d, stretchAxis(pos1.z + 0.5 * depth, depth - 2.0 * bevel))); // thickness
        d -= bevel;

        float y = h1 * (1.0 - fract(row2) + float(i)) * h / (h + ext);
        float edge = floor(h1 * 3.0); // material edge group variation
        edge = y > 0.1 ? edge : 0.0; // exclude top edge

        vec3 d2 = vec3(d, MATERIAL_TILE + 0.99 * y, edge);
        d2 = maxx(d2, bounds);

        d1 = minx(d1, d2);
    }

    return d1;
}

vec3 sdLightningRod(vec3 pos)
{
    float bounds = sdBoxApprox(pos, vec3(0.45, 2.0, 0.45), vec3y(0.9));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 p = vec2(length(pos.xz), pos.y);

    float d1 = sdLine(p, vec2(0.4, 0.0), vec2(0.0, 1.3)) - 0.1; // bottom cone

    float d2 = sdLine(p, vec2(0.0, 0.7), vec2(0.25, 2.0)); // middle cone
    d1 = smin(d1, d2, 0.2);

    d2 = sdLine(p, vec2(0.25, 2.0), vec2(0.4, 2.15)); // top cone base
    d1 = min(d1, d2);

    d2 = sdLine(p, vec2(0.4, 2.15), vec2(0.0, 3.5)); // top cone
    d1 = min(d1, d2);

    d2 = sdCircle(p - vec2(0.0, 1.3), 0.3); // sphere
    d1 = smin(d1, d2, 0.1);

    return vec3(d1, MATERIAL_METAL1, 0.0);
}

vec3 sdRoundBricks(vec3 pos, vec3 size, vec3 offset, float bevel, float rows, float columns, float seed, float material, float materialBias)
{
    float r = columns * size.x / PI2;

    float bounds = sdBoxApprox(pos, vec3(r + 0.5 * size.z + offset.z, 0.5 * rows * size.y, r + 0.5 * size.z + offset.z), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos.y -= 0.5 * size.y;

    vec3 pos1 = vec3(atan(pos.x, pos.z) / PI2 * columns * size.x, pos.y, length(pos.xz)); // radial coordinates

    float row = floor(pos1.y / size.y + 0.5);
    row = clamp(row, 0.0, rows - 1.0);
    pos1.y -= row * size.y;
    pos1.z -= r;

    float h1 = hash(row + rows + seed);
    pos1.x -= 0.5 * size.x * mod(row, 2.0); // center
    pos1.x -= offset.x * (2.0 * h1 - 1.0);

    float column = floor(pos1.x / size.x + 0.5);
    column = clamp(column, -columns, columns);
    pos1.x -= column * size.x;

    column = mod(column, columns);

    float h2 = hash(columns * row + column);
    pos1.z += offset.z * (2.0 * h2 - 1.0);

    float h3 = fract(h1 + h2);
    float h4 = fract(h1 - h2);

    float d1 = sdBox(pos1, size * 0.5, vec3(0.0), bevel);

    // seal wall
    float d2 = abs(length(pos.xz) - r) - 0.01;
    d2 = max(d2, -pos.y);
    d2 = max(d2, pos.y - (rows - 1.0) * size.y);
    d1 = min(d1, d2);

    float edge = floor(3.0 * h3);
    return vec3(d1, material + materialBias * h4, edge);
}

vec3 sdChimney(vec3 pos)
{
    const vec3 size = vec3(0.4, 0.25, 0.15); // brick size
    const vec3 offset = vec3(0.05, 0.0, 0.01);
    const float bevel = 0.03;
    const float rows = 18.0;
    const float columns = 9.0;
    const float seed = 0.0;

    return sdRoundBricks(pos, size, offset, bevel, rows, columns, seed, MATERIAL_TILE, 1.0);
}

vec3 sdChimneyTop(vec3 pos)
{
    const float size1 = 0.4;
    const float thickness1 = 0.01;
    const float thickness2 = 0.02;
    const float width1 = 0.2;
    const float count1 = 7.0;

    float bounds = sdBoxApprox(pos, vec3(0.7, 1.1, 0.7), vec3y(0.9));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 p = vec2(length(pos.xz), pos.y); // polar coordinates

    // pipe
    float d1 = sdLine(p, vec2(0.52, 0.0), vec2(0.0, 0.6)) - 0.1; // segment
    float d2 = sdLine(p, vec2(0.3, 0.0), vec2(0.15, 1.5)) - 0.02; // segment
    d1 = min(d1, d2);

    // top part
    vec3 pos1 = pos;
    float index = 0.0;
    pos1.xz = radialMod(pos1.xz, 5.0, index);

    vec3 d = vec3(d1, MATERIAL_METAL1, 0.0);

    pos1 = pos;
    pos1.y -= 1.38;
    pos1.xz = radialMod(pos1.xz, count1, index);
    pos1.x -= 1.2 * size1;

    float width = width1 * sqrt(smoothstep(0.1, -0.9 * size1, pos1.x));
    float thickness = thickness1 + thickness2 * smoothstep(0.0, -size1, pos1.x);
    d1 = sdCircle(pos1.xy, size1);
    d1 = length(vec2(d1, stretchAxis(pos1.z, width)));
    d1 = max(d1, pos1.x - 0.08);
    d1 = max(d1, -pos1.y + 0.4 * size1);
    d1 -= thickness;

    d = minx(d, vec3(d1, MATERIAL_METAL3, 0.0));
    return d;
}

vec3 sdBrickWall(vec3 pos, vec2 size)
{
    // closest point
    vec3 c = vec3(clamp(pos.x, 0.0, size.x), clamp(pos.y, 0.0, size.y), 0.0);

    float rows = round(size.y / 0.25);
    float columns = size.x / 0.5; // clipped by offset, so no need to round

    float row = (c.y / size.y) * rows;
    float h1 = hash(floor(row)); // row hash
    float column = (c.x / size.x) * columns + mod(floor(row), 2.0) * 0.5 + h1 * 0.25;

    float h2 = hash(floor(vec2(row, column))); // row+column hash

    float bump = (0.5 - abs(fract(row) - 0.5)) * (0.5 - abs(fract(column) - 0.5)); // bump
    bump = clamp(bump, 0.0, 0.005); // clip bump
    bump *= 4.0 * h2; // bump variation

    float d = length(pos - c) - bump;
    float edge = floor(h2 * 3.0); // material edge group variation
    return vec3(d, MATERIAL_TILE + 0.99 * h2, edge);
}

vec3 sdMoominWindow(vec3 pos, float angle)
{
    // quater size
    const float w = 0.3;
    const float h = 0.4;

    // window
    const float depth1 = 0.06;
    const float thickness1 = 0.08;
    const float bevel1 = 0.01;
    // divider
    const float depth2 = 0.04;
    const float thickness2 = 0.08;
    const float bevel2 = 0.01;
    // frame
    const float depth3 = 0.1;
    const float thickness3 = 0.1;
    const float bevel3 = 0.02;
    // handle
    const float r4 = 0.07;
    const float thickness4 = 0.005;
    const float width4 = 0.015;

    const float segmentOffset = 0.25 * (h - w);
    const vec3 baseSize = vec3(0.45, 0.06, 0.08);

    float bounds = sdBoxApprox(pos, vec3(1.0, 0.6, 0.6), vec3x(0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d1, d2, d3;
    vec3 pos1;
    vec2 p;

    // frame
    pos1 = pos;
    pos1.z = stretchAxis(pos1.z, depth3 - 2.0 * bevel3);
    p = pos1.xy; // 2d coordinates

    d1 = sdRoundedRectangle(p, vec2(w, h) + thickness3 - bevel3, vec4(w + thickness3 - bevel3, 0.0, w + thickness3 - bevel3, 0.0));
    float t = thickness3 * 0.5 - bevel3;

    d1 = abs(d1 + t) - t; // split into 2 borders
    d1 = max(0.0, d1); // fill shape

    d1 = length(vec2(d1, pos1.z)); // convert to 3d distance
    d1 -= bevel3;
    vec3 d = vec3(d1, MATERIAL_PAINTED_WOOD, 1.0);

    // frame base
    d1 = sdBox(pos + vec3y(h + baseSize.y - 0.001), baseSize - bevel3);
    d1 -= bevel3;
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 2.0));

    // window
    pos1 = pos;

    // rotation
    pos1 -= vec3(w, 0.0, 0.5 * depth1);
    pos1.xz *= rotation(angle);
    pos1 += vec3(w, 0.0, 0.5 * depth1);

    p = pos1.xy; // 2d coordinates

    d1 = sdRoundedRectangle(p, vec2(w, h) - bevel1, vec4(w - bevel1, 0.0, w - bevel1, 0.0));
    t = thickness1 * 0.5 - bevel1;
    d1 = abs(d1 + t) - t; // split into 2 borders
    d1 = max(0.0, d1); // fill shape
    d1 = length(vec2(d1, stretchAxis(pos1.z, depth1 - 2.0 * bevel1))); // convert to 3d distance
    d1 -= bevel1;

    vec3 d4 = vec3(d1, MATERIAL_WOOD3, 2.0);
    bool isVertical = p.y > -h + thickness1 + 0.001;
    d4.yz += 0.99 * fract(isVertical ? (vec2(0.1, 0.01) * vec2(pos1.x + pos1.z, pos1.y) + 0.5) : (vec2(0.01, 0.1) * vec2(pos1.x, pos1.y + pos1.z) + 0.5)); // uv
    d = minx(d, d4);

    // dividers
    d1 = length(vec2(max(abs(p.x) - w + thickness2 - bevel2, 0.0), stretchAxis(p.y + segmentOffset, thickness2 - 2.0 * bevel2))); // horizontal segment
    d1 = max(0.0, d1); // fill shape

    d2 = length(vec2(max(abs(p.y) - h + thickness2 - bevel2, 0.0), stretchAxis(p.x, thickness2 * 0.5 - 2.0 * bevel2))); // vertical segment
    d2 = max(0.0, d2); // fill shape
    d1 = min(d1, d2);
    d1 = length(vec2(d1, stretchAxis(pos1.z, depth2 - 2.0 * bevel2))); // convert to 3d distance
    d1 -= bevel2;
    d4 = vec3(d1, MATERIAL_WOOD3, 3.0);
    isVertical = abs(p.y + segmentOffset) > 0.5 * thickness2 + 0.001;
    d4.yz += 0.99 * fract(isVertical ? (vec2(0.1, 0.01) * vec2(pos1.x + pos1.z, pos1.y)) + 0.5 : (vec2(0.01, 0.1) * vec2(pos1.x, pos1.y + pos1.z)) + 0.5); // uv
    d = minx(d, d4);

    // handle
    vec3 pos2 = pos1;
    pos2.x += 0.5 * w + 1.5 * thickness1 - bevel1;
    pos2.y += segmentOffset;
    d1 = sdCircle(pos2.yz, r4);
    d1 = length(vec2(d1, stretchAxis(pos2.x, width4)));
    d1 -= thickness4;
    d1 = max(d1, pos2.z);
    d4 = vec3(d1, MATERIAL_METAL2, 3.0);
    d = minx(d, d4);

    return d;
}

vec2 sdMoominWindowGlass(vec3 pos, float angle)
{
    // quater size
    const float w = 0.3;
    const float h = 0.4;

    const float depth = 0.06;
    const float thickness = 0.01;

    float bounds = sdBoxApprox(pos, vec3(1.0, 0.6, 0.6), vec3x(0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, 0.0);
    }

    float d1, d2, d3;
    vec3 pos1;
    vec2 p;

    // window
    pos1 = pos;

    // rotation
    pos1 -= vec3(w, 0.0, 0.5 * depth);
    pos1.xz *= rotation(angle);
    pos1 += vec3(w, 0.0, 0.5 * depth);

    p = pos1.xy; // 2d coordinates

    d1 = sdRoundedRectangle(p, vec2(w, h) - depth, vec4(w, 0.0, w, 0.0));

    d1 = max(0.0, d1); // fill shape
    d1 = length(vec2(d1, stretchAxis(pos1.z, thickness))); // convert to 3d distance

    return vec2(d1, MATERIAL_WINDOW_GLASS);
}

float sdMoominRoomBounds(vec3 pos)
{
    const vec3 size = vec3(0.5, 1.0, 1.0);

    float bounds = sdBoxApprox(pos, size, vec3(0.0, 0.0, 0.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return bounds;
    }

    vec3 pos1 = pos;

    float d = abs(pos1.y) - size.y;
    pos1.xz = abs(pos1.xz);
    d = max(d, pos1.x - size.x);
    d = max(d, pos1.z - size.z);
    d = max(d, pos1.x + pos1.y - size.y); // slope

    return d;
}

vec3 sdMoominRoom(vec3 pos)
{
    vec3 d1, d2, d3;

    float bounds = sdBoxApprox(pos, vec3(1.0, 1.2, 1.0), vec3(0.0, 0.0, 0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d = sdMoominRoomBounds(pos);

    d = max(d, -d - 0.1); // exclude inner space
    d = max(d, -pos.z);

    // window opening
    vec3 pos1 = pos;
    pos1.z -= 1.0;
    d = max(d, -sdSphere(pos1 - vec3y(0.3), 0.4));
    d = max(d, -sdBox(pos1, vec3(0.4, 0.3, 0.4)));

    d1 = vec3(d, MATERIAL_PAINTED_WOOD, 0.0);

    // window
    pos1 = pos;
    pos1 -= vec3(0.0, 0.2, 1.0);
    d2 = sdMoominWindow(pos1, -2.5);
    d1 = minx(d1, d2);

    // tiles
    float seed = max(0.0, sign(pos.x));
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1 -= vec3(0.0, 1.0, 0.3);
    pos1.xz *= rotation_n90;
    pos1.yz *= rotation_n45;
    d2 = sdTiles(pos1, vec3(0.5, 0.4, 0.03), vec2(3.0, 3.0), seed + 9.0);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdRopeLadderSegment(vec3 pos, float count, float rope0, float rope1)
{
    const float h = 0.3;
    const float w = 0.8;
    const float r1 = 0.04; // step radius
    const float r2 = 0.02; // rope radius

    float bounds = sdBoxApprox(pos - vec3y(rope0), vec3(w, h * count + rope0 + rope1, r1 + r2 + r2), vec3y(-1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d;

    float index = clamp((pos.y + h) / (2.0 * h), -count + 1.0, 0.0);
    float an = 0.2 * (0.5 - hash(floor(index))); // angle

    vec3 pos1 = pos;
    pos1.y -= floor(index) * 2.0 * h;

    // wood
    pos1.xy *= rotationApprox(an);
    d = sdCircle(pos1.zy, r1);
    d = max(d, 0.0);
    d = length(vec2(d, stretchAxis(pos1.x, w))); // convert to 3d distance
    vec3 d1 = vec3(d, MATERIAL_WOOD3, 1.0);
    d1.yz += vec2(0.01, 0.1) * vec2(pos1.x, pos1.y + pos1.z) + 0.5; // uv

    // rope loops
    pos1.x = abs(pos1.x) - w * 0.5 + 0.1 + 0.2 * abs(an); // mirror 1
    float edge = max(0.0, sign(pos1.x)); // separate loops
    float index2 = sign(pos1.x);
    pos1.x = abs(pos1.x) - 0.014; // mirror 2
    pos1.y = -pos1.y;
    pos1.xy *= rotation_7_5;
    d = sdCircle(pos1.zy, r1 + r2 * 0.5); // rope size
    d = length(vec2(d, pos1.x)); // convert to 3d distance
    d -= r2; // rope thickness

    vec3 d2 = vec3(d, MATERIAL_ROPE, 1.0 + edge);
    d2.y += 0.99 * fract(sqrt(abs(sin(100.0 * (pos1.x + pos1.y) + index2)))); // uv
    d1 = minx(d1, d2);

    // rope
    pos1 = pos;
    pos1.x = abs(pos1.x) - w * 0.5 + 0.1; // mirror
    pos1.z += r1 - r2 * 0.5;
    d = length(pos1.xz);
    d = max(d, max(pos1.y - rope0 * 2.0 * h, -pos1.y - (count - 1.0 + rope1) * 2.0 * h)); // rope length
    d -= r2; // thickness

    d2 = vec3(d, MATERIAL_ROPE, 3.0);
    d2.y += 0.99 * fract(sqrt(abs(sin(100.0 * (pos1.x + pos1.y))))); // uv

    d1 = minx(d1, d2);

    return d1;
}

vec3 sdRopeLadder(vec3 pos)
{
    float bounds = sdBoxApprox(pos, vec3(0.5, 1.2, 1.0), vec3z1);
    bounds = min(bounds, sdBoxApprox(pos - vec3z(1.8), vec3(0.5, 6.0, 0.2), vec3y(-1.0)));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1 -= vec3(0.0, -0.52, 1.15);
    pos1.yz *= rotation_n36;
    vec3 d1 = sdRopeLadderSegment(pos1, 3.0, 0.4, 0.0); // segment 1

    pos1 = pos;
    pos1 -= vec3(0.0, -1.57, 0.71) + vec3(0.0, -0.52, 1.15);
    vec3 d2 = sdRopeLadderSegment(pos1, 14.0, 1.0, 0.6); // segment 2
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdOuterWalls(vec3 pos)
{
    const vec3 size = vec3(0.5, 3.0, 0.06); // tile size
    const vec3 offset = vec3(0.0, 0.4, 0.3); // tile offset
    const float r = 4.0 - 0.5 * size.z;
    const float h = HOUSE_HEIGHT;
    const float seed = 0.0;

    float bounds = sdBoxApprox(pos, vec3(r + size.z, 0.5 * h, r + size.z), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float columns = round(PI2 * r / size.x);
    float an = atan(pos.x, pos.z);

    vec3 pos1 = vec3(an / PI2 * columns * size.x, pos.y, length(pos.xz)); // radial coordinates

    float column = floor(pos1.x / size.x);
    pos1.x -= (column + 0.5) * size.x;
    pos1.z -= r;

    float h1 = hash(column - columns + seed);

    pos1.y -= size.y * 0.5 * mod(column, 2.0); // center
    pos1.y -= size.y * offset.y * h1;

    float row = floor(pos1.y / size.y + 0.5);
    pos1.y -= row * size.y;

    float h2 = hash(columns * row + column + seed);
    float h3 = hash(columns * row + column + seed + 1000.0);
    float h4 = hash(columns * row + column + seed + 2000.0);

    pos1.z += size.z * offset.z * h2;
    float d = sdBox(pos1, size * 0.5); // tile

    float edge = floor(3.0 * h3);
    vec3 d1 = vec3(d, MATERIAL_OUTER_WALL + 0.99 * h4, edge);

    // inner wall
    d = length(pos.xz) - r + size.z;
    d = abs(d) - 0.5 * size.z;
    d = max(0.0, d);

    vec3 d2 = vec3(d, MATERIAL_INNER_WALL + 0.99 * fract(60.0 * (an + PI) / PI2), 0.0);
    d1 = minx(d1, d2);

    d1.x = max(d1.x, -pos.y);
    d1.x = max(d1.x, pos.y - h);

    return d1;
}

float sdRectangleFrame(vec3 pos, vec3 size, vec2 thickness, float bevel)
{
    float d = sdRectangle(pos.xy, 0.5 * size.xy - bevel, thickness);
    return length(vec2(d, stretchAxis(pos.z, size.z - 2.0 * bevel))) - bevel;
}

vec3 sdWindow(vec3 pos, float type)
{
    vec3 d = vec3(MAX_DIST, 0.0, 0.0);
    float d1, d2, d3;

    const float w = 1.0;
    const float h = 1.4;

    vec3 boundsSize = vec3(w, h, 0.2);
    boundsSize.x += type >= 3.0 ? 0.6 * w : 0.0;
    boundsSize.z += type >= 4.0 ? 0.6 * w : 0.0;

    float bounds = sdBoxApprox(pos, boundsSize);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // window
    const float depth1 = 0.06;
    const float thickness1 = 0.1;
    const float bevel1 = 0.01;
    // divider
    const float depth2 = 0.04;
    const float thickness2 = 0.06;
    const float bevel2 = 0.01;
    // frame horizontal segment
    const float depth3 = 0.2;
    const float thickness3 = 0.06;
    const float bevel3 = 0.01;
    const float ext3 = 0.04;
    // frame vertical segment
    const float depth4 = 0.15;
    const float thickness4 = 0.04; // vertical
    const float bevel4 = 0.01;
    // adornment
    const float depth5 = 0.25;
    const float depth6 = 0.05;

    const vec3 baseSize = vec3(w + 0.3, 0.2, 0.25);

    vec3 pos1 = pos; // wide window (type 3)
    pos1.x = abs(pos.x) - 0.5 * w - thickness4;

    vec3 pos2 = pos; // bay window (type 4)
    pos2.z -= w * 0.55;
    pos2.x = abs(pos2.x);
    pos2.xz *= rotation_n20;
    pos2.x = abs(pos2.x - 0.5 * w) - 0.5 * w;
    pos2.xz *= rotation_n20;

    pos = type >= 3.0 ? pos1 : pos;
    pos = type >= 4.0 ? pos2 : pos;

    pos1 = pos;

    // window
    pos1 = pos;
    float index = max(0.0, sign(pos1.x));
    pos1.x = abs(pos1.x) - 0.25 * w;

    d1 = sdRectangleFrame(pos1, vec3(0.5 * w, h, depth1), vec2(thickness1 * 0.5), bevel1);
    d = minx(d, vec3(d1, MATERIAL_WOOD3, 2.0 + index));

    // dividers
    pos1.y = abs(pos1.y) - h / 6.0; // mirror
    d1 = sdBox(pos1, vec3(w / 4.0, 0.5 * thickness2, 0.5 * depth2) - bevel2);
    d1 -= bevel2;
    d = minx(d, vec3(d1, MATERIAL_WOOD3, 4.0));

    bool isVertical = abs(pos1.x) > 0.25 * w - thickness2 - bevel2;
    d.yz += 0.99 * fract(isVertical ? (vec2(0.1, 0.01) * vec2(pos.x, pos.y + pos.z) + 0.5) : (vec2(0.01, 0.1) * vec2(pos.x + pos.y, pos.z) + 0.5)); // uv

    // frame
    pos1 = pos;
    pos1.y = abs(pos1.y) - 0.5 * h - thickness3;
    d1 = sdBox(pos1, vec3(w * 0.5 + 2.0 * thickness4 + ext3, thickness3, depth3) - bevel3); // horizontal
    d1 -= bevel3;
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 5.0));

    pos1 = pos;
    pos1.x = abs(pos1.x) - 0.5 * w - thickness4;
    d1 = sdBox(pos1, vec3(thickness4, 0.5 * h, depth4) - bevel3); // vertical
    d1 -= bevel3;
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 6.0));

    // adornment
    pos1 = pos;
    pos1.x = abs(pos1.x) - 0.25 * w; // mirror
    pos1.y -= 0.5 * h + 2.0 * thickness3; // base height

    // pointed pediment
    pos2 = pos1;
    pos2.z = stretchAxis(pos2.z, depth5);
    float h2 = 0.3 * w;
    pos2.y -= h2;
    pos2.xy *= rotation_n45;
    d1 = sdBox(pos2, vec3(w * 0.5, thickness4, depth6) - bevel4);
    d2 = sdBoxApprox(pos2 + vec3(0.0, h2, 0.0), vec3(w * 0.5, h2, 0.0));
    d1 = min(d1, d2);
    d1 -= bevel3;

    // segmental pediment
    pos2 = pos1;
    pos2.z = stretchAxis(pos2.z, depth5);
    pos2.x += w * 0.25;
    d2 = sdCircle(pos2.xy, w * 0.5);
    d3 = d2;
    d2 = max(d2, 0.0);
    d2 = length(vec2(d2, pos2.z));

    d3 -= thickness4;
    d3 = abs(d3) - thickness4 + bevel4;
    d3 = max(d3, 0.0);
    d3 = length(vec2(d3, stretchAxis(pos2.z, depth6)));
    d2 = min(d2, d3);
    d2 -= bevel4;

    d1 = type < 1.0 ? d1 :
        (type < 2.0 ? d2 : MAX_DIST); // select type

    d1 = max(d1, -pos1.z + 0.01);

    d1 = max(d1, -pos1.y);
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 7.0));

    return d;
}

float sdWindowsBounds(vec3 pos)
{
    const float floorHeight = HOUSE_HEIGHT / 3.0;

    float bounds = sdBoxApprox(pos, vec3(4.5, 6.2, 4.5), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return bounds;
    }

    vec3 pos1 = pos;
    float row = clamp(floor(pos1.y / floorHeight), 0.0, 2.0);
    pos1.y += 0.1;
    pos1.y -= (row + 0.5) * floorHeight;

    float column = 0.0;
    pos1.xz *= rotation_30;
    pos1.xz = radialMod(pos1.xz, 6.0, column);
    pos1.xz *= rotation_n90;

    bool isWideWindow = row == 0.0 && column == 0.0;
    bool isBayWindow = row == 1.0 && column == -1.0;

    vec3 pos2 = pos1;
    pos2.xz *= rotation_n7_5;
    pos1 = isBayWindow ? pos2 : pos1; // shift bay window

    pos1.z -= 4.0;
    float w = 0.5;
    w += isWideWindow ? 0.5 : 0.0; // wide window
    w += isBayWindow ? 0.8 : 0.0; // bay window
    float d1 = sdBoxApprox(pos1, vec3(w, 0.75, 0.4));
    d1 -= 0.03;

    // mask
    pos1 = pos;
    pos1.z = abs(pos1.z); // front and back windows
    pos1 -= vec3(0.0, 2.4, 4.0);
    float d2 = -sdBoxApprox(pos1, vec3(0.7, 1.2, 0.2));
    d1 = max(d1, d2);

    return d1;
}

vec3 sdFrontWindowDecoration(vec3 pos)
{
    const float s1 = 0.21; // top diamond size
    const float s2 = 0.14; // middle shpere radius
    const float h2 = 0.12; // middle shpere height
    const float s3 = 0.04; // base thickness
    const float r3 = 0.02; // base corner radius
    const float w3 = 0.3; // base depth
    const float h3 = 0.1; // base height
    const float width4 = 0.1; // pendiment wings
    const float length4 = 0.7;
    const float thickness4 = 0.03;
    const float depth4 = 0.4;
    const float bevel4 = 0.01;
    const float curve4 = 0.25;
    const float gap4 = 0.2;
    const float r5 = 1.5; // pendiment surface size
    const float h5 = 0.55;
    const float thickness5 = 0.2;
    const float bevel5 = 0.01;
    const float r6 = 1.8; // pendiment surface cut radius

    float bounds = sdBoxApprox(pos, vec3(1.0, 0.5, 0.3), vec3y(-0.3));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d1, d2, d3;

    vec3 pos1 = pos;
    pos1.z -= 0.3;
    pos1.y -= 0.28;

    vec3 pos2 = pos1;

    // top diamond
    pos2 = abs(pos2);
    pos2.y -= s1;
    pos2.xz *= rotation_n45;
    pos2.zy *= rotation_25;

    d1 = pos2.z;

    // middle sphere
    pos2 = pos1;
    pos2.y += 1.3 * s1;
    d2 = sdEllipsoid(pos2, vec3(s2, h2, s2));
    d1 = smin(d1, d2, 0.04);

    // base
    pos2.y += h2;
    vec3 pos3 = pos2;
    pos3.z += s3 + w3 - r3;
    d2 = sdRectangle(pos3.yz, vec2(h3, w3));
    d2 -= r3;
    d2 = length(vec2(d2, pos3.x));
    d2 -= s3;
    d2 = max(d2, pos3.y);
    d2 = max(d2, -pos3.z);

    d1 = smin(d1, d2, 0.05);

    // pediment wings
    pos1 = pos;
    pos1.y -= thickness4 * 0.5;
    pos1.x = abs(pos1.x);
    pos1.x -= gap4;
    d2 = abs(pos1.y + curve4 * smoothstep(0.0, length4, pos1.x));
    d2 -= thickness4;
    d2 = max(0.0, d2);
    d2 = length(vec2(d2, stretchAxis(pos1.z, depth4)));
    d2 = max(d2, -pos1.x);
    d2 = max(d2, pos1.x - length4);
    d2 -= bevel4;

    d1 = min(d1, d2);

    // pendiment surface
    pos1 = pos;
    pos1.y += r5;
    d2 = sdCircle(pos1.xy, r5);
    d2 = max(0.0, d2); // fill
    pos1.y -= r5 - h5;
    d2 = max(d2, -pos1.y); // cut bottom part

    pos2 = pos1;
    pos2.x = abs(pos2.x);
    pos2.x -= 0.95;
    d3 = sdCircle(pos2.xy, 0.2 * r6);
    d2 = max(d2, -d3); // cut side circles

    d2 = length(vec2(d2, stretchAxis(pos1.z, thickness5)));
    d2 -= bevel5;
    d1 = min(d1, d2);

    return vec3(d1, MATERIAL_PAINTED_WOOD, 0.0);
}

vec3 sdBayWindowTiles(vec3 pos)
{
    const vec3 tileSize = vec3(0.5, 0.5, 0.03);

    vec3 pos1 = pos;
    pos1.y -= 1.62;

    float bounds = sdBoxApprox(pos1, vec3(1.8, 0.8, 1.3), vec3y(-1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos1.z -= 0.05;
    pos1.z += pow2(abs(pos.x) * 0.67);
    pos1.yz *= rotation_n45;

    float d = sdBox(pos1, vec3(1.5, 0.55, 0.08), vec3(0.0, -1.0, -1.0), 0.0);
    vec3 d1 = vec3(d, MATERIAL_PAINTED_WOOD, 0.0);

    vec3 d2 = sdTiles(pos1 - vec3z(tileSize.z), tileSize, vec2(7.0, 3.0), 4.0);
    d2.x *= 0.8; // approximation
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdBayWindowSupport(vec3 pos)
{
    // base
    const float bevel1 = 0.01;

    // support
    const float bevel2 = 0.01;
    const float gap2 = 0.3;
    const float offset2 = 0.2;
    const vec3 size2 = vec3(0.12, 0.6, 0.08);

    float bounds = sdBoxApprox(pos, vec3(1.2, 1.4, 0.8), vec3y(-0.2));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y += 0.1;
    pos1.y = abs(pos1.y);
    pos1.y -= 0.76;
    pos1.z -= 0.11;
    float d = sdBox(pos1, vec3(1.05, 0.06, 0.25) - bevel1);
    d -= bevel1;
    vec3 d1 = vec3(d, MATERIAL_PAINTED_WOOD, 5.0);

    pos1 = pos;

    pos1.y += 1.15;

    vec3 pos2 = pos1;
    pos2.z -= 0.1;
    pos2.z -= abs(pos.x) < gap2 * 0.5 ? offset2 : 0.0;
    pos2.yz *= rotation_45;
    pos2.x = abs(pos2.x) - gap2;
    pos2.x = abs(pos2.x) - gap2;
    d = sdBox(pos2, size2 - bevel2);
    d -= bevel2;
    d = max(d, -pos1.z);
    d = max(d, pos1.y - 0.5 * size2.y);

    vec3 d2 = vec3(d, MATERIAL_PAINTED_WOOD, 1.0);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdWindows(vec3 pos)
{
    const float floorHeight = HOUSE_HEIGHT / 3.0;

    float bounds = sdBoxApprox(pos, vec3(4.5, HOUSE_HEIGHT / 2.0, 4.5), vec3y1);
    bounds = max(bounds, -sdBoxApprox(pos, vec3(2.8, 6.0, 2.8), vec3y1));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;

    float row = clamp(floor(pos1.y / floorHeight), 0.0, 2.0);
    pos1.y -= (row + 0.5) * floorHeight;

    float column = 0.0;
    pos1.xz *= rotation_30;
    pos1.xz = radialMod(pos1.xz, 6.0, column);
    pos1.xz *= rotation_n90;

    bool isWideWindow = row == 0.0 && column == 0.0;
    bool isBayWindow = row == 1.0 && column == -1.0;

    vec3 pos2 = pos1;

    vec3 pos3 = pos2;
    pos3.xz *= rotation_n7_5;
    pos2 = isBayWindow ? pos3 : pos2; // shift bay window

    pos2.y += 0.1;
    pos2.z -= 3.89;
    float style = row;
    style += isWideWindow ? 3.0 : 0.0;
    style += row == 0.0 && column == -1.0 ? 2.0 : 0.0; // -1,0 doesn't have decoration
    style += row == 1.0 && column == 1.0 ? 1.0 : 0.0; // 1,1 has entrance decoration
    style += isBayWindow ? 3.0 : 0.0;

    vec3 d1 = sdWindow(pos2, style);

    // radial bounds
    pos2 = pos1;
    pos2.x = abs(pos2.x);
    pos2.xz *= rotation_n30;
    pos2.x -= 0.1;
    d1.x = min(d1.x, -pos2.x);

    pos2 = pos;
    pos2.y -= 1.5 * floorHeight + 1.25;
    pos2.z -= 3.9;
    vec3 d2 = sdFrontWindowDecoration(pos2);

    pos2 = pos;
    pos2.y -= 1.5 * floorHeight;
    pos2.xz *= rotation_n120;
    pos2.xz *= rotation_n7_5;
    pos2.z -= 3.9;
    vec3 d3 = sdBayWindowTiles(pos2);
    d2 = minx(d2, d3);

    d3 = sdBayWindowSupport(pos2);
    d2 = minx(d2, d3);

    d2.x = max(d2.x, -length(pos.xz) + 3.9);
    d1 = minx(d1, d2);

    // mask
    pos1 = pos;
    pos1.z = abs(pos1.z); // front and back windows
    pos1 -= vec3(0.0, 2.4, 4.0);
    d2 = vec3(-sdBoxApprox(pos1, vec3(0.7, 1.3, 0.5)), 0.0, 0.0);
    d1 = maxx(d1, d2);

    return d1;
}

vec2 sdWindowsGlass(vec3 pos)
{
    const float floorHeight = HOUSE_HEIGHT / 3.0;

    float bounds = sdBoxApprox(pos, vec3(4.5, HOUSE_HEIGHT / 2.0, 4.5), vec3y1);
    bounds = max(bounds, -sdBoxApprox(pos, vec3(2.8, 6.0, 2.8), vec3y1));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, 0.0);
    }

    vec3 pos1 = pos;

    float row = clamp(floor(pos1.y / floorHeight), 0.0, 2.0);
    pos1.y += 0.1;
    pos1.y -= (row + 0.5) * floorHeight;

    float column = 0.0;
    pos1.xz *= rotation_30;
    pos1.xz = radialMod(pos1.xz, 6.0, column);
    pos1.xz *= rotation_n90;

    bool isWideWindow = row == 0.0 && column == 0.0;
    bool isBayWindow = row == 1.0 && column == -1.0;

    vec3 pos2 = pos1;

    vec3 pos3 = pos2;
    pos3.xz *= rotation_n7_5;
    pos2 = isBayWindow ? pos3 : pos2; // shift bay window

    pos2.z -= 3.89;

    float w = 0.5;
    w += isWideWindow ? 0.5 : 0.0;

    pos3 = pos2; // bay window
    pos3.x = abs(pos3.x);
    pos3.xz *= rotation_n20;
    pos3.x = abs(pos3.x - 0.65 * w) - 0.65 * w;
    pos3.xz *= rotation_n20;
    pos3.z -= 1.1 * w;
    pos2 = isBayWindow ? pos3 : pos2;

    float d1 = sdBoxApprox(pos2, vec3(w, 0.8, 0.005));

    // radial bounds
    pos2 = pos1;
    pos2.x = abs(pos2.x);
    pos2.xz *= rotation_n30;
    pos2.x -= 0.1;
    d1 = min(d1, -pos2.x);

    // mask
    pos1 = pos;
    pos1.z = abs(pos1.z); // front and back windows
    pos1 -= vec3(0.0, 2.4, 4.0);
    float d2 = -sdBoxApprox(pos1, vec3(0.7, 1.3, 0.5));
    d1 = max(d1, d2);

    return vec2(d1, MATERIAL_WINDOW_GLASS);
}

vec3 sdHouseBase(vec3 pos)
{
    const float bevel = 0.2;
    const float r0 = 4.0 + bevel;

    const float r1 = 4.5 - bevel;
    const float h1 = 0.6 - bevel;

    const float r2 = 4.8 - bevel;
    const float h2 = 0.4 - bevel;

    float bounds = sdBoxApprox(pos, vec3(r2, h1, r2) + bevel);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 p = vec2(length(pos.xz), pos.y);
    vec2 uv = vec2((atan(pos.z, pos.x) + PI) / PI2, 0.0);

    // slope
    vec2 p1 = vec2(r1, h1);
    vec2 p2 = vec2(r2, h2);
    float t = clamp(lineIntersection(p, p1, p2), 0.0, 1.0);
    vec2 c1 = p1 + t * (p2 - p1); // closest point on slope

    // closest point
    vec2 c2 = p.x > r1 ? (p.y > h2 ? c1 : vec2(r2, max(p.y, 0.0))) : vec2(max(p.x, r0), h1);

    float d = length(p - c2);

    uv.y = (c2.x + max(h2 - c2.y, 0.0)) / (r2 + h2);

    vec2 v = d < 0.21 ? voronoi(uv * 10.0 * vec2(4.0, 1.0)) : vec2(0.0);

    d -= bevel - 0.1 * v.x;

    return vec3(d, MATERIAL_BASE_ROCK + 0.99 * v.x, 1.0);
}

vec3 sdPostBase(vec3 pos, vec2 size, float style) // 1 - mirror, 2 - 90 degrees, 3 - both
{
    // half size
    const float bevel = 0.01;

    const vec2 thickness = vec2(0.04, 0.08);
    const float depth = 0.02;

    float bounds = sdBoxApprox(pos, size.xyx);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d1 = sdBox(pos, size.xyx - bevel);
    d1 -= bevel;

    vec3 d = vec3(d1, MATERIAL_PAINTED_WOOD, 1.0);

    vec3 pos1 = pos;
    pos1.xz = style == 1.0 || style == 3.0 ? abs(pos1.xz) : pos1.xz; // mirror
    pos1.xz = style >= 2.0 && pos1.z < pos1.x ? pos1.zx : pos1.xz; // 90 degree mirror

    d1 = sdBox(pos1 - vec3z(size.x), vec3(size - thickness, depth));
    d = maxx(d, vec3(-d1, MATERIAL_PAINTED_WOOD, 2.0));

    return d;
}

vec3 sdPost(vec3 pos, vec2 size)
{
    const float curve = 1.5;
    const float skew = 0.07;
    const float bevel = 0.02;

    vec2 p = vec2(length(pos.xz), pos.y);

    float r = size.x;
    float h = size.y;

    float bounds = sdBoxApprox(pos, size.xyx);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 p1 = p;
    p1.y = abs(p1.y); // mirror

    vec2 p2 = p1;
    p2.y -= h - bevel;
    float d1 = p2.y <= 0.0 ? length(p2) - r + bevel : length(vec2(max(p2.x - r + bevel, 0.0), p2.y)); // bottom half of a sphere
    d1 -= bevel;

    // slice of a large sphere
    float h1 = h - r;
    float r1 = curve * (r * r + h1 * h1) / (2.0 * r); // larger sphere radius
    float d2 = length(p + vec2(r1 - 1.0 * r, skew * h)) - r1;
    d2 = max(d2, p1.y - h + r); // clip sphere
    d1 = smin(d1, d2, 0.05);

    return vec3(d1, MATERIAL_PAINTED_WOOD, 1.0);
}

vec3 sdPostCap(vec3 pos, float r)
{
    const float bevel = 0.03;
    const float petals = 5.0;

    vec2 p = vec2(length(pos.xz), pos.y);

    float bounds = sdBoxApprox(pos, vec3(r, 1.5 * r, r), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // base
    vec2 p1 = p;
    float d1 = length(p1 - vec2y(r)) - r;

    // petals
    vec2 p2 = p;
    float an = atan(pos.z, pos.x);
    float offset1 = 1.0 - pow2(2.0 * (mod(petals * an / PI2, 1.0) - 0.5)); // petals offset
    float r1 = r * (1.0 + 0.4 * offset1 * smoothstep(0.0, r, p.x)); // petals radius

    p2.y -= 3.2 * r - r1;
    float d2 = p2.y > 0.0 ? (length(p2) - r1 + bevel) : length(vec2(max(p2.x - r1 + bevel, 0.0), p2.y)); // top half of a sphere
    d2 -= bevel;
    d1 = min(d1, d2);

    return vec3(d1, MATERIAL_PAINTED_WOOD, 2.0);
}

// corbel
vec3 sdPoleSupport(vec3 pos, float gap, float style) // 1 - mirror, 2 - 90 degrees, 3 - both
{
    const float h = 0.21;
    const float w = 0.4;
    const float depth = 0.15;
    const float bevel = 0.02;

    pos.y += 2.0 * h;

    pos.xz = -pos.xz;
    pos.xz = style == 1.0 || style == 3.0 ? abs(pos.xz) : pos.xz; // mirror
    pos.xz = style >= 2.0 && pos.x < pos.z ? pos.zx : pos.xz; // 90 degree mirror

    pos.x -= gap;

    float bounds = sdBoxApprox(pos - vec3(w, h, 0.0), vec3(w, h, depth));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d1 = sdRectangleApprox(pos.xy - vec2(w, h), vec2(w - bevel, h - bevel));
    float d2 = sdEllipse(pos.xy - vec2x(2.0 * w), vec2(2.0 * w + bevel, 2.0 * h + bevel));
    d1 = max(d1, -d2);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos.z, depth)));
    d1 -= bevel;

    return vec3(d1, MATERIAL_PAINTED_WOOD, 0.0);
}

vec3 sdPorchDoorHandle(vec3 pos)
{
    const vec2 size = vec2(0.045, 0.07); // door handle base size
    const float r = 0.015; // door handle radius
    const float width = 0.18; // door handle length
    const float depth = 0.15; // door handle depth
    const float bevel = 0.005;

    float bounds = sdBoxApprox(pos, vec3(depth, size.x, 2.0 * size.x), vec3x(0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 100.0, 0.0);
    }

    // handle base
    vec3 pos1 = pos;
    float d1 = sdCircle(pos1.xy, size.x - bevel);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos.z, size.y - 2.0 * bevel)));
    d1 -= bevel;
    vec3 d = vec3(d1, MATERIAL_METAL4, 7.0);

     // handle
    pos1 = pos;
    pos1 -= vec3(width * 0.5, 0.0, depth * 0.5);
    pos1.x += 0.5 * width;
    pos1.z = -pos1.z;
    pos1.xz = pos1.x > pos1.z ? pos1.xz : pos1.zx;
    d1 = length(pos1.xz - vec2(clamp(pos1.x, 0.0, width), 0.0));
    d1 = length(vec2(d1, pos1.y));
    d1 -= r;

    d = minx(d, vec3(d1, MATERIAL_METAL4, 8.0));
    return d;
}

float sdPorchDoorBounds(vec3 pos)
{
    // half size
    const float w = 0.7;
    const float h = 1.1;
    const float depth = 0.25;

    float bounds = sdBoxApprox(pos, vec3(w, h, depth));
    if (bounds > BOUNDS_MARGIN)
    {
        return bounds;
    }

    float d = sdRoundedRectangle(pos.xy, vec2(w, h), vec4(w, 0.0, w, 0.0));
    d = max(0.0, d); // fill
    d = length(vec2(d, stretchAxis(pos.z, depth)));
    d -= 0.01;

    return d;
}

vec3 sdPorchDoor(vec3 pos)
{
    // half size
    const float w = 0.7;
    const float h = 1.1;
    const float width1 = 0.08; // door frame width
    const float depth1 = 0.04; // door frame depth
    const float width2 = (w - width1) / 4.0; // bars width
    const float depth2 = 0.03; // bars depth
    const float width31 = 0.015; // window dividers
    const float width32 = 0.035; // window frame width
    const float depth3 = 0.035; // window frame depth
    const float width4 = 0.05; // lintel width
    const float depth4 = 0.25; // lintel depth
    const float r1 = 0.5 * w; // window radius
    const float r2 = 0.2 * w; // window dividers size
    const float bevel = 0.01;

    float bounds = sdBoxApprox(pos, vec3(w + depth4, h + depth4, 0.2));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1;
    float d1, d2, d3, d4;

    pos.z = abs(pos.z); // mirror

    // base shape
    float baseShape = sdRoundedRectangle(pos.xy, vec2(w, h) - bevel, vec4(w - bevel, 0.0, w - bevel, 0.0));

    // window opening
    pos1 = pos;
    pos1.y -= h - w;
    float windowOpening = sdCircle(pos1.xy, r1);

    // window
    pos1.xy = abs(pos1.xy); // mirror
    pos1.xy = pos1.x < pos1.y ? pos1.yx : pos1.xy; // mirror 90 degrees

    // window dividers
    d1 = abs(r2 - pos1.x - pos1.y) * 0.7071067; // diagonal distance
    d1 = pos1.x > r2 ? min(pos1.y, d1) : d1; // perpendicular distance
    d1 = max(d1, windowOpening); // clip
    d1 -= width31 - bevel; // add thickness
    d1 = max(0.0, d1); // fill

    // window perimeter
    d2 = windowOpening;
    d2 = abs(d2) - width32 + bevel; // add thickness;
    d2 = max(0.0, d2); // fill
    d1 = min(d1, d2);

    d1 = length(vec2(d1, stretchAxis(pos1.z, depth3 - 2.0 * bevel)));
    d1 -= bevel;

    vec3 d = vec3(d1, MATERIAL_PAINTED_WOOD, 1.0);

    // vertical bars
    pos1 = pos;
    float column = floor(pos1.x / width2 + 0.5);
    pos1.x -= column * width2;
    d1 = abs(pos1.x) - 0.5 * (width2 - bevel);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos1.z, depth2 - 2.0 * bevel)));
    d1 -= bevel;

    d2 = max(baseShape + 0.5 * width1 - bevel, -windowOpening); // window opening
    d2 = max(0.0, d2); // fill
    d1 = max(d1, d2); // intersection

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 2.0 + mod(column, 2.0)));

    // door frame
    d1 = baseShape;
    d1 += width1 - bevel;
    d1 = abs(d1) - width1 + bevel;
    d1 = max(0.0, d1);

    // door frame horizontal bar
    d2 = sdRectangle(pos.xy + vec2y(0.5 * w - width1), vec2(w - bevel, width1 - bevel));
    d2 = max(0.0, d2);
    d1 = min(d1, d2);

    d1 = length(vec2(d1, stretchAxis(pos.z, depth1 - 2.0 * bevel)));
    d1 -= bevel;

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 5.0));

    // lintel
    d1 = baseShape;
    d1 -= width4 + bevel;
    d1 = abs(d1) - width4 + bevel;
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos.z, depth4 - 2.0 * bevel)));
    d1 -= bevel;
    d1 = max(d1, -pos.y - h + 0.01);
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 6.0));

    // door handle
    pos1 = pos;
    pos1.xy += vec2(w - width1 * 1.3, 0.5 * w - width1);
    d = minx(d, sdPorchDoorHandle(pos1));

    return d;
}

vec2 sdPorchDoorGlass(vec3 pos)
{
    float bounds = sdBoxApprox(pos, vec3(0.4, 0.4, 0.05));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, 0.0);
    }

    float d = sdCircle(pos.xy, 0.35);
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos.z, 0.01)));

    float m = pos.x * pos.y > 0.0 ? MATERIAL_DOOR_GLASS1 : MATERIAL_DOOR_GLASS2;
    m = abs(pos.x) + abs(pos.y) > 0.12 ? m : MATERIAL_DOOR_GLASS3;

    return vec2(d, m);
}

float sdFenceRails(vec3 pos, float gridSize)
{
    const float width = 0.15;
    const float depth = 0.1;
    const float bevel = 0.02;

    pos.z = stretchAxis(pos.z + gridSize, 2.0 * gridSize) - 1.5 * gridSize; // length
    pos.xz = pos.z < pos.x ? pos.zx : pos.xz; // mirror 90 degrees

    float bounds = sdBoxApprox(pos, vec3(5.5 * gridSize, depth, width));
    if (bounds > BOUNDS_MARGIN)
    {
        return bounds;
    }

    float d = sdRectangle(pos.xz, vec2(5.5 * gridSize, width) - bevel);
    d = max(0.0, d); // fill
    d = length(vec2(d, stretchAxis(pos.y, depth - bevel * 2.0))); // depth
    d -= bevel;

    return d;
}

vec3 sdPorchFloor(vec3 pos, float gridSize)
{
    const float thickness = 0.02; // floor thickness
    const float height = 0.6; // base height
    const float bevel = 0.02;
    const float baseGridSize = 0.7;

    float bounds = sdBoxApprox(pos, vec3(gridSize * 7.5, height * 0.5, gridSize * 4.0), vec3(0.0, 1.0, -1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // bars
    vec3 pos1 = pos;
    pos1.y -= height - thickness;
    pos1.z += 4.0 * gridSize;
    float index = floor(pos1.x / gridSize + 0.5);
    index = clamp(index, -7.0, 7.0);
    pos1.x -= index * gridSize;
    float d = sdRectangle(pos1.xz, gridSize * vec2(0.5, 4.0) - bevel);
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos1.y, 2.0 * thickness - bevel * 2.0)));
    d -= bevel;
    vec3 d1 = vec3(d, MATERIAL_WOOD4, 1.0 + mod(index, 2.0));
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * pos.xz + 0.1 * index); // uv

    // base
    pos1 = pos;
    pos1.z += 4.0 * gridSize;
    float gridSize1 = gridSize * baseGridSize;
    vec2 index1 = floor(pos1.xz / gridSize1 + 0.5);
    index1 = clamp(index1, vec2(-10.0, -5.0), vec2(10.0, 5.0));
    pos1.xz -= index1 * gridSize1;

    d = sdRectangle(pos1.xz, gridSize1 * vec2(0.5) - bevel);
    d = max(0.0, d); // fill
    d = length(vec2(d, stretchAxis(pos1.y - (height - 2.0 * thickness) * 0.5, height - 2.0 * thickness - bevel * 2.0))); // height
    d -= bevel;
    vec3 d2 = vec3(d, MATERIAL_WOOD4, 4.0 + mod(index1.x, 2.0) + mod(index1.y, 2.0));
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index1); // uv

    d1 = minx(d1, d2);

    return d1;
}

vec3 sdPorchStairs(vec3 pos, float gridSize)
{
    const float thickness = 0.02; // floor thickness
    const float height = 0.2; // step height
    const float depth = 0.4; // step depth
    const float ext = 0.05; // step extension
    const float bevel = 0.02;
    const float baseGridSize = 0.7;

    float gridSize1 = gridSize * baseGridSize;

    pos.z += ext;

    vec3 pos1 = pos;
    pos1 -= vec3(0.0, height, depth);
    float bounds = sdBoxApprox(pos1, vec3(gridSize1 * 2.5, height, depth) + ext);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // top step
    pos1 = pos;

    float index = floor(pos1.x / gridSize1 + 0.5);
    index = clamp(index, -2.0, 2.0);

    pos1 -= vec3(index * gridSize1, height - thickness, 0.5 * depth);
    float d = sdBox(pos1, vec3(gridSize1 * 0.5, height - thickness, depth * 0.5) - bevel);
    d -= bevel;
    vec3 d1 = vec3(d, MATERIAL_WOOD4, 1.0 + mod(index, 2.0));
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index); // uv

    pos1 = pos;
    pos1 -= vec3(0.0, 2.0 * height - thickness, 0.5 * depth + 0.5 * ext);
    d = sdBox(pos1, vec3(gridSize1 * 2.5 + ext, thickness, (depth + ext) * 0.5) - bevel);
    d -= bevel;
    vec3 d2 = vec3(d, MATERIAL_WOOD4, 4.0);
    d2.yz += 0.99 * fract(0.5 + vec2(0.01, 0.1) * pos.xz); // uv
    d1 = minx(d1, d2);

    // bottom step
    pos1 = pos;
    pos1 -= vec3(index * gridSize1, height * 0.5 - thickness, 1.5 * depth);
    d = sdBox(pos1, vec3(gridSize1 * 0.5, height * 0.5 - thickness, depth * 0.5) - bevel);
    d -= bevel;
    d2 = vec3(d, MATERIAL_WOOD4, 3.0 + mod(index, 2.0));
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index); // uv
    d1 = minx(d1, d2);

    pos1 = pos;
    pos1 -= vec3(0.0, height - thickness, 1.5 * depth + 0.5 * ext);
    d = sdBox(pos1, vec3(gridSize1 * 2.5 + ext, thickness, (depth + ext) * 0.5) - bevel);
    d -= bevel;
    d2 = vec3(d, MATERIAL_WOOD4, 4.0);
    d2.yz += 0.99 * fract(0.5 + vec2(0.01, 0.1) * pos.xz); // uv
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdPorchChair(vec3 pos)
{
    // seat
    const float w1 = 0.25;
    const float thickness1 = 0.04;

     // back
    const float h2 = 0.35;
    const float thickness2 = 0.01;

    const float h3 = 0.2; // legs length (half)
    const float r3 = 0.025; // legs radius
    const float bevel = 0.015;

    float bounds = sdBoxApprox(pos, vec3(w1, h2 + h3, w1), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d = vec3(MAX_DIST, 0.0, 0.0);

    pos.x = abs(pos.x);

    vec3 pos1 = pos;
    pos1.y -= 2.0 * h3;
    pos1.z -= w1;

    // back
    vec3 pos2 = pos1;
    pos2.yz *= rotation_7_5;
    pos2 -= vec3(0.0, h2 * 0.8, -2.0 * thickness1);

    float d1 = sdEllipse(pos2.xy, vec2(w1, h2) - bevel);
    d1 = max(0.0, d1); // fill
    d1 = length(vec2(d1, stretchAxis(pos2.z, thickness2 - 2.0 * bevel))); // add thickness

    pos2.x -= w1 * 0.4;
    float d2 = sdEllipse(pos2.xy, vec2(w1 * 0.3, h2 * 0.6) + bevel); // opening
    d2 = max(d2, abs(pos2.z) - 2.0 * (thickness2 + 2.0 * bevel)); // add thickness
    d2 = d2 < 1.0 ? d2 * 0.5 : d2; // compansate approximation

    d1 = max(d1, -d2); // clip openings
    d1 = max(d1, -pos1.y + thickness1); // clip bottom part
    d1 -= bevel;

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 1.0));

    // seat
    pos2 = pos1;
    pos2.z += w1;

    d1 = sdCircle(pos2.xz, w1 - bevel);
    d1 = max(0.0, d1); // fill
    d1 = length(vec2(d1, stretchAxis(pos2.y, thickness1 - 2.0 * bevel))); // add thickness
    d1 -= bevel;

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 2.0));

    // legs
    pos2.z = abs(pos2.z);
    pos2.xz -= vec2(0.5 * w1);
    pos2.xz *= rotation_n45;
    pos2.yz *= rotation_n10;
    d1 = sdCircle(pos2.xz, r3);
    d1 = max(d1, abs(pos2.y + h3) - h3); // clip legs

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 3.0));

    return d;
}

vec3 sdPorchTable(vec3 pos)
{
    const float r1 = 0.55; // table radius
    const float h = 0.7; // height
    const float thickness1 = 0.04; // top thickness
    const float r2 = 0.08; // base radius
    const float r3 = 0.2; // legs curve radius
    const float w3 = 0.05; // legs width (half)
    const float thickness3 = 0.06; // legs thickness
    const float bevel = 0.02;

    float bounds = sdBoxApprox(pos, vec3(r1, h * 0.5, r1), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d = vec3(MAX_DIST, 0.0, 0.0);

    // top
    vec3 pos1 = pos;
    pos1.y -= h - thickness1 * 0.5;
    float d1 = sdCircle(pos1.xz, r1 - bevel);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos1.y, thickness1 - 2.0 * bevel))); // add thickness
    d1 -= bevel;
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 1.0));

    // base
    vec2 p = vec2(length(pos.xz), pos.y);
    p.y -= h - thickness1;
    d1 = sdCircle(p, r2); // top part
    d1 = max(d1, p.y);

    p.y = pos.y - r3 + w3;
    float d2 = sdEllipse(p, vec2(r2, h - r2 - r3 + w3)); // center part
    d2 = max(d2, -p.y);
    d1 = smin(d1, d2, 0.1);

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 2.0));

    // legs
    pos1 = pos;
    pos1.zx = abs(pos1.zx);
    pos1.xz = pos1.x < pos1.z ? pos1.zx : pos1.xz;
    pos1.x -= r2 * 0.5;
    d1 = sdCircle(pos1.xy, r3);
    d1 = max(0.0, abs(d1) - w3 + bevel); // duplicate edge
    d1 = max(d1, -pos1.y); // clip bottom half
    pos1.x -= r3 + 0.5 * w3;
    d2 = sdRectangle(pos1.xy, w3 * vec2(1.5, 0.5) - bevel);
    d1 = smin(d1, d2, 0.1);
    d1 = max(d1, 0.0); // fill
    d1 = max(d1, -pos1.y); // flatten bottom part

    d1 = length(vec2(d1, stretchAxis(pos1.z, thickness3 - 2.0 * bevel))); // add thickness
    d1 -= bevel;

    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 3.0));
    return d;
}

vec3 sdJarJuice(vec3 pos)
{
    const float r = 0.075;
    const float h = 0.3;
    const float thickness1 = 0.005;
    // base
    const float thickness2 = 0.01;
    const float f = 0.6; // fill

    float bounds = sdBoxApprox(pos, vec3(1.3 * r, 0.6 * h, 1.3 * r), vec3y(0.8));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y -= 0.5 * h + thickness1 + 2.0 * thickness2;

    float d = sdCircle(pos1.xz, r + 0.017 * sin(3.0 + 18.5 * pos1.y));
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos1.y + 0.5 * (1.0 - f) * h, f * h)));

    d *= 0.9; // approximation

    return vec3(d, MATERIAL_JUICE, 0.0);
}

vec2 sdJarGlass(vec3 pos)
{
    // body
    const float r1 = 0.075;
    const float h1 = 0.3;
    const float thickness1 = 0.005;
    const float base = 0.02;
    // base
    const float thickness2 = 0.01;
    // spout
    const float h3 = 0.06;
    const float w3 = 0.05;
    const float depth3 = 0.01;
    // handle
    const float r4 = 0.08;

    float bounds = sdBoxApprox(pos, vec3(1.9 * r1, 0.6 * h1, 1.3 * r1), vec3(0.3, 0.8, 0.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, MATERIAL_GLASS1);
    }

    vec3 pos1 = pos;

    pos1.y -= thickness1 + 2.0 * thickness2;

    // base
    float d1 = sdCircle(pos1.xz, r1);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, pos1.y + thickness1)) - 2.0 * thickness2;
    vec2 d = vec2(d1, MATERIAL_GLASS1);

    // body
    pos1.y -= 0.5 * h1;
    float spout = pos1.x < 0.0 ? depth3 * smoothstep(w3, 0.0, abs(pos1.z)) * smoothstep(-h1, 0.0, pos1.y - 0.5 * h1) : 0.0;
    d1 = sdCircle(pos1.xz, r1 + thickness1 + 0.017 * sin(3.0 + 18.5 * pos1.y) + spout);
    float d2 = d1;

    float m = d1 > 0.0 ? MATERIAL_GLASS1 : MATERIAL_GLASS2; // add outline beween inner and outer surfaces
    d1 = length(vec2(d1, stretchAxis(pos1.y, h1)));
    d1 -= thickness1;
    d1 *= 0.8; // approximation
    d = minx(d, vec2(d1, m));

    // handle
    d2 = max(0.0, -d2);
    d2 = length(vec2(d2, stretchAxis(pos1.y, h1)));
    pos1.x -= 0.04;
    pos1.y -= 0.04;
    d1 = sdCircle(pos1.xy, r4 * (1.0 + 0.5 * smoothstep(-1.0, 1.0, (pos1.x - pos1.y) / r4)));
    d1 = length(vec2(d1, stretchAxis(pos1.z, 0.01))) - 0.01;
    d1 = max(d1, d2);
    d = minx(d, vec2(d1, MATERIAL_GLASS2));

    return d;
}

vec3 sdGlassCupJuice(vec3 pos, float fill)
{
    const float r1 = 0.04;
    const float r2 = 0.05;
    const float h1 = 0.12;
    const float thickness1 = 0.002;

    // base
    const float thickness2 = 0.01;

    float bounds = sdBoxApprox(pos, 1.3 * vec3(r2, 0.5 * h1, r2), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y -= thickness2;

    float d2 = sdCircle(pos1.xz, r1 + (r2 - r1) * smoothstep(0.0, h1, pos1.y) - thickness1);
    d2 = max(0.0, d2);
    d2 = length(vec2(d2, stretchAxis(pos1.y - 0.5 * fill * h1, fill * h1)));
    d2 *= 0.9; // approximation

    return vec3(d2, MATERIAL_JUICE, 0.0);
}

vec2 sdGlassCup(vec3 pos)
{
    const float r1 = 0.04;
    const float r2 = 0.05;
    const float h1 = 0.12;
    const float thickness1 = 0.002;

    // base
    const float thickness2 = 0.01;

    float bounds = sdBoxApprox(pos, 1.3 * vec3(r2, 0.5 * h1, r2), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, MATERIAL_GLASS3);
    }

    vec3 pos1 = pos;
    pos1.y -= thickness2;
    float d1 = sdCircle(pos1.xz, r1 - thickness2 + thickness1);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, pos1.y));
    d1 -= thickness2;
    vec2 d = vec2(d1, MATERIAL_GLASS3);

    d1 = sdCircle(pos1.xz, r1 + (r2 - r1) * smoothstep(0.0, h1, pos1.y));
    float m = d1 > 0.0 ? MATERIAL_GLASS3 : MATERIAL_GLASS4;
    d1 = length(vec2(d1, stretchAxis(pos1.y - 0.5 * h1, h1)));
    d1 -= thickness1;
    d = minx(d, vec2(d1, m));

    return d;
}

vec3 sdCake(vec3 pos)
{
    // cake
    const float r1 = 0.13;
    const float h1 = 0.06;

    // frosting
    const float h2 = 0.02;
    const float bevel2 = 0.005;

    // plate
    const float r3 = 0.1;
    const float curve3 = 0.3;
    const float thickness3 = 0.002;

    float bounds = sdBoxApprox(pos, vec3(r3, 0.5 * (h1 + h2), r3), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // cake
    vec3 pos1 = pos;
    pos1.y -= 0.5 * h1 + 0.02 * curve3;
    pos1.z -= 0.5 * r1;
    pos1.x = abs(pos1.x);
    pos1.xz *= rotation_15;
    pos1.xz *= rotation_7_5;
    float d1 = sdCircle(pos1.xz, r1);
    float d2 = d1;
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos1.y, h1)));
    d1 = max(d1, pos1.x);
    vec3 d = vec3(d1, MATERIAL_CAKE1, 0.0);

    // frosting
    pos1.y -= 0.5 * h1;
    d1 = d2;
    d1 = max(0.0, d1);
    float drop = pos1.y < 0.0 ? 0.5 * (2.0 + cos(200.0 * pos.x) + cos(200.0 * pos.z)) : 0.0;
    d1 = length(vec2(d1, stretchAxis(pos1.y, h2 * (0.1 + 0.9 * drop))));
    d1 = max(d1, pos1.x + 0.8 * bevel2);
    d1 -= bevel2;
    d = minx(d, vec3(d1, MATERIAL_CAKE2, 0.0));

    // plate
    pos1 = pos;
    pos1.y -= curve3 - thickness3;
    d1 = sdSphere(pos1, curve3);
    d1 = abs(d1) - thickness3;
    d1 = max(d1, pos1.y);
    d2 = sdCircle(pos1.xz, r3);
    d2 = max(0.0, d2);
    d1 = max(d1, d2);
    d1 = max(d1, -pos1.y - curve3 + thickness3);

    d = minx(d, vec3(d1, MATERIAL_PORCELIN, 0.0));

    return d;
}

vec3 sdPorchTableAndChairs(vec3 pos)
{
    float bounds = sdBoxApprox(pos, vec3(0.8, 0.5, 0.8), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // table
    vec3 pos1 = pos;
    pos1.xz *= rotation_n15;
    vec3 d1 = sdPorchTable(pos1);

    // chairs
    pos1 = pos;
    pos1.xz *= rotation_n60;
    pos1.xz = pos1.x < pos1.z ? pos1.xz : pos1.zx; // mirror 90 degrees
    pos1 -= vec3(-0.1, 0.0, 0.6);
    pos1.xz *= rotation_7_5;
    vec3 d2 = sdPorchChair(pos1);
    d1 = minx(d1, d2);

#ifdef RENDER_CAKE
    // jar
    pos1 = pos;
    pos1 -= vec3(-0.2, 0.7, -0.2);
    pos1.xz *= rotation_180;
    pos1.xz *= rotation_n10;
    d2 = sdJarJuice(pos1);
    d1 = minx(d1, d2);

    // cups
    pos1 = pos;
    pos1.xz *= rotation_n90;
    pos1.xz *= rotation_n7_5;
    float fill = pos1.x > 0.0 ? 0.3 : 0.7;
    pos1.x = abs(pos1.x);
    pos1 -= vec3(0.25, 0.7, 0.2);
    d2 = sdGlassCupJuice(pos1, fill);
    d1 = minx(d1, d2);

    // cakes
    pos1 = pos;
    pos1 -= vec3(0.22, 0.7, -0.12);
    pos1.xz *= rotation_60;
    float index = sign(pos1.x);
    pos1.x = abs(pos1.x);
    pos1.x -= 0.32;
    pos1.xz = index > 0.0 ? (pos1.xz * rotation_60) : (pos1.xz * rotation_180);
    d2 = sdCake(pos1);
    d1 = minx(d1, d2);
#endif

    return d1;
}

vec3 sdPorchCeiling(vec3 pos, float gridSize)
{
    const float h1 = 0.25; // base layer 1
    const float w1 = 0.3;  // base layer 1
    const float thickness1 = 0.1; // base layer 1
    const float h2 = 0.15;  // base layer 2
    const float w2 = 0.4;  // base layer 2
    const float thickness2 = 0.1; // base layer 2
    const float bevel = 0.02;

    pos.z += 6.0 * gridSize;

    vec2 size = vec2(7.0, 5.5) * gridSize;
    float bounds = sdBoxApprox(pos, vec3(size.x + w2, (h1 + h2) * 0.5, size.y + w2), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d = vec3(MAX_DIST, 0.0, 0.0);

    // bottom section
    vec3 pos1 = pos;
    pos1.y -= 0.5 * h1;
    float d1 = sdRectangle(pos1.xz, size + w1 * 0.5 - bevel, vec2(w1));
    d1 = max(d1, -pos1.z - 2.0 * gridSize); // clip back size
    d1 = length(vec2(d1, stretchAxis(pos1.y, h1 - 2.0 * bevel)));
    d1 -= bevel;
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 1.0));

    // top section
    pos1.y -= 0.5 * (h1 + h2);
    d1 = sdRectangle(pos1.xz, size + 0.5 * w2 - bevel, vec2(w2));
    d1 = max(d1, -pos1.z - 2.0 * gridSize); // clip back size
    d1 = length(vec2(d1, stretchAxis(pos1.y, h2 - 2.0 * bevel)));
    d1 -= bevel;
    d = minx(d, vec3(d1, MATERIAL_PAINTED_WOOD, 2.0));

    return d;
}

vec3 sdPorchRoof(vec3 pos)
{
    const float thickness1 = 0.1; // base
    const float bevel = 0.02;
    const vec3 tileSize = vec3(0.5, 0.5, 0.03);

    pos -= vec3(0.0, 3.8, -1.9);
    vec2 size = vec2(8.0, 6.0);

    float bounds = sdBoxApprox(pos, vec3(4.0, 2.2, 2.1), vec3(0.0, -0.7, 0.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);

    // side tiles
    vec3 pos1 = pos;
    float index = sign(pos1.x);
    pos1.x = abs(pos1.x); // mirror side tiles

    pos1.zx *= rotation_90;
    pos1.yz *= rotation_n45;

    float columns = floor(0.5 * size.y / tileSize.x) + 2.0;
    float rows = floor(0.5 * size.x / tileSize.y) + 2.0;
    pos1.y -= 0.25;

    // base
    float d = sdBox(pos1, vec3(vec2(columns, rows) * tileSize.xy, thickness1) * 0.5, vec3(0.0, -1.0, -1.0), bevel);
    d1 = minx(d1, vec3(d, MATERIAL_PAINTED_WOOD, 1.0 + index));

    // tile
    d1 = minx(d1, sdTiles(pos1 - vec3z(tileSize.z), tileSize, vec2(columns, rows), index + 17.0));

    // clip
    pos1 = pos;
    pos1.yz *= rotation_60;
    d1.x = max(d1.x, pos1.y);

    // front tiles

    pos1 = pos;
    pos1.yz *= rotation_n30;

    columns = floor(0.5 * size.x / tileSize.x) + 5.0;
    rows = floor(0.5 * size.y / tileSize.y) + 2.0;
    pos1.y -= 0.1;

    // base
    d = sdBox(pos1, vec3(vec2(columns, rows) * tileSize.xy, thickness1) * 0.5, vec3(0.0, -1.0, -1.0), bevel);
    vec3 d2 = vec3(d, MATERIAL_PAINTED_WOOD, 1.0 + index);

    // tile
    d2 = minx(d2, sdTiles(pos1 - vec3z(tileSize.z), tileSize, vec2(columns, rows), 0.0));

    // clip
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1.xy *= rotation_n45;
    d2.x = max(d2.x, pos1.y);

    d1 = minx(d1, d2);

    return d1;
}

vec3 sdFlower(vec3 pos, float h1)
{
    // petals
    const float height1 = 0.06;
    const float curve1 = -0.5;
    const float thickness1 = 0.03;
    const float taper1 = 0.5;

    // anther
    const float height2 = 0.06;
    const float curve2 = 0.6;
    const float thickness2 = 0.004;
    const float taper2 = 0.4;

    // stem
    const float size3 = 0.2;
    const float thickness3 = 0.005;

    // leaves
    const float size4 = 0.15;
    const float thickness4 = 0.005;
    const float width4 = 0.05;
    const float crease4 = 0.004;

    const vec2 gridSize = vec2(1.3);
    vec2 index2 = floor(pos.xz / gridSize + 0.5);

    float bounds = sdBoxApprox(pos, vec3(0.15, 0.2, 0.15), vec3y(-0.5));
    if (bounds > 0.1)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos.xz *= rotation(hash(index2) * PI);
    pos.x += 0.08;

    // petals
    vec3 pos1 = pos;
    pos1.xy *= rotation_45;

    vec3 pos2 = pos1;
    float index = 0.0;
    pos2.xz = radialMod(pos2.xz, 7.0, index);
    pos2.x -= 0.02;
    pos2.y += 0.02;

    vec3 pos3 = pos2;
    pos3.xy *= rotation_n45;
    float d1 = sdArc(pos3, height1, curve1, thickness1, taper1);
    vec3 d = vec3(d1, MATERIAL_FLOWER1, h1);

    // anthers
    pos3 = pos2;
    pos3.xy -= vec2(0.01, 0.065);
    pos3.xy *= rotation_n30;
    pos3.y = -pos3.y;
    d1 = sdArc(pos3, height2, curve2, thickness2, taper2);
    d = minx(d, vec3(d1, MATERIAL_FLOWER2, h1));

    // stem
    pos2 = pos1;
    pos2.y += height1;
    pos2.x += size3;

    d1 = sdCircle(pos2.xy, size3);
    d1 = length(vec2(d1, pos2.z));
    d1 = max(d1, -pos2.x);
    d1 = max(d1, pos2.y);
    d1 -= thickness3;

    d = smin(d, vec3(d1, MATERIAL_STEM, 0.0), 0.04);

    // leaves
    pos2 = pos;
    pos2.xy += size3 * vec2(-0.5, 0.7);
    pos2.y += size4;

    pos2.xz = radialMod(pos2.xz, 3.0, index);
    pos2.x -= 0.9 * size4;
    pos2.y -= crease4 * sqrt(clamp(abs(pos2.z) / 0.05, 0.0, 1.0));
    float width = width4 * pow(smoothstep(0.0, -0.9 * size4, pos2.x), 0.4);
    float thickness = 0.001 + thickness4 * smoothstep(0.0, -size4, pos2.x);
    d1 = sdCircle(pos2.xy, size4);
    d1 = length(vec2(d1, stretchAxis(pos2.z, width)));
    d1 = max(d1, pos2.x);
    d1 = max(d1, -pos2.y + 0.4 * size4);
    d1 -= thickness;

    d = minx(d, vec3(d1, MATERIAL_STEM, 0.0));

    return d;
}

vec3 sdPorchFlowers(vec3 pos, float seed, float time)
{
    const vec2 gridSize = vec2(0.3, 0.2);
    const float r = 0.6;
    const float seed1 = 1.0;

    pos.y -= 0.35;

    float bounds = sdBoxApprox(pos, vec3(0.9, 0.2, 0.4), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);

    vec3 pos1 = pos;
    pos1 += vec3(0.67, -0.02, 0.27);

    pos1.xz += pos1.y * 0.05 * vec2(sin(1.5 * pos1.x + time), sin(2.0 * pos1.z + 1.2 * time));

    float s = 1.0;
    for (int i = 0; i < 3; i++)
    {
        vec3 pos2 = pos1;
        vec2 index = floor(pos2.xz / gridSize);
        index = clamp(index, vec2(0.0), vec2(3.0, 1.0));
        pos2.xz -= gridSize * (index + 0.5);

        float h1 = hash(index + 10.0 * seed + 100.0 * float(i) + seed1);
        float h2 = hash(index + 10.0 * seed + 100.0 * float(i) + seed1 + 1000.0);
        pos2.xz *= rotation(h1 * PI2);

        float s = 1.0 - 0.4 * h1;
        pos2.y -= 0.3 * s;
        pos2 /= s;
        vec3 d2 = sdFlower(pos2, h2);
        d2.x *= s;
        d1 = minx(d1, d2);

        pos1.xz -= 0.08;
    }

    return d1;
}

vec3 sdPorchFlowerPot(vec3 pos, float seed)
{
    const vec3 size = vec3(0.7, 0.2, 0.3);
    const float thickness = 0.05;
    const float bevel = 0.01;

    // bricks
    const float w = (size.x + size.z) / 20.0;
    const float h = size.y / 1.5;

    float bounds = sdBoxApprox(pos, size, vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos.y -= size.y;

    vec2 p = pos.xz;
    float d1 = sdRectangle(p, size.xz - thickness);
    float d2 = d1;
    d1 = abs(d1) - thickness + bevel;
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos.y, 2.0 * (size.y - bevel))));
    d1 -= bevel;

    // uv.x clockwise mapping
    float x = abs(pos.z) < abs(pos.x) - size.x + size.z ? // quater
        (pos.x < 0.0 ? (3.0 * size.z - pos.z + 2.0 * size.x) : (size.z + pos.z)) : // z-axis mapping
        (pos.z < 0.0 ? (3.0 * size.x + pos.x + 4.0 * size.z) : (size.x - pos.x + 2.0 * size.z)); // x-axis mapping
    x /= 4.0 * (size.x + size.z);

    float row = pos.y / h + 0.5;
    row = min(row, 1.99);
    float h1 = hash(seed + floor(row));
    float column = x / w + h1;
    float h2 = hash(seed + vec2(floor(row), floor(column)));
    float h3 = hash(seed + 10.0 + vec2(floor(row), floor(column)));

    d1 -= h3 * 0.01;
    float edge = floor(h2 * 3.0);
    vec3 d = vec3(d1, MATERIAL_BRICK + 0.6 * h2 + 0.4 * (1.0 - fract(row)), edge);

    d2 = max(0.0, d2);
    float bump = sin(5.0 * seed + 15.0 * pos.x + 12.0 * pos.z) + sin(10.0 * seed + 25.0 * pos.x - 12.0 * pos.z);
    d2 = length(vec2(d2, stretchAxis(pos.y - 0.1 + 0.01 * bump, 0.1)));
    d = minx(d, vec3(d2, MATERIAL_SOIL, 0.0));

    return d;
}

vec3 sdYardFlowerPot(vec3 pos, float seed, float time)
{
    // pot
    const vec3 size1 = vec3(0.2, 0.1, 0.08); // brick size
    const vec3 offset1 = vec3(0.05, 0.0, 0.005);
    const float bevel1 = 0.015;
    const float rows1 = 4.0;
    const float columns1 = 20.0;
    const float seed1 = 0.0;

    // flowers
    const vec2 gridSize2 = vec2(0.22);
    const float r2 = 2.0;
    const float seed2 = 0.0;

    float bounds = sdBoxApprox(pos, vec3(0.8, 0.4, 0.8), vec3y(0.8));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y += size1.y;
    vec3 d1 = sdRoundBricks(pos1, size1, offset1, bevel1, rows1, columns1, seed1, MATERIAL_BRICK, 1.0);

    pos1 = pos;
    pos1 += vec3(0.07, -0.2, 0.19);

    pos1.xz += pos1.y * 0.05 * vec2(sin(1.5 * pos1.x + time), sin(2.0 * pos1.z + 1.2 * time));

    float s = 1.0;
    for (int i = 0; i < 3; i++)
    {
        vec3 pos2 = pos1;
        vec2 index = floor(pos2.xz / gridSize2);

        float an = atan(index.y, index.x);
        index = round(min(length(index), r2) * vec2(cos(an), sin(an)));

        pos2.xz -= gridSize2 * (index + 0.5);

        float h1 = hash(index + 10.0 * seed + 100.0 * float(i) + seed2);
        float h2 = hash(index + 10.0 * seed + 100.0 * float(i) + seed2 + 1000.0);
        pos2.xz *= rotation(h1 * PI2);

        float s = 1.0 - 0.4 * h1;
        pos2.y -= 0.3 * s;
        pos2 /= s;
        vec3 d2 = sdFlower(pos2, h2);
        d2.x *= s;
        d1 = minx(d1, d2);

        pos1.xz -= 0.05;
        pos1.xz *= rotation_30;
    }

    pos1 = pos;
    pos1.y -= (rows1 - 1.8) * size1.y;

    float bump = sin(5.0 * seed + 15.0 * pos.x + 12.0 * pos.z) + sin(10.0 * seed + 25.0 * pos.x - 12.0 * pos.z);
    float d = pos1.y - 0.01 * bump;
    d = max(d, length(pos1.xz) - columns1 * size1.x / PI2);

    vec3 d2 = vec3(d, MATERIAL_SOIL, 0.0);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdPorch(vec3 pos, float time)
{
    const float gridSize = 0.45;
    const vec3 pos0 = vec3(-0.5, 0.2, -2.6); // yard flowers

    vec3 d1, d2;
    vec3 pos1, pos2, pos3;
    vec2 index;
    float gridSize1, style;

    float bounds = sdBoxApprox(pos, vec3(7.5 * gridSize + 0.5, 3.5, 5.5 * gridSize + 2.0), vec3(0.0, 1.0, -0.8));
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1 += vec3(-2.0, 0.0, -0.3) + pos0;
    bounds = min(bounds, sdBoxApprox(pos1, vec3(0.8, 0.3, 0.8), vec3y1));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    d1 = vec3(MAX_DIST, MATERIAL_PAINTED_WOOD, 0.0);

    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1 += vec3(0.0, -0.6, 5.5 * gridSize);

    // fence posts
    pos2 = pos1;
    pos2.z += gridSize;
    pos2.y -= 0.25;
    index = floor(pos2.xz / gridSize + 0.5);
    index = clamp(index, vec2(0.0), vec2(7.0, 6.0));
    pos2.xz -= index * gridSize;
    d2 = sdPost(pos2, vec2(0.1, 0.25));
    d1 = minx(d1, d2);

    // remove fence post at the opening
    pos2 = pos1;
    pos2.z -= gridSize * 5.0;
    pos2.y -= 0.25;
    d1.x = max(d1.x, -sdBoxApprox(pos2, vec3(gridSize * 1.5, 0.5, gridSize * 0.5)));

    // support posts
    pos2 = pos1;
    pos2.x -= gridSize * 2.0;
    gridSize1 = gridSize * 5.0;
    index = floor(pos2.xz / gridSize1 + 0.5);
    index = clamp(index, vec2(0.0), vec2(1.0));
    pos2.xz -= index * gridSize1;
    pos2.y -= 1.1;
    d2 = sdPost(pos2, vec2(0.12, 0.5));
    d1 = minx(d1, d2);
    d2 = sdPostCap(pos2 - vec3y(0.48), 0.12);
    d1 = minx(d1, d2);

    // poles supports
    pos3 = pos2;
    pos3.y -= 1.3;
    style = index.x > 0.0 && index.y > 0.0 ? 2.0 : 1.0;
    pos3.xz = index.y <= 0.0 ? pos3.xz * rotation_90 : pos3.xz;
    d2 = sdPoleSupport(pos3, 0.12, style);
    d1 = minx(d1, d2);

    // remove fence posts below support posts
    pos2.y += 0.9;
    d1.x = max(d1.x, -sdBoxApprox(pos2, vec3(0.2, 0.3, 0.2)));

    // post base
    pos2.y -= 1.0;
    pos2.y = abs(pos2.y); // mirror
    pos2.y -= 0.95;
    style = index.x > 0.0 && index.y > 0.0 ? 2.0 : 1.0;
    pos2.xz = index.y <= 0.0 ? pos2.xz * rotation_90 : pos2.xz;
    d2 = sdPostBase(pos2, vec2(0.12, 0.25), style);
    d1 = minx(d1, d2);

    // remove fence posts
    pos2 = pos1;
    pos2 -= vec3(-gridSize * 0.5, 0.5, 0.0);
    d1.x = max(d1.x, -sdBoxApprox(pos2, vec3(gridSize * 7.0, 2.0, gridSize * 4.5)));

    // rails
    pos2 = pos1;
    pos2.xz -= gridSize * vec2(7.0, 3.5);
    pos2.y -= 0.55;
    d2 = vec3(sdFenceRails(pos2, gridSize), MATERIAL_PAINTED_WOOD, 0.0);
    d1 = minx(d1, d2);

    // floor
    d2 = sdPorchFloor(pos, gridSize);
    d1 = minx(d1, d2);

    // stairs
    d2 = sdPorchStairs(pos, gridSize);
    d1 = minx(d1, d2);

    // table and chairs
    pos1 = pos;
    pos1 -= vec3(2.0, 0.6, -1.3);
    d2 = sdPorchTableAndChairs(pos1);
    d1 = minx(d1, d2);

    // ceiling
    pos1 = pos;
    pos1.y -= 3.0;
    d2 = sdPorchCeiling(pos1, gridSize);
    d1 = minx(d1, d2);

    // roof
    d2 = sdPorchRoof(pos1);
    d1 = minx(d1, d2);

    // flower pots
    pos1 = pos;
    pos1.z -= 0.3;
    float seed = sign(pos1.x);
    pos1.x = abs(pos1.x);
    pos1.x -= gridSize * 4.5;
    d2 = sdPorchFlowerPot(pos1, seed);
    d1 = minx(d1, d2);

    d2 = sdPorchFlowers(pos1, seed, time);
    d1 = minx(d1, d2);

    pos1 += pos0;
    d2 = sdYardFlowerPot(pos1, seed, time);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdEntrancePediment(vec3 pos)
{
    const float w1 = 0.9; // width
    const float depth = 0.05;
    const float n = 3.0;
    const float bevel = 0.02;

    float bounds = sdBoxApprox(pos, vec3(w1, w1 * 0.5, depth) + bevel, vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d, pos1, pos2;

    float w = w1 / n;

    pos1 = pos;
    pos1.z += depth;
    float index = floor(pos1.x / w);
    index = clamp(index, -n - 1.0, n);
    pos1.x -= (index + 0.5) * w;

    float d1 = abs(pos1.x) - 0.5 * w + bevel; // vertical line
    d1 = max(0.0, d1); // fill shape
    d1 = length(vec2(d1, stretchAxis(pos1.z, 2.0 * (depth - bevel))));
    d1 -= bevel;

    pos1 = pos;
    pos1.x = abs(pos1.x);
    d1 = max(d1, -pos1.y); // clip bottom side

    pos1.xy *= rotation_45;
    pos1.x -= w1 * 0.7071067;

    d1 = max(d1, pos1.x); // clip diagonal side

    return vec3(d1, MATERIAL_PAINTED_WOOD, mod(index, 2.0) + 1.0);
}

vec3 sdEntrancePedimentDecoration(vec3 pos)
{
    const float s1 = 0.08; // center part radius
    const float t1 = 0.1; // center part thickness
    const float h1 = 0.25; // top part height
    const float s2 = 0.15; // base radius
    const float h2 = 0.1; // base height

    float bounds = sdBoxApprox(pos, vec3(0.4, 0.45, 0.2), vec3y(-0.2));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d1, d2, d3;

    vec3 pos1 = pos;

    d1 = MAX_DIST;
    pos1 = pos;
    pos1.y += h1;

    // center part
    vec2 p1 = vec2(length(pos1.xz), pos1.y);
    vec2 p2 = p1;

    p2.x -= t1 * s1;
    d1 = p2.x - s1 * pow(smoothstep(2.5 * h1, 0.0, p2.y), 0.7);
    d1 = max(d1, p2.y - 2.0 * h1);
    d1 = max(d1, -p2.y);

    p2 = p1;
    p2.y -= 1.985 * h1;
    d2 = length(p2) - s1 * 0.3088;
    d2 = max(d2, -p2.y + s1 * 0.045);
    d1 = min(d1, d2);

    d2 = min(d1, length(p1) - (1.0 + t1) * s1);
    d1 = min(d1, d2);

    // base
    pos1 = pos;
    pos1.y += 2.0 * h1 - 0.8 * h2;
    d2 = sdEllipsoid(pos1, vec3(s2, h2, s2));
    d1 = smin(d1, d2, 0.04);

    // wings
    vec3 pos2 = pos1;
    pos2.x = abs(pos2.x);
    pos2.x -= 0.85 * s2;
    pos2.y -= 0.1 * h2;

    vec3 pos3 = pos2;
    pos3.xy *= rotation_n60;
    d2 = sdArc(pos3, 0.4, -0.95, 0.085, 0.11);

    pos3 = pos2;
    pos3.x -= 0.029;
    pos3.y -= 0.348;
    pos3.xy *= rotation_30;
    d3 = sdArc(pos3, 0.2, 0.8, 0.04, 0.1);
    d2 = smin(d2, d3, 0.005);
    d1 = smin(d1, d2, 0.02);

    return vec3(d1, MATERIAL_PAINTED_WOOD, 0.0);
}

vec3 sdEntranceStairs(vec3 pos)
{
    const float w = 2.0; // steps width
    const float h = 0.2; // step height
    const float depth = 0.3; // step depth
    const float ext = 1.5; // last step depth

    vec3 d, d1, d2;

    vec3 pos1 = pos;

    pos1 += vec3(0.0, -h * 3.0, ext + depth * 3.0) * 0.5;
    d = abs(pos1) - vec3(w, h * 3.0, depth * 3.0 + ext) * 0.5;
    d1 = maxx(maxx(vec3(d.x, 0.0, 1.0), vec3(d.y, 0.0, 2.0)), vec3(d.z, 0.0, 3.0)); // cube with edge index

    if (d1.x > BOUNDS_MARGIN)
    {
        return d1;
    }

    pos1 -= vec3(0.0, h * 1.5, depth * 1.5 + ext * 0.5);
    d = abs(pos1) - vec3(w, h, depth * 2.0);
    d2 = maxx(maxx(vec3(d.x, 0.0, 1.0), vec3(d.y, 0.0, 2.0)), vec3(d.z, 0.0, 3.0)); // cube with edge index
    d2.x = -d2.x;
    d1 = maxx(d1, d2); // cut middle step

    pos1 -= vec3(0.0, -h, depth);
    d = abs(pos1) - vec3(w, h, depth * 2.0);
    d2 = maxx(maxx(vec3(d.x, 0.0, 1.0), vec3(d.y, 0.0, 2.0)), vec3(d.z, 0.0, 3.0)); // cube with edge index
    d2.x = -d2.x;
    d1 = maxx(d1, d2); // cut lower step

    d1.y = MATERIAL_PAINTED_WOOD;

    return d1;
}

float sdEntranceDoorBounds(vec3 pos)
{
    // half size
    const float w = 0.55;
    const float h = 1.1;
    const float depth = 0.5;

    pos.y -= h;

    float bounds = sdBoxApprox(pos, vec3(w, h, depth));
    if (bounds > BOUNDS_MARGIN)
    {
        return bounds;
    }

    float d = sdRoundedRectangle(pos.xy, vec2(w, h), vec4(w, 0.0, w, 0.0));
    d = max(0.0, d); // fill
    d = length(vec2(d, stretchAxis(pos.z, depth)));
    d -= 0.05;

    return d;
}

vec3 sdEntranceDoorHandle(vec3 pos)
{
    const vec3 size = vec3(0.038, 0.075, 0.03); // door handle base size
    const float r = 0.015; // door handle radius
    const float width = 0.18; // door handle length
    const float depth = 0.15; // door handle depth
    const float bevel = 0.005;

    float bounds = sdBoxApprox(pos, vec3(0.15), vec3x(0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 100.0, 0.0);
    }

    // handle base
    vec3 pos1 = pos;
    pos1.y += size.y * 0.5;
    float d1 = sdBox(pos1, size, vec3(0.0), bevel);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos.z, depth - 2.0 * bevel)));
    d1 -= bevel;
    vec3 d = vec3(d1, MATERIAL_METAL2, 7.0);

    // handle
    pos1 = pos;
    pos1 -= vec3(width * 0.5, 0.0, depth * 0.5);
    pos1.x += 0.5 * width;
    pos1.z = -pos1.z;
    pos1.xz = pos1.x > pos1.z ? pos1.xz : pos1.zx;
    d1 = length(pos1.xz - vec2(clamp(pos1.x, 0.0, width), 0.0));
    d1 = length(vec2(d1, pos1.y));
    d1 -= r;

    d = minx(d, vec3(d1, MATERIAL_METAL2, 8.0));
    return d;
}

vec3 sdEntranceDoor(vec3 pos)
{
    const float w = 0.55; // door width (half)
    const float h = 1.1; // door height (half)

    const float thickness1 = 0.06; // outer frame thickness
    const float depth1 = 0.2; // outer frame depth

    const float thickness2 = 0.07; // inner frame thickness (half)
    const float depth2 = 0.05; // inner frame depth

    const float thickness3 = 0.14; // diagonal bars thickness (half)
    const float offset3 = 0.04; // diagonal bars thickness (half)
    const float depth3 = 0.04; // inner frame depth

    const float bevel = 0.01;

    vec3 pos1 = pos;
    pos1.y -= h;

    float bounds = sdBoxApprox(pos1, vec3(w, h, 0.1) + thickness1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // outer frame
    float frameBounds = sdRoundedRectangle(pos1.xy, vec2(w, h), vec4(w, 0.0, w, 0.0));
    float d = frameBounds;
    d = abs(d - thickness1) - thickness1 + bevel;
    d = max(d, -pos1.y - h + bevel);
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos1.z, depth1 - bevel * 2.0)));
    d -= bevel;
    vec3 d1 = vec3(d, MATERIAL_PAINTED_WOOD, 0.0);

    // inner frame
    d = frameBounds;
    d = abs(d + thickness2) - thickness2 + bevel;
    d = max(d, -pos1.y - h + bevel);
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos1.z, depth2 - 2.0 * bevel + 0.001))); // depth
    d -= bevel;
    vec3 d2 = vec3(d, MATERIAL_WOOD3, 1.0);
    bool isVertical = pos1.y > -h + 2.0 * thickness2;
    d2.yz += (isVertical ? vec2(0.1, 0.01) : vec2(0.01, 0.1)) * pos1.xy + 0.5;
    d1 = minx(d1, d2);

    // vertical bar
    pos1 = pos;
    d = max(0.0, abs(pos1.x) - thickness2 + bevel); // bar
    d = max(d, abs(pos1.y - h) - h + thickness2 + bevel); // clip
    d = length(vec2(d, stretchAxis(pos1.z, depth2 - 2.0 * bevel))); // depth
    d -= bevel;
    d2 = vec3(d, MATERIAL_WOOD3, 1.0);
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * pos1.xy + 0.5); // uv
    d1 = minx(d1, d2);

    float offset = (2.0 * h - w - thickness2) / 4.0;
    // horizontal bars
    pos1 = pos;
    pos1.y -= 2.0 * h - w;
    pos1.y = abs(pos1.y + offset) - offset;
    d = max(0.0, abs(pos1.y) - thickness2 + bevel); // bar
    d = max(d, abs(pos1.x) - w + thickness2 + bevel); // clip
    d = length(vec2(d, stretchAxis(pos1.z, depth2 - 2.0 * bevel))); // depth
    d -= bevel;
    d2 = vec3(d, MATERIAL_WOOD3, 1.0);
    d2.yz += 0.99 * fract(vec2(0.01, 0.1) * pos1.xy + 0.5); // uv
    d1 = minx(d1, d2);

    // diagonal bars
    pos1 = pos;
    pos1.y -= 2.0 * h - w;
    pos1.xy = abs(pos1.xy); // mirror
    pos1.y -= 2.0 * offset;
    pos1.xy = abs(pos1.xy); // mirror

    pos1.xy *= rotation_30;
    pos1.x += offset3;
    float index = floor(pos1.x / thickness3 + 0.5);
    pos1.x -= thickness3 * index; // repeat

    d = max(0.0, abs(pos1.x) - thickness3 * 0.5 + bevel); // bar
    d = length(vec2(d, stretchAxis(pos1.z, depth3 - bevel * 2.0))); // thickness
    d -= bevel;

    float d3 = frameBounds + thickness2 * 0.5;
    d3 = max(0.0, d3);
    d = max(d, d3); // clip

    d2 = vec3(d, MATERIAL_WOOD3, mod(index, 2.0) + 3.0);
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * pos1.xy + 0.5); // uv
    d1 = minx(d1, d2);

    // door handle
    pos1 = pos;
    pos1.z = abs(pos1.z);
    pos1.y -= h - 0.5 * (w - thickness2);
    pos1.x += w - thickness2;
    d2 = sdEntranceDoorHandle(pos1);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdEntranceRoof(vec3 pos)
{
    const vec3 tileSize = vec3(0.5, 0.5, 0.03);

    pos -= vec3(0.0, 3.95, -1.6);

    float bounds = sdBoxApprox(pos, vec3(1.3, 0.6, 1.3), vec3y(-0.8));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float index = sign(pos.x);
    pos.x = abs(pos.x);
    pos.xz *= rotation_n90;
    pos.yz *= rotation_n45;
    pos.y -= 0.08;

    vec3 d1 = vec3(sdBox(pos, vec3(1.0, 0.7, 0.04), vec3(0.0, -1.0, 0.0), 0.02), MATERIAL_PAINTED_WOOD, 0.0);
    pos.z -= 0.08;

    vec3 d2 = sdTiles(pos, tileSize, vec2(4.0, 3.0), index);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdEntrance(vec3 pos)
{
    const float w = 0.8; // width
    const vec3 tileSize = vec3(0.5, 0.5, 0.03);

    float bounds = sdBoxApprox(pos, vec3(1.2, 2.4, 1.4), vec3(0.0, 1.0, -1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1, d2, pos1, pos2;

    // steps
    d1 = sdEntranceStairs(pos);

    // bottom posts base
    pos1 = pos;
    pos1.x = abs(pos.x);
    pos1 -= vec3(w, 0.8, -0.8);
    d2 = sdPostBase(pos1, vec2(0.12, 0.2), 3.0);
    d1 = minx(d1, d2);

    // posts
    pos1.y -= 0.78;
    d2 = sdPost(pos1, vec2(0.12, 0.58));
    d2.z = 2.0;
    d1 = minx(d1, d2);

    // caps
    pos1.y -= 0.56;
    d2 = sdPostCap(pos1, 0.12);
    d1 = minx(d1, d2);

    // top posts base
    pos2 = pos1;
    pos2.y -= 0.57;
    d2 = sdPostBase(pos2, vec2(0.12, 0.22), 2.0);
    d1 = minx(d1, d2);
    pos2.y -= 0.22;

    // front arcs
    d2 = sdPoleSupport(pos2, 0.12, 2.0);
    d1 = minx(d1, d2);

    // back arcs
    pos2.z += 2.0 * w;
    pos2.xz *= rotation_n90;
    d2 = sdPoleSupport(pos2, 0.12, 0.0);
    d1 = minx(d1, d2);

    // roof base
    pos1 = pos;
    pos1 -= vec3(0.0, 2.95, -1.65);
    float d = sdRectangleFrame(pos1.xzy, vec3(1.85, 2.0, 0.05), vec2(0.2), 0.02);
    d1 = minx(d1, vec3(d, MATERIAL_PAINTED_WOOD, 0.0));

    // roof
    pos1 = pos;
    pos1 -= vec3(0.0, 2.98, -0.75);
    d2 = sdEntrancePediment(pos1);
    d1 = minx(d1, d2);

    pos1.y -= 1.52;
    pos1.z += 0.05;
    d2 = sdEntrancePedimentDecoration(pos1);
    d1 = minx(d1, d2);

    // tiles
    d2 = sdEntranceRoof(pos);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdFloor(vec3 pos, float thickness, float seed)
{
    const float r = 3.95; // radius
    const float w = 2.0; // floor tile width
    const float h = 0.4; // floor tile length
    const float columns = ceil(r / w + 1.0);
    const float rows = ceil(r / h);

    pos.y += 2.0 * thickness;

    float bounds = sdBoxApprox(pos, vec3(r, 2.0 * thickness, r));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    bounds = length(pos.xz) - r + 0.01;

    vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);

    // floor
    vec2 p = pos.xz;
    float row = p.y / h + 0.5;
    float h1 = hash(seed + floor(row));
    p.x -= h1 * w; // column offset
    float column = p.x / w + 0.5;
    row = clamp(row, -rows, rows);
    column = clamp(column, -columns, columns);

    p.x -= floor(column) * w;
    p.y -= floor(row) * h;

    float h2 = hash(seed + vec2(floor(row), floor(column)));
    float d = sdRectangleApprox(p, vec2(w, h) * 0.5); // floor tile
    d = max(0.0, d); // fill shape
    d = max(d, abs(pos.y - thickness) - thickness); // thickness
    d = max(d, bounds); // clip
    float edge = mod((h2 + h1) * 10.0, 4.0);
    d1 = vec3(d, MATERIAL_WOOD3, edge);
    d1.yz += 0.99 * fract(vec2(0.01, 0.1) * pos.xz + 0.5 + 0.1 * h1);

    // ceiling
    p = pos.xz;
    d = sdRectangleApprox(p, vec2(r));
    d = max(0.0, d); // file shape
    d = max(d, abs(pos.y + thickness) - thickness); // thickness
    d = max(d, bounds); // clip
    vec3 d2 = vec3(d, MATERIAL_PAINTED_WOOD, 0.0);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdFloors(vec3 pos)
{
    const float h = 14.0 / 3.0; // height
    const float thickness = 0.2; // thickness (half)

    float bounds = sdBoxApprox(pos, vec3(4.0, 10.0, 4.0), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos.y -= 0.6;
    float index = floor(pos.y / h + 0.5);
    index = clamp(index, 0.0, 3.0);

    float offset = index > 2.0 ? 0.04 : 0.0;
    pos.y += offset;
    pos.y -= index * h;

    return sdFloor(pos, thickness + offset, floor(index) * 10.0);
}

vec3 sdWoodShadePile(vec3 pos, float r1, float r2, float depth1, float depth2, vec2 gridSize, vec2 count, float offset1, float offset2)
{
    const float bevel = 0.001;
    const float curve = 0.06;

    float bounds = sdBoxApprox(pos, vec3(1.0, 0.7, 0.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 p = pos.xy;

    p += 0.5 * count * gridSize; // center

    vec2 index, p1;
    float h1, h2, r, d;

    offset1 *= 0.25;

    index = floor(p / gridSize + 0.5);
    index.x += offset2;
    index.y = round(min(index.y, count.y - curve * (count.x - index.x - offset1) * (count.x - index.x - offset1)));
    index = clamp(index, vec2(0.0), count);

    p1 = p - index * gridSize;
    h1 = hash(index + 2.0);
    h2 = hash(index + 102.0);
    r = r1 - h1 * r2; // radius variance
    p1 += (vec2(h1, h2) - 0.5) * 0.01; // position offset
    d = length(p1) - r + bevel; // circle
    d = max(0.0, d); // fill shape;
    d = min(d, gridSize.x); // cell bounds
    d = length(vec2(d, stretchAxis(pos.z - 0.8 * h2 * depth2, depth1 + h2 * depth2))); // convert to 3d length
    d -= bevel;

    float edge = 1.0 + mod(index.x, 2.0) + 2.0 * mod(index.y, 2.0);
    vec3 d1 = vec3(d, MATERIAL_WOOD4, edge);
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.y, pos.z) + 0.1 * index + h1); // uv

    return d1;
}

vec3 sdWoodShadePile(vec3 pos, vec2 count)
{
    const float r1 = 0.06;
    const float r2 = 0.01; // radius variance
    const float depth1 = 0.7;
    const float depth2 = 0.05; // depth variance
    const vec2 gridSize = vec2(0.12, 0.18);

    float bounds = sdBoxApprox(pos, vec3(0.5 * (count + 1.0) * gridSize, depth1 + depth2));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1, d2;

    d1 = sdWoodShadePile(pos, r1, r2, depth1, depth2, gridSize, count, 0.0, 0.0);

    d2 = sdWoodShadePile(pos, r1, r2, depth1, depth2, gridSize, count, 0.0, 1.0);
    d1 = minx(d1, d2);

    pos = vec3(pos.xy + 0.5 * gridSize, pos.z);
    d2 = sdWoodShadePile(pos, r1, r2, depth1, depth2, gridSize, count, 1.0, 0.0);
    d2.z += 3.0; // edge offset
    d1 = minx(d1, d2);

    d2 = sdWoodShadePile(pos, r1, r2, depth1, depth2, gridSize, count, 1.0, 1.0);
    d2.z += 3.0; // edge offset
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdWoodShadeSide(vec3 pos)
{
    const float r1 = 0.06;
    const float r2 = 0.01; // radius variance
    const float len1 = 0.8;
    const float len2 = 0.3; // length variance
    const float bevel = 0.01;
    const float w1 = 0.28; // gap
    const float w2 = 0.05; // gap variance

    float bounds = sdBoxApprox(pos + vec3z(w1), vec3(0.5 * len1, 0.5 * len1, 3.0 * w1), vec3(0.0, 1.0, 1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float index = floor(pos.z / w1 + 0.5);
    index = clamp(index, 0.0, 5.0);
    pos.z -= index * w1;

    float h1 = hash(index);
    float h2 = hash(index + 10.0);
    float h3 = hash(index + 20.0);

    pos.z += h1 * w2;
    pos.yz *= rotationApprox((h2 - 0.5) * 0.3);
    pos.xy *= rotation_n30;
    pos.x -= 0.5 * h3 * len2;
    pos.y += h3 * len2;

    vec2 p1 = pos.xz;
    float r = r1 - h3 * r2;
    float d = length(p1) - r + bevel; // circle
    d = max(0.0, d); // fill shape
    d = length(vec2(d, pos.y - clamp(pos.y, 0.0, len1)));
    d -= bevel;

    vec3 d1 = vec3(d, MATERIAL_WOOD4, 0.0);
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index + h1); // uv
    return d1;
}

vec3 sdWoodShadeWalls(vec3 pos)
{
    // lower panel (half)
    const float w1 = 0.1;
    const float h1 = 0.9;
    const float depth1 = 0.04;

    // separator (half)
    const float w2 = 0.05;
    const float h2 = w2;

    // upper panel (half)
    const float w3 = 0.05;
    const float h3 = 0.3;
    const float depth3 = 0.02;

    // corners (half)
    const float w4 = 0.1;

    // top support (half)
    const float w5 = 0.07;
    const float h5 = w5;

    const float bevel = 0.01;

    vec3 pos1, pos2, pos3;

    float bounds = sdBoxApprox(pos, vec3(1.3), vec3(0.0, 1.0, 1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos1 = pos;
    pos1.x = -abs(pos1.x);
    pos1.x += w1 * 12.0;
    pos1.xz = pos1.x < pos1.z ? pos1.zx : pos1.xz;

    // lower panels
    pos2 = pos1;
    float index = floor(pos2.x / (w1 * 2.0) + 0.5);
    index = min(index, 9.0);
    pos2.x -= index * w1 * 2.0;
    float d = sdBox(pos2, vec3(w1, h1, depth1), vec3y1, bevel);
    vec3 d1 = vec3(d, MATERIAL_WOOD3, 1.0 + mod(index, 2.0));
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index + 0.5); // uv

    // separators
    pos2 = pos1;
    pos2.y -= h1 * 2.0;
    d = sdBox(pos2, vec3(w1 * 20.0, h2, w2), vec3y1, bevel);
    vec3 d2 = vec3(d, MATERIAL_WOOD3, 3.0);
    d2.yz += 0.99 * fract(vec2(0.01, 0.1) * vec2(pos.x + pos.z, pos.y) + 0.5); // uv
    d1 = minx(d1, d2);

    // upper panels
    index = floor(pos2.x / (w1 * 4.0) + 0.5);
    index = min(index, 4.0);
    pos2.x -= index * w1 * 4.0;
    pos2.y -= h2 * 2.0;
    d = sdBox(pos2, vec3(w3, h3, depth3), vec3y1, bevel);
    d2 = vec3(d, MATERIAL_WOOD3, 4.0 + mod(index, 2.0));
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index + 0.5); // uv
    d1 = minx(d1, d2);

    // corners
    pos1 = pos;
    pos1.z -= w1 * 10.0;
    pos1.xz = abs(pos1.xz);
    pos1.z -= w1 * 10.0;
    pos1.x -= w1 * 12.0;
    d = sdBox(pos1, vec3(w4, h1 + h2 + h3 + h5, w4) + 0.001, vec3y1, bevel);
    d2 = vec3(d, MATERIAL_WOOD3, 6.0);
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.5); // uv
    d1 = minx(d1, d2);

    // top
    pos2 = pos1;
    pos2.xz = pos2.x < pos2.z ? pos2.zx : pos2.xz;
    pos2.y -= (h1 + h2 + h3) * 2.0;
    d = sdBox(pos2, vec3(w5, h5, w1 * 20.0), vec3y1, bevel);
    d2 = vec3(d, MATERIAL_WOOD3, 7.0);
    d2.yz += 0.99 * fract(vec2(0.01, 0.1) * vec2(pos.x + pos.z, pos.y) + 0.5); // uv
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdWoodShadeRoof(vec3 pos)
{
    // base (half)
    const float w1 = 0.05;
    const float h1 = 1.0;
    const float thickness1 = 0.1;

    // tiles
    const float w2 = 0.14;
    const float h2 = 1.15; // length
    const float thickness2 = 0.02;

    const float bevel = 0.01;

    pos.y -= 2.64;
    pos.z -= 1.0;

    float bounds = sdBoxApprox(pos, vec3(1.8, 1.0, 1.4), vec3y(0.4));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1.x -= 1.3;
    pos1.xy *= rotation_45;

    // bars
    vec3 pos2 = pos1;
    float index = sign(pos2.z);
    pos2.z = abs(pos2.z);
    pos2.z -= 1.0;
    float d = sdBox(pos2, vec3(w1, h1, thickness1), vec3(-1.0, 1.0, 0.0), bevel);
    d = max(d, -pos.y);
    vec3 d1 = vec3(d, MATERIAL_WOOD3, 1.0);
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos2.x + pos2.z, pos2.y) + 0.5); // uv

    // tiles base
    pos2 = pos1;
    pos2.y += thickness2;
    index = floor(pos2.z / (w2 * 2.0) + 0.5);
    index = clamp(index, -4.0, 4.0);
    pos2.z -= index * w2 * 2.0;
    pos2.y += h2 - h1;
    d = sdBox(pos2, vec3(thickness2, h2, w2), vec3(1.0, 1.0, 0.0), bevel);
    vec3 d2 = vec3(d, MATERIAL_WOOD3, 2.0 + mod(index, 2.0));
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos2.x + pos2.z, pos2.y) + 0.1 * index + 0.5); // uv
    d1 = minx(d1, d2);

    // tiles
    float seed = sign(pos.x) + 2.0;
    pos2 = pos1;
    pos2.xz *= rotation_n90;
    pos2.y -= 1.9;
    pos2.z -= 0.06;
    d2 = sdTiles(pos2, vec3(0.5, 0.4, 0.03), vec2(5.0, 6.0), seed);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdWoodShade(vec3 pos)
{
    const vec2 pileCount = vec2(11.0, 7.0);

    float bounds = sdBoxApprox(pos - vec3z1, vec3(1.8, 2.1, 1.4), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1 = sdWoodShadeWalls(pos);

    vec3 pos1 = pos;

    vec3 d2 = sdWoodShadeRoof(pos1);
    d1 = minx(d1, d2);

    pos1 = pos;
    pos1.x -= 0.15;
    pos1.z -= 1.5;
    pos1.xz = vec2(-pos1.z, pos1.x);
    bool leftPile = pos1.z < 0.0;
    pos1.y -= leftPile ? 0.6 : 0.8;
    pos1.z = abs(pos1.z);
    pos1.xz = leftPile ? pos1.zx : pos1.xz;
    pos1.x -= 0.7;
    pos1.z -= 0.6;
    pos1.z *= -1.0;
    d2 = sdWoodShadePile(pos1, leftPile ? pileCount - 2.0 : pileCount);
    d1 = minx(d1, d2);

    pos1 = pos;
    pos1.x += 1.68;
    pos1.z -= 0.4;
    d2 = sdWoodShadeSide(pos1);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdKitchenDoor(vec3 pos)
{
    // bars (half)
    const float w1 = 0.09;
    const float h1 = 1.0;
    const float thickness1 = 0.03;

    // frame
    const float w2 = 0.05;
    const float thickness2 = 0.15;

    // lintel
    const float h3 = 0.1;
    const float thickness3 = 0.2;

    // handle
    const float w5 = 0.04;
    const float h5 = 0.12;
    const float depth5 = 0.07;
    const float thickness5 = 0.015;

    float bevel5 = 0.01;

    const float bevel = 0.01;

    float bounds = sdBoxApprox(pos, vec3(w1 * 6.0 + 2.0 * w2, h1 + h3, thickness3) + 0.1, vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    float index = floor(pos1.x / (w1 * 2.0));
    index = clamp(index, -3.0, 2.0);
    pos1.x -= (index + 0.5) * w1 * 2.0;

    float d = sdBox(pos1, vec3(w1, h1, thickness1), vec3y1, bevel);

    vec3 d1 = vec3(d, MATERIAL_WOOD3, 1.0 + mod(index, 2.0));
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * pos.xy + 0.1 * index); // uv

    // frame
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1.x -= 6.0 * w1;
    d = sdBox(pos1, vec3(w2, h1, thickness2), vec3(1.0, 1.0, 0.0), bevel);
    vec3 d2 = vec3(d, MATERIAL_WOOD3, 1.0);
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y)); // uv
    d1 = minx(d1, d2);

    // lintel
    pos1 = pos;
    pos1.y -= h1 * 2.0;
    d = sdBox(pos1, vec3(6.0 * w1 + 2.0 * w2, h3, thickness3), vec3y1, bevel);
    d2 = vec3(d, MATERIAL_WOOD3, 2.0);
    d2.yz += 0.99 * fract(vec2(0.01, 0.1) * vec2(pos.x, pos.y + pos.z) + 0.5); // uv
    d1 = minx(d1, d2);

    // handle
    pos1 = pos;
    pos1.x -= w1 * 5.0;
    pos1.y -= 0.9;
    d = sdEllipse(pos1.yz, vec2(h5, depth5));
    d = abs(d) - thickness5 * 0.5 + bevel5;
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos1.x, w5 - 2.0 * bevel5)));
    d -= bevel5;
    d2 = vec3(d, MATERIAL_METAL2, 4.0);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdKitchenStairs(vec3 pos)
{
    const float w = 1.4; // steps width
    const float h = 0.3; // step height
    const float depth = 0.4; // bottom step depth
    const float ext = 1.0; // top step depth

    vec3 d, d1, d2;

    vec3 pos1 = pos;

    pos1 += vec3(0.0, -h * 2.0, ext + depth) * 0.5;
    d = abs(pos1) - vec3(w, h * 2.0, ext + depth) * 0.5;
    d1 = maxx(maxx(vec3(d.x, 0.0, 1.0), vec3(d.y, 0.0, 2.0)), vec3(d.z, 0.0, 3.0)); // cube with edge index

    if (d1.x > BOUNDS_MARGIN)
    {
        return d1;
    }

    pos1 = pos;
    pos1 += vec3(0.0, -h * 4.0, 0.0) * 0.5;
    d = abs(pos1) - vec3(w + 0.1, h * 2.0, depth * 2.0) * 0.5;
    d2 = maxx(maxx(vec3(d.x, 0.0, 1.0), vec3(d.y, 0.0, 2.0)), vec3(d.z, 0.0, 3.0)); // cube with edge index
    d2.x = -d2.x;
    d1 = maxx(d1, d2); // cut middle step

    d1.y = MATERIAL_BASE_ROCK;

    return d1;
}

vec3 sdBasementDoor(vec3 pos)
{
    // bars
    const float w1 = 0.1;
    const float h1 = 0.6;
    const float n1 = 2.0; // count
    const float thickness1 = 0.01;

    // frame
    const float w2 = 0.06;
    const float thickness2 = 0.11;
    const float bevel2 = 0.03;

    // lintel
    const float h3 = 0.08;
    const float thickness3 = 0.12;
    const float bevel3 = 0.03;

    // handle
    const float r4 = 0.08;
    const float thickness4 = 0.012;
    const float r5 = 0.05;

    pos.y -= h1;

    float bounds = sdBoxApprox(pos, vec3(n1 * w1 + 2.0 * w2, h1 + h3, 0.2) + 0.1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // door
    vec3 pos1 = pos;
    float index = floor(pos1.x / (2.0 * w1));
    index = clamp(index, -n1, n1 - 1.0);
    pos1.x -= (index * 2.0 + 1.0) * w1;
    float d = sdBox(pos1, vec3(w1, h1, thickness1));
    vec3 d1 = vec3(d, MATERIAL_WOOD3, 1.0 + mod(index, 2.0));
    d1.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index + 0.5); // uv

    // frame
    pos1 = pos;
    pos1.x = abs(pos1.x);
    pos1.x -= n1 * 2.0 * w1;
    d = sdBox(pos1, vec3(w2, h1 + h3, thickness2), vec3x1, bevel2);
    vec3 d2 = vec3(d, MATERIAL_WOOD3, 3.0);
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 + 0.5); // uv
    d1 = minx(d1, d2);

    // lintel
    pos1 = pos;
    pos1.y -= h1;
    d = sdBox(pos1, vec3(w1 * 2.0 * n1 + 2.0 * w2, h3, thickness3), vec3y1, bevel3);
    d2 = vec3(d, MATERIAL_WOOD3, 5.0);
    d2.yz += 0.99 * fract(vec2(0.01, 0.1) * vec2(pos.x, pos.y + pos.z) + 0.1 + 0.5); // uv
    d1 = minx(d1, d2);

    // handle
    pos1 = pos;
    pos1.x += (2.0 * n1 - 1.0) * w1;
    pos1.z -= thickness1 + thickness4;
    d = sdCircle(pos1.xy, r4 - thickness4);
    d = length(vec2(d, pos1.z));
    d -= thickness4;
    d2 = vec3(d, MATERIAL_METAL2, 1.0);
    d1 = minx(d1, d2);

    pos1 = pos;
    pos1.y -= r4;
    pos1.x += (2.0 * n1 - 1.0) * w1;
    pos1.z -= thickness1 - thickness4;
    d = sdCircle(pos1.yz, r5 - thickness4);
    d = length(vec2(d, pos1.x));
    d -= thickness4;
    d2 = vec3(d, MATERIAL_METAL2, 2.0);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdBasement(vec3 pos)
{
    // brick walls
    const vec3 size = vec3(1.2, 0.7, 1.3);
    const float s = 2.5; // scale
    const float bevel = 0.3;

    // roof tiles
    const float w1 = 0.2;
    const float n1 = 3.0; // (count - 1) / 2
    const float ext1 = 0.3; // extrude
    const float thickness1 = 0.03;
    const float bevel1 = 0.01;

    // roof base wood bars
    const float w2 = 0.15;
    const float ext2 = -0.1; // extrude
    const float n2 = 3.0;
    const float thickness2 = 0.02;

    pos.y -= size.y;

    float bounds = sdBoxApprox(pos, vec3(size.x + ext1, size.y * 2.8, size.z) + 0.1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float d = sdBox(pos + vec3y(0.2), size - bevel + vec3y(0.2));
    vec2 uv;
    uv.x = pos.z > 0.0 ? (size.x - pos.x) : (3.0 * size.x + pos.x);
    uv.x += size.z - pos.z;
    uv.x /= 4.0 * size.x + 2.0 * size.z;
    uv.y = (size.y + pos.y) / (2.0 * size.y);

    vec2 v = d < 0.35 ? voronoi(uv * s * vec2(6.0, 1.0)) : vec2(0.0);

    d -= bevel - 0.02 * v.x;

    vec3 d1 = vec3(d, MATERIAL_BASE_ROCK + 0.5 * v.x + 0.1 * v.y, 2.0);

    // roof
    vec3 pos1 = pos;
    pos1.x -= size.x + ext2;
    pos1.y -= 2.0 * size.y + 0.5 * (size.x + ext2);
    pos1.xy *= rotation_30;
    float index = floor(pos1.z / (2.0 * w1) + 0.5);
    index = clamp(index, -n1, n1);

    pos1.z -= index * 2.0 * w1;

    d = sdBox(pos1, vec3((size.x + 2.0 * ext2) / 0.866 + ext1, thickness1, w1), vec3(-1.0, 1.0, 0.0), bevel1);

    vec3 d2 = vec3(d, MATERIAL_WOOD3, 1.0 + mod(index, 2.0));
    d2.yz += 0.99 * fract(vec2(0.01, 0.1) * pos1.xz + 0.1 * index + 0.5); // uv
    d1 = minx(d1, d2);

    // roof base
    pos1 = pos;
    pos1.y -= size.y - 0.2;
    index = floor(pos1.x / (2.0 * w2) + 0.5);
    index = clamp(index, -n2, n2);

    pos1.x -= index * 2.0 * w2;
    d = sdBox(pos1, vec3(w2, size.x * 0.7, size.z + ext2), vec3y1, bevel1);

    pos1 = pos;
    pos1.y -= size.y + 0.5 * size.x;
    pos1.xy *= rotation_30;
    d = max(d, pos1.y);

    d2 = vec3(d, MATERIAL_WOOD3, 3.0 + mod(index, 2.0));
    d2.yz += 0.99 * fract(vec2(0.1, 0.01) * vec2(pos.x + pos.z, pos.y) + 0.1 * index + 0.5); // uv
    d1 = minx(d1, d2);

    // door
    pos1 = pos;
    pos1.x += 0.35;
    pos1.z -= size.z + ext2;
    pos1.y += size.y;
    d1.x = max(d1.x, -sdBoxApprox(pos1 + vec3y(0.1), vec3(0.45, 0.7, 0.3), vec3y1));

    d2 = sdBasementDoor(pos1);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdWell(vec3 pos)
{
    // wall
    const vec3 size1 = vec3(0.4, 0.25, 0.3); // brick size
    const vec3 offset1 = vec3(0.05, 0.0, 0.01);
    const float bevel1 = 0.06;
    const float rows1 = 10.0;
    const float columns1 = 10.0;

    // support
    const vec3 size2 = vec3(0.18, 0.35, 0.18);
    const float bevel2 = 0.03;

    // rod
    const float curve3 = 3.0; // curve
    const float thickness3 = 0.1;
    const float width3 = 0.49;
    const float height3 = 0.05;

    // axis
    const float thickness4 = 0.015;
    const float length4 = 0.85;
    const float r4 = 0.15; // rotation radius
    const float skew4 = 0.05;
    const float offset4 = 0.03;

    // handle
    const float thickness5 = 0.025;
    const float length5 = 0.2;

    // bolts
    const float thickness6 = 0.01;
    const float offset6 = 0.1;

    // rope
    const float thickness7 = 0.02;
    const float count7 = 5.0;
    const float skew7 = 0.1;
    const float curve7 = 0.1;

    float bounds = sdBoxApprox(pos + vec3y(0.5), vec3(0.8, 1.7, 0.8));
    bounds = min(bounds, sdBoxApprox(pos + vec3(0.0, -0.7, -1.0), vec3(0.15, 0.15, 0.4)));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    // wall
    vec3 pos1 = pos;
    pos1.y += 2.0;
    pos1.xz *= rotation_15;
    vec3 d1 = sdRoundBricks(pos1, size1, offset1, bevel1, rows1, columns1, 0.0, MATERIAL_BASE_ROCK, 0.3);
    d1.y += 0.3; // material shade

    // support
    pos1 = pos;
    pos1.y -= 0.65;

    vec3 pos2 = pos1;
    pos2.z = abs(pos2.z);
    pos2.z -= 0.62;
    float d = sdRoundedRectangle(pos2.xy, size2.xy - bevel2, vec4(size2.x - bevel2, 0.0, size2.x - bevel2, 0.0));
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos2.z, size2.z - bevel2)));
    d -= bevel2;
    vec3 d2 = vec3(d, MATERIAL_WOOD4, 0.0);
    d2.yz += fract(vec2(0.1, 0.01) * vec2(pos2.x + pos2.z, pos2.y) + 0.5); // uv
    d1 = minx(d1, d2);

    // rod
    pos2 = pos1;
    pos2.y -= height3;

    vec3 pos3 = pos2;
    d = sdCircle(pos3.xy, curve3 + thickness3);
    d = length(vec2(d, pos3.z));
    d -= curve3;
    d = max(-d, sdCircle(pos3.xy, 2.0 * thickness3));
    d = max(d, abs(pos3.z) - width3);
    d2 = vec3(d, MATERIAL_WOOD4, 0.0);
    d2.yz += fract(vec2(0.1, 0.01) * vec2(pos3.x + pos3.y, pos3.z) + 0.5); // uv
    d1 = minx(d1, d2);

    // axis
    pos3 = pos2;
    pos3.z -= offset4;
    d = sdLine(pos3.zy, vec2(-length4, 0.0), vec2(length4, 0.0));
    d = min(d, sdLine(pos3.zy, vec2(length4, 0.0), vec2(length4 + skew4, -r4)));
    d = min(d, sdLine(pos3.zy, vec2(length4 + skew4, -r4), vec2(length4 + skew4 + 2.0 * thickness4 + thickness5 + 2.0 * length5, -r4)));
    d = length(vec2(d, pos3.x));
    d -= thickness4;
    d2 = vec3(d, MATERIAL_METAL3, 1.0);
    d1 = minx(d1, d2);

    // handle
    pos3 = pos2;
    pos3.z -= offset4 + length4 + skew4 + thickness4 + thickness5 + length5;
    pos3.y += r4;
    d = sdCircle(pos3.xy, thickness5);
    d = max(d, abs(pos3.z) - length5);
    d2 = vec3(d, MATERIAL_WOOD4, 0.0);
    d2.yz += fract(vec2(0.01, 0.1) * vec2(pos3.x + pos3.z, pos3.y) + 0.5); // uv
    d1 = minx(d1, d2);

    // bolts
    pos3 = pos2;
    pos3.z += length4 - offset6;
    d = sdCircle(pos3.xy, 3.0 * thickness4);
    d = max(d, abs(pos3.z) - thickness6);
    d2 = vec3(d, MATERIAL_METAL3, 2.0);
    d1 = minx(d1, d2);

    pos3.z += 2.5 * thickness6;
    d = sdCircle(pos3.xy, 2.5 * thickness4);
    d = max(d, abs(pos3.z) - thickness6);
    d2 = vec3(d, MATERIAL_METAL3, 3.0);
    d1 = minx(d1, d2);

    // rope loops
    pos3 = pos2;
    pos3.z -= skew7 * (pos3.x + pos3.y);
    float index = floor(pos3.z / (2.0 * thickness7) + 0.5);
    index = clamp(index, -count7, count7);
    pos3.z -= index * 2.0 * thickness7;
    d = sdCircle(pos3.xy, (0.9 + curve7 * pow2(index / count7)) * thickness3 + thickness7);
    d = length(vec2(d, pos3.z));
    d -= thickness7;
    d2 = vec3(d, MATERIAL_ROPE, 1.0 + mod(index, 2.0));
    d2.y += 0.99 * fract(sqrt(abs(sin(10.0 * atan(pos3.x, pos3.y) + 100.0 * pos3.z)))); // uv
    d1 = minx(d1, d2);

    // rope line
    pos3 = pos2;
    d = length(pos3.xz) - thickness7;
    d = max(d, pos3.y);
    d2 = vec3(d, MATERIAL_ROPE, 0.0);
    d2.y += 0.99 * fract(sqrt(abs(sin(100.0 * (pos3.x + pos3.y))))); // uv
    d1 = minx(d1, d2);

    return d1;
}

vec2 sdWellWater(vec3 pos, float time)
{
    const float height = 0.005; // ripple height
    const float count = 20.0; // ripples count

    pos -= WELL_POSITION;
    pos.y -= HILL_HEIGHT;

    pos.y += 0.75;

    float bounds = sdBoxApprox(pos, vec3(1.0, 0.1, 1.0));
    bounds = max(0.0, bounds);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, 0.0);
    }

    float r = length(pos.xz);
    pos.y += height * pow2(max(0.8 - r, 0.0)) * sin(count * r - time);
    float d = max(pos.y, bounds);

    return vec2(d, MATERIAL_WATER);
}

vec3 sdHouse(vec3 pos, float time)
{
    vec3 d1, d2, d3;
    vec3 pos1, pos2, pos3;

    float bounds = sdBoxApprox(pos, vec3(5.0, HOUSE_HEIGHT / 2.0 + 5.0, 5.0), vec3y1);
    bounds = min(bounds, sdBoxApprox(pos - vec3z(4.5), vec3(2.0, 2.5, 2.0), vec3(0.0, 1.0, 0.0))); // entrance
    bounds = min(bounds, sdBoxApprox(pos - vec3(4.5, 0.0, -0.4), vec3(2.6, 3.5, 3.7), vec3(0.0, 1.0, 0.0))); // porch
    bounds = min(bounds, sdBoxApprox(pos + vec3z(5.0), vec3(2.0, 2.0, 2.0), vec3(0.0, 1.0, 0.0))); // wood shade
    bounds = min(bounds, sdBoxApprox(pos + vec3x(4.5), vec3(2.0), vec3(0.0, 1.0, 0.0))); // basement
    bounds = min(bounds, sdBoxApprox(pos - WELL_POSITION + vec3y(2.0), vec3(1.1, 4.0, 1.1))); // well
    bounds = min(bounds, sdBoxApprox(pos - vec3(9.0, 0.0, -0.5), vec3(1.0, 0.4, 3.5))); // yard flowers
    if (bounds > BOUNDS_MARGIN_LARGE)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    d1 = vec3(MAX_DIST, 0.0, 0.0);
    vec2 p = vec2(length(pos.xz), pos.y);
    float wallsBounds = p.x - 3.92;

    // roof
    float roofBounds = sdRoofBounds(p - vec2y(HOUSE_HEIGHT - 0.2));
    roofBounds = min(roofBounds, pos.y - HOUSE_HEIGHT);

    pos1 = pos - vec3y(HOUSE_HEIGHT - 0.2);
    d1 = sdRoof(pos1);

    // lightning rod
    d2 = sdLightningRod(pos1 - vec3y(5.6));
    d1 = minx(d1, d2);

    pos2 = pos1 + vec3x(3.3);
    d2 = sdChimney(pos2);
    d1 = minx(d1, d2);

    d2 = sdChimneyTop(pos2 - vec3y(4.5));
    d1 = minx(d1, d2);

    // walls
    d2 = sdOuterWalls(pos);
    d1 = minx(d1, d2);

#ifdef RENDER_HOUSE_DETAILS
    // windows openings
    d1.x = max(d1.x, -sdWindowsBounds(pos));
    d2 = sdWindows(pos);
    d1 = minx(d1, d2);

    // Moomin room
    pos2 = pos1;
    pos2.xz *= rotation_n60;
    pos2 -= vec3(0.0, 1.3, 2.6);

    d1.x = max(d1.x, -sdMoominRoomBounds(pos2) - 0.05);

    d2 = sdMoominRoom(pos2);
    d2.x = max(d2.x, -roofBounds - 0.03);
    d1 = minx(d1, d2);

    d2 = sdMoomin(pos2 + vec3(0.0, 0.835, -0.8), state.origin - vec3(2.95, 25.15, 1.65), time);
    d1 = minx(d1, d2);

    // ladder
    d2 = sdRopeLadder(pos2);
    d1 = minx(d1, d2);

    // house base
    pos1 = pos;
    pos1.xz *= rotation_180;
    d2 = sdHouseBase(pos1);
    d1 = minx(d1, d2);

    // porch door
    pos1 = pos;
    pos1.xz *= rotation_n93;
    pos1.z -= 3.9;
    pos1.y -= 1.7;
    d1.x = max(d1.x, -sdPorchDoorBounds(pos1));
    d2 = sdPorchDoor(pos1 + vec3y(0.001));
    d1 = minx(d1, d2);

    // porch
    pos1 = pos;
    pos1.xz *= rotation_n93;
    pos1.z -= 6.2;
    d2 = sdPorch(pos1, time);
    d2.x = max(d2.x, -wallsBounds);
    d1 = minx(d1, d2);

    // entrance door
    pos1 = pos;
    pos1.z -= 6.22;
    pos1 -= vec3(0.0, 0.599, -2.3);
    d1.x = max(d1.x, -sdEntranceDoorBounds(pos1));
    d2 = sdEntranceDoor(pos1);
    d1 = minx(d1, d2);

    // entrance
    pos1 = pos;
    pos1.z -= 6.22;
    d2 = sdEntrance(pos1);
    d2.x = max(d2.x, -wallsBounds);
    d1 = minx(d1, d2);

    // wood shade
    pos1 = pos;
    pos1.xz *= rotation_180;
    pos1.z -= 4.5;
    d2 = sdWoodShade(pos1);
    d1 = minx(d1, d2);

    // kitchen door
    pos1 = pos;
    pos1.xz *= rotation_145;
    pos1.z -= 3.92;
    pos1.y -= 0.6;
    d1.x = max(d1.x, -sdBoxApprox(pos1, vec3(0.6, 1.0, 0.4), vec3y1));
    d2 = sdKitchenDoor(pos1);
    d1 = minx(d1, d2);

    // kitchen stairs
    pos1 = pos;
    pos1.xz *= rotation_145;
    pos1.z -= 5.25;
    d2 = sdKitchenStairs(pos1 - vec3y(0.001));
    d1 = minx(d1, d2);

    // basement
    pos1 = pos;
    pos1.xz *= rotation_90;
    pos1.z -= 5.0;
    pos1.xz *= rotation_n90;

    d2 = sdBasement(pos1);
    d2.x = max(d2.x, -wallsBounds);
    d1 = minx(d1, d2);

    // inner floors
    d2 = sdFloors(pos);
    d2.x = max(d2.x, roofBounds);
    d1 = minx(d1, d2);

    // well
    pos1 = pos;
    pos1 -= WELL_POSITION;
    pos1.xz *= rotation_n145;
    d2 = sdWell(pos1);
    d1 = minx(d1, d2);
#endif

    return d1;
}

vec3 sdBridgeSegment(vec3 pos, float r, float r1, float n1, float n2, float dir)
{
    const float w = 1.5;
    const float bevel = 0.03;

    float w1 = 2.0 * r / r1;

    // center segment
    vec3 pos2 = pos;

    float an = atan(pos2.x, dir * pos2.y);
    float index = floor(an / w1 + 0.5);
    index = clamp(index, n1, n2);
    an -= index * w1;

    pos2.xy = length(pos2.xy) * vec2(sin(an), cos(an));
    pos2.y -= r1;

    vec2 p = pos2.xy;
    float r0 = length(p);
    float d1 = sdCircle(p, r - bevel);
    float d2 = sdRectangle(p + dir * vec2y(r1 + 0.5 * bevel), vec2(r1 - bevel));
    d1 = max(d1, d2);
    d1 = max(0.0, d1);
    d1 = length(vec2(d1, stretchAxis(pos2.z, w - bevel * 2.0)));
    d1 -= bevel;

    vec3 d = vec3(d1, MATERIAL_WOOD3, 1.0 + mod(index, 2.0));
    d.yz += mod(vec2(0.3 * (r0 + index), 0.003 * pos.z + w), 1.0); // uv stretch
    return d;
}

vec3 sdBridgeHandrails(vec3 pos, float r, float h)
{
    const float r1 = 0.06;
    const float r2 = 0.05;
    const float w = 0.2; // poles angle

    float an = atan(pos.x, pos.y);
    float r0 = length(pos.xy);
    float index = floor(an / w + 0.5);

    vec3 pos1 = pos;
    float d = sdCircle(pos1.xy, r + h);
    d = abs(d);
    d = max(0.0, d);
    d = length(vec2(d, pos1.z));
    d -= r1;

    // rail
    pos1.x = abs(pos1.x);
    pos1.xy *= rotation_n30;
    d = max(d, pos1.x);
    vec3 d1 = vec3(d, MATERIAL_WOOD3, 3.0);
    d1.yz += mod(0.5 * vec2(0.1 * (an + PI), r0), 1.0); // uv stretch

    // poles

    pos1 = pos;
    index = clamp(index, -2.0, 2.0);
    float an2 = index * w;

    vec3 c = vec3(clamp(r0, r - 0.1, r + h) * vec2(sin(an2), cos(an2)), 0.0); // center
    d = length(pos1 - c) - r2; // circle

    vec3 d2 = vec3(d, MATERIAL_WOOD3, 2.0);
    d2.yz += mod(vec2(an + index, 0.01 * r0), 1.0); // uv stretch
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdBridgeSupportRail(vec3 pos, float r, float startAngle, float endAngle, float dir, float side)
{
    const float w = 0.15;
    const float h = 0.07;
    const float bevel = 0.02;

    r -= dir * h;

    float an = atan(pos.y, pos.x);
    float r0 = length(pos.xy);

    vec3 pos1 = pos;
    float d = sdCircle(pos1.xy, r);
    d = abs(d) - h; // duplicate circle
    d = max(0.0, d); // fill shape
    d = length(vec2(d, stretchAxis(pos1.z, 2.0 * (w - bevel)))); // convert to 3d distance
    d -= bevel;

    d = max(d, -dir * pos1.y); // remove half

    pos1 = pos;
    pos1.xy *= rotation(-dir * startAngle);
    d = max(d, -pos1.x); // cut start

    pos1 = pos;
    pos1.xy *= rotation(-dir * endAngle);
    d = max(d, pos1.x); // cut end

    vec3 d1 = vec3(d, MATERIAL_WOOD3, 5.0);
    d1.yz += mod(0.2 * vec2(0.1 * an, (r0 + pos.z)), 1.0); // uv stretch

    return d1;
}

vec3 sdBridgePosts(vec3 pos, float r, float w)
{
    const float r1 = 0.13;
    const float h = 1.0;
    vec2 gridSize = vec2(1.3, w);

    float bounds = sdBoxApprox(pos, vec3(r, 1.5, w), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.z += 0.5 * gridSize.y;
    vec2 index = floor(pos1.xz / gridSize + 0.5);
    index = clamp(index, vec2(-1.0, 0.0), vec2(1.0, 1.0));
    pos1.xz -= index * gridSize;

    vec3 pos2 = pos1;
    float h1 = hash(index);
    float an = 0.25 * (h1 - 0.5);
    pos2.xy *= rotation(an);

    float d1 = length(pos2.xz) - r1;
    d1 = max(0.0, d1);

    // bounds
    float d2 = -sdRectangleApprox(pos1.xz, gridSize * 0.5 + 0.3);
    float d3 = sdRectangleApprox(pos.xz, gridSize * vec2(1.5, 1.0));
    d2 = max(d2, d3);
    d1 = min(d1, d2);

    pos1 = pos;
    d2 = length(pos1.xy) - r;
    d1 = max(d1, d2);

    float an0 = atan(pos2.x, pos2.z);

    vec3 d = vec3(d1, MATERIAL_WOOD3, 1.0);
    d.yz += mod(0.02 * vec2(0.5 * pos2.y, an0), 1.0); // uv stretch
    return d;
}

vec3 sdBridge(vec3 pos)
{
    // tile
    const float r = 0.15;
    const float w = 1.0;

    // center curve
    const float r1 = 2.5;
    const float n1 = 5.0; // count
    const float w1 = 2.0 * r / r1;

    // side curve
    const float r2 = 3.5;
    const float n2 = 7.0; // count
    const float start2 = 2.0; // start index
    const float w2 = 2.0 * r / r2;
    const vec2 offset2 = vec2(r1 * sin(n1 * w1) + r2 * sin(n2 * w2), r1 * cos(n1 * w1) + r2 * cos(n2 * w2));

    // handrails
    const float h3 = 0.6;
    const float r3 = r1 * 1.2;

    const float h = r1 * (1.0 - cos(n1 * w1)) + r2 * (1.0 - cos(n2 * w2));

    float bounds = sdBoxApprox(pos, vec3(3.0, 1.6, 1.0));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y += r1 - h;

    // center segment
    vec3 pos2 = pos1;
    float side = sign(pos2.x);
    pos2.x = abs(pos2.x);
    vec3 d1 = sdBridgeSegment(pos2, r, r1, 0.0, n1, 1.0);

    // center segment support
    pos2.z = abs(pos2.z);
    pos2.z -= 0.5 * w;
    vec3 d2 = sdBridgeSupportRail(pos2, r1 - r, 0.0, n1 * w1, 1.0, side);
    d1 = minx(d1, d2);

    // side segment
    pos2 = pos1;
    pos2.x = abs(pos2.x);
    pos2.xy -= offset2;
    d2 = sdBridgeSegment(pos2, r, r2, -n2 + 1.0, -start2, -1.0);
    d2.z += 2.0; // edge offset
    d1 = minx(d1, d2);

    // side segment support
    pos2.z = abs(pos2.z);
    pos2.z -= 0.5 * w;
    d2 = sdBridgeSupportRail(pos2, r2 + r, -n2 * w2, -start2 * w2, -1.0, side);
    d1 = minx(d1, d2);

    // handrails
    pos2 = pos;
    pos2.y += r3 - h;
    pos2.z -= 0.6 * w;
    d2 = sdBridgeHandrails(pos2, r3, h3);
    d1 = minx(d1, d2);

    // posts
    pos2 = pos;
    pos2.y += r1 - h + 0.2;
    d2 = sdBridgePosts(pos2, r1, w);
    d1 = minx(d1, d2);

    return d1;
}

vec3 sdMailboxPost(vec3 pos)
{
    // post
    const float h = 1.8;
    const float r = 0.04;

    // mailbox
    const float w1 = 0.15;
    const float h1 = 0.23;
    const float depth1 = 0.06;
    const float thickness1 = 0.01;

    // opening
    const float w2 = w1 - 0.03;
    const float h2 = 0.02;
    const float offset2 = 0.01;

    // top
    const float w3 = w1 + 0.015;
    const float h3 = depth1 * 1.4142 + 0.02;
    const float thickness3 = 0.015;

    // arrow tail
    const float w4 = 0.15;
    const float h4 = 0.04;
    const float offset4 = 0.18;
    const float thickness4 = 0.01;

    // arrow head
    const float w5 = 0.06;

    const float bevel = 0.005;

    float bounds = sdBoxApprox(pos, vec3(w1, h, w1) * 0.5 + 0.2, vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.z += depth1 + r;
    pos1.y -= 0.6 * h;

    // mailbox
    float d = sdBox(pos1, vec3(w1, h1, depth1) - bevel) - bevel;
    d = max(d, -d - thickness1); // hollow
    float shade = -0.4 * pos1.y / h1;
    vec3 d1 = vec3(d, MATERIAL_OUTER_WALL + clamp(shade, 0.0, 0.99), 1.0);

    // opening
    vec3 pos2 = pos1;
    pos2.y -= offset2;
    pos2.z += depth1;
    d = sdBox(pos2, vec3(w2, h2, thickness1 + 0.01));
    vec3 d2 = vec3(-d, MATERIAL_OUTER_WALL, 2.0);
    d1 = maxx(d1, d2);

    // roof
    pos2 = pos1;
    pos2.y -= h1;
    pos2.yz *= rotation_n45;
    pos2.y += depth1;

    d1.x = max(d1.x, pos2.y); // cut top

    pos2.z -= 0.025;
    d = sdBox(pos2, vec3(w3, thickness3 * 0.5, h3), vec3(0.0, 1.0, -1.0), bevel);
    shade = 0.25 * pos2.z / h3;
    d2 = vec3(d, MATERIAL_TILE + clamp(shade, 0.0, 0.99), 0.0);
    d1 = minx(d1, d2);

    // arrow tail
    pos2 = pos1;
    pos2.y -= h1 + offset4;
    pos2.z -= depth1 - thickness4;
    vec3 pos3 = pos2;
    pos3.x += w5 * 0.6;
    d = sdRectangle(pos3.xy, vec2(w4, h4) - bevel);

    // arrow head
    pos3 = pos2;
    pos3.x -= w4 - 0.1 * w5;
    pos3.xy *= rotation_30;
    d = min(d, sdTriangle(pos3.xy, w5));

    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos3.z, thickness4)));
    d -= bevel;
    d2 = vec3(d, MATERIAL_TILE, 1.0);
    d1 = minx(d1, d2);

    // post
    pos1 = pos;
    pos1.y -= 0.5 * h;
    d = length(pos1.xz) - r + bevel;
    d = max(0.0, d);
    d = length(vec2(d, stretchAxis(pos1.y, h)));
    d -= bevel;
    d2 = vec3(d, MATERIAL_WOOD3, 1.0);
    d2.yz += 0.99 * fract(vec2(0.5) + vec2(0.1, 0.01) * vec2(pos1.x + pos1.z, pos1.y)); // uv
    d1 = minx(d1, d2);

    return d1;
}

float getRiverJuiceMask(vec3 pos, float time)
{
    vec2 p = pos.xz;
    p -= HAT_POSITION.xz + vec2(0.85, 0.15);

    float bounds = sdRectangleApprox(p - vec2x1, vec2(3.0, 1.5));
    if (bounds > BOUNDS_MARGIN)
    {
        return 0.0;
    }

    p *= 2.0;
    float a = smoothstep(-2.0, 3.0, p.x);
    p.x -= a * 6.0 * fbm(p - vec2x(time)); // stretch
    p.y *= 3.0 - 2.0 * a; // taper

    float d = length(p);

    return d < 2.0 ? 1.0 : 0.0;
}

vec3 sdHat(vec3 pos)
{
    const float h1 = 0.30; // height
    const float h2 = 0.01; // raised edge height
    const float w1 = 0.06; // ribbon width
    const float r1 = 0.16; // top radius
    const float r2 = 0.13; // center radius
    const float r3 = 0.17; // base radius
    const float r4 = 0.19; // edge radius
    const float thickness1 = 0.005; // thickness
    const float thickness2 = 0.008; // ribbon thickness

    float bounds = sdBoxApprox(pos, vec3(r4, 0.5 * h1, r4), vec3y1);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec2 pos1 = vec2(length(pos.xz), pos.y);

    float d1 = sdLine(pos1, vec2(0.0, h1), vec2(r1, h1)); // top
    float d2 = sdLine(pos1, vec2(r1, h1), vec2(r2, w1)); // side
    d1 = min(d1, d2);

    d2 = sdLine(pos1, vec2(r2, w1), vec2(r2, 0.0)); // bottom
    d1 = min(d1, d2);

    d2 = sdLine(pos1, vec2(r2, 0.0), vec2(r3, 0.0)); // bottom
    d1 = min(d1, d2);

    d2 = sdLine(pos1, vec2(r3, 0.0), vec2(r4, h2)); // edge
    d1 = min(d1, d2);

    d1 -= thickness1;

    vec3 d = vec3(d1, MATERIAL_HAT, 0.0);

    d1 = sdLine(pos1,
    vec2(r2 + thickness1, thickness1 + w1),
    vec2(r2 + thickness1, thickness1)); // ribbon
    d1 -= thickness2;

    d = minx(d, vec3(d1, MATERIAL_HAT_RIBBON, 0.0));

    return d;
}

vec3 sdRock(vec3 pos, float size, float h1, float h2)
{
    float bounds = sdBoxApprox(pos, vec3(1.5 * size));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float phase = PI * h2;

    vec3 pos1 = pos;
    pos1.x += 0.02 * (sin(15.0 * pos.x + phase) + sin(10.0 * pos.z + phase));
    pos1.y += 0.01 * (sin(13.0 * pos.x + phase) + sin(18.0 * pos.z + phase));
    pos1.z += 0.02 * (sin(10.0 * pos.x + phase) + sin(15.0 * pos.z + phase));
    pos1.y += 0.4 * size;

    pos1 /= size;
    float d = sdSphere(pos1, 1.0);
    d *= size;

    return vec3(d, MATERIAL_PATHWAY_ROCK, 0.0);
}

vec3 sdRocks(vec3 pos, bool simplified)
{
    const float gridSize = 1.3;
    const float size = 0.4; // rock size
    const float margin1 = 10.0; // river banks
    const float p1 = 0.8; // groups density
    const float p2 = 0.3; // groups size
    const float p3 = 0.6; // pathway scatter probability
    const float p4 = 0.8; // river groups density
    const float riverWidth = 2.0;
    const float riverDepth = 1.9;
    const float banksWidth = 1.0;
    const float seed = 3.0;
    const vec2[] offsets = vec2[2](vec2(0.0), gridSize * vec2(0.5, 0.25));

    float bounds = pos.y - size;

    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);

    for (int i = 0; i < 2; i++)
    {
        vec3 pos1 = pos;
        vec2 offset = offsets[i];

        vec4 c = hexCoordinates(pos1.xz - offset, gridSize);
        vec2 index = c.zw;

        float h1 = hash(index + seed + 0.5 * float(i));
        float h2 = hash(index + vec2(100.0) + seed + 0.5 * float(i));

        vec2 center = pos1.xz - c.xy;
        pos1.xz -= center.xy;

        vec3 riverMask = getRiverMask(center.x);
        float riverDist = abs(center.y - riverMask.z);
        vec3 pathwayMask = getPathwayMask(center.y);
        float pathwayDist = abs(center.x - pathwayMask.x) / pathwayMask.z;

        float p = p1 + h1 * h2; // grass
        p = fbm(index * gridSize * 0.2 + seed) < p2 ? p : 0.0; // mask grass
        p += h1 < p3 && pathwayDist < 2.5 && center.y > 0.0 ? 1.0 : 0.0; // add pathway rocks
        p = pathwayDist > 0.87 ? p : 0.0; // mask pathway center
        p += h2 < p4 && riverDist < 0.5 * riverMask.x ? 1.0 : 0.0; // add more river rocks
        p = abs(riverDist - 0.5 * riverMask.x) > 0.4 ? p : 0.0; // mask river banks

        if (p < 1.0)
        {
            continue;
        }

        pos1.xz -= 0.5 * map01_11(vec2(h1, h2));

        float size1 = size * (1.0 - 0.5 * h2);

        if (simplified)
        {
            vec3 d2 = vec3(sdSphere(pos1, size1 + 0.08), 100.0, 0.0);
            d1 = minx(d1, d2);
            continue;
        }

        vec3 d2 = sdRock(pos1, size1, h1, h2);
        d1 = minx(d1, d2);
    }

    return d1;
}

vec3 sdPathway(vec3 pos)
{
    const float z1 = 5.5; // entrance
    const float z2 = 8.0; // entrance
    const float z3 = 40.0; // bridge exit
    const float z4 = 50.0; // bridge exit
    const float z5 = 50.0; // bridge entrance
    const float z6 = 60.0; // bridge entrance

    const float depth1 = 0.04; // base
    const float depth2 = 0.05; // bump
    const float bevel = 0.3;

    pos.y -= getGroundHeight(pos);

    float bounds = sdRectangleApprox(pos.xy + vec2x(8.0), vec2(10.0, 0.2));
    bounds = max(bounds, -pos.z);

    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;

    float mask1 = smoothstep(z2, z1, pos1.z) + // entrance path
            smoothstep(z3, z4, pos1.z) * smoothstep(z6, z5, pos1.z); // bridge path

    pos1.y -= 0.1 * mask1;

    vec3 mask = getPathwayMask(pos1.z);
    float width = mask.z;
    float center = mask.x;

    float depth = depth1 + (1.0 - mask1) * depth2 * (sin(pos1.z * 3.0) + sin(pos1.z + pos1.x * 5.0) + 2.0) / 4.0;

    pos1.x -= center;
    pos1.y += depth;
    float d = sdRectangle(pos1.xy - vec2y(0.5), vec2(width, depth + 0.5) - bevel);
    d = max(0.0, d);
    d -= bevel;

    d = max(d, -pos.z);

    return vec3(d, MATERIAL_PATHWAY, 0.0);
}

vec3 sdPathwayEdges(vec3 pos)
{
    const float width1 = 1.0;
    const float width2 = 1.2;
    const float thickness1 = 0.05;
    const float thickness2 = 0.15;
    const float r1 = 50.0; // river position
    const float r2 = 2.0; // river width

    float h = getGroundHeight(pos);
    float bounds = pos.y - h - thickness2;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 mask1 = getPathwayMask(pos.z);
    float d1 = abs(pos.x - mask1.x);

    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float width = mask1.z;

    float curvePos = 0.2 * pos.z;
    float thickness = mix(thickness1, thickness2, 0.5 + 0.5 * abs(sin(23.0 * curvePos) + cos(17.0 * curvePos)));

    float mask2 = smoothstep(r1 - 3.0, r1 - 2.0, pos.z) - smoothstep(r1 + 2.0, r1 + 3.0, pos.z); // bridge mask
    mask2 += smoothstep(7.0, 5.0, pos.z); // entrance mask

    thickness = mix(thickness, thickness2, mask2);
    pos.y += 0.5 * mask2;

    pos.y -= 0.05;
    pos.y += 0.8 * thickness;

    d1 = length(vec2(abs(d1 - width), pos.y - h)) - thickness;

    float d2 = abs(pos.z - r1) - r2;
    d1 = smax(d1, -d2, 0.2);

    return vec3(d1, MATERIAL_GRASS, 0.0);
}

vec3 sdGround(vec3 pos)
{
    float h = getGroundBaseHeight(pos);

    float bounds = pos.y - h;
    if (bounds > 1.5)
    {
        return vec3(bounds, MATERIAL_GRASS, 0.0);
    }

    h = getGroundHeight(pos, h);
    vec3 riverMask = getRiverMask(pos.x);

    float d1 = pos.y - h;

    float d2 = length(pos.xz - WELL_POSITION.xz) - 0.7; // well

    d2 = max(d2, -pos.y + HILL_HEIGHT - 2.0);
    d1 = max(d1, -d2);

    if (pos.y < 0.1 && abs(pos.z - riverMask.z) < riverMask.x || d2 < 0.0)
    {
        return vec3(d1, MATERIAL_RIVERBED, 0.0);
    }

    return vec3(d1, MATERIAL_GRASS, 0.0);
}

vec3 sdRiverBanks(vec3 pos)
{
    const float thickness1 = 0.1;
    const float thickness2 = 0.2;
    const float riverWidth = 2.0;
    const float rocksGap = 0.7;
    const float rocksSize = 0.3;
    const float rocksDensity = 0.6;
    const float seed = 100.0;

    float bounds = pos.y - 0.2;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    pos1.y += 0.05;
    float curvePos = pos1.x * 0.4;
    float thickness = mix(thickness1, thickness2, 0.5 * abs(sin(13.0 * curvePos) + cos(7.0 * curvePos)));

    vec3 riverMask = getRiverMask(pos1.x);
    float dist = abs(riverMask.z - pos1.z) - 0.38 * riverMask.x -0.9 + thickness;

    vec3 pos2 = pos1;
    pos2.y += 0.7 * thickness - 0.15;
    float d = length(vec2(dist, pos2.y)) - thickness;

    return vec3(d, MATERIAL_GRASS, 1.0); // grass material with group 0 doesn't cast shadow
}

vec3 sdRiverBanksRocks(vec3 pos)
{
    const float riverWidth = 2.0;
    const float gap = 1.2;
    const float size1 = 0.4;
    const float size2 = 0.6;
    const float p0 = 0.5; // group size
    const float p1 = 0.5; // group gap
    const float p2 = 0.7; // density
    const float seed = 3.0;

    vec3 pos1 = pos;

    vec3 riverMask = getRiverMask(pos1.x);
    pos1.z -= riverMask.z;
    pos1.z -= sign(pos1.z) * riverMask.x * 0.5;

    float bounds = sdCircle(pos1.yz, 0.8);
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);

    for (int i = 0; i < 2; i++)
    {
        pos1 = pos;

        float offset = float(i) * gap * 0.5;
        pos1.x -= offset;

        float index = floor(pos1.x / gap + 0.5);
        index = sign(index + 0.01) * max(2.0, abs(index)); // mask bridge

        riverMask = getRiverMask(index * gap + offset);

        pos1.x -= index * gap;
        pos1.z -= riverMask.z;

        index += 1000.0 * sign(pos1.z) + float(i) * 2000.0;

        float h1 = fbm(vec2((index + 0.5 * float(i)), 0.0) / p0 + seed);

        index += float(i) * 2000.0;
        float h2 = hash(index + seed);
        float h3 = hash(index + 100.0 + seed);

        if (h1 > p1 || h2 > p2)
        {
            continue;
        }

        float size = mix(size1, size2, h2);

        pos1.z = abs(pos1.z);
        pos1.z -= 0.5 * riverMask.x;

        pos1.yz += 0.8 * size - vec2(0.4, 0.5);

        vec3 d2 = sdRock(pos1, size, h2, h3);
        d1 = minx(d1, d2);
    }

    return d1;
}

vec2 sdRiverWater(vec3 pos, float time)
{
    const float h1 = 0.01; // ripple height
    const float h2 = 0.01; // rocks ripple height
    const float h3 = 0.02; // bridge ripple height

    float bounds = pos.y - h1;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec2(bounds, MATERIAL_WATER);
    }

    vec3 riverMask = getRiverMask(pos.x);
    float d = abs(pos.z - riverMask.z) - riverMask.x;

    d = max(0.0, d);
    if (d > BOUNDS_MARGIN)
    {
        return vec2(d, MATERIAL_WATER);
    }

    float d2 = sdRiverBanksRocks(pos).x;

    vec3 pos1 = pos;
    pos1.y += 1.35;
    pos1.z -= 50.0;
    pos1.xz *= rotation_n90;
    float d3 = sdBridgePosts(pos1, 2.5, 1.0).x;

    float h = 0.0;
    h += h1 * sin(5.0 * pos.x - 4.0 * time);
    h += h2 * smoothstep(0.2, 0.0, d2) * (sin(40.0 * d2 - 2.0 * time));
    h += h3 * smoothstep(0.1, 0.0, d3) * (sin(40.0 * d3 - 2.0 * time + PI05));

    d = max(pos.y + h, d);

    return vec2(d, MATERIAL_WATER);// + ref);
}

vec3 sdGrass(vec3 pos, float time)
{
    const vec2 gridSize1 = vec2(0.05);
    const vec2 gridSize2 = vec2(0.15);
    const float h1 = 0.08;
    const float h2 = 0.15;
    const float h3 = 0.03;
    const float r1 = 0.005;
    const float r2 = 0.015;
    const float rocksMargin = 0.0;
    const vec2[] offsets = vec2[](vec2(0.0), vec2(0.2, 0.8), vec2(0.7, 0.3));

    float bounds = pos.y - h1 - 2.0 * h3;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float viewDist = length(state.origin - pos);

    float d1 = pos.y;
    vec2 rootPos = pos.xz;

    float rocksDist = sdRocks(vec3(pos.xz, 0.0).xzy, true).x - rocksMargin;
    float rocksMask1 = smoothstep(-0.1, 0.0, rocksDist);

    vec3 riverMask1 = getRiverMask(pos.x);
    float riverMask2 = smoothstep(0.75, 0.8, abs(pos.z - riverMask1.z) - 0.38 * riverMask1.x);

    vec3 pathwayMask1 = getPathwayMask(pos.z);
    float pathwayDist = abs(pathwayMask1.x - pos.x) - pathwayMask1.z;
    float pathwayMask2 = smoothstep(0.0, 0.1, pathwayDist);
    pathwayMask2 = pos.z < 0.0 ? 1.0 : pathwayMask2;

    float wellMask = smoothstep(0.8, 0.85, length(pos.xz - WELL_POSITION.xz));

    float mask = rocksMask1 * riverMask2 * pathwayMask2 * wellMask;

    if (mask < 0.01)
    {
        return vec3(MAX_DIST, 0.0, 0.0);
    }

    if (viewDist > 100.0)
    {
        d1 = pos.y - 0.5 * (h1 + h2);
    }
    else
    {
        pos.xz += 0.1 * vec2(sin(4.0 * pos.z), sin(4.0 * pos.x)); // wrap grid
        vec3 windForce = getWindForce(pos, time) * rocksMask1;

        for (int i = 0; i < 3; i++)
        {
            float j = float(i);

            vec3 pos1 = pos;
            vec2 gridSize = mix(gridSize1, gridSize2, j / 2.0);
            pos1.xz += offsets[i] * gridSize;

            float h = mix(h1, h2, map11_01(0.5 * (sin(7.1 * pos1.x + 1.8 * j) + sin(9.3 * pos1.z + 1.5 * j))));
            h += j * h3;
            h *= mask;

            vec3 dir = vec3y1;
            dir += windForce * (j * 0.5 + 1.0);
            dir.y = max(0.0, dir.y);
            dir = normalize(dir);
            dir *= h;

            float y = clamp(pos1.y / dir.y, 0.0, 1.0);

            pos1.xz -= 0.2 * dir.xz * pow(y, 2.0); // curve

            vec2 gridOffset = y * dir.xz; // offset grid index based on the direction relative to the queried position height
            vec2 index = floor((pos1.xz - gridOffset) / gridSize + 0.5);
            vec3 pos2 = pos1;

            float h1 = hash(index);
            float h2 = fract(h1 * h1);

            pos2.xz -= index * gridSize;
            pos2.xz += 0.3 * gridSize * map01_11(vec2(h1, h2)); // jitter

            float r = mix(r2, r1, y);
            float d2 = sdCapsule(pos2, vec3(0.0), dir, r);

            rootPos = d2 < d1 ? index * gridSize : rootPos;
            d1 = min(d1, d2);
        }
    }

    vec3 d = vec3(d1, MATERIAL_GRASS, 0.0);
    d.yz += fract(rootPos / 1000.0 + 0.5); // serialize root position
    return d;
}

vec3 sdGrassFlower(vec3 pos, float hue, float scale, vec3 dir)
{
    const float size1 = 0.02; // petals
    const float thickness1 = 0.002;
    const float size2 = 0.03; // base
    const float size3 = 0.02; // disk
    const float size4 = 0.2; // stem
    const float thickness4 = 0.004;

    pos /= scale;

    float bounds = sdBoxApprox(pos, vec3(0.07, 0.1, 0.07), vec3y1) * scale;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos.zy *= rotation(atan(-dir.z, dir.y));
    pos.xy *= rotation(atan(-dir.x, dir.y));

    pos.y -= 0.8 * size4;

    // petals
    vec3 pos1 = pos;
    pos1.xy *= rotation_n30;

    float index = 0.0;
    vec3 pos2 = pos1;
    pos2.xz = radialMod(pos2.xz, 5.0, index);
    pos2.x -= 1.5 * size1;
    pos2.xy *= rotation_30;
    float d = sdCircle(pos2.xz, size1);
    d = max(0.0, d);
    d = length(vec2(d, pos2.y));
    d -= thickness1;
    vec3 d1 = vec3(d, MATERIAL_GRASS_FLOWER1, hue);

    // base
    pos2 = pos1;
    pos2.y -= 0.4 * size2;
    d = sdSphere(pos2, size2);
    d = max(d, pos2.y + 0.68 * size2);
    vec3 d2 = vec3(d, MATERIAL_GRASS, 0.8);
    d1 = smin(d1, d2, 0.01);

    // stem
    pos2 = pos;
    pos2.x -= 0.73 * size4;
    pos2.y += 0.7 * size4;
    d = sdCircle(pos2.xy, size4);
    d = length(vec2(d, pos2.z));
    d = max(d, pos2.x);
    d = max(d, pos1.y + 0.1 * size4);
    d = max(d, -pos2.y);
    d -= thickness4;
    d2 = vec3(d, MATERIAL_GRASS, 0.5);
    d1 = smin(d1, d2, 0.01);

    // disk
    pos2 = pos1;
    pos2.y += size3;
    d = sdSphere(pos2, size3);
    d = max(d, -pos2.y + 0.5 * size3);
    d2 = vec3(d, MATERIAL_GRASS_FLOWER2, 0.0);
    d1 = minx(d1, d2);

    d1.x *= scale;
    return d1;
}

vec3 sdGrassFlowers(vec3 pos, float time)
{
    const vec2 gridSize = vec2(0.5);
    const float p1 = 1.8; // groups density
    const float p2 = 0.4; // groups size
    const float seed = 1.0;

    float bounds = pos.y - 0.2;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float viewDist = length(state.origin - pos);
    if (viewDist > 80.0)
    {
        return vec3(MAX_DIST, 0.0, 0.0);
    }

    vec3 pos1 = pos;

    float h = 0.35 + 0.05 * (sin(pos.x) + sin(pos.z)); // height

    vec3 dir = vec3y1;
    dir += 0.3 * getWindForce(pos, time + 0.2);
    dir.y = max(0.0, dir.y);
    dir = normalize(dir);
    dir *= h / dir.y;

    float y = clamp(pos1.y / dir.y, 0.0, 1.0);

    vec2 index = floor((pos1.xz - y * dir.xz) / gridSize + 0.5);

    vec3 center = vec3(index * gridSize, pos1.y).xzy;
    
    vec3 pos2 = pos1;
    pos2.xz -= index * gridSize;

    vec3 riverMask = getRiverMask(center.x);
    float riverDist = abs(center.z - riverMask.z) - riverMask.x;

    vec3 pathwayMask = getPathwayMask(center.z);
    float pathwayDist = abs(center.x - pathwayMask.x) - pathwayMask.z - 0.05;

    float rockDist = MAX_DIST;
#ifdef RENDER_ROCKS
    rockDist = sdRocks(center, false).x - 0.04;
#endif

    float wellDist = length(center.xz - WELL_POSITION.xz) - 0.6;

    float p = fbm(index / p1 + 100.0 * seed);
    if (p > p2 || riverDist < 0.1 || pathwayDist < 0.1 || rockDist < 0.1 || wellDist < 0.1)
    {
        return vec3(MAX_DIST, 0.0, 0.0);
    }

    pos2.xz -= 0.1 * y * dir.xz; // skew

    float h1 = hash(index + seed);
    float h2 = hash(index + seed + 1000.0);
    float h3 = fract(h1 + h2);
    float h4 = fract(h1 - h2);

    pos2.xz -= (0.5 * gridSize - 0.1) * map01_11(vec2(h1, h2)); // jitter
    pos2.xz *= rotation(h3 * PI2);

    float hue = h1 < 0.7 ? 0.0 : 0.99;
    float scale = 1.0 + 0.3 * h4;

    vec3 d1 = sdGrassFlower(pos2, hue, scale, dir);
    
    return d1;
}

vec3 sdFlowers(vec3 pos, float time)
{
    const vec2 gridSize = vec2(0.25);
    const vec2 gridBounds = vec2(1.0, 2.0);
    const float r = 0.6;

    float bounds = sdBoxApprox(pos, vec3(r + 0.2));
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);

    vec3 pos1 = pos;
    float s = 1.0;
    for (int i = 0; i < 2; i++)
    {
        vec3 pos2 = pos1;
        vec2 index = floor(pos2.xz / gridSize);
        index = clamp(index, -gridBounds, gridBounds);
        pos2.xz -= gridSize * (index + 0.5);

        float h1 = hash(index + 1000.0 * float(i));
        float h2 = hash(index + 100.0 + 1000.0 * float(i));
        pos2.xz *= rotation(h1 * PI2);

        float s = 1.0 - 0.4 * h1;
        pos2.y -= 0.3 * s;
        pos2 /= s;
        vec3 d2 = sdFlower(pos2, h2);
        d2.x *= s;
        d1 = minx(d1, d2);

        pos1.xz *= rotation_7_5;
        pos1.xz += 0.1;
    }

    return d1;
}

float sdLeaf(vec2 p, float size)
{
    p /= size;

    float offset = 0.5 * smoothstep(0.0, 1.0, pow(abs(p.x), 0.7));
    vec2 p1 = p;
    p1.y -= offset;
    float d1 = length(p1) - 1.0;

    p1 = p;
    p1.x = abs(p1.x);
    p1 *= rotation_n7_5;
    float d2 = p1.x;
    d2 = max(d2, p1.y - 1.8);

    d1 = min(d1, d2);

    d1 *= size;
    return d1;
}

vec3 sdMountains(vec3 pos)
{
    const float scale = 200.0;

    const float f = 2.0;
    const float r1 = 2.0;
    const float h1 = 1.6;
    const float thickness1 = 0.8;
    const float count1  = 4.0;
    const float offset1 = -1.4;

    const float r2 = 3.0;
    const float h2 = 2.0;
    const float thickness2 = 1.0;
    const float variation2 = 0.3;
    const float count2  = 3.0;
    const float offset2 = 3.6;

    const float bumps = 0.2;
    const float details = 2.5;
    const float seed = 0.0;

    pos /= scale;

    vec3 pos1 = pos;

    float r = length(pos1.xz);

    float bounds = (abs(r - 3.0) - 2.0) * scale;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    pos1.y -= bumps * fbm(pos1 * details + seed) - 0.1;
    pos1.y += thickness1;

    float an = atan(pos1.z, pos1.x);

    float d1 = sdCircle(pos1.xz, r1);
    float h = pow(map11_01(sin(count1 * an + offset1)), 0.8) * h1;
    d1 = length(vec2(d1, stretchAxis(pos1.y, h)));
    d1 -= thickness1;

    float mask = smoothstep(0.0, 1.0, abs(an + PI05)); // front valley mask

    float d2 = sdCircle(pos1.xz, r2);
    h = pow(map11_01(sin(count2 * an + PI + offset2)) + 0.05, 0.3) * h2;
    h *= 1.0 + variation2 * sin((count2 - 1.0) * an); // variation
    h *= mask;
    d2 = length(vec2(d2, stretchAxis(pos1.y, h)));
    d2 -= thickness2 * mask;

    d1 = min(d1, d2);

    d1 = smin(d1, pos.y + 0.1, 0.8);
    d1 = max(d1, -pos.y);
    d1 = max(d1, r - r2 - 2.0 * thickness2);

    return vec3(d1 * scale, MATERIAL_MOUNTAIN, 0.0);
}

vec3 sdTreeBranches(vec3 pos, float count, float size)
{
    const float size1 = 0.5;
    const float thickness1 = 0.01;
    const float width1 = 0.9;
    const float curve1 = 1.0;

    pos /= size;

    float bounds = sdBoxApprox(pos, vec3(0.8, 0.3, 0.8), vec3y(-0.9)) * size;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;
    float index;

    pos1.xz = radialMod(pos1.xz, count, index);

    pos1.x = -pos1.x + size1;

    pos1.xy *= rotation_n30;
    float an = atan(pos1.y, pos1.x);
    an = clamp(an, -curve1, curve1 * 0.4);
    float width = width1 * (an + curve1) / (2.0 * curve1);
    float thickness = thickness1 / size;

    float d1 = length(pos1.xy - size1 * vec2(cos(an), sin(an)));
    d1 = length(vec2(d1, stretchAxis(pos1.z, width)));
    d1 -= thickness;

    vec3 d = vec3(d1, MATERIAL_TREE_BRANCH, 0.0);

    d.x *= size;

    return d;
}

vec3 sdTree(vec3 pos, float size, float time)
{
    const float thickness1 = 0.07; // bark

    pos /= size;

    float bounds = sdBoxApprox(pos, vec3(1.6), vec3y(0.9)) * size;
    if (bounds > BOUNDS_MARGIN)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;

    time *= 0.5;
    pos1.y += 0.05 * (sin(3.0 * pos1.x + time) + sin(2.0 * pos1.z + time));
    pos1.x += 0.05 * sin(0.7 * time) * pow(max(pos1.y, 0.0), 1.5);
    pos1.z += 0.05 * sin(time) * pow(max(pos1.y, 0.0), 1.5);

    vec3 pos2 = pos1;
    pos2.y -= 2.9;
    float d = sdCircle(pos2.xz, max(0.0, -thickness1 * pos2.y));
    d = max(0.0, d);
    d = max(d, pos2.y);

    vec3 d1 = vec3(d, MATERIAL_TREE_BARK, 0.0);

    for (int i = 0; i < 4; i++)
    {
        float index = float(i);
        vec3 pos2 = pos1;
        pos2.y -= 2.4 + index * 0.2;
        vec3 d2 = sdTreeBranches(pos2, 8.0 - index, 3.5 - 0.6 * pow(index, 1.2));
        d1 = minx(d1, d2);
    }

    d1.x *= size;

    return d1;
}

vec3 sdTrees(vec3 pos, float time)
{
    const float gridSize = 8.0;
    const float r1 = 50.0;
    const float scale = 3.0;
    const float seed = 2.0;

    float bounds = max(pos.y - 10.0, -(length(pos.xz) - 10.0));
    if (bounds > 10.0)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    vec3 pos1 = pos;

    vec4 c = hexCoordinates(pos1.xz, gridSize);

    vec2 index = c.zw;
    vec3 center = pos1 - vec3(c.xy, pos1.y).xzy;

    pos1 -= center;
    pos1.y -= getGroundHeight(center);

    float bounds2 = -sdHexApprox(pos1.xz, 1.3 * gridSize);

    if (abs(center.x) < 32.0 || abs(center.z - 40.0) < 15.0)
    {
        return vec3(bounds2, 0.0, 0.0);
    }

    float mask = fbm(0.2 * index + seed);
    if (mask > 0.35)
    {
        return vec3(bounds2, 0.0, 0.0);
    }

    float h1 = map01_11(hash(index + 100.0 + seed));
    float h2 = map01_11(hash(index + 200.0 + seed));
    float h3 = map01_11(hash(index + 300.0 + seed));

    pos1.xz += (1.5 - h3) * vec2(h1, h2);

    pos1.xy *= rotation(0.2 * h1);
    pos1.xz *= rotation(PI2 * h2);

    vec3 d1 = sdTree(pos1, scale + h3, time + 10.0 * h3);

    d1.x = min(d1.x, bounds2);

    return d1;
}

vec3 sdClouds(vec3 pos, float time)
{
    const float gridSize = 160.0;
    const vec3 size = 50.0 * vec3(1.0, 0.5, 1.0);
    const float speed1 = 5.0;
    const float speed2 = 8.0;
    float seed = 26.0;

    pos.y -= 100.0;

    float bounds = -pos.y - 2.0 * size.y;
    if (bounds > 1.0)
    {
        return vec3(bounds, 0.0, 0.0);
    }

    float bump = 15.0 * map01_11(fbm(0.05 * vec3(1.0, 1.0, 0.5)  * pos));

    float d1 = MAX_DIST;

    for (int i = 0; i < 2; i++)
    {
        float j = float(i);

        vec3 pos1 = pos;

        pos1.y -= size.y * j;
        pos1.z -= time * mix(speed1, speed2, j);
        pos1.xz += 0.5 * gridSize * j;

        float gridSize1 = gridSize * (1.0 + 0.5 * j);
        vec2 index = floor(pos1.xz / gridSize1 + 0.5);

        pos1.xz -= index * gridSize1;

        bounds = sdRectangleApprox(pos1.xz, 0.6 * vec2(gridSize1));

        float h1 = hash(index + seed);
        float h2 = hash(index + 1000.0 + seed);
        float h3 = fract(h1 + h2);

        float size1 = 1.0 - 0.7 * h3;
        vec3 size2 = size * size1;
        pos1.xz -= (0.4 * vec2(gridSize) - size2.xz) * map01_11(vec2(h1, h2));

        float d2 = sdEllipsoid(pos1, size2);
        d2 -= bump * size1;
        d2 = min(d2, -bounds);

        d1 = min(d1, d2);
    }

    d1 = max(d1, abs(pos.y) - 2.0 * size.y);
    d1 = max(d1, length(pos - state.origin) - MAX_DIST + 50.0);

    return vec3(d1, MATERIAL_CLOUD, 0.0);
}

vec3 sdBackground(vec3 pos, float time)
{
    vec3 d1 = vec3(MAX_DIST, MATERIAL_SKY, 0.0);
    vec3 d2, pos1;

#ifdef RENDER_MOUNTAINS
    pos1 = pos;
    pos1.xz -= state.origin.xz;
    d2 = sdMountains(pos1);
    d1 = minx(d1, d2);
#endif

#ifdef RENDER_GROUND
    d2 = sdGround(pos);
    d1 = minx(d1, d2);

    d2 = sdPathway(pos);
    d1 = maxx(d1, vec3(-d2.x, d2.yz));
#endif

#ifdef RENDER_CLOUDS
    d2 = sdClouds(pos, time);
    d1 = minx(d1, d2);
#endif

    return d1;
}

vec3 map(vec3 pos, float time, bool shadowPass)
{
    vec3 d1, d2;
    vec3 pos1, pos2;

    d1 = vec3(MAX_DIST, 0.0, 0.0);

    float time1 = time;

    pos1 = pos;
    pos1.y -= getGroundHeight(pos);

    if (!shadowPass)
    {
#ifdef RENDER_GROUND
    d2 = sdGround(pos);
    d1 = minx(d1, d2);

    d2 = sdPathway(pos);
    d1 = maxx(d1, vec3(-d2.x, d2.yz));
#endif

#ifdef RENDER_GRASS
    d2 = sdGrass(pos1, time);
    d1 = minx(d1, d2);
#endif

#ifdef RENDER_FLOWERS
    d2 = sdGrassFlowers(pos1, time);
    d1 = minx(d1, d2);
#endif
    }

#ifdef RENDER_GROUND
    d2 = sdRiverBanks(pos);
    d1 = smin(d1, d2, 0.1);

    d2 = sdPathwayEdges(pos);
    d1 = smin(d1, d2, 0.1);
#endif

#ifdef RENDER_ROCKS
    d2 = sdRocks(pos1, false);
    d1 = minx(d1, d2);

    d2 = sdRiverBanksRocks(pos);
    d1 = minx(d1, d2);
#endif

#ifdef RENDER_TREES
    d2 = sdTrees(pos, time);
    d1 = minx(d1, d2);
#endif

    pos1 = pos;
    pos1.y -= HILL_HEIGHT;

#ifdef RENDER_HOUSE
    d2 = sdHouse(pos1, time);
    d1 = minx(d1, d2);
#endif

    pos1 = pos;
    pos1.y -= 0.4;
    pos1.z -= 50.0;
    pos1.xz *= rotation_n90;

#ifdef RENDER_BRIDGE
    d2 = sdBridge(pos1);
    d1 = minx(d1, d2);

    pos1.x -= 3.3;
    pos1.z -= 0.8;
    d2 = sdMailboxPost(pos1);
    d1 = minx(d1, d2);
#endif

    pos1 = pos;
    pos1 -= HAT_POSITION;
    pos1.xy *= rotation_n90;
    d2 = sdHat(pos1);
    d1 = minx(d1, d2);

    return d1;
}

// objects that are expected to be visible in a reflection
vec3 mapReflection(vec3 pos, float time)
{
    vec3 d1, d2;
    vec3 pos1, pos2;

    d1 = vec3(MAX_DIST, 0.0, 0.0);

#ifdef RENDER_GROUND
    pos1 = pos;

    d2 = sdGround(pos);
    d1 = minx(d1, d2);

    d2 = sdRiverBanks(pos);
    d1 = minx(d1, d2);
#endif

#ifdef RENDER_BRIDGE
    pos1 = pos;
    pos1.y -= 0.4;
    pos1.z -= 50.0;
    pos1.xz *= rotation_n90;
    d2 = sdBridge(pos1);
    d1 = minx(d1, d2);

    pos1.x -= 3.3;
    pos1.z -= 0.8;
    d2 = sdMailboxPost(pos1);
    d1 = minx(d1, d2);
#endif

#ifdef RENDER_ROCKS
    d2 = sdRiverBanksRocks(pos);
    d1 = minx(d1, d2);
#endif

    pos1 = pos;
    pos1 -= HAT_POSITION;
    pos1.xy *= rotation_n90;
    d2 = sdHat(pos1);
    d1 = minx(d1, d2);

#ifdef RENDER_HOUSE_DETAILS
    // well
    pos1 = pos;
    pos1 -= WELL_POSITION;
    pos1.y -= HILL_HEIGHT;
    pos1.xz *= rotation_n145;
    d2 = sdWell(pos1);
    d1 = minx(d1, d2);
#endif

    return d1;
}

// transparent objects
vec2 mapTransparent(vec3 pos, float time)
{
    vec2 d1 = vec2(MAX_DIST, 0.0);
    vec2 d2 = d1;

    vec3 pos1, pos2;

#ifdef RENDER_HOUSE
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;

    pos2 = pos1;
    pos2.xz *= rotation_n93;
    pos2.z -= 3.9;
    pos2.y -= 2.1;
    d2 = sdPorchDoorGlass(pos2);
    d1 = minx(d1, d2);

    pos2 = pos1;
    d2 = sdWindowsGlass(pos2);
    d1 = minx(d1, d2);

    pos2 = pos1;
    pos2 -= vec3y(HOUSE_HEIGHT - 0.2);
    pos2.xz *= rotation_n60;
    pos2 -= vec3(0.0, 1.5, 3.6);
    d2 = sdMoominWindowGlass(pos2, -2.5);
    d1 = minx(d1, d2);
#endif

    d2 = sdWellWater(pos, time);
    d1 = minx(d1, d2);

    d2 = sdRiverWater(pos, time);
    d1 = minx(d1, d2);

#ifdef RENDER_CAKE
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;
    pos1.xz *= rotation_n93;
    pos1 -= vec3(2.0, 0.6, 4.9);

    pos2 = pos1;
    pos2 -= vec3(-0.2, 0.7, -0.2);
    pos2.xz *= rotation_180;
    pos2.xz *= rotation_n10;
    d2 = sdJarGlass(pos2);
    d1 = minx(d1, d2);

    pos2 = pos1;
    pos2.xz *= rotation_n90;
    pos2.xz *= rotation_n7_5;
    pos2.x = abs(pos2.x);
    pos2 -= vec3(0.25, 0.7, 0.2);
    d2 = sdGlassCup(pos2);
    d1 = minx(d1, d2);
#endif

    return d1;
}

// object that affect walk navigation
float mapCollision(vec3 pos, float time)
{
    const float floorHeight = 4.65;
    const float ladderStepHeight = 0.5;

    float d1 = MAX_DIST;
    float d2, d3;
    float r = 0.0;
    vec3 pos1 = pos;
    vec3 pos2, pos3, pos4;

#ifdef RENDER_HOUSE
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;

    // house floors
    pos2 = pos1;
    pos2.y -= 0.5;
    float index = floor(pos2.y / floorHeight + 0.5);
    index = clamp(index, 0.0, 3.0);
    pos2.y -= index * floorHeight;
    r = sdCircle(pos2.xz, index < 3.0 ? 4.0 : 3.8);
    d2 = r;
    d2 = max(0.0, d2);
    d2 = length(vec2(d2, stretchAxis(pos2.y, 0.2)));
    d1 = min(d1, d2);

    // house roof
    pos2 = pos1;
    pos2.y -= HOUSE_HEIGHT - 0.6;
    vec2 p1 = vec2(length(pos2.xz), pos2.y);
    d2 = sdLine(p1, 4.5, 6.3);
    d2 -= 0.1;

    pos2.xz *= rotation_n60;
    pos2.y -= 2.0;
    d3 = sdBoxApprox(pos2, vec3(0.6, 1.0, 3.0), vec3z1); // window opening
    d2 = max(d2, -d3);

    d1 = min(d1, d2);
#endif

#ifdef RENDER_HOUSE_DETAILS
    // porch roof
    pos2 = pos1;
    pos2.xz *= rotation_n93;
    pos2.y -= 6.8;
    pos2.z -= 4.4;

    pos3 = pos2;
    pos3.x = abs(pos3.x);
    pos3.xy *= rotation_n45;
    d2 = sdBoxApprox(pos3, vec3(5.0, 0.1, 2.0));

    pos4 = pos2;
    pos4.yz *= rotation_n30;
    d2 = max(d2, pos4.z);

    d3 = sdBoxApprox(pos4, vec3(4.0, 4.0, 0.1), -vec3z1);
    d3 = max(d3, pos3.y);
    d2 = min(d2, d3);

    d2 = max(d2, -r);
    d1 = min(d1, d2);

    // ladder steps
    pos2 = pos1;
    pos2.xz *= rotation_n60;
    pos2.z -= 4.6;
    index = floor(pos2.y / ladderStepHeight + 0.5);
    index = clamp(index, 9.0, 27.0);
    pos2.y -= index * ladderStepHeight;
    d2 = sdBoxApprox(pos2, vec3(0.5, 0.1, 0.3));
    d1 = min(d1, d2);

    // entrance stairs
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;
    pos1.z -= 6.2;
    d2 = sdEntranceStairs(pos1).x;
    d1 = min(d1, d2);

    // kitchen stairs
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;
    pos1.xz *= rotation_145;
    pos1.z -= 5.25;
    d2 = sdKitchenStairs(pos1).x;
    d1 = min(d1, d2);

    // porch
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;
    pos1.xz *= rotation_n93;
    pos1.z -= 4.3;
    pos2 = pos1;
    d2 = sdBoxApprox(pos2, vec3(3.3, 0.3, 2.0), vec3y1);
    d1 = min(d1, d2);
    pos2.y -= 0.05;
    pos2.z -= 1.5;
    d2 = sdBoxApprox(pos2, vec3(0.8, 0.15, 0.6), vec3z1);
    d1 = min(d1, d2);
    pos2.y -= 0.2;
    d2 = sdBoxApprox(pos2, vec3(0.8, 0.15, 0.4), vec3z1);
    d1 = min(d1, d2);

    // porce steps
    pos2 = pos1;
    pos2.x += 3.0;
    index = floor(pos2.y / ladderStepHeight + 0.5);
    index = clamp(index, 0.0, 6.0);
    pos2.y -= index * ladderStepHeight;
    d2 = sdBoxApprox(pos2, vec3(0.3, 0.1, 1.5));
    d1 = min(d1, d2);

    // basement
    pos1 = pos;
    pos1.y -= HILL_HEIGHT;
    pos1.x += 5.0;
    d2 = sdBoxApprox(pos1, vec3(1.4), vec3y1);
    pos1.y -= 2.1;
    pos1.xy *= rotation_30;
    d2 = max(d2, pos1.y);
    d2 = max(d2, -r);
    d1 = min(d1, d2);
#endif

#ifdef RENDER_BRIDGE
    // bridge
    pos1 = pos;
    pos1.z -= 50.0;
    pos1.y -= 0.4 + 0.95 * smoothstep(3.2, 0.0, pow(abs(pos1.z), 1.2));
    d2 = sdBoxApprox(pos1, vec3(0.8, 0.1, 4.0));
    d1 = min(d1, d2);
#endif

    return d1;
}



vec3 getNormalTransparent(vec3 pos, float time)
{
    vec3 n = vec3(0.0);

    for (int i = 0; i < 4; i++)
    {
        vec3 d = 2.0 * vec3(((i + 3) >> 1) & 1, (i >> 1) & 1, i & 1) - 1.0;
        vec2 d1 = mapTransparent(pos + 0.05 * d, time);

        n += d1.y > 0.0 ? d * d1.x : vec3(0.0);
    }

    return normalize(n);
}

vec3 castRay(vec3 ro, vec3 rd, float time, int maxSteps, bool shadowPass) // ray origin, ray direction
{
    float d = 0.0; // distance from ray origin
    vec2 m = vec2(0.0); // material

    float shadow = 1.0;

    for (int i = 0; i < maxSteps; i++)
    {
        vec3 pos = ro + rd * d; // current position

        vec3 d1 = map(pos, time, shadowPass); // distance from current position to the scene
        marchSteps++;
        m = d1.yz;

        if (shadowPass)
        {
            if (materialCastsShadow(floor(d1.y)))
            {
                shadow = min(shadow, max(0.0, 40.0 * d1.x / d)); // soft shadow
            }

            d1.x = max(d1.x, 0.01);
        }

        d += d1.x;

        if (d > MAX_DIST || abs(d1.x / (d + 1.0)) < SURF_DIST)
        {
            break;
        }
    }
    
    if (shadowPass)
    {
        return vec3(max(1.0 - shadow, 0.0), 0.0, 0.0);
    }

    if (d > MAX_DIST || m.x < 1.0)
    {
        m = vec2(MATERIAL_SKY, 0.0);
        d = MAX_DIST;
    }

    return vec3(d, m);
}

vec3 castRayBackground(vec3 ro, vec3 rd, float time, int maxSteps, float maxDistance) // ray origin, ray direction
{
    float d = 0.0; // distance from ray origin
    vec2 m = vec2(0.0); // material

    int i;
    for (i = 0; i < maxSteps; i++)
    {
        vec3 pos = ro + rd * d; // current position

        vec3 dm = sdBackground(pos, time); // distance from current position to the scene
        d += dm.x;
        m = dm.yz;
        marchSteps++;

        if (d > maxDistance || abs(dm.x / (d + 1.0)) < SURF_DIST)
        {
            break;
        }
    }

    if (d > maxDistance || m.x < 1.0)
    {
        m = vec2(MATERIAL_SKY, 0.0);
        d = MAX_DIST;
    }

    return vec3(d, m);
}


vec3 castRayReflection(vec3 ro, vec3 rd, float time, int maxSteps) // ray origin, ray direction
{
    float d = 0.0; // distance from ray origin
    vec2 m = vec2(0.0); // material

    for (int i = 0; i < maxSteps; i++)
    {
        vec3 pos = ro + rd * d; // current position

        vec3 d1 = mapReflection(pos, time); // distance from current position to the scene
        d += d1.x;
        m = d1.yz;

        marchReflectionSteps++;

        if (d > MAX_DIST || abs(d1.x / (d + 1.0)) < SURF_DIST)
        {
            break;
        }
    }

    if (d > MAX_DIST || m.x < MATERIAL_EMPTY + 1.0)
    {
        m = vec2(MATERIAL_SKY, 0.0);
        d = MAX_DIST;
    }

    return vec3(d, m);
}

vec2 castRayTransparent(vec3 ro, vec3 rd, float time, int maxSteps, float maxDistance)
{
    float d = 0.0;
    float m = 0.0;

    for (int i = 0; i < maxSteps; i++)
    {
        vec3 pos = ro + rd * d;

        vec2 d1 = mapTransparent(pos, time);
        d += d1.x;
        m = d1.y;

        marchTransparentSteps++;

        if (d > maxDistance)
        {
            return vec2(MAX_DIST, 0.0);
        }

        if (abs(d1.x / (d + 1.0)) < SURF_DIST)
        {
            break;
        }
    }

    return vec2(d, m);
}

float castRayCollision(vec3 ro, vec3 rd, float time, int maxSteps) // ray origin, ray direction
{
    float d = 0.0; // distance from ray origin

    for (int i = 0; i < maxSteps; i++)
    {
        vec3 pos = ro + rd * d; // current position

        float d1 = mapCollision(pos, time); // distance from current position to the scene
        d += d1;

        if (d > MAX_DIST || abs(d1 / (d + 1.0)) < SURF_DIST)
        {
            break;
        }
    }

    return min(d, MAX_DIST);
}

float castShadowTransparent(vec3 ro, vec3 rd, float time)
{
    float result = 1.0;
    float d = 0.01; // position

    for (int i = 0; i < 50; i++)
    {
        vec3 pos = ro + d * rd;
        vec2 d1 = mapTransparent(pos, time);

        marchShadowSteps++;

        if (!materialCastsShadow(floor(d1.y)))
        {
            d1.x += 0.01; // skip object
        }
        else
        {
            result = min(result, max(0.0, 40.0 * d1.x / d)); // soft shadow
        }

        d += max(d1.x, 0.01);

        if (abs(d1.x) < (d * 0.001) || d > MAX_DIST)
        {
            break;
        }
    }

    return clamp(1.0 - result, 0.0, 1.0);
}

void getViewAxis(in vec3 origin, in vec3 target, out vec3 viewOrigin, out vec3 viewX, out vec3 viewY, out vec3 viewZ)
{
    origin.y = max(origin.y, getGroundHeight(origin) + MIN_CAMERA_HEIGHT);

    viewOrigin = origin;
    viewZ = normalize(target - origin);
    viewX = normalize(cross(viewZ, vec3(0.0, 1.0, 0.0)));
    viewY = cross(viewX, viewZ);
}

bool isKeyDown(int key)
{
    return keyboardTexture((vec2(0.5) + vec2(float(key), 0.0))).x > 0.5;
}

bool isKeyPressed(int key)
{
    return keyboardTexture((vec2(0.5) + vec2(float(key), 1.0))).x > 0.5;
}

vec2 scaleMouseCoordinate(vec2 coord)
{
    vec2 uv = map01_11(coord / iResolution.xy);
    uv *= state.renderScale;
    return map11_01(uv) * iResolution.xy;
}

vec3 getPosition(vec2 fragCoord)
{
    vec4 t = inputTexture(fragCoord);

    vec2 uv = map01_11(fragCoord / iResolution.xy);
    uv.x *= iResolution.x / iResolution.y;

    float depth = deserializeDepth(getDepthComponent(t));
    vec3 rd = normalize(uv.x * state.viewX + uv.y * state.viewY + FIELD_OF_VIEW * state.viewZ * state.renderScale);

    vec3 pos = state.viewOrigin + depth * rd; // point in scene

    return pos;
}

void getFlyCoordinates(float time, out vec3 origin, out vec3 target)
{
    const float z0 = 10.0; // entrance segment start
    const float z1 = 40.0; // bridge segment end
    const float z2 = 50.0; // bridge
    const float z3 = 100.0; // bridge segment start
    const float depth1 = 0.1;

    time *= smoothstep(0.0, 15.0, time); // slow start

    float z = 62.0 * (1.0 - time * 0.04);

    float center = 6.0 * (sin(z * 0.138 + 0.97) - 1.0);

    center *= smoothstep(z2, z1, z) + smoothstep(z2, z3, z);
    center *= smoothstep(0.0, z0, z);
    float width = 1.0 + 0.1 * (sin(z * 2.0) + 0.5 * sin(z * 5.0));
    width = z < 0.0 ? 0.0 : width;

    float depth = depth1;

    float offset = smoothstep(15.0, 30.0, z);
    vec3 origin1 = vec3(center - offset, 10.0, z);
    origin1.y = mix(max(getGroundHeight(origin1), 0.4), 1.5, smoothstep(3.4, 0.0, abs(z - z2)));
    origin1.y += MOVE_CAMERA_HEIGHT;
    vec3 target1 = vec3(0.0, 18.0, 0.0);

    // phase 2
    float an = -0.8 - 0.5 * time;
    float r = 7.0 + 8.0 * map11_01(sin(-0.54 * time + 4.5));
    float h = HILL_HEIGHT + 1.5 + 16.0 * map11_01(sin(0.18 * time + 0.77));
    vec3 target2 = vec3(0.0, h, 0.0);
    vec3 origin2 = vec3(r * cos(an), h, r * sin(an));

    // phase 3
    an = -2.4 - 0.15 * time;
    r = 25.0 + 40.0 * map11_01(sin(-0.11 * time + 1.9));
    h = HILL_HEIGHT + 11.0 + 0.3 * r * sin(0.07 * time + 0.6);
    float h2 = HILL_HEIGHT + 10.0 + 0.1 * r * sin(0.07 * time + 4.3);

    vec3 target3 = vec3(0.0, h2, 0.0);
    vec3 origin3 = vec3(r * cos(an), h, r * sin(an));

    // mix phases
    float f12 = smoothstep(20.0, 23.0, time);
    float f23 = smoothstep(36.0, 42.0, time);
    origin = mix(origin1, mix(origin2, origin3, f23), f12);
    target = mix(target1, mix(target2, target3, f23), f12);
}

void updateState(vec2 fragCoord, float delta, float time)
{
    bool toggleRenderModeAction = isKeyPressed(KEY_F1);
    bool toggleNavigationModeAction = isKeyPressed(KEY_N);
    bool resetViewAction = isKeyPressed(BUTTON_RIGHT) || isKeyPressed(KEY_R);
    bool scaleUpRenderAction = isKeyPressed(KEY_KP_PLUS) || isKeyPressed(KEY_EQUALS);
    bool scaleDownRenderAction = isKeyPressed(KEY_KP_MINUS) || isKeyPressed(KEY_MINUS);
    bool zoomInAction = isKeyPressed(MOUSE_SCROLL_UP);
    bool zoomOutAction = isKeyPressed(MOUSE_SCROLL_DOWN);
    bool moveLeftAction = isKeyDown(KEY_A);
    bool moveRightAction = isKeyDown(KEY_D);
    bool moveForwardAction = isKeyDown(KEY_W);
    bool moveBackwardAction = isKeyDown(KEY_S);
    bool moveUpAction = isKeyDown(KEY_E);
    bool moveDownAction = isKeyDown(KEY_C);
    bool startDragAction = isKeyPressed(BUTTON_LEFT) || isKeyPressed(BUTTON_MIDDLE) || iMouse.w > 0.0;
    bool dragAction = isKeyDown(BUTTON_LEFT) || isKeyDown(BUTTON_MIDDLE) || iMouse.z > 0.0;
    bool dragZoomModifier = isKeyDown(KEY_CONTROL);
    bool dragPanModifier = isKeyDown(KEY_SHIFT);
    bool moveModifier = isKeyDown(KEY_SHIFT);

    bool isMouseOverViewport = iMouse.x > 0.0 && iMouse.y > 0.0 && iMouse.x < iResolution.x && iMouse.y < iResolution.y;
    bool moveAction = moveLeftAction || moveRightAction || moveForwardAction || moveBackwardAction;

    if (iMouse.z > 0.0 || isKeyPressed(BUTTON_LEFT) || isKeyPressed(BUTTON_MIDDLE) || isKeyPressed(BUTTON_RIGHT))
    {
        state.focused = isMouseOverViewport;
    }

    state.focused = true; // override

    float zoomOffset = 0.0;
    vec3 panOffset = vec3(0.0);
    vec2 swivelOffset = vec2(0.0);

    bool isDragging = length(state.dragStartPosition) > 0.0;
    bool isClicked = isDragging && !dragAction && (time - state.dragStartTime < CLICK_TIME && length(iMouse.xy - state.dragStartPosition) < 20.0);
    if (isClicked)
    {
        state.clickCount = time - state.clickTime > 0.0 && time - state.clickTime < CLICK_TIME ? state.clickCount + 1.0 : 0.0;
        state.clickTime = time;
    }

    if (state.focused)
    {
        if (toggleRenderModeAction)
        {
            state.nextRenderMode = mod(state.renderMode + 1.0, 8.0);
            state.modeAnnotation = vec2(1.0, time);
        }

        if (toggleNavigationModeAction)
        {
            state.navigationMode = mod(state.navigationMode + 1.0, 2.0);
            state.modeAnnotation = vec2(2.0, time);
        }

        if (scaleUpRenderAction)
        {
            state.nextRenderScale = clamp(state.renderScale * 1.1, 0.01, 1.0);
            state.modeAnnotation = vec2(3.0, time);
        }

        if (scaleDownRenderAction)
        {
            state.nextRenderScale = clamp(state.renderScale / 1.1, 0.01, 1.0);
            state.modeAnnotation = vec2(3.0, time);
        }

        if (resetViewAction)
        {
            resetState();
            state.focused = true;
        }

        float moveSpeed = moveModifier ? MOVE_SPEED2 : MOVE_SPEED1;

        if (moveLeftAction)
        {
            panOffset.x = delta * moveSpeed;
        }

        if (moveRightAction)
        {
            panOffset.x = -delta * moveSpeed;
        }

        if (moveForwardAction)
        {
            panOffset.z = -delta * moveSpeed;
        }

        if (moveBackwardAction)
        {
            panOffset.z = delta * moveSpeed;
        }

        if (moveUpAction)
        {
            panOffset.y = -delta * moveSpeed * 0.5;
        }

        if (moveDownAction)
        {
            panOffset.y = delta * moveSpeed * 0.5;
        }
    }

    if (isMouseOverViewport)
    {
        if (zoomInAction)
        {
            zoomOffset = -ZOOM_SCROLL_SPEED;
        }

        if (zoomOutAction)
        {
            zoomOffset = ZOOM_SCROLL_SPEED;
        }

        if (startDragAction)
        {
            state.dragStartTime = time;
            state.dragStartPosition = iMouse.xy;
            state.dragLastPosition = iMouse.xy;
            isDragging = true;
        }
    }

    if (dragAction || moveAction)
    {
        state.targetAnnotation = vec4(0.0);
        state.modeAnnotation = vec2(0.0);
    }

    if (!dragAction)
    {
        state.dragStartPosition = vec2(0.0);
        state.dragLastPosition = vec2(0.0);
        isDragging = false;
    }

    if (isDragging && dragAction)
    {
        vec2 dragOffset = (iMouse.xy - state.dragLastPosition) / iResolution.y;
        state.dragLastPosition = iMouse.xy;

        if (dragZoomModifier && !moveAction)
        {
            zoomOffset = -ZOOM_DRAG_SPEED * sign(dragOffset.y) * 2.0 * length(dragOffset);
        }
        else if (dragPanModifier && !moveAction)
        {
            panOffset = vec3(dragOffset.xy, 0.0);
        }
        else // swivel
        {
            swivelOffset = SWIVEL_SPEED * dragOffset.xy;
        }
    }

    vec3 viewDirection = state.target - state.origin;
    float viewDistance = length(viewDirection);

    vec2 viewRotation = vec2(atan(viewDirection.z, viewDirection.x), atan(viewDirection.y, length(viewDirection.xz)));

    if (state.navigationMode > 1.0) // fly mode (2)
    {
        if (isClicked)
        {
            time = 0.0;
            state.navigationMode = 1.0;
        }

        vec3 origin;
        vec3 target;
        getFlyCoordinates(time, origin, target);
        state.nextOrigin = origin;
        state.nextTarget = target;
    }
    else if (state.navigationMode > 0.0) // walk mode (1)
    {
        vec3 origin = state.origin;

        vec3 d1 = vec3(castRayCollision(origin, vec3y(-1.0), time, MAX_STEPS), 100.0, 0.0);

        float targetHeight = MOVE_CAMERA_HEIGHT + max(getGroundHeight(state.origin), origin.y - d1.x);

        vec3 moveZ = normalize(vec3(state.viewZ.xz, 0.0).xzy);
        vec3 moveY = vec3y(1.0);
        vec3 moveX = cross(moveZ, moveY);
        vec3 targetOffset = panOffset.x * moveX + panOffset.z * moveZ;

        viewRotation += swivelOffset.xy * 0.5;
        viewRotation.y = clamp(viewRotation.y, -PI05 + 0.001, PI05 - 0.001);

        vec3 target = origin + viewDistance * vec3(cos(viewRotation.x) * cos(viewRotation.y), sin(viewRotation.y), sin(viewRotation.x) * cos(viewRotation.y));

        origin -= targetOffset;
        target -= targetOffset;

        targetHeight = clamp(targetHeight, origin.y - MOVE_GRAVITY * delta, origin.y + MOVE_COLLISION * delta);
        target.y += targetHeight - origin.y;
        origin.y = targetHeight;

        // teleport
        if (isClicked && state.clickCount > 0.0) // double click
        {
            vec3 clickPosition = getPosition(scaleMouseCoordinate(iMouse.xy));
            float d1 = length(clickPosition - state.origin);

            if (d1 < 300.0) // exclude mountains and sky
            {
                vec3 pos = clickPosition; // point in scene
                pos.y += MOVE_CAMERA_HEIGHT;
                target += pos - origin;
                origin = pos;
            }
        }

        state.nextOrigin = origin;
        state.nextTarget = target;
    }
    else // inspection mode (0)
    {
        // zoom
        viewDistance *= pow(2.0, zoomOffset);

        // swivel
        viewRotation.xy += swivelOffset;
        viewRotation.y = clamp(viewRotation.y, -PI05 + 0.001, PI05 - 0.001);

        // pan
        vec3 panX = state.viewX;
        vec3 panZ = normalize(vec3(state.viewZ.xz, 0.0).xzy);
        vec3 panY = cross(panX, panZ);
        vec3 targetOffset = viewDistance * (panOffset.x * panX + panOffset.y * panY + panOffset.z * panZ);

        state.nextOrigin = state.target - targetOffset - viewDistance * vec3(cos(viewRotation.x) * cos(viewRotation.y), sin(viewRotation.y), sin(viewRotation.x) * cos(viewRotation.y));
        state.nextTarget = state.target - targetOffset;

        // re-center target
        state.nextTargetOffset *= max(0.0, 1.0 - 0.5 * length(swivelOffset) - length(panOffset) - abs(zoomOffset) - length(panOffset));

        if (isClicked)
        {
            vec3 clickPosition = getPosition(scaleMouseCoordinate(iMouse.xy));
            float d1 = length(clickPosition - state.origin);

            #ifdef RENDER_TRANSPARENCY
                float d2 = castRayTransparent(state.origin, state.viewZ, time, MAX_STEPS, MAX_DIST).x;
                d1 = min(d1, d2);
            #endif

            if (d1 < 100.0) // limit distance
            {
                vec3 target = clickPosition; // point in scene

                state.nextTargetOffset += state.target - target;
                state.nextTarget = target;
                state.targetAnnotation = vec4(iMouse.xy, time, 1.0);

                if (state.clickCount > 0.0) // double click
                {
                    state.nextTargetOffset = vec3(0.0);
                    state.nextOrigin = target - 2.0 * normalize(viewDirection);
                }
            }
        }
    }

    if (length(state.nextOrigin - state.origin) < 0.0001)
    {
        state.nextOrigin = state.origin;
    }

    if (length(state.nextTarget - state.target) < 0.0001)
    {
        state.nextTarget = state.target;
    }
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    deserializeState(iChannel0, iResolution.xy);

    if (!state.initialized)
    {
        resetState();
        state.initialized = true;
        state.nextRenderMode = 0.0;
        state.nextRenderScale = 1.0;
        state.nextOrigin = INITIAL_ORIGIN;
        state.nextTarget = INITIAL_TARGET;
        state.nextTargetOffset = vec3(0.0);
        state.navigationMode = 2.0;
    }

    state.origin = state.nextOrigin;
    state.target = state.nextTarget;
    state.targetOffset = state.nextTargetOffset;
    state.renderMode = state.nextRenderMode;
    state.renderScale = state.nextRenderScale;

    vec3 origin = state.origin;
    vec3 target = state.target + state.targetOffset;

    float time = iTime;

    vec2 uv = map01_11(fragCoord / iResolution.xy);

    if (fragCoord.x < STATE_SIZE && fragCoord.y < 1.0) // state
    {
        float delta = iTimeDelta;

        vec3 origin, rdx, rdy, rdz;
        getViewAxis(state.origin, state.target + state.targetOffset, origin, rdx, rdy, rdz);

        state.viewX = rdx;
        state.viewY = rdy;
        state.viewZ = rdz;
        state.viewOrigin = origin;

        updateState(fragCoord, delta, time);

        fragColor = serializeState(int(floor(fragCoord.x)));
    }
    else if (abs(uv.x) < state.renderScale && abs(uv.y) < state.renderScale)
    {
        // ray direction
        vec3 origin, rdx, rdy, rdz;
        getViewAxis(state.origin, state.target + state.targetOffset, origin, rdx, rdy, rdz);

        uv.x *= iResolution.x / iResolution.y;
        vec3 rd = normalize(uv.x * rdx + uv.y * rdy + FIELD_OF_VIEW * rdz * state.renderScale);
        
        vec3 d1 = vec3(MAX_DIST, 0.0, 0.0);
        float shadow = 0.0;

        for (int i = 0; i < 2; i++)
        {
            bool shadowPass = i == 1;

            vec3 d = castRay(
                shadowPass ? (origin + d1.x * rd + 0.01 * SUN_DIRECTION) : origin,
                shadowPass ? SUN_DIRECTION : rd,
                time,
                shadowPass ? MAX_SHADOW_STEPS : MAX_STEPS,
                shadowPass);

            shadow = d.x;
            d1 = shadowPass ? d1 : d;
        }

        vec3 d2 = castRayBackground(origin, rd, time, MAX_STEPS, d1.x);
        d1 = minx(d1, d2);
        vec3 pos = origin + d1.x * rd; // point in scene

        float tint = 0.0;

        #ifdef RENDER_TRANSPARENCY
            vec2 d3 = castRayTransparent(origin, rd, time, MAX_STEPS, d1.x);

            if (d3.y > 0.0)
            {
                // transparent tint
                tint = d3.y;

                if (materialIsTransparentObject(tint))
                {
                    // override the underlaying object depth with transparent object depth
                    // this affects the outline, but not always desired (for example in cases
                    // where the underlaying objects material is using the position)
                    d1.x = d3.x;
                }

                vec3 pos2 = origin + d3.x * rd; // transparent point in scene
                vec3 n2 = getNormalTransparent(pos2, time); // transparent normal

                // reflection
                if (materialIsTransparentWithReflection(tint) && state.origin.y > 0.0)
                {
                    vec3 r = reflect(rd, n2);
                    vec3 d4 = castRayReflection(pos2, r, time, MAX_STEPS);

                    if (materialIsReflected(d4.y))
                    {
                        tint = floor(d4.y);
                        d1.z += floor(d4.z);
                    }

                    float juiceMask = getRiverJuiceMask(pos2, time);
                    tint = mix(tint, MATERIAL_JUICE, juiceMask);
                    d1.z += juiceMask > 0.0 ? 1.0 : 0.0;
                }
                else if (materialIsTransparent(tint))
                {
                    vec3 r = reflect(rd, n2);
                    //tint += dot(r, SUN_DIRECTION) > 0.8 ? 1.0 : 0.0; // sun reflection
                    tint += sin(d3.x * (r.z + r.x + r.y)) > 0.95 ? 1.0 : 0.0; // simple reflection
                }
            }
        #endif


        #ifdef RENDER_TRANSPARENCY
        #ifdef RENDER_TRANSPARENCY_SHADOW
            shadow += 0.5 * castShadowTransparent(pos, SUN_DIRECTION, time);
        #endif
        #endif

        shadow = d1.y > MATERIAL_SKY ? shadow : 0.0;
        shadow = clamp(shadow, 0.0, 0.99);

        if (state.renderMode == 1.0) // override uv with ray march steps count
        {
            int steps = marchSteps;
            steps += marchTransparentSteps;
            steps += marchReflectionSteps;
            steps += marchShadowSteps;

            d1.z = floor(d1.z) + min(0.99, 0.5 * (float(steps) / float(MAX_STEPS)));
        }
        else if (d1.y >= MATERIAL_GRASS && d1.y < MATERIAL_GRASS + 1.0)
        {
            vec2 rootPos = length(fract(d1.yz)) < 0.0001 ? (pos.xz + 500.0) : fract(d1.yz) * 1000.0; // deserialize root position
            float h = (pos.y - getGroundHeight(pos)) / 0.2;
            d1.y = MATERIAL_GRASS + 0.99 * getGrassShade(rootPos);
            d1.z = 0.9 * clamp(h, 0.0, 1.0);
        }

        fragColor = vec4(serializeDepth(d1.x), d1.y, d1.z, tint + shadow);
    }
}
