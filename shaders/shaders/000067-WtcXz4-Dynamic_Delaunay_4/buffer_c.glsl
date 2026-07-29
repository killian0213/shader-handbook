// Buffer C (buffer) — Dynamic Delaunay 4 by rory618
// https://www.shadertoy.com/view/WtcXz4

vec4 B(int i){
    return texture(iChannel1, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

bool keyIsDown( float key ) {
    return texture( iChannel3, vec2(key,0.75) ).x > .5;
}

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

void vline(inout float d, vec2 a, vec2 b, vec2 I){
    vec2 Ip = I-a;
    vec2 bp = b-a;
    bp = mod(bp + R.xy/2.,R.xy)-R.xy/2.;
    Ip = mod(Ip + R.xy/2.,R.xy)-R.xy/2.;
    
    vec2 mp = bp/2.;
    vec2 norm = normalize(bp);
    float dist = abs(dot(norm,Ip-mp));
    d = min(d,dist);
}


void mainImage( out vec4 O, in vec2 I )
{
    O = vec4(0);
    vec4 t2 = texture(iChannel3, I/R.xy);
    t2 = B(cvt(t2.x));
    vec4 t = texture(iChannel1, I/R.xy);
    vec4 t0 = texture(iChannel2, I/R.xy);
    vec4 a = A(cvt(t.x));
    vec4 b = A(cvt(t.y));
    vec4 c = A(cvt(t.z));
    vec4 d = A(cvt(t.w));
    
    vec4 tri = B(cvt(t0.x));
    
    vec4 a0 = A(cvt(tri.x));
    vec4 b0 = A(cvt(tri.y));
    vec4 c0 = A(cvt(tri.z));
    vec4 d0 = A(cvt(tri.w));
    
    float z = 1e7;
    
    
    float cd0 = abs(sdTriangle(I,a0.xy, b0.xy, c0.xy,R.xy));
    z = max(0., cd0);
    
    
    
    //vline(z,a.xy,b.xy,I);
    //vline(z,b.xy,c.xy,I);
    //vline(z,c.xy,d.xy,I);
    
    /*vec4 tt = t0;
    O.x = min(tt.x,min(tt.y,tt.z));
    if(floor(tt.x+.5)==floor(O.x+.5)) O.yz = vec2(min(tt.y,tt.z), max(tt.y,tt.z));
    if(floor(tt.y+.5)==floor(O.x+.5)) O.yz = vec2(min(tt.z,tt.x), max(tt.z,tt.x));
    if(floor(tt.z+.5)==floor(O.x+.5)) O.yz = vec2(min(tt.x,tt.y), max(tt.x,tt.y));
    O /= R.x*R.y/30.;*/
    // tri = B(cvt(t0.z));
    
    //O.x = min(tri.x,min(tri.y,tri.z));
    if(floor(tri.x+.5)==floor(O.x+.5)) O.yz = vec2(min(tri.y,tri.z), max(tri.y,tri.z));
    if(floor(tri.y+.5)==floor(O.x+.5)) O.yz = vec2(min(tri.z,tri.x), max(tri.z,tri.x));
    if(floor(tri.z+.5)==floor(O.x+.5)) O.yz = vec2(min(tri.x,tri.y), max(tri.x,tri.y));
    O/= R.x*R.y/300.;
    
    
    O = max(O,vec4(z));
    O = min(vec4(1),O);
    
    

    vec2 v0 = b0.xy - a0.xy, v1 = c0.xy - a0.xy, v2 = I.xy - a0.xy;
    float d00 = dot(v0, v0);
    float d01 = dot(v0, v1);
    float d11 = dot(v1, v1);
    float d20 = dot(v2, v0);
    float d21 = dot(v2, v1);
    float invDenom = 1.0 / (d00 * d11 - d01 * d01);
    float v = (d11 * d20 - d01 * d21) * invDenom;
    float w = (d00 * d21 - d01 * d20) * invDenom;
    float u = 1.0f - v - w;
    
    vec2 coord = (I-(a0.zw * v + b0.zw * w + c0.zw * u)/4. );
    O.x = mix(O.x, texture(iChannel3,coord/R.xy).x,.9);
    O.yz =(texture(iChannel3,coord/R.xy).xy +
          texture(iChannel3,(coord + vec2(1,0))/R.xy).yz +
          texture(iChannel3,(coord + vec2(0,1))/R.xy).yz +
          texture(iChannel3,(coord - vec2(1,0))/R.xy).yz +
          texture(iChannel3,(coord - vec2(0,1))/R.xy).yz)/5.;
    

}