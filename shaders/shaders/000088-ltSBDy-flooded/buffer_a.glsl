// Buffer A (buffer) — flooded by zguerrero
// https://www.shadertoy.com/view/ltSBDy

const float epsilon = 0.05;
const int maxItter = 128;
const int underWaterMaxItter = 16;
const float maxDistance = 80.0;
const float waterMaxDepth = 7.0;
const float pi = 3.14159265359;

const vec3 color1 = vec3(0.2, 0.35, 0.45);
const vec3 color2 = vec3(0.3, 0.5, 0.55);
const vec3 color3 = vec3(0.1, 0.2, 0.3);
const vec3 groundColor = vec3(1.0, 0.9, 0.7);

const float wavesSize = 0.2;
const float wavesHeight = 1.6;
const float wavesSpeed = 2.0;
const float turbSpeed = 0.15;

const mat2 rot1 = mat2(0.99500416527,0.0998334166,-0.0998334166,0.99500416527);
const mat2 rot2 = mat2(0.98006657784,0.19866933079,-0.19866933079,0.98006657784);
const mat2 rot3 = mat2(0.95533648912,0.29552020666,-0.29552020666,0.95533648912);
const mat2 rot4 = mat2(0.921060994,0.3894183423,-0.3894183423,0.921060994);
const mat2 rot5 = mat2(0.87758256189,0.4794255386,-0.4794255386,0.87758256189);
const mat2 rot6 = mat2(0.82533561491,0.56464247339,-0.56464247339,0.82533561491);
const mat2 rot7 = mat2(0.76484218728,0.64421768723,-0.64421768723,0.76484218728);
const mat2 rot8 = mat2(0.69670670934,0.7173560909,-0.7173560909,0.69670670934);
const mat2 rot9 = mat2(0.62160996827,0.78332690962,-0.78332690962,0.62160996827);
const mat2 rot10 = mat2(0.54030230586,0.8414709848,-0.8414709848,0.54030230586);

#define LIGHT normalize(vec3(0.0, 0.15, 1.0))
#define LIGHTCOLOR vec3(1.0, 0.85, 0.5)*0.5

vec2 sinNoise(vec2 p, vec4 s)
{
    vec4 ps = p.xyxy + s * iTime;
    vec2 p1 = ps.xy;
    vec2 p2 = ps.xy * rot2 * 0.4;
    vec2 p3 = ps.zw * rot6 * 0.7;
    vec2 p4 = ps.zw * rot10 * 1.5;
	vec4 s1 = sin(vec4(p1.x, p1.y, p2.x, p2.y));
    vec4 s2 = sin(vec4(p3.x, p3.y, p4.x, p4.y));
    
    return ((s1.xy + s1.zw + s2.xy + s2.zw)*0.25);
}

vec4 waves(vec3 pos, float speed)
{
    pos *= wavesSize;
    vec4 s;
    s.xy = sinNoise(pos.xz*vec2(0.5, 1.0), vec4(0.2, 0.4, -0.1, 0.1)*speed);
    s.zw = sinNoise(pos.xz*vec2(0.3, 0.6) + s.yx*5.0, vec4(-0.2, 0.6, 0.1, 0.3)*speed);
    return abs(s);
}

float Sea(vec3 pos)
{   
	vec4 s = waves(pos, wavesSpeed) + waves(pos * 1.5, wavesSpeed * 1.3) * 0.3;
	return pos.y + (s.z + s.w)*wavesHeight;
}

float Ground(vec3 pos)
{
    vec2 s = sinNoise(pos.xz*vec2(0.2), vec4(0.0))*4.0;
    float g = pos.y + 4.0;
    
    return g + s.x + s.y + textureLod(iChannel2, pos.xz*vec2(0.02, 0.07), 0.0).x;
}

//Bump method Taken from this shader by Shane : from https://www.shadertoy.com/view/XlXXWj
float SeaBump(vec2 p)
{
    float n0 = 1.0 - textureLod(iChannel2, p*0.08 + iTime * vec2(1.0, 0.7)*turbSpeed, 0.0).x;
    float n1 = 1.0 - textureLod(iChannel2, p*0.06 - iTime * vec2(0.8, 0.5)*turbSpeed + (n0 - 0.5)*0.08, 0.0).x;
    float n2 = 1.0 - textureLod(iChannel2, p*0.1 + iTime * vec2(0.6, -0.9)*turbSpeed + (n0 - 0.5)*0.1, 0.0).x;
    
    return n1 + n2;
}

vec4 SeaBumpMap(vec2 uv, vec3 nor)
{ 
    float ref = SeaBump(uv); 
    float e = 0.1;
    vec3 grad = vec3(SeaBump(vec2(uv.x-e, uv.y))-ref, 0.0, SeaBump(vec2(uv.x, uv.y-e))-ref); 
             
    grad -= nor*dot(nor, grad);          
                      
    return vec4(normalize(nor + grad*3.0), ref);
}

struct NormStruct
{
    vec3 norm;
    vec4 bumped;
};

//Normal calculation method Taken from this shader by Nimitz : https://www.shadertoy.com/view/Xts3WM  
NormStruct SeaNorm(in vec3 p)
{
    NormStruct o;
    vec2 e = vec2(-epsilon, epsilon);   
    float t1 = Sea(p + e.yxx), t2 = Sea(p + e.xxy);
    float t3 = Sea(p + e.xyx), t4 = Sea(p + e.yyy);

    o.norm = normalize(e.yxx*t1 + e.xxy*t2 + e.xyx*t3 + e.yyy*t4);
    o.bumped = SeaBumpMap(p.xz, o.norm);
    return o;
}

//Bump method Taken from this shader by Shane : from https://www.shadertoy.com/view/XlXXWj
float GroundBump(vec2 p)
{
    return 1.0 - textureLod(iChannel2, p*0.15, 0.0).x;
}

vec3 GroundBumpMap(vec2 uv, vec3 nor)
{ 
    float ref = GroundBump(uv); 
    float e = 0.05;
    vec3 grad = vec3(GroundBump(vec2(uv.x-e, uv.y))-ref, 0.0, GroundBump(vec2(uv.x, uv.y-e))-ref); 
             
    grad -= nor*dot(nor, grad);          
                      
    return normalize(nor + grad*6.0);
}

//Normal calculation method Taken from this shader by Nimitz : https://www.shadertoy.com/view/Xts3WM 
vec3 GroundNorm(in vec3 p)
{
    vec2 e = vec2(-epsilon, epsilon);   
    float t1 = Ground(p + e.yxx), t2 = Ground(p + e.xxy);
    float t3 = Ground(p + e.xyx), t4 = Ground(p + e.yyy);
	vec3 n = normalize(e.yxx*t1 + e.xxy*t2 + e.xyx*t3 + e.yyy*t4);
    
    return GroundBumpMap(p.xz, n);
}


struct rayMarchOut
{
    vec2 totalDistances;
    vec3 opaqueNormal;
    NormStruct transparentNormal;
    vec3 refractedNormal;
    float dist;
    vec2 mask;
};
    
rayMarchOut RayMarch(vec3 rayDir, vec3 cameraOrigin)
{
    rayMarchOut OUT;

	vec3 pos = cameraOrigin;
	OUT.totalDistances = vec2(0.0);
    OUT.opaqueNormal = vec3(0.0, 1.0, 0.0);
    OUT.transparentNormal.norm = vec3(0.0, 1.0, 0.0);
    OUT.transparentNormal.bumped = vec4(0.0, 1.0, 0.0, 0.0);
    OUT.refractedNormal = vec3(0.0, 1.0, 0.0);
    OUT.mask = vec2(0.0);
    bool hittedSea = false;
    
    for(int i = 0; i < maxItter; i++)
	{
        float distSea = Sea(pos);
        float distOpaque = Ground(pos);         
        OUT.dist = min(distSea, distOpaque);
        
		OUT.totalDistances.x += OUT.dist;

		pos += OUT.dist * rayDir;

        if(OUT.dist < epsilon)
		{
            OUT.mask = smoothstep(vec2(epsilon), vec2(epsilon) + vec2(0.25, 5.0), vec2(distOpaque));
            
            if(distSea < epsilon)
            {
                OUT.transparentNormal = SeaNorm(pos);
                hittedSea = true;
                break;
            }
            else
            {
                OUT.opaqueNormal = GroundNorm(pos);
				break;
            }
		}   
        
        if(OUT.totalDistances.x > maxDistance)
        {
            break;
        }
	}

    if(hittedSea == true)
    {   
    	vec3 refractedRay = normalize(refract(rayDir.xyz, OUT.transparentNormal.bumped.xyz, 1.0/1.333));
    	vec3 refractedPos = pos;
        
    	for(int j = 0; j < underWaterMaxItter; j++)
    	{                                    
    		float distRefracted = Ground(refractedPos);
    		OUT.totalDistances.y += distRefracted;         
    		refractedPos += distRefracted * refractedRay;
                    
    		if(distRefracted < epsilon)
    		{
    			OUT.refractedNormal = GroundNorm(refractedPos);
    			break;
    		}
                    
    		if(OUT.totalDistances.y > waterMaxDepth)
    		{
    			break;
    		}
    	}
    }
    
    return OUT;
}


//Camera Function by iq :
//https://www.shadertoy.com/view/Xds3zN
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

vec3 SeaLighting(NormStruct n, vec3 rayDir, vec3 reflectDir)
{
    float diff = max(0.0, dot(LIGHT, n.norm));
    float spec = smoothstep(0.98, 1.0, dot(reflectDir, LIGHT));
    float fresnel = (1.0 - max(0.0, dot(-n.bumped.xyz, rayDir)));
	//smoothstep(0.25, 1.0, dot((rayDir + LIGHT), n.bumped.xyz));
    return vec3(diff, spec*fresnel, fresnel); 
}

vec2 GroundLighting(vec3 n, vec3 rayDir)
{
    float diff = max(0.0, dot(LIGHT, n));
    float spec = smoothstep(0.5, 1.0, dot(reflect(rayDir, n), LIGHT));
	float fresnel = (1.0 - max(0.0, dot(-n, rayDir)));
    
    return vec2(diff, spec * fresnel); 
}

struct SkyStruct
{
    vec3 sky;
    vec3 glow;
    float lensFlare;
};

SkyStruct Sky(vec3 ray)
{
   SkyStruct o;
    
   vec3 diff = ray - LIGHT;
   float sunDist = clamp(length(diff), 0.0, 1.0);
   float at = (atan(diff.x, diff.y) + pi) / (2.0 * pi);
   vec4 rays = textureLod(iChannel0, vec2(iTime*0.02, at), 0.0).x * (1.0 - sunDist) * vec4(0.0, 0.05, 0.1, 0.0);

   vec4 sun = smoothstep(vec4(0.07, 0.3, 1.25, 0.5), vec4(0.0), vec4(sunDist)) * vec4(1.0, 0.2, 1.0, 1.0) + rays;
   vec3 grad = mix(vec3(1.2, 0.85, 0.7), vec3(0.55, 0.6, 0.7), smoothstep(0.0, 1.0, ray.y*1.5+0.4));
    
   vec3 res = grad + (sun.x + sun.y) * LIGHTCOLOR;
       
   o.sky = res;
   o.glow = sun.z * LIGHTCOLOR * 1.3;
   o.lensFlare = sun.w;
       
   return o;
}

float FoamNoise(vec3 pos)
{
    vec2 s = iTime * vec2(0.01);
    vec2 t1 = texture(iChannel1, pos.xz*0.03 + s).xz-0.5;
    float t2 = texture(iChannel1, pos.xz*0.06 - s + t1*0.1).y;
    
    return t2;
}

float Foam(vec3 pos, float noise, vec2 mask)
{
    float t = smoothstep(max(0.0, pos.y*0.5+1.2), 0.0, noise);
    float border = smoothstep(1.25, 1.5, (1.0 - mask.y)+noise) * mask.x * 0.75;
    return smoothstep(0.7, 1.0, t)*0.4 + border;
}

vec3 FoamBumpMap(vec3 pos, vec3 nor, float ref, vec2 mask)
{ 
    float e = 0.05;
    vec3 p1 = vec3(pos.x - e, pos.y, pos.z);
    vec3 p2 = vec3(pos.x, pos.y, pos.z - e);
    float fn1 = FoamNoise(p1);
    float fn2 = FoamNoise(p2);

    vec3 grad = vec3(Foam(p1, fn1, mask)-ref, 0.0, 
                     Foam(p2, fn2, mask)-ref); 
    
    grad -= nor*dot(nor, grad);          
                      
    return normalize(nor + grad*5.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    vec2 s = sinNoise(vec2(0.0), vec4(0.0, 0.1, 0.0, 0.2));
    
    float camX = 0.0;
    float camY = 7.0 - (s.x + s.y)*wavesHeight*2.0;
    float camZ = iTime*10.0;                
    vec3 cameraOrigin = vec3(camX, camY, camZ);
	vec3 cameraTarget = vec3(sin(iTime*0.25)*8.0, 0.0, cameraOrigin.z + 10.0);
    
	vec2 screenPos = uv * 2.0 - 1.0;
	screenPos.x *= iResolution.x/iResolution.y;
    
    mat3 cam = setCamera(cameraOrigin, cameraTarget, sin(iTime*0.3)*0.1);
    
    vec3 rayDir = cam*normalize(vec3(screenPos.xy,0.65));
    
    rayMarchOut r = RayMarch(rayDir, cameraOrigin);
    
    vec3 res = vec3(0.0);
    
    SkyStruct sky = Sky(rayDir);
   
    if(r.dist < epsilon)
    {  
        vec3 pos = cameraOrigin + r.totalDistances.x*rayDir;
        vec3 rfrPos = pos + r.totalDistances.y*rayDir;
		vec3 groundPos = mix(pos, rfrPos, r.mask.x);
        vec3 groundNorm = mix(r.opaqueNormal, r.refractedNormal, r.mask.x);
        vec3 groundColors =  groundColor * (0.5 + 0.5 * texture(iChannel1, groundPos.xz*0.2).xyz);
        vec3 groundAmb = mix(groundColors, groundColors * Sky(groundNorm).sky, 0.75);
        vec2 groundLighting = GroundLighting(groundNorm, rayDir);
        float rfrFog = clamp(smoothstep(waterMaxDepth, 0.0, r.totalDistances.y) + (1.0 - r.mask.x), 0.0, 1.0);
        vec3 groundFinal = groundAmb + groundAmb * groundLighting.x * LIGHTCOLOR + groundLighting.y * LIGHTCOLOR;
                
        float foamNoise = FoamNoise(pos);
        vec3 pf = pos + vec3(0.0, r.transparentNormal.bumped.w*0.75, 0.0);
        float foam = Foam(pf, foamNoise, r.mask);   
        r.transparentNormal.bumped.xyz = FoamBumpMap(pf, r.transparentNormal.bumped.xyz, foam, r.mask);
        r.transparentNormal.norm = FoamBumpMap(pf, r.transparentNormal.norm, foam, r.mask);
        
        vec3 seaRefl = reflect(rayDir, r.transparentNormal.bumped.xyz);
		vec3 seaLighting = SeaLighting(r.transparentNormal, rayDir, seaRefl);
        
        float d = smoothstep(0.0, 20.0, r.totalDistances.x);
        vec3 seaColor = mix(color3, mix(color1, color2, (pos.y + r.transparentNormal.bumped.w*1.5 + 0.25)), d) + foam;
        vec3 seaAmb = mix(seaColor, seaColor * Sky(seaRefl).sky, 0.5);
        vec3 seaFinal = mix(seaAmb, groundFinal, clamp(rfrFog - foam*0.6, 0.0, 1.0)) 
        + seaColor * (seaLighting.z * (1.0 - foam) + seaLighting.x) * LIGHTCOLOR + seaLighting.y * LIGHTCOLOR;
        
        float f = smoothstep(30.0, maxDistance, r.totalDistances.x);
        res = mix(seaFinal, sky.sky, f);
    }
    else  
    {
        res = sky.sky;
    }
    
    res += sky.glow * LIGHTCOLOR;
    
	vec2 v = 1.0 - abs(uv - 0.5) * 2.0;
    v.x *= v.y;
    v.x = clamp(v.x*2.0, 0.0, 1.0);
    
	fragColor = vec4(res, sky.lensFlare * v.x);
}