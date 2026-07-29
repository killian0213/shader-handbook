// Buffer B (buffer) — A cup of coffee (Progressive) by PixelPhil
// https://www.shadertoy.com/view/3ltXR8

// This buffer backs up the current frame and litens to the 'S' key
// To restart the slideshow. That's about it

#define KEY_S 83.0


bool isPressed(float keyCode) {
        keyCode = (keyCode + 0.5) / 256.0;
        vec2 uv = vec2(keyCode, 0.25);
        float key = texture(iChannel1, uv).r;

        return key > 0.0;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec4 inputTex =  textureLod(iChannel0, fragCoord.xy / iResolution.xy, 0.0);
    
    if (fragCoord.x < 1.0 && fragCoord.y < 1.0)
    {
        // In the secret pixel
        
        if (isPressed(KEY_S))
        {
            inputTex.z = 0.1; // Restart slideshow
            inputTex.a = 1.0; // Reset integration
        }
        
        if (iResolution.x <= 300.0 && inputTex.z == 0.0)
        {
            inputTex.z = 0.1; // Force Slideshow mode in the thumbnail
        }
    }
    
    fragColor = inputTex;
}

