// Image (image) — Fidget Cube by TheBen27
// https://www.shadertoy.com/view/M3sXDS

#define MAX_DEPTH 8.0
#define CUBE_COUNT 8
#define SPEED 2.0

const float minDepth = 0.01;
const float matchEps = 0.0001;

// Global vars
float time;
// For some reason, making this a global variable is good for performance,
// despite the fact that shaders don't have a stack. Maybe this array is
// copied into inner functions?
mat4[CUBE_COUNT] transforms;
float shapeFactor;

float snapping(float a, float b, float t) {
    t = clamp(t, a, b);
    t = (t - a) / (b - a);
    t = clamp(t * 2.0, 0.0, 1.0);
    
    float s = step(0.5, t);
    float ta = pow(t * 2.0, 2.0) * 0.5;
    float tb = 0.5 + pow(max(0.0, t * 2.0 - 1.0), 0.5) * 0.5;
    t = mix(ta, tb, s);
    
    return t;
}

float beat() {
    return mod(time * SPEED, 8.0);
}

mat4[CUBE_COUNT] cubeTransforms() {
    
    // 120BPM
    float time = beat();

    mat4 preT = translate(vec3(0.25, -0.25, -0.25));
    
    mat4 mats[CUBE_COUNT];
    mats[0] = rotY(0.0) * preT;
    mats[1] = rotY(PI / 2.0) * preT;
    mats[2] = rotY(PI) * preT;
    mats[3] = rotY(PI * 3.0 / 2.0) * preT;
    mat4 sy = translate(vec3(0.0, -1.0, 0.0)) * rotX(PI);
    mats[4] = sy * mats[0];
    mats[5] = sy * mats[1];
    mats[6] = sy * mats[2];
    mats[7] = sy * mats[3];
    
    // first folding out
    float s1 = snapping(0.0, 1.0, time);
    mat4 t1 = translate(vec3(0.0, -s1 * 0.5, 0.0));
    mat4 r1 = t1 * rotX(s1 * PI / 2.0);
    mat4 r1i = t1 * rotX(-s1 * PI / 2.0);
    mats[0] = r1i * mats[0];
    mats[1] = r1  * mats[1];
    mats[2] = r1  * mats[2];
    mats[3] = r1i * mats[3];
    mats[4] = r1  * mats[4];
    mats[5] = r1i * mats[5];
    mats[6] = r1i * mats[6];
    mats[7] = r1  * mats[7];
    
    // second folding
    float s2 = snapping(1.0, 2.0, time);
    mat4 t2 = translate(vec3(0.0, -s2 * 0.5, 0.0));
    mat4 r2 = t2 * rotZ(s2 * PI / 2.0);
    mat4 r2i = t2 * rotZ(-s2 * PI / 2.0);
    mats[0] = r2i *  mats[0];
    mats[1] = r2i * mats[1];
    mats[2] = r2  * mats[2];
    mats[3] = r2  * mats[3];
    mats[4] = r2i * mats[4];
    mats[5] = r2i * mats[5];
    mats[6] = r2  * mats[6];
    mats[7] = r2  * mats[7];
    
    // third folding
    float s3 = snapping(2.0, 3.0, time);
    mat4 t3 = translate(vec3(0.0, -s3 * 0.5, 0.0));
    mat4 r3 = t3 * translate(vec3(0.0, 0.0, 0.5)) * rotX(s3 * PI) * translate(vec3(0.0, 0.0, -0.5));
    mat4 r3i = t3 * translate(vec3(0.0, 0.0, -0.5)) * rotX(-s3 * PI) * translate(vec3(0.0, 0.0, 0.5));
    mats[0] = t3  *  mats[0];
    mats[1] = t3  * mats[1];
    mats[2] = t3  * mats[2];
    mats[3] = t3  * mats[3];
    mats[4] = r3  * mats[4];
    mats[5] = r3i * mats[5];
    mats[6] = r3i * mats[6];
    mats[7] = r3  * mats[7];
    
    // TODO can get rid of remaining foldings
    
    // fourth folding
    float s4 = snapping(4.0, 5.0, time);
    mat4 t4 = translate(vec3(0.0, -s4 * 0.5, 0.0));
    mat4 r4 = t4 * rotZ(s4 * PI / 2.0);
    mat4 r4i = t4 * rotZ(-s4 * PI / 2.0);
    mats[0] = r4i * mats[0];
    mats[1] = r4i * mats[1];
    mats[2] = r4 * mats[2];
    mats[3] = r4 * mats[3];
    mats[4] = r4i * mats[4];
    mats[5] = r4i * mats[5];
    mats[6] = r4 * mats[6];
    mats[7] = r4 * mats[7];
    

    // fifth folding
    float s5 = snapping(5.0, 6.0, time);
    mat4 t5 = translate(vec3(0.0, -s5 * 0.5, 0.0));
    mat4 r5 = t5 * rotX(s5 * PI / 2.0);
    mat4 r5i = t5 * rotX(-s5 * PI / 2.0);
    mats[0] = r5i * mats[0];
    mats[1] = r5 * mats[1];
    mats[2] = r5 * mats[2];
    mats[3] = r5i * mats[3];
    mats[4] = r5 * mats[4];
    mats[5] = r5i * mats[5];
    mats[6] = r5i * mats[6];
    mats[7] = r5 * mats[7];
    
    // sixth and final folding
    float s6 = snapping(6.0, 7.0, time);
    mat4 t6 = translate(vec3(0.0, -s6 * 0.5, 0.0));
    mat4 r6 = t6 * translate(vec3(-0.5, 0.0, 0.0)) * rotZ(s6 * PI) * translate(vec3(0.5, 0.0, 0.0));
    mat4 r6i = t6 * translate(vec3(0.5, 0.0, 0.0)) * rotZ(-s6 * PI) * translate(vec3(-0.5, 0.0, 0.0));
    mats[0] = r6i * mats[0];
    mats[1] = r6i * mats[1];
    mats[2] = r6 * mats[2];
    mats[3] = r6 * mats[3];
    mats[4] = t6 * mats[4];
    mats[5] = t6 * mats[5];
    mats[6] = t6 * mats[6];
    mats[7] = t6 * mats[7];
    
    // spin every fourth beat
    mat4 spin = rotY(
        PI * 0.5 * (snapping(7.0, 8.0, time) + snapping(3.0, 4.0, time))
    );
    mats[0] = spin * mats[0];
    mats[1] = spin * mats[1];
    mats[2] = spin * mats[2];
    mats[3] = spin * mats[3];
    mats[4] = spin * mats[4];
    mats[5] = spin * mats[5];
    mats[6] = spin * mats[6];
    mats[7] = spin * mats[7];
    
    return mats;
}

vec2 sceneSDF(vec3 pos) {
    vec2 sm = vec2(MAX_DEPTH, 0.0);
    vec4 p = vec4(pos, 1.0);
    
    for (int i = 0; i < CUBE_COUNT; i++) {
        float tri = sdTriBox((p * transforms[i]).xyz);
        float cir = sdCircleBox((p * transforms[i]).xyz);
        float mixed = mix(tri, cir, shapeFactor);
        if (mixed < sm.x) {
            sm.x = mixed;
            sm.y = float(i);
        }
    }
    return sm;
}

vec3 sceneNormal( in vec3 p)
{
    const float h = 0.001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*sceneSDF( p + k.xyy*h).x + 
                      k.yyx*sceneSDF( p + k.yyx*h).x + 
                      k.yxy*sceneSDF( p + k.yxy*h).x + 
                      k.xxx*sceneSDF( p + k.xxx*h).x );
}

bool intersectPlane(vec3 normal, vec3 planeOrigin, vec3 eye, vec3 dir, out float dist)
{
    eye.y = -eye.y;
    dir.y = -dir.y;
    // Assuming vectors are all normalized
    float denom = dot(normal, dir);
    if (denom > 1e-6) {
        vec3 p0l0 = planeOrigin - eye;
        dist = dot(p0l0, normal) / denom; 
        return (dist >= 0.0);
    }

    return false;
}

bool intersectFloor(float height, vec3 eye, vec3 dir, out float t) {
    return intersectPlane(vec3(0.0, 1.0, 0.0), vec3(0.0, height, 0.0), eye, dir, t);
}

vec2 intersectAABB(vec3 rayOrigin, vec3 rayDir, vec3 boxMin, vec3 boxMax) {
    vec3 tMin = (boxMin - rayOrigin) / rayDir;
    vec3 tMax = (boxMax - rayOrigin) / rayDir;
    vec3 t1 = min(tMin, tMax);
    vec3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
    return vec2(tNear, tFar);
}

vec2 getDepthAndMaterial(vec3 eye, vec3 dir) {
    // AABB check
    vec2 boxCheck =
        intersectAABB(
            eye,
            dir,
            vec3(-0.75, -0.25, -1.25),
            vec3(0.75, 1.25, 1.25)
    );
    if (boxCheck.x > boxCheck.y) {
        return vec2(MAX_DEPTH, 0.0);
    }

    float depth = boxCheck.x;
    float sdf = matchEps;
    float mat = 0.0;
    for (int steps = 0;
         sdf >= matchEps && depth < MAX_DEPTH && steps < 40;
         steps++) {
        vec2 sdf = sceneSDF(eye + depth * dir);
        depth += sdf.x;
        mat = sdf.y;
    }
    depth = min(depth, MAX_DEPTH);
    
    return vec2(depth, mat);
}

float occ( in vec3 p, in vec3 n)
{
    const float maxDist = 0.5;
    const float falloff = 1.0;
    const int nbIte = 8;
    const float nbIteInv = 1./float(nbIte);
    const float rad = 1.-1.*nbIteInv; //Hemispherical factor (self occlusion correction)

    float ao = 0.0;

    for( int i=0; i<nbIte; i++ )
    {
        float l = rand(float(i))*maxDist;
        vec3 rd = normalize(n+randomHemisphereDir(n, l )*rad)*l; // mix direction with the normal for self occlusion problems!

        ao += (l - max(sceneSDF( p + rd).x,0.)) / maxDist * falloff;
    }

    return clamp( 1.-ao*nbIteInv, 0., 1.);
}

vec3 getTexCoords(vec3 pos, float mat) {
    vec4 p = vec4(pos, 1.0);
    return (p * transforms[int(mat)]).xyz;
}

// surprisingly acceptable for something so simple
vec2 boxMapping(vec3 tc, vec3 norm) {
    vec2 uvTop = tc.xz;
    vec2 uvRight = tc.zy;
    vec2 uvFront = tc.xy;
    float weightTop = abs(norm.y);
    float weightRight = abs(norm.x);
    float weightFront = abs(norm.z);
    float totalWeights = weightTop + weightRight + weightFront;
    
    return (uvTop * weightTop + uvRight * weightRight + uvFront * weightFront) / totalWeights;
}

vec3 textureAt(vec3 tc, vec3 norm, float mat) {
    norm = (vec4(norm, 0.0) * transforms[int(mat)]).xyz;
    
    // box mapping
    vec2 uv = boxMapping(tc, norm);
    
    vec3 color;
    
    // outside faces:
    // (0, 0, 1)
    // (0, -1, 0)
    // (-1, 0, 0)
    float isOutside = step(0.9, dot(norm, vec3(-1.0, -1.0, 1.0)));
    
    // base colors
    float checker = step(mod(mat, 2.0), 0.99);
    vec3 outside = mix(
        vec3(1.0, 0.5, 0.9), // pink
        vec3(0.5, 0.7, 0.8), // blue
        checker
    );
    vec3 inside = mix(
        vec3(0.8, 0.2, 0.2), // red
        vec3(0.2, 0.8, 0.2), // green
        checker
    );
    color = mix(inside, outside, isOutside);
    
    // add an edge outline
    
    // "snap" the normal vector to the nearest cardinal direction
    // not sure if there's a better way to do this...
    // bias the snap based on what side of the cube's diagonal we're on
    // this makes the diagonal side look right
    float bias = sign(-tc.x - tc.z) * 0.001;
    vec3 snorm;
    
    if (abs(norm.x) + bias > abs(norm.y) && abs(norm.x) + bias > abs(norm.z)) {
        snorm = vec3(sign(norm.x), 0.0, 0.0);
    } else if (abs(norm.y) + bias > abs(norm.z)) {
        snorm = vec3(0.0, sign(norm.y), 0.0);
    } else {
        snorm = vec3(0.0, 0.0, sign(norm.z));
    }
    
    // proj a onto b = dot(a, b) / dot(b, b) * b
    // since |b| = 1...
    vec3 p = dot(tc, snorm) * snorm;
    vec3 r = tc - p;
    float boxDist = max(abs(r.x), max(abs(r.y), abs(r.z)));
    float edgeHighlight = smoothstep(0.24, 0.25, boxDist);
    
    // apply edge highlight
    color = mix(color, vec3(1.0, 0.8, 0.9), edgeHighlight);
    
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{   
    vec2 uv = fragCoord/iResolution.xy;
    if (iMouse.z > 0.0) {
        time = 4.0 * iMouse.x / iResolution.x;
    } else {
        ivec2 t = ivec2(mod(fragCoord, vec2(textureSize(iChannel3, 0))));
        time = iTime - 0.5 * texelFetch(iChannel3, t, 0).r * iTimeDelta; 
    }
 
    float shape1 = snapping(3.0, 4.0, mod(beat(), 4.0));
    shapeFactor = beat() > 4.0 ? (1.0 - shape1) : shape1;
 
    vec3 eye, dir;
    uv -= 0.5;
    uv.x *= iResolution.x / iResolution.y;
    
    float dist = -2.5;
    mat2 rx = rot(PI / 6.5);
    mat2 ry = rot(PI / 4.0);
    eye = vec3(0.0, 0.25, dist);
    eye.yz *= rx;
    eye.xz *= ry;
    dir = normalize(vec3(uv, 1.0));
    dir.yz *= rx;
    dir.xz *= ry;
   
    vec3 col = vec3(1.0, 1.0, 0.0);
    
    // it looks like we do something wrong here...
    transforms = cubeTransforms();
    
    vec2 sdf = getDepthAndMaterial(eye, dir);
    float depth = sdf.x;
    float mat = sdf.y;
    
    if (depth >= MAX_DEPTH) {
        float dist;
        bool hitFloor = intersectFloor(0.0, eye, dir, dist);
        if (hitFloor) {
            depth = dist;
            mat = -1.0;
        }
    }
    
    if (depth < MAX_DEPTH || mat == -1.0) {
        vec3 pos = eye + dir * depth;
        vec3 norm;
        
        if (mat < 0.0) {
            norm = vec3(0.0, 1.0, 0.0);
            col = vec3(1.0);
        } else {
            // texture
            norm = sceneNormal(pos);
            vec3 color = textureAt(getTexCoords(pos, mat), norm, mat);
            col = color;
        }
        pos += norm * 0.001;
        
        // diffuse light
        col *= texture(iChannel0, norm).rgb;

        // specular highlights
        float fresnel = 0.8 * fresnelFactor(1.2, dir, norm);
        float spec = texture(iChannel0, reflect(dir, norm)).a;
        col = mix(col, vec3(spec), max(0.0, fresnel));
        
        float occ = occ(pos, norm);
        occ *= occ;
        col *= occ;
        
    } else {
        col = sky(dir);
    }

    // Output to screen
    fragColor = vec4(sqrt(Tonemap_ACES(col * 0.8)),1.0);
}
