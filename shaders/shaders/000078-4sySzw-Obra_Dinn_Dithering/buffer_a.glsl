// Buf A (buffer) — Obra Dinn Dithering by cornusammonis
// https://www.shadertoy.com/view/4sySzw

#define B 232.0

vec2 uv = vec2(0);
vec2 texel = vec2(0);

float err(int i, int j) {
    vec4 temp = texture(iChannel1, uv + vec2(float(i)*texel.x, float(j)*texel.y));
    return temp.y*(1.0-temp.z) - temp.y*temp.z;
} 

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float kernel[25];         

    kernel[0] = 1.0/B;    
    kernel[1] = 4.0/B;     
    kernel[2] = 7.0/B;    
    kernel[3] = 4.0/B;     
    kernel[4] = 1.0/B; 
    kernel[5] = 4.0/B;  
    kernel[6] = 16.0/B;  
    kernel[7] = 26.0/B; 
    kernel[8] = 16.0/B;  
    kernel[9] = 4.0/B; 
    kernel[10] = 7.0/B;  
    kernel[11] = 26.0/B;  
    kernel[12] = 0.0/B;  
    kernel[13] = 26.0/B;  
    kernel[14] = 7.0/B; 
    kernel[15] = 4.0/B;  
    kernel[16] = 16.0/B;  
    kernel[17] = 26.0/B; 
    kernel[18] = 16.0/B;  
    kernel[19] = 4.0/B; 
    kernel[20] = 1.0/B;  
    kernel[21] = 4.0/B;   
    kernel[22] = 7.0/B;  
    kernel[23] = 4.0/B;   
    kernel[24] = 1.0/B;

    uv = fragCoord.xy / iResolution.xy;
    texel = 1.0 / iResolution.xy;
    vec4 cr = texture(iChannel0, uv); 
    vec4 rc = texture(iChannel1, uv);
    vec4 cur = vec4(cr.x, rc.yz, 0.0);
    float sum = cur.x + kernel[ 0]*err(-2,-2) + kernel[ 1]*err(-1,-2) + kernel[ 2]*err( 0,-2) + kernel[ 3]*err( 1,-2) + kernel[ 4]*err( 2,-2) + 
        kernel[ 5]*err(-2,-1) + kernel[ 6]*err(-1,-1) + kernel[ 7]*err( 0,-1) + kernel[ 8]*err( 1,-1) + kernel[ 9]*err( 2,-1) + 
        kernel[10]*err(-2, 0) + kernel[11]*err(-1, 0) + kernel[12]*err( 0, 0) + kernel[13]*err( 1, 0) + kernel[14]*err( 2, 0) + 
        kernel[15]*err(-2, 1) + kernel[16]*err(-1, 1) + kernel[17]*err( 0, 1) + kernel[18]*err( 1, 1) + kernel[19]*err( 2, 1) + 
        kernel[20]*err(-2, 2) + kernel[21]*err(-1, 2) + kernel[22]*err( 0, 2) + kernel[23]*err( 1, 2) + kernel[24]*err( 2, 2); 
    vec4 new = ((sum > 0.5))?vec4(cur.x,1.0-sum,1.0,1.0):vec4(cur.x,sum-0.0,0.0,1.0);
    int fx = int(mod(fragCoord.x, 3.0));
    int fy = int(mod(fragCoord.y, 3.0));

    int px = int(mod(float(iFrame), 3.0));
    int py = int(mod(float(iFrame) / 3.0, 3.0));
    fragColor = ((fx == px)&&(fy == py))?new:cur; 
}