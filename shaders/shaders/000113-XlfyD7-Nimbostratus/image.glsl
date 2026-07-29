// Image (image) — Nimbostratus by Xor
// https://www.shadertoy.com/view/XlfyD7

float Speed = .03;
vec3 Light = vec3(.6,.2,.8);
    
float Map(vec3 Position)
{
    vec3 P = (Position*0.5+texture(iChannel0,Position*2.+iTime*Speed*.2).xyz*.02);
    
    float C = texture(iChannel0,P).r;
    C *= texture(iChannel0,P*vec3(.5,1,.5)).g;
    C = C*.9+.1*pow(texture(iChannel0,P*5.1).a,2.);
    return max((C-.3)*sqrt((Position.z-.1)/.3),0.)/.5;
}
void mainImage(out vec4 Color,in vec2 Coord)
{
    vec3 R = vec3((Coord-.5*iResolution.xy)/iResolution.y,1);
    vec3 P = vec3(0,iTime*Speed,0);
    
    vec4 C = vec4(0);
    for(float I = .2;I<.5;I+=.01)
    {
        float M1 = Map(P+R*I);
        float M2 = Map(P+R*I+Light*.01);
        C += vec4((.6+vec3(.6,.5,.4)*(exp(-M2*10.)-M1)),1)*M1*(1.-C.a);
        if (C.a>.99) break;
    }
	Color = C+vec4(vec3(.5,.7,.9)-R.y*.4,1)*(1.-C.a);
}