// Image (image) — Quadric Quadtree by paniq
// https://www.shadertoy.com/view/MtjyDt

// Quadric Quadtree
// using 2d vector graphics library (https://www.shadertoy.com/view/lslXW8)

#define SUBTRACTION 0
#define UNION 1
#define INTERSECTION 2

// what operation to demonstrate
#define CSG_MODE SUBTRACTION

struct surface2x3 {
    float c[10];
};

struct surface2x2 {
    float c[6];
};

#define surface2x1 vec3

const float infinity = 1.0/0.0;

// versor (unit quaternion) from axis and angle
vec4 versor(vec3 axis, float angle) {
    float a = angle * 0.5;
    return vec4(axis * sin(a), cos(a));
}

// invert rotation
vec4 conjugate(vec4 q) {
    return vec4(-q.xyz, q.w);
}

// rotate point by versor
// q (t) * V * q (t) ^-1
vec3 rotate(vec4 q, vec3 p) {
    vec3 t = cross(q.xyz,p) * 2.0;
    return p + q.w * t + cross(q.xyz, t);
}

// rotation matrix constructor from versor
mat3 rotation (vec4 q) {
    float n = dot(q,q);
    vec4 qs = (n == 0.0)?vec4(0.0):(q * (2.0 / n));
    vec3 w = qs.w * q.xyz;
    vec3 x = qs.x * q.xyz;
    vec3 y = qs.y * q.xyz;
    float zz = qs.z * q.z;
    return mat3(
        1.0 - (y.y + zz), x.y + w.z, x.z - w.y,
        x.y - w.z, 1.0 - (x.x + zz), y.z + w.x,
        x.z + w.y, y.z - w.x, 1.0 - (x.x + y.y));
}

// swizzle the components of a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// performing this twice selects zxy
void surface2x3_swizzle_yzx(in surface2x3 surf, out surface2x3 dest) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float XZ = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
	dest.c[0] = YY;
	dest.c[1] = ZZ;
	dest.c[2] = XX;

    dest.c[3] = YZ;
	dest.c[4] = XY;
	dest.c[5] = XZ;

    dest.c[6] = Y;
	dest.c[7] = Z;
	dest.c[8] = X;
    dest.c[9] = surf.c[9];
}

// swap the x and y components of a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
void surface2x2_swizzle_yx(in surface2x2 surf, out surface2x2 dest) {
	float XX = surf.c[0]; float YY = surf.c[1];
	float X = surf.c[3]; float Y = surf.c[4];
    dest.c[0] = YY;
    dest.c[1] = XX;
    dest.c[2] = surf.c[2];
    dest.c[3] = Y;
    dest.c[4] = X;
    dest.c[5] = surf.c[5];
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// compute the partial differential for the given position (x y z)
vec3 surface2x3_diff(in surface2x3 surf, vec3 p) {
	float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
	float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];
	float G = surf.c[6]; float H = surf.c[7]; float I = surf.c[8];
    return vec3(
        2.0*A*p.x + D*p.y + E*p.z + G,
    	D*p.x + 2.0*B*p.y + F*p.z + H,
    	E*p.x + F*p.y + 2.0*C*p.z + I);
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// compute the value for the given position (x y z)
float surface2x3_eval(in surface2x3 surf, vec3 p) {
	float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
	float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];
	float G = surf.c[6]; float H = surf.c[7]; float I = surf.c[8];
    float J = surf.c[9];
    return A*p.x*p.x + B*p.y*p.y + C*p.z*p.z
        + D*p.x*p.y + E*p.x*p.z + F*p.y*p.z
        + G*p.x + H*p.y + I*p.z + J;
}

// for a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// compute the value for the given position (x y)
float surface2x2_eval(in surface2x2 surf, vec2 p) {
	float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
	float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];
    return A*p.x*p.x + B*p.y*p.y + C*p.x*p.y + D*p.x + E*p.y + F;
}

// transform a quadric
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + J
// by a 4x3 matrix to yield a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
void surface2x3_new(in vec4 quadric, in mat4 mtx, out surface2x3 surf) {
    float A = quadric.x; float B = quadric.y; float C = quadric.z; float J = quadric.w;
    vec3 ABC = vec3(A,B,C);
    vec3 ABC2 = ABC*2.0;
    surf.c[0] = dot(ABC, mtx[0].xyz*mtx[0].xyz);
    surf.c[1] = dot(ABC, mtx[1].xyz*mtx[1].xyz);
    surf.c[2] = dot(ABC, mtx[2].xyz*mtx[2].xyz);
    surf.c[3] = dot(ABC2, mtx[0].xyz*mtx[1].xyz);
    surf.c[4] = dot(ABC2, mtx[0].xyz*mtx[2].xyz);
    surf.c[5] = dot(ABC2, mtx[1].xyz*mtx[2].xyz);
    surf.c[6] = dot(ABC2, mtx[0].xyz*mtx[3].xyz);
    surf.c[7] = dot(ABC2, mtx[1].xyz*mtx[3].xyz);
    surf.c[8] = dot(ABC2, mtx[2].xyz*mtx[3].xyz);
    surf.c[9] = dot(ABC, mtx[3].xyz*mtx[3].xyz) + J;
}

void transformed_quadric(vec4 coeffs, vec4 rot, vec3 pos, out surface2x3 surf) {
    mat4 mtx = mat4(transpose(rotation(rot)));
    mat4 translate = mat4(1.0);
    translate[3] = vec4(-pos, 1.0);
    surface2x3_new(coeffs, mtx * translate, surf);
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// and a projective vertical plane that goes through the origin and x
// return the bivariate quadratic that describes a slice of this surface
// h(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
void surface2x3_perspective_plane_x(in surface2x3 surf, float x,
	out surface2x2 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float ZX = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
    float O = surf.c[9];

    // zx -> x
    // y -> y
    slice.c[0] = (XX*x + ZX)*x + ZZ;
    slice.c[1] = YY;
    slice.c[2] = XY*x + YZ;
    slice.c[3] = X*x + Z;
    slice.c[4] = Y;
    slice.c[5] = O;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// and a projective vertical plane that goes through the origin and y
// return the bivariate quadratic that describes a slice of this surface
// h(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
void surface2x3_perspective_plane_y(in surface2x3 surf, float y,
	out surface2x2 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float ZX = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
    float O = surf.c[9];

    // zy -> x
    // x -> y
    slice.c[0] = (YY*y + YZ)*y + ZZ;
    slice.c[1] = XX;
    slice.c[2] = XY*y + ZX;
    slice.c[3] = Y*y + Z;
    slice.c[4] = X;
    slice.c[5] = O;
}

// for a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// and a projective line that goes through the origin and y
// return the univariate quadratic that describes a slice of this surface
// h(x) = A*x^2 + B*x + C
void surface2x2_perspective_plane(in surface2x2 surf, float y,
	out surface2x1 slice) {
    float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
    float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];

    slice[0] = (B*y + C)*y + A;
    slice[1] = E*y + D;
    slice[2] = F;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// and a xy plane that goes through z
// return the bivariate quadratic that describes a slice of this surface
// h(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
void surface2x3_ortho_plane_z(in surface2x3 surf, float z,
	out surface2x2 slice) {
	float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
	float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];
	float G = surf.c[6]; float H = surf.c[7]; float I = surf.c[8];
    float J = surf.c[9];

    slice.c[0] = A;
    slice.c[1] = B;
    slice.c[2] = D;
    slice.c[3] = E*z + G;
    slice.c[4] = F*z + H;
    slice.c[5] = (C*z + I)*z + J;
}

// for a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// and a vertical line that goes through x
// return the univariate quadratic that describes a slice of this surface
// h(x) = A*x^2 + B*x + C
void surface2x2_ortho_plane_x(in surface2x2 surf, float x,
	out surface2x1 slice) {
    float XX = surf.c[0]; float YY = surf.c[1]; float XY = surf.c[2];
    float X = surf.c[3]; float Y = surf.c[4]; float O = surf.c[5];

    slice[0] = YY;
    slice[1] = XY*x + Y;
    slice[2] = (XX*x + X)*x + O;
}

// for a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// and a horizontal line that goes through y
// return the univariate quadratic that describes a slice of this surface
// h(x) = A*x^2 + B*x + C
void surface2x2_ortho_plane_y(in surface2x2 surf, float y,
	out surface2x1 slice) {
    float XX = surf.c[0]; float YY = surf.c[1]; float XY = surf.c[2];
    float X = surf.c[3]; float Y = surf.c[4]; float O = surf.c[5];

    slice[0] = XX;
    slice[1] = XY*y + X;
    slice[2] = (YY*y + Y)*y + O;
}


// for a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// return the coordinate of the inflection point
vec2 surface2x2_center(in surface2x2 surf) {
    float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
    float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];

	float f = 1.0/(4.0*A*B - C*C);
    return vec2(
		(C*E - 2.0*B*D)*f,
        (C*D - 2.0*A*E)*f);
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// and a projective ray that goes through the origin and (p.x p.y 1)
// return the univariate quadratic that describes a slice of this surface
// h(x) = A*x^2 + B*x + C
void surface2x3_perspective_ray(in surface2x3 surf, vec2 p,
	out surface2x1 slice) {
	float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
	float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];
	float G = surf.c[6]; float H = surf.c[7]; float I = surf.c[8];
    float J = surf.c[9];

    slice[0] = (A*p.x + E)*p.x + (D*p.x + B*p.y + F)*p.y + C;
    slice[1] = G*p.x + H*p.y + I;
    slice[2] = J;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// and an orthogonal ray that goes through (p.x p.y 1)
// return the univariate quadratic that describes a slice of this surface
// h(x) = A*x^2 + B*x + C
void surface2x3_ortho_ray(in surface2x3 surf, vec2 p,
	out surface2x1 slice) {
	float A = surf.c[0]; float B = surf.c[1]; float C = surf.c[2];
	float D = surf.c[3]; float E = surf.c[4]; float F = surf.c[5];
	float G = surf.c[6]; float H = surf.c[7]; float I = surf.c[8];
    float J = surf.c[9];

    slice[0] = C;
    slice[1] = E*p.x + F*p.y + I;
    slice[2] = (A*p.x + G)*p.x + (D*p.x + B*p.y + H)*p.y + J;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// return the slice of the plane that describes the contour of the surface
// observed from the orthogonal xy plane
void surface2x3_project_ortho_xy(in surface2x3 surf, out surface2x2 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float ZX = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
	float O = surf.c[9];
    ZZ *= 4.0;
	slice.c[0] = XX*ZZ - ZX*ZX;
    slice.c[1] = YY*ZZ - YZ*YZ;
    slice.c[2] = XY*ZZ - 2.0*ZX*YZ;
    slice.c[3] = X*ZZ - 2.0*ZX*Z;
    slice.c[4] = Y*ZZ - 2.0*YZ*Z;
    slice.c[5] = O*ZZ - Z*Z;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// return the slice of the plane that describes the contour of the surface
// observed from the orthogonal yz plane
void surface2x3_project_ortho_yz(in surface2x3 surf, out surface2x2 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float ZX = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
	float O = surf.c[9];
    XX *= 4.0;
	slice.c[0] = YY*XX - XY*XY;
    slice.c[1] = ZZ*XX - ZX*ZX;
    slice.c[2] = YZ*XX - 2.0*XY*ZX;
    slice.c[3] = Y*XX - 2.0*XY*X;
    slice.c[4] = Z*XX - 2.0*ZX*X;
    slice.c[5] = O*XX - X*X;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// return the slice of the plane that describes the contour of the surface
// observed from the orthogonal zx plane
void surface2x3_project_ortho_zx(in surface2x3 surf, out surface2x2 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float ZX = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
	float O = surf.c[9];
    YY *= 4.0;
	slice.c[0] = ZZ*YY - YZ*YZ;
    slice.c[1] = XX*YY - XY*XY;
    slice.c[2] = ZX*YY - 2.0*YZ*XY;
    slice.c[3] = Z*YY - 2.0*YZ*Y;
    slice.c[4] = X*YY - 2.0*XY*Y;
    slice.c[5] = O*YY - Y*Y;
}

// for a bivariate quadratic
// f(x,y) = A*x^2 + B*y^2 + C*x*y + D*x + E*y + F
// return the slice of the line that describes the contour of the surface
// observed from the orthogonal x plane
void surface2x2_project_ortho_x(in surface2x2 surf, out surface2x1 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float XY = surf.c[2];
	float X = surf.c[3]; float Y = surf.c[4]; float O = surf.c[5];
    YY *= 4.0;
	slice[0] = XX*YY - XY*XY;
    slice[1] = X*YY - 2.0*XY*Y;
    slice[2] = O*YY - Y*Y;
}

// for a second order surface
// f(x,y,z) = A*x^2 + B*y^2 + C*z^2 + D*x*y + E*x*z + F*y*z + G*x + H*y + I*z + J
// return the slice of the plane that describes the contour of the surface
// observed from the orthogonal xy plane
void surface2x3_project_ortho_z(in surface2x3 surf, out surface2x1 slice) {
	float XX = surf.c[0]; float YY = surf.c[1]; float ZZ = surf.c[2];
	float XY = surf.c[3]; float ZX = surf.c[4]; float YZ = surf.c[5];
	float X = surf.c[6]; float Y = surf.c[7]; float Z = surf.c[8];
	float O = surf.c[9];
    YY *= 4.0;
	float NXX = ZZ*YY - YZ*YZ;
    float NYY = (XX*YY - XY*XY)*4.0;
    float NXY = ZX*YY - 2.0*YZ*XY;
    float NY = X*YY - 2.0*XY*Y;
	slice[0] = NXX*NYY - NXY*NXY;
    slice[1] = (Z*YY - 2.0*YZ*Y)*NYY - 2.0*NXY*NY;
    slice[2] = (O*YY - Y*Y)*NYY - NY*NY;
}

// for a univariate quadratic
// f(x) = A*x^2 + B*x + C
// return the near and far points that bound the function at f(x) = 0
vec2 surface2x1_bounds(float A, float B, float C) {
    // (-b +- sqrt(b*b - 4.0*a*c)) / 2.0*a
    float a_neg_rcp = -1.0/A;
    float k = 0.5*B*a_neg_rcp;
    float q = sqrt(k*k + C*a_neg_rcp);
    return k + vec2(-q,q);
}


// for a univariate quadratic
// f(x) = A*x^2 + B*x + C
// return the near and far points that bound the function at f(x) = 0
vec2 surface2x1_bounds(in surface2x1 surf) {
    float A = surf[0]; float B = surf[1]; float C = surf[2];
    return surface2x1_bounds(A, B, C);
}

// for a univariate quadratic
// f(x) = A*x^2 + B*x + C
// return the coordinate of the inflection point
float surface2x1_center(in surface2x1 surf) {
    float A = surf[0]; float B = surf[1]; float C = surf[2];
    return -B / (2.0*A);
}

struct bounds2x3 {
    vec3 v0, v1;
    vec3 eh0_0, eh0_1, eh1_0, eh1_1;
    vec3 ev0_0, ev0_1, ev1_0, ev1_1;
    vec3 c00_0, c01_0, c10_0, c11_0;
    vec3 c00_1, c01_1, c10_1, c11_1;
};

bool in_wedge(vec2 p, vec2 u) {
    return (p.x >= u[0]*p.y) && (p.x <= u[1]*p.y);
}
bool in_frustum(vec3 p, vec2 u, vec2 v) {
    return in_wedge(p.xz, u) && in_wedge(p.yz, v);
}

void merge_plane_range(inout vec2 front, inout vec2 back, vec2 p0, vec2 p1, vec2 u) {
    front[0] = in_wedge(p0, u)?min(front[0], p0.y):front[0];
    back[1] = in_wedge(p1, u)?max(back[1], p1.y):back[1];
}

void merge_corner_range(inout vec2 front, inout vec2 back, float z0, float z1) {
    front[0] = min(front[0], z0);
    back[1] = max(back[1], z1);
    front[1] = max(front[1], (z0 == z0)?z0:infinity);
    back[0] = min(back[0], (z1 == z1)?z1:-infinity);
}

vec4 compute_bounds(bounds2x3 bounds, vec2 u, vec2 v) {
    vec2 front = vec2(infinity, -infinity);
    vec2 back = vec2(infinity, -infinity);

    front[0] = in_frustum(bounds.v0, u, v)?min(front[0], bounds.v0.z):front[0];
    back[1] = in_frustum(bounds.v1, u, v)?max(back[1], bounds.v1.z):back[1];

    merge_corner_range(front, back, bounds.c00_0.z, bounds.c00_1.z);
    merge_corner_range(front, back, bounds.c01_0.z, bounds.c01_1.z);
    merge_corner_range(front, back, bounds.c10_0.z, bounds.c10_1.z);
    merge_corner_range(front, back, bounds.c11_0.z, bounds.c11_1.z);

    merge_plane_range(front, back, bounds.eh0_0.yz, bounds.eh0_1.yz, v);
    merge_plane_range(front, back, bounds.eh1_0.yz, bounds.eh1_1.yz, v);
    merge_plane_range(front, back, bounds.ev0_0.xz, bounds.ev0_1.xz, u);
    merge_plane_range(front, back, bounds.ev1_0.xz, bounds.ev1_1.xz, u);

    front[1] = min(front[1], back[1]);
    back[0] = max(back[0], front[0]);
    return vec4(front, back);
}

void compute_bounding_points_compact(surface2x3 surf, vec2 u, vec2 v, out bounds2x3 bounds) {

    float surf_c7_c7 = surf.c[7]*surf.c[7];
    float surf_2x_c0 = 2.0*surf.c[0];
    float surf_2x_c1 = 2.0*surf.c[1];
    float surf_2x_c3 = 2.0*surf.c[3];
    float surf_2x_c6 = 2.0*surf.c[6];
    float surf_4x_c1 = 4.0*surf.c[1];

    {
	    float surf_4x_c0_c1_sub_c3_c3 = surf_2x_c0*surf_2x_c1 - surf.c[3]*surf.c[3];

        // extract contour of quadratic along z plane
        float NXY = surf.c[4]*surf_4x_c1 - surf.c[5]*surf_2x_c3;
        float NY = surf.c[6]*surf_4x_c1 - surf.c[7]*surf_2x_c3;
        float NYY = surf_4x_c0_c1_sub_c3_c3*4.0;

        // compute z bounds of volume
        vec2 vz = surface2x1_bounds(
        	(surf.c[2]*surf_4x_c1 - surf.c[5]*surf.c[5])*NYY - NXY*NXY,
        	(surf.c[8]*surf_4x_c1 - 2.0*surf.c[5]*surf.c[7])*NYY - 2.0*NXY*NY,
        	(surf.c[9]*surf_4x_c1 - surf_c7_c7)*NYY - NY*NY);
        // extract quadratic of plane at volume z bounds
        float slice_z0_c3 = surf.c[4]*vz[0] + surf.c[6];
        float slice_z0_c4 = surf.c[5]*vz[0] + surf.c[7];

        float slice_z1_c3 = surf.c[4]*vz[1] + surf.c[6];
        float slice_z1_c4 = surf.c[5]*vz[1] + surf.c[7];

        // compute position of contact points at volume z bounds
        float f = 1.0/surf_4x_c0_c1_sub_c3_c3;
        bounds.v0 = vec3(
            (surf.c[3]*slice_z0_c4 - surf_2x_c1*slice_z0_c3)*f,
            (surf.c[3]*slice_z0_c3 - surf_2x_c0*slice_z0_c4)*f,
        	vz[0]);
        bounds.v1 = vec3(
            (surf.c[3]*slice_z1_c4 - surf_2x_c1*slice_z1_c3)*f,
            (surf.c[3]*slice_z1_c3 - surf_2x_c0*slice_z1_c4)*f,
        	vz[1]);
    }

    // compute z bounds of corner quadratics
    // compute position of contact points at corner z bounds
    {
    	float surf_2x_c7 = 2.0*surf.c[7];
        float surf_c1_v0 = surf.c[1]*v[0];
        float surf_c7_v0 = surf.c[7]*v[0];
        float surf_c1_v1 = surf.c[1]*v[1];
        float surf_c7_v1 = surf.c[7]*v[1];

        // compute z bounds of plane contours
        // compute position of contact points at plane z bounds
        float surf_2x_c1_neg_rcp = -1.0 / surf_2x_c1;
	    float surf_4x_c9_c1_sub_c7_c7 = surf.c[9]*surf_4x_c1 - surf_c7_c7;

        {
            float slice_x0_c0 = (surf.c[0]*u[0] + surf.c[4])*u[0] + surf.c[2];
            float slice_x0_c2 = surf.c[3]*u[0] + surf.c[5];
            float slice_x0_c3 = surf.c[6]*u[0] + surf.c[8];

            {
                vec2 cx0y0 = surface2x1_bounds((surf_c1_v0 + slice_x0_c2)*v[0] + slice_x0_c0, surf_c7_v0 + slice_x0_c3, surf.c[9]);
                bounds.c00_0 = vec3(u[0], v[0], 1.0) * cx0y0[0];
                bounds.c00_1 = vec3(u[0], v[0], 1.0) * cx0y0[1];
            }
            {
                vec2 cx0y1 = surface2x1_bounds((surf_c1_v1 + slice_x0_c2)*v[1] + slice_x0_c0, surf_c7_v1 + slice_x0_c3, surf.c[9]);
                bounds.c01_1 = vec3(u[0], v[1], 1.0) * cx0y1[1];
                bounds.c01_0 = vec3(u[0], v[1], 1.0) * cx0y1[0];
            }
            {
                vec2 ph0 = surface2x1_bounds(slice_x0_c0*surf_4x_c1 - slice_x0_c2*slice_x0_c2, slice_x0_c3*surf_4x_c1 - slice_x0_c2*surf_2x_c7, surf_4x_c9_c1_sub_c7_c7);
                bounds.eh0_0 = vec3(ph0[0] * u[0], (slice_x0_c2*ph0[0] + surf.c[7]) * surf_2x_c1_neg_rcp, ph0[0]);
                bounds.eh0_1 = vec3(ph0[1] * u[0], (slice_x0_c2*ph0[1] + surf.c[7]) * surf_2x_c1_neg_rcp, ph0[1]);
            }

        }
        {
            float slice_x1_c0 = (surf.c[0]*u[1] + surf.c[4])*u[1] + surf.c[2];
            float slice_x1_c2 = surf.c[3]*u[1] + surf.c[5];
            float slice_x1_c3 = surf.c[6]*u[1] + surf.c[8];

            {
                vec2 cx1y0 = surface2x1_bounds((surf_c1_v0 + slice_x1_c2)*v[0] + slice_x1_c0, surf_c7_v0 + slice_x1_c3, surf.c[9]);
                bounds.c10_0 = vec3(u[1], v[0], 1.0) * cx1y0[0];
                bounds.c10_1 = vec3(u[1], v[0], 1.0) * cx1y0[1];
            }
            {
                vec2 cx1y1 = surface2x1_bounds((surf_c1_v1 + slice_x1_c2)*v[1] + slice_x1_c0, surf_c7_v1 + slice_x1_c3, surf.c[9]);
                bounds.c11_1 = vec3(u[1], v[1], 1.0) * cx1y1[1];
                bounds.c11_0 = vec3(u[1], v[1], 1.0) * cx1y1[0];
            }
            {
                vec2 ph1 = surface2x1_bounds(slice_x1_c0*surf_4x_c1 - slice_x1_c2*slice_x1_c2, slice_x1_c3*surf_4x_c1 - slice_x1_c2*surf_2x_c7, surf_4x_c9_c1_sub_c7_c7);
                bounds.eh1_0 = vec3(ph1[0] * u[1], (slice_x1_c2*ph1[0] + surf.c[7]) * surf_2x_c1_neg_rcp, ph1[0]);
                bounds.eh1_1 = vec3(ph1[1] * u[1], (slice_x1_c2*ph1[1] + surf.c[7]) * surf_2x_c1_neg_rcp, ph1[1]);
            }

        }
    }

    {
	    float surf_4x_c0 = 4.0*surf.c[0];
    	float surf_4x_c9_c0_sub_c6_c6 = surf.c[9]*surf_4x_c0 - surf.c[6]*surf.c[6];

        // compute z bounds of plane contours
        // compute position of contact points at plane z bounds
        float surf_2x_c0_neg_rcp = -1.0 / surf_2x_c0;
        {
            float slice_y0_c0 = (surf.c[1]*v[0] + surf.c[5])*v[0] + surf.c[2];
            float slice_y0_c2 = surf.c[3]*v[0] + surf.c[4];
            float slice_y0_c3 = surf.c[7]*v[0] + surf.c[8];

            vec2 pv0 = surface2x1_bounds(slice_y0_c0*surf_4x_c0 - slice_y0_c2*slice_y0_c2, slice_y0_c3*surf_4x_c0 - slice_y0_c2*surf_2x_c6, surf_4x_c9_c0_sub_c6_c6);
            bounds.ev0_0 = vec3((slice_y0_c2*pv0[0] + surf.c[6]) * surf_2x_c0_neg_rcp, pv0[0] * v[0], pv0[0]);
            bounds.ev0_1 = vec3((slice_y0_c2*pv0[1] + surf.c[6]) * surf_2x_c0_neg_rcp, pv0[1] * v[0], pv0[1]);
        }

        {
            float slice_y1_c0 = (surf.c[1]*v[1] + surf.c[5])*v[1] + surf.c[2];
            float slice_y1_c2 = surf.c[3]*v[1] + surf.c[4];
            float slice_y1_c3 = surf.c[7]*v[1] + surf.c[8];

            vec2 pv1 = surface2x1_bounds(slice_y1_c0*surf_4x_c0 - slice_y1_c2*slice_y1_c2, slice_y1_c3*surf_4x_c0 - slice_y1_c2*surf_2x_c6, surf_4x_c9_c0_sub_c6_c6);
            bounds.ev1_0 = vec3((slice_y1_c2*pv1[0] + surf.c[6]) * surf_2x_c0_neg_rcp, pv1[0] * v[1], pv1[0]);
            bounds.ev1_1 = vec3((slice_y1_c2*pv1[1] + surf.c[6]) * surf_2x_c0_neg_rcp, pv1[1] * v[1], pv1[1]);
        }
    }
}

void compute_bounding_points_clean(surface2x3 surf, vec2 u, vec2 v, out bounds2x3 bounds) {


    surface2x1 contour_z;
    // extract contour of quadratic along z plane
    surface2x3_project_ortho_z(surf, contour_z);
    // compute z bounds of volume
    vec2 vz = surface2x1_bounds(contour_z);
    surface2x2 slice_z0;
    surface2x2 slice_z1;
    // extract quadratic of plane at volume z bounds
    surface2x3_ortho_plane_z(surf, vz[0], slice_z0);
    surface2x3_ortho_plane_z(surf, vz[1], slice_z1);
    // compute position of contact points at volume z bounds
    bounds.v0 = vec3(surface2x2_center(slice_z0),vz[0]);
    bounds.v1 = vec3(surface2x2_center(slice_z1),vz[1]);

    // extract quadratic at planes
    surface2x2 slice_x0;
    surface2x2 slice_x1;
    surface2x2 slice_y0;
    surface2x2 slice_y1;
	surface2x3_perspective_plane_x(surf, u[0], slice_x0);
    surface2x3_perspective_plane_x(surf, u[1], slice_x1);
	surface2x3_perspective_plane_y(surf, v[0], slice_y0);
    surface2x3_perspective_plane_y(surf, v[1], slice_y1);

    surface2x1 contour_h0;
    surface2x1 contour_h1;
    surface2x1 contour_v0;
    surface2x1 contour_v1;
    // extract contour of quadratics at planes
    surface2x2_project_ortho_x(slice_x0, contour_h0);
    surface2x2_project_ortho_x(slice_x1, contour_h1);
    surface2x2_project_ortho_x(slice_y0, contour_v0);
    surface2x2_project_ortho_x(slice_y1, contour_v1);
    // compute z bounds of plane contours
    vec2 ph0 = surface2x1_bounds(contour_h0);
    vec2 ph1 = surface2x1_bounds(contour_h1);
    vec2 pv0 = surface2x1_bounds(contour_v0);
    vec2 pv1 = surface2x1_bounds(contour_v1);


    surface2x1 slice_h0z0;
    surface2x1 slice_h0z1;
    surface2x1 slice_h1z0;
    surface2x1 slice_h1z1;
    surface2x1 slice_v0z0;
    surface2x1 slice_v0z1;
    surface2x1 slice_v1z0;
    surface2x1 slice_v1z1;

    // extract quadratic of line at plane z bounds
    surface2x2_ortho_plane_x(slice_x0, ph0[0], slice_h0z0);
    surface2x2_ortho_plane_x(slice_x0, ph0[1], slice_h0z1);
    surface2x2_ortho_plane_x(slice_x1, ph1[0], slice_h1z0);
    surface2x2_ortho_plane_x(slice_x1, ph1[1], slice_h1z1);
    surface2x2_ortho_plane_x(slice_y0, pv0[0], slice_v0z0);
    surface2x2_ortho_plane_x(slice_y0, pv0[1], slice_v0z1);
    surface2x2_ortho_plane_x(slice_y1, pv1[0], slice_v1z0);
    surface2x2_ortho_plane_x(slice_y1, pv1[1], slice_v1z1);

    // compute position of contact points at plane z bounds
    bounds.eh0_0 = vec3(ph0[0] * u[0], surface2x1_center(slice_h0z0), ph0[0]);
    bounds.eh1_0 = vec3(ph1[0] * u[1], surface2x1_center(slice_h1z0), ph1[0]);
    bounds.ev0_0 = vec3(surface2x1_center(slice_v0z0), pv0[0] * vec2(v[0],1.0));
    bounds.ev1_0 = vec3(surface2x1_center(slice_v1z0), pv1[0] * vec2(v[1],1.0));
    bounds.eh0_1 = vec3(ph0[1] * u[0], surface2x1_center(slice_h0z1), ph0[1]);
    bounds.eh1_1 = vec3(ph1[1] * u[1], surface2x1_center(slice_h1z1), ph1[1]);
    bounds.ev0_1 = vec3(surface2x1_center(slice_v0z1), pv0[1] * vec2(v[0],1.0));
    bounds.ev1_1 = vec3(surface2x1_center(slice_v1z1), pv1[1] * vec2(v[1],1.0));

    // extract quadratic of corners
    surface2x1 slice_x0y0;
    surface2x1 slice_x0y1;
    surface2x1 slice_x1y0;
    surface2x1 slice_x1y1;
	surface2x2_perspective_plane(slice_x0, v[0], slice_x0y0);
    surface2x2_perspective_plane(slice_x0, v[1], slice_x0y1);
	surface2x2_perspective_plane(slice_x1, v[0], slice_x1y0);
    surface2x2_perspective_plane(slice_x1, v[1], slice_x1y1);

    // compute z bounds of corner quadratics
    vec2 cx0y0 = surface2x1_bounds(slice_x0y0);
    vec2 cx0y1 = surface2x1_bounds(slice_x0y1);
    vec2 cx1y0 = surface2x1_bounds(slice_x1y0);
    vec2 cx1y1 = surface2x1_bounds(slice_x1y1);

    // compute position of contact points at corner z bounds
    bounds.c00_0 = vec3(u[0], v[0], 1.0) * cx0y0[0];
    bounds.c01_0 = vec3(u[0], v[1], 1.0) * cx0y1[0];
    bounds.c10_0 = vec3(u[1], v[0], 1.0) * cx1y0[0];
    bounds.c11_0 = vec3(u[1], v[1], 1.0) * cx1y1[0];
    bounds.c00_1 = vec3(u[0], v[0], 1.0) * cx0y0[1];
    bounds.c01_1 = vec3(u[0], v[1], 1.0) * cx0y1[1];
    bounds.c10_1 = vec3(u[1], v[0], 1.0) * cx1y0[1];
    bounds.c11_1 = vec3(u[1], v[1], 1.0) * cx1y1[1];


}

vec2 lissajous(float t, float a, float b) {
    return vec2(sin(a*t), sin(b*t));
}

void setup_quadric(inout surface2x3 surf, float t) {
    vec2 plane_offset = lissajous(t*0.2, 5.0, 4.0)*0.3;
    vec4 plane_rotation = versor(normalize(vec3(1.0)), t*0.2);
    vec3 plane_normal = rotate(plane_rotation, vec3(0.0, 0.0, 1.0));
    vec3 ellipsoid_size = vec3(1.0,3.0,1.0) * 0.3;
    transformed_quadric(
        vec4(1.0 / (ellipsoid_size*ellipsoid_size) * vec3(1.0,1.0,1.0),-1.0),
		plane_rotation, vec3(plane_offset + vec2(0.0,0.0),1.0), surf);
}

surface2x3 surf3;
surface2x3 surf3_b;

void setup_globals(float t) {

    setup_quadric(surf3, t);
    setup_quadric(surf3_b, -t*1.1 - 1.0);
}

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

// interface
//////////////////////////////////////////////////////////

// set color source for stroke / fill / clear
void set_source_rgba(vec4 c);
void set_source_rgba(float r, float g, float b, float a);
void set_source_rgb(vec3 c);
void set_source_rgb(float r, float g, float b);
void set_source_linear_gradient(vec3 color0, vec3 color1, vec2 p0, vec2 p1);
void set_source_linear_gradient(vec4 color0, vec4 color1, vec2 p0, vec2 p1);
void set_source_radial_gradient(vec3 color0, vec3 color1, vec2 p, float r);
void set_source_radial_gradient(vec4 color0, vec4 color1, vec2 p, float r);
void set_source(sampler2D image);
// control how source changes are applied
const int Replace = 0; // default: replace the new source with the old one
const int Alpha = 1; // alpha-blend the new source on top of the old one
const int Multiply = 2; // multiply the new source with the old one
void set_source_blend_mode(int mode);
// if enabled, blends using premultiplied alpha instead of
// regular alpha blending.
void premultiply_alpha(bool enable);

// set line width in normalized units for stroke
void set_line_width(float w);
// set line width in pixels for stroke
void set_line_width_px(float w);
// set blur strength for strokes in normalized units
void set_blur(float b);

// add a circle path at P with radius R
void circle(vec2 p, float r);
void circle(float x, float y, float r);
// add an ellipse path at P with radii RW and RH
void ellipse(vec2 p, vec2 r);
void ellipse(float x, float y, float rw, float rh);
// add a rectangle at O with size S
void rectangle(vec2 o, vec2 s);
void rectangle(float ox, float oy, float sx, float sy);
// add a rectangle at O with size S and rounded corner of radius R
void rounded_rectangle(vec2 o, vec2 s, float r);
void rounded_rectangle(float ox, float oy, float sx, float sy, float r);

// set starting point for curves and lines to P
void move_to(vec2 p);
void move_to(float x, float y);
// draw straight line from starting point to P,
// and set new starting point to P
void line_to(vec2 p);
void line_to(float x, float y);
// draw quadratic bezier curve from starting point
// over B1 to B2 and set new starting point to B2
void curve_to(vec2 b1, vec2 b2);
void curve_to(float b1x, float b1y, float b2x, float b2y);
// connect current starting point with first
// drawing point.
void close_path();

// clear screen in the current source color
void clear();
// fill paths and clear the path buffer
void fill();
// fill paths and preserve them for additional ops
void fill_preserve();
// stroke paths and clear the path buffer
void stroke_preserve();
// stroke paths and preserve them for additional ops
void stroke();
// clears the path buffer
void new_path();

// return rgb color for given hue (0..1)
vec3 hue(float hue);
// return rgb color for given hue, saturation and lightness
vec3 hsl(float h, float s, float l);
vec4 hsl(float h, float s, float l, float a);

// rotate the context by A in radians
void rotate(float a);
// uniformly scale the context by S
void scale(float s);
// non-uniformly scale the context by S
void scale(vec2 s);
void scale(float sx, float sy);
// translate the context by offset P
void translate(vec2 p);
void translate(float x, float y);
// clear all transformations for the active context
void identity_matrix();
// transform the active context by the given matrix
void transform(mat3 mtx);
// set the transformation matrix for the active context
void set_matrix(mat3 mtx);

// return the active query position for in_fill/in_stroke
// by default, this is the mouse position
vec2 get_query();
// set the query position for subsequent calls to
// in_fill/in_stroke; clears the query path
void set_query(vec2 p);
// true if the query position is inside the current path
bool in_fill();
// true if the query position is inside the current stroke
bool in_stroke();

// return the transformed coordinate of the current pixel
vec2 get_origin();
// draw a 1D graph from coordinate p, result f(p.x),
// and gradient1D(f,p.x)
void graph(vec2 p, float f_x, float df_x);
// draw a 2D graph from coordinate p, result f(p),
// and gradient2D(f,p)
void graph(vec2 p, float f_x, vec2 df_x);
// adds a custom distance field as path
// this field will not be testable by queries
void add_field(float c);

// returns a gradient for 1D graph function f at position x
#define gradient1D(f,x) (f(x + get_gradient_eps()) - f(x - get_gradient_eps())) / (2.0*get_gradient_eps())
// returns a gradient for 2D graph function f at position x
#define gradient2D(f,x) vec2(f(x + vec2(get_gradient_eps(),0.0)) - f(x - vec2(get_gradient_eps(),0.0)),f(x + vec2(0.0,get_gradient_eps())) - f(x - vec2(0.0,get_gradient_eps()))) / (2.0*get_gradient_eps())
// draws a 1D graph at the current position
#define graph1D(f) { vec2 pp = get_origin(); graph(pp, f(pp.x), gradient1D(f,pp.x)); }
// draws a 2D graph at the current position
#define graph2D(f) { vec2 pp = get_origin(); graph(pp, f(pp), gradient2D(f,pp)); }

// represents the current drawing context
// you usually don't need to change anything here
struct Context {
    // screen position, query position
    vec4 position;
    vec2 shape;
    vec2 clip;
    vec2 scale;
    float line_width;
    bool premultiply;
    vec2 blur;
    vec4 source;
    vec2 start_pt;
    vec2 last_pt;
    int source_blend;
    bool has_clip;
};

float AA;
float AAINV;

// save current stroke width, starting
// point and blend mode from active context.
Context _save();
// restore stroke width, starting point
// and blend mode to a context previously returned by save()
void restore(Context ctx);

#define save(name) Context name = _save();

// draws a half-transparent debug gradient for the
// active path
void debug_gradient();
void debug_clip_gradient();
// returns the gradient epsilon width
float get_gradient_eps();

float distborder(float x) {
	return 1.0 - clamp(x*400.0, 0.0, 1.0);
}

bool is_solid(vec4 range) {
    return range[1] < range[2];
}

bool join_a_b(vec4 range_a, vec4 range_b) {
    bool solid_a = is_solid(range_a);
    bool solid_b = is_solid(range_b);
    vec2 r_a = range_a.xy;
    vec2 r_ae = range_a.zw;
    vec2 r_b = range_b.xy;

    bool used = false;
    if ((range_a[0] != infinity) && (range_b[0] != infinity)) {
        used = true;
        if ((r_a[0] >= range_b[3]) || (r_a[1] <= range_b[0])) {
            used = false;
        }
        #if 0
        if ((r_ae[0] < r_b[1]) && (r_ae[1] > r_b[0])) {
            used = true;
        }
        #endif
    }

    return used;
}

bool join_a_nb(vec4 range_a, vec4 range_b) {
    bool solid_a = is_solid(range_a);
    bool solid_b = is_solid(range_b);
    vec2 r_a = range_a.xy;
    vec2 r_ae = range_a.zw;
    vec2 r_b = range_b.zw;

    bool used = false;
    if (range_a[0] != infinity) {
        used = true;
        if (range_b[0] != infinity) {
            if (solid_b
                && (r_a[0] >= range_b[1])
                && (r_a[1] <= range_b[2])) {
                used = false;
            }
            #if 1
            if ((r_b[0] < r_ae[1]) && (r_b[1] > r_ae[0])) {
                used = true;
            }
            #endif
        }
    }

    return used;
}
bool join_na_b(vec4 range_a, vec4 range_b) {
    bool solid_a = is_solid(range_a);
    bool solid_b = is_solid(range_b);
    vec2 r_a = range_a.zw;
    vec2 r_ae = range_a.xy;
    vec2 r_b = range_b.xy;

    bool used = false;
    if (range_a[0] != infinity) {
        used = true;
        if (range_b[0] != infinity) {
            if ((r_a[0] >= range_b[3]) || (r_a[1] <= range_b[0])) {
                used = false;
            }
            #if 1
            if ((r_ae[0] < r_b[1]) && (r_ae[1] > r_b[0])) {
               used = true;
            }
            #endif
        } else {
            used = false;
        }
    }

    return used;
}

float cull_brushes(vec4 range_a, vec4 range_b, out bool use_a, out bool use_b) {
    float z_occ = infinity;
    bool solid_a = (range_a[1] < range_a[2]);
    bool solid_b = (range_b[1] < range_b[2]);
	use_a = false;
    use_b = false;
    
#if (CSG_MODE == SUBTRACTION)
    vec2 r_a = range_a.xy;
    vec2 r_b = range_b.zw;
    use_a = join_a_nb(range_a, range_b);
    use_b = join_na_b(range_b, range_a);
    if (use_a) {
        if (solid_a) z_occ = min(z_occ, r_a[1]);
    }
    if (use_b) {
        if (solid_b) z_occ = min(z_occ, r_b[1]);
    }
    if (range_a[0] > z_occ)
        use_a = false;
    if (range_b[0] > z_occ)
        use_b = false;
#elif (CSG_MODE == INTERSECTION)
    vec2 r_a = range_a.xy;
    vec2 r_b = range_b.xy;
    use_a = join_a_b(range_a, range_b);
    use_b = join_a_b(range_b, range_a);
    if (use_a) {
        if (solid_a) z_occ = min(z_occ, r_a[1]);
    }
    if (use_b) {
        if (solid_b) z_occ = min(z_occ, r_b[1]);
    }
    if (range_a[0] > z_occ)
        use_a = false;
    if (range_b[0] > z_occ)
        use_b = false;
#else
    vec2 r_a = range_a.xy;
    vec2 r_b = range_b.xy;
    use_a = range_a[0] != infinity;
    use_b = range_b[0] != infinity;
    if (use_a) {
        if (solid_a) z_occ = min(z_occ, r_a[1]);
    }
    if (use_b) {
        if (solid_b) z_occ = min(z_occ, r_b[1]);
    }
    if (range_a[0] > z_occ)
        use_a = false;
    if (range_b[0] > z_occ)
        use_b = false;
#endif    
    return z_occ;
}

void paint() {
    float t = iTime;
    setup_globals(t);

    //scale(0.3);

    float rdot = AAINV*2.0;

    vec2 p = get_origin();
    surface2x1 surf1;
    surface2x3_perspective_ray(surf3, p, surf1);
    vec2 d = surface2x1_bounds(surf1);
    d.x = min(infinity, d.x);
    d.y = max(-infinity, d.y);

    surface2x1 surf1b;
    surface2x3_perspective_ray(surf3_b, p, surf1b);
    vec2 db = surface2x1_bounds(surf1b);
    db.x = min(infinity, db.x);
    db.y = max(-infinity, db.y);

    float z = infinity;
    vec3 normal = vec3(0.5);
    {
    	float q = d[0];
#if (CSG_MODE == SUBTRACTION)
        if ((q > db[0]) && (q < db[1])) {
            q = infinity;
        }
#elif (CSG_MODE == INTERSECTION)
        if ((q < db[0]) || (q > db[1])) {
            q = infinity;
        }
#else
#endif
        if (q < z) {
            z = q;
            normal = normalize(surface2x3_diff(surf3, vec3(p,1.0)*q));
        }
    }
    {
		float q;
        float s = 1.0;
#if (CSG_MODE == SUBTRACTION)    
        q = db[1];
        if ((q < d[0]) || (q > d[1])) {
            q = infinity;
        }
        s = -1.0;
#elif (CSG_MODE == INTERSECTION)
        q = db[0];
        if ((q < d[0]) || (q > d[1])) {
            q = infinity;
        }    
#else
	    q = db[0];
#endif
        if (q < z) {
            z = q;
            normal = s*normalize(surface2x3_diff(surf3_b, vec3(p,1.0)*q));
        }
    }    

    if ((z > 0.0) && (z != infinity)) {
        vec3 pos = vec3(p,1.0) * z;
        vec3 color = (normal * 0.5 + 0.5);

        color = clamp(color, vec3(0.0), vec3(1.0));
        set_source_rgb(color);
        clear();
    } else {
        set_source_rgb(vec3(0.0,0.0,0.2));
        clear();
    }

    set_source_rgb(vec3(1.0));
    set_line_width_px(1.3);
    vec2 c0 = vec2(-2.0,-2.0);
    vec2 c1 = vec2(2.0,2.0);
    const int N = 9;
    for (int i = 0; i <= N; ++i) {
        vec2 c = (c0 + c1)*0.5;
        vec2 h = (c1 - c0)*0.5;
        if (p.x < c.x) {
            c1.x = c.x;
        } else {
            c0.x = c.x;
        }
        if (p.y < c.y) {
            c1.y = c.y;
        } else {
            c0.y = c.y;
        }
        vec2 u = vec2(c0.x,c1.x);
        vec2 v = vec2(c0.y,c1.y);
        vec4 range_a;
        vec4 range_b;
        bounds2x3 bounds;
        compute_bounding_points_compact(surf3, u, v, bounds);
        range_a = compute_bounds(bounds, u, v);
        compute_bounding_points_compact(surf3_b, u, v, bounds);
        range_b = compute_bounds(bounds, u, v);

        bool use_a = false;
        bool use_b = false;
        cull_brushes(range_a, range_b, use_a, use_b);

        if (use_a == use_b) {
            if (!use_a)
            	set_source_rgb(vec3(0.3));
            else
                set_source_rgb(vec3(1.0));
        } else if (use_a)
            set_source_rgb(vec3(1.0, 0.5, 0.1));
        else if (use_b)
            set_source_rgb(vec3(0.1, 0.5, 1.0));
        else
            set_source_rgb(vec3(1.0, 0.0, 0.0));

        if (!use_a || !use_b || (i == N)) {
	        rectangle(c0, c1 - c0);
	        stroke();
            break;
        }
    }

    if (iMouse.z > 0.5) {
        vec4 range_a;
        vec4 range_b;
        vec2 m = get_query();
        vec2 r = vec2(-1.0,1.0)*(1.0/64.0);
        vec2 u = m.x + r;
        vec2 v = m.y + r;
        set_source_rgb(1.0,0.0,0.0);
        rectangle(vec2(u[0],v[0]), vec2(u[1] - u[0],v[1] - v[0]));
        stroke();
        bounds2x3 bounds;
        compute_bounding_points_compact(surf3, u, v, bounds);
        range_a = compute_bounds(bounds, u, v);
        compute_bounding_points_compact(surf3_b, u, v, bounds);
        range_b = compute_bounds(bounds, u, v);
        bool solid_a = (range_a[1] < range_a[2]);
        bool solid_b = (range_b[1] < range_b[2]);

        range_a = range_a*2.0 - 2.0;
        range_b = range_b*2.0 - 2.0;
        
        bool use_a = false;
        bool use_b = false;
		float z_occ = cull_brushes(range_a, range_b, use_a, use_b);
        
        range_a[1] = min(range_a[1], 2.0);
        range_a[2] = max(range_a[2], -2.0);
        range_b[1] = min(range_b[1], 2.0);
        range_b[2] = max(range_b[2], -2.0);

        float h = 0.05;
        float y = -1.0 + h*3.0;
        vec3 color_a = use_a?vec3(1.0, 0.5, 0.1):vec3(1.0,0.0,0.0);
        vec3 color_b = use_b?vec3(0.1, 0.5, 1.0):vec3(1.0,0.0,0.0);
        set_source_rgba(vec4(color_a,1.0));
        rectangle(range_a[0], y, range_a[1] - range_a[0], h);
        fill();
        y -= h;
        rectangle(range_a[2], y, range_a[3] - range_a[2], h);
        fill();
        y -= h;
        set_source_rgba(vec4(color_b, 1.0));
        rectangle(range_b[0], y, range_b[1] - range_b[0], h);
        fill();
        y -= h;
        rectangle(range_b[2], y, range_b[3] - range_b[2], h);
        fill();
        set_source_rgb(vec3(1.0));
        move_to(z_occ, y);
        line_to(z_occ, y + h*4.0);
        stroke();
    }

}

// implementation
//////////////////////////////////////////////////////////

vec2 aspect;
vec2 uv;
vec2 position;
vec2 query_position;
float ScreenH;

//////////////////////////////////////////////////////////

float det(vec2 a, vec2 b) { return a.x*b.y-b.x*a.y; }

//////////////////////////////////////////////////////////

vec3 hue(float hue) {
    return clamp(
        abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0,
        0.0, 1.0);
}

vec3 hsl(float h, float s, float l) {
    vec3 rgb = hue(h);
    return l + s * (rgb - 0.5) * (1.0 - abs(2.0 * l - 1.0));
}

vec4 hsl(float h, float s, float l, float a) {
    return vec4(hsl(h,s,l),a);
}

//////////////////////////////////////////////////////////

#define DEFAULT_SHAPE_V 1e+20
#define DEFAULT_CLIP_V -1e+20

Context _stack;

void init (vec2 fragCoord) {
    uv = fragCoord.xy / iResolution.xy;
    vec2 m = iMouse.xy / iResolution.xy;

    position = (uv*2.0-1.0)*aspect;
    query_position = (m*2.0-1.0)*aspect;

    _stack = Context(
        vec4(position, query_position),
        vec2(DEFAULT_SHAPE_V),
        vec2(DEFAULT_CLIP_V),
        vec2(1.0),
        1.0,
        false,
        vec2(0.0,1.0),
        vec4(vec3(0.0),1.0),
        vec2(0.0),
        vec2(0.0),
        Replace,
        false
    );
}

vec3 _color = vec3(1.0);

vec2 get_origin() {
    return _stack.position.xy;
}

vec2 get_query() {
    return _stack.position.zw;
}

void set_query(vec2 p) {
    _stack.position.zw = p;
    _stack.shape.y = DEFAULT_SHAPE_V;
    _stack.clip.y = DEFAULT_CLIP_V;
}

Context _save() {
    return _stack;
}

void restore(Context ctx) {
    // preserve shape
    vec2 shape = _stack.shape;
    vec2 clip = _stack.clip;
    bool has_clip = _stack.has_clip;
    // preserve source
    vec4 source = _stack.source;
    _stack = ctx;
    _stack.shape = shape;
    _stack.clip = clip;
    _stack.source = source;
    _stack.has_clip = has_clip;
}

mat3 mat2x3_invert(mat3 s)
{
    float d = det(s[0].xy,s[1].xy);
    d = (d != 0.0)?(1.0 / d):d;

    return mat3(
        s[1].y*d, -s[0].y*d, 0.0,
        -s[1].x*d, s[0].x*d, 0.0,
        det(s[1].xy,s[2].xy)*d,
        det(s[2].xy,s[0].xy)*d,
        1.0);
}

void identity_matrix() {
    _stack.position = vec4(position, query_position);
    _stack.scale = vec2(1.0);
}

void set_matrix(mat3 mtx) {
    mtx = mat2x3_invert(mtx);
    _stack.position.xy = (mtx * vec3(position,1.0)).xy;
    _stack.position.zw = (mtx * vec3(query_position,1.0)).xy;
    _stack.scale = vec2(length(mtx[0].xy), length(mtx[1].xy));
}

void transform(mat3 mtx) {
    mtx = mat2x3_invert(mtx);
    _stack.position.xy = (mtx * vec3(_stack.position.xy,1.0)).xy;
    _stack.position.zw = (mtx * vec3(_stack.position.zw,1.0)).xy;
    _stack.scale *= vec2(length(mtx[0].xy), length(mtx[1].xy));
}

void rotate(float a) {
    float cs = cos(a), sn = sin(a);
    transform(mat3(
        cs, sn, 0.0,
        -sn, cs, 0.0,
        0.0, 0.0, 1.0));
}

void scale(vec2 s) {
    transform(mat3(s.x,0.0,0.0,0.0,s.y,0.0,0.0,0.0,1.0));
}

void scale(float sx, float sy) {
    scale(vec2(sx, sy));
}

void scale(float s) {
    scale(vec2(s));
}

void translate(vec2 p) {
    transform(mat3(1.0,0.0,0.0,0.0,1.0,0.0,p.x,p.y,1.0));
}

void translate(float x, float y) { translate(vec2(x,y)); }

void clear() {
    _color = mix(_color, _stack.source.rgb, _stack.source.a);
}

void blit(out vec4 dest) {
    dest = vec4(sqrt(_color), 1.0);
}

void blit(out vec3 dest) {
    dest = sqrt(_color);
}

void add_clip(vec2 d) {
    d = d / _stack.scale;
    _stack.clip = max(_stack.clip, d);
    _stack.has_clip = true;
}

void add_field(vec2 d) {
    d = d / _stack.scale;
    _stack.shape = min(_stack.shape, d);
}

void add_field(float c) {
    _stack.shape.x = min(_stack.shape.x, c);
}

void new_path() {
    _stack.shape = vec2(DEFAULT_SHAPE_V);
    _stack.clip = vec2(DEFAULT_CLIP_V);
    _stack.has_clip = false;
}

void debug_gradient() {
    vec2 d = _stack.shape;
    _color = mix(_color,
        hsl(d.x * 6.0,
            1.0, (d.x>=0.0)?0.5:0.3),
        0.5);
}

void debug_clip_gradient() {
    vec2 d = _stack.clip;
    _color = mix(_color,
        hsl(d.x * 6.0,
            1.0, (d.x>=0.0)?0.5:0.3),
        0.5);
}

void set_blur(float b) {
    if (b == 0.0) {
        _stack.blur = vec2(0.0, 1.0);
    } else {
        _stack.blur = vec2(
            b,
            0.0);
    }
}

void write_color(vec4 rgba, float w) {
    float src_a = w * rgba.a;
    float dst_a = _stack.premultiply?w:src_a;
    _color = _color * (1.0 - src_a) + rgba.rgb * dst_a;
}

void premultiply_alpha(bool enable) {
    _stack.premultiply = enable;
}

float min_uniform_scale() {
    return min(_stack.scale.x, _stack.scale.y);
}

float uniform_scale_for_aa() {
    return min(1.0, _stack.scale.x / _stack.scale.y);
}

float calc_aa_blur(float w) {
    vec2 blur = _stack.blur;
    w -= blur.x;
    float wa = clamp(-w*AA*uniform_scale_for_aa(), 0.0, 1.0);
    float wb = clamp(-w / blur.x + blur.y, 0.0, 1.0);
	return wa * wb;
}

void fill_preserve() {
    write_color(_stack.source, calc_aa_blur(_stack.shape.x));
    if (_stack.has_clip) {
	    write_color(_stack.source, calc_aa_blur(_stack.clip.x));
    }
}

void fill() {
    fill_preserve();
    new_path();
}

void set_line_width(float w) {
    _stack.line_width = w;
}

void set_line_width_px(float w) {
    _stack.line_width = w*min_uniform_scale() * AAINV;
}

float get_gradient_eps() {
    return (1.0 / min_uniform_scale()) * AAINV;
}

vec2 stroke_shape() {
    return abs(_stack.shape) - _stack.line_width/_stack.scale;
}

void stroke_preserve() {
    float w = stroke_shape().x;
    write_color(_stack.source, calc_aa_blur(w));
}

void stroke() {
    stroke_preserve();
    new_path();
}

bool in_fill() {
    return (_stack.shape.y <= 0.0);
}

bool in_stroke() {
    float w = stroke_shape().y;
    return (w <= 0.0);
}

void set_source_rgba(vec4 c) {
    c = clamp(c, vec4(0.0), vec4(1.0));
    c.rgb = c.rgb*c.rgb;
    if (_stack.source_blend == Multiply) {
        _stack.source *= c;
    } else if (_stack.source_blend == Alpha) {
    	float src_a = c.a;
    	float dst_a = _stack.premultiply?1.0:src_a;
	    _stack.source =
            vec4(_stack.source.rgb * (1.0 - src_a) + c.rgb * dst_a,
                 max(_stack.source.a, c.a));
    } else {
    	_stack.source = c;
    }
}

void set_source_rgba(float r, float g, float b, float a) {
    set_source_rgba(vec4(r,g,b,a)); }

void set_source_rgb(vec3 c) {
    set_source_rgba(vec4(c,1.0));
}

void set_source_rgb(float r, float g, float b) { set_source_rgb(vec3(r,g,b)); }

void set_source(sampler2D image) {
    set_source_rgba(texture(image, _stack.position.xy));
}

void set_source_linear_gradient(vec4 color0, vec4 color1, vec2 p0, vec2 p1) {
    vec2 pa = _stack.position.xy - p0;
    vec2 ba = p1 - p0;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    set_source_rgba(mix(color0, color1, h));
}

void set_source_linear_gradient(vec3 color0, vec3 color1, vec2 p0, vec2 p1) {
    set_source_linear_gradient(vec4(color0, 1.0), vec4(color1, 1.0), p0, p1);
}

void set_source_radial_gradient(vec4 color0, vec4 color1, vec2 p, float r) {
    float h = clamp( length(_stack.position.xy - p) / r, 0.0, 1.0 );
    set_source_rgba(mix(color0, color1, h));
}

void set_source_radial_gradient(vec3 color0, vec3 color1, vec2 p, float r) {
    set_source_radial_gradient(vec4(color0, 1.0), vec4(color1, 1.0), p, r);
}

void set_source_blend_mode(int mode) {
    _stack.source_blend = mode;
}

vec2 length2(vec4 a) {
    return vec2(length(a.xy),length(a.zw));
}

vec2 dot2(vec4 a, vec2 b) {
    return vec2(dot(a.xy,b),dot(a.zw,b));
}

void rounded_rectangle(vec2 o, vec2 s, float r) {
    s = (s * 0.5);
    r = min(r, min(s.x, s.y));
    o += s;
    s -= r;
    vec4 d = abs(o.xyxy - _stack.position) - s.xyxy;
    vec4 dmin = min(d,0.0);
    vec4 dmax = max(d,0.0);
    vec2 df = max(dmin.xz, dmin.yw) + length2(dmax);
    add_field(df - r);
}

void rounded_rectangle(float ox, float oy, float sx, float sy, float r) {
    rounded_rectangle(vec2(ox,oy), vec2(sx,sy), r);
}

void rectangle(vec2 o, vec2 s) {
    rounded_rectangle(o, s, 0.0);
}

void rectangle(float ox, float oy, float sx, float sy) {
    rounded_rectangle(vec2(ox,oy), vec2(sx,sy), 0.0);
}

void circle(vec2 p, float r) {
    vec4 c = _stack.position - p.xyxy;
    add_field(vec2(length(c.xy),length(c.zw)) - r);
}
void circle(float x, float y, float r) { circle(vec2(x,y),r); }

// from https://www.shadertoy.com/view/4sS3zz
float sdEllipse( vec2 p, in vec2 ab )
{
	p = abs( p ); if( p.x > p.y ){ p=p.yx; ab=ab.yx; }

	float l = ab.y*ab.y - ab.x*ab.x;
    if (l == 0.0) {
        return length(p) - ab.x;
    }

    float m = ab.x*p.x/l;
	float n = ab.y*p.y/l;
	float m2 = m*m;
	float n2 = n*n;

    float c = (m2 + n2 - 1.0)/3.0;
	float c3 = c*c*c;

    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;

    float co;

    if( d<0.0 )
    {
        float p = acos(q/c3)/3.0;
        float s = cos(p);
        float t = sin(p)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = ( ry + sign(l)*rx + abs(g)/(rx*ry) - m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow( abs(q+h), 1.0/3.0 );
        float u = sign(q-h)*pow( abs(q-h), 1.0/3.0 );
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        float p = ry/sqrt(rm-rx);
        co = (p + 2.0*g/rm - m)/2.0;
    }

    float si = sqrt( 1.0 - co*co );

    vec2 r = vec2( ab.x*co, ab.y*si );

    return length(r - p ) * sign(p.y-r.y);
}

void ellipse(vec2 p, vec2 r) {
    vec4 c = _stack.position - p.xyxy;
    add_field(vec2(sdEllipse(c.xy, r), sdEllipse(c.zw, r)));
}

void ellipse(float x, float y, float rw, float rh) {
    ellipse(vec2(x,y), vec2(rw, rh));
}

void move_to(vec2 p) {
    _stack.start_pt = p;
    _stack.last_pt = p;
}

void move_to(float x, float y) { move_to(vec2(x,y)); }

// stroke only
void line_to(vec2 p) {
    vec4 pa = _stack.position - _stack.last_pt.xyxy;
    vec2 ba = p - _stack.last_pt;
    vec2 h = clamp(dot2(pa, ba)/dot(ba,ba), 0.0, 1.0);
    vec2 s = sign(pa.xz*ba.y-pa.yw*ba.x);
    vec2 d = length2(pa - ba.xyxy*h.xxyy);
    add_field(d);
    add_clip(d * s);
    _stack.last_pt = p;
}

void line_to(float x, float y) { line_to(vec2(x,y)); }

void close_path() {
    line_to(_stack.start_pt);
}

// from https://www.shadertoy.com/view/ltXSDB

// Test if point p crosses line (a, b), returns sign of result
float test_cross(vec2 a, vec2 b, vec2 p) {
    return sign((b.y-a.y) * (p.x-a.x) - (b.x-a.x) * (p.y-a.y));
}

// Determine which side we're on (using barycentric parameterization)
float bezier_sign(vec2 A, vec2 B, vec2 C, vec2 p) {
    vec2 a = C - A, b = B - A, c = p - A;
    vec2 bary = vec2(c.x*b.y-b.x*c.y,a.x*c.y-c.x*a.y) / (a.x*b.y-b.x*a.y);
    vec2 d = vec2(bary.y * 0.5, 0.0) + 1.0 - bary.x - bary.y;
    return mix(sign(d.x * d.x - d.y), mix(-1.0, 1.0,
        step(test_cross(A, B, p) * test_cross(B, C, p), 0.0)),
        step((d.x - d.y), 0.0)) * test_cross(A, C, B);
}

// Solve cubic equation for roots
vec3 bezier_solve(float a, float b, float c) {
    float p = b - a*a / 3.0, p3 = p*p*p;
    float q = a * (2.0*a*a - 9.0*b) / 27.0 + c;
    float d = q*q + 4.0*p3 / 27.0;
    float offset = -a / 3.0;
    if(d >= 0.0) {
        float z = sqrt(d);
        vec2 x = (vec2(z, -z) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        return vec3(offset + uv.x + uv.y);
    }
    float v = acos(-sqrt(-27.0 / p3) * q / 2.0) / 3.0;
    float m = cos(v), n = sin(v)*1.732050808;
    return vec3(m + m, -n - m, n - m) * sqrt(-p / 3.0) + offset;
}

// Find the signed distance from a point to a quadratic bezier curve
float bezier(vec2 A, vec2 B, vec2 C, vec2 p)
{
    B = mix(B + vec2(1e-4), B, abs(sign(B * 2.0 - A - C)));
    vec2 a = B - A, b = A - B * 2.0 + C, c = a * 2.0, d = A - p;
    vec3 k = vec3(3.*dot(a,b),2.*dot(a,a)+dot(d,b),dot(d,a)) / dot(b,b);
    vec3 t = clamp(bezier_solve(k.x, k.y, k.z), 0.0, 1.0);
    vec2 pos = A + (c + b*t.x)*t.x;
    float dis = length(pos - p);
    pos = A + (c + b*t.y)*t.y;
    dis = min(dis, length(pos - p));
    pos = A + (c + b*t.z)*t.z;
    dis = min(dis, length(pos - p));
    return dis * bezier_sign(A, B, C, p);
}

void curve_to(vec2 b1, vec2 b2) {
    vec2 shape = vec2(
        bezier(_stack.last_pt, b1, b2, _stack.position.xy),
        bezier(_stack.last_pt, b1, b2, _stack.position.zw));
    add_field(abs(shape));
    add_clip(shape);
	_stack.last_pt = b2;
}

void curve_to(float b1x, float b1y, float b2x, float b2y) {
    curve_to(vec2(b1x,b1y),vec2(b2x,b2y));
}

void graph(vec2 p, float f_x, float df_x) {
    add_field(abs(f_x - p.y) / sqrt(1.0 + (df_x * df_x)));
}

void graph(vec2 p, float f_x, vec2 df_x) {
    add_field(abs(f_x) / length(df_x));
}

//////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	 aspect = vec2(iResolution.x / iResolution.y, 1.0);
	 ScreenH = min(iResolution.x,iResolution.y);
	 AA = ScreenH*0.4;
	 AAINV = 1.0 / AA;

    init(fragCoord);

    paint();

    blit(fragColor);
}

#ifdef GLSLSANDBOX
void main() {
    mainImage(gl_FragColor, gl_FragCoord.xy);
}
#endif
