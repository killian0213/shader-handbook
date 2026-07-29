// Image (image) — Fix texture tiling in 3 taps by Suslik
// https://www.shadertoy.com/view/tsVGRd

const float pi = 3.141592;
const vec2 hexRatio = vec2(1.0, sqrt(3.0));

//credits for hex tiling goes to Shane (https://www.shadertoy.com/view/Xljczw)
//center, index
vec4 GetHexGridInfo(vec2 uv)
{
  vec4 hexIndex = round(vec4(uv, uv - vec2(0.5, 1.0)) / hexRatio.xyxy);
  vec4 hexCenter = vec4(hexIndex.xy * hexRatio, (hexIndex.zw + 0.5) * hexRatio);
  vec4 offset = uv.xyxy - hexCenter;
  return dot(offset.xy, offset.xy) < dot(offset.zw, offset.zw) ? 
    vec4(hexCenter.xy, hexIndex.xy) : 
    vec4(hexCenter.zw, hexIndex.zw);
}

float GetHexSDF(in vec2 p)
{
  p = abs(p);
  return 0.5 - max(dot(p, hexRatio * 0.5), p.x);
}

//xy: node pos, z: weight
vec3 GetTriangleInterpNode(in vec2 pos, in float freq, in int nodeIndex)
{
  vec2 nodeOffsets[] = vec2[](
    vec2(0.0, 0.0),
    vec2(1.0, 1.0),
    vec2(1.0,-1.0));

  vec2 uv = pos * freq + nodeOffsets[nodeIndex] / hexRatio.xy * 0.5;
  vec4 hexInfo = GetHexGridInfo(uv);
  float dist = GetHexSDF(uv - hexInfo.xy) * 2.0;
  return vec3(hexInfo.xy / freq, dist);
}

vec3 hash33( vec3 p )
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
			  dot(p,vec3(269.5,183.3,246.1)),
			  dot(p,vec3(113.5,271.9,124.6)));

	return fract(sin(p)*43758.5453123);
}

vec4 GetTextureSample(vec2 pos, float freq, vec2 nodePoint)
{
    vec3 hash = hash33(vec3(nodePoint.xy, 0));
    float ang = hash.x * 2.0 * pi;
    mat2 rotation = mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
    
    vec2 uv = rotation * pos * freq + hash.yz;
    return texture(iChannel0, uv);
}

vec2 GetVelocity(vec2 pos)
{
    float aspect = iResolution.y / iResolution.x;
    vec2 diff0 = pos - vec2(0.2, 0.5 * aspect);
    vec2 diff1 = pos - vec2(0.8, 0.5 * aspect);
    
    float charge0 = -0.01;
    float charge1 =  0.01;
    
    float eps = 0.1;
    return 
        normalize(diff0) * charge0 / (dot(diff0, diff0) + eps) +
        normalize(diff1) * charge1 / (dot(diff1, diff1) + eps);
}

vec4 GetScrollingTextureSample(vec2 pos, float freq, vec2 nodePoint, vec2 velocity)
{
    vec3 hash = hash33(vec3(nodePoint.xy, 0));
    float ang = hash.x * 2.0 * pi;
    mat2 rotation = mat2(cos(ang), sin(ang), -sin(ang), cos(ang));
    
    vec2 dir = normalize(velocity);
    mat2 flowMatrix = mat2(dir.x, dir.y, -dir.y, dir.x);
    mat2 flowStretch = mat2(2.0, 0.0, 0.0, 1.0);
    vec2 flowPos = flowStretch * (inverse(flowMatrix) * pos * freq + vec2(iTime, 0.0));
    vec2 uv = rotation * flowMatrix * flowPos + hash.yz;
    return texture(iChannel0, uv);
}

//from Qizhi Yu, et al [2011]. Lagrangian Texture Advection: Preserving Both Spectrum and Velocity Field. 
//IEEE Transactions on Visualization and Computer Graphics 17, 11 (2011), 1612–1623
vec3 PreserveVariance(vec3 linearColor, vec3 meanColor, float moment2)
{
    return (linearColor - meanColor) / sqrt(moment2) + meanColor;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 normCoord = fragCoord / iResolution.xy;
    ivec2 quadIndex2 = ivec2(normCoord * 2.0);
    int quadIndex = quadIndex2.x + quadIndex2.y * 2;
    
    vec2 quadCoord = mod(fragCoord, iResolution.xy * 0.5) / (iResolution.x * 0.5);
    
    float texFreq = 10.0;
    float tileFreq = 20.0;
    
    vec2 centralDist = abs(fragCoord.xy - iResolution.xy * 0.5);
    if(centralDist.x < 2.0 || centralDist.y < 2.0)
    {
        fragColor = vec4(1.0);
        return;
    }

    fragColor = vec4(0.0);
    if(quadIndex == 0)
    {
        fragColor = GetTextureSample(quadCoord, texFreq, vec2(0.0));
    }
    if(quadIndex == 1)
    {
        float moment1 = 0.0;
        float moment2 = 0.0;
        for(int i = 0; i < 3; i++)
        {
            vec3 interpNode = GetTriangleInterpNode(quadCoord, tileFreq, i);
            fragColor += GetTextureSample(quadCoord, texFreq, interpNode.xy) * interpNode.z;
            
            moment1 += interpNode.z;
            moment2 += interpNode.z * interpNode.z;
        }
        vec3 meanColor = textureLod(iChannel0, vec2(0.0), 10.0).rgb;
        
        float subquadDelta = fragCoord.x - iResolution.x * 3.0 / 4.0;
        if(abs(subquadDelta) < 2.0)
        {
            fragColor.rgb = vec3(1.0);
            return;
        }
        if(subquadDelta > 0.0) //variance-preserving blending
            fragColor.rgb = PreserveVariance(fragColor.rgb, meanColor, moment2);
    }
    if(quadIndex == 2)
    {
        vec3 opacities = clamp((fract(0.2 * iTime) - vec3(0.0, 1.0 / 3.0, 2.0 / 3.0)) * 10.0, vec3(0.0), vec3(1.0));
        for(int i = 0; i < 3; i++)
        {
            
            vec3 interpNode = GetTriangleInterpNode(quadCoord, tileFreq, i);
            fragColor += GetTextureSample(quadCoord, texFreq, interpNode.xy) * interpNode.z * opacities[i];
        }
    }

    if(quadIndex == 3)
    {
        for(int i = 0; i < 3; i++)
        {
            vec3 interpNode = GetTriangleInterpNode(quadCoord, tileFreq, i);
            vec2 velocity = GetVelocity(interpNode.xy);
            fragColor += GetTextureSample(quadCoord + velocity * iTime, texFreq, interpNode.xy) * interpNode.z;
            //can be used for simulating stuff that scrolls and stretches locally like water ripples, waves, etc
            //fragColor += GetScrollingTextureSample(quadCoord, texFreq, interpNode.xy, velocity) * interpNode.z;
        }
    }
}