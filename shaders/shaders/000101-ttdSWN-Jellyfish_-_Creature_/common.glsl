// Common (common) — Jellyfish - Creature  by senzheng
// https://www.shadertoy.com/view/ttdSWN

#define PI 3.14159265359

struct Hit {
    float d;
    vec2 uv;
    vec3 col;
    float ref;
    float spe;
    float rough;
    float lightD;
    vec3 lightCol;
    float lightStrength;
	float sss;
    float diffuseTex;
};
    
vec2 rotate(vec2 v, float a) {
    return vec2(cos(a)*v.x + sin(a)*v.y, -sin(a)*v.x + cos(a)*v.y);
}

mat4 translate( float x, float y, float z )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 x,   y,   z,   1.0 );
}