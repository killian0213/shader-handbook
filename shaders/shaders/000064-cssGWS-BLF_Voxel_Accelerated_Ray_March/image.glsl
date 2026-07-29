// Image (image) — BLF Voxel Accelerated Ray March by iY0Yi
// https://www.shadertoy.com/view/cssGWS

// This shader is almost just my attempt to understand jt's voxel experiments.
// "primitives in voxels" https://www.shadertoy.com/view/flyfRz
// "Cast Voxels March Sub-Objects" https://www.shadertoy.com/view/NstSR8
// I tweaked it to make it easier to use in my shaders.
// Also now we can use cuboid as cell of voxel :)

// the size of voxel cell. (only integers are allowed)
//--------------------------------------------------------------------------------------
#define I_CELL_SIZE ivec3(5,3,5)
#define V_CELL_SIZE vec3(I_CELL_SIZE)

#define CELL_NUM vec3(4,4,4)

// get cell by ray position.
//--------------------------------------------------------------------------------------
ivec3 getCell(vec3 p){
    return ivec3(floor(p/V_CELL_SIZE)*V_CELL_SIZE);
}

// define active cells of voxel by sdf.
//--------------------------------------------------------------------------------------
float sdVoxelBound(ivec3 cell){
    vec3 p = vec3(cell);
    return length(p)-max(.1,cos(iTime)+.5)*40.;
}

// return ID of cell.
// "0u" means the cell is empty.
//--------------------------------------------------------------------------------------
uint getCellID(ivec3 cell){
    if(sdVoxelBound(cell)>0.) return 0u;
    if(any(lessThan(cell, -ivec3(CELL_NUM)*I_CELL_SIZE)) || any(greaterThan(cell, ivec3(CELL_NUM)*I_CELL_SIZE))) return 0u;
    return 1u + (uhash(uvec3(cell/I_CELL_SIZE)) % 3u);
}

// the map function of each cell.
//--------------------------------------------------------------------------------------
vec4 sdCell(vec3 p, ivec3 icell){
    vec4 res = vec4(MAX_DIST,MAT_VOID);

    uint id = getCellID(icell);
    
    vec3 cell = vec3(icell);
    float diff = hash13(cell)*PI;
    vec3 rnd = hash33(cell);

    vec2 sp = bx_cossin((iTime*3.+diff)*sign(rnd.x-.5));
    float r = .8;
    vec3 op = vec3(sp.x, abs(sin(5.*(iTime*3.+diff))), sp.y);
    uint underCellId = getCellID(icell-ivec3(0,V_CELL_SIZE.y,0));
    if(id == 1u && (underCellId==2u || underCellId==3u)) res = vec4(sdSphere(p+op*(V_CELL_SIZE*.5-r), r), vec3(1.000,0.902,0.6)+rnd*.002);
    if(id == 2u) res = vec4(sdBoxFrame(p, vec3(.5)*V_CELL_SIZE-.125, .05)-.125, vec3(.3,.8,.5)+rnd*.1);
    if(id == 3u) res = vec4(sdBox(p, vec3(.5)*V_CELL_SIZE-.125)-.125, vec3(.2,.7,.5)+rnd*.1);

    return res;
}

// ray march the cell.
//--------------------------------------------------------------------------------------
vec4 marchCell(vec3 ro, vec3 rd, float tmin, float tmax, ivec3 cell){
    for(float t = tmin; t < tmax;){
        vec4 res = sdCell(ro+rd*t, cell);
        if(res.x<MIN_DIST)return vec4(t, res.yzw);
        t += res.x;
    }
    return vec4(MAX_DIST,MAT_VOID);
}

// main function to attempt to intersect
// http://lodev.org/cgtutor/raycasting.html
//--------------------------------------------------------------------------------------
vec4 intersectVoxel(vec3 ro, vec3 rd){
    ivec3 cell = getCell(ro);
    
    // "Branchless Voxel Raycasting" by fb39ca4
    // https://www.shadertoy.com/view/4dX3zl
    ivec3 rayStep = ivec3(sign(rd))*I_CELL_SIZE;
    vec3 deltaDist = V_CELL_SIZE/abs(rd);
    vec3 sideDist = (sign(rd) * (vec3(cell)-ro)/V_CELL_SIZE + sign(rd)*.5+.5) * deltaDist;

    for (int i=0; i<MAX_RAY_STEPS; i++){
        // if the cell is not empty, do ray marching.
        if(getCellID(cell)>0u){ 
            vec3 p = ro-vec3(cell)-V_CELL_SIZE*.5;
            // bounding box
            vec2 bounds = iBox(p, rd, V_CELL_SIZE*.5);
            // ray marching in the cell
            vec4 res = marchCell(p, rd, bounds.x, bounds.y, cell);
            if(res.x>=bounds.x && res.x<=bounds.y && res.x>0.) return res;
        }
        
        // the branchless tricks
        bvec3 mask = lessThanEqual(sideDist.xyz, min(sideDist.yzx, sideDist.zxy));
        sideDist += vec3(mask) * deltaDist;
        cell += ivec3(vec3(mask)) * rayStep;
    }
    return vec4(MAX_DIST,MAT_VOID);
}

// to calculate ao, mix distances with neighbor cells.
//--------------------------------------------------------------------------------------
float sdCellNeighbors(ivec3 cell, vec3 offset){
    float d = MAX_DIST;
    // kastorp's optimization: traverse only 2x2x2 cells (instead of 3x3x3),
    // chosen depending on where in the cell the current point is located.
    // https://www.shadertoy.com/view/Nl3BDj
    ivec3 off = -ivec3(step(vec3(0), offset));
    for(int z=off.z; z<=off.z+1; z++)
    for(int y=off.y; y<=off.y+1; y++)
    for(int x=off.x; x<=off.x+1; x++){
        ivec3 ncell = cell-ivec3(x,y,z)*I_CELL_SIZE;
        if(getCellID(ncell) > 0u){
            d = min(d, sdCell(offset+vec3(x,y,z)*V_CELL_SIZE, ncell).x);
        }
    }
    return d;
}

// normal calcutation
//--------------------------------------------------------------------------------------
vec3 normalCell(vec3 p, ivec3 cell) {
    vec3 n = vec3(0.0);
    for(int i = 0; i < 4; i++) {
        vec3 e = 0.5773 * (2.0 * vec3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
        n += e * sdCell(p + MIN_DIST * e, cell).x;
    }
    return normalize(n);
}

// "Multi Level AO" by iY0Yi
// https://www.shadertoy.com/view/fsBfDR
float aoSeed = 0.;
const float MAX_SAMP = 4.;
float ao(vec3 p, vec3 n, float radius) {
    float ao = 0.;
    for(float i = 0.; i <= MAX_SAMP; i++) {
        vec2 rnd = hash21(i + 1. + aoSeed);

        float scale = (i + 1.)/MAX_SAMP;
        scale = mix(.0, 1., pow(scale, .5));

        rnd.x = (rnd.x * 2. - 1.) * PI * .5;
        rnd.y = (rnd.y * 2. - 1.) * PI;
        vec3 rd = normalize(n + hash21(i + 2. + aoSeed).xyx);
        rd.xy *= mat2(cos(rnd.x), sin(rnd.x), -sin(rnd.x), cos(rnd.x));
        rd.xz *= mat2(cos(rnd.y), sin(rnd.y), -sin(rnd.y), cos(rnd.y));

        rd *= sign(dot(rd, n));

        float raylen = radius * scale;
        vec3 rndp = p + normalize(n + rd) * raylen;
        ivec3 cell = getCell(rndp);

        float res = sdCellNeighbors(cell, rndp-vec3(cell)-.5*V_CELL_SIZE);
        ao += res;
        aoSeed++;
    }
    return ao/float(MAX_SAMP);
}

// https://hanecci.hatenadiary.org/entry/20130505/p2
// http://www.project-asura.com/program/d3d11/d3d11_006.html
float normalizedBlinnPhong(float shininess, vec3 n, vec3 vd, vec3 ld) {
  float norm_factor = (shininess + 5.) / (2. * PI);
  vec3 h = normalize(-vd + ld);
  return pow(max(0., dot(h, n)), shininess) * norm_factor;
}

vec3 ACESFilm(vec3 x) {
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float e = 0.14;
    return (x * (a * x + b))/(x * (c * x + d) + e);
}

void camera(vec2 uv) {
    const float pY = .5;
    const float cL = 150.;
    const vec3 focus = V_CELL_SIZE*.5;
    const float fov = .1;
    vec3 up = vec3(0, 1, 0);
    vec3 pos = vec3(0, .0, -1) * cL;
    R(pos.xz, iTime*.5);
    
    if(iMouse.z > .5) {
        pos = vec3(
            -sin(iMouse.x/iResolution.x * PI*2. + PI * .5),
            sin(iMouse.y/iResolution.y * PI * 2.),
            -cos(iMouse.x/iResolution.x * PI*2. + PI * .5)
            ) * cL;
        R(pos.xz, PI);
    }
    
    vec3 dir = normalize(focus - pos);
    vec3 target = pos - dir;
    vec3 cw = normalize(target - pos);
    vec3 cu = normalize(cross(cw, up));
    vec3 cv = normalize(cross(cu, cw));
    mat3 camMat = mat3(cu, cv, cw);
    rd = normalize(camMat * normalize(vec3(sin(fov) * uv.x, sin(fov) * uv.y, -cos(fov))));
    ro = pos;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy/iResolution.xy;
    uv = (uv * 2. - 1.);
    uv.x *= iResolution.x/iResolution.y;
    
    // set ray vectors
    camera(uv);
    
    // optimization: skip empty voxels
    ro += rd*iBox(vec3(ro)-V_CELL_SIZE*.5, rd, V_CELL_SIZE*(CELL_NUM+.5)+MIN_DIST ).x;

    // attempt to intersect
    vec4 res = intersectVoxel(ro, rd);

    // sky color
    vec3 col = vec3(.5,.8,.8)*(1./PI)*2.;
    
    // hit
    if(res.x < MAX_DIST){
        vec3 pos = ro+rd*res.x;
        
        // calc normal
        ivec3 cell = getCell(pos+rd*MIN_DIST);
        vec3 n = normalCell(pos-vec3(cell)-.5*V_CELL_SIZE, cell);
        
        vec3 ldir = normalize(vec3(0, 1., 1.));
        R(ldir.xz, -iTime*.5);
        
        // calc shading
        float diff = max(0., dot(n, ldir))*(1./PI);
        float indr = (dot(n, -ldir) * .5 + .5)*(1./PI);
        float rgh = (distance(res.yzw, vec3(1.000,0.902,0.7))<.2) ? .125 : .01;
        float spec = normalizedBlinnPhong(1./rgh, n, rd, ldir);
        float a = ao(pos, n, .1);
        a += ao(pos, n, .9)*.25;
        a /= 2.;
        
        // shadow
        float sdw = step(MAX_DIST,intersectVoxel(pos,ldir).x);

        col = diff*2.8*sdw*vec3(1.000,0.929,0.541);
        col += vec3(.65,.8,.8)*.4*(.3+.7*a);
        col += vec3(.2,.7,.5)*1.*indr*(.3+.7*a);
        #if 0
            col *= .8*(.75+.25*sin(res.yzw*5.+vec3(3.+sin(floor(iTime*.125)),1,2.+sin(2.+floor(iTime*.125)))+floor(iTime*.125)));
        #else
            col *= res.yzw;
        #endif
        col += spec * .25 * sdw;
    }
    col = ACESFilm(col);

    // contrast curve
    col = smoothstep(.05,.9,col);

    fragColor = vec4(pow(col,vec3(.4545)),1);
}
