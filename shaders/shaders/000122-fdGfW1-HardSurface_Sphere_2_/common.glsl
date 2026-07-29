// Common (common) — HardSurface Sphere [2] by tdhooper
// https://www.shadertoy.com/view/fdGfW1

//#define LOOP
//#define LOOP2
//#define NIGHT_MODE
//#define CROP


// skaplun https://www.shadertoy.com/view/7tf3Ws
float easeOutBack(float x, float t) {
    float c1 = t;
    float c3 = c1 + 1.;

    return 1. + c3 * pow(x - 1., 3.) + c1 * pow(x - 1., 2.);
}

float easeInOutBack(float x) {
    float c1 = 1.70158;
    float c2 = c1 * 1.525;

    return x < .5
      ? (pow(2. * x, 2.) * ((c2 + 1.) * 2. * x - c2)) / 2.
      : (pow(2. * x - 2., 2.) * ((c2 + 1.) * (x * 2. - 2.) + c2) + 2.) / 2.;
}

float easeSnap(float x) {
    x = pow(x, .75);
    x = easeInOutBack(x);
    return x;
}

float linearstep(float a, float b, float t) {
    return clamp((t - a) / (b - a), 0., 1.);
}

#ifdef LOOP
float timeOffset = (92. + 100.) * (3./4.);
float timeGap = 3.;
#else
#ifdef LOOP2
    float timeOffset = (92. + 100.);
    float timeGap = 4.;
#else
    float timeOffset = (92. + 100.);
    float timeGap = 4.;
#endif
#endif

float gTime;
float gDuration;
float gSpeed;

void initTime(float time) {
    gTime = time;
    gSpeed = 1.;
    gDuration = 14.;
    
    #ifdef LOOP
    gSpeed = 1.5;
    gDuration = (3. * timeGap) / gSpeed; // 6
    gTime /= gDuration;
    gTime = fract(gTime);
    gTime *= gDuration;
    gTime *= gSpeed;
    gTime += .25;
    #endif
    
    #ifdef LOOP2
    gSpeed = 1.;
    gDuration = (3. * timeGap) / gSpeed; // 12
    gTime /= gDuration;
    gTime = fract(gTime);
    gTime *= gDuration;
    gTime *= gSpeed;
    //gTime += .25;
    #endif
}

float tFloor(float time) {
    time += timeOffset;
    time -= timeGap / 3.;
    return floor(time / timeGap);
}

float tFract(float time) {
    time += timeOffset;
    time -= timeGap / 3.;
    return fract(time / timeGap) * timeGap * .5;
}

vec3 primaryAxis(vec3 p) {
    vec3 a = abs(p);
    return (1.-step(a.xyz, a.yzx))*step(a.zxy, a.xyz)*sign(p);
}