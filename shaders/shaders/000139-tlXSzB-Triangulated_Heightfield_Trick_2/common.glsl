// Common (common) — Triangulated Heightfield Trick 2 by fizzer
// https://www.shadertoy.com/view/tlXSzB

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

float area(vec3 a,vec3 b,vec3 c)
{
   b-=a;
   c-=a;
   return length(cross(b,c))/2.;
}

