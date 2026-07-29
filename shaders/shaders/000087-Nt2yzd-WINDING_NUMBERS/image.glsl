// Image (image) — WINDING NUMBERS by alro
// https://www.shadertoy.com/view/Nt2yzd

/*
    The winding number of a point describes how many full revolutions a curve makes around it.
    Open curves produce interesting visuals. We discretise parametric curves into linear
    segments and find the signed angle between the vectors connecting a point to the segment.
    The sum of these angles, divided by 2PI radians, gives the winding number.

    Based on:
        https://en.wikipedia.org/wiki/Winding_number
    [1] https://igl.ethz.ch/projects/winding-number/
        https://twitter.com/keenanisalive/status/1448036393012322313
        https://www.shadertoy.com/view/Wddyz2

*/

#define PI 3.1415926536
#define TWO_PI 6.2831853072

const float sceneSwitchSpeed = 0.21;

// Uncomment defines to control scene and colour

/* 
    0: Circle
    1: Heart
    2: Star
    3: Lemniscate
*/

//#define SCENE 1

/*
    0: Black and white
    1: Pastel rainbow
    2: Red and purple
    3: Blue
*/

//#define PALETTE 2


// https://math.stackexchange.com/questions/3020095/signed-angle-in-plane:
// "the ratio of the cross product and scalar product is the tangent of the angle"
// From [1]: "The tangent of the signed angle between a and b is det([ab]) / dot(ab)"
float signedAngle(vec2 a, vec2 b){
    // atan(y, x) returns the angle whose arctangent is y / x. Value in [-pi, pi]
    return atan(a.x*b.y - a.y*b.x, dot(a, b));
}


// https://iquilezles.org/articles/palettes/
vec3 getColour(float t, int palette){


    if(palette == 0){

        // Black and white
        return vec3(-0.5 * t + 0.45);
    }

    vec3 a;
    vec3 b;
    vec3 c;
    vec3 d;
    
    if(palette == 1){

        // Pastel rainbow
        // Animated

        t *= 0.45;
        t += 0.1 * iTime;

        a = vec3(0.65);
        b = 1.0 - a;
        c = vec3(1.0,1.0,1.0);
        d = vec3(0.15,0.5,0.75);

    }else if(palette == 2){

        // Red and purple

        t *= -0.3;
        t += 0.65;

        a = vec3(0.55, 0.5, 0.7);
        b = 1.0-a;
        c = vec3(1.0,1.0,1.0);
        d = vec3(0.15,0.95,0.8);

    }else if(palette == 3){

        // Blue
        // Same as above with different t

        t *= 0.35;
        t += 0.3;

        a = vec3(0.55, 0.5, 0.7);
        b = 1.0-a;
        c = vec3(1.0,1.0,1.0);
        d = vec3(0.15,0.95,0.8);

    }

    return a + b * cos(TWO_PI * (c * t + d));
}

vec2 getCircle(float t){
    return vec2(sin(t), cos(t));
}

// http://mathworld.wolfram.com/Lemniscate.html
vec2 getLemniscate(float t){
    float a = 1.5;
    return vec2((a * cos(t)) / (1.0 + (sin(t) * sin(t))), 
                (a * sin(t) * cos(t))/ (1.0 + (sin(t) * sin(t))));
}

// http://mathworld.wolfram.com/HeartCurve.html
vec2 getHeart(float t){
    return 0.05 * vec2(1, -1) * vec2(16.0 * sin(t) * sin(t) * sin(t),
                -(13.0 * cos(t) - 5.0 * cos(2.0 * t)
                - 2.0 * cos(3.0 * t) - cos(4.0 * t))) + vec2(0, 0.1);
}

vec2 rotate2d(vec2 v, float a){
    return v * mat2(cos(a),-sin(a), sin(a), cos(a));
}

// https://en.wikipedia.org/wiki/Hypotrochoid
// https://mathworld.wolfram.com/Hypotrochoid.html
vec2 getHypotrochoid(float t){
    float a = 5.0;
    float b = 3.0;
    float h = 5.0;
    float a_b  = a - b;
    float t_ab = t * a_b / b;
    return vec2(a_b * cos(t) + h * cos(t_ab), a_b * sin(t) - h * sin(t_ab));
}


vec2 getPosition(float t, int scene){

    if(scene == 0){
        return getCircle(t);
    }else if(scene == 1){
        return getHeart(t);
    }else if(scene == 2){
        return getHypotrochoid(t);
    }else{
        return getLemniscate(t);
    }

}

// https://www.shadertoy.com/view/4djSRW
float hash11(float p){
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    uv -= 0.5;
    uv.y /= iResolution.x / iResolution.y;
    uv *= 4.0;
    
    // 0: Circle
    // 1: Heart
    // 2: Star
    // 3: Lemniscate
    int scene = int(floor(mod(sceneSwitchSpeed * iTime, 4.0)));
    
    // 0: Black and white
    // 1: Pastel rainbow
    // 2: Red and purple
    // 3: Blue
    
    // Pick a random palette. Should use a better method with uniform distribution which
    // avoids picking the same value consecutively.
    float rand = mod(1.0 + 4.0 * hash11(floor(sceneSwitchSpeed * iTime)), 4.0);
    
    int palette = int(rand);
    
#ifdef SCENE
    scene = SCENE;
#endif

#ifdef PALETTE
    palette = PALETTE;
#endif
    
    float angle = 0.0;
    float segments = 16.0;

    float delta = (0.25 * (TWO_PI)) / segments;
    
    float speed = 2.0;
    float radius = 1.0;
    
    // Heart
    if(scene == 1){
        segments = 16.0;
        speed = 2.0;
        delta = (0.15 * (TWO_PI)) / segments;
    }
    
    // Star
    if(scene == 2){
        radius = 0.142;
        speed = 4.0;
        delta = (0.08 * (6.0 * PI)) / segments;
        // Rotate star
        uv = rotate2d(uv, -0.31415);
    }
    
    // Lemniscate
    if(scene == 3){
        segments = 32.0;
        speed = 2.5;
        delta = (0.25 * (TWO_PI)) / segments;
    }
    
    vec2 c0;
    vec2 c1;
    float t = speed * iTime;

    for(float i = 0.0; i < segments; i += 1.0){
        
        c0 = radius * getPosition(t + (i) * delta, scene);
        c1 = radius * getPosition(t + (i + 1.0) * delta, scene);
        angle += signedAngle(c0-uv, c1-uv);
        
        // Add additional lines for some shapes
        
        // Circle
        if(scene == 0){
            c0 = 0.333 * radius * getPosition(2.2 * t + (i) * delta, scene);
            c1 = 0.333 * radius * getPosition(2.2 * t + (i + 1.0) * delta, scene);
            angle -= signedAngle(c0-uv, c1-uv);
            
            c0 = 0.666 * radius * getPosition(-t + (i) * delta, scene);
            c1 = 0.666 * radius * getPosition(-t + (i + 1.0) * delta, scene);
            angle += signedAngle(c0-uv, c1-uv);
        }
        
        // Heart
        if(scene == 1){
            c0 = radius * getPosition(t + (i) * delta + 3.0, scene);
            c1 = radius * getPosition(t + (i + 1.0) * delta + 3.0, scene);
            angle += signedAngle(c0-uv, c1-uv);
        }
        
        // Star
        if(scene == 2){
            c0 = radius * getPosition(t + (i) * delta + 3.0, scene);
            c1 = radius * getPosition(t + (i + 1.0) * delta + 3.0, scene);
            angle += signedAngle(c0-uv, c1-uv);
        }
    }

    vec3 col = getColour(angle / TWO_PI, palette);
   
    fragColor = vec4(col, 1.0);
}