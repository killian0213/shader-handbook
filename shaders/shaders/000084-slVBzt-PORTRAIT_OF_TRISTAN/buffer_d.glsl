// Buffer D (buffer) — PORTRAIT OF TRISTAN by alro
// https://www.shadertoy.com/view/slVBzt

/*
    R: Lip detail
    G: Lip map
    B: Eyebrow height map
    
    Rendered only on start or resolution change.
*/

// Variable iterator initializer to stop loop unrolling
#define ZERO (min(float(iFrame),0.0))

#define EYEBROW_COUNT 1024.0

vec2 rotate(vec2 p, float a){
    return mat2(cos(a), sin(a), -sin(a), cos(a)) * p;
}

float sdCircle( vec2 p, float r ){
    return length(p) - r;
}

float sdUnevenCapsule( vec2 p, float r1, float r2, float h ){
    p.x = abs(p.x);
    float b = (r1-r2)/h;
    float a = sqrt(1.0-b*b);
    float k = dot(p,vec2(-b,a));
    if( k < 0.0 ) return length(p) - r1;
    if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
    return dot(p, vec2(a,b) ) - r1;
}

//https://www.shadertoy.com/view/MlKcDD
//Signed distance to a quadratic bezier
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C){    
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    float res = 0.0;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0){ 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );

        // 1 root
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    }else{
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );

        // 3 roots
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);
        
        res = dis;

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        res = min(res,dis);

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        res = min(res,dis);

        res = sqrt( res );
    }
    
    return res;
}

float mouthLine(vec2 pos){

    const int N = 6;
    vec2 points[N];
    pos.y += 0.002;
    points[0] = vec2(-0.225, -0.27);
    points[1] = vec2(-0.07, -0.2075);
    points[2] = vec2(-0.0, -0.21);
    points[3] = vec2(0.07, -0.2075);
    points[4] = vec2(0.29, -0.3);
    
    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
    float dist = 1e10;
    for(int i = 0; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[min(i+1, N-1)]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }
    return dist;
}

#define SIZE 1024

// https://www.shadertoy.com/view/4djSRW
vec2 hash(vec2 p){
    p = mod(p, float(SIZE));
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return 2.0 * fract((p3.xx+p3.yz)*p3.zy) - 1.0;
}

float hash(float p){
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}


float getEyebrowHeight(vec2 pos, float id){

    vec2 o = pos;

    float r = mix(0.0035, 0.0055, smoothstep(0.0, 0.35, float(id)/512.0) * smoothstep(1.0, 0.85, id/EYEBROW_COUNT));
    
    float rand = hash(float(id));
    
    pos.y -= mix(0.1, 0.2, saturate(id/(0.25*EYEBROW_COUNT))) * rand;
    float angle = PI * mix(0.3, 0.65, hash(id));
    
    angle *= mix(0.25, 1.0, saturate(id/(0.25*EYEBROW_COUNT)));
    pos = rotate(pos, angle);

    const int N = 4;
    vec2 points[N];
    points[0] = vec2(0.0, 0.0);
    points[1] = vec2(mix(-0.025, 0.025, hash(float(id + 23.0))), 0.2);
    points[2] = vec2(0.1, 0.35);
    points[3] = vec2(0.1, 0.35);
    
    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
    float dist = 1e10;
    for(int i = 0; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }
    
    
    float t = dist / r;
    float z = sqrt(1.0-t*t) * r;
    z *= smoothstep(r, 0.999*r, dist);
    z *= mix(0.5, 1.0, hash(float(id+2.0)));
    z *= 3.0*smoothstep(0.0, 0.2, pos.y)*smoothstep(0.2, 0.0, pos.y);

    return z;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){

    bool resolutionChanged = texelFetch(iChannel0, ivec2(0.5, 2.5), 0).r > 0.0;
    
    if(iFrame == 0 || resolutionChanged){
        vec2 uv = fragCoord / iResolution.xy;

        vec2 p = uv;
        p -= 0.5;

        vec2 q = p;
        q.y += 0.18;

        float mouthDist = mouthLine(q);
        float h = 0.0;

        q = p;
        q.x = abs(q.x);
        q.x += smoothstep(mix(0.075, 0.025, smoothstep(0.2, 0.0, abs(p.x))), -0.7, mouthDist);

        float lipNoise = 0.25 * pow(abs(sin(175.0*q.x)), 0.25);

        float lips = lipNoise * smoothstep(mix(0.005, 0.05, smoothstep(0.2, 0.05, abs(p.x))), -0.75, mouthDist);
        lips -= 100.0*smoothstep(0.0025, -1.5, mouthDist);
        h = saturate(lips);
        float d = ((1.0-lipNoise)*smoothstep(mix(0.005, 0.075, smoothstep(0.2, 0.05, abs(p.x))), mix(-0.1, -0.02, smoothstep(0.2, 0.0, abs(p.x))), mouthDist));

        q = uv;
        q -= 0.5;
        q += vec2(0.5, 0.175);
        float eyebrowHeight = 0.0;
        q.x -= 0.125;
        q.y -= 0.015;
        for(float i = ZERO; i < EYEBROW_COUNT; i++){
            eyebrowHeight = max(eyebrowHeight, getEyebrowHeight(q, i));
            q.x -= mix(0.5*0.0005, 0.5*0.002, i/EYEBROW_COUNT);
            q.y += mix(0.65*-0.0006, 0.65*0.00045, i/EYEBROW_COUNT);
        }
        
       
        fragColor = vec4(saturate(h), saturate(1.0-d), eyebrowHeight, 0.0);
    
    }else{
        fragColor = texelFetch(iChannel1, ivec2(fragCoord), 0);
    }
    
}