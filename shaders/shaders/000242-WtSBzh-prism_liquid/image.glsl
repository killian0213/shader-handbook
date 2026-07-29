// Image (image) — prism liquid by louis_C
// https://www.shadertoy.com/view/WtSBzh


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
      vec2 uv = fragCoord/iResolution.xy;
    vec3 col = vec3(0.);
    float b = sqrt(64.);
    float v1 = distance(uv.y,0.5)*0.005+0.0002;
    for(float i = -0.5*b;i<=0.5*b;i++)
    for(float j=-0.5*b;j<=0.5*b;j++)
    {
    col += texture(iChannel0,uv+vec2(i,j)*v1).xyz;
    }
    col/=64.;
    float m = (1.-distance(uv.x,0.5))*(1.-distance(uv.y,0.5));
    fragColor = vec4(pow(col,vec3(mix(2.,1.,m))),1.);
}