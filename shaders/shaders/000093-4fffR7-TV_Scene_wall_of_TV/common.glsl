// Common (common) — TV Scene, wall of TV by morimea
// https://www.shadertoy.com/view/4fffR7


#define MAX_DIST 1000.
#define MIN_DIST .001

#define OBJ_SKY 0
#define OBJ_FLOOR 1
#define OBJ_BOX 2

#define cam_cyli

const float camera_fov = 70.;


struct HitInfo {
    float t;
    vec3 norm;
    vec4 color;
    int obj_type;
};

bool boxAABB(in vec3 dims, vec3 ro, vec3 rd) {
    rd += 0.0001 * (1.0 - abs(sign(rd)));
    vec3 n = ro / rd;
    vec3 k = dims / abs(rd);
    vec3 t1 = -k - n, t2 = k - n;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    return tN < tF && tF > 0.0;
}

const vec2 mscl = vec2(800.,450.)*1.15;

// https://danilw.github.io/blog/Hash_Noise_in_GPU_Shaders/
#define FIX_FRACT_HASH 3000.

float hash12(vec2 p)
{
#ifdef FIX_FRACT_HASH
    p = sign(p)*(floor(abs(p))+floor(fract(abs(p))*FIX_FRACT_HASH)/FIX_FRACT_HASH);
#endif
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
#ifdef FIX_FRACT_HASH
    p = sign(p)*(floor(abs(p))+floor(fract(abs(p))*FIX_FRACT_HASH)/FIX_FRACT_HASH);
#endif
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}

float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return (-1.+2.*(mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y));
}

vec3 Hue(vec3 c, float h)
{
    vec3 P = vec3(0.55735)*dot(vec3(0.55735),c);
    vec3 U = c-P;
    vec3 V = cross(vec3(0.55735),U);    
    c = U*cos(h*6.2832) + V*sin(h*6.2832) + P;
    return c;
}

vec3 HueShift(vec3 c, float h){
    h = floor(h*25.)/25.;
    vec3 tc = Hue(c, (h-0.5)*0.25);
    return tc;
}

vec2 Box_hit(vec3 ro,vec3 rd,vec3 p0,vec3 p1)
{
    vec3 t0 = (mix(p1, p0, step(0., rd * sign(p1 - p0))) - ro) / rd;
    vec3 t1 = (mix(p0, p1, step(0., rd * sign(p1 - p0))) - ro) / rd;
    return vec2(max(t0.x, max(t0.y, t0.z)),min(t1.x, min(t1.y, t1.z)));
}

vec3 boxNormal(vec3 pos,vec3 p0,vec3 p1, vec3 bsize)
{
    pos = pos - (p0 + p1) / 2.;
    vec3 arp = abs(pos) / bsize;
    return step(arp.yzx, arp) * step(arp.zxy, arp) * sign(pos);
}

bool BoxIntersect_min( in vec3 ro, in vec3 rd, vec3 opos, vec3 size, out float tN, out vec3 norm){
    vec3 p = size*0.5+opos;
    vec3 q = -size*0.5+opos;
    vec2 b = Box_hit(ro, rd, p, q);
    tN=MAX_DIST;
    norm=vec3(0.,1.,0.);

    if(b.x > MIN_DIST && b.x < b.y && b.x < MAX_DIST)
    {
        tN = b.x;
        vec3 pos = ro + rd * tN;
        norm = boxNormal(pos, p, q, size);
        return true;
    }
    return false;
}


const vec3 sun_color = vec3(0.5);
const vec3 sky_color = vec3(0.075);
//const vec3 horizon_color = vec3(.25);
const vec3 ground_color = vec3(0.05);

const vec3 lig = normalize(vec3(0.7,0.5,0.4));

vec3 blurred_background(vec3 rd)
{
    float sun = max(0.0, dot(rd, lig));
    return 0.1*(mix(ground_color, sky_color, (dot(rd, vec3(0.0, 1.0, 0.0))*0.5 + 0.5)) +
        0.24*pow(sun, 2.0)*sun_color);
}

float fresnel(vec3 d, vec3 n)
{
    float a = clamp(1.0-dot(n,-d), 0.0, 1.0);
    return clamp(exp((5.0*a)-5.0), 0.0, 1.0);
}

vec3 mixc(vec3 ro, vec3 rd, float t, vec3 nor, vec3 a, vec3 e, float v){
    const vec3 lig = normalize(vec3(0.7,0.5,0.4));
    vec3 hal = normalize(-rd+lig);
    float dif = clamp( dot(nor,lig), 0.0, 1.0 );
    float amb = clamp( 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0)), 0.0, 1.0 );
    
    vec3 col = a+e*0.;
    col *= vec3(0.6)*amb + vec3(1.)*dif;
    col+=e;
    float tl = fresnel(rd, nor);
    col*=1.-tl;
    col += v*0.4*pow(clamp(dot(hal,nor),0.0,1.0),8.0)*dif;
    col += v*5.*pow(clamp(dot(hal,nor),0.0,1.0),28.0)*dif*tl;
    return col;
    
}


bool BoxIntersect_min_inv( in vec3 ro, in vec3 rd, vec3 opos, vec3 size, out float tN, out vec3 norm){
    vec3 p = size*0.5+opos;
    vec3 q = -size*0.5+opos;
    vec2 b = Box_hit(ro, rd, p, q);
    tN=MAX_DIST;
    norm=vec3(0.,1.,0.);

    if(b.y > MIN_DIST && b.x < b.y && b.y < MAX_DIST)
    {
        tN = b.y;
        vec3 pos = ro + rd * tN;
        norm = -boxNormal(pos, p, q, size);
        return true;
    }
    return false;
}

void tix_ta(vec2 ts, bool fa, out vec2 tix, out bool ta);
void BoxIntersectMin_minimal_inv_tv(vec3 ro, vec3 rd, vec3 box_l, vec3 opos, inout bool result, inout HitInfo hit, sampler2D ch, vec2 ires, vec2 ts, bool fa, float timer) {
    float tnew;
    vec3 normnew;
    
    if (BoxIntersect_min_inv(ro, rd, opos, box_l, tnew, normnew)) {
        if (tnew < hit.t) {
            if(normnew.x>-0.5){
                hit.t = tnew;
                hit.norm = normnew;
                vec3 refd = normalize(reflect(rd, normnew));
                vec3 mc = blurred_background(refd);
                
                vec3 tp = ro-opos+rd*tnew;
                
                vec2 tuv = vec2(tp.zx/box_l.zx)*vec2(0.95,.85*-normnew.y);
                if(abs(normnew.z)>0.5)tuv = (tp.xy/box_l.xy)*vec2(-normnew.z*0.95,.85);
                tuv+=0.5;
                const ivec2 MEMORY_BOUNDARY = ivec2(5, 3+10);
                const float mscale = 10.;
                vec2 sft = vec2(0.,MEMORY_BOUNDARY.y+1)/ires;
                vec2 tix;
                bool ta;
                tix_ta(ts, fa, tix, ta);
                
                bool ecf = ((hash12(ts*11.31+10.853))>0.8);
                vec2 ttixx = ivec2(tix)==ivec2(1,1)?(hash12(ts*1.31+.53)>0.6?vec2(1.,0.):vec2(0.,1.-float(hash12(ts*.31+.53)>0.5))):tix;
                if(ecf)tix=1.-ttixx;
                tuv+=tix;
                
                tuv*=(mscl/ires.xy)*.5*1./mscale;
                tuv+=sft;
                if(ecf)tuv.y+=2.0*((mscl/ires.xy)*.5*1./mscale).y;
                vec4 tc = textureLod(ch, tuv, 0.);
                tc.rgb=HueShift(tc.rgb,hash12(ts*263.131+0.5));
                
                int ix = int(hash12(ts*143.331)*7.);
                mat3 trc = mat3(vec3(1.,0.5,0.75),vec3(.5,1.,.75),vec3(0.5,0.75,1.));
                vec3 tco = ((ix<3)&&(ivec2(tix)!=ivec2(1,1)))?trc[ix]:vec3(.25,.85,1.);
                if(ecf){tco[2-(ix%3)]+=5.;tco*=0.25;}
                if(ta)tc.rgb = vec3(tco*clamp(tc.a,0.,1.));
                bool tfax = ivec2(tix)==ivec2(1,1)&&ta;
                if(tfax)tc.rgb=clamp((1.-clamp(.5*trc[ix%3]/(2.5*tc.rgb+0.001),0.,1.))*1.5,0.,1.);
                
                float ttsx = (ts.x+ts.y)*.5-10.;
                float tml = timer*2.75;
                float ttd = step(0.,0.35-ttsx-tml);
                float tsl = step(timer, 10.);
                ttd*=tsl;
                ttd*=float(!((fa)&&(ivec2(ts)==ivec2(1,-2))));
                tc.rgb = tc.rgb*(1.-ttd)+ttd*0.;
                
                tc.rgb*=0.25+1.6*float(ta&&!tfax);
                
                
                float d = step(0.15,(tuv.y))*1.;
                
                mc = mixc(ro, rd, tnew, normnew, 2.5*mc+tc.rgb*0.5, tc.rgb*0.21, .25);
                
                hit.color = vec4(mc, 1.);
                hit.obj_type = OBJ_BOX;
                result = true;
            }
        }
    }
}

void BoxIntersectMin_minimal_inv_tv_a1(vec2 m, vec3 ro, vec3 rd, vec3 box_l, vec3 opos, inout bool result, inout HitInfo hit) {
    float tnew;
    vec3 normnew;
    
    if (BoxIntersect_min_inv(ro, rd, opos, box_l, tnew, normnew)) {
        if (tnew < hit.t) {
            bool a = normnew.x>-0.5;
            bool b = true;
            if(normnew.x>0.5){
                vec3 tp = ro-opos+rd*tnew;
                tp.z+=sign(tp.z)*0.15*(m.x+.5);
                tp.z=fract(tp.z)-0.5;
                
                b = length(m.y*tp.yz*vec2(1.,0.5)*1.5)>0.125;
            }
            if(a&&b){
                hit.t = tnew;
                hit.norm = normnew;
                vec3 refd = normalize(reflect(rd, normnew));
                vec3 mc = blurred_background(refd);
                mc = mixc(ro, rd, tnew, normnew, mc, vec3(0.), 0.5);
                hit.color = vec4(mc, 1.);
                hit.obj_type = OBJ_BOX;
                result = true;
            }
        }
    }
}





// https://www.shadertoy.com/view/3tj3DW
bool rounded2Intersect_iSphere4( in vec3 ro, in vec3 rd, in float ra, out float tNo)
{
    tNo=MAX_DIST+1.;
    float r2 = ra*ra;
    
    vec3 d2 = rd*rd; vec3 d3 = d2*rd;
    vec3 o2 = ro*ro; vec3 o3 = o2*ro;

    float ka = 1.0/dot(d2,d2);

    float k3 = ka* dot(ro,d3);
    float k2 = ka* dot(o2,d2);
    float k1 = ka* dot(o3,rd);
    float k0 = ka*(dot(o2,o2) - r2*r2);

    float c2 = k2 - k3*k3;
    float c1 = k1 + 2.0*k3*k3*k3 - 3.0*k3*k2;
    float c0 = k0 - 3.0*k3*k3*k3*k3 + 6.0*k3*k3*k2 - 4.0*k3*k1;

    float p = c2*c2 + c0/3.0;
    float q = c2*c2*c2 - c2*c0 + c1*c1;
    
    float h = q*q - p*p*p;

    if( h<0.0 ) return false;
    float sh = sqrt(h);

    float s = sign(q+sh)*pow(abs(q+sh),1.0/3.0);
    float t = sign(q-sh)*pow(abs(q-sh),1.0/3.0);
    vec2  w = vec2( s+t,s-t );

#if 1
    vec2  v = vec2( w.x+c2*4.0, w.y*sqrt(3.0) )*0.5;
    float r = length(v);
    float tt = -abs(v.y)/sqrt(r+v.x) - c1/r - k3;
    if(tt<0.0) return false;
    tNo=tt;
    return true;
#else
    float r = sqrt( c2*c2 + w.x*w.x + 2.0*w.x*c2 - c0 );
    float tt = -sqrt( 3.0*w.y*w.y/(4.0*r+w.x*2.0+c2*8.0)) - c1/r - k3;
    if(tt<0.0) return false;
    tNo=tt;
    return true;
#endif    
}

vec3 nSphere4( in vec3 pos )
{
    return normalize( pos*pos*pos );
}


// https://www.shadertoy.com/view/WlSXRW
bool roundedboxIntersect( in vec3 ro, in vec3 rd, in vec3 size, in float rad, out float tNo) 
{
    tNo=MAX_DIST+1.;
    // bounding box
    rd += 0.0001 * (1.0 - abs(sign(rd)));
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*(size+rad);
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN > tF || tF < 0.0) return false;
    float t = tN;
    
    // convert to first octant
    vec3 pos = ro+t*rd;
    vec3 s = sign(pos);
    ro  *= s;
    rd  *= s;
    pos *= s;

    // faces
    pos -= size;
    pos = max( pos.xyz, pos.yzx );

    bool ifl = t<0.0;
    if( min(min(pos.x,pos.y),pos.z)<0.0&&!ifl){tNo = t; return true;}

    // some precomputation
    vec3 oc = ro - size;
    vec3 dd = rd*rd;
    vec3 oo = oc*oc;
    vec3 od = oc*rd;
    float ra2 = rad*rad;

    t = MAX_DIST+1.;        

    {
        float b = od.x + od.y + od.z;
        float c = oo.x + oo.y + oo.z - ra2;
        
        float h = b*b - c;
        if( h>0.0 ) t = -b-sqrt(h);
    }

    // edge X
    {
        float a = dd.y + dd.z;
        float b = od.y + od.z;
        float c = oo.y + oo.z - ra2;
        float h = b*b - a*c;
        if( h>0.0 )
        {
            h = (-b-sqrt(h))/a;
            if( h>0.0 && h<t && abs(ro.x+rd.x*h)<size.x ) t = h;
        }
    }
    // edge Y
    {
        float a = dd.z + dd.x;
        float b = od.z + od.x;
        float c = oo.z + oo.x - ra2;
        float h = b*b - a*c;
        if( h>0.0 )
        {
            h = (-b-sqrt(h))/a;
            if( h>0.0 && h<t && abs(ro.y+rd.y*h)<size.y ) t = h;
        }
    }
    // edge Z
    {
        float a = dd.x + dd.y;
        float b = od.x + od.y;
        float c = oo.x + oo.y - ra2;
        float h = b*b - a*c;
        if( h>0.0 )
        {
            h = (-b-sqrt(h))/a;
            if( h>0.0 && h<t && abs(ro.z+rd.z*h)<size.z ) t = h;
        }
    }

    if(t>MAX_DIST){return false;}
    if(t<=0.0) return false;
    tNo = t;
    return true;
}

vec3 roundedboxNormal( in vec3 pos, in vec3 siz, in float rad )
{
    return sign(pos)*normalize(max(abs(pos)-siz,0.0));
}

void RoundedBoxIntersectMin_mod_tv(vec2 ts, vec4 acu, vec3 ro, vec3 rd, in vec3 size, vec3 opos, in float rad, inout bool result, inout HitInfo hit) {
    float tnew;
    vec3 normnew;
    ro -= opos;
    if (roundedboxIntersect(ro, rd, size, rad, tnew)) {
        if (tnew < hit.t) {
            normnew=roundedboxNormal(ro+rd*tnew, size, rad);
            vec3 tp = ro+rd*tnew;
            bool a = normnew.x<0.5;
            bool b = a;
            if(!a){
                bool se = false;
                vec3 bpc = vec3(acu.x*0.5, -(acu.x*0.25+acu.z*0.5), 0.);
                float tlp = abs(tp.y-bpc.y)-(acu.x*0.5-acu.z)*0.5*acu.w;
                bool c=tlp>0.;
                if(!c)c=c||((fract(tlp*45.)-0.5>0.));
                b = (normnew.x>0.5&&(se||(c&&step(tp.y,-acu.z)>0.5)||step(acu.y,tp.y)>0.5||step(acu.y,abs(tp.z))>0.5));
                
            }
            
            if(a||b){
                hit.t = tnew;
                
                hit.norm = normnew;
                vec3 refd = normalize(reflect(rd, normnew));
                vec3 mc = blurred_background(refd);
                mc = mixc(ro, rd, tnew, normnew, mc, vec3(0.), .25);
                hit.color = vec4(mc*(1.-smoothstep(-0.16,-0.18,(tnew*rd+ro).x-size.x)),1.);
                hit.obj_type = OBJ_BOX;
                result = true;
            }
        }
    }
}

// https://www.shadertoy.com/view/wdBXRt
vec2 edts(vec2 p) {
    vec2 uv = p*p;
    float t = 2.0 * sqrt(2.0);
    vec2 s = vec2(2.0 + uv.x - uv.y, 2.0 - uv.x + uv.y);
    vec2 t1 = s + p * t;
    vec2 t2 = s - p * t;
    //t1=abs(t1);t2=abs(t2); //or this
    if (any(lessThan(vec4(t1, t2), vec4(0.))))return 0.5 * (t1) - 0.5 * (t2);
    return 0.5 * sqrt(t1) - 0.5 * sqrt(t2);
}


void tix_ta(vec2 ts, bool fa, out vec2 tix, out bool ta){
    ts+=112.;
    tix = floor(hash22(ts*141.331)*2.);
    ta = hash12(ts*122.331)>0.45;
    if(ivec2(tix)==ivec2(1,1)&&(!fa)&&ta){
        tix = vec2(hash22(ts*81.331));
        ta = tix.y>0.5;
        if(ta)tix = tix.x>0.66?vec2(1.,0.):(tix.x>0.33?vec2(0.,0.):vec2(0.,1.));
        else tix = floor(hash22(ts*91.331)*2.);
    }
}

vec3 texure_sph(vec3 nor, vec3 pos, sampler2D ch, sampler2D ch2, out float d, float rad, vec2 ts, out float tba, bool fa, float timer){
    vec3 uvw = pos/rad;
    vec2 uv = uvw.zy;
    uv = edts(uv*.62588);
    vec2 tix;
    bool ta;
    tix_ta(ts, fa, tix, ta);
    d = step(abs(uv.x),0.5)*step(abs(uv.y),0.5);
    vec4 tc = vec4(0.);
    
    bool ecf = ((hash12(ts*11.31+10.853))>0.8);
    vec2 ttixx = ivec2(tix)==ivec2(1,1)?(hash12(ts*1.31+.53)>0.6?vec2(1.,0.):vec2(0.,1.-float(hash12(ts*.31+.53)>0.5))):tix;
    if(!ecf)tc = textureLod(ch,(uv+0.5)*.5+.5*tix,0.);
    else tc = textureLod(ch2,(uv+0.5)*.5+.5*(1.-ttixx),0.);
    tc.rgb=HueShift(tc.rgb,hash12(ts*263.131+0.5));
    
    int ix = int(hash12(ts*143.331)*7.);
    mat3 trc = mat3(vec3(1.,0.5,0.75),vec3(.5,1.,.75),vec3(0.5,0.75,1.));
    vec3 tco = ((ix<3)&&(ivec2(tix)!=ivec2(1,1)))?trc[ix]:vec3(.25,.85,1.);
    if(ecf){tco[2-(ix%3)]+=5.;tco*=0.25;}
    if(ta)tc.rgb = vec3(tco*clamp(tc.a,0.,1.));
    tba = (1.-2.*float(ta));
    if(ivec2(tix)==ivec2(1,1)&&ta)tc.rgb=clamp((1.-clamp(0.5*trc[ix%3]/(tc.rgb+0.001),0.,1.))*2.,0.,2.);
    
    float ttsx = (ts.x+ts.y)*.5-10.;
    float tml = timer*2.75;
    float ttd = step(0.,length(uv)-ttsx-tml);
    float tsl = step(timer, 10.);
    ttd*=tsl;
    ttd*=float(!((fa)&&(ivec2(ts)==ivec2(1,-2))));
    if(tba>0.5)tba=1.-2.*step(ttsx+tml,1.)*tsl;
    tc.rgb = tc.rgb*(1.-ttd)+ttd*0.;
    return tc.rgb*d+0.001;
}

void Rounded2Intersect_iSphere4Min_tv(vec2 ts, bool fa, vec3 ro, vec3 rd, vec3 opos, in float rad, inout bool result, inout HitInfo hit, sampler2D ch, sampler2D ch2, float timer) {
    float tnew;
    ro -= opos;
    if (rounded2Intersect_iSphere4( ro, rd, rad, tnew)) {
        if (tnew < hit.t) {
            vec3 normnew=nSphere4(ro+rd*tnew);
            vec3 refd = normalize(reflect(rd, normnew));
            vec3 mc = mixc(ro, rd, tnew, normnew, vec3(0.), vec3(0.), 1.);
            
            hit.t = tnew;
            hit.norm = normnew;
            hit.color = vec4(mc, 1.);
            hit.obj_type = OBJ_BOX;
            result = true;
            
            float ttnew;
            if(rounded2Intersect_iSphere4( ro, rd, rad*0.905, ttnew))
            {
                if((ttnew*rd+ro).x>0.805*rad*0.905)
                {
                    //hit.t = ttnew;
                    vec3 tnormnew=nSphere4(ro+rd*tnew);
                    //hit.norm = tnormnew;
                    float d;
                    float tba;
                    mc = texure_sph(tnormnew, ro+rd*ttnew, ch, ch2, d, rad, ts, tba, fa, timer);
                    mc = mixc(ro, rd, tnew, normnew, mc*0.25, mc*.85, 0.45);
                    if(d>0.5)hit.color = vec4(mc*tba,1.);
                    //hit.obj_type = OBJ_BOX;
                    //result = true;
                }
            }

        }
    }
}


vec3 eliNormal( in vec3 pos, vec3 sph_pos, vec3 sph_rad)
{
    return normalize((pos-sph_pos)/(sph_rad*sph_rad));
}

//https://www.shadertoy.com/view/MlsSzn
bool eliIntersect_inv( in vec3 ro, in vec3 rd, vec3 sph_pos, vec3 sph_rad, out float tN)
{
    tN = MAX_DIST;
    vec3 oc = ro - sph_pos;
    
    vec3 ocn = oc / sph_rad;
    vec3 rdn = rd / sph_rad;
    
    float a = dot(rdn, rdn);
  float b = dot(ocn, rdn);
  float c = dot(ocn, ocn);
  //float h = b*b - a*(c-1.0);
    float h = b*b - a*(c-1.0);
  if( h<0.0 ) return false;
  float t = (-b + sqrt(h))/a;
    if(t<0.)return false;
    tN = t;
    return true;
}

void eliIntersectMin_inv_mod_tv(vec4 acu, vec3 SpPos, vec3 SpRad, vec3 ro, vec3 rd, inout bool result, inout HitInfo hit, int obj_t, sampler2D ch, vec2 ires, vec2 ts, bool fa, float timer) {
    float tnew;
    if (eliIntersect_inv(ro, rd, SpPos, SpRad, tnew)) {
        if (tnew < hit.t) {
            vec3 tp = ro-SpPos+rd*tnew;
            vec3 normnew = eliNormal(ro+rd*tnew, SpPos, SpRad);
            bool ab = boxAABB(vec3(100.5,acu.x*0.25+acu.z*0.5-0.5*(acu.x*0.5-acu.y),acu.y+0.001), tp, normnew);
            
            if(ab&&tp.x<-acu.w)
            {
                hit.t = tnew;
                hit.norm = -normnew;
                hit.obj_type = obj_t;
                vec3 refd = normalize(reflect(rd, -normnew));
                
                vec2 tuv = (tp.zy/SpRad.zy)*vec2(0.66,0.62)+0.5;
                const ivec2 MEMORY_BOUNDARY = ivec2(5, 3+10);
                const float mscale = 10.;
                vec2 sft = vec2(0.,MEMORY_BOUNDARY.y+1)/ires;
                vec2 tix;
                bool ta;
                tix_ta(ts, fa, tix, ta);
                
                bool ecf = ((hash12(ts*11.31+10.853))>0.8);
                vec2 ttixx = ivec2(tix)==ivec2(1,1)?(hash12(ts*1.31+.53)>0.6?vec2(1.,0.):vec2(0.,1.-float(hash12(ts*.31+.53)>0.5))):tix;
                if(ecf)tix=1.-ttixx;
                
                tuv+=tix;
                vec2 ouv = tuv;
                tuv*=(mscl/ires.xy)*.5*1./mscale;
                tuv+=sft;
                if(ecf)tuv.y+=2.0*((mscl/ires.xy)*.5*1./mscale).y;
                
                vec4 tc = textureLod(ch, tuv, 0.);
                tc.rgb=HueShift(tc.rgb,hash12(ts*263.131+0.5));
                int ix = int(hash12(ts*143.331)*7.);
                mat3 trc = mat3(vec3(1.,0.5,0.75),vec3(.5,1.,.75),vec3(0.5,0.75,1.));
                vec3 tco = ((ix<3)&&(ivec2(tix)!=ivec2(1,1)))?trc[ix]:vec3(.25,.85,1.);
                if(ecf){tco[2-(ix%3)]+=5.;tco*=0.25;}
                if(ta)tc.rgb = vec3(tco*clamp(tc.a,0.,1.));
                bool tfax = ivec2(tix)==ivec2(1,1)&&ta;
                if(tfax)tc.rgb=clamp((1.-clamp(0.5*trc[ix%3]/(2.5*tc.rgb+0.001),0.,1.))*1.5,0.,1.);
                
                float ttsx = (ts.x+ts.y)*.5-10.;
                float tml = timer*2.75;
                float ttd = step(0.,0.35-ttsx-tml);
                float tsl = step(timer, 10.);
                ttd*=tsl;
                ttd*=float(!((fa)&&(ivec2(ts)==ivec2(1,-2))));
                tc.rgb = tc.rgb*(1.-ttd)+ttd*0.;
                
                vec2 tpu = (fract(ouv)-0.5);
                tpu*=tpu;
                float d = 1.-smoothstep(0.05,0.305,length(tpu));
                tc.rgb*=0.25+0.46*float(ta&&!tfax);
                tc.rgb*= vec3(d*d);
                vec3 mc = mixc(ro, rd, tnew, -normnew, blurred_background(refd)*1.+tc.rgb*1., tc.rgb*0., 0.01);
                hit.color = vec4(mc,1.);
                result = true;
            }
        }
    }
}


bool CylinderIntersect( in vec3 ro, in vec3 rd, in float ra, in float heigh, out float tN, out vec3 norm, out bool wa) 
{
    vec3 pa=vec3(0.,heigh,0.);
    vec3 pb=vec3(0.,-heigh,0.);
    vec3 ba = pb-pa;
    wa = false;

    norm=vec3(0.,1.,0.);
    tN=MAX_DIST;

    vec3  oc = ro - pa;

    float baba = dot(ba,ba);
    float bard = dot(ba,rd);
    float baoc = dot(ba,oc);

    float k2 = baba            - bard*bard;
    float k1 = baba*dot(oc,rd) - baoc*bard;
    float k0 = baba*dot(oc,oc) - baoc*baoc - ra*ra*baba;

    float h = k1*k1 - k2*k0;
    if( h<0.0 ) return false;
    float ins = -1.; // inside -1.
    h = ins*sqrt(h);
    float t = (-k1-h)/k2;
    //if( t<0.0 ) return false; //original

    float y = baoc + t*bard;
    if( y>0.0 && y<baba ){
        if( t<0.0 ) return false;//fix to hide when camera over it
        tN=t;
        norm=ins*(oc+t*rd - ba*y/baba)/ra;
        return true;
    }

    t = ( ((y<0.0) ? 0.0 : baba) - baoc)/bard;
    if( t<0.0 ) return false;//fix to hide when camera over it
    if( abs(k1+k2*t)<ins*h ){
        tN=t;
        norm=ba*sign(y)/baba;
        wa=true;
        return true;
    }

    return false;
}

vec3 cylNormal( in vec3 p, float ra )
{
    vec3 a=vec3(0.,1.,0.);
    vec3 b=vec3(0.,-1.,0.);
    vec3  pa = p - a;
    vec3  ba = b - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float h = dot(pa,ba)/baba;
    return (pa - ba*h)/ra;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 ab = b - a;
    float t = dot(p - a, ab) / dot(ab, ab);
    t = clamp(t, 0.0, 1.0);
    return length((a + t * ab) - p) - r;
}

float flare(float e, float i, float s) { return exp(1.-(e*i))*s; }

vec4 colorCylinder(vec3 ro, vec3 rd, float d, vec3 nor,float heigh, vec2 ts, float timer, bool fa)
{
    vec3 pos = (ro+rd*d);
    vec2 tuv=vec2(0.5,0.)+vec2(2.*atan(pos.x,pos.z)/(3.1415926*2.), pos.y*.5/heigh);
    
    float tt = (abs(ts.x)+abs(ts.y))*112.331;
    tt+=timer;
    vec3 col = 0.5 + 0.5*cos(tt*2.+10.*tuv.xyx+vec3(0,2,4));
    
    float tl = clamp(0.051/(0.001+smoothstep(0.0,.975,abs(tuv.x))),0.,1.);
    vec2 ttuv= tuv*4.;
    ttuv.y+=timer*2.5;
    float td = fract(ttuv.x + ttuv.y)*fract(ttuv.y - ttuv.x); 
    td*=tl;
    vec3 c1 = 1.*(td*0.35+1.5*td*col);
    ttuv= tuv*2.;
    ttuv.y+=timer*.5;
    td = fract(ttuv.x + ttuv.y)*fract(ttuv.y - ttuv.x); 
    td*=tl;
    c1 = c1*0.5+2.*td*c1+0.5*(td*0.35+1.5*td*col);
    //c1=clamp(c1,0.,1.);
    
    float ttsx = (ts.x+ts.y)*.5-10.;
    float tml = timer*2.75;
    float ttd = step(0.,0.35-ttsx-tml);
    float tsl = step(timer, 10.);
    ttd*=tsl;
    ttd*=float(!((fa)&&(ivec2(ts)==ivec2(1,-2))&&timer>0.4));
    c1.rgb = c1.rgb*(1.-ttd)+ttd*0.;
    
    int ix = int(hash12(ts*243.331+1.3)*7.);
    mat3 trc = mat3(vec3(1.,0.25,0.275),vec3(.35,.75,.75),vec3(0.25,0.275,1.));
    vec3 tco = (ix<5)?trc[ix%3]*5.:vec3(1.,1.,1.);
    
    vec3 mc = mixc(ro, rd, d, nor, clamp(c1*tco,0.,1.)*1.5, vec3(0.), .5);
    return vec4(mc,1.);
}

void CylinderIntersectMin(vec3 ro, vec3 rd, float rad, float heigh, vec3 opos, inout bool result, inout HitInfo hit, vec2 ts, float timer, bool fa) {
    float tnew;
    vec3 normnew;
    ro -= opos;
    bool wa;
    if (CylinderIntersect(ro, rd, rad, heigh, tnew, normnew, wa)) {
        if (tnew < hit.t) {
            vec3 tp = ro+rd*tnew;
            if(tp.x<-0.0){
                normnew=normnew.xzy; //rot
                hit.t = tnew;
                hit.norm = normnew;
                if(wa){hit.color = vec4(vec3(0.051),1.);}
                else hit.color = colorCylinder(ro,rd,hit.t,normnew,heigh,ts,timer, fa);
                hit.obj_type = OBJ_BOX;
                result = true;
            }
        }
    }
}





// base on https://www.shadertoy.com/view/NlycW1

struct its
{
	float t;
	vec3 n;    //normal 
	
};
const its  NO_its=its(MAX_DIST,vec3(0.,1.,0.));

struct span
{
	its n;
	its f;
};

//-----------Intersection functions--(based on Iq)------------------
span Inter(span a, span b)
{
   bvec4 cp = bvec4(a.n.t<b.n.t,a.n.t<b.f.t,a.f.t<b.n.t,a.f.t<b.f.t); 
   // if(b.n.t==NOHIT || a.n.t==NOHIT) return span(NO_its,NO_its);
   
   if(cp.x && cp.z) return span(NO_its,NO_its);
   else if(cp.x && !cp.z && cp.w)  return span(b.n,a.f);
   else if(cp.x && !cp.z && !cp.w) return b;
   else if(!cp.x && cp.y &&  cp.w) return a;
   else if(!cp.x && cp.y &&  !cp.w) return span(a.n,b.f);
   else return span(NO_its,NO_its);
}

span Sub(span a, span b)
{
   bvec4 cp = bvec4(a.n.t<b.n.t,a.n.t<b.f.t,a.f.t<b.n.t,a.f.t<b.f.t); 
   // if(a.n.t==NOHIT) return span(NO_its,NO_its);
   // else if(b.n.t==NOHIT) return a;        
   if     (cp.x && cp.z) return a;
   else if(cp.x && !cp.z && cp.w)  return span(a.n,b.n);
   else if(cp.x && !cp.z && !cp.w && b.n.t>0.) return span(a.n,b.n); 
   else if(cp.x && !cp.z && !cp.w && b.n.t<0.) return span(b.f,a.f); //+ secondary span =  span(b.f,a.f)
   else if(!cp.x && cp.y && cp.w) return span(NO_its,NO_its);
   else if(!cp.x && cp.y && !cp.w) return span(b.f,a.f);
   else return a;
   
}

// useful if transparent 
span Union(span a, span b)
{
   bvec4 cp = bvec4(a.n.t<b.n.t,a.n.t<b.f.t,a.f.t<b.n.t,a.f.t<b.f.t); 
   if(b.n.t==MAX_DIST) return a;
   else if(a.n.t==MAX_DIST) return b;   
   else if(cp.x  && cp.z  && a.f.t>0.) return a;
   else if(cp.x  && cp.z  && a.f.t<0.) return b;
   else if(cp.x  && !cp.z && cp.w) return span(a.n,b.f);
   else if(cp.x  && !cp.z && !cp.w) return a;
   else if(!cp.x && cp.y  && cp.w) return b;
   else if(!cp.x && cp.y  && !cp.w) return span(b.n,a.f);
   else if(!cp.x && !cp.y  && a.f.t>0.) return b;
   else /*if(!cp.x && !cp.y  && a.f.t<0.) */ return a;   
}

// this is infinite long box
// exist because Nvidia bugs https://www.shadertoy.com/view/NtfyD2
span iBox_2d( in vec3 ro, in vec3 rd, vec2 boxSize) 
{
    rd+=0.000001*(1.-abs(sign(rd))); //fix against vertical line on middle
    vec3 m = 1./rd; 
    vec3 n = m*ro;   
    vec3 boxSize_t=vec3(1.,boxSize);
    vec3 k = abs(m)*boxSize_t;
    
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( t1.y, t1.z );
    float tF = min( t2.y, t2.z );
    if( tN>tF ) return span(NO_its,NO_its); // no intersection
    vec3 oNor = -sign(rd)*vec3(0.,step(t1.zy,t1.yz)); 
    vec3  fNor= sign(rd)*vec3(0.,step(t2.yz,t2.zy)); 
    return  span(its(tN,oNor) , its(tF,fNor));
}


//  plane with thickness h
span iPlane( in vec3 ro, in vec3 rd, in vec3 n ,float h)
{
    float d1= -dot(ro,n)/dot(rd,n),   d2= -(dot(ro-h*n,n))/dot(rd,n);
    vec3  u = normalize(cross(n,vec3(0,0,1))), v = normalize(cross(u,n) );
    vec3 oNor=n;
    if(d1<d2) return span(its(d1,-oNor),its(d2,oNor));
    return span(its(d2,oNor),its(d1,-oNor));
}

vec3 opU( vec3 d, span s, inout vec3 normal, float mat ) {
    its ix= s.n;   
    //if(ix.t<0.) ix=s.f;
    if( ix.t<d.y && ix.t>d.x) {
        normal=ix.n;
        d=vec3(d.x, ix.t, mat);
    }
	return d;
}

vec3 RayTracing_Domain_Repetition( in vec3 ro, in vec3 rd, out vec3 normal, float sc, float st, vec2 boxx, int mx) {
    
    vec3  d = vec3(MIN_DIST, MAX_DIST, 0.);
    span s2,s3,s4;
    s2= iBox_2d(ro,rd,boxx);
    normal=vec3(0.,1.,0.);

    if(s2.n.t<MAX_DIST){
        float x = s2.n.t>0.? ro.x+ rd.x*s2.n.t:ro.x;
        float xm = fract(x*sc),         
              xf = floor(x*sc); 
              
        // 2x visible only to single direction when Sub used
        // add more loop iterations to see more layers repetitions when inside
        for(int j=0; j<2;j++){
            s3=  iPlane(ro-vec3(sign(xf)*min(abs(xf),float(mx))/sc,0,0),rd,normalize(vec3(1.,0.,0.)),st);
            s4=  Inter(s2,s3);
            d= opU(d,  s4,normal, xf);
            xf+=sign(rd.x);
        }

    }
    
    if(dot(rd,normal)>0.) normal=-normal;
    return d;
}


void RayTracing_Domain_RepetitionMin(vec3 ro, vec3 loc, vec3 rd, inout bool result, inout HitInfo hit, float sc, float st, vec2 boxx) {
    float tnew;
    vec3 normnew;
    vec3 rrt = RayTracing_Domain_Repetition((ro-loc).zxy, (rd).zxy, normnew, sc, st, boxx, 33);
    tnew = rrt.y;
    if (tnew < hit.t) {
        //if(rrt.z>-35.&&rrt.z<35.)
        {
            hit.t = tnew;
            hit.norm = normnew.yzx;
            vec3 refd = normalize(reflect(rd, normnew.yzx));
            vec3 mc = blurred_background(refd);
            mc = mixc(ro, rd, tnew, normnew.yzx, mc, vec3(0.), .25);
            hit.color = vec4(mc,1.);
            hit.obj_type = OBJ_BOX;
            result = true;
        }
    }
}


//#define SHOW_ab
void TVIntersectMin(float max_h, vec2 ts, vec3 ro, vec3 rd, inout bool result, inout HitInfo hit, sampler2D ch, sampler2D ch2, float timer, vec2 ires){
    float box_tv = .985;
    vec4 sfi = vec4(0.);
    vec2 tm = vec2(1.);
    vec2 tts = mod(ts, vec2(5.));
    vec2 tix = floor(ts/5.);
    tts+=-floor(hash22(tix*111.185+23.43)*3.95);
    float tva = step(abs(tts.x-0.5),1.)*step(abs(tts.y-0.5),1.);
    box_tv+= 1.*tva;
    sfi+= vec4(-tts,vec2(1.))*tva;
    tm+=vec2(-1.,-0.5)*tva;
    
    vec2 tv_frame_sz = box_tv*vec2(0.45, 0.27);
    vec3 box_sz = vec3(box_tv);
    float tv_sz = box_tv*0.4;
    float tv_s_p = box_tv*0.05;

    bool ft_bx = false;
    vec2 ls_bx = vec2(1.395,1.435);

    float ls_sc = box_tv*0.0451;
    float ls_es = ls_sc*0.0;
    vec2 tv_s_szsc2 = vec2(.95,.95);
    float tv2_sh = box_tv*0.1214;
    float el_1_sc = 0.7;
    

    vec3 box_pos_local = vec3(-box_tv*0.5+-box_tv*0.025*(1.-tva),vec2(0.5,0.5)+vec2(0.5,0.5)*ts*2.+sfi.xy*1.+0.5*sfi.zw);
    
    
    // to use replace in VoxelsIntersect vec3 k = rda*vec3(.5, tps, .5); to vec3 k = rda*vec3(.5, 30.+tps, .5);
    /*
    box_pos_local.x+=0.5*ts.y;
    //vec2 tts2 = ts;
    tts.y=4.*sin(timer*1.+tts.y*.133);
    box_pos_local.x+=0.5*tts.y;
    box_pos_local.x+=0.5*length(tts.xy);
    */
    
    bool ab = boxAABB(box_sz*0.5+vec3(tv_s_p*1.25,0.,0.)+0.01, ro-box_pos_local+vec3(-tv_s_p*1.25,0.,0.), rd);
    //bool ab = true;
    if(ab){
        const float rb = 0.0135;
        RoundedBoxIntersectMin_mod_tv(ts, vec4(box_tv,tv_frame_sz,el_1_sc), ro, rd, box_sz*0.5-rb, box_pos_local, rb, result, hit);
#ifdef SHOW_ab
hit.color=vec4(vec3(0.),1.);
result = result||ab;
#endif
        
        vec3 esr_s = vec3(box_tv*0.25,tv_frame_sz.x-(box_tv*0.5-tv_frame_sz.y)*0.5+0.5*(box_tv*0.5-tv_frame_sz.x),tv_frame_sz.x);
        bool ab_s = boxAABB(esr_s+vec3(tv_s_p*1.25,0.,0.)+0.01, ro-box_pos_local+vec3(-tv_s_p*1.25,0.,0.)+-vec3(esr_s.x,-tv_frame_sz.y*0.5+0.5*tv_frame_sz.x,0.), rd);
        if(ab_s){
            BoxIntersectMin_minimal_inv_tv(ro, rd, esr_s*2., box_pos_local+vec3(esr_s.x,-tv_frame_sz.y*0.5+0.5*tv_frame_sz.x,0.), result, hit, ch2, ires, tix*tva+ts*(1.-tva), tva>0.5, timer);
            Rounded2Intersect_iSphere4Min_tv(tix*tva+ts*(1.-tva), tva>0.5, ro, rd, box_pos_local+vec3(box_tv*0.5-tv_sz+tv_s_p,-tv_frame_sz.y*0.5+0.5*tv_frame_sz.x,0.), tv_sz, result, hit, ch, ch2, timer);
            {
                vec3 es = vec3(ls_sc,ls_bx.x*((tv_frame_sz.x-(box_tv*0.5-tv_frame_sz.y)*0.5+0.5*(box_tv*0.5-tv_frame_sz.x))+float(ft_bx)*(box_tv*0.5-tv_frame_sz.x)),ls_bx.y*(tv_frame_sz.x+float(ft_bx)*(box_tv*0.5-tv_frame_sz.x)));
                vec3 ep = box_pos_local+vec3(box_tv*0.5+ls_es,-tv_frame_sz.y*0.5+0.5*tv_frame_sz.x,0.);
                eliIntersectMin_inv_mod_tv(vec4(box_tv,tv_frame_sz,ls_es), ep, es, ro, rd, result, hit, OBJ_BOX, ch2, ires, tix*tva+ts*(1.-tva), tva>0.5, timer);
            }
#ifdef SHOW_ab
hit.color=vec4(vec3(0.,0.,1.),1.);
result = result||ab_s;
#endif
        }
        
        vec3 esr_bp = box_pos_local+vec3(box_tv*0.5, -(box_tv*0.25+tv_frame_sz.y*0.5), 0.);
        bool ab_d = boxAABB(vec3((box_tv*0.5-tv_frame_sz.y)*0.5*el_1_sc,(box_tv*0.5-tv_frame_sz.y)*0.5*el_1_sc,tv_frame_sz.x)+0.01, ro-esr_bp, rd);
        if(ab_d){
            CylinderIntersectMin(ro.xzy, rd.xzy, (box_tv*0.5-tv_frame_sz.y)*0.5*el_1_sc, tv_frame_sz.x, esr_bp.xzy, result, hit, tix*tva+ts*(1.-tva), timer, tva>0.5);

            BoxIntersectMin_minimal_inv_tv_a1(tm, ro, rd, vec3(0.0051, 0.001+(box_tv*0.5-tv_frame_sz.y)*el_1_sc, 0.001+2.*tv_frame_sz.x), esr_bp-vec3(0.5*0.0051,0.,0.), result, hit);
            
            RayTracing_Domain_RepetitionMin(ro, esr_bp+vec3(-0.01,0.,0.), rd, result, hit, (25.+tm.x*25.)*1.5, (1.+(1.-tm.x)*0.9)/1.5*0.0082, vec2(0.012,-0.0+(box_tv*0.5-tv_frame_sz.y)*0.5*el_1_sc));
#ifdef SHOW_ab
hit.color=vec4(vec3(0.,1.,0.),1.);
result = result||ab_d;
#endif
        }
    }
}



float heightField(vec2 uv)
{
    //return hash21u(uv);
    return 0.5;
}

// ffix float precision fix, fix reflections 0.0001 main, -0.0009 refl
bool VoxelsIntersect(int steps, float max_h, float ffix, in vec3 ro, in vec3 rd, out vec3 normal , out float tnew, out vec2 idx, out vec3 col, sampler2D ch, sampler2D ch2, float timer, vec2 ires) {
    col = vec3(0.);
    vec2 pos = floor(ro.xz);
    rd += 0.0001 * (1.0 - abs(sign(rd)));
    vec3 rdi = 1./rd;

    vec3 rda = abs(rdi);
    vec3 rds = sign(rd);
    vec2 dis = (pos - ro.xz + .5 + rds.xz*.5) * rdi.xz;
    
    vec3 roi = rdi*(ro-vec3(.5,0.,.5));

    vec2 mm = vec2(0.0);
    for( int i=0; i<steps; i++ ) {    
        float tm=1.;
        float tps = -0.00099+max(heightField(pos),0.001)*max_h*tm;
        vec3 n = roi - rdi * vec3(pos.x, tps-1., pos.y);
        
        vec3 k = rda*vec3(.5, tps, .5);

        vec3 t1 = -n - k;
        vec3 t2 = -n + k;

        float tN = max( max( t1.x, t1.y ), t1.z )-ffix;
        float tF = min( min( t2.x, t2.y ), t2.z );

        if ( tN < tF && tN>MIN_DIST && tN<MAX_DIST ) {
            
            bool tresult = false;
            HitInfo thit;
            thit.color=vec4(0.);
            thit.t = MAX_DIST;
            thit.obj_type = OBJ_SKY;
            TVIntersectMin(max_h, pos, ro.yxz, rd.yxz, tresult, thit, ch, ch2, timer, ires);
            if(tresult){
                normal = thit.norm;
                tnew = thit.t;
                idx = pos;
                col = thit.color.rgb;
                return true;
            }
        }

    mm = step( dis.xy, dis.yx ); 
    dis += mm*rda.xz;
    pos += mm*rds.xz;
    }

    return false;
}

void VoxelsIntersectMin(vec3 ro, vec3 rd, inout bool result, inout HitInfo hit, sampler2D ch, sampler2D ch2, float timer, vec2 ires) {
    
    float tnew;
    vec2 idx;
    vec3 normnew;
    float ref = 1.;
    float vros = length(ro.xz);
    //box_tv+tv_s_p*1.25
    vec3 tcol;
    if(VoxelsIntersect(25, 1.1, 0.0001, ro, rd, normnew, tnew, idx, tcol, ch, ch2, timer, ires)){
        if (tnew < hit.t) {
            hit.color = vec4(tcol,1.);
            //hit.color = vec4(normnew,1.);
            hit.obj_type = OBJ_BOX;
            result = true;
            hit.t = tnew;
            hit.norm = normnew;
        }
    }
}



// halton low discrepancy sequence, from https://www.shadertoy.com/view/wdXSW8
void halton_loop(inout vec2 s, inout vec4 a){
    const vec2 coprimes = vec2(2.0f, 3.0f);
    a.xy = a.xy/coprimes;
    a.zw += a.xy*mod(s, coprimes);
    s = floor(s/coprimes);
}
vec2 halton(int index){
    vec2 s = vec2(index, index);
	vec4 a = vec4(1,1,0,0);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    if (s.x > 0. && s.y > 0.)halton_loop(s, a);
    return a.zw;
}





