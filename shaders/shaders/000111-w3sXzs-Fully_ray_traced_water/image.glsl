// Image (image) — Fully ray traced water by michael0884
// https://www.shadertoy.com/view/w3sXzs

//antialiasing
#define AA 1

#define RADIUS 0.3
#define NORMAL_SMOOTHNESS 0.0
#define FOV 2.5
#define MaxBounces 6
#define IOR 1.25
#define F0 0.005
#define Roughness 0.02

const vec3 absorb = vec3(0.643,0.796,0.996);

vec3 getRay(vec2 angles, vec2 pos)
{
    mat3 camera = getCamera(angles);
    return normalize(transpose(camera)*vec3(FOV*pos.x, 1., FOV*pos.y));
}

float Density(vec3 p)
{
    return trilinear(ch0, p).z;
}

vec3 DensityNormal(vec3 pos)
{
    const float h = 1.0;
    float d211 = Density(pos + vec3(h, 0, 0));
    float d121 = Density(pos + vec3(0, h, 0));
    float d112 = Density(pos + vec3(0, 0, h));
    float d011 = Density(pos + vec3(-h, 0, 0));
    float d101 = Density(pos + vec3(0, -h, 0));
    float d110 = Density(pos + vec3(0, 0, -h));
    return normalize(vec3(d211 - d011, d121 - d101, d112 - d110));
}

vec3 Background(vec3 rd)
{
    vec3 col = texture(iChannel3,  rd.yzx).xyz;
    return 2.0*pow(col, vec3(2.0)) + col*exp(10.0*(length(col) - 1.45));
}


vec4 GetVoxelSamples(vec3 ro, vec3 rd, float mint, float deltat)
{   
    float y0 = Density(ro += rd * mint);
    float y1 = Density(ro += rd * deltat);
    float y2 = Density(ro += rd * deltat);
    float y3 = Density(ro += rd * deltat);
    return vec4(y0, y1, y2, y3) - IsoValue;
}

uvec2 getBlock(vec3 block)
{
    vec2 data = LOAD3D(ch1, block).xy;
    return floatBitsToUint(data);
}

bool getVoxel(vec3 pos, vec3 block, uvec2 blockData)
{
    vec3 blockPos = pos - block;
    uint id = uint((blockPos.x * float(BLOCK_SIZE) + blockPos.y) * float(BLOCK_SIZE) + blockPos.z);
    uint data = bool(id >> 5u) ? blockData.y : blockData.x;
    uint voxelFlag = (data >> (id & 31u)) & 1u;
    return bool(voxelFlag);
}

bool BlockRaycast(inout vec3 ro, vec3 rd, VoxelRayProps props, vec3 block, float tmax, uvec2 surfaceMask)
{
    bool blockEmpty = all(equal(surfaceMask, uvec2(0)));
    if(blockEmpty) return false;
    VoxelRay ray = CreateVoxelRay(ro, props);
    bool hit = false;
    for(int i = 0; i < 12; i++) 
    {
        vec4 next = ComputeNextVoxel(ray);
        bool hasSurface = getVoxel(ray.voxelPos, block, surfaceMask);
        if(hasSurface) { 
            float tdNew = ray.curTraveled;
            vec3 roNew = ro + rd * tdNew;

            //intersect the trilinear surface
            float mint = -5e-5, maxt = next.w - tdNew, deltat = (maxt - mint) / 3.0;
            vec4 ys = GetVoxelSamples(roNew, rd, mint, deltat);
            vec2 result = iIsoSurf4Samples(mint, deltat, ys);

            if (result.y > 0.5) {
                hit = true;
                ro = roNew + rd * result.x;
                break; 
            }
        } 
        StepVoxelRay(ray, next);
        if(ray.curTraveled >= tmax) break;
    }
    return hit;
}

bool GridRaycast(inout vec3 ro, vec3 rd, float maxt)
{
    ro = ro / float(BLOCK_SIZE);
    maxt = maxt / float(BLOCK_SIZE);

    VoxelRayProps props = CreateVoxelRayProps(rd);
    VoxelRay ray = CreateVoxelRay(ro, props);

    bool hit = false;
    
    for(int i = 0; i < 128; i++) 
    {   
        vec4 next = ComputeNextVoxel(ray);
        uvec2 surfaceMask = getBlock(ray.voxelPos);
        vec3 roNew = (ro + rd*ray.curTraveled) * float(BLOCK_SIZE);
        if(BlockRaycast(roNew, rd, ray.props, ray.voxelPos * float(BLOCK_SIZE), (min(next.w, maxt) - ray.curTraveled) * float(BLOCK_SIZE), surfaceMask)) {
            ro = roNew;
            hit = true;
            break;
        }
        StepVoxelRay(ray, next);
        if(ray.curTraveled > maxt) break;
    }
    return hit;
}

bool TraceRay(inout vec3 ro, vec3 rd, inout float traveled)
{
    vec3 ro0 = ro;
    vec2 tdBox = iBox(ro - (size3d-1.0) * 0.5, rd, 0.5*(size3d - 1.0) - 1e-3);
    float td = max(tdBox.x, 0.0);
    ro += td * rd;
    float maxt = tdBox.y - td;
    bool hit = false;
    if(tdBox.y < MAX_DIST) {
        if(GridRaycast(ro, rd, maxt)) {
            hit = true;
            traveled = length(ro - ro0);
        } else {
            traveled = maxt;
        }
    } 

    return hit;
}


bool PathTrace(
    vec3  ro,
    vec3  rd,
    out vec3 firstPos,
    out vec3 lastPos,
    out vec3 lastRd,
    out bool camInside,
    out vec3 incoming,
    out vec3 absorption)
{
    float cameraDensity = Density(ro);
    camInside = (cameraDensity > IsoValue) && InsideSimDomain(ro);
    bool inside   = camInside;
    incoming      = vec3(0.0);
    absorption    = vec3(1.0);
    bool hitAny   = false;
    bool hasHit   = false;
    float totalTraveled = 0.0;
    int bounce = 0; 
    for(;bounce < MaxBounces; ++bounce)
    {
        float td     = 0.0;
        vec3  prevRo = ro;
        hasHit = TraceRay(ro, rd, td);
        if(bounce != 0) totalTraveled += td;

        if(hasHit)
        {
            hitAny = true;
            vec3 normal  = normalize(DensityNormal(ro));
            if(bounce == 0) firstPos = ro;
            normal  = inside ?  normal : -normal;
            float n1 = inside ? 1.0 : IOR;
            float n2 = inside ? IOR : 1.0;
            vec3 refrDir = refract(rd, normal, n2 / n1);
            vec3 reflDir = reflect(rd, normal);

            if(inside)
            {
                vec3 addedAbsorption = exp(- 0.25*(1.0 - absorb) * td);
                absorption *= addedAbsorption;
            }

            if((absorption.x + absorption.y + absorption.z) < 0.01) break;

            float kS = mix(fresnelFull(reflDir, refrDir, normal, n2, n1), 1.0, F0);
            float kD = 1.0 - kS;

            if(kS > 0.95)
            {   // reflection
                ro += 0.01 * normal;
                rd  = reflDir;
                absorption *= kS;
                incoming += Background(refrDir) * absorption * kD;
            }
            else
            {   // refraction
                ro -= 0.01 * normal;
                rd  = refrDir;
                inside = !inside;
                absorption *= kD;

                vec3 lightDir  = light_dir;
                vec3 H         = normalize(lightDir - rd);
                float NdotL    = max(0.0, dot(normal, lightDir));
                float NdotV    = max(0.0, dot(normal, -rd));
                float selfshadow = G_ggx(NdotL, Roughness) * G_ggx(NdotV, Roughness) /
                                   max(4.0 * NdotL * NdotV, 1e-3);
                float specular = selfshadow * NDF_ggx(H, normal, Roughness) * NdotL;
                vec3  lightColor = vec3(1.5);
                incoming += (lightColor * specular + Background(reflDir)) * absorption * kS;
            }
            lastPos = ro;
            lastRd  = rd;
        }
        else
        {
            incoming += Background(rd) * absorption;
            break;
        }
    }
    
    if(bounce == MaxBounces) incoming += Background(rd) * absorption;
    
    return hitAny;
}

vec3 render(vec2 fragCoord)
{
    vec2 uv = (fragCoord - 0.5*R)/max(R.x, R.y);
    vec2 angles = vec2(2.*PI, PI)*(iMouse.xy/iResolution.xy - 0.5);

    if(iMouse.z <= 0.)
    {
        angles = vec2(0.04 + 0.05*iTime, -0.5);
    }
    vec3 rd = getRay(angles, uv);
    vec3 center_rd = getRay(angles, vec2(0.));
 
    float d = sqrt(dot(vec3(size3d), vec3(size3d)))*0.4;
    vec3 ro = vec3(size3d)*vec3(0.5, 0.5, 0.5) - center_rd*d;

    vec3 count = vec3(0.0);
    float td = 0.0;
    vec3 firstPos = vec3(0.0);
    vec3 lastPos = vec3(0.0);
    vec3 lastRd = vec3(0.0);
    bool camInside = false;
    vec3 incoming = vec3(0.0);
    vec3 absorption = vec3(0.0);
    bool hit = PathTrace(ro, rd, firstPos, lastPos, lastRd, camInside, incoming, absorption);
    
    return tanh(1.5*pow(incoming.xyz,vec3(1.0/1.3)));
}

void mainImage( out vec4 col, in vec2 fragCoord )
{    
    InitGrid(iResolution.xy);
    col.xyz = vec3(0.0);
    loop(i, AA) loop(j, AA) {
        col.xyz += render(fragCoord + vec2(i, j) / float(AA));
    }
    col.xyz /= float(AA * AA);
}