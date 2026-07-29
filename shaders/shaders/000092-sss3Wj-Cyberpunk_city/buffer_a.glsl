// Buffer A (buffer) — Cyberpunk city by z0rg
// https://www.shadertoy.com/view/sss3Wj

// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define UPSIDEDOWN // Comment to see not only the dow side

#define FFT(f) (texture(iChannel1, vec2(f, 0.)).x)


float _speed = 20.;
float _time;
float _cube(vec3 p, vec3 s)
{
    vec3 l = abs(p)-s;
    return max(l.x, max(l.y, l.z));
}

vec2 _min(vec2 a, vec2 b)
{
    if (a.x < b.x)
        return a;
    return b;
}

vec2 _max(vec2 a, vec2 b)
{
    if (a.x > b.x)
        return a;
    return b;
}

float _cars(vec3 op, vec3 s)
{
    op.z+=_time*20.;
    float carStp = 10.5;
    vec3 pcar = op;
    float idxCar = floor((pcar.z+.5*carStp)/carStp);
    pcar.z = mod(pcar.z+.5*carStp, carStp)-.5*carStp;
    pcar.x += sin(idxCar);
#ifndef UPSIDEDOWN
    pcar.y += 90.;
#endif
    pcar.y += sin(idxCar*5.+_time);
    return _cube(pcar, s*(sin(idxCar)*.5+.5));
}

vec2 map(vec3 p)
{

    p.z += _time*_speed;
    vec3 op = p;
    
#ifdef UPSIDEDOWN
    p.y = abs(p.y)-100.;
#endif
    vec2 acc = vec2(100., -1.);
    vec2 ground = vec2(_cube(p, vec3(50., .1, 50.)), 0.);
    vec3 pBat = p;
    vec2 repBat = vec2(10.);
    vec2 idxBat = floor((pBat.xz+repBat*.5)/ repBat); 
    pBat.xz = mod(pBat.xz+repBat*.5, repBat)-repBat*.5;
    float height = mix(1., 8., (sin(idxBat.x+idxBat.y*10.)*.5+.5));
    height += (texture(iChannel0, idxBat*.1).x-.5)*5.;
    float width = texture(iChannel0, idxBat/10.).x*.75;
    pBat.xz += sin(idxBat*10.)*.5;
    vec2 bat = vec2(_cube(pBat, vec3(5.5*width,height*8.,3.7)), 0.);
    
    acc = _min(acc, ground);
    acc = _min(acc, bat);
    acc = _min(acc, vec2(_cars(op-vec3(0.,10.,0.), vec3(.5,.5,1.5)), 1.));
    acc = _min(acc, vec2(_cars(op-vec3(50.,10.,0.), vec3(.5,.5,1.5)), 1.));
    
    float repz = 50.;
    float idxz = op.z / repz;
    op.z = mod(op.z+.5*repz, repz)-repz*.5;
    op.xz *= r2d(1.57);
    op.y += sin(idxz)*25.;
    acc = _min(acc, vec2(_cars(op, vec3(.5,.5,2.5)), 1.));
    return acc;
}

vec3 trace(vec3 ro, vec3 rd, float dist, int steps)
{
    vec3 p = ro;
    for (int i = 0; i < steps && ((dist > 0.0 && distance(ro, p) < dist) || dist < 0.0); ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
        {
            return vec3(res.x, distance(ro, p), res.y);
        }
        // We allow march step to be false if far enough from origin
        p += rd * min(res.x,.5+(distance(ro, p)/120.));
    }
    return vec3(-1.);
}

float traceShadow(vec3 ro, vec3 rd, float dist, int steps)
{
    float rad = 1.5;
    vec3 p = ro;
    float acc = 1.;//rad;//rad*50.;
    for (int i = 0; i < steps && distance(p, ro) < dist; ++i)
    {
        vec2 res = map(p);
        if (res.x < 0.01)
        {
            return 0.;
        }
        float d =min(res.x,1.5);
        acc = min(acc, 30.*d/distance(p, ro));
        p += rd * d;
         // check this https://www.shadertoy.com/view/3tVBRV
        //acc += sat(d/rad*dist*.005);
    }
    return acc;
}
vec3 getCam(vec3 rd, vec2 uv)
{
    vec3 r = normalize(cross(rd, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(rd, r));
    float fov = 4.;
    return normalize(rd+(uv.x*r+uv.y*u)*fov);
}

vec3 getNormal(float d, vec3 p)
{
    vec2 e = vec2(0.04, 0.);
    //return -normalize(cross(dFdx(p), dFdy(p)));
    return normalize(vec3(d)-vec3(map(p-e.xyy).x, map(p-e.yxy).x, map(p-e.yyx).x));
}



vec3 rdr(vec2 uv)
{
    vec3 col = vec3(0.);
#ifdef UPSIDEDOWN
    vec3 ro = vec3(sin(_time*.3)*15.,15.+sin(_time*.15)*15.,-75.)*.75;
    vec3 ta = vec3(0.,-10.,0.)*.5;
#else
    vec3 ro = vec3(sin(_time*.3)*15.,-105.+sin(_time*.15)*15.,-75.)*.75;
    vec3 ta = vec3(0.,-110.,0.)*.5;
#endif

    vec3 rd = normalize(ta-ro);
    rd = getCam(rd, uv);
    
    vec3 res = trace(ro, rd, -1., 256);
    if (res.y > 0.)
    {
        vec3 p = ro+rd*res.y;
        vec3 n = getNormal(res.x, p);
        
        
        col = n*.5+.5;
        float rad = 50.;
        float tsun = iMouse.x/100.;//_time*.25;
        float lDist = 550.;
        //vec3 lpos = vec3(cos(tsun)*lDist, lDist,sin(tsun)*lDist);
        vec3 shadowO = p+n*0.01;
        vec3 ldir = vec3(1.,-2.,5.)*lDist;//lpos-shadowO;
        vec3 lCol = vec3(1.,0.,0.);
        
        
        float shadowRes = traceShadow(shadowO, normalize(ldir), lDist, int(650.*(1.-sat((length(p.xz)-150.)*.01))));
        vec3 ambientCol = vec3(0.569,0.675,0.714);
        vec3 diffuseCol = vec3(0.678,0.878,0.902);
        col = ambientCol; // Ambient col
        
        col *= sat(pow(sat(shadowRes),.5)+.15);
        if (shadowRes > 0.01)
        {
            
            vec3 h = normalize(ldir+rd);
            // diffuse
            col += 500.*sat(dot(n, normalize(ldir)))*diffuseCol/lDist;
            float specPower = mix(1.,.01, sat(sin(p.y*2.)*50.));
            // spec
            col += (.025/specPower)*100.*vec3(1.000,0.584,0.000)*pow(sat(abs(dot(n, h))),specPower)/lDist;
        }

        col += mix(vec3(0.), mix(vec3(1.000,0.000,0.400), vec3(1.), sat(abs(length(p.xz)*.0025))), 1.-sat(exp(-distance(p, ro)/500.)));
        p.z += _time*_speed;


       col += float(dot(n, vec3(0.,-1.,0.)) < 0.1)*vec3(0.851,0.690,0.506)*pow(texture(iChannel2, p*.02).x,20.)*2.;
       col += .3*vec3(0.729,0.565,0.212)*(sat(p.y*.1+5.))*pow(texture(iChannel2, vec3(1.,4.,1.)*p*.02+vec3(.5*_time*sign(sin(p.z*5.)), 0., 0.)).x,20.);

    }
    else
        col = sat(mix(mix(vec3(.75), vec3(1.000,0.000,0.400)*.75, .1),texture(iChannel3, vec2(-rd.x, rd.y)*vec2(2.,-8.)-vec2(0.,.7)).xyz,(sat((rd.y-.175)*40.))*.5*sat(length(uv*2.))));//*sat(-rd.y*2.+1.);

    col += (1.-sat(lenny(rd.xy*vec2(1.,4.)*.5)))*vec3(1.000,0.000,0.400)*.5*float(res.y<0.);
    col += 3.*pow(1.-sat(lenny(rd.xy*.15*vec2(1.,8.))),5.)*vec3(1.000,0.000,0.400)*.5;//*float(res.y<0.);
    col *= mix(.75,1.5,pow(sat(FFT(0.5)),2.));
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // This helps a bit decreasing aliasing by doing a no sampling motion blur
    _time =  iTime + texture(iChannel0, fragCoord/8.).x*.25;

    vec2 uv = (fragCoord-vec2(.5)*iResolution.xy)/iResolution.xx;
    vec3 col = rdr(uv);

    
    col = pow(col, vec3(.85));
    col *= (1.-sat(lenny(uv*2.)-.5));
    
    col = mix(col, texture(iChannel3, fragCoord/iResolution.xy).xyz, sat(.9)*sat(length(uv*2.)));

    fragColor = vec4(col,1.0);
}