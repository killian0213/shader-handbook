// Image (image) — Volume Path Tracing on Bunny by SebH
// https://www.shadertoy.com/view/7dVGWR

/*
Welcome to this volumetric path tracing demo!

It presents volumetric path tracing with ratio and spectral tracking to respectively estimate transmittance and scattering for multiple wavelength at the same time.

The cloud data comes from Disney https://www.disneyanimation.com/data-sets/?drawer=/resources/clouds/. See BufferA for more details as to how it is achieved.

!!!
==> I am so SORRY the cloud data generateion shader in BufferA takes so long to compile. It would be smarter to do some block compression for instance to improve that situation.
To change that you can set USE_CLOUD to 0.

==> By default, you should expect 5fp on a 1080. To improve framerate, you can reduce the scattering or path depth available at the top of BufferC code.
!!!

BufferB: the states of the scene+camera
BufferC: current frame tracing result
BufferD: accumulated result

Keys:
- click+mouse to look around
- press left arrow + mouse to move the sun around
- press up to reset accumulation history

Thanks to https://www.shadertoy.com/user/morimea for the many fixes for the OpenGL backend.

https://twitter.com/SebHillaire
https://sebh.github.io/
*/










// Final image output through sRGB

float sRGB(float x)
{
	if (x <= 0.00031308)
		return 12.92 * x;
	else
		return 1.055*pow(x, (1.0 / 2.4)) - 0.055;
}

void mainImage( out float4 fragColor, in float2 fragCoord )
{    
	float2 uv = fragCoord.xy / iResolution.xy;
    float time = iTime;
    
    float4 RGBSampleCount = texture(iChannel0, uv);
    fragColor = float4(sRGB(RGBSampleCount.r / RGBSampleCount.a), sRGB(RGBSampleCount.g / RGBSampleCount.a), sRGB(RGBSampleCount.b / RGBSampleCount.a), 1.0);
}
