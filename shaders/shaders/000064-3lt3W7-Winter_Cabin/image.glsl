// Image (image) — Winter Cabin by suyoku
// https://www.shadertoy.com/view/3lt3W7

#define KERNEL_SIZE 9

void DecompressColor(in vec4 color, out vec3 diffuseColor, out vec3 specularColor, out float depth, out int materialID)
{
    depth = fract(color.w);
    materialID = int(color.w - depth);
	depth *= SCENE_MAX_T; 
    
    diffuseColor = fract(color.rgb);
    specularColor = (color.rgb - diffuseColor) / 1000.0;
} 

float GaussianCurve(float x, float stdDev)
{
    return exp(-(x * x) / (2.0 * stdDev * stdDev)) / (sqrt(2.0 * PI) * stdDev);
}

vec3 GammaCorrect(in vec3 color)
{
    return pow( color, vec3(1.0 /2.2) );
}

vec3 Vignette(in vec3 color, in vec2 uv)
{
    // Don't vignette the top because that takes 
    // away from the aurora borealis
    float distToEdge = min(
        min(uv.x, 1.0 - uv.x),
        uv.y);
    return mix(color * 0.3, color, min(distToEdge / 0.12, 1.0));
}

#define NO_BLUR 0x0
#define SNOW_BLUR 0x1
#define DOF_BLUR 0x2
#define ICE_BLUR 0x4
#define DOF_BLUR_START 500.0
#define DOF_BLUR_GAUSSIAN_STD_DEV 2.1
int DetermineBlurType(float depth, int materialID)
{
    if(depth > DOF_BLUR_START)
    {
        return DOF_BLUR;
    }
    else if(materialID == SNOW_MATERIAL_ID)
    {
        return SNOW_BLUR;
    }
    else if(materialID == ICE_MATERIAL_ID)
    {
        return ICE_BLUR;
    }
    else
    {
        return NO_BLUR;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 pixelUVOffset = 1.0 / iResolution.xy;
    float accumulatedWeight = 0.0;
    vec3 accumulatedColor = vec3(0.0);
    vec3 centerSpecularColor;
	vec3 centerDiffuseColor;
    
    // Tuned at 800x450, scale gaussian distribution based on how much larger the
    // current viewport is
    float gaussianScale = iResolution.x / 800.0;

    float depth;
    vec3 diffuse, specular;
    int materialID;
    DecompressColor(texture(iChannel0, uv), centerDiffuseColor, centerSpecularColor, depth, materialID);
    int blurType = DetermineBlurType(depth, materialID);
    
    if(blurType != NO_BLUR)
    {
        for(int x = -KERNEL_SIZE / 2; x <= KERNEL_SIZE / 2; x++)
        {
            for(int y = -KERNEL_SIZE / 2; y <= KERNEL_SIZE / 2; y++)
            {
                float distFromCenter = sqrt(float(x * x + y * y));
                vec2 uvOffset = pixelUVOffset * vec2(x, y);

                vec3 diffuse, specular;
                DecompressColor(texture(iChannel0, uv + uvOffset), diffuse, specular, depth, materialID);
                
                bool validPixel = blurType != SNOW_BLUR || (materialID == SNOW_MATERIAL_ID);
                validPixel = blurType != ICE_BLUR || (materialID == ICE_MATERIAL_ID);
                if(validPixel)
                {
                    float gaussianStdDev;
                    if(blurType == DOF_BLUR)
                    {
                        // Just picking a constant amount that looks good
                        // Needed something that blurs the trees
                        // but also leaves some details for the 
                        // aurora borealis in-tact.
						gaussianStdDev = DOF_BLUR_GAUSSIAN_STD_DEV;
                    }
                    else
                    {
                        // Reduce the blur the further you get as a hack to account for
                        // perspective
                        gaussianStdDev = max(7.0 - depth / 50.0, DOF_BLUR_GAUSSIAN_STD_DEV);
                    }
                    float gaussianWeight = GaussianCurve(distFromCenter, gaussianStdDev * gaussianScale);
               		accumulatedWeight += gaussianWeight;
                	accumulatedColor += gaussianWeight * diffuse;
                }

            }
        }
    }
    else
    {
        accumulatedWeight = 1.0;
        accumulatedColor = centerDiffuseColor;
    }
    
    vec3 finalColor = centerSpecularColor + (accumulatedColor / accumulatedWeight);
	fragColor = vec4(GammaCorrect(Vignette(finalColor, uv)), 1.0);
}