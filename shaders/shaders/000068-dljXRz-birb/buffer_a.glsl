// Buffer A (buffer) — birb by A_Toaster
// https://www.shadertoy.com/view/dljXRz

// Pre-calculated BRDF LUT for reflections

#define PI 3.14159265359
#define INV_PI 0.31830988618
#define INV_SQRT_PI 0.56418958354

vec2 SampleEquirectangular(vec3 dir)
{
    vec2 uv = vec2(atan(dir.z, dir.x), asin(dir.y));
    uv *= vec2(0.1591, 0.3183);
    uv += 0.5;
    return uv;
}

vec3 F_Schlick(float NoV, vec3 F0, float roughness)
{
	return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - NoV, 5.0);
}

float D_GGX(float NoH, float roughness)
{
	float a = roughness * roughness;
    float a2 = a * a;
    float nom = a2;
    float denom = (NoH * NoH * (a2 - 1.0) + 1.0);
	denom = PI * denom * denom;
    
    return nom / denom;
}

float G_SmithIBL(float roughness, float NoL, float NoV)
{
	float k = roughness * roughness * 0.5;
    return (NoL * NoV) / ((k + NoV * (1.0 - k)) * (k + NoL * (1.0 - k)));
}

float G_SmithDirect(float roughness, float NoL, float NoV)
{
	float k = (roughness + 1.0) * (roughness + 1.0) * 0.125;
    return (NoL * NoV) / ((k + NoV * (1.0 - k)) * (k + NoL * (1.0 - k)));
}

vec3 ImportanceSampleGGX(vec2 Xi, float roughness, vec3 n)
{
	float a = roughness * roughness;
    float phi = 2.0 * PI * Xi.x;
	float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a * a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
    
    vec3 h;
    h.x = sinTheta * cos(phi);
    h.y = sinTheta * sin(phi);
    h.z = cosTheta;
    
    vec3 up = abs(n.z) < 0.999 ? vec3(0, 0, 1) : vec3(1, 0, 0);
    vec3 tangentX = normalize(cross(up, n));
    vec3 tangentY = cross(n, tangentX);
    return tangentX * h.x + tangentY * h.y + n * h.z;
}

vec2 Hammersley(uint i, uint N)
{
    uint bits = i;
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    float inv = float(bits) * 2.3283064365386963e-10;
	return vec2(float(i)/float(N), inv);
}


vec2 IntegrateBRDF(float roughness, float NoV)
{
	vec3 v;
    v.x = sqrt(1.0 - NoV * NoV);
    v.y = 0.0;
    v.z = NoV;
    
    float A = 0.0;
    float B = 0.0;
    
    vec3 n = vec3(0.0, 0.0, 1.0);
    
    const uint numSamples = 1024u;
    for (uint i = 0u; i < numSamples; i++)
    {
    	vec2 Xi = Hammersley(i, numSamples);
        vec3 h = ImportanceSampleGGX(Xi, roughness, n);
        vec3 l = 2.0 * dot(v, h) * h - v;
        
        float NoL = clamp(l.z, 0.0, 1.0);
        float NoH = clamp(h.z, 0.0, 1.0);
        float VoH = clamp(dot(v, h), 0.0, 1.0);
        
        if (NoL > 0.0)
        {
            float G = G_SmithIBL(roughness, NoL, NoV);
            float G_Vis = G * VoH / (NoH * NoV);
            float Fc = pow(1.0 - VoH, 5.0);
            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }
    
    return vec2(A, B) / float(numSamples);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    if (iFrame > 0) {
        if(fragCoord.x > 256. || fragCoord.y > 256.){
            fragColor = vec4(0.);
        } else {
    
    
            vec2 uv = fragCoord / vec2(256.);
            float NoV = uv.x;
            float roughness = uv.y;
            fragColor = vec4(IntegrateBRDF(roughness, NoV).xy, 0.0, 1.0);
        }
    } else {
        fragColor = texelFetch(iChannel0, ivec2(fragCoord), 0);
        return;
    }
}