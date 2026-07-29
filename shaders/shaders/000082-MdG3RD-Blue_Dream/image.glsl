// Image (image) — Blue Dream by Passion
// https://www.shadertoy.com/view/MdG3RD

const int NUM_SAMPLES = 55;

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    //vec4 buffer = texture(iChannel0,uv);
    float decay=0.96815;
    float exposure=0.21;
    float density=0.926;
    float weight=0.58767;
    
    vec2 tc = uv;
    vec2 lightPos = iMouse.xy;
    vec2 deltaTexCoord = tc;
    
    deltaTexCoord =  uv+vec2(sin(iTime*.7)*.3,-cos(iTime*.2)*.3)-.5;
    deltaTexCoord *= 1.0 / float(NUM_SAMPLES)  * density;
    
    float illuminationDecay = 1.0;
    vec4 color =texture(iChannel0, tc.xy)*0.305104;
    
    tc += deltaTexCoord * fract( sin(dot(uv.xy+fract(iTime), 
                                         vec2(12.9898, 78.233)))* 43758.5453 );
    
    for(int i=0; i < NUM_SAMPLES; i++)
    {
        tc -= deltaTexCoord;
        vec4 sampleTex = texture(iChannel0, tc)*0.305104;
        sampleTex *= illuminationDecay * weight;
        color += sampleTex;
        illuminationDecay *= decay;
    }
    fragColor = color*exposure;
}
