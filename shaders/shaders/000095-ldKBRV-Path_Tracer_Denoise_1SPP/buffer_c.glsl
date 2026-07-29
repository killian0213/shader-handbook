// Buffer C (buffer) — Path Tracer Denoise 1SPP by cornusammonis
// https://www.shadertoy.com/view/ldKBRV

// Edge-Avoiding À-TrousWavelet Transform for denoising
// implemented on https://www.shadertoy.com/view/ldKBzG
// feel free to use it

// here, the denoising kernel stride ranges from 1.0 to 4.0
#define DENOISE_RANGE vec2(1, 4)

float hash1(float seed) {
    return fract(sin(seed)*43758.5453123);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) 
{
    
    vec2 offset[25];
    offset[0] = vec2(-2,-2);
    offset[1] = vec2(-1,-2);
    offset[2] = vec2(0,-2);
    offset[3] = vec2(1,-2);
    offset[4] = vec2(2,-2);
    
    offset[5] = vec2(-2,-1);
    offset[6] = vec2(-1,-1);
    offset[7] = vec2(0,-1);
    offset[8] = vec2(1,-1);
    offset[9] = vec2(2,-1);
    
    offset[10] = vec2(-2,0);
    offset[11] = vec2(-1,0);
    offset[12] = vec2(0,0);
    offset[13] = vec2(1,0);
    offset[14] = vec2(2,0);
    
    offset[15] = vec2(-2,1);
    offset[16] = vec2(-1,1);
    offset[17] = vec2(0,1);
    offset[18] = vec2(1,1);
    offset[19] = vec2(2,1);
    
    offset[20] = vec2(-2,2);
    offset[21] = vec2(-1,2);
    offset[22] = vec2(0,2);
    offset[23] = vec2(1,2);
    offset[24] = vec2(2,2);
    
    
    float kernel[25];
    kernel[0] = 1.0f/256.0f;
    kernel[1] = 1.0f/64.0f;
    kernel[2] = 3.0f/128.0f;
    kernel[3] = 1.0f/64.0f;
    kernel[4] = 1.0f/256.0f;
    
    kernel[5] = 1.0f/64.0f;
    kernel[6] = 1.0f/16.0f;
    kernel[7] = 3.0f/32.0f;
    kernel[8] = 1.0f/16.0f;
    kernel[9] = 1.0f/64.0f;
    
    kernel[10] = 3.0f/128.0f;
    kernel[11] = 3.0f/32.0f;
    kernel[12] = 9.0f/64.0f;
    kernel[13] = 3.0f/32.0f;
    kernel[14] = 3.0f/128.0f;
    
    kernel[15] = 1.0f/64.0f;
    kernel[16] = 1.0f/16.0f;
    kernel[17] = 3.0f/32.0f;
    kernel[18] = 1.0f/16.0f;
    kernel[19] = 1.0f/64.0f;
    
    kernel[20] = 1.0f/256.0f;
    kernel[21] = 1.0f/64.0f;
    kernel[22] = 3.0f/128.0f;
    kernel[23] = 1.0f/64.0f;
    kernel[24] = 1.0f/256.0f;
    
    vec3 sum = vec3(0.0);
    vec3 sum_f = vec3(0.0);
    float c_phi = 1.0;
    float r_phi = 1.0;
    float n_phi = 0.5;
    float p_phi = 0.25;
    
	vec3 cval = texelFetch(iChannel0, ivec2(fragCoord), 0).xyz;
    vec3 rval = texelFetch(iChannel2, ivec2(fragCoord), 0).xyz;
	vec3 nval = texelFetch(iChannel1, ivec2(fragCoord), 0).xyz;

    float ang = 2.0*3.1415926535*hash1(251.12860182*fragCoord.x + 729.9126812*fragCoord.y+5.1839513*iTime);
	mat2 m = mat2(cos(ang),sin(ang),-sin(ang),cos(ang));
    
    float cum_w = 0.0;
    float cum_fw = 0.0;
    
    float denoiseStrength = (DENOISE_RANGE.x + (DENOISE_RANGE.y-DENOISE_RANGE.x)*hash1(641.128752*fragCoord.x + 312.321374*fragCoord.y+1.92357812*iTime));
    
    for(int i=0; i<25; i++)
    {
        vec2 uv = (fragCoord+m*(offset[i]* denoiseStrength))/iResolution.xy;
        
        vec3 ctmp = texture(iChannel0, uv).xyz;
        vec3 t = cval - ctmp;
        float dist2 = dot(t,t);
        float c_w = min(exp(-(dist2)/c_phi), 1.0);
        
        vec3 ntmp = texture(iChannel1, uv).xyz;
        t = nval - ntmp;
        dist2 = max(dot(t,t), 0.0);
        float n_w = min(exp(-(dist2)/n_phi), 1.0);
        
        vec3 rtmp = texture(iChannel2, uv).xyz;
        t = rval - rtmp;
        dist2 = dot(t,t);
        float r_w = min(exp(-(dist2)/r_phi), 1.0);
        
        // new denoised frame
        float weight0 = c_w*n_w;
        sum += ctmp*weight0*kernel[i];
        cum_w += weight0*kernel[i];
        
        // denoise the previous denoised frame again
        float weight1 = r_w*n_w;
        sum_f += rtmp*weight1*kernel[i];
        cum_fw += weight1*kernel[i];
    }
    
    // mix in more of the just-denoised frame if it differs significantly from the
    // frame from feedback
    vec3 ptmp = texture(iChannel2, fragCoord/iResolution.xy).xyz;
    vec3 t = sum/cum_w - ptmp;
    float dist2 = dot(t,t);
    float p_w = min(exp(-(dist2)/p_phi), 1.0);
    
    fragColor = clamp(vec4(mix(sum/cum_w,sum_f/cum_fw,p_w),0.0),0.0,1.0);


}