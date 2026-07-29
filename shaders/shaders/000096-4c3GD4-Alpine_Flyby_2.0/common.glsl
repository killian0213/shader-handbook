// Common (common) — Alpine Flyby 2.0 by loicvdb
// https://www.shadertoy.com/view/4c3GD4

#define TREE_HEIGHT 0.015
#define AMBIENT_COL (vec3(.8, 1.3, 2.3) * 0.8)
#define LIGHT_COL vec3(1.7)
#define LIGHT_DIR normalize(vec3(1.0, 1.0, 1.0))
#define TREE_VOLUME_DENSITY 500.0
#define TREE_STEP_SIZE (0.8 / TREE_VOLUME_DENSITY)
#define CLOUD_DENSITY 15.0
#define CAM_POS vec3(0.0, -0.1, 2.0)
#define CAM_FLENGTH 1.3

mat3 rotation(float time)
{
    vec2 rot = vec2(0.7, time * 0.1);
    
    vec2 c = cos(rot);
    vec2 s = sin(rot);
    
    mat3 rx = mat3(1, 0, 0, 0, c.x, s.x, 0, -s.x, c.x);
    mat3 rz = mat3(c.y, -s.y, 0, s.y, c.y, 0, 0, 0, 1);
    
    return rz * rx;
}

float cloudSdf(vec4 h, vec3 p)
{
    float t = h.w * 1.1 + 0.08;
    float b = h.w * 0.3 + 0.13 + 0.012 * sin(dot(p.xy, vec2(16.0, -32.0)));
    
    return max(b - p.z, p.z - t);
}