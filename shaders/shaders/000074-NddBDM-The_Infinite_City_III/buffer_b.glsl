// Buffer B (buffer) — The Infinite City III by fancyzero
// https://www.shadertoy.com/view/NddBDM

//todo: pack 24*4 columns into 1 pixel to reduce sampling
//due to the inconstistency of float<->bits storage on some platform I'm not storing 128 bits per pixel
//and use buffer's upper right corner to store states such as camera pos, random seeds

float sampleField( ivec2 f )
{
    
    return texelFetch(iChannel0, f,0 ).x ;
}



void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

    ivec2 uv = ivec2(fragCoord);
    int width = int(iResolution.x);
    

    if ( uv.x == width-2 && uv.y == 0 )
    {
        fragColor = texelFetch(iChannel1, uv,0);
        if ( fragColor.x != iResolution.x || fragColor.y != iResolution.y || texelFetch(iChannel2,ivec2(32,0),0).x > 0. )
            fragColor.z = float(iFrame);

        fragColor.xy = iResolution.xy;
        return;
    }
    
    if ( uv.x == width-1 && uv.y == 0 )
    {
        vec4 state1 = texelFetch(iChannel1, ivec2(width-2,0),0);//xy: resolution, z:base frame Num.    
        fragColor = texelFetch(iChannel1, ivec2(width-1,0),0);
        int frame = (iFrame-int(state1.z));
        if ( frame % 200 == 0 )
            fragColor.y =  iDate.w*100.+iTime;
        if ( frame % 50 == 0 )
            fragColor.x = hash(uvec3(fragColor.y ), uint(frame) ).x*32768.;

            
        fragColor.z =  hash(uvec3(fragColor.y ), uint(frame) ).y*32768.;
        
        if ( iFrame % 25 == 0 )
            fragColor.w = hash(uvec3(fragColor.y ), uint(frame) ).z*32768.;            

        return;
    }


    ivec2 f = ivec2(fragCoord) *2;
    
    
    float a = sampleField( f );
    float b = sampleField( f+ivec2(1,0) );
    float c = sampleField( f+ivec2(0,1) );
    float d = sampleField( f+ivec2(1,1) );
    
    fragColor = vec4(a,b,c,d);
}

