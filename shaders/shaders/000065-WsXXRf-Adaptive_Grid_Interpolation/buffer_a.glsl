// Buffer A (buffer) — Adaptive Grid Interpolation by drivenbynostalgia
// https://www.shadertoy.com/view/WsXXRf

// The purpose of Buffer A in this example is to provide data values to the reconstruction shaders.
// One value per cell is provided in stored in a 1D-buffer like fashion. In a real application,
// this buffer is provided by the host application whenever the data field changes.

float rand(float p)
{
	p = fract(p * 0.1031);
	p += 3.0 * p * (p + 19.19);

	return fract(2.0 * p * p);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    ivec2 bufferSize = ivec2(iResolution.xy);
    ivec2 texel = ivec2(fragCoord);
    int dataIndex = texel.y * bufferSize.x + texel.x;

    if (dataIndex < gNumCells)
    {
        fragColor = vec4(0.5 * sin(0.05 * iTime + 13.37 * rand(float(dataIndex))) + 0.5, 0.0, 0.0, 1.0);
    }
    else
    {
        fragColor = vec4(1.0, 0.5, 0.5, 1.0);
    }
}