// Common (common) — Alas, poor Yorick! by shau
// https://www.shadertoy.com/view/3ddXR4

// Created by SHAU - 2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.141592
#define EPS .005
#define FAR 20.
#define ZERO (min(iFrame,0))
#define R iResolution.xy
#define T iTime

#define SKULL 1.0
#define TEETH 2.0
#define STONE_I 3.0 
#define STONE_O 4.0 
#define GLOW 5.0
#define BLACK 6.0

//Fabrice - compact rotation
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}