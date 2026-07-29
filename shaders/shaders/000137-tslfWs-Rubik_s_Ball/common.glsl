// Common (common) — Rubik's Ball by tdhooper
// https://www.shadertoy.com/view/tslfWs


#define LOOP_DURATION 5.
#define MOVE_COUNT 6.
#define TIME_OFFSET .3

// axisX, axisY, axisZ, turns 
vec4 moves[6] = vec4[6](
    vec4(1,0,0, 2.),
    vec4(0,1,0, -1.),
    vec4(0,-1,0, -3.),
    vec4(0,0,-1, 2.),
    vec4(0,-1,0, -1.),
    vec4(0,1,0, -3.)
);


// Quaternions
// https://github.com/mattatz/ShibuyaCrowd/blob/master/source/shaders/common/quaternion.glsl

#define QUATERNION_IDENTITY vec4(0, 0, 0, 1)

#define PI 3.1415926

// Quaternion multiplication
// http://mathworld.wolfram.com/Quaternion.html
vec4 qmul(vec4 q1, vec4 q2) {
	return vec4(
		q2.xyz * q1.w + q1.xyz * q2.w + cross(q1.xyz, q2.xyz),
		q1.w * q2.w - dot(q1.xyz, q2.xyz)
	);
}

// Vector rotation with a quaternion
// http://mathworld.wolfram.com/Quaternion.html
vec3 rotate_vector(vec3 v, vec4 r) {
	vec4 r_c = r * vec4(-1, -1, -1, 1);
	return qmul(r, qmul(vec4(v, 0), r_c)).xyz;
}

// A given angle of rotation about a given axis
vec4 rotate_angle_axis(float angle, vec3 axis) {
	float sn = sin(angle * 0.5);
	float cs = cos(angle * 0.5);
	return vec4(axis * sn, cs);
}

vec4 q_conj(vec4 q) {
	return vec4(-q.x, -q.y, -q.z, q.w);
}

vec4 q_slerp(vec4 a, vec4 b, float t) {
    // if either input is zero, return the other.
    if (length(a) == 0.0) {
        if (length(b) == 0.0) {
            return QUATERNION_IDENTITY;
        }
        return b;
    } else if (length(b) == 0.0) {
        return a;
    }

    float cosHalfAngle = a.w * b.w + dot(a.xyz, b.xyz);

    if (cosHalfAngle >= 1.0 || cosHalfAngle <= -1.0) {
        return a;
    } else if (cosHalfAngle < 0.0) {
        b.xyz = -b.xyz;
        b.w = -b.w;
        cosHalfAngle = -cosHalfAngle;
    }

    float blendA;
    float blendB;
    if (cosHalfAngle < 0.99) {
        // do proper slerp for big angles
        float halfAngle = acos(cosHalfAngle);
        float sinHalfAngle = sin(halfAngle);
        float oneOverSinHalfAngle = 1.0 / sinHalfAngle;
        blendA = sin(halfAngle * (1.0 - t)) * oneOverSinHalfAngle;
        blendB = sin(halfAngle * t) * oneOverSinHalfAngle;
    } else {
        // do lerp if angle is really small.
        blendA = 1.0 - t;
        blendB = t;
    }

    vec4 result = vec4(blendA * a.xyz + blendB * b.xyz, blendA * a.w + blendB * b.w);
    if (length(result) > 0.0) {
        return normalize(result);
    }
    return QUATERNION_IDENTITY;
}
