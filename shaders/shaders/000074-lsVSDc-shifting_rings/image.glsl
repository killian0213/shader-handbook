// Image (image) — shifting rings by mahalis
// https://www.shadertoy.com/view/lsVSDc

float ringStep(float outerRadius, float innerRadius, vec2 coord, float rotationOffset) {
    float d = length(coord);
    const float smoothingWidth = 0.02;
    float ringValue = smoothstep(smoothingWidth, 0.0, d - outerRadius) * smoothstep(0.0, smoothingWidth, d - innerRadius);
    float radialMultiplier = fract(atan(coord.y, coord.x) * 7.0 / 6.28 - 0.3 * iTime + rotationOffset);
    return ringValue * smoothstep(0.0, 0.1, radialMultiplier - 0.4);
}

float noiseish(vec2 coord, vec2 coordMultiplier1, vec2 coordMultiplier2, vec2 coordMultiplier3, vec3 timeMultipliers) {
    return 0.5 + 0.1667 * (sin(dot(coordMultiplier1, coord) + timeMultipliers.x * iTime) + sin(dot(coordMultiplier2, coord) + timeMultipliers.y * iTime) + sin(dot(coordMultiplier3, coord) + timeMultipliers.z * iTime));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.y;
    uv.x += 0.04 * cos(0.6 * uv.x + 0.7 * uv.y - 4.0*cos(0.3 * iTime) * (0.3 + 0.02*uv.y));
    const float cellResolution = 7.0;
    vec2 localUV = fract(uv * cellResolution) - vec2(0.5);
    const float smoothingWidth = 0.04;
    
    vec2 cellCoord = floor(uv * cellResolution);
    
    float cellValue = noiseish(cellCoord, vec2(1.3, -1.0), vec2(1.7, 1.9), vec2(0.3, 0.7), vec3(-1.3, 2.3, -0.8));
    float outer1 = 0.2 + 0.3 * cellValue;
    float inner1 = 0.02 + 0.38 * pow(cellValue, 0.8);
    
    float cellValue2 = noiseish(cellCoord, vec2(-2.3, 1.1), vec2(1.4, 0.8), vec2(0.1, 0.5), vec3(2.1, 1.9, -1.7));
    
    float v = 1.0 - (ringStep(outer1, inner1, localUV, 0.0) + ringStep(0.05 + 0.25 * cellValue2, 0.05 + 0.05 * cellValue2, localUV, iTime * 1.2));
    
	fragColor = vec4(v, v, v, 1.0);
}