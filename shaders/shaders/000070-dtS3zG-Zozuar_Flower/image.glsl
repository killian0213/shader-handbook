// Image (image) — Zozuar Flower by mla
// https://www.shadertoy.com/view/dtS3zG

// Zozuar Flower, mla, 2023. Original by @zozuar/@yonatan.
// Degolfed version of https://twitter.com/zozuar/status/1612919479582728232

/*
for(float i,g,e,R,S;i++<1e2;o.rgb+=hsv(.4-.02/R,
(e=max(e*R*1e4,.7)),.03/exp(e))){S=1.;vec3 p=vec3
((FC.xy/r-.5)*g,g-.3)-i/2e5;p.yz*=rotate2D(.3);
for(p=vec3(log(R=length(p))-t,e=asin(-p.z/R)-.1/
R,atan(p.x,p.y)*3.);S<1e2;S+=S)e+=pow(abs(dot(sin
(p.yxz*S),cos(p*S))),.2)/S;g+=e*R*.1;}
*/

void mainImage(out vec4 fragColor, vec2 fragCoord) {
  float time = iTime;
  fragColor = vec4(0);
  vec2 uv = 0.5*(2.0*fragCoord-iResolution.xy)/iResolution.y;
  vec3 ro = vec3(0,0,-0.6);
  vec3 rd = vec3(uv,1);
  float t = 0.0;
  vec2 m = 2.0*(iMouse.xy/iResolution.xy - 0.5); 
  for (float i = 0.0; i < 1e2; i++) {
    vec3 p = ro+t*rd-i/2e5;
    if (iMouse.x > 0.0) {
      p.z -= 1.0; // Rotation centre
      p.yz *= rotate2D(PI*m.y);
      p.xz *= rotate2D(PI*m.x);
      p.z += 1.0;
    }
    p.yz *= rotate2D(0.2);

    float r = length(p);
    float e = asin(-p.z/r)-0.1/r;  // DE
    float rot = 3.0; // rotational symmetry
    vec3 q = vec3(log(r)-time,e,rot*atan(p.x,p.y)); // log spherical?
    for (float scale = 1.0; scale<1e2; scale += scale) {
      e += pow(abs(dot(sin(q.yxz*scale),cos(q*scale))),0.2)/scale; // FBM?
    }
    t += e*r*0.1; // Attenuate DE
    if (t > 50.0) break;
    float k = max(e*r*1e4,0.7);
    k = pow(k,0.4);
    fragColor.rgb += hsv(0.4-.02/r,k,0.02/exp(k));
  }
  fragColor *= 2.0/(1.0+fragColor);
  fragColor = pow(fragColor,vec4(0.4545));
}