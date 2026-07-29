// Image (image) — Liquid Metalball by NoxWings
// https://www.shadertoy.com/view/7dtSDf

// Scene

#define NUM_REFLECTIONS 5

const float SURF_HIT = 0.01;
const float farPlane = 20.0;
const int maxSteps = 128;

Hit ground(in vec3 p) {
    return Hit(0, -(length(p-vec3(0, 198.8, 0)) - 200.));
}

Hit metaBall(in vec3 p) {
    vec3 q = p;
    q.y += A(cos(animTime * PI) * 1.0 + 1.7, 0.0, 0.0, 4.0);    
    if (animTime > 10.0) {
        float t = animTime - 10.0;
        q.y += -2.5 * t + 0.5 * 10.0 * t*t;
    }
    
    
    q.xz *= rot2D(q.y);
    
    vec3 scale = A(vec3(1), vec3(0.5, 1.0, 0.5), 10., 11.);
    q *= scale;
    
    float r = 1.0;
    r = A(r, 0.2, 10., 10.5);

    float amp = 0.1;
    amp = A(amp, sin(animTime * 30.0) * .05 + 0.1, 8.0, 10.);
    amp = A(amp, 1., 10., 10.5);
    
    r += amp * sin(q.x * 8.0 + animTime * 5.0) * sin(q.y * 8.0) * sin(q.z * 8.0);
    float sphere = sdSphere(q, r);
    
    float definition = A(0.7, 0.3, 10., 10.5);
    sphere *= definition;
    

    return Hit(1, sphere);
}

Hit ballGround(in vec3 p) {
    float blend = A(0.5, 0.0, 0.0, 8.0);
    blend = A(blend, 0.5, 10.0, 11.0);

    return hsmin(metaBall(p), ground(p), blend);
}

Hit map(in vec3 p) {
    Hit h = ballGround(p);
    return h;
}

vec3 mapNormal(in vec3 p, float surfHit) {
    vec2 e = vec2(0.01, 0.0);
 	float d = map(p).d;
    return normalize(vec3(
        d - map(p - e.xyy).d,
        d - map(p - e.yxy).d,
        d - map(p - e.yyx).d
    ));
}

// -----------------------------------------------------------------------------

// Regular sphere tracing
// If maxSteps is hit it returns the closest hit found
TraceResult trace(in vec3 ro, in vec3 rd, in float maxDistance, in int maxSteps) {
    float d = 0.0;
    float closestD = maxDistance;
    Hit closest = Hit(-1, maxDistance);
    
    for (int i=0; i < maxSteps && d < maxDistance; i++) {
    	vec3 p = ro + rd * d;
        Hit h = map(p);
        
        if (h.d < closest.d) {
            closest = h;
            closestD = d;
        }
        if (h.d <= SURF_HIT) return TraceResult(closest.id, d, ro, rd);
        
        d += h.d;
    }
    
    if (d >= maxDistance) {
        return TraceResult(-1, maxDistance, ro, rd);
    }

    return TraceResult(-2, closestD, ro, rd);
}

// Sphere tracing for reflections
//
// If maxSteps is hit it reports the maxDistance
// It also tries to step away from the surface it is reflecting 
// (mostly eyeballing here to avoid artifacts with bent space around the ball)
TraceResult traceReflection(Surface s, in float maxDistance, in int maxSteps) {
    vec3 ro = s.p + s.n * SURF_HIT * 2.0;
    vec3 rd = reflect(s.rd, s.n);
    
    float d = SURF_HIT * 2.0;
    for (int i=0; i < maxSteps && d < maxDistance; i++) {
    
    	vec3 p = ro + rd * d;
        Hit h = map(p);
        
        if (h.d < SURF_HIT) {
            return TraceResult(h.id, d, ro, rd);
        }
        
        d += h.d;
    }
    
    return TraceResult(-1, maxDistance, ro, rd);
}

Surface getSurf(TraceResult tr) { 
    vec3 p = tr.ro + tr.rd * tr.d;
    vec3 n = mapNormal(p, SURF_HIT);
    float ao = 0.0;
    
    return Surface(
        tr.id, // material id
        tr.d,  // distance
        p,    // position
        n,    // normal
        ao,   // ambient occlusion
        tr.rd    // view ray direction
    );
}

struct LightingResult {
    Material mat;
    vec3 color;
};

// On one iteration I used an environment map for reflections too
// but currently I'm not using it, I love the simplicity of the real reflections
vec4 sampleEnv(in samplerCube samp, vec3 dir) {
    dir.xz = rot2D(270. * DEG2RAD) * dir.xz;
    return sRGBToLinear(texture(samp, dir));
}

Material matFromSurface(Surface s) {
    Material m;
    m.albedo    = vec3(0.0);
    m.emissive  = vec3(0.0);
    m.roughness = 1.0;
    m.metallic  = 0.0;
    m.ao = s.ao;

    if (s.materialId == -1) {
        m.albedo    = vec3(0.01);
        m.roughness = 0.85;
    } else if (s.materialId == 0) {
        m.albedo    = vec3(0.01);
        m.roughness = 0.0;
    } else if (s.materialId == 1) {
        m.albedo = vec3(0.1);
        m.roughness = 0.1;
        m.metallic = 1.0;
    } else {
        m.emissive = vec3(1, 0, 1);
    }
    
    return m;
}

vec3 calculateLights(Surface s, Material m) {
    const int lights = 2;
    Light l[2];
    l[0].direction = normalize(vec3(1, 1, 0));
    l[0].ambient = vec3(0.01);
    l[0].color = vec3(3.0);
    l[1].direction = normalize(vec3(-1, 1, 0));
    l[1].ambient = vec3(0.01);
    l[1].color = vec3(3.0);
    
    vec3 color = vec3(0);
    for (int i=0; i < lights; i++) {
        vec3 cont = BRDF(l[i], s, m);
        cont = max(cont, vec3(0));
        color += cont;
    }
    
    return color;
}

LightingResult surfaceLighting(inout Surface s) {  
    if (s.materialId == -1) {
        // Sky
        // This one is a bit hacky, 
        // I wanted some kind of dome with somewhat interesting colors so that reflections looked good
        // I think the dome actually ended up looking somewhat similar to a SH but it was already working this way...
        s.p.y += 1.1;
        vec3 n = normalize(vec3(s.p.x, s.p.y, s.p.z));

        Surface floorS = Surface(
            0,
            s.dist,
            s.p,
            vec3(0,1,0),
            s.ao,
            s.rd
        );
        Material floorM = matFromSurface(s);
        vec3 floorColor = calculateLights(floorS, floorM);
        
        float floorBlend = S(-.2, 1.2, n.y);
        
        Material m = matFromSurface(s);
        s.n = n;
        m.roughness = 1.0;
        
        vec3 color = mix(floorColor, vec3(0), floorBlend);
        
        return LightingResult(m, color);
    } else if (s.materialId == 0) {
        // Floor
        
        Material m = matFromSurface(s);
        vec3 floorColor = calculateLights(s, m);
        
        return LightingResult(m, floorColor);
    } else if (s.materialId == 1) {
        // Ball
        // The floor part here is for the ball, surface parameter blending
        // I should probably do something a bit more clear to blend surface parameters
    
        Surface floorS = Surface(
            0,
            s.dist,
            s.p,
            s.n,
            s.ao,
            s.rd
        );
        Material floorM = matFromSurface(floorS);
        vec3 floorColor = calculateLights(floorS, floorM);
        
        Material m = matFromSurface(s);
        vec3 ballColor = calculateLights(s, m);
        
        float blend = S(-1.1, -0.9, s.p.y); 
        vec3 color = mix(floorColor, ballColor, blend);
        
        m.metallic = mix(floorM.metallic, m.metallic, blend);
        m.roughness = mix(floorM.roughness, m.roughness, blend);
        
        return LightingResult(m, color);
    } else {
        // error, unset material
        Material m = matFromSurface(s);
        vec3 color = calculateLights(s, m);
        return LightingResult(m, color);
    }
}

vec3 lighting(Surface s) {
    LightingResult current = surfaceLighting(s);
    vec3 color = current.color;
    
    const int reflections = NUM_REFLECTIONS;
    float extinction = 1.0;
    
    for (int i = 0; i < reflections; i++) {
        TraceResult rh = traceReflection(s, farPlane, maxSteps);
        
        s = getSurf(rh);
        
        float refAmount = (1.0 - current.mat.roughness);
        extinction *= refAmount;
        
        current = surfaceLighting(s);
        color += extinction * saturate(current.color) * 0.6;
    }
    
    return color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    
    vec2 screen = uv * 2.0 - 1.0;
    screen.x *= iResolution.x / iResolution.y;
    
    float xCam = A(0.0, -0.2, 0.0, 3.0);
    xCam = A(xCam, -0.65, 0.0, 9.0);
    xCam = A(xCam, -0.95, 8.5, 10.0);
    xCam = A(xCam, -1.0, 10.0, 11.0);
    
    float yCam = A(-0.25, -0.08, 0.3, 1.0);
    yCam = A(yCam, -0.3, 0.5, 2.5);
    yCam = A(yCam, -0.08, 0.5, 3.0);
    yCam = A(yCam, -0.06, 4.0, 10.0);
    yCam = A(yCam, 0.15, 10.0, 10.5);
    yCam = A(yCam, -0.25, 10.0, 11.0);
    
    float camDist = A(1.5, 5.5, 0.0, 2.0);
    camDist = A(camDist, 3.5, 0.0, 3.0);
    camDist = A(camDist, 4.0, 3.0, 5.0);
    camDist = A(camDist, 4.5, 4.0, 7.0);
    camDist = A(camDist, 3.5, 7.0, 10.0);
    camDist = A(camDist, 2.0, 9.5, 10.5);
    camDist = A(camDist, 2.5, 10.0, 11.);
    
    Camera cam = createOrbitCamera(
        screen, 
        vec2(xCam, yCam) *  PI, 
        iResolution.xy, 
        60.0 * DEG2RAD, 
        vec3(0, 0.5, 0), 
        0.0, 
        camDist
    );

    vec3 ro = cam.position;
    vec3 rd = cam.direction;
    
    TraceResult tr = trace(ro, rd, farPlane, maxSteps);
    Surface s = getSurf(tr);
    
    vec4 col = vec4(lighting(s), 1.0);
    col = ACESFilm(col);
    col = linearTosRGB(col);
    fragColor = col;
}