// Buffer C (buffer) — Light Propagation Volume by paniq
// https://www.shadertoy.com/view/XdtSRn

// iterative light propagation, one step per frame

///////////////////

vec4 fetch_gv(vec3 p) {
    if ((min(p.x,min(p.y,p.z)) < 0.5) || (max(p.x,max(p.y,p.z)) > (lpvsize.x - 0.5)))
        return vec4(0.0);
    float posidx = packfragcoord3(p, lpvsize);
    vec2 uv = unpackfragcoord2(posidx, iChannelResolution[0].xy) / iChannelResolution[0].xy;
    return texture(iChannel0, uv);
}

float numvoxels;
float channel;
vec3 cmix;

float fetch_av(vec3 p) {
    if ((min(p.x,min(p.y,p.z)) < 0.5) || (max(p.x,max(p.y,p.z)) > (lpvsize.x - 0.5)))
        return 0.0;
    float posidx = packfragcoord3(p, lpvsize);
    vec2 uv = unpackfragcoord2(posidx, iChannelResolution[1].xy) / iChannelResolution[1].xy;
    return dot(texture(iChannel1, uv).rgb, cmix);
}

vec4 fetch_lpv(vec3 p) {
    if ((min(p.x,min(p.y,p.z)) < 0.5) || (max(p.x,max(p.y,p.z)) > (lpvsize.x - 0.5)))
        return vec4(0.0);
    float posidx = packfragcoord3(p, lpvsize) + channel * numvoxels;
    vec2 uv = unpackfragcoord2(posidx, iChannelResolution[2].xy) / iChannelResolution[2].xy;
    return texture(iChannel2, uv);
}

//#if USE_LPV_OCCLUSION || USE_LPV_BOUNCE
vec4 gv4[6];
vec4 gv[8];
//#if USE_LPV_BOUNCE
float bc4[6];
float bc[8];
//#endif // USE_LPV_BOUNCE
//#endif // USE_LPV_OCCLUSION || USE_LPV_BOUNCE

//angle = (4.0*atan(sqrt(11.0)/33.0));
const float solid_angle_front = 0.4006696846462392 * m3div4pi;
//angle = (-M_PI/3.0+2.0*atan(sqrt(11.0)*3.0/11.0));
const float solid_angle_side = 0.4234313544367392 * m3div4pi;

// 6 * (solid_angle_side * 4 + solid_angle_front) = 4 * PI

vec4 accum_face(vec4 shcoeffs, int i, int j, int dim, int face_dim, 
                vec3 p, vec3 offset, vec3 face_offset,
                vec4 gvcoeffs, vec4 gvrefcoeffs, float gvrefcolor) {
    if (i == j) return vec4(0.0);

    vec3 dirw = normalize(face_offset - offset);
    
    float solid_angle = (dim == face_dim)?solid_angle_front:solid_angle_side;
    
    vec4 outdirsh = sh_project(dirw);
    vec4 indirsh = outdirsh;
    vec4 invindirsh = sh_project(-dirw);
    
	// how much flux has been received
    float influx = sh_dot(shcoeffs, indirsh) * solid_angle;
   
    // how much flux will be occluded
    #if USE_LPV_OCCLUSION
    float occluded = sh_dot(gvcoeffs, indirsh);
    #else
    float occluded = 0.0;
    #endif
    
    // how much flux will be passed on
    float outflux = influx * (1.0 - occluded);
    
    vec4 result = outdirsh * outflux; 
    
    // how much flux will be reflected
    #if USE_LPV_BOUNCE
    vec4 rvec = gvrefcoeffs;
    float reflected = outflux * sh_dot(rvec, invindirsh);
    if (reflected > 0.0) {
        result += rvec * (reflected * gvrefcolor);
    }
    #endif    
    
    return result;
}
    
vec4 sample_neighbors( int i, int dim, vec3 p, vec3 offset, vec4 gvcoeffs) {
    vec4 shcoeffs = fetch_lpv(p + offset);
	vec4 shsumcoeffs = vec4(0.0);
    
    vec3 e = vec3(-0.5,0.5,0.0);
    shsumcoeffs += accum_face(shcoeffs, i, 0, dim, 2, p, offset, e.zzx, gvcoeffs, gv4[0], bc4[0]);
    shsumcoeffs += accum_face(shcoeffs, i, 1, dim, 2, p, offset, e.zzy, gvcoeffs, gv4[1], bc4[1]);
    shsumcoeffs += accum_face(shcoeffs, i, 2, dim, 1, p, offset, e.zxz, gvcoeffs, gv4[2], bc4[2]);
    shsumcoeffs += accum_face(shcoeffs, i, 3, dim, 1, p, offset, e.zyz, gvcoeffs, gv4[3], bc4[3]);
    shsumcoeffs += accum_face(shcoeffs, i, 4, dim, 0, p, offset, e.xzz, gvcoeffs, gv4[4], bc4[4]);
    shsumcoeffs += accum_face(shcoeffs, i, 5, dim, 0, p, offset, e.yzz, gvcoeffs, gv4[5], bc4[5]);
    return shsumcoeffs;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float posidx = packfragcoord2(fragCoord.xy, iResolution.xy);
    numvoxels = lpvsize.x * lpvsize.y * lpvsize.z;
    channel = floor(posidx / numvoxels);
    posidx -= channel * numvoxels;
    cmix = vec3(
        float(channel == 0.0),
        float(channel == 1.0),
        float(channel == 2.0));
    if ((iFrame != 0) && (posidx < numvoxels)) {
	    vec3 pos = unpackfragcoord3(posidx,lpvsize);
        vec3 tpos = (pos + 0.5) / lpvsize;
        vec3 wpos = (tpos * 2.0 - 1.0) * 2.5 + vec3(0.0,1.0,0.0);
        float r = 1.0 * 1.7320508075689 / lpvsize.x;
		float d = doModel(wpos, iTime).x;        
        const float L = 1.0;
        if (d >= L) {
            vec3 n = calcNormal(wpos, iTime);
		   	float lightcolor = dot(cmix,vec3(1.0,0.9,0.85));
        	fragColor = sh_project(-n) * 20.0 * lightcolor;
        } else {
            vec4 shsumcoeffs = vec4(0.0);
            vec3 e = vec3(-1.0,1.0,0.0);
            
            #if USE_LPV_OCCLUSION || USE_LPV_BOUNCE
            vec2 w = vec2(0.0,1.0);
            gv[0] = fetch_gv(pos + w.xxx);
            gv[1] = fetch_gv(pos + w.xxy);
            gv[2] = fetch_gv(pos + w.xyx);
            gv[3] = fetch_gv(pos + w.xyy);
            gv[4] = fetch_gv(pos + w.yxx);
            gv[5] = fetch_gv(pos + w.yxy);
            gv[6] = fetch_gv(pos + w.yyx);
            gv[7] = fetch_gv(pos + w.yyy);

            #if USE_LPV_BOUNCE
            bc[0] = fetch_av(pos + w.xxx);
            bc[1] = fetch_av(pos + w.xxy);
            bc[2] = fetch_av(pos + w.xyx);
            bc[3] = fetch_av(pos + w.xyy);
            bc[4] = fetch_av(pos + w.yxx);
            bc[5] = fetch_av(pos + w.yxy);
            bc[6] = fetch_av(pos + w.yyx);
            bc[7] = fetch_av(pos + w.yyy);
            #endif    

            gv4[0] = (gv[0]+gv[1]+gv[2]+gv[3])*0.25;
            gv4[1] = (gv[4]+gv[5]+gv[6]+gv[7])*0.25;
            gv4[2] = (gv[0]+gv[4]+gv[1]+gv[5])*0.25;
            gv4[3] = (gv[2]+gv[6]+gv[3]+gv[7])*0.25;
            gv4[4] = (gv[0]+gv[2]+gv[4]+gv[6])*0.25;
            gv4[5] = (gv[1]+gv[3]+gv[5]+gv[7])*0.25;

            #if USE_LPV_BOUNCE
            bc4[0] = (bc[0]+bc[1]+bc[2]+bc[3])*0.25;
            bc4[1] = (bc[4]+bc[5]+bc[6]+bc[7])*0.25;
            bc4[2] = (bc[0]+bc[4]+bc[1]+bc[5])*0.25;
            bc4[3] = (bc[2]+bc[6]+bc[3]+bc[7])*0.25;
            bc4[4] = (bc[0]+bc[2]+bc[4]+bc[6])*0.25;
            bc4[5] = (bc[1]+bc[3]+bc[5]+bc[7])*0.25;
            #endif

            #endif // USE_LPV_OCCLUSION || USE_LPV_BOUNCE 
            
            
            shsumcoeffs += sample_neighbors(0, 2, pos, e.zzx, gv4[0]);
            shsumcoeffs += sample_neighbors(1, 2, pos, e.zzy, gv4[1]);
            shsumcoeffs += sample_neighbors(2, 1, pos, e.zxz, gv4[2]);
            shsumcoeffs += sample_neighbors(3, 1, pos, e.zyz, gv4[3]);
            shsumcoeffs += sample_neighbors(4, 0, pos, e.xzz, gv4[4]);
            shsumcoeffs += sample_neighbors(5, 0, pos, e.yzz, gv4[5]);
        
            fragColor = shsumcoeffs;
        }
    } else {
        fragColor = vec4(0.0,0.0,0.0,0.0);
    }
}