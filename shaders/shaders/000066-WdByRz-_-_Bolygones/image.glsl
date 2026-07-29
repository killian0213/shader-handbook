// Image (image) — 大龙猫 - Bolygones by totetmatt
// https://www.shadertoy.com/view/WdByRz

//      v---- Day 22 for me :D
#define CHAT 0.0
#define PI 3.141592
#define TAU PI*2.
 
vec2 circleCoord(float r, float theta) {
    return  vec2(r*cos(theta),r*sin(theta));
}
mat2 r(float a){
    float c=cos(a),s=sin(a);
    return mat2(c,-s,s,c);
}
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}
float hash21(vec2 p) {
    p = fract(p * vec2(233.34, 851.74));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = (fragCoord.xy-.5*iResolution.xy)/ iResolution.y;
    uv*=4.;
    float steps = 200.;
    float d  = .0;

     vec2 id = floor(uv);
     uv = fract(uv)-.5;
     uv *=2.2;

float n = 20.+sin(iTime*.01+hash21(id))*10.;
    for(float i =0.;i<TAU;i+=TAU/steps) {
   
        vec2 coord = uv +circleCoord(1.,i);
        
        float s = 8./iResolution.y;
        d += smoothstep(s,s-0.01,sdSegment(coord,vec2(.0,.0),2.*vec2(cos(n*i),sin(n*i))))/3.;
       
    }
    
 
    vec3 col = vec3(d)*1.-step(1.,length(uv));
    col = mix(vec3(0.0,.0,.0),vec3(hash21(id+iTime*.0000001),0.5,0.5),col);
    fragColor = vec4(col,1.0);
}