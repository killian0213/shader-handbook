// Buf A (buffer) — Voronoi Raymarching by rory618
// https://www.shadertoy.com/view/ltK3DR

vec3 hash33(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = ((fragCoord.xy+hash33(vec3(fragCoord.xy,iFrame)).xy)-iResolution.xy/2.) / iResolution.xx;
    vec3 p = iTime*vec3(.35, .47, .79)+vec3(iMouse.xy/50., .4);
    float l = .0;
    vec3 d = vec3(.36, .48, .80);
    vec3 r = vec3(0.48, -0.36, 0);
    vec3 rd = normalize(r*uv.x+cross(r,d)*uv.y + d*(1.-.6*iMouse.x/ iResolution.x));
    for(int i = 0; i < 40; i++){
        float closest = 1.;
        for(int nx = -1; nx < 1; nx++){
        for(int ny = -1; ny < 1; ny++){
        for(int nz = -1; nz < 1; nz++){
            vec3 np = ceil(p+l*rd) + vec3(nx,ny,nz);
            np += (hash33(np)-.5)*.8*smoothstep(-.5,.5,clamp(sin(.5*iTime),-.5,.5));
            closest = min(closest, length(p+l*rd-np));
            //Cubes:
            //closest = min(closest, dot(abs(p+l*rd-np),vec3(.5)));
        }
        }
        }
        l += .8*closest-(l+1.)/100.;
    }
    l=(l*l+5.)/(l+1.);
	fragColor = .7*texture(iChannel0,fragCoord.xy/iResolution.xy) + .3*vec4(0.5+0.5*sin(l*vec3(.3,.4,.5)),1.0);
}