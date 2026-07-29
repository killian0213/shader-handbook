// Buffer C (buffer) — Pixie dust by rory618
// https://www.shadertoy.com/view/wllcR7

#define pi 3.1415
vec3 sbf(vec3 c, vec3 w, float s){
    //float x = sin(pi*c.x*w.x) * cos(pi*c.y*w.y) * cos(pi*c.z*w.z);
    //float y = sin(pi*c.y*w.y) * cos(pi*c.z*w.z) * cos(pi*c.x*w.x);
    //float z = sin(pi*c.z*w.z) * cos(pi*c.x*w.x) * cos(pi*c.y*w.y);
    vec3 k = sin(pi*c*w) * cos(pi*c.yzx*w.yzx) * cos(pi*c.zxy*w.zxy);
    k = mix(k, k* cross(normalize(w), normalize(vec3(2,4,1))), s);
    return k;
}

void mainImage( out vec4 O, in vec2 I )
{
    if(iFrame<3){
       int seed = int(I.x) + 2000*int(I.y);
        seed = IHash(seed);
        vec3 coord = rand3(seed);
        coord = mix(coord,normalize(coord-.5)/2.5+.5,.9);
        O.xyz = coord;
        O.w = dot(sin(6.*coord*vec3(4,5,6)),vec3(1));
    } else{
        O = texture(iChannel0, I/R.xy);
        O.xyz += 10.*sbf(O.xyz,vec3(3,3 ,3) ,.9 + .1*abs(sin(iTime/4.)))/1300.  *(2.+cos(iTime*.4));
        O.xyz += 10.*sbf(O.xyz,vec3(1,23,1), .9 + .1*abs(sin(iTime/4.)))/1445. *(2.+sin(iTime*.5));
        O.xyz += 10.*sbf(O.xyz,vec3(3,12,5), .9 + .1*abs(sin(iTime/4.)))/753.*(2.+sin(iTime*.65));
        O.xyz += 10.*sbf(O.xyz,vec3(4,7 ,1) ,.9 + .1*abs(sin(iTime/4.)))/1725.  *(2.+cos(iTime*.67));
        O.xyz -= 10.*sbf(O.xyz,vec3(5,6 ,3) ,.9 + .1*abs(sin(iTime/4.)))/2034. *(2.+cos(iTime*.87));
        O.xyz -= 10.*sbf(O.xyz,vec3(1,4 ,4) ,.9 + .1*abs(sin(iTime/4.)))/3646. *(2.+sin(iTime*.9));
        O.xyz += 10.*sbf(O.xyz,vec3(1,9 ,3) ,.9 + .1*abs(sin(iTime/4.)))/2420. *(2.+cos(iTime*.3));
        O.xyz = clamp(O.xyz,vec3(0), vec3(1));
        O.xyz = mix(O.xyz, vec3(.5), .002);
    }
}