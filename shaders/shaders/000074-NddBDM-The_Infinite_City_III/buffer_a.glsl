// Buffer A (buffer) — The Infinite City III by fancyzero
// https://www.shadertoy.com/view/NddBDM


mat2 makerot(float r)
{
    mat2 rotmat = mat2(vec2(cos(r),sin(r)), vec2(-sin(r), cos(r)));
    return rotmat;
}


float hex(in vec2 p){
    const float hexSize = .5;
    const vec2 s = vec2(1, 1.7320508);
    
    p = abs(p);
    return max(dot(p, s*.5), p.x) - hexSize;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
    //setup random parameters
    
    fragColor = texture(iChannel0,fragCoord/iResolution.xy);
    int width = int(iResolution.x);
    vec4 randomData = texelFetch(iChannel1, ivec2(width-1,0),0);
    vec4 state1 = texelFetch(iChannel1, ivec2(width-2,0),0);//xy: resolution, z:base frame Num.
    ivec2 index = ivec2(fragCoord);

        
    int baseRndSeed = int(randomData.x);
    float windowSize = iResolution.y/10.;
    
    int symetrical = int(randomData.y) % 4;
    if (symetrical != 0 )
        baseRndSeed += int((fragCoord.x-iResolution.x/2.)/windowSize)+int((fragCoord.y-iResolution.y/2.)/windowSize)*10;
    
    int kernelShape = 0;

    vec3 hh = hash(uvec3(baseRndSeed),11u);
    int frameDivid=int(hh.x*6.)+3;   
    int frameMod=int(hh.x*20.)+3;

    int ppFrameDivid=randomRange(11,22,56,iFrame,0.);
    int ppFrameMod=randomRange(4,7,56,iFrame,0.);

    kernelShape=int (hash(uvec3(iFrame+77),99u).x*100.)%20;
    
    int frame = (iFrame-int(state1.z)) % 200 ;
    

    

    
    // initial frame
    // and clear buffer if resolution change detedted
    if ( frame <= 2 )
    {
        vec2 diff = abs(fragCoord - iResolution.xy/2.);
        float f = max(diff.x, diff.y);
        f = step(f,mod(randomData.y,8.)+2.);
        vec3 hashValue = hash(uvec3(randomData.x, 0,0.),384u);
        f= max(f,step(hash(uvec3(fragCoord.xy, randomData.x*18473.),77u).x,
        hashValue.x*hashValue.x*hashValue.x*hashValue.x*0.00002));
        fragColor = vec4(f, iTime,frame, 1.);  
    }
    else
    {
        ivec2 foffset = ivec2(0,0);
        

        int range = randomRange2(4,16,222,baseRndSeed,0.);

        fragColor = texelFetch( iChannel0, ivec2(fragCoord.xy)+foffset,0);
        if (frame > 100 )
            return;
        
        if ( range < 6 && frame > 20 )
            range = 6;
            

        //counting using a kernel
        int total = 0;
        ivec2 vc = ivec2(fragCoord);

         
        for (int i = -range; i <= range; i++ )
        {
            for (int j = -range; j <= range; j++ )        
            {
                if ( i*i + j*j > range*range && kernelShape ==0)
                    continue;
                    
                if ( abs(i)> abs(j)  && kernelShape <=2 && kernelShape > 0)
                    continue;   
                    
                ivec2 tvc = (vc/2+ivec2(i,j));

                
                vec4 data = texelFetch( iChannel1, tvc+foffset,0);
                vec4 mask =vec4(1);
                int ix = (vc.x)%2;
                int iy = (vc.y)%2;
                
                if ( ix == 0 )
                {
                    if ( i == range )
                        mask *= vec4(0);
                    if ( i == -range )
                        mask *= vec4(0,1,0,1);                         
                }
                else
                {
                    if ( i == -range )
                        mask *= vec4(0);
                    if ( i == range )
                        mask *= vec4(1,0,1,0);                                
                }  
                    
                if (iy == 0 )
                {
                    if ( j == range )
                        mask *= vec4(0);
                    if ( j == -range )
                        mask *= vec4(0,0,1,1);
                }
                else
                {
                    if ( j == -range )
                        mask *= vec4(0);
                    if ( j == range )
                        mask *= vec4(1,1,0,0);                    
                }  
                
                
                total +=int(dot(mask, data));
            }
        }        
                
        
        
        int pp = range;
        int m = pp/(frame/ppFrameDivid+1)%ppFrameMod;
        if (m < 8)
            m = 8;
            
        // where the magic happens
        if ( fragColor.x <= 0.5 && (total <= m) && (total >0) && ((total % pp) < m))
            fragColor = vec4(1,iTime,frame,1);
        
    }
}