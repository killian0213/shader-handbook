// Common (common) — Tetrahedral Voxel Traversal by fizzer
// https://www.shadertoy.com/view/wtfXWB


mat3 rotX(float a)
{
    return mat3(1., 0., 0.,
                0., cos(a), sin(a),
                0., -sin(a), cos(a));
}

mat3 rotY(float a)
{
    return mat3(cos(a), 0., sin(a),
                0., 1., 0.,
                -sin(a), 0., cos(a));
}

mat3 rotZ(float a)
{
    return mat3(cos(a), sin(a), 0.,
                -sin(a), cos(a), 0.,
                0., 0., 1.);
}

void swap(inout vec3 a, inout vec3 b)
{
    vec3 temp = a;
    a = b;
    b = temp;
}

void swap(inout float a, inout float b)
{
    float temp = a;
    a = b;
    b = temp;
}
