// Image (image) — Analytic Direct Lighting by fad
// https://www.shadertoy.com/view/dlcXR4

// Analytic direct lighting in 2D. Sky integral taken from
// https://www.shadertoy.com/view/NttSW7 but otherwise made from
// scratch. It's interactive! Try dragging around the end points of the
// line segments. It doesn't handle intersecting lines properly.

struct LineSegment {
    vec2 p0;
    vec2 p1;
    vec3 emissiveColor;
};

LineSegment[N] segments;
float angles[2 * N];

void sortAngles() {
    for (int i = 0; i < N; ++i) {
        for (int j = 0; j < 2; ++j) {
            int k = 2 * i + j;
            vec2 p = j == 0 ? segments[i].p0 : segments[i].p1;
            float angle = mod(atan(p.y, p.x), 2.0 * PI);
            int l = k - 1;
            
            while (l >= 0 && angle < angles[l]) {
                angles[l + 1] = angles[l];
                l -= 1;
            }
            
            angles[l + 1] = angle;
        }
    }
}

vec3 integrateRadiance(LineSegment a, vec2 angle) {
    return (angle[1] - angle[0]) * a.emissiveColor;
}

vec3 integrateSkyRadiance_(vec2 angle) {
    float a1 = angle[1];
    float a0 = angle[0];
    
    // https://www.shadertoy.com/view/NttSW7
    const vec3 SkyColor = vec3(0.2,0.5,1.);
    const vec3 SunColor = vec3(1.,0.7,0.1)*10.;
    const float SunA = 2.0;
    const float SunS = 64.0;
    const float SSunS = sqrt(SunS);
    const float ISSunS = 1./SSunS;
    vec3 SI = SkyColor*(a1-a0-0.5*(cos(a1)-cos(a0)));
    SI += SunColor*(atan(SSunS*(SunA-a0))-atan(SSunS*(SunA-a1)))*ISSunS;
    return SI / 6.0;
}

vec3 integrateSkyRadiance(vec2 angle) {
    if (angle[1] < 2.0 * PI) {
        return integrateSkyRadiance_(angle);
    }
    
    return integrateSkyRadiance_(vec2(angle[0], 2.0 * PI)) + integrateSkyRadiance_(vec2(0.0, angle[1] - 2.0 * PI));
}

int findIndex(float angle) {
    mat2 m;
    m[1] = vec2(cos(angle), sin(angle));
    int bestIndex = -1;
    float bestU = 1e10;
    
    for (int i = 0; i < N; ++i) {
        m[0] = segments[i].p0 - segments[i].p1;
        vec2 tu = inverse(m) * segments[i].p0;
        if (tu == clamp(tu, vec2(0.0), vec2(1.0, bestU))) {
            bestU = tu.y;
            bestIndex = i;
        }
    }
    
    return bestIndex;
}

vec3 calculateFluence() {
    vec3 fluence = vec3(0.0);
    
    for (int i = 0; i < 2 * N; ++i) {
        vec2 a;
        a[0] = angles[i];
        
        if (i + 1 < 2 * N) {
            a[1] = angles[i + 1];
        } else {
            a[1] = angles[0] + 2.0 * PI;
        }
        
        if (a[0] == a[1]) {
            continue;
        }
        
        int j = findIndex((a[0] + a[1]) / 2.0);
        
        if (j == -1) {
            fluence += integrateSkyRadiance(a);
        } else {
            fluence += integrateRadiance(segments[j], a);
        }
    }
    
    return fluence;
}

float sdf(LineSegment l, vec2 p) {
    vec2 pa = p-l.p0, ba = l.p1-l.p0;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

vec4 blendOver(vec4 top, vec4 bottom) {
    float a = top.a + bottom.a * (1.0 - top.a);
    return vec4((top.rgb * top.a + bottom.rgb * bottom.a * (1.0 - top.a)) / a , a);
}

void drawSDF(inout vec4 dst, vec4 src, float sdf) {
    dst = blendOver(vec4(src.rgb, src.a * clamp(1.5 - abs(sdf), 0.0, 1.0)), dst);
}

void mainImage(out vec4 fragColor, vec2 fragCoord) {
    for (int i = 0; i < N; ++i) {
        segments[i].p0 = getPoint(2 * i + 0) - fragCoord;
        segments[i].p1 = getPoint(2 * i + 1) - fragCoord;
        segments[i].emissiveColor = vec3(0.0);
    }
    
    segments[10].emissiveColor = vec3(1.0, 0.1, 0.3);
    segments[11].emissiveColor = vec3(0.1, 0.6, 0.9);
    
    sortAngles();
    vec3 fluence = calculateFluence();
    fragColor = vec4(1.0 - 1.0 / pow(1.0 + fluence, vec3(3.0)), 1.0);
    fragColor.a = 1.0;
    
    for (int i = 0; i < N; ++i) {
        drawSDF(
            fragColor, 
            vec4(3.0 * pow(segments[i].emissiveColor, vec3(1.0 / 2.2)), 1.0),
            sdf(segments[i], vec2(0.0))
        );
    }
}