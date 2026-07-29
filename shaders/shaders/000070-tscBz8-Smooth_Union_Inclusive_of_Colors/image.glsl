// Image (image) — Smooth Union Inclusive of Colors by oneshade
// https://www.shadertoy.com/view/tscBz8

/*
This shader uses my Raymarcher Template shader (https://www.shadertoy.com/view/3styDs).

I've replaced the sdCuboid() and sdCylinder() distance functions with the exact ones
from Inigo Quilez's 3D distance functions article (https://iquilezles.org/articles/distfunctions)
for nicer blending.
*/

// Default (background) color:
vec3 backgroundColor = vec3(0.0, 0.0, 0.0);

// Light variables:
vec3 lightDirection = vec3(-0.58, 0.58, 0.58);
vec3 lightColor = vec3(1.0, 1.0, 1.0);

// Camera variables:
vec3 cameraPosition = vec3(0.0, 0.0, 1000.0);
vec3 cameraRight = vec3(1.0, 0.0, 0.0);
vec3 cameraUp = vec3(0.0, 1.0, 0.0);
vec3 cameraForward = vec3(0.0, 0.0, -1.0);
float cameraFocalLength = 400.0;

// Ray marching constants:
const vec3 GRADIENT_STEP = vec3(0.001, 0.0, 0.0);
const float MAX_TRACE_DISTANCE = 2000.0;
const float MIN_HIT_DISTANCE = 0.001;
const int MAX_STEPS = 500;

// Raymarching structures:
struct Ray {
    vec3 origin;
    vec3 direction;
};

struct Surface {
    vec3 ambientColor;
    vec3 diffuseColor;
    vec3 specularColor;
    float shininess;
    float signedDistance;
};

// Signed Distance Functions (SDFs):
float sdCuboid(in vec3 p, in float h, in float w, in float d) {
    vec3 q = abs(p) - 0.5 * vec3(w, h, d);
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdCylinder(in vec3 p, in float h, in float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, 0.5 * h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

// Constructive Solid Geometry (CSG) Operators:
Surface SmoothUnion(in Surface surface1, in Surface surface2, in float smoothness) {
    float interpolation = clamp(0.5 + 0.5 * (surface2.signedDistance - surface1.signedDistance) / smoothness, 0.0, 1.0);
    return Surface(mix(surface2.ambientColor, surface1.ambientColor, interpolation),// - smoothness * interpolation * (1.0 - interpolation);
                   mix(surface2.diffuseColor, surface1.diffuseColor, interpolation),// - smoothness * interpolation * (1.0 - interpolation);
                   mix(surface2.specularColor, surface1.specularColor, interpolation),// - smoothness * interpolation * (1.0 - interpolation);
                   mix(surface2.shininess, surface1.shininess, interpolation),// - smoothness * interpolation * (1.0 - interpolation);
                   mix(surface2.signedDistance, surface1.signedDistance, interpolation) - smoothness * interpolation * (1.0 - interpolation));
}

// Transformations:
vec3 Translate(in vec3 p, in vec3 t) {
    return p - t;
}

vec3 Rotate(in vec3 p, in vec3 r) {
    vec3 rad = radians(-r);
    vec3 cosRad = cos(rad);
    vec3 sinRad = sin(rad);

    mat3 xRotation = mat3(1.0,      0.0,       0.0,
                          0.0, cosRad.x, -sinRad.x,
                          0.0, sinRad.x,  cosRad.x);

    mat3 yRotation = mat3( cosRad.y, 0.0, sinRad.y,
                                0.0, 1.0,      0.0,
                          -sinRad.y, 0.0, cosRad.y);

    mat3 zRotation = mat3(cosRad.z, -sinRad.z, 0.0,
                          sinRad.z,  cosRad.z, 0.0,
                               0.0,       0.0, 1.0);

    return zRotation * yRotation * xRotation * p;
}

// Scene mapping function:
Surface mapScene(in vec3 p) {
    vec4 metashapeInfo1 = vec4(vec2(sin(iTime * 0.75), cos(iTime * 1.0)) * 200.0, 0.0, 80.0);
    vec4 metashapeInfo2 = vec4(vec2(cos(iTime * 1.0), cos(iTime * 1.25)) * 200.0, 0.0, 100.0);
    vec4 metashapeInfo3 = vec4(vec2(sin(iTime * 1.25), cos(iTime * 0.5)) * 200.0, 0.0, 120.0);

    Surface metashape1 = Surface(vec3(0.0, 0.0, 0.0),
                                 vec3(1.0, 0.0, 0.0),
                                 vec3(1.0, 1.0, 1.0), 8.0,
                                 sdCuboid(Rotate(Translate(p, metashapeInfo1.xyz), vec3(0.0, 0.0, iTime * 40.0)), 2.0 * metashapeInfo1.w, 2.0 * metashapeInfo1.w, 2.0 * metashapeInfo1.w) - 10.0);

    Surface metashape2 = Surface(vec3(0.0, 0.0, 0.0),
                                 vec3(0.0, 1.0, 0.0),
                                 vec3(1.0, 1.0, 1.0), 64.0,
                                 sdCylinder(Rotate(Translate(p, metashapeInfo2.xyz), vec3(0.0, 0.0, iTime * -20.0)), 2.0 * metashapeInfo2.w, metashapeInfo2.w) - 10.0);

    Surface metashape3 = Surface(vec3(0.0, 0.0, 0.0),
                                 vec3(0.0, 0.0, 1.0),
                                 vec3(0.0, 0.0, 0.0), 0.0,
                                 sdSphere(Translate(p, metashapeInfo3.xyz), metashapeInfo3.w));

    return SmoothUnion(metashape1, SmoothUnion(metashape2, metashape3, 70.0), 70.0);
}

// Normal calculation function (using gradient):
vec3 calculateNormal(in vec3 p) {
    float gradientX = mapScene(p + GRADIENT_STEP.xyy).signedDistance - mapScene(p - GRADIENT_STEP.xyy).signedDistance;
    float gradientY = mapScene(p + GRADIENT_STEP.yxy).signedDistance - mapScene(p - GRADIENT_STEP.yxy).signedDistance;
    float gradientZ = mapScene(p + GRADIENT_STEP.yyx).signedDistance - mapScene(p - GRADIENT_STEP.yyx).signedDistance;
    return normalize(vec3(gradientX, gradientY, gradientZ));
}

// Surface shader (uses the Phong illumination model):
vec3 shadeSurface(in Surface surface, in Ray ray, in vec3 normal) {
    vec3 illuminationAmbient = surface.ambientColor * lightColor;
    float lambertian = max(0.0, dot(normal, lightDirection));
    vec3 illuminationDiffuse = lambertian * surface.diffuseColor * lightColor;
    vec3 reflection = reflect(lightDirection, normal);
    float specularAngle = max(0.0, dot(reflection, ray.direction));
    vec3 illuminationSpecular = clamp(pow(specularAngle, surface.shininess), 0.0, 1.0) * surface.specularColor * lightColor;
    return illuminationAmbient + illuminationDiffuse + illuminationSpecular;
}

// Raymarching loop:
vec4 rayMarch(in Ray ray) {
    float distanceTraveled = 0.0;
    for (int iterations=0; iterations < MAX_STEPS; ++iterations) {
        vec3 currentPosition = ray.origin + ray.direction * distanceTraveled;
        Surface sceneSurface = mapScene(currentPosition);
        if (abs(sceneSurface.signedDistance) < MIN_HIT_DISTANCE) {
            vec3 normal = calculateNormal(currentPosition);
            vec3 color = shadeSurface(sceneSurface, ray, normal);
            return vec4(color, 1.0);
        }

        if (distanceTraveled > MAX_TRACE_DISTANCE) {
            break;
        }

        distanceTraveled += sceneSurface.signedDistance;
    }

    return vec4(backgroundColor, 1.0);
}

// Pixel shader output function:
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 halfResolution = 0.5 * iResolution.xy;
    vec2 xy = fragCoord - halfResolution;
    vec3 rayOrigin = cameraPosition + cameraForward * cameraFocalLength;
    vec3 rayDirection = normalize(rayOrigin - (cameraPosition - cameraRight * xy.x - cameraUp * xy.y));
    fragColor = rayMarch(Ray(rayOrigin, rayDirection));
    fragColor = pow(fragColor, vec4(1.0 / 2.2));
}