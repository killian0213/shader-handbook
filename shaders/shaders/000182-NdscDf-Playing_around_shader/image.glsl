// Image (image) — Playing around shader by MinimilisticBits
// https://www.shadertoy.com/view/NdscDf



//NOT MY CODE//////////////////////
vec3 ACESFilm(vec3 x)
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return clamp((x*(a*x+b))/(x*(c*x+d)+e), 0.,1.);
}
//////////////////////////////////

vec3 blur(vec2 uv, float r){
vec3 c = vec3(0.);
uv *= iResolution.xy;
float iter = 0.;
for(int i = 0; i < 10; i++){
  for(int k = 0; k < 10; k++){
     float x = float(k)-5.;
     float y = float(i)-5.;
     x*=r;
     y*=r;
     //float bok = texture(iChannel1, vec2(0.5)+((vec2(x,y)*6.)/iResolution.xy)).y;
     vec4 c2 = texture(iChannel0, (uv+vec2(x,y))/iResolution.xy).xyzw;
     vec3 col = c2.xyz;
     col = clamp(col,0.,1.);
     //if(length(col) > 0.6)col*=1.2;
     c += col;
     iter+=1.;
  }
}
c/=iter;
return c;
} 


vec3 blur2(vec2 p,float dist){
p*=iResolution.xy;
    vec3 s;
    
    vec3 div = vec3(0.);
    //vec2 off = vec2(0.0, r);
    float k = 0.61803398875;
    for(int i = 0; i < 150; i++){
    float m = float(i)*0.01;
    float r = 2.*3.14159*k*float(i);
    vec2 coords = vec2(m*cos(r), m*sin(r))*dist;
    vec4 c2 = texture(iChannel0, (p+coords)/iResolution.xy).xyzw;
    vec3 c = c2.xyz / (c2.w+1.);
    //c = c*c *1.8;
    vec3 bok = pow(c,vec3(4.));
      s+=c*bok;
      div += bok;
    }
        
    s/=div;
    
    return s;
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    //vec3 col = texture(iChannel0, uv).xyz;
    // Output to screen
    vec3 col = blur2(uv, length((uv*2.0-1.0)*5.));
    float off = texture(iChannel0, uv).w;
     vec3 rad;
    vec2 offset2 = (fragCoord - iResolution.xy/2.)*1.;
    for(int i = 0; i < 20; i++){
       vec2 offset = fragCoord + offset2*smoothstep(0.,15.-length(uv*2.0-1.)*1.5, float(i)/20.)*1.;
       rad.x += texture(iChannel0, (offset+offset2*0.034)/iResolution.xy).x;
       rad.y += texture(iChannel0, (offset)/iResolution.xy).y;
       rad.z += texture(iChannel0, (offset-offset2*0.034)/iResolution.xy).z;

    }
    rad /= 16.;
    
    col += rad*0.8;
    col = clamp(col, 0., 1.);
     col = vec3(1.)-exp(-1.3*col);

    //NOT MY CODE//////////////////
    vec3 a = vec3(0.3,0.3,0.4)-0.4;
    col = mix(col, smoothstep(0.,1.,col),a);
    //////////////////////////////
    // Output to screen
    vec3 aa = vec3(1.0,1.1,1.1);
    col = sqrt(col/aa);
    col = (1.0/((1.0)+exp(-(10.)*(col-0.5))));
col = pow(col, vec3(1.5))*1.8;
//col = pow(col, vec3(0.7,0.8,0.9));
col = ACESFilm(col);
    col = pow(col, vec3(1./2.2));
    
    fragColor = vec4(col,1.0);
}