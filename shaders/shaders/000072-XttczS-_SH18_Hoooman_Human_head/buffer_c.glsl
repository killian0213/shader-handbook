// Buffer C (buffer) — [SH18] Hoooman: Human head by ThomasSchander
// https://www.shadertoy.com/view/XttczS

mat3 setCamera( vec3 ro, vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

float sq(float x)
{
    return x*x;
}

float pow5(float x)
{
	float x2 = x*x;
	return x2*x2*x;
}

float F_Schlick(float f0, float VoN)
{
	return f0 + (1.0 - f0) * pow5(1.0 - VoN);
}

float F_Schlick (in float f0 , in float f90 , in float cosT )
{
	return f0 + (f90 - f0) * pow5(1.0 - cosT);
}

float GGX( float roughness, float NoH )
{
	float m = roughness * roughness;
	float m2 = m*m;
	float f = ( NoH * m2 - NoH ) * NoH + 1.0;
	return m2 / (f*f);
}

float SmithJoint(float roughness,float NoV,float NoL )
{
	float a = roughness*roughness;
	float Vis_SmithV = NoL* (NoV* (1.0-a) + a);
	float Vis_SmithL = NoV* (NoL* (1.0-a) + a);
	return 0.5/(Vis_SmithV + Vis_SmithL);
}

const float MAX_Z = 0.02;

float Burley(float roughness, float NoV, float NoL, float VoH)
{
	float FD90 = (0.5 + 2.0 * VoH * VoH) * roughness;
	float FdV = F_Schlick(1.0, FD90, NoV);
	float FdL = F_Schlick(1.0, FD90, NoL);
	return FdV * FdL * (1.0 - roughness * 0.338);
}

vec3 spotlight(vec3 Lpos, vec3 Lspot, vec3 hitPoint, float spotAngle, vec3 albedo, vec3 N, vec3 V)
{
    Lpos += (floatRand3()-vec3(0.5)) * 0.02;
    const float SMAX_S = 0.6;
    const float SSTEPSIZE = 0.009;
    vec3 Ldelta = Lpos - hitPoint;
    float Llen = length(Ldelta);
    vec3 L = Ldelta/Llen;
    vec3 H = normalize(V + L);
    float VoH = saturate(dot(V, H));
    float NoV = abs(dot(N, V)) + 1e-5;
    float NoH = saturate(dot(N, H));
    float NoL = saturate(dot(N, L));    
    float att = max(0.0, smoothstep(spotAngle, 1.0-0.5*(1.0-spotAngle), dot(L, -Lspot)) / (Llen*Llen));
    float rough = 0.8*albedo.r;
    float F = F_Schlick(0.035, NoV);
    vec3 lightCon = NoL*(albedo*Burley(rough, NoV, NoL, VoH) + SmithJoint(rough, NoV, NoL)*GGX(rough, NoH)*F);
    vec3 subS = vec3(0.0);
    float s = 0.008+floatRand() * SSTEPSIZE;
    for(; s < SMAX_S; s+=SSTEPSIZE)
    {
        vec3 tP = hitPoint + s*L;
        vec3 tPUV = tP / VOL_DIMS;
        vec4 dRead = textureLod(iChannel0, tPUV.xy+ (floatRand2()-vec2(0.5)) * 0.0, 0.0);
        if(dRead.w > tPUV.z && dRead.w > MAX_Z && dRead.z < tPUV.z && tPUV.xy == saturate(tPUV.xy))
        {
            lightCon = vec3(-1.0);
            subS = vec3(0.0);
        }
        else if(lightCon == vec3(-1.0) && subS == vec3(0.0))
        {
            vec3 incNormal = oct_to_float32x3(dRead.xy);
            subS = 0.7*vec3(0.17, 0.03, 0.01) * exp(-650.0*s*s) * saturate(0.5+0.5*dot(incNormal, L)) * exp(-max(0.0, -100.0*tP.z));
        }
    }
    return att * (max(vec3(0.0), lightCon) + subS * albedo);
}

#define NUM_LIGHTS 2
#define NUM_KEYFRAMES 3

struct KeyFrame
{
    vec3 camPos[2];
    vec3 camLookAt[2];
    
    vec3 lightPos[NUM_LIGHTS];
    vec3 lightSpot[NUM_LIGHTS];
    vec3 ambientDir;
};

KeyFrame keyframes[NUM_KEYFRAMES];

float smStep(float x)
{
    return 3.0*x*x-2.0*x*x*x;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    seed = fragCoord.x + fragCoord.y * 1.125125 + iTime;
    vec2 mo = iMouse.xy/iResolution.xy;
	float time = 15.0 + iTime;
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec3 camPos = vec3(VOL_DIMS.x *0.5 - 1.6*cos(3.0*mo.x), VOL_DIMS.y * 0.1 + mo.y*1.0, 0.9 + 0.9*sin(3.0*mo.x) );
    vec3 target = VOL_DIMS * 0.5;
    vec3 lightPos[2] = vec3[2](vec3(-0.9, 1.0, -0.7), vec3(1.7, 1.0, -0.7));
    vec3 lightSpot[2] = vec3[2](vec3(0.35, -0.2, 0.8), vec3(-0.4, -0.2, 0.8));
    vec3 ambientDir = vec3(-0.4, -0.3, 0.2);
    keyframes[0] = KeyFrame(vec3[2](vec3(1.4, 0.5, -1.4), vec3(2.3, 0.2, 0.2)),
                            vec3[2](vec3(0.6, 0.47, 0.14), vec3(0.45, 0.44, 0.2)),
                            vec3[2](vec3(0.2, 0.45, 1.9), vec3(-1.2, 1.0, 0.9)), // light pos
                            vec3[2](vec3(0.0, 0.35, -0.7), vec3(0.7, -0.0, -0.9)), // light dir
                            vec3(-0.6, -0.3, 0.3) );
    
    keyframes[1] = KeyFrame(vec3[2](vec3(0.48, 1.8, 1.5), vec3(0.51, 0.1, 2.1)),
                            vec3[2](vec3(0.45, 0.41, 0.25), vec3(0.44, 0.45, 0.14)),
                            vec3[2](vec3(-0.62, 0.2, -1.1), vec3(1.2, 0.6, -0.1)), // light pos
                            vec3[2](vec3(0.5, 0.6, 0.8), vec3(-0.5, 0.0, 0.2)), // light dir
                            vec3(-0.6, -0.3, 0.4) );
    
    keyframes[2] = KeyFrame(vec3[2](vec3(-0.45, 0.6, 1.3), vec3(-0.1, 0.7, 1.6)),
                            vec3[2](vec3(0.57, 0.48, 0.14), vec3(0.5, 0.47, 0.14)),
                            vec3[2](vec3(-0.3, 0.6, -0.9), vec3(1.2, 0.6, 0.2)), // light pos
                            vec3[2](vec3(0.02, -0.0, 0.9), vec3(-0.5, 0.0, 0.2)), // light dir
                            vec3(-0.6, 0.8, 0.4) );
    const float KF_TIME = 8.0;
    float blackBlend = 1.0;
#if 1
    int kfId = int(iTime / KF_TIME);
    if(iMouse.z < 0.0001 && kfId < NUM_KEYFRAMES)
    {        
        float kfProgress = fract(iTime / KF_TIME);
        blackBlend = min(1.0, 10.0*kfProgress) * saturate(6.0*(1.0 - kfProgress));
#else // Used for keyframe debugging
    if(iMouse.z < 0.0001)
    {
        float kfProgress = 1.0;
        int kfId = 0;
#endif
        float smP = smStep(kfProgress);
        smP = smStep(smP);
        camPos = mix(keyframes[kfId].camPos[0], keyframes[kfId].camPos[1], smP);
        target = mix(keyframes[kfId].camLookAt[0], keyframes[kfId].camLookAt[1], kfProgress);
        lightPos = keyframes[kfId].lightPos;
        lightSpot = keyframes[kfId].lightSpot;
        ambientDir = keyframes[kfId].ambientDir;
    }
    
    mat3 ca = setCamera( camPos, target, 0.0 );
    vec2 p = (-iResolution.xy + 2.0*(fragCoord + floatRand2(iTime)))/iResolution.y;
    vec3 V = ca * normalize( -vec3(p.xy, 4.0) );
       
    const float MAX_S = 3.0;
    const float STEPSIZE = 0.002;
    vec3 N;
    vec3 albedo = vec3(0.0);
    float s = 1.2 + floatRand() * STEPSIZE;
    for(; s < MAX_S; s+=STEPSIZE)
    {
        vec3 tP = camPos - s*V;
        vec3 tPUV = tP / VOL_DIMS;
        vec4 dRead = textureLod(iChannel0, tPUV.xy + (floatRand2()-vec2(0.5)) * 0.0, 0.0);
        if(dRead.w > tPUV.z && dRead.w > MAX_Z && dRead.z < tPUV.z && tPUV.xy == saturate(tPUV.xy))
        {
            N = oct_to_float32x3(dRead.xy);
            vec3 mirrorNormal = N;
            mirrorNormal.z *= -1.0;
            mirrorNormal = mix(mirrorNormal, vec3(0.0, 0.0, -1.0), saturate(-1.9*tPUV.z));
            N = normalize(mix(N, normalize(mirrorNormal), saturate(2.5*max(0.0, -(tPUV.z-dRead.w)))));
            albedo = textureLod(iChannel1, tPUV.xy, 0.0).xyz;
            albedo = mix(albedo, vec3(195.0, 151.0, 141.0)/255.0, saturate(-1.9*tPUV.z));
            break;
        }
    }
    
    if(s >= MAX_S)
    {
        // SKY
        fragColor = 0.09*max(vec4(0.0), vec4(0.05, 0.1-0.2*V.y, 0.2-0.5*V.y, 1.0));
        fragColor.xyz += 0.07*textureLod(iChannel2, -V, 0.0).xyz;
    }
    else
    {
        vec3 hitPoint = camPos - s*V;
        albedo = pow(albedo, vec3(2.2));
        vec3 lightContrib = spotlight(lightPos[0], normalize(lightSpot[0]), hitPoint, 0.8, albedo, N, V);
        lightContrib += 0.5*spotlight(lightPos[1], normalize(lightSpot[1]), hitPoint, 0.8, albedo, N, V);
        lightContrib += 0.2*spotlight(vec3(1.1, 1.0, 0.8), normalize(vec3(-1.0, -0.16, -1.0)), hitPoint, 0.8, albedo, N, V);
        fragColor.xyz = vec3(0.1)*max(0.0, dot(ambientDir, N)+0.5)*albedo + lightContrib;
    }
    fragColor *= blackBlend;
    return;
}
