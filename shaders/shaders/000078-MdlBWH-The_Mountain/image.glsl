// Image (image) — The Mountain by banthar
// https://www.shadertoy.com/view/MdlBWH

const float tau = 6.28318530718;

mat4 perspective(float r, float t, float f, float n) {
    return mat4(
		  r,  0,      0,       0,
		  0,  t,      0,       0,
		  0,  0,(f+n)/(n-f),   -1,
		  0,  0,(f*n)/(n-f), 0
        );
}

mat4 rotateX(float a) {
    return mat4(
        1,0,0,0,
		0,cos(a),-sin(a),0,
		0,sin(a),cos(a),0,
		0,0,0,1);
}


mat4 rotateY(float a) {
    return mat4(
		cos(a),0,sin(a),0,
		0,1,0,0,
		-sin(a),0,cos(a),0,
		0,0,0,1
    );
}

mat4 rotateZ(float a) {
    return mat4(
		cos(a),-sin(a),0,0,
		sin(a),cos(a),0,0,
		0,0,1,0,
		0,0,0,1
    );
}

mat4 translate(vec3 v) {
	return mat4(
		1,0,0,0,
		0,1,0,0,
		0,0,1,0,
		v.xyz,1
    );
}

vec4 gridI(vec4 b) {
    float p = 0.1;
    return floor(b)*p + max(fract(b)-1.0+p, 0.0);
}

float crtI(float x) {
    return 0.5 * x - 0.5*cos(x*2.0);
}

vec4 grid(vec4 b) {
    vec4 fw = fwidth(b)*2.0;
    vec4 p = (gridI(b+fw) - gridI(b))/fw;
    float line = max(p.x,p.y);

    fw*=4.0;
    vec4 q = (gridI(b+fw) - gridI(b))/fw;
    float shadow = max(q.x,q.y);

    
    float f = b.y * 32.0;
    float df = fwidth(f)*10.0;
    float crt = (crtI(f+df)-crtI(f)) / df / sqrt(b.z)*.25+.1;
    
    vec4 color = vec4(0.0,0.0,0.0,1.0);
    
    color = max(color, vec4(.9,.3,.4,1.0)*line);
    color = max(color, vec4(.4,.3,.9,1.0)*shadow);
    color = max(color, vec4(.5,.0,1.0,1.0)*crt);
    
    return color;
}

vec4 star_plane(vec2 uv) {
    uv = uv.xy + uv.yx*vec2(1,-1);
    vec2 res = vec2(iChannelResolution[1]);
    vec2 pos = uv*res;
    vec2 cell_center = floor(pos)+.5;
    vec4 q = textureLod(iChannel1, cell_center/res, 0.0);
    q*=q;
    float blue = q.x;
    float f = 0.25;
    return vec4(1.0-blue*f,1.0-blue*f,1.0-f*(1.0-blue),1)*clamp(q.t *8.0 * (0.25*q.z-distance(pos - cell_center, (q.xy-.5)*.5/q.z)),0.0,1.0);
}


vec4 star_dust_plane(vec2 uv) {
    vec2 res = vec2(iChannelResolution[1]);
    float q = texture(iChannel1, uv*0.5).r*0.25 + texture(iChannel1, uv*0.25).r*0.75;
    float n = mix(1.0, texture(iChannel1, uv*32.0).r, 0.5);
    return vec4(0.1,0.1,0.2,1)*q*n;
    return vec4(0.1,0.1,0.2,1) * n * smoothstep(0.25,0.75,q);
}

vec4 stars(vec3 eye) {
    eye /= max(abs(eye.x),max(abs(eye.y),abs(eye.z)));
    vec3 eye_m = abs(eye);
    vec2 pq;
    if(eye_m.x > eye_m.y && eye_m.x > eye_m.z) {
        pq = eye.yz;
    } else if(eye_m.z > eye_m.x && eye_m.z > eye_m.y) {
        pq = eye.xy;
    } else if(eye_m.y > eye_m.x && eye_m.y > eye_m.z) {
        pq = eye.zx;
    }
    vec2 st = fract(pq*16.0);
    vec4 fragColor = star_plane(pq*0.2);
	fragColor += star_plane(pq*0.1);
	return fragColor;    
}


vec4 sun(vec2 uv) {
    float h = min(uv.y-0.1,0.)+0.8;
    float r = max(length(uv),min(.51,(1.0+sin(max(h*h*64.0,0.)))*.5));
    vec4 a = vec4(1.0,0.2,0.4,1.0);
    vec4 b = vec4(1.0,0.9,0.3,1.0);
    float c = uv.y+0.5-uv.x*.25;
    c += length(uv)*length(uv)*.5;
    float n = 0.0;
    n = (texture(iChannel1, uv*.5).r);
    n += (texture(iChannel1, uv*.2).r)*2.0;
    n += (texture(iChannel1, uv*.05).r)*4.0;
    n += (texture(iChannel1, uv*.02).r)*7.0;
    c += ((n/14.0)-.5)*.25;
    vec4 sun = mix(a,b,c);
    vec4 sky = vec4(1.0,0.2,0.4,clamp(0.5-(r-.5)*1.0,0.0,1.0));
    
    float a0 = sin(max(h*h*64.0,0.))*0.005/fwidth(uv.y);
    float a1 = length(uv);
    float f = smoothstep(0.5,0.5 + length(fwidth(uv)), a1);
    return mix(sun, sky, max(min(1.0,a0),f));
}


const float F = (sqrt(3.0)-1.0)/2.0;


float height(vec2 uv) {
    return textureLod(iChannel1, uv/100.0, 0.).r -0.1;
}

float elev_s(vec2 uv) {
    float f = cos((uv.x+uv.y)*0.2);
    f=0.2+f*f*0.7;
	return max(0.15, f* (5.0 - abs(20.0 - length(uv)) + height(uv/4.0)*4.0));
}

float elev(vec2 uv) {
    return elev_s(uv-uv.yx * (1.0-2.0*F));
}

vec4 mountain2(vec3 pos, vec3 normal) {
    pos.xy += normal.xy * 0.0;
    float F = (sqrt(3.0)-1.0)/2.0;
	pos.xy += (pos.x + pos .y) * F;
	normal.xy += (normal.x + normal.y) * F;
    
    vec3 s = sign(normal.xyz);
	vec3 sn = (s + 1.0 ) /2.0;
    vec2 ipos = floor(pos.xy);
    vec3 fpos = pos - vec3(ipos,0.0);

    float e0 = 0.0;
    vec3 pos0 = vec3(0.0, 0.0, 0.0);
    
    const int d = 50;
    float f0 = 0.0;
    for(int i=0;i<d;i++) {
        float e1;
        
        vec2 old_ipos = ipos;
        
        vec3 a = ((s+1.)/2. - s*fpos)/normal*s;
        if(a.x >= a.y) {
            if(fpos.x * s.y <= fpos.y * s.y) {
            	fpos += normal * a.y;
            	fpos.y = -(s.y - 1.)/2.;
            	ipos.y += s.y;
                e1 = mix(elev(ipos.xy + vec2(0,1.0-sn.y)), elev(ipos.xy+ vec2(1,1.0-sn.y)), fpos.x);
            } else {
                fpos += (fpos.x-fpos.y)/(normal.y-normal.x) * normal;
                fpos.y = fpos.x;
                e1 = mix(elev(ipos.xy + vec2(0,0)), elev(ipos.xy+ vec2(1,1)), fpos.x);
            }
        } else {
            if(fpos.x *s.x >= fpos.y * s.x) {
            	fpos += normal * a.x;
            	fpos.x = -(s.x - 1.)/2.;
            	ipos.x += s.x;
                e1 = mix(elev(ipos.xy + vec2(1.0-sn.x,0)), elev(ipos.xy+ vec2(1.0-sn.x,1)), fpos.y);
            } else {
                fpos += (fpos.x-fpos.y)/(normal.y-normal.x) * normal;
                fpos.y = fpos.x;
                e1 = mix(elev(ipos.xy + vec2(0,0)), elev(ipos.xy+ vec2(1,1)), fpos.x);
            }
        }

        vec3 pos1 = fpos + vec3(ipos,0);
        f0 = max(f0, (0.05 - distance(e1, fpos.z))*20.0);
        if(e1 >= fpos.z) {
            float t = (e0 - pos0.z) / (pos1.z - pos0.z - e1 + e0);
            vec3 fpost = pos0 + t * (pos1 - pos0);
            vec2 uv = fract(fpost.xy);
            vec2 fv = abs(uv-0.5) * 2.0;
            float f = max(max(fv.x, fv.y), 1.0-2.0*abs(uv.x-uv.y));
            
            float tq = 0.9;
            
            float p = smoothstep(tq, tq*1.1, f) + 0.05 * smoothstep(0.5, 1.0, f);
            p = max(p,f0);
            float q = 0.6 * max(0.0,elev(floor(fpost.xy) + vec2(0,0)) - elev(floor(fpost.xy)+ vec2(1,0)));
            
            return vec4(max(mix(vec3(1,1,1), vec3(0.05,0.7,0.93), 1.0-0.1*fpost.z)*p, vec3(0.15,0.3,0.5)*q),1);
        }
		e0 = e1;
        pos0 = pos1;
        
    }
    return vec4(0.05,0.7,0.93,f0);
}

const float speed = 1.0;

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec3 pos = texture(iChannel2, vec2(0.5,0.5)/iChannelResolution[2].xy).xyz;
    vec3 rot = texture(iChannel2, vec2(1.5,0)/iChannelResolution[2].xy).xyz;
    float yaw = rot.x;
    float pitch = -rot.y;
    float l = 319.0;
    float t = fract(iTime/319.0*speed);
    vec4 eye = vec4(0,t*400.0,1,0);
	vec4 screen = vec4((fragCoord.xy * 2.0 - iResolution.xy) / min(iResolution.x,iResolution.y), 2.0, 1.0);
    vec4 eyeV = normalize(rotateZ(yaw)*rotateX(pitch)*screen);
    vec4 floorHit = vec4((eye+eyeV*eye.z/eyeV.z).xy, eye.z/eyeV.z, 1.0);
    vec4 horizon = vec4(0,1,0,0);
    if(floorHit.z>0.0) {
   		fragColor = grid(floorHit);
    } else {
        vec4 skyV = rotateX(t-0.4)*rotateZ(-t*0.1)*eyeV;
	    vec4 skyHit = vec4((horizon+skyV*horizon.y/skyV.y).xz, horizon.y/skyV.y, 1.0);
        vec4 air = mix(vec4(0.2,0.5,1.0,1.0)*(1.0-t),vec4(1.0-t,0.2,1.0-0.5*t,1),skyV.y);
        fragColor = max(air*(1.0-t), t*stars(skyV.xyz));
        if(skyV.y > 0.01) {
        	vec4 sunColor = sun(skyHit.xy*-1.0+0.0*vec2(0,mix(-0.6,0.5,t)));
        	fragColor = mix(fragColor, sunColor, sunColor.a);
        }
        eyeV.xy *= -1.0;
        vec4 mountainColor = mountain2(eye.xyz*vec3(0.01,0.01,0.12) - eyeV.xyz*5.0, -eyeV.xyz);
        fragColor = mix(fragColor, mountainColor, mountainColor.a);
    }
}