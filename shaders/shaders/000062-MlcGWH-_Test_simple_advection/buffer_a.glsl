// Buf A (buffer) — [Test] simple advection by Ultraviolet
// https://www.shadertoy.com/view/MlcGWH

/*
   _____                           _             _   _              
  / ____|                         | |           | | (_)            
 | |     ___  _ __   ___ ___ _ __ | |_ _ __ __ _| |_ _  ___  _ __  
 | |    / _ \| '_ \ / __/ _ \ '_ \| __| '__/ _` | __| |/ _ \| '_ \ 
 | |___| (_) | | | | (_|  __/ | | | |_| | | (_| | |_| | (_) | | | |
  \_____\___/|_| |_|\___\___|_| |_|\__|_|  \__,_|\__|_|\___/|_| |_|
                                                                           
                                                                           
*/

#define Dt (1.0)

// number of iteration for implicit solving
#define NITER	100

vec2 screen2world(in vec2 fragCoord)
{
    return (2.0*fragCoord.xy - iResolution.xy)/iResolution.y;
}

vec2 world2screen(in vec2 pos)
{
    return (pos*iResolution.y + iResolution.xy) * 0.5;
}

vec2 screen2uv(in vec2 fragCoord)
{
    return fragCoord / iResolution.xy;
}

vec2 uv2screen(in vec2 uv)
{
    return uv * iResolution.xy;
}

vec2 world2uv(in vec2 pos)
{
    return world2screen(pos) / iResolution.xy;
}

vec2 uv2world(in vec2 uv)
{
    return screen2world(uv2screen(uv));
}

vec2 implicitSolveV(vec2 pos)
{
    vec2 posInit = pos;
    for(int i=0; i<NITER; i++)
    {
        pos = posInit - Dt*texture(iChannel1,  world2uv(pos)).xy;
    }
    
    return pos;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{    
    vec2 pos = screen2world(fragCoord);
    if (iMouse.x < 10.0) 
    {
        if (length(vec2(cos(iTime), 0.7*sin(2.0*iTime))*vec2(1.2,0.6) - pos) < .06) 
        {
            fragColor = vec4(1.,1.,1.,1.);
        	return;
        }
    } 
    else 
    {
        if(iMouse.z > 0.0)
        if (length(screen2world(iMouse.xy)-pos) < .06) 
        {
            fragColor = vec4(1.,1.,1.,1.);
            return;
        }
    }
    
/*    
    vec2 speed = texture(iChannel1, world2uv(pos)).xy;
    //speed = 0.5*(speed + texture(iChannel1, world2uv(pos - speed*Dt)).xy);
    fragColor = vec4(0.99, 0.99, 1.0, 1.0) * texture(iChannel0, world2uv(pos - speed*Dt))*.99;
/*/

    vec2 advPos = implicitSolveV(pos);
    vec4 newVal = texture(iChannel0, world2uv(advPos));
    fragColor = vec4(0.99, 0.99, 1.0, 1.0) * newVal *.99;
    //fragColor = vec4(world2uv(advPos), 0.0, 0.0);
    
//*/
}