// Buffer A (buffer) — PORTRAIT OF TRISTAN by alro
// https://www.shadertoy.com/view/slVBzt

/*
    Albedo (RGB) and detail height map for skin (A)
    Rendered only on start or resolution change.

    &
    
    Track mouse movement and resolution change between frames and set camera position. 
    (Overwrites first couple of pixels)
*/

#define EPS 1e-4

#define SIZE 1024

// Variable iterator initializer to stop loop unrolling
#define ZERO (min(iFrame,0))

// https://www.shadertoy.com/view/4djSRW
vec2 hash(vec2 p){
    p = mod(p, float(SIZE));
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return 2.0 * fract((p3.xx+p3.yz)*p3.zy) - 1.0;
}

// 5th order polynomial interpolation
vec2 fade(vec2 t){
    return (t * t * t) * (t * (t * 6.0 - 15.0) + 10.0);
}

float gradientNoise(vec2 p ){

    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = fade(f);
    return  0.5+0.5*mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                              dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                         mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                              dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float worley(vec2 pos, float numCells){
	vec2 p = pos * numCells;
	float d = 1e10;
	for (int x = -1; x <= 1; x++){
		for (int y = -1; y <= 1; y++){
            vec2 tp = floor(p) + vec2(x, y);
            tp = p - tp - (0.5 + 0.5 * hash(mod(tp, numCells)));
            d = min(d, dot(tp, tp));
        }
    }
	return d;
}

float getGlow(float dist, float radius, float intensity){
    return min(1e2, max(1e-5, pow(radius/max(1e-5, dist), intensity)));
}

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
    points[0] = vec2(-0.0525, -0.22);
    points[1] = vec2(-0.015, -0.195);
    points[2] = vec2(-0.00001, -0.20);
    points[3] = vec2(0.015, -0.195);
    points[4] = vec2(0.07, -0.23);
    points[5] = vec2(0.07, -0.23);
    
    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
    float dist = 1e10;
    for(int i = ZERO; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }
    return dist;
}

float getEyeLine(vec2 pos){

    float dist = 1e10;
    const int N = 6;
    vec2 points[N];
    pos.y -= 0.2055;
    pos.x = abs(pos.x);
    pos.x -= 0.015;
    points[0] = vec2(0.02, -0.22);
    points[1] = vec2(0.03, -0.2);
    points[2] = vec2(0.045, -0.195);
    points[3] = vec2(0.06, -0.2);
    points[4] = vec2(0.07, -0.22);
    points[5] = vec2(0.07, -0.22);
    
    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
    for(int i = ZERO; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }
    
    pos.y += 0.028;
    pos.y += 0.0055;
    pos.x -= 0.002;
    
    points[0] = vec2(0.02, -0.195);
    points[1] = vec2(0.03, -0.2);
    points[2] = vec2(0.045, -0.21);
    points[3] = vec2(0.06, -0.2);
    points[4] = vec2(0.07, -0.19);
    points[5] = vec2(0.07, -0.19);
    
    c = (points[0] + points[1]) / 2.0;
    c_prev;
    for(int i = ZERO; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }

    return dist;
}

float getEyeLashes(vec2 pos){

    float dist = 1e10;
    const int N = 6;
    vec2 points[N];
    pos.y -= 0.2055;
    pos.x = abs(pos.x);
    pos.x -= 0.015;
    points[0] = vec2(0.02, -0.22);
    points[1] = vec2(0.03, -0.2);
    points[2] = vec2(0.045, -0.198);
    points[3] = vec2(0.06, -0.205);
    points[4] = vec2(0.07, -0.22);
    points[5] = vec2(0.07, -0.22);
    
    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
    for(int i = ZERO; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }
    
    pos.y += 0.028;
    pos.y += 0.0055;
    pos.x -= 0.002;
    
    points[0] = vec2(0.02, -0.195);
    points[1] = vec2(0.03, -0.205);
    points[2] = vec2(0.045, -0.205);
    points[3] = vec2(0.06, -0.2);
    points[4] = vec2(0.07, -0.18);
    points[5] = vec2(0.07, -0.18);
    
    c = (points[0] + points[1]) / 2.0;
    c_prev;
    for(int i = ZERO; i < N-2; i++){
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        dist = min(dist, sdBezier(pos, c_prev, points[i], c));
    }

    return dist;
}

float fbm(vec2 p){
    float weight = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float res = 0.0;
    for(int i = ZERO; i < 3; i++){
        res += amplitude * gradientNoise(frequency * p);
        weight += amplitude;
        amplitude *= 0.9;
        frequency *= 2.0;
    }
    
    return res / weight;
}

vec4 getSkin(vec2 fragCoord){
    bool resolutionChanged = texelFetch(iChannel0, ivec2(0.5, 2.5), 0).r > 0.0;
    
    if(iFrame == 0 || resolutionChanged){
    
        vec2 uv = fragCoord/iResolution.xy;
        vec2 p = uv;
        uv.x *= iResolution.x/iResolution.y;

        vec3 skinCol = 0.7*vec3(0.945, 0.44, 0.3);

        float noise0 = gradientNoise(128.0*uv);
        float noise1 = gradientNoise(64.0*(uv+0.5));
        float noise2 = gradientNoise(200.0*uv);

        skinCol = mix(vec3(1,0.9,0.9)*skinCol, skinCol, noise0);
        skinCol = mix(vec3(0.9,0.85,1)*skinCol, skinCol, saturate(0.4+noise1));

        vec3 lipCol = mix(skinCol, 0.35*vec3(1.0, 0.1, 0.2), 0.4);
        vec3 vessels = vec3(1, 0.02, 0.15);
        vec3 darkCol = mix(skinCol, 0.5*vessels, 0.25*noise2);
        darkCol = mix(darkCol, 0.3*vessels, 0.225);

        vec3 col = skinCol;

        float lip = 1e10;

        vec2 q = p;
        q -= 0.5;
        q.x = abs(q.x);
        q.y += 0.191;
        q = rotate(q, PI * 0.66);
        lip = min(lip, sdUnevenCapsule(q, 0.015, 0.0045, 0.04));

        q = p;
        q -= 0.5;
        q.x = abs(q.x);
        q.y += 0.208;
        q = rotate(q, PI * 0.53);
        lip = min(lip, sdUnevenCapsule(q, 0.013, 0.005, 0.03));

        q = p;
        q -= 0.5;
        q.y += 0.16;
        q = rotate(q, PI * 0.55);
        lip = opSmoothSub(sdCircle(q, 0.02), lip, 0.01);

        col = mix(col, lipCol, smoothstep(0.01, -0.001, lip));
        
        float eyes = 1e10;
        q = p;
        q -= 0.5;
        q.x = abs(q.x);
        q.x -= 0.03;
        q.y += 0.015;
        q = rotate(q, PI * 0.775);
        eyes = min(eyes, sdUnevenCapsule(q, 0.05, 0.03, 0.05));

        q = p;
        q -= 0.5;
        q.x = abs(q.x);
        q.x -= 0.05;
        q.y += 0.015;
        q = rotate(q, PI * 0.5);
        eyes = min(eyes, sdUnevenCapsule(q, 0.03, 0.03, 0.025));

        q = p;
        q -= 0.5;
        q.y += 0.08;
        eyes = opSmoothSub(sdUnevenCapsule(q, 0.005, 0.01, 0.095), eyes, 0.035);

        col = mix(col, 0.9*darkCol, smoothstep(0.015, -0.025, eyes));

        float nose = 1e10;
        q = p;
        q -= 0.5;
        q.y += 0.125;
        nose = sdCircle(q, 0.03);

        q = p;
        q -= 0.5;
        q.y += 0.125;
        nose = min(nose , sdUnevenCapsule(q, 0.015, 0.001, 0.075));

        col = mix(col, mix(skinCol, darkCol, 0.75), smoothstep(0.02, -0.01, nose));

        float cheeks = 1e10;
        q = p;
        q -= 0.5;
        q.x = abs(q.x);
        q.x -= 0.075;
        q.y += 0.11;
        q = rotate(q, PI * 0.9);
        cheeks = sdUnevenCapsule(q, 0.035, 0.02, 0.09);

        col = mix(col, mix(skinCol, darkCol, 0.5), smoothstep(0.03, -0.02, cheeks));

        float ears = 1e10;
        q = p;
        q -= 0.5;
        q.x = abs(q.x);
        q.x -= 0.265;
        q.y -= 0.02;
        q = rotate(q, PI);
        ears = sdUnevenCapsule(q, 0.02, 0.03, 0.2);

        col = mix(col, mix(skinCol, darkCol, 0.75), smoothstep(0.025, -0.02, ears));

        float brow = 1e10;
        q = p;
        q -= 0.5;
        q.x = abs(q.x);
        float noise = fbm(rotate(q, 0.05*PI) * vec2(256.0, 32.0));
        q.y += mix(0.0, -0.0075, smoothstep(0.0, 0.1, q.x));
        q.y += mix(0.0, -0.0025, smoothstep(0.0, 0.05, q.x));
        q.x -= 0.0325;
        q.y -= 0.042;
        q = rotate(q, 0.5*PI);
        brow = sdUnevenCapsule(q, 0.0175, 0.0075, 0.0575);

        q = p;
        q -= 0.5;
        float mouthLine = mouthLine(q);
        
        float lipNoise = fbm(q * vec2(64.0, 10.0));
        col = mix(col, mix(lipCol, mix(lipCol, lipCol*vec3(0.6,0.5,0.5), 0.5), lipNoise), smoothstep(0.03, -0.01, mouthLine) * smoothstep(0.01, -0.005, lip));       
        col = mix(col, mix(lipCol, mix(lipCol, 0.75*lipCol*vec3(0.4,0.15,0.15), 0.5), smoothstep(0.05, 0.01, abs(q.x))), smoothstep(0.0075, -0.005, mouthLine));
        col = mix(col, mix(lipCol, mix(lipCol, 0.75*lipCol*vec3(0.4,0.15,0.15), 0.5), smoothstep(0.05, 0.01, abs(q.x))), smoothstep(0.015, -0.03, mouthLine));

        q = p;
        q -= 0.5;
        float eyeLine = getEyeLine(q);
        col = mix(col, mix(skinCol, skinCol*vec3(0.4,0.15,0.2), 0.6), smoothstep(0.015, -0.0, eyeLine));
        
        q = p;
        q -= 0.5;
        q.y += 0.001;
        float eyeLashes = getEyeLashes(q);
        col = mix(col, mix(col, 0.125*vec3(0.4, 0.2, 0.1), 0.45), smoothstep(0.005, -0.0, eyeLashes));
        
        uv = fragCoord/iResolution.xy;
        float skinHeight = smoothstep(2.0, 0.0, worley(uv, 32.0));
        float pores = 1.0-saturate(getGlow(worley(uv, 32.0), 0.001, 0.2));

        return vec4(col, skinHeight * pores);
    }else{
        return texelFetch(iChannel0, ivec2(fragCoord), 0);
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    fragColor = getSkin(fragCoord);
    
    // Store camera and resolution data in the first four pixels.
    if((fragCoord.x == 0.5) && (fragCoord.y < 5.0)){
        
        vec4 oldData = texelFetch(iChannel0, ivec2(0.5), 0).xyzw;

        vec2 oldPolarAngles = oldData.xy;
        vec2 oldMouse = oldData.zw;

        vec2 polarAngles = vec2(0);
        vec2 mouse = iMouse.xy / iResolution.xy; 
        
        // Stop camera going directly above and below
        float angleEps = 0.01;

        float mouseDownLastFrame = texelFetch(iChannel0, ivec2(0.5, 3.5), 0).x;
        
        // If mouse button is down and was down last frame.
        if(iMouse.z > 0.0 && mouseDownLastFrame > 0.0){
            
            // Difference between mouse position last frame and now.
            vec2 mouseMove = mouse - oldMouse;
            polarAngles = oldPolarAngles + vec2(5.0, 3.0) * mouseMove;
            
        }else{
            polarAngles = oldPolarAngles;
        }
        
        polarAngles.x = mod(polarAngles.x, 2.0 * PI - angleEps);
        polarAngles.y = min(PI - angleEps, max(angleEps, polarAngles.y));

        // Store mouse data in the first pixel of Buffer A.
        if(fragCoord == vec2(0.5, 0.5)){
            // Set value at first frames.
            if(iFrame == 0){
                polarAngles = vec2(0.2, 1.71);
                mouse = vec2(0);
            }
            fragColor = vec4(polarAngles, mouse);
        }

        // Store camera position in the second pixel of Buffer A.
        if(fragCoord == vec2(0.5, 1.5)){
            // Cartesian direction from polar coordinates.
            vec3 cameraPos = normalize(vec3(-cos(polarAngles.x) * sin(polarAngles.y), 
                                             cos(polarAngles.y), 
                                            -sin(polarAngles.x) * sin(polarAngles.y)));

            fragColor = vec4(CAMERA_DIST * cameraPos, 1.0);
        }
        
        // Store resolution change data in the third pixel of Buffer B.
        if(fragCoord == vec2(0.5, 2.5)){
            float resolutionChangeFlag = 0.0;
            // The resolution last frame.
            vec2 oldResolution = texelFetch(iChannel0, ivec2(0.5, 2.5), 0).yz;
            
            if(iResolution.xy != oldResolution){
            	resolutionChangeFlag = 1.0;
            }
            
        	fragColor = vec4(resolutionChangeFlag, iResolution.xy, 1.0);
        }
           
        // Store whether the mouse button is down in the fourth pixel of Buffer A
        if(fragCoord == vec2(0.5, 3.5)){
            if(iMouse.z > 0.0){
            	fragColor = vec4(vec3(1.0), 1.0);
            }else{
            	fragColor = vec4(vec3(0.0), 1.0);
            }
        }

        // Store FOV in the fifth pixel of Buffer A
        if(fragCoord == vec2(0.5, 4.5)){
            float fovChangeFlag = 0.0;
            // The FOV last frame.
            float oldFOV = texelFetch(iChannel0, ivec2(0.5, 4.5), 0).y;
            
            if(FOV != oldFOV){
            	fovChangeFlag = 1.0;
            }
            
        	fragColor = vec4(fovChangeFlag, FOV, 0.0, 1.0);
        }
    }
}