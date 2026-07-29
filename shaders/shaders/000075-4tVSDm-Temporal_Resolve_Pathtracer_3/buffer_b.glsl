// Buffer B (buffer) — Temporal Resolve Pathtracer 3 by granito
// https://www.shadertoy.com/view/4tVSDm

//Temporal sampling

float grayscale(vec3 image) {
    return dot(image, vec3(0.3, 0.59, 0.11));
}

float normpdf(in float x, in float sigma)
{
	return 0.39894*exp(-0.5*x*x/(sigma*sigma))/sigma;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
  lowp vec2 uv = fragCoord.xy / iResolution.xy;

    
  lowp vec3 imageacc = max( texture(iChannel1,uv).rgb , vec3(0.0));
  lowp vec3 image = max( texture(iChannel0,uv).rgb , vec3(0.0));  

    //declare stuff
    const int mSize = 6;
    const int kSize = (mSize-1)/2 ;
    float kernel[mSize];
    lowp vec3 imageblurred = vec3(0.0);

    //create the 1-D kernel
    float sigma = 2.;
    float Z = 0.0;
    for (int j = 0; j <= kSize; ++j)
    {
        kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j), sigma);
    }

    //get the normalization factor (as the gaussian has been clamped)
    for (int j = 0; j < mSize; ++j)
    {
        Z += kernel[j];
    }

    //read out the texels
    for (int i=-kSize; i <= kSize; ++i)
    {
        for (int j=-kSize; j <= kSize; ++j)
        {
            imageblurred += kernel[kSize+j]*kernel[kSize+i]*texture(iChannel0, (fragCoord.xy+vec2(float(i),float(j))) / iResolution.xy).rgb;

        }
    }   
    
    imageblurred = imageblurred / (Z*Z);  
    
    image = min(image, imageblurred * 1.25); // reduce fireflies 
    //image = max(image, imageblurred * 0.75); // reduce darkflies

    if (iMouse.z < 0.5) 
    {
        // attempt to reduce ghosting
        lowp float weight = grayscale( pow( clamp( abs(imageacc - image) * 0.25 , 0., 1.), vec3(0.35)));
        imageacc = mix(imageacc, image, clamp(weight + 0., 0.05, 1.));
    } else { 

        imageacc = image;
    }
    
    fragColor = vec4(imageacc,1.0);

	
}