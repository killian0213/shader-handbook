// Buffer A (buffer) — pixel outlines by UltimateBurrito
// https://www.shadertoy.com/view/csKyRm

vec2 pixelateCoord(vec2 coord)
{
    vec2 c = floor(coord / float(pixelSize)) * float(pixelSize) / iResolution.xy;
    c.y = 1.0 - c.y;
    return c;
}

float SDFBox(vec3 p, Box b)
{
    mat3 basis = b.basis;
    if(basis == customSpinRotation)
    {
        basis = yRotation(iTime*90.0) * xRotation(iTime*90.0);
    }
    vec3 d = abs((b.pos - p)*basis) - b.size*0.5;
    return min(max(d.x, max(d.y,d.z)), 0.0) + length(max(d, 0.0));
}
float SDFScene(vec3 p)
{
    float dist = farPlane;
    for(int i = 0; i<boxCount; i++)
    {
        dist = min(SDFBox(p,boxes[i]),dist);
    }
    return dist;
}
Material SceneMaterial(vec3 p)
{
    float nearestDist = farPlane;
    Material m;
    for(int i = 0; i<boxCount; i++)
    {
        float dist = SDFBox(p,boxes[i]);
        if(dist < nearestDist){
            nearestDist = dist;
            m = materials[boxes[i].materialIndex];
        }
    }
    return m;
}
Box SceneBox(vec3 p)
{
    float nearestDist = farPlane;
    Box b;
    for(int i = 0; i<boxCount; i++)
    {
        float dist = SDFBox(p,boxes[i]);
        if(dist < nearestDist){
            nearestDist = dist;
            b = boxes[i];
        }
    }
    return b;
}
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}
float rayMarch(vec3 origin, vec3 direction, float start, float end) {
    float depth = start;
    for (int i = 0; i < maxIterations; i++) {
        float dist = SDFScene(origin + depth * direction);
        if (dist < epsilon) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

vec3 estimateNormal(vec3 p)
{
    return normalize(vec3(
        SDFScene(vec3(p.x + epsilon, p.y, p.z)) - SDFScene(vec3(p.x - epsilon, p.y, p.z)),
        SDFScene(vec3(p.x, p.y + epsilon, p.z)) - SDFScene(vec3(p.x, p.y - epsilon, p.z)),
        SDFScene(vec3(p.x, p.y, p.z  + epsilon)) - SDFScene(vec3(p.x, p.y, p.z - epsilon))
    ));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 posMod = vec3((iMouse.x/ iResolution.x)*40.0-20.0,0.0,(iMouse.y/ iResolution.y)*40.0-20.0);
    vec3 cameraPos = vec3(0.0,-12.0,0.0) + posMod;
    vec3 cameraLook = vec3(0,-2,0);
    
    vec2 screenPos = pixelateCoord(fragCoord);

    mat4 cameraMatrix = viewMatrix(cameraPos,cameraLook,vec3(0,1,0));
    vec3 rayOrigin = (cameraMatrix * vec4((screenPos - 0.5) * vec2(1,iResolution.y/iResolution.x) * orthographicSize*2.0,0,1)).xyz + cameraPos;
    vec3 rayDirection = (cameraMatrix * vec4(0,0,-1,1)).xyz;
    float depth = rayMarch(rayOrigin, rayDirection, nearPlane, farPlane);
    vec3 position = rayOrigin + depth * rayDirection;
    vec3 normal = estimateNormal(position);
    if(depth < farPlane)
    {
        Material mat = SceneMaterial(position);
        Box box = SceneBox(position);
        vec3 albedo = mat.albedo;
        float lambert = (dot(normal,lightDir) + 1.0)*0.5;
        if(dot(normal,lightDir) > 0.0)
        {
            float shadowDepth = rayMarch(position, lightDir, nearPlane, farPlane);
            if(shadowDepth < farPlane) lambert *= 0.5;
        }
        
        vec3 color = albedo * (lambert * sunColor);
        for(int i = 0; i < lightCount; i++) // iterate lights
        {
            float dist;
            vec3 pos;
            if(lights[i].linkedBoxIndex == -1)
            {
                dist = distance(position,lights[i].pos);
                pos = lights[i].pos;
            }
            else
            {
                dist = SDFBox(position,boxes[lights[i].linkedBoxIndex]);
                pos = normalize(boxes[lights[i].linkedBoxIndex].pos-position)*dist; //boxes[lights[i].linkedBoxIndex].pos;
            }
            float facing = (dot(normal,normalize(pos-position)) + 1.0)*0.5;
            if(box == boxes[lights[i].linkedBoxIndex]) facing = 1.0;
            color += clamp(1.0 - (dist / lights[i].dist),0.0,1.0) * lights[i].color * facing;
        }
        fragColor = vec4(color,depth);
    }
    else
    {
        vec3 color = vec3(0.5,0.5,0.5);
        fragColor = vec4(color,depth);
    }
    
}