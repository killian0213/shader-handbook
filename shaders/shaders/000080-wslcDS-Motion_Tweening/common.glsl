// Common (common) — Motion Tweening by Shane
// https://www.shadertoy.com/view/wslcDS

// Easing functions are their own topic, but a lot of it is straight forward.
// Usage is easy. Normalize the time between zero and one, then choose the 
// one you're after.

const float PI = 3.14159265358979;

// Robert Penner's easing functions in GLSL.
// Available as a module for glslify. http://stack.gl/glsl-easings/

float easeInOutCubic(float t){

    return t<0.5 ? 4.*t*t*t : (t - 1.)*(2.*t - 2.)*(2.*t - 2.) + 1.;
}

float easeInOutQuint(float t){

    return t<.5 ? 16.*t*t*t*t*t : 1. +16.*(--t)*t*t*t*t;
}

float easeOutQuad(float t) {
    return -1. * t * (t - 2.);
}

float easeInQuad(float t) {
    return t * t;
}

 
float bounceOut(float t) {
    
  const float a = 4.0 / 11.0;
  const float b = 8.0 / 11.0;
  const float c = 9.0 / 10.0;

  const float ca = 4356.0 / 361.0;
  const float cb = 35442.0 / 1805.0;
  const float cc = 16061.0 / 1805.0;

  float t2 = t * t;

  return t < a
    ? 7.5625 * t2
    : t < b
      ? 9.075 * t2 - 9.9 * t + 3.4
      : t < c
        ? ca * t2 - cb * t + cc
        : 10.8 * t * t - 20.52 * t + 10.72;
}

float bounceInOut(float t) {
  return t < 0.5
    ? 0.5 * (1.0 - bounceOut(1.0 - t * 2.0))
    : 0.5 * bounceOut(t * 2.0 - 1.0) + 0.5;
}

float bounceIn(float t) {
  return 1.0 - bounceOut(1.0 - t);
}


float elasticOut(float t) {
  return sin(-13.0 * (t + 1.0) * PI/2.) * pow(2.0, -10.0 * t) + 1.0;
}

float circularInOut(float t) {
  return t < 0.5
    ? 0.5 * (1.0 - sqrt(1.0 - 4.0 * t * t))
    : 0.5 * (sqrt((3.0 - 2.0 * t) * (2.0 * t - 1.0)) + 1.0);
}

float exponentialOut(float t) {
  return t == 1.0 ? t : 1.0 - pow(2.0, -10.0 * t);
}

float exponentialIn(float t) {
  return t == 0.0 ? t : pow(2.0, 10.0 * (t - 1.0));
}

float exponentialInOut(float t) {
  return t == 0.0 || t == 1.0
    ? t
    : t < 0.5
      ? +0.5 * pow(2.0, (20.0 * t) - 10.0)
      : -0.5 * pow(2.0, 10.0 - (t * 20.0)) + 1.0;
}


// IQ's unsigned box formula.
float sBox(in vec3 p, in vec3 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}

// IQ's unsigned rectangle formula.
float sBox(in vec2 p, in vec2 b, in float sf){

  return length(max(abs(p) - b + sf, 0.)) - sf;
}

/*
// IQ's signed box formula.
float sBoxS(in vec3 p, in vec3 b, in float sf){

  vec3 d = abs(p) - b + sf;
  return min(max(max(d.x, d.y), d.z), 0.) + length(max(d, 0.)) - sf;
}
*/
