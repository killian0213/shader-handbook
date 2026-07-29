// Common (common) — Moominhouse by ytt
// https://www.shadertoy.com/view/dlSSDd

// MIT License

// Common

// ---Render options ---
#define RENDER_GROUND
#define RENDER_MOUNTAINS
#define RENDER_HOUSE
#define RENDER_HOUSE_DETAILS
#define RENDER_BRIDGE
#define RENDER_GRASS
#define RENDER_ROCKS
#define RENDER_TRANSPARENCY
#define RENDER_TREES
#define RENDER_FLOWERS
#define RENDER_CLOUDS
//#define RENDER_CAKE

// include transparent object shadow
//#define RENDER_TRANSPARENCY_SHADOW
// non pixelated scaling
//#define SMOOTH_SCALE
// display state.debug value
//#define DISPLAY_DEBUG_VALUE

#define MAX_STEPS 100
#define MAX_SHADOW_STEPS 40
#define MAX_REFLECTION_STEPS 30
#define MAX_DIST 600.0
#define MAX_DIST_LOG 6.4
#define FIELD_OF_VIEW 1.8
#define SURF_DIST 0.0001
#define BOUNDS_MARGIN 0.2
#define BOUNDS_MARGIN_LARGE 0.4
#define TEXT_SCALE 0.6

// --- Interaction ---
#define ZOOM_DRAG_SPEED 4.0
#define ZOOM_SCROLL_SPEED 0.3
#define MOVE_CAMERA_HEIGHT 1.0
#define MOVE_SPEED1 4.0
#define MOVE_SPEED2 8.0
#define MOVE_GRAVITY 4.0
#define MOVE_COLLISION 6.0
#define SWIVEL_SPEED 5.0
#define CLICK_TIME 0.4
#define MIN_CAMERA_HEIGHT 0.2

// --- Scene parameters ---
const vec3 INITIAL_TARGET = vec3(0.0, 18.0, 0.0); // house
const vec3 INITIAL_ORIGIN = vec3(-1.95, 1.39, 62.0); // bridge entrance
const vec3 SUN_DIRECTION = normalize(vec3(1.0));

// Materials
#define MATERIAL_EMPTY 0.0
#define MATERIAL_SKY 1.0
#define MATERIAL_GRASS 2.0
#define MATERIAL_GRASS_FLOWER1 3.0
#define MATERIAL_GRASS_FLOWER2 4.0
#define MATERIAL_MOUNTAIN 5.0
#define MATERIAL_CLOUD 6.0
#define MATERIAL_OUTER_WALL 7.0
#define MATERIAL_INNER_WALL 8.0
#define MATERIAL_PAINTED_WOOD 9.0
#define MATERIAL_WOOD1 10.0
#define MATERIAL_WOOD2 11.0
#define MATERIAL_WOOD3 12.0
#define MATERIAL_WOOD4 13.0
#define MATERIAL_TILE 14.0
#define MATERIAL_BRICK 15.0
#define MATERIAL_METAL1 16.0
#define MATERIAL_METAL2 17.0
#define MATERIAL_METAL3 18.0
#define MATERIAL_METAL4 19.0
#define MATERIAL_BASE_ROCK 20.0
#define MATERIAL_ROPE 21.0
#define MATERIAL_RIVERBED 22.0
#define MATERIAL_SOIL 23.0
#define MATERIAL_PATHWAY 24.0
#define MATERIAL_PATHWAY_ROCK 25.0
#define MATERIAL_TREE_BRANCH 26.0
#define MATERIAL_TREE_BARK 27.0
#define MATERIAL_STEM 28.0
#define MATERIAL_FLOWER1 29.0
#define MATERIAL_FLOWER2 30.0
#define MATERIAL_HAT 31.0
#define MATERIAL_HAT_RIBBON 32.0
#define MATERIAL_SKIN 33.0
#define MATERIAL_EYE 34.0
#define MATERIAL_PUPIL 35.0
#define MATERIAL_MOUTH 36.0
#define MATERIAL_SCARF 37.0
#define MATERIAL_PORCELIN 38.0
#define MATERIAL_CAKE1 39.0
#define MATERIAL_CAKE2 40.0

// Transparent materials (leave gap for added reflection material)
#define MATERIAL_WINDOW_GLASS 50.0
#define MATERIAL_DOOR_GLASS1 52.0
#define MATERIAL_DOOR_GLASS2 54.0
#define MATERIAL_DOOR_GLASS3 56.0
#define MATERIAL_GLASS1 58.0
#define MATERIAL_GLASS2 60.0
#define MATERIAL_GLASS3 62.0
#define MATERIAL_GLASS4 64.0

// Transparent material with reflection
#define MATERIAL_WATER 68.0
#define MATERIAL_JUICE 70.0

// Materials properties
#define materialHasOutline(m) ((m) > MATERIAL_CLOUD || (m) >= MATERIAL_GRASS_FLOWER1 && (m) <= MATERIAL_GRASS_FLOWER2)
#define materialHasInnerLines(m) ((m) >= MATERIAL_MOUNTAIN)
#define materialFadeOutlines(m) ((m) >= MATERIAL_GRASS && (m) <= MATERIAL_GRASS_FLOWER2)
#define materialFadeInnerLines(m) ((m) != MATERIAL_MOUNTAIN)
#define materialCastsShadow(m) ((m) > MATERIAL_CLOUD && (m) < MATERIAL_WATER)
#define materialReceivesShadow(m) ((m) > MATERIAL_SKY && (m) < MATERIAL_MOUNTAIN || (m) > MATERIAL_CLOUD)
#define materialIsTransparent(m) ((m) >= MATERIAL_WINDOW_GLASS)
#define materialIsTransparentWithReflection(m) ((m) >= MATERIAL_WATER)
#define materialIsTransparentObject(m) (false)
#define materialIsReflected(m) ((m) > MATERIAL_SKY)
#define materialHasGroundBounceLight(m) ((m) > MATERIAL_GRASS && (m) < MATERIAL_SKIN)

// --- Constants ---
#define PI025 0.78539816339
#define PI05 1.57079632679
#define PI075 2.35619449019
#define PI 3.14159265359
#define PI2 6.28318530718

#define map11_01(x) (((x) + 1.0) * 0.5)
#define map01_11(x) ((x) * 2.0 - 1.0)

#define vec2x(x) vec2(x, 0.0)
#define vec2y(y) vec2(0.0, y)
#define vec3x(x) vec3(x, 0.0, 0.0)
#define vec3y(y) vec3(0.0, y, 0.0)
#define vec3z(z) vec3(0.0, 0.0, z)

#define vec2x1 vec2(1.0, 0.0)
#define vec2y1 vec2(0.0, 1.0)
#define vec3x1 vec3(1.0, 0.0, 0.0)
#define vec3y1 vec3(0.0, 1.0, 0.0)
#define vec3z1 vec3(0.0, 0.0, 1.0)

#define KEY_SHIFT 16
#define KEY_CONTROL 17
#define KEY_A 65
#define KEY_C 67
#define KEY_D 68
#define KEY_E 69
#define KEY_N 78
#define KEY_R 82
#define KEY_S 83
#define KEY_W 87
#define KEY_KP_PLUS 107
#define KEY_KP_MINUS 109
#define KEY_F1 112
#define KEY_EQUALS 61
#define KEY_MINUS 173
#define BUTTON_LEFT 245
#define BUTTON_MIDDLE 246
#define BUTTON_RIGHT 247
#define MOUSE_SCROLL_UP 250
#define MOUSE_SCROLL_DOWN 251

#define inputTexture(coord) texture(iChannel0, (coord) / iResolution.xy)
#define inputTextureState(i) texture(iChannel0, vec2(float(i) + 0.5, 0.5) / iResolution.xy)

// --- Serialization ---

// Buffer definition (broken into [whole].[fraction] parts):
//     x: outline.depth
//     y: material.uv_x
//     z: edge.uv_y
//     w: tint.shadow

#define getOutlineComponent(t) floor(t.x)
#define getDepthComponent(t) fract(t.x)
#define getMaterialIndexComponent(t) floor(t.y)
#define getEdgeGroupComponent(t) floor(t.z)
#define getMaterialUvComponent(t) fract(t.yz)
#define getTintIndexComponent(t) floor(t.w)
#define getShadowComponent(t) fract(t.w)

#define setOutlineComponent(t, g) vec4(fract(t.x) + g, t.yzw)
#define serializeDepth(d) clamp(log((d) + 1.0) / MAX_DIST_LOG, 0.0, 0.9999)
#define deserializeDepth(d) (exp((d) * MAX_DIST_LOG) - 1.0)

struct State
{
    bool initialized; // 0 - state initialized
    vec3 origin; // 1 - camera origin
    vec3 target; // 2 - camera target
    vec3 targetOffset; // 3 - camera target offset (when target is set but not centered)
    vec4 targetAnnotation; // 4 - camera target offset (when target is set but not centered)
    vec3 nextOrigin; // 5 - next frame navigated origin
    vec3 nextTarget; // 6 - next frame navigated target
    vec3 nextTargetOffset; // 7
    vec3 viewX; // 8 - camera x axis (cached)
    vec3 viewY; // 9 - camera y axis (cached)
    vec3 viewZ; // 10 - camera z axis (cached)
    vec3 viewOrigin; // 11 - clipped camera origin (above ground)
    float dragStartTime; // 12
    vec2 dragStartPosition; // 13
    vec2 dragLastPosition; // 14 - non applied drag delta start
    float renderMode; // 15
    float renderScale; // 16
    float nextRenderMode; // 17
    float nextRenderScale; // 18
    float navigationMode; // 19
    bool focused; // 20 - viewport was clicked
    float clickTime; // 21
    float clickCount; // 22
    vec2 modeAnnotation; // 23
    vec4 debug; // 24
} state;

#define STATE_SIZE 25.0

void deserializeState(sampler2D iChannel0, vec2 iResolution)
{
    state.initialized = inputTextureState(0).x > 0.0;
    state.origin = inputTextureState(1).xyz;
    state.target = inputTextureState(2).xyz;
    state.targetOffset = inputTextureState(3).xyz;
    state.targetAnnotation = inputTextureState(4);
    state.nextOrigin = inputTextureState(5).xyz;
    state.nextTarget = inputTextureState(6).xyz;
    state.nextTargetOffset = inputTextureState(7).xyz;
    state.viewX = inputTextureState(8).xyz;
    state.viewY = inputTextureState(9).xyz;
    state.viewZ = inputTextureState(10).xyz;
    state.viewOrigin = inputTextureState(11).xyz;
    state.dragStartTime = inputTextureState(12).x;
    state.dragStartPosition = inputTextureState(13).xy;
    state.dragLastPosition = inputTextureState(14).xy;
    state.renderMode = inputTextureState(15).x;
    state.renderScale = inputTextureState(16).x;
    state.nextRenderMode = inputTextureState(17).x;
    state.nextRenderScale = inputTextureState(18).x;
    state.navigationMode = inputTextureState(19).x;
    state.focused = inputTextureState(20).x > 0.0;
    state.clickTime = inputTextureState(21).x;
    state.clickCount = inputTextureState(22).x;
    state.modeAnnotation = inputTextureState(23).xy;
    state.debug = inputTextureState(24);
}

vec4 serializeState(int index)
{
    if (index == 0) return vec4(state.initialized ? 1.0 : 0.0, 0.0, 0.0, 0.0);
    if (index == 1) return vec4(state.origin, 0.0);
    if (index == 2) return vec4(state.target, 0.0);
    if (index == 3) return vec4(state.targetOffset, 0.0);
    if (index == 4) return vec4(state.targetAnnotation);
    if (index == 5) return vec4(state.nextOrigin, 0.0);
    if (index == 6) return vec4(state.nextTarget, 0.0);
    if (index == 7) return vec4(state.nextTargetOffset, 0.0);
    if (index == 8) return vec4(state.viewX, 0.0);
    if (index == 9) return vec4(state.viewY, 0.0);
    if (index == 10) return vec4(state.viewZ, 0.0);
    if (index == 11) return vec4(state.viewOrigin, 0.0);
    if (index == 12) return vec4(state.dragStartTime, 0.0, 0.0, 0.0);
    if (index == 13) return vec4(state.dragStartPosition, 0.0, 0.0);
    if (index == 14) return vec4(state.dragLastPosition, 0.0, 0.0);
    if (index == 15) return vec4(state.renderMode, 0.0, 0.0, 0.0);
    if (index == 16) return vec4(state.renderScale, 0.0, 0.0, 0.0);
    if (index == 17) return vec4(state.nextRenderMode, 0.0, 0.0, 0.0);
    if (index == 18) return vec4(state.nextRenderScale, 0.0, 0.0, 0.0);
    if (index == 19) return vec4(state.navigationMode, 0.0, 0.0, 0.0);
    if (index == 20) return vec4(state.focused ? 1.0 : 0.0, 0.0, 0.0, 0.0);
    if (index == 21) return vec4(state.clickTime, 0.0, 0.0, 0.0);
    if (index == 22) return vec4(state.clickCount, 0.0, 0.0, 0.0);
    if (index == 23) return vec4(state.modeAnnotation, 0.0, 0.0);
    if (index == 24) return vec4(state.debug);

    return vec4(0.0);
}

void resetState()
{
    state.initialized = false;
    state.origin = vec3(0.0);
    state.target = vec3(0.0);
    state.targetOffset = vec3(0.0);
    state.nextOrigin = vec3(0.0);
    state.nextTarget = vec3(0.0);
    state.nextTargetOffset = vec3(0.0);
    state.viewX = vec3(0.0);
    state.viewY = vec3(0.0);
    state.viewZ = vec3(0.0);
    state.viewOrigin = vec3(0.0);
    state.dragStartTime = 0.0;
    state.dragStartPosition = vec2(0.0);
    state.dragLastPosition = vec2(0.0);
    state.renderMode = 0.0;
    state.renderScale = 0.0;
    state.nextRenderMode = 0.0;
    state.nextRenderScale = 0.0;
    state.navigationMode = 0.0;
    state.focused = false;
    state.clickTime = 0.0;
    state.clickCount = 0.0;
    state.modeAnnotation = vec2(0.0);
    state.debug = vec4(0.0);
}

// --- Common functions ---

float smin(float a, float b, float k) // smooth min
{
    k = max(k, 0.001);
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k / 6.0;
}

vec3 smin(vec3 a, vec3 b, float k) // x component smooth min
{
    float x = smin(a.x, b.x, k);
    return vec3(x, a.x <= b.x ? a.yz : b.yz);
}

float smax(float a, float b, float k) // smooth max
{
    k = max(k, 0.001);
    float h = max(k - abs(a - b), 0.0) / k;
    return max(a, b) + h * h * h * k / 6.0;
}

vec3 smax(vec3 a, vec3 b, float k) // x component smooth max
{
    float x = smax(a.x, b.x, k);
    return vec3(x, a.x <= b.x ? b.yz : a.yz);
}

vec2 minx(vec2 a, vec2 b) // x component min
{
    return a.x <= b.x ? a : b;
}

vec3 minx(vec3 a, vec3 b) // x component min
{
    return a.x <= b.x ? a : b;
}

vec2 maxx(vec2 a, vec2 b) // x component max
{
    return a.x >= b.x ? a : b;
}

vec3 maxx(vec3 a, vec3 b) // x component max
{
    return a.x >= b.x ? a : b;
}

mat2 rotation(float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, s, -s, c);
}

mat2 rotationApprox(float angle)
{
    float s = angle - angle * angle * angle / 6.0;
    float c = 1.0 - 0.5 * angle * angle;
    return mat2(c, s, -s, c);
}

float pow2(float value)
{
    return value * value;
}

float stretchAxis(float p, float w)
{
    p += w * 0.5;
    return p - clamp(p, 0.0, w);
}

float stretchAxis(float p, float a, float b)
{
    return p - clamp(p, a, b) + a;
}

vec2 radialMod(vec2 p, float count, out float index)
{
    float angle = atan(p.y, p.x);
    float size = PI2 / count;

    index = angle / size + 0.5;
    angle = (fract(index) - 0.5) * size;

    index = floor(index);
    return vec2(cos(angle), sin(angle)) * length(p.xy);
}

vec4 hexCoordinates(vec2 p, float scale)
{
    // hexagon edge length is 1
    const float a = sqrt(0.75); // hexagon width is 2a
    const float b = sqrt(0.25); // hexagon height is 2b+1

    p /= scale;

    vec2 gridSize = vec2(2.0 * a, 2.0 * (b + 1.0));
    vec2 index = floor(p / gridSize);

    index *= 2.0; // center hexagon has an even index

    vec2 q = p;
    q -= 0.5 * gridSize * (index + 1.0); // center
    vec2 s = sign(q);

    q = vec2(abs(q.x), 0.5 + b - abs(q.y)); // mirror, and flip y
    if (b * q.x > a * q.y) // cell corners, move to previous or next hexagon
    {
        index += s;
    }

    p -= 0.5 * gridSize * (index + 1.0); // center

    p *= scale;

    return vec4(p, index);
}

float lineIntersection(vec2 p, vec2 a, vec2 b)
{
    vec2 v1 = p - a;
    vec2 v2 = b - a;
    float t = dot(v1, v2) / dot(v2, v2);
    return t;
}

// Noise

float hash(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 pos)
{
    vec2 p = floor(pos);
    vec2 f = fract(pos);

    f = f * f * (3.0 - 2.0 * f);

    float n = p.x + 7.0 * p.y;

    return mix(mix(hash(n), hash(n + 1.0), f.x),
               mix(hash(n + 7.0), hash(n + 8.0), f.x), f.y);
}

float noise(vec3 pos)
{
    vec3 p = floor(pos);
    vec3 f = fract(pos);

    f = f * f * (3.0 - 2.0 * f);

    float a = 37.0;
    float b = 19.0;

    float n = p.x + a * p.y + b * p.z;

    float res = mix(mix(mix(hash(n), hash(n + 1.0), f.x),
                        mix(hash(n + a), hash(n + a + 1.0), f.x), f.y),
                    mix(mix(hash(n + b), hash(n + b + 1.0), f.x),
                        mix(hash(n + a + b), hash(n + a + b + 1.0), f.x), f.y), f.z);
    return res;
}

float fbm(vec2 p)
{
    float f = 0.5 * noise(p);
    p *= 2.1; f += 0.25 * noise(p);
    p *= 2.1; f += 0.25 * noise(p);
    return f;
}

float fbm(vec3 p)
{
    float f = 0.5 * noise(p);
    p *= 2.1; f += 0.25 * noise(p);
    return f;
}

vec2 voronoi(vec2 pos)
{
    vec2 p = floor(pos);
    vec2 f = fract(pos);

    vec2 result = vec2(1.0, 0.0);

    for( int i = 0; i < 9; i++)
    {
        vec2 offset = vec2(float(i % 3), float(i / 3)) - 1.0;
        vec2 r = offset - f + hash(p + offset);

        float d = dot(r, r);
        float id = hash(p + offset);

        result = minx(result, vec2(d, id));
    }

    return result;
}


// SDF

float sdLine(vec2 pos, float len)
{
    return length(vec2(max(0.0, abs(pos.x) - len), pos.y));
}

float sdLine(vec2 pos, vec2 a, vec2 b)
{
    float t = lineIntersection(pos, a, b);
    vec2 c = a + clamp(t, 0.0, 1.0) * (b - a);
    return length(pos - c);
}

float sdLine(vec2 pos, float x, float y)
{
    return sdLine(pos, vec2x(x), vec2y(y));
}

float sdCircle(vec2 pos, float r)
{
    return length(pos) - r;
}

float sdTriangle(vec2 p, float r)
{
    const float m = 1.7320508075; //sqrt(3.0);

    float h = m * r;

    p.x = abs(p.x);
    p.y += h / 3.0;

    // edge line is y = h-m*x
    // perpendicular line is y = c+x/m
    // intersection point is (a,b)
    float c = p.y - p.x / m;
    float a = m * (h - c) / 4.0;
    a = clamp(a, 0.0, r);
    float b = h - m * a;

    float d = length(p - vec2(a, b)); // distance from side edge
    d = p.x < r ? min(d, abs(p.y)) : d; // distance from base edge
    d = p.y > 0.0 && p.y < b ? -d : d; // sign

    return d;
}

float sdRectangle(vec2 pos, vec2 size)
{
   vec2 d = abs(pos) - size;
   return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdRectangle(vec2 pos, vec2 size, vec2 thickness)
{
   vec2 d = abs(pos) - size;
   return length(max(d, 0.0)) - min(max(d.x + thickness.x, d.y + thickness.y), 0.0);
}

float sdRectangleApprox(vec2 pos, vec2 size)
{
    vec2 d = abs(pos) - size;
    return max(d.x, d.y);
}

float sdRoundedRectangle(vec2 pos, vec2 size, vec4 r)
{
    r.xy = pos.x < 0.0 ? r.zw : r.xy;
    r.x  = pos.y < 0.0 ? r.y : r.x;
    vec2 q = abs(pos) - size + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float sdHexApprox(vec2 p, float scale)
{
      // hex edge length is 1
    const float a = sqrt(0.75); // hex width is 2a
    const float b = sqrt(0.25); // hex height is 2b+1
    const float m = b / a; // slope

    p /= scale;

    float y = 0.5 + b - m * abs(p.x);
    float h = abs(p.y) - y;

    float d1 = a * h;
    float d2 = abs(p.x) - a;
    d1 = max(d1, d2);

    d1 *= scale;

    return d1;
}

float sdEllipse(vec2 pos, vec2 rad)
{
    float k0 = length(pos / rad);
    float k1 = length(pos / rad / rad);
    return k0 * (k0 - 1.0) / k1;
}

float sdSurface(vec3 pos)
{
    return pos.y;
}

float sdSphere(vec3 pos, float rad)
{
    return length(pos) - rad;
}

float sdEllipsoid(vec3 pos, vec3 rad)
{
    float k0 = length(pos / rad);
    float k1 = length(pos / rad / rad);
    return k0 * (k0 - 1.0) / k1;
}

float sdBox(vec3 pos, vec3 size)
{
    vec3 d = abs(pos) - size;
    return length(max(d, 0.0)) + min(max(max(d.x, d.y), d.z), 0.0);
}

float sdBox(vec3 pos, vec3 size, vec3 origin, float bevel)
{
    return sdBox(pos - origin * size, size - bevel) - bevel;
}

float sdBoxApprox(vec3 pos, vec3 size)
{
    vec3 d = abs(pos) - size;
    return max(max(d.x, d.y), d.z);
}

float sdBoxApprox(vec3 pos, vec3 size, vec3 origin)
{
    return sdBoxApprox(pos - origin * size, size);
}

float sdBoxFlatBevel(vec3 pos, vec3 size, float bevel)
{
    const float a = 0.70710678;
    const float b = 0.54690282;

    pos = abs(pos);
    size -= bevel;

    float d = pos.x - size.x;
    d = max(d, pos.y - size.y);
    d = max(d, pos.z - size.z);
    d = max(d, a * (pos.x + pos.y - size.x - size.y));
    d = max(d, a * (pos.x + pos.z - size.x - size.z));
    d = max(d, a * (pos.y + pos.z - size.y - size.z));
    d = max(d, b * (pos.x + pos.y + pos.z - size.x - size.y - size.z));

    d -= bevel;

    return d;
}

float sdArc(vec3 pos, float len, float angle, float width, float taper)
{
    angle = map01_11(step(0.0, angle)) * max(abs(angle), 0.01);

    // parameters
    vec2 sc = vec2(sin(angle), cos(angle));
    float ra = 0.5 * len / angle;

    // recenter
    pos.x -= ra;

    // reflect
    vec2 q = pos.xy - 2.0 * sc * max(0.0, dot(sc, pos.xy));

    float u = abs(ra) - length(q);
    float d2 = (q.y < 0.0) ? dot(q + vec2(ra, 0.0), q + vec2(ra, 0.0)) : u * u;
    float s = sign(angle);

    float t = (pos.y > 0.0) ? atan(s * pos.y, -s * pos.x) * ra : (s * pos.x < 0.0) ? pos.y : len - pos.y;
    width = max(0.001, width - t * taper);

    return sqrt(d2 + pos.z * pos.z) - width;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
  vec3 pa = p - a;
  vec3 ba = b - a;
  float h = clamp( dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

  return length(pa - ba * h) - r;
}

float sdPlane(vec3 pos, vec3 size)
{
    float t = lineIntersection(pos.xy, vec2(0.0, 0.0), size.xy);
    vec3 c = vec3(size.xy * clamp(t, 0.0, 1.0), clamp(pos.z, 0.0, size.z)); // closest point
    return length(pos - c);
}

