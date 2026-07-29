// Common (common) — Android Runtime by shau
// https://www.shadertoy.com/view/DltBRM

// Created by SHAU - 2023
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------

#define R iResolution.xy
#define PI 3.141592
#define S(a, b, v) smoothstep(a, b, v)

//Fabrice - compact rotation
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

#define CAM vec2(30.5,0.5)
#define LA vec2(31.5,0.5)

#define RIGHT 1.0
#define LEFT -1.0

#define R_HIP      vec2(0.5, 0.5)
#define R_KNEE     vec2(1.5, 0.5)
#define R_ANKLE    vec2(2.5, 0.5)
#define R_FOOT     vec2(3.5, 0.5)
#define R_TOE      vec2(4.5, 0.5)
#define L_HIP      vec2(5.5, 0.5)
#define L_KNEE     vec2(6.5, 0.5)
#define L_ANKLE    vec2(7.5, 0.5)
#define L_FOOT     vec2(8.5, 0.5)
#define L_TOE      vec2(9.5, 0.5)
#define R_SHOULDER vec2(10.5, 0.5)
#define R_ELBOW    vec2(11.5, 0.5)
#define R_WRIST    vec2(12.5, 0.5)
#define R_KNUCKLE  vec2(13.5, 0.5)
#define R_FINGER   vec2(14.5, 0.5)
#define L_SHOULDER vec2(15.5, 0.5)
#define L_ELBOW    vec2(16.5, 0.5)
#define L_WRIST    vec2(17.5, 0.5)
#define L_KNUCKLE  vec2(18.5, 0.5)
#define L_FINGER   vec2(19.5, 0.5)
#define B_SPINE    vec2(20.5, 0.5)
#define T_SPINE    vec2(21.5, 0.5)
#define HEAD       vec2(22.5, 0.5)

