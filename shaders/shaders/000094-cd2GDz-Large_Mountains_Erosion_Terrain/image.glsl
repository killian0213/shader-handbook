// Image (image) — Large Mountains Erosion Terrain by Hatchling
// https://www.shadertoy.com/view/cd2GDz

float maxHeight()
{
    return 500.0 / iChannelResolution[0].x;        
}

float precis()
{
    return 1.5 / iChannelResolution[0].x;        
}//


vec3 worldToTerrain(vec3 p)
{
    p.x /= iChannelResolution[0].x / iChannelResolution[0].y;
    p.xz += 0.5;
    p.y /= maxHeight();
    return p;
}

vec3 terrainToWorld(vec3 p)
{
    p.y *= maxHeight();   
    p.xz -= 0.5;
    p.x *= iChannelResolution[0].x / iChannelResolution[0].y;
    return p;
}

float terrain(vec2 p){

    p.x /= iChannelResolution[0].x / iChannelResolution[0].y;
    
    p += 0.5;
    

    
    if(clamp(p,0.0,1.0) != p) return 0.;
    
    vec4 t = texture(iChannel0, p);
    return t.r / t.a * maxHeight();
}

vec2 calculate_curvature(vec3 p)
{    
    float height_mod = 1.;
    float prec = precis();
    float heightC = terrain(p.xz)*height_mod;
    
    vec3 posC = vec3(p.x, heightC, p.z);
    vec3 posR = p + vec3(prec, 0.0,  0.0);
    vec3 posL = p - vec3(prec, 0.0,  0.0);
    vec3 posT = p + vec3( 0.0, 0.0, prec);
    vec3 posB = p - vec3( 0.0, 0.0, prec);
    
    posR.y = terrain(posR.xz)*height_mod;
    posL.y = terrain(posL.xz)*height_mod;
    posT.y = terrain(posT.xz)*height_mod;
    posB.y = terrain(posB.xz)*height_mod;
    
    vec3 dx = posR - posL;
    vec3 dy = posT - posB;
    
    vec3 normal = normalize(cross(dx, dy));
    
    float curveX = -dot(posC + posC - posR - posL, normal);
    float curveY = -dot(posC + posC - posT - posB, normal);
    
    return vec2(curveX, curveY) / prec;
}

vec3 calculate_normal(vec3 p)
{    
    float height_mod = 1.;
    float prec = precis();
    float heightC = terrain(p.xz)*height_mod;
    
    vec3 posC = vec3(p.x, heightC, p.z);
    vec3 posR = p + vec3(prec, 0.0,  0.0);
    vec3 posL = p - vec3(prec, 0.0,  0.0);
    vec3 posT = p + vec3( 0.0, 0.0, prec);
    vec3 posB = p - vec3( 0.0, 0.0, prec);
    
    posR.y = terrain(posR.xz)*height_mod;
    posL.y = terrain(posL.xz)*height_mod;
    posT.y = terrain(posT.xz)*height_mod;
    posB.y = terrain(posB.xz)*height_mod;
    
    vec3 dx = posR - posL;
    vec3 dy = posT - posB;
    
    return -normalize(cross(dx, dy));
}

bool pointTerrain(vec3 p){
    return terrain(p.xz) >= p.y;
}

vec3 skybox(vec3 dir)
{
    float gradient = dir.y * 0.5 + 0.5;
    
    gradient *= gradient;
    gradient *= gradient;
   
    gradient = 1.-gradient;
    gradient *= gradient;
    gradient *= gradient;
    gradient *= gradient;
    gradient *= gradient;
    gradient = 1.-gradient;
    
    gradient = smoothstep(0., 1., gradient);
    gradient = smoothstep(0., 1., gradient);
    gradient = smoothstep(0., 1., gradient);
    gradient = smoothstep(0., 1., gradient);
    
    vec3 gradient3 = pow(vec3(gradient), vec3(8.0, 1.0, 1.0));
    gradient3 = vec3(1.)-gradient3;
    gradient3 = pow(gradient3, vec3(0.4, 0.5, 4.0));
    gradient3 = vec3(1.)-gradient3;
    
    vec3 color = mix(vec3(0.99,0.99,0.99), vec3(0.01,0.02,0.2), gradient3) * 2.0;
    
    
    return color;
}

vec3 skyboxBlurry(vec3 dir)
{
    float gradient = dir.y * 0.5 + 0.5;
    
    
    
   
    //gradient *= gradient;
   ;
    gradient = 1.-gradient;
    gradient *= gradient * gradient;
    gradient = 1.-gradient;
    
    
    vec3 gradient3 = pow(vec3(gradient), vec3(8.0, 1.0, 1.0));
    gradient3 = vec3(1.)-gradient3;
    gradient3 = pow(gradient3, vec3(0.4, 0.5, 4.0));
    gradient3 = vec3(1.)-gradient3;
    
    vec3 color = mix(vec3(0.99,0.99,0.99), vec3(0.01,0.02,0.2), gradient3) * 2.0;
    
    
    return color;
}

vec3 castRayTerrain2(vec3 camPos, vec3 camDir){
    bounds b;
    b.mini = terrainToWorld(vec3(0));
    b.maxi = terrainToWorld(vec3(1));
    
    vec3 near, far;
    if(!rayIntersectBounds(b, camPos, camDir, near, far))
    {
        return skybox(camDir);
    }
    
    vec3 p = near;
    float minD = 0.0, maxD = 1.0;
    bool hit = false;
    for(float i=0.; i<=1.; i+=.005)
    {
        float j = i*i;
    	p = mix(near, far, j);
        
        maxD = j;
        
        
        if(pointTerrain(p))
        {
            hit = true;
            break;
        }
        
        minD = j;
    }
    
    if(!hit) return skybox(camDir);

    maxD = (minD + maxD) * 0.5;
    float stepSize = (maxD - minD) * 0.5;

    for(int i = 0; i < 5; i++, stepSize *= 0.5)
    {
    	p = mix(near, far, maxD);
        if(!pointTerrain(p))
        {
            minD = maxD;
            maxD += stepSize;
        }
        else
        {
            maxD -= stepSize;
        }
    }
    
    
    vec3 normal = calculate_normal(p);
    vec2 curve2 = calculate_curvature(p);
    
    vec2 posCurve2 = max(vec2(0), curve2);
    vec2 negCurve2 = -min(vec2(0), curve2);
    
    float posCurve = posCurve2.x + posCurve2.y;
    posCurve = posCurve / (0.2 + posCurve);
    float negCurve = negCurve2.x + negCurve2.y;
    negCurve = negCurve / (0.2 + negCurve);
    float curve = (curve2.x + curve2.y);
    curve = curve / (0.2 + abs(curve));
    
    p = vec3(p.x, terrain(p.xz), p.z);

    vec3 lightDir = normalize(vec3(0, 3, 5));
    vec3 lightColor = max(0.0,dot(normal, lightDir)) * vec3(1.0, 0.75, 0.5) * 2.0;
    
    vec3 ambientDir = vec3(0, 1, 0);
    float ambient = dot(normal, ambientDir) * 0.5 + 0.5;
    ambient *= ambient;
    //ambient *= ambient;
    //ambient *= ambient;
    ambient *= curve * 0.5 + 0.5;
    vec3 ambientColor = ambient * skyboxBlurry(normal);
    
    vec3 totalDiffuse = ambientColor + lightColor;

    vec3 eyeDir = normalize(camPos-p);
    vec3 reflec = reflect(-lightDir, normal);
    float spec = max(0.0,dot(eyeDir, reflec));
    spec = pow(spec*1.01, 100.);// * 10.;

    vec3 albedo  = vec3(1.);
    
    float slopeFactor;
    float heightFactor;
    {
        heightFactor = p.y / maxHeight();
        
        heightFactor = smoothstep(0., 1., heightFactor);        
        heightFactor = smoothstep(0., 1., heightFactor);
        
        slopeFactor = abs(normal.y);
        slopeFactor *= slopeFactor;
        slopeFactor *= slopeFactor;
        slopeFactor *= slopeFactor;
        //slopeFactor *= slopeFactor;
        slopeFactor = 1.-slopeFactor;
        slopeFactor *= slopeFactor;
        slopeFactor *= slopeFactor;
        //slopeFactor *= slopeFactor;
        slopeFactor = 1.-slopeFactor;
        //slopeFactor = smoothstep(0., 1., slopeFactor);
        //slopeFactor = smoothstep(0., 1., slopeFactor);
        //slopeFactor = smoothstep(0., 1., slopeFactor);
        
        vec3 flatLow = vec3(0.1, 0.4, 0.05);
        vec3 flatHigh = vec3(0.7, 0.7, 0.5);
        
        vec3 slopeLow = vec3(0.4, 0.7, 0.2);
        vec3 slopeHigh = vec3(0.3, 0.2, 0.05);
        
        vec3 flatColor = mix(flatLow, flatHigh, heightFactor);
        vec3 slopeColor = mix(slopeLow, slopeHigh, heightFactor);
        
        albedo = mix(slopeColor, flatColor, slopeFactor);
    }
    
    albedo = mix(albedo, (albedo*1.0+vec3(0.75))*vec3(0.7,0.65,0.3), posCurve); 
    
    // Add rivers.
    float rivers;
    {
        rivers = max(0.,negCurve - posCurve);
        
        rivers = pow(rivers, pow(2., mix(0.5, -0.7, slopeFactor) + mix(-0.7, 0.7, heightFactor)));   

        //rivers = pow(rivers, heightFactor + 1.0);   
        //rivers = pow(rivers, heightFactor*3.+0.5);         
        
        rivers = smoothstep(0., 1., rivers);
        rivers = smoothstep(0., 1., rivers);
        
        //rivers = 1.-rivers;
        //rivers *= rivers;
        //rivers = 1.-rivers;
        
        albedo = mix(albedo, vec3(0.1,0.2,0.5), rivers); 
    }

    albedo *= albedo;

    //albedo = mix(albedo, curve > 0.0 ? vec3(1,0.7,0.3) : vec3(0.3,0.7,1), vec3(abs(curve))); 

    float specMult = 0.0;
    specMult = mix(specMult, 0.5, posCurve);//length(color)*length(color)*0.2;
    specMult = mix(specMult, 1.5, rivers);//length(color)*length(color)*0.2;

    vec3 color = albedo*totalDiffuse + lightColor*spec*specMult;
    
    float fogDist = dot(p - camPos, p - camPos);
    
    color = mix(skybox(camDir), color, pow(vec3(0.98), fogDist * vec3(0.1,0.4,2.))); 
    
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 camRay = normalize(vec3((fragCoord - iResolution.xy * 0.5) / iResolution.yy, 1));
    vec3 camPos = vec3(0.0, maxHeight() * 1.0, -1.0);
    
    vec3 lookDir = vec3(0, maxHeight() * 0.0, 0) - camPos;
    
    quaternion pan = FromAngleAxis(vec3(0, iTime * 0.125, 0));
    quaternion tilt = FromToRotation(vec3(0,0,1), lookDir);
    
    camPos = mul(pan, camPos);
    //camRay = mul(, camRay);
    camRay = mul(mul(pan, tilt), camRay);
    
    vec3 col = castRayTerrain2(camPos, camRay);
    
    col = pow(col, vec3(1./2.2));
    
    col = col / sqrt(0.5+col*col);

    fragColor = vec4(col,1.0);
}