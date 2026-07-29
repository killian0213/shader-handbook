// Buffer A (buffer) — pencil_drawn_crystal by skaplun
// https://www.shadertoy.com/view/styGDw

#define AA (10./max(iResolution.x, iResolution.y))

const int CUTOFF_PLANES_COUNT = 12;
vec4 cutoffPlanes[CUTOFF_PLANES_COUNT];
float world(vec3 p){
    float res = length(p) - 3.;
    for(int i=0; i<CUTOFF_PLANES_COUNT; i++){
        res = max(res, sdPlane(p, cutoffPlanes[i].xyz, -cutoffPlanes[i].w));
    }
    return res;
}

const int MAX_MARCHING_STEPS = 64;
float march(in Ray r, float minDst, float maxDst){
    float t = minDst;
    for(int i = 0; i <= MAX_MARCHING_STEPS; i++){
        vec3 p = r.origin + r.direction * t;
        float dst = world(p);
        if(dst < .01)
            return t;
        t += dst;
        if(t > maxDst)
            break;
    }
    return -1.;
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        world(vec3(p.x + EPSILON, p.y, p.z)) - world(vec3(p.x - EPSILON, p.y, p.z)),
        world(vec3(p.x, p.y + EPSILON, p.z)) - world(vec3(p.x, p.y - EPSILON, p.z)),
        world(vec3(p.x, p.y, p.z  + EPSILON)) - world(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

float crystalColor(vec3 pos, vec3 viewDir, float specMul, vec2 uv){
    vec3 norm = estimateNormal(pos);
            
    vec3 lights[] = vec3[2](vec3(5., 3., -1.), vec3(-5., 0., 2.));
    float totalDiff = 0.;
    float totalSpec = 0.;
    for(int i=0; i<2; i++) {
        vec3 lightDir = normalize(lights[i] - pos);
        vec3 reflectDir = reflect(-lightDir, norm);
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.);
        totalSpec += .5 * spec;
        totalDiff += max(dot(norm, lightDir), 0.0);
    }
    return .2 + totalDiff + totalSpec * specMul;
}

vec3 color(in vec2 fragCoord){
    {
        int planeIndex = 0;
        for(float i=0.; i<float(CUTOFF_PLANES_COUNT/3); i++){
            vec3 nrm = SIDE;
            vec3 h = hash33(vec3(3.17, 47.121, i)) * 2. - 1.;
            nrm *= rx(radians(25. + 15. * h.x));
            nrm *= ry(radians(90. * i + 15. * h.y));
            float dst = 1.5 + .15 * h.z;
            cutoffPlanes[planeIndex++] = vec4(nrm, dst);
            
            nrm = SIDE;
            h = hash33(vec3(41.17, i, 71.121)) * 2. - 1.;
            nrm *= rx(radians(-25. + 5. * h.x));
            nrm *= ry(radians(90. * i + 15. * h.y));
            dst = 1.5 + .15 * h.z;
            cutoffPlanes[planeIndex++] = vec4(nrm, dst);
            
            nrm = SIDE;
            h = hash33(vec3(i, 69.121, 47.17)) * 2. - 1.;
            nrm *= rx(radians(15. * h.x));
            nrm *= ry(radians(90. * i + 45.));
            dst = 1.5 - .1 * h.z;
            cutoffPlanes[planeIndex++] = vec4(nrm, dst);
        }
    }
    
    vec2 uv = fragCoord/iResolution.y;
    float ang = (iMouse.x/iResolution.x) * PI2 + iTime * .5;
    vec3 eye = vec3(20. * sin(ang), 3., 20. * cos(ang));
    vec3 viewDir = rayDirection(45., iResolution.xy, fragCoord);
    vec3 worldDir = viewMatrix(eye, vec3(0., -1., 0.), vec3(0., 1., 0.)) * viewDir;
    
    Ray r = Ray(eye, worldDir);
    
    float color = 0.;
    vec3 dst = vec3(MAX_FLOAT);
    if(box_hit(Box(vec3(0.), vec3(2., 3.2, 2.)), r, dst.xy)){
        dst.z = march(r, dst.x, dst.y);
        if (dst.z >= 0.) {
            vec3 pos = r.origin + r.direction * dst.z;
            color += crystalColor(pos, r.direction, 1., uv);
        }else{
            dst.z = MAX_FLOAT;
        }
    }
    
    float hitFloor = (-3.-r.origin.y)/r.direction.y;
    if(hitFloor >= 0. && hitFloor < dst.z){
        vec3 p = r.origin + r.direction * hitFloor;
        float f = mod(floor(p.z * .25) + floor(p.x * .25), 2.);
        color = .5 + f * .5;
        color *= smoothstep(150., 25., distance(p.xz, vec2(0.)));
        
        Ray r2 = Ray(p, reflect(r.direction, vec3(0., 1., 0.)));
        vec3 dst = vec3(-MAX_FLOAT);
        if(box_hit(Box(vec3(0.), vec3(2., 3.2, 2.)), r2, dst.xy)){
            dst.z = march(r2, max(dst.x, 0.), max(dst.x, dst.y));
            if (dst.z >= 0.) {
                vec3 pos = r2.origin + r2.direction * dst.z;
                color += .5 * crystalColor(pos, r2.direction, .1, uv);
            }
        }
    }
    
    return vec3(1.) * color;
}

#define SS 1
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    fragColor = vec4(0.);
    for(int y = 0; y < SS; ++y)
        for(int x = 0; x < SS; ++x){
            fragColor.rgb += clamp(color(fragCoord + vec2(x, y) / float(SS)), 0., 1.);
        }
    
    fragColor.rgb /= float(SS * SS);
}