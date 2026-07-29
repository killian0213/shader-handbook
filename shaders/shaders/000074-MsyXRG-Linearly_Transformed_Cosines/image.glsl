// Image (image) — Linearly Transformed Cosines by XT95
// https://www.shadertoy.com/view/MsyXRG

// -- Real-Time Polygonal-Light Shading with Linearly Transformed Cosines --
// All the code by Eric Heitz's : https://eheitzresearch.wordpress.com/415-2/
// A really fast area light solution with great results

// Ugly port of LUT textures : precomputed low res arrays. If you have a better idea..!
// In fact the low resolution totally breaks the visual :/

#define USE_LUT8
//#define USE_LUT16


float uiSlider(int id){return texture(iChannel0, vec2(float(id)+.5,0.5)/iResolution.xy).r;}
vec3 uiColor(int id){return texture(iChannel0, vec2(float(id)+.5,1.5)/iResolution.xy).rgb;}
float roughness;
vec3  dcolor;
vec3  scolor;

float intensity;
float width;
float height;
float roty;
float rotz;
bool twoSided = false;

const float pi = 3.14159265;

// Tracing and intersection
///////////////////////////

struct Ray
{
    vec3 origin;
    vec3 dir;
};

struct Rect
{
    vec3  center;
    vec3  dirx;
    vec3  diry;
    float halfx;
    float halfy;

    vec4  plane;
};

bool RayPlaneIntersect(Ray ray, vec4 plane, out float t)
{
    t = -dot(plane, vec4(ray.origin, 1.0))/dot(plane.xyz, ray.dir);
    return t > 0.0;
}

bool RayRectIntersect(Ray ray, Rect rect, out float t)
{
    bool intersect = RayPlaneIntersect(ray, rect.plane, t);
    if (intersect)
    {
        vec3 pos  = ray.origin + ray.dir*t;
        vec3 lpos = pos - rect.center;
        
        float x = dot(lpos, rect.dirx);
        float y = dot(lpos, rect.diry);    

        if (abs(x) > rect.halfx || abs(y) > rect.halfy)
            intersect = false;
    }

    return intersect;
}

// Camera functions
///////////////////
mat3 rotate( in vec3 v, in float angle)
{
	float c = cos(angle);
	float s = sin(angle);
	
	return mat3(c + (1.0 - c) * v.x * v.x, (1.0 - c) * v.x * v.y - s * v.z, (1.0 - c) * v.x * v.z + s * v.y,
		(1.0 - c) * v.x * v.y + s * v.z, c + (1.0 - c) * v.y * v.y, (1.0 - c) * v.y * v.z - s * v.x,
		(1.0 - c) * v.x * v.z - s * v.y, (1.0 - c) * v.y * v.z + s * v.x, c + (1.0 - c) * v.z * v.z
		);
}


Ray GenerateCameraRay(vec2 uv, float u1, float u2)
{
    Ray ray;

    // Random jitter within pixel for AA
    vec2 xy = 2.0*(uv)/iResolution.xy - vec2(1.0);
	xy.x *= iResolution.x/iResolution.y;
    ray.dir = normalize(vec3(xy, 2.0));

    float focalDistance = 2.0;
    float ft = focalDistance/ray.dir.z;
    vec3 pFocus = ray.dir*ft;

    ray.origin = vec3(0);
    ray.dir    = normalize(pFocus - ray.origin);

    // Apply camera transform
    ray.origin = vec3(0.,6.,10.);
    ray.dir = rotate(vec3(1.,0.,0.), -0.1745) * ray.dir;

    return ray;
}

vec3 mul(mat3 m, vec3 v)
{
    return m * v;
}

mat3 mul(mat3 m1, mat3 m2)
{
    return m1 * m2;
}

vec3 rotation_y(vec3 v, float a)
{
    vec3 r;
    r.x =  v.x*cos(a) + v.z*sin(a);
    r.y =  v.y;
    r.z = -v.x*sin(a) + v.z*cos(a);
    return r;
}

vec3 rotation_z(vec3 v, float a)
{
    vec3 r;
    r.x =  v.x*cos(a) - v.y*sin(a);
    r.y =  v.x*sin(a) + v.y*cos(a);
    r.z =  v.z;
    return r;
}

vec3 rotation_yz(vec3 v, float ay, float az)
{
    return rotation_z(rotation_y(v, ay), az);
}

// Linearly Transformed Cosines
///////////////////////////////

float IntegrateEdge(vec3 v1, vec3 v2)
{
    float cosTheta = dot(v1, v2);
    float theta = acos(cosTheta);    
    float res = cross(v1, v2).z * ((theta > 0.001) ? theta/sin(theta) : 1.0);

    return res;
}

void ClipQuadToHorizon(inout vec3 L[5], out int n)
{
    // detect clipping config
    int config = 0;
    if (L[0].z > 0.0) config += 1;
    if (L[1].z > 0.0) config += 2;
    if (L[2].z > 0.0) config += 4;
    if (L[3].z > 0.0) config += 8;

    // clip
    n = 0;

    if (config == 0)
    {
        // clip all
    }
    else if (config == 1) // V1 clip V2 V3 V4
    {
        n = 3;
        L[1] = -L[1].z * L[0] + L[0].z * L[1];
        L[2] = -L[3].z * L[0] + L[0].z * L[3];
    }
    else if (config == 2) // V2 clip V1 V3 V4
    {
        n = 3;
        L[0] = -L[0].z * L[1] + L[1].z * L[0];
        L[2] = -L[2].z * L[1] + L[1].z * L[2];
    }
    else if (config == 3) // V1 V2 clip V3 V4
    {
        n = 4;
        L[2] = -L[2].z * L[1] + L[1].z * L[2];
        L[3] = -L[3].z * L[0] + L[0].z * L[3];
    }
    else if (config == 4) // V3 clip V1 V2 V4
    {
        n = 3;
        L[0] = -L[3].z * L[2] + L[2].z * L[3];
        L[1] = -L[1].z * L[2] + L[2].z * L[1];
    }
    else if (config == 5) // V1 V3 clip V2 V4) impossible
    {
        n = 0;
    }
    else if (config == 6) // V2 V3 clip V1 V4
    {
        n = 4;
        L[0] = -L[0].z * L[1] + L[1].z * L[0];
        L[3] = -L[3].z * L[2] + L[2].z * L[3];
    }
    else if (config == 7) // V1 V2 V3 clip V4
    {
        n = 5;
        L[4] = -L[3].z * L[0] + L[0].z * L[3];
        L[3] = -L[3].z * L[2] + L[2].z * L[3];
    }
    else if (config == 8) // V4 clip V1 V2 V3
    {
        n = 3;
        L[0] = -L[0].z * L[3] + L[3].z * L[0];
        L[1] = -L[2].z * L[3] + L[3].z * L[2];
        L[2] =  L[3];
    }
    else if (config == 9) // V1 V4 clip V2 V3
    {
        n = 4;
        L[1] = -L[1].z * L[0] + L[0].z * L[1];
        L[2] = -L[2].z * L[3] + L[3].z * L[2];
    }
    else if (config == 10) // V2 V4 clip V1 V3) impossible
    {
        n = 0;
    }
    else if (config == 11) // V1 V2 V4 clip V3
    {
        n = 5;
        L[4] = L[3];
        L[3] = -L[2].z * L[3] + L[3].z * L[2];
        L[2] = -L[2].z * L[1] + L[1].z * L[2];
    }
    else if (config == 12) // V3 V4 clip V1 V2
    {
        n = 4;
        L[1] = -L[1].z * L[2] + L[2].z * L[1];
        L[0] = -L[0].z * L[3] + L[3].z * L[0];
    }
    else if (config == 13) // V1 V3 V4 clip V2
    {
        n = 5;
        L[4] = L[3];
        L[3] = L[2];
        L[2] = -L[1].z * L[2] + L[2].z * L[1];
        L[1] = -L[1].z * L[0] + L[0].z * L[1];
    }
    else if (config == 14) // V2 V3 V4 clip V1
    {
        n = 5;
        L[4] = -L[0].z * L[3] + L[3].z * L[0];
        L[0] = -L[0].z * L[1] + L[1].z * L[0];
    }
    else if (config == 15) // V1 V2 V3 V4
    {
        n = 4;
    }
    
    if (n == 3)
        L[3] = L[0];
    if (n == 4)
        L[4] = L[0];
}


vec3 LTC_Evaluate(
    vec3 N, vec3 V, vec3 P, mat3 Minv, vec3 points[4], bool twoSided)
{
    // construct orthonormal basis around N
    vec3 T1, T2;
    T1 = normalize(V - N*dot(V, N));
    T2 = cross(N, T1);

    // rotate area light in (T1, T2, N) basis
    Minv = mul(Minv, transpose(mat3(T1, T2, N)));

    // polygon (allocate 5 vertices for clipping)
    vec3 L[5];
    L[0] = mul(Minv, points[0] - P);
    L[1] = mul(Minv, points[1] - P);
    L[2] = mul(Minv, points[2] - P);
    L[3] = mul(Minv, points[3] - P);

    int n;
    ClipQuadToHorizon(L, n);
    
    if (n == 0)
        return vec3(0, 0, 0);

    // project onto sphere
    L[0] = normalize(L[0]);
    L[1] = normalize(L[1]);
    L[2] = normalize(L[2]);
    L[3] = normalize(L[3]);
    L[4] = normalize(L[4]);

    // integrate
    float sum = 0.0;

    sum += IntegrateEdge(L[0], L[1]);
    sum += IntegrateEdge(L[1], L[2]);
    sum += IntegrateEdge(L[2], L[3]);
    if (n >= 4)
        sum += IntegrateEdge(L[3], L[4]);
    if (n == 5)
        sum += IntegrateEdge(L[4], L[0]);

    sum = twoSided ? abs(sum) : max(0.0, sum);

    vec3 Lo_i = vec3(sum, sum, sum);

    return Lo_i;
}

// Scene helpers
////////////////

void InitRect(out Rect rect)
{
    rect.dirx = rotation_yz(vec3(1, 0, 0), roty*2.0*pi, rotz*2.0*pi);
    rect.diry = rotation_yz(vec3(0, 1, 0), roty*2.0*pi, rotz*2.0*pi);

    rect.center = vec3(0, 6, 32);
    rect.halfx  = 0.5*width;
    rect.halfy  = 0.5*height;

    vec3 rectNormal = cross(rect.dirx, rect.diry);
    rect.plane = vec4(rectNormal, -dot(rectNormal, rect.center));
}

void InitRectPoints(Rect rect, out vec3 points[4])
{
    vec3 ex = rect.halfx*rect.dirx;
    vec3 ey = rect.halfy*rect.diry;

    points[0] = rect.center - ex - ey;
    points[1] = rect.center + ex - ey;
    points[2] = rect.center + ex + ey;
    points[3] = rect.center - ex + ey;
}

// Misc. helpers
////////////////

float saturate(float v)
{
    return clamp(v, 0.0, 1.0);
}

vec3 PowVec3(vec3 v, float p)
{
    return vec3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
}

const float gamma = 2.2;

vec3 ToLinear(vec3 v) { return PowVec3(v,     gamma); }
vec3 ToSRGB(vec3 v)   { return PowVec3(v, 1.0/gamma); }

//UGLY CODE
#ifdef USE_LUT8
	#define LUTSIZE 8
#endif
#ifdef USE_LUT16
	#define LUTSIZE 16
#endif
vec4 ltc_mat[LUTSIZE*LUTSIZE]; float ltc_mag[LUTSIZE*LUTSIZE];
void computeLUT();


vec4 getLUTMat( vec2 p )
{
    for(int x=0; x<LUTSIZE; x++)
    for(int y=0; y<LUTSIZE; y++)
    {
        if( x == int(p.x) && y == int(p.y) )
        {
            vec4 a = mix( ltc_mat[y*LUTSIZE+x], ltc_mat[y*LUTSIZE+x+1], fract(p.x));
            vec4 b = mix( ltc_mat[(y+1)*LUTSIZE+x], ltc_mat[(y+1)*LUTSIZE+x+1], fract(p.x));
            return mix(a,b,fract(p.y));
        }
    }
    return vec4(0.);
}
float getLUTMag( vec2 p )
{
    for(int x=0; x<LUTSIZE; x++)
    for(int y=0; y<LUTSIZE; y++)
    {
        if( x == int(p.x) && y == int(p.y) )
        {
            float a = mix( ltc_mag[y*LUTSIZE+x], ltc_mag[y*LUTSIZE+x+1], fract(p.x));
            float b = mix( ltc_mag[(y+1)*LUTSIZE+x], ltc_mag[(y+1)*LUTSIZE+x+1], fract(p.x));
            return mix(a,b,fract(p.y));
        }
    }
    return 0.;
}
//END

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    computeLUT();
    
    //Get UI data
    roughness = uiSlider(0);
    dcolor = uiColor(0);
    scolor = uiColor(1);

    intensity = uiSlider(1)*10.;
    width = uiSlider(2)*15.;
    height = uiSlider(4)*15.;
    roty = uiSlider(5);
    rotz = uiSlider(10);
    
    Rect rect;
    InitRect(rect);

    vec3 points[4];
    InitRectPoints(rect, points);

    vec4 floorPlane = vec4(0, 1, 0, 0);

    vec3 lcol = vec3(intensity);
    vec3 dcol = ToLinear(dcolor);
    vec3 scol = ToLinear(scolor);
    
    vec3 col = vec3(0);

    Ray ray = GenerateCameraRay(fragCoord, 0.0, 0.0);

    float distToFloor;
    bool hitFloor = RayPlaneIntersect(ray, floorPlane, distToFloor);
    if (hitFloor)
    {
        vec3 pos = ray.origin + ray.dir*distToFloor;

        vec3 N = floorPlane.xyz;
        vec3 V = -ray.dir;
        
        float theta = acos(dot(N, V));
        vec2 uv = vec2(roughness, theta/(0.5*pi)) * float(LUTSIZE-1);        
        vec4 t = getLUTMat(uv);
        mat3 Minv = mat3(
            vec3(  1,   0, t.y),
            vec3(  0, t.z,   0),
            vec3(t.w,   0, t.x)
        );
        
        vec3 spec = LTC_Evaluate(N, V, pos, Minv, points, twoSided);
        spec *= getLUTMag(uv);
        
        vec3 diff = LTC_Evaluate(N, V, pos, mat3(1), points, twoSided); 
        
        col  = lcol*(scol*spec + dcol*diff);
        col /= 2.0*pi;
    }

    float distToRect;
    if (RayRectIntersect(ray, rect, distToRect))
        if ((distToRect < distToFloor) || !hitFloor)
            col = lcol;

	vec2 uv = fragCoord.xy / iResolution.xy;
	vec4 ui = texture(iChannel0,uv);
    col = mix(col, ui.rgb, ui.a);
    
    fragColor = vec4(col, 1.0);
}


void computeLUT()
{
#ifdef USE_LUT8
    ltc_mag[0] = 1.000000;ltc_mag[1] = 1.000000;ltc_mag[2] = 0.999138;ltc_mag[3] = 0.953919;ltc_mag[4] = 0.855017;ltc_mag[5] = 0.677721;ltc_mag[6] = 0.475624;ltc_mag[7] = 0.306905;ltc_mag[8] = 1.000000;ltc_mag[9] = 0.999990;ltc_mag[10] = 0.995492;ltc_mag[11] = 0.955938;ltc_mag[12] = 0.852346;ltc_mag[13] = 0.676815;ltc_mag[14] = 0.478562;ltc_mag[15] = 0.311751;ltc_mag[16] = 1.000000;ltc_mag[17] = 0.999952;ltc_mag[18] = 0.993337;ltc_mag[19] = 0.950365;ltc_mag[20] = 0.844905;ltc_mag[21] = 0.674537;ltc_mag[22] = 0.487632;ltc_mag[23] = 0.327273;ltc_mag[24] = 1.000000;ltc_mag[25] = 0.999865;ltc_mag[26] = 0.991766;ltc_mag[27] = 0.942684;ltc_mag[28] = 0.831852;ltc_mag[29] = 0.673589;ltc_mag[30] = 0.505564;ltc_mag[31] = 0.355949;ltc_mag[32] = 1.000000;ltc_mag[33] = 0.999665;ltc_mag[34] = 0.986371;ltc_mag[35] = 0.930421;ltc_mag[36] = 0.813602;ltc_mag[37] = 0.678975;ltc_mag[38] = 0.537882;ltc_mag[39] = 0.403271;ltc_mag[40] = 1.000000;ltc_mag[41] = 0.999025;ltc_mag[42] = 0.973317;ltc_mag[43] = 0.900245;ltc_mag[44] = 0.804126;ltc_mag[45] = 0.703751;ltc_mag[46] = 0.594890;ltc_mag[47] = 0.481143;ltc_mag[48] = 1.000000;ltc_mag[49] = 0.992850;ltc_mag[50] = 0.926124;ltc_mag[51] = 0.860745;ltc_mag[52] = 0.833379;ltc_mag[53] = 0.782873;ltc_mag[54] = 0.703637;ltc_mag[55] = 0.620129;ltc_mag[56] = 0.987461;ltc_mag[57] = 0.938899;ltc_mag[58] = 0.942983;ltc_mag[59] = 0.943682;ltc_mag[60] = 0.943818;ltc_mag[61] = 0.943681;ltc_mag[62] = 0.943351;ltc_mag[63] = 0.942877;	
    ltc_mat[0] = vec4(0.000200, -0.000000, 1.000000, -0.000000);ltc_mat[1] = vec4(0.040821, -0.000000, 1.000000, -0.000000);ltc_mat[2] = vec4(0.163499, -0.000000, 1.000000, -0.000000);ltc_mat[3] = vec4(0.359810, -0.000000, 1.000000, -0.000000);ltc_mat[4] = vec4(0.608219, -0.000000, 1.000000, -0.000000);ltc_mat[5] = vec4(0.849327, -0.000000, 1.000000, -0.000000);ltc_mat[6] = vec4(1.026876, -0.000000, 1.000000, -0.000000);ltc_mat[7] = vec4(1.127918, -0.000000, 1.000000, -0.000000);ltc_mat[8] = vec4(0.000200, -0.000046, 1.052217, 0.228243);ltc_mat[9] = vec4(0.040821, -0.009316, 1.052066, 0.228242);ltc_mat[10] = vec4(0.163218, -0.036566, 1.051517, 0.228141);ltc_mat[11] = vec4(0.360871, -0.077435, 1.049110, 0.226851);ltc_mat[12] = vec4(0.608870, -0.112986, 1.040456, 0.216178);ltc_mat[13] = vec4(0.850681, -0.110371, 1.022363, 0.171798);ltc_mat[14] = vec4(1.033758, -0.063836, 1.011022, 0.089896);ltc_mat[15] = vec4(1.130218, 0.000062, 1.000010, -0.000080);ltc_mat[16] = vec4(0.000200, -0.000096, 1.232269, 0.481573);ltc_mat[17] = vec4(0.040829, -0.019653, 1.232083, 0.481559);ltc_mat[18] = vec4(0.163323, -0.077152, 1.229494, 0.481157);ltc_mat[19] = vec4(0.361362, -0.161748, 1.215935, 0.476966);ltc_mat[20] = vec4(0.602530, -0.224893, 1.149731, 0.444834);ltc_mat[21] = vec4(0.832866, -0.211716, 1.066321, 0.339254);ltc_mat[22] = vec4(1.033638, -0.123274, 1.025543, 0.170803);ltc_mat[23] = vec4(1.137644, 0.000154, 0.999953, -0.000082);ltc_mat[24] = vec4(0.000199, -0.000159, 1.627474, 0.797472);ltc_mat[25] = vec4(0.040836, -0.032524, 1.635685, 0.797401);ltc_mat[26] = vec4(0.164108, -0.127318, 1.628042, 0.795956);ltc_mat[27] = vec4(0.365844, -0.258932, 1.575327, 0.783120);ltc_mat[28] = vec4(0.602895, -0.339455, 1.372632, 0.710306);ltc_mat[29] = vec4(0.825683, -0.302224, 1.158343, 0.512880);ltc_mat[30] = vec4(1.030563, -0.173519, 1.049980, 0.243539);ltc_mat[31] = vec4(1.151713, 0.000105, 0.999957, -0.000055);ltc_mat[32] = vec4(0.000198, -0.000248, 2.529443, 1.253956);ltc_mat[33] = vec4(0.040880, -0.051100, 2.570697, 1.253684);ltc_mat[34] = vec4(0.166706, -0.198049, 2.542881, 1.248409);ltc_mat[35] = vec4(0.380361, -0.384441, 2.334701, 1.206127);ltc_mat[36] = vec4(0.617299, -0.459699, 1.772357, 1.025249);ltc_mat[37] = vec4(0.835445, -0.380695, 1.304201, 0.680722);ltc_mat[38] = vec4(1.040850, -0.213042, 1.089431, 0.306573);ltc_mat[39] = vec4(1.176060, 0.000010, 1.000023, -0.000021);ltc_mat[40] = vec4(0.000187, -0.000388, 4.301116, 2.076506);ltc_mat[41] = vec4(0.041070, -0.084546, 5.305590, 2.075270);ltc_mat[42] = vec4(0.175521, -0.321638, 5.161014, 2.051541);ltc_mat[43] = vec4(0.413187, -0.560077, 4.055352, 1.869406);ltc_mat[44] = vec4(0.665130, -0.580464, 2.432246, 1.376237);ltc_mat[45] = vec4(0.870094, -0.441204, 1.506300, 0.819691);ltc_mat[46] = vec4(1.068578, -0.241436, 1.137736, 0.354430);ltc_mat[47] = vec4(1.219174, -0.000534, 1.000063, 0.000162);ltc_mat[48] = vec4(0.000144, -0.000631, 6.468958, 4.381222);ltc_mat[49] = vec4(0.042200, -0.177353, 20.085962, 4.369584);ltc_mat[50] = vec4(0.209979, -0.606367, 16.868328, 4.106197);ltc_mat[51] = vec4(0.500901, -0.795643, 8.099620, 2.893355);ltc_mat[52] = vec4(0.769693, -0.688227, 3.439625, 1.659662);ltc_mat[53] = vec4(0.955036, -0.470746, 1.760819, 0.883184);ltc_mat[54] = vec4(1.134532, -0.254869, 1.190455, 0.377490);ltc_mat[55] = vec4(1.308330, -0.002944, 0.999844, 0.001275);ltc_mat[56] = vec4(0.000102, -0.118482, 1184.816772, 1184.816284);ltc_mat[57] = vec4(0.319603, -3.097308, 7133.888672, 23.645655);ltc_mat[58] = vec4(0.546638, -1.442077, 133.966263, 8.593670);ltc_mat[59] = vec4(0.837342, -1.129903, 20.226521, 3.658263);ltc_mat[60] = vec4(1.004258, -0.809128, 5.700182, 1.768790);ltc_mat[61] = vec4(1.117055, -0.531464, 2.269246, 0.923613);ltc_mat[62] = vec4(1.336692, -0.312752, 1.241618, 0.414403);ltc_mat[63] = vec4(1.670654, -0.056394, 0.998759, 0.033416);
#endif
#ifdef USE_LUT16
    ltc_mag[0] = 1.000000;ltc_mag[1] = 1.000000;ltc_mag[2] = 1.000000;ltc_mag[3] = 0.999995;ltc_mag[4] = 0.999717;ltc_mag[5] = 0.979309;ltc_mag[6] = 0.970877;ltc_mag[7] = 0.938201;ltc_mag[8] = 0.889932;ltc_mag[9] = 0.824544;ltc_mag[10] = 0.743058;ltc_mag[11] = 0.650845;ltc_mag[12] = 0.554957;ltc_mag[13] = 0.463155;ltc_mag[14] = 0.379312;ltc_mag[15] = 0.306905;ltc_mag[16] = 1.000000;ltc_mag[17] = 1.000000;ltc_mag[18] = 0.999998;ltc_mag[19] = 0.999977;ltc_mag[20] = 0.999655;ltc_mag[21] = 0.979310;ltc_mag[22] = 0.968313;ltc_mag[23] = 0.937060;ltc_mag[24] = 0.889471;ltc_mag[25] = 0.824075;ltc_mag[26] = 0.742592;ltc_mag[27] = 0.650615;ltc_mag[28] = 0.555398;ltc_mag[29] = 0.463696;ltc_mag[30] = 0.380333;ltc_mag[31] = 0.307881;ltc_mag[32] = 1.000000;ltc_mag[33] = 1.000000;ltc_mag[34] = 0.999993;ltc_mag[35] = 0.999948;ltc_mag[36] = 0.999420;ltc_mag[37] = 0.984176;ltc_mag[38] = 0.967133;ltc_mag[39] = 0.935012;ltc_mag[40] = 0.887660;ltc_mag[41] = 0.822522;ltc_mag[42] = 0.741349;ltc_mag[43] = 0.650340;ltc_mag[44] = 0.556263;ltc_mag[45] = 0.465640;ltc_mag[46] = 0.383098;ltc_mag[47] = 0.311128;ltc_mag[48] = 1.000000;ltc_mag[49] = 0.999999;ltc_mag[50] = 0.999982;ltc_mag[51] = 0.999897;ltc_mag[52] = 0.998274;ltc_mag[53] = 0.986417;ltc_mag[54] = 0.965250;ltc_mag[55] = 0.934238;ltc_mag[56] = 0.885653;ltc_mag[57] = 0.819686;ltc_mag[58] = 0.739402;ltc_mag[59] = 0.649857;ltc_mag[60] = 0.557797;ltc_mag[61] = 0.469017;ltc_mag[62] = 0.387811;ltc_mag[63] = 0.316611;ltc_mag[64] = 1.000000;ltc_mag[65] = 0.999998;ltc_mag[66] = 0.999967;ltc_mag[67] = 0.999817;ltc_mag[68] = 0.995607;ltc_mag[69] = 0.986465;ltc_mag[70] = 0.961843;ltc_mag[71] = 0.931931;ltc_mag[72] = 0.881713;ltc_mag[73] = 0.815883;ltc_mag[74] = 0.736814;ltc_mag[75] = 0.649441;ltc_mag[76] = 0.560136;ltc_mag[77] = 0.473984;ltc_mag[78] = 0.394722;ltc_mag[79] = 0.324550;ltc_mag[80] = 1.000000;ltc_mag[81] = 0.999997;ltc_mag[82] = 0.999947;ltc_mag[83] = 0.999704;ltc_mag[84] = 0.994666;ltc_mag[85] = 0.985101;ltc_mag[86] = 0.960790;ltc_mag[87] = 0.927560;ltc_mag[88] = 0.876611;ltc_mag[89] = 0.811246;ltc_mag[90] = 0.733686;ltc_mag[91] = 0.649431;ltc_mag[92] = 0.563766;ltc_mag[93] = 0.480872;ltc_mag[94] = 0.404021;ltc_mag[95] = 0.335182;ltc_mag[96] = 1.000000;ltc_mag[97] = 0.999993;ltc_mag[98] = 0.999918;ltc_mag[99] = 0.999524;ltc_mag[100] = 0.993965;ltc_mag[101] = 0.983847;ltc_mag[102] = 0.960105;ltc_mag[103] = 0.920983;ltc_mag[104] = 0.871218;ltc_mag[105] = 0.805245;ltc_mag[106] = 0.730155;ltc_mag[107] = 0.650095;ltc_mag[108] = 0.568976;ltc_mag[109] = 0.490011;ltc_mag[110] = 0.416071;ltc_mag[111] = 0.348950;ltc_mag[112] = 1.000000;ltc_mag[113] = 0.999993;ltc_mag[114] = 0.999871;ltc_mag[115] = 0.999216;ltc_mag[116] = 0.993285;ltc_mag[117] = 0.981230;ltc_mag[118] = 0.957149;ltc_mag[119] = 0.912841;ltc_mag[120] = 0.863026;ltc_mag[121] = 0.798812;ltc_mag[122] = 0.727721;ltc_mag[123] = 0.652386;ltc_mag[124] = 0.576345;ltc_mag[125] = 0.502021;ltc_mag[126] = 0.431459;ltc_mag[127] = 0.366428;ltc_mag[128] = 1.000000;ltc_mag[129] = 0.999988;ltc_mag[130] = 0.999799;ltc_mag[131] = 0.997368;ltc_mag[132] = 0.990993;ltc_mag[133] = 0.977585;ltc_mag[134] = 0.951576;ltc_mag[135] = 0.907513;ltc_mag[136] = 0.852047;ltc_mag[137] = 0.792675;ltc_mag[138] = 0.725179;ltc_mag[139] = 0.656814;ltc_mag[140] = 0.586781;ltc_mag[141] = 0.517674;ltc_mag[142] = 0.451016;ltc_mag[143] = 0.388326;ltc_mag[144] = 1.000000;ltc_mag[145] = 0.999983;ltc_mag[146] = 0.999697;ltc_mag[147] = 0.995895;ltc_mag[148] = 0.988571;ltc_mag[149] = 0.971928;ltc_mag[150] = 0.942828;ltc_mag[151] = 0.899020;ltc_mag[152] = 0.840963;ltc_mag[153] = 0.785548;ltc_mag[154] = 0.726594;ltc_mag[155] = 0.663778;ltc_mag[156] = 0.601271;ltc_mag[157] = 0.537922;ltc_mag[158] = 0.475569;ltc_mag[159] = 0.415940;ltc_mag[160] = 1.000000;ltc_mag[161] = 0.999970;ltc_mag[162] = 0.999514;ltc_mag[163] = 0.994886;ltc_mag[164] = 0.984282;ltc_mag[165] = 0.963160;ltc_mag[166] = 0.929981;ltc_mag[167] = 0.886619;ltc_mag[168] = 0.835011;ltc_mag[169] = 0.779061;ltc_mag[170] = 0.730448;ltc_mag[171] = 0.677540;ltc_mag[172] = 0.620700;ltc_mag[173] = 0.564181;ltc_mag[174] = 0.506662;ltc_mag[175] = 0.450645;ltc_mag[176] = 1.000000;ltc_mag[177] = 0.999952;ltc_mag[178] = 0.999163;ltc_mag[179] = 0.991924;ltc_mag[180] = 0.976946;ltc_mag[181] = 0.948976;ltc_mag[182] = 0.911852;ltc_mag[183] = 0.871720;ltc_mag[184] = 0.830537;ltc_mag[185] = 0.785688;ltc_mag[186] = 0.738647;ltc_mag[187] = 0.696321;ltc_mag[188] = 0.649759;ltc_mag[189] = 0.598576;ltc_mag[190] = 0.546948;ltc_mag[191] = 0.495355;ltc_mag[192] = 1.000000;ltc_mag[193] = 0.999905;ltc_mag[194] = 0.996815;ltc_mag[195] = 0.986701;ltc_mag[196] = 0.962382;ltc_mag[197] = 0.925918;ltc_mag[198] = 0.888385;ltc_mag[199] = 0.857635;ltc_mag[200] = 0.831095;ltc_mag[201] = 0.802060;ltc_mag[202] = 0.766993;ltc_mag[203] = 0.726743;ltc_mag[204] = 0.685065;ltc_mag[205] = 0.644827;ltc_mag[206] = 0.600405;ltc_mag[207] = 0.553886;ltc_mag[208] = 1.000000;ltc_mag[209] = 0.999780;ltc_mag[210] = 0.993959;ltc_mag[211] = 0.972777;ltc_mag[212] = 0.932627;ltc_mag[213] = 0.891746;ltc_mag[214] = 0.866246;ltc_mag[215] = 0.853629;ltc_mag[216] = 0.844259;ltc_mag[217] = 0.831159;ltc_mag[218] = 0.810666;ltc_mag[219] = 0.782735;ltc_mag[220] = 0.748451;ltc_mag[221] = 0.710160;ltc_mag[222] = 0.669797;ltc_mag[223] = 0.632054;ltc_mag[224] = 1.000000;ltc_mag[225] = 0.999071;ltc_mag[226] = 0.978305;ltc_mag[227] = 0.923456;ltc_mag[228] = 0.878693;ltc_mag[229] = 0.866629;ltc_mag[230] = 0.870987;ltc_mag[231] = 0.877527;ltc_mag[232] = 0.880450;ltc_mag[233] = 0.878156;ltc_mag[234] = 0.869582;ltc_mag[235] = 0.855647;ltc_mag[236] = 0.837287;ltc_mag[237] = 0.815034;ltc_mag[238] = 0.789895;ltc_mag[239] = 0.762613;ltc_mag[240] = 0.987461;ltc_mag[241] = 0.919155;ltc_mag[242] = 0.938078;ltc_mag[243] = 0.941585;ltc_mag[244] = 0.942787;ltc_mag[245] = 0.943329;ltc_mag[246] = 0.943609;ltc_mag[247] = 0.943753;ltc_mag[248] = 0.943813;ltc_mag[249] = 0.943809;ltc_mag[250] = 0.943751;ltc_mag[251] = 0.943646;ltc_mag[252] = 0.943503;ltc_mag[253] = 0.943324;ltc_mag[254] = 0.943113;ltc_mag[255] = 0.942877;
    ltc_mat[0] = vec4(0.000200, -0.000000, 1.000000, -0.000000);ltc_mat[1] = vec4(0.008889, -0.000000, 1.000000, -0.000000);ltc_mat[2] = vec4(0.035559, -0.000000, 1.000000, -0.000000);ltc_mat[3] = vec4(0.080038, -0.000000, 1.000000, -0.000000);ltc_mat[4] = vec4(0.142411, -0.000000, 1.000000, -0.000000);ltc_mat[5] = vec4(0.220033, -0.000000, 1.000000, -0.000000);ltc_mat[6] = vec4(0.316278, -0.000000, 1.000000, -0.000000);ltc_mat[7] = vec4(0.423690, -0.000000, 1.000000, -0.000000);ltc_mat[8] = vec4(0.539870, -0.000000, 1.000000, -0.000000);ltc_mat[9] = vec4(0.659130, -0.000000, 1.000000, -0.000000);ltc_mat[10] = vec4(0.773957, -0.000000, 1.000000, -0.000000);ltc_mat[11] = vec4(0.877617, -0.000000, 1.000000, -0.000000);ltc_mat[12] = vec4(0.965329, -0.000000, 1.000000, -0.000000);ltc_mat[13] = vec4(1.036009, -0.000000, 1.000000, -0.000000);ltc_mat[14] = vec4(1.089483, -0.000000, 1.000000, -0.000000);ltc_mat[15] = vec4(1.127918, -0.000000, 1.000000, -0.000000);ltc_mat[16] = vec4(0.000200, -0.000021, 1.010198, 0.105104);ltc_mat[17] = vec4(0.008889, -0.000934, 1.011053, 0.105104);ltc_mat[18] = vec4(0.035558, -0.003737, 1.011059, 0.105104);ltc_mat[19] = vec4(0.080038, -0.008411, 1.011020, 0.105103);ltc_mat[20] = vec4(0.142402, -0.014951, 1.010968, 0.105098);ltc_mat[21] = vec4(0.220021, -0.023060, 1.010840, 0.105076);ltc_mat[22] = vec4(0.315854, -0.031374, 1.010587, 0.104709);ltc_mat[23] = vec4(0.423539, -0.040928, 1.010182, 0.104002);ltc_mat[24] = vec4(0.540085, -0.049016, 1.009474, 0.102065);ltc_mat[25] = vec4(0.659616, -0.054144, 1.008563, 0.097708);ltc_mat[26] = vec4(0.775103, -0.054571, 1.007611, 0.089324);ltc_mat[27] = vec4(0.879842, -0.050065, 1.006683, 0.076483);ltc_mat[28] = vec4(0.968356, -0.040660, 1.005082, 0.059225);ltc_mat[29] = vec4(1.038468, -0.027956, 1.003079, 0.039444);ltc_mat[30] = vec4(1.090680, -0.013968, 1.001058, 0.019119);ltc_mat[31] = vec4(1.128415, 0.000027, 1.000054, 0.000016);ltc_mat[32] = vec4(0.000200, -0.000042, 1.043132, 0.212556);ltc_mat[33] = vec4(0.008888, -0.001889, 1.045141, 0.212553);ltc_mat[34] = vec4(0.035560, -0.007558, 1.045255, 0.212554);ltc_mat[35] = vec4(0.080034, -0.017006, 1.045084, 0.212550);ltc_mat[36] = vec4(0.142377, -0.030196, 1.044834, 0.212529);ltc_mat[37] = vec4(0.220904, -0.045718, 1.044263, 0.212328);ltc_mat[38] = vec4(0.315788, -0.064371, 1.043310, 0.211852);ltc_mat[39] = vec4(0.423366, -0.083475, 1.041445, 0.210375);ltc_mat[40] = vec4(0.540176, -0.099041, 1.037930, 0.206062);ltc_mat[41] = vec4(0.659997, -0.108477, 1.032911, 0.196592);ltc_mat[42] = vec4(0.775012, -0.108985, 1.025381, 0.178991);ltc_mat[43] = vec4(0.879518, -0.099376, 1.018116, 0.151882);ltc_mat[44] = vec4(0.970072, -0.080849, 1.013279, 0.117308);ltc_mat[45] = vec4(1.042446, -0.055893, 1.009345, 0.078317);ltc_mat[46] = vec4(1.093981, -0.027785, 1.004134, 0.038049);ltc_mat[47] = vec4(1.129939, 0.000089, 0.999986, -0.000029);ltc_mat[48] = vec4(0.000200, -0.000065, 1.106594, 0.324918);ltc_mat[49] = vec4(0.008889, -0.002888, 1.105498, 0.324918);ltc_mat[50] = vec4(0.035558, -0.011552, 1.105520, 0.324914);ltc_mat[51] = vec4(0.080032, -0.025983, 1.105361, 0.324897);ltc_mat[52] = vec4(0.142314, -0.045947, 1.104717, 0.324829);ltc_mat[53] = vec4(0.221455, -0.069973, 1.103424, 0.324476);ltc_mat[54] = vec4(0.315699, -0.098456, 1.100968, 0.323651);ltc_mat[55] = vec4(0.424268, -0.125858, 1.096258, 0.320723);ltc_mat[56] = vec4(0.540688, -0.149040, 1.086388, 0.313357);ltc_mat[57] = vec4(0.657380, -0.162319, 1.068415, 0.297043);ltc_mat[58] = vec4(0.768810, -0.161556, 1.046659, 0.266948);ltc_mat[59] = vec4(0.873065, -0.146802, 1.030547, 0.224205);ltc_mat[60] = vec4(0.967024, -0.119456, 1.021017, 0.172057);ltc_mat[61] = vec4(1.044423, -0.082918, 1.015845, 0.115585);ltc_mat[62] = vec4(1.098636, -0.041315, 1.008504, 0.056612);ltc_mat[63] = vec4(1.132608, 0.000070, 1.000057, -0.000099);ltc_mat[64] = vec4(0.000200, -0.000089, 1.197685, 0.445227);ltc_mat[65] = vec4(0.008889, -0.003957, 1.198210, 0.445226);ltc_mat[66] = vec4(0.035559, -0.015827, 1.198197, 0.445217);ltc_mat[67] = vec4(0.080031, -0.035579, 1.197705, 0.445175);ltc_mat[68] = vec4(0.142264, -0.062487, 1.196664, 0.444993);ltc_mat[69] = vec4(0.221849, -0.095749, 1.194123, 0.444390);ltc_mat[70] = vec4(0.315691, -0.133989, 1.189136, 0.442917);ltc_mat[71] = vec4(0.424895, -0.170191, 1.177294, 0.437793);ltc_mat[72] = vec4(0.538516, -0.199766, 1.151034, 0.425284);ltc_mat[73] = vec4(0.651697, -0.214708, 1.114753, 0.400110);ltc_mat[74] = vec4(0.760693, -0.211752, 1.078880, 0.357627);ltc_mat[75] = vec4(0.863433, -0.191412, 1.050120, 0.297620);ltc_mat[76] = vec4(0.959872, -0.155709, 1.031110, 0.224926);ltc_mat[77] = vec4(1.044851, -0.108544, 1.022578, 0.150121);ltc_mat[78] = vec4(1.104064, -0.054450, 1.013592, 0.074418);ltc_mat[79] = vec4(1.136289, 0.000158, 0.999997, -0.000024);ltc_mat[80] = vec4(0.000200, -0.000115, 1.333168, 0.577350);ltc_mat[81] = vec4(0.008889, -0.005132, 1.333357, 0.577347);ltc_mat[82] = vec4(0.035562, -0.020521, 1.333256, 0.577326);ltc_mat[83] = vec4(0.080061, -0.046108, 1.332649, 0.577240);ltc_mat[84] = vec4(0.142399, -0.080897, 1.330840, 0.576904);ltc_mat[85] = vec4(0.222394, -0.123651, 1.326271, 0.575823);ltc_mat[86] = vec4(0.316991, -0.171541, 1.315336, 0.572991);ltc_mat[87] = vec4(0.425000, -0.217053, 1.289993, 0.564857);ltc_mat[88] = vec4(0.537294, -0.251374, 1.242604, 0.546624);ltc_mat[89] = vec4(0.648553, -0.266626, 1.182411, 0.510690);ltc_mat[90] = vec4(0.755627, -0.260509, 1.125525, 0.452347);ltc_mat[91] = vec4(0.857208, -0.233678, 1.079633, 0.372433);ltc_mat[92] = vec4(0.953742, -0.189188, 1.048268, 0.278375);ltc_mat[93] = vec4(1.044680, -0.132424, 1.030346, 0.182196);ltc_mat[94] = vec4(1.110309, -0.066805, 1.019193, 0.091049);ltc_mat[95] = vec4(1.141452, 0.000114, 0.999929, -0.000066);ltc_mat[96] = vec4(0.000200, -0.000145, 1.518584, 0.726544);ltc_mat[97] = vec4(0.008889, -0.006458, 1.527746, 0.726536);ltc_mat[98] = vec4(0.035562, -0.025816, 1.527342, 0.726500);ltc_mat[99] = vec4(0.080101, -0.057967, 1.526773, 0.726327);ltc_mat[100] = vec4(0.142658, -0.101633, 1.523286, 0.725710);ltc_mat[101] = vec4(0.223284, -0.155053, 1.515425, 0.723851);ltc_mat[102] = vec4(0.319826, -0.213091, 1.496106, 0.718798);ltc_mat[103] = vec4(0.426167, -0.267494, 1.448783, 0.707159);ltc_mat[104] = vec4(0.539127, -0.304774, 1.369640, 0.679365);ltc_mat[105] = vec4(0.648133, -0.319235, 1.275229, 0.628699);ltc_mat[106] = vec4(0.753290, -0.308002, 1.187951, 0.549834);ltc_mat[107] = vec4(0.853423, -0.273227, 1.117805, 0.447358);ltc_mat[108] = vec4(0.949891, -0.220011, 1.069607, 0.330918);ltc_mat[109] = vec4(1.043926, -0.154424, 1.040714, 0.212954);ltc_mat[110] = vec4(1.117527, -0.078402, 1.025177, 0.106607);ltc_mat[111] = vec4(1.148244, 0.000154, 0.999912, -0.000094);ltc_mat[112] = vec4(0.000200, -0.000180, 1.808295, 0.900398);ltc_mat[113] = vec4(0.008890, -0.008004, 1.810867, 0.900395);ltc_mat[114] = vec4(0.035568, -0.031986, 1.809942, 0.900323);ltc_mat[115] = vec4(0.080172, -0.071745, 1.808488, 0.899995);ltc_mat[116] = vec4(0.143115, -0.125699, 1.802430, 0.898880);ltc_mat[117] = vec4(0.224742, -0.190926, 1.788151, 0.895635);ltc_mat[118] = vec4(0.323459, -0.260464, 1.753135, 0.887096);ltc_mat[119] = vec4(0.429709, -0.322673, 1.671908, 0.868820);ltc_mat[120] = vec4(0.542848, -0.361458, 1.542328, 0.826512);ltc_mat[121] = vec4(0.651105, -0.371741, 1.397676, 0.753429);ltc_mat[122] = vec4(0.755288, -0.352921, 1.267091, 0.648577);ltc_mat[123] = vec4(0.854131, -0.309892, 1.166239, 0.520298);ltc_mat[124] = vec4(0.950567, -0.248426, 1.097868, 0.380820);ltc_mat[125] = vec4(1.045393, -0.173791, 1.054109, 0.242284);ltc_mat[126] = vec4(1.126261, -0.088985, 1.031606, 0.120863);ltc_mat[127] = vec4(1.157047, 0.000134, 1.000057, -0.000106);ltc_mat[128] = vec4(0.000205, -0.000228, 2.319357, 1.110603);ltc_mat[129] = vec4(0.008891, -0.009873, 2.233277, 1.110594);ltc_mat[130] = vec4(0.035590, -0.039453, 2.233160, 1.110467);ltc_mat[131] = vec4(0.080335, -0.088217, 2.228793, 1.109843);ltc_mat[132] = vec4(0.143925, -0.154357, 2.218054, 1.107816);ltc_mat[133] = vec4(0.227220, -0.233620, 2.192165, 1.102112);ltc_mat[134] = vec4(0.328663, -0.315496, 2.124780, 1.087479);ltc_mat[135] = vec4(0.438073, -0.382681, 1.977735, 1.055260);ltc_mat[136] = vec4(0.548584, -0.421597, 1.772177, 0.991389);ltc_mat[137] = vec4(0.658463, -0.423809, 1.552600, 0.885680);ltc_mat[138] = vec4(0.760458, -0.397037, 1.366707, 0.749323);ltc_mat[139] = vec4(0.858841, -0.343659, 1.224969, 0.590730);ltc_mat[140] = vec4(0.953790, -0.273399, 1.129419, 0.427225);ltc_mat[141] = vec4(1.050723, -0.191173, 1.070699, 0.269484);ltc_mat[142] = vec4(1.136994, -0.098301, 1.038687, 0.133390);ltc_mat[143] = vec4(1.168201, 0.000092, 0.999988, -0.000023);ltc_mat[144] = vec4(0.000207, -0.000285, 3.035475, 1.376369);ltc_mat[145] = vec4(0.008890, -0.012234, 2.894652, 1.376351);ltc_mat[146] = vec4(0.035503, -0.048724, 2.877935, 1.376254);ltc_mat[147] = vec4(0.080635, -0.109069, 2.885150, 1.374925);ltc_mat[148] = vec4(0.145345, -0.190477, 2.865479, 1.371136);ltc_mat[149] = vec4(0.231360, -0.286312, 2.813700, 1.360647);ltc_mat[150] = vec4(0.336535, -0.380943, 2.675665, 1.334194);ltc_mat[151] = vec4(0.449809, -0.450381, 2.404360, 1.276167);ltc_mat[152] = vec4(0.559352, -0.483702, 2.071935, 1.175233);ltc_mat[153] = vec4(0.669162, -0.476676, 1.747295, 1.025267);ltc_mat[154] = vec4(0.772178, -0.436382, 1.483158, 0.845947);ltc_mat[155] = vec4(0.867520, -0.375043, 1.293919, 0.657185);ltc_mat[156] = vec4(0.961683, -0.295233, 1.166830, 0.468837);ltc_mat[157] = vec4(1.058525, -0.205999, 1.088960, 0.293683);ltc_mat[158] = vec4(1.150910, -0.106602, 1.046242, 0.144024);ltc_mat[159] = vec4(1.182903, 0.000219, 1.000051, -0.000066);ltc_mat[160] = vec4(0.000205, -0.000354, 4.090361, 1.732025);ltc_mat[161] = vec4(0.008891, -0.015395, 3.999569, 1.731999);ltc_mat[162] = vec4(0.035651, -0.061466, 3.994824, 1.731529);ltc_mat[163] = vec4(0.081183, -0.137048, 3.982212, 1.729159);ltc_mat[164] = vec4(0.147890, -0.238222, 3.940577, 1.721663);ltc_mat[165] = vec4(0.238393, -0.354396, 3.825064, 1.700962);ltc_mat[166] = vec4(0.348459, -0.460080, 3.513971, 1.649010);ltc_mat[167] = vec4(0.466917, -0.527502, 3.008729, 1.541454);ltc_mat[168] = vec4(0.581798, -0.548104, 2.462442, 1.374466);ltc_mat[169] = vec4(0.684965, -0.528665, 1.987500, 1.169501);ltc_mat[170] = vec4(0.788480, -0.474403, 1.622773, 0.939095);ltc_mat[171] = vec4(0.883373, -0.399648, 1.371290, 0.713688);ltc_mat[172] = vec4(0.972402, -0.314310, 1.207963, 0.505745);ltc_mat[173] = vec4(1.070508, -0.217952, 1.108812, 0.314264);ltc_mat[174] = vec4(1.167783, -0.113897, 1.052839, 0.153430);ltc_mat[175] = vec4(1.201838, -0.000175, 1.000102, 0.000122);ltc_mat[176] = vec4(0.000182, -0.000408, 4.465641, 2.246014);ltc_mat[177] = vec4(0.008894, -0.019965, 6.053748, 2.245986);ltc_mat[178] = vec4(0.035761, -0.079704, 6.037868, 2.244851);ltc_mat[179] = vec4(0.082244, -0.177153, 6.004071, 2.239702);ltc_mat[180] = vec4(0.152629, -0.305967, 5.901763, 2.223206);ltc_mat[181] = vec4(0.250076, -0.445606, 5.572710, 2.176924);ltc_mat[182] = vec4(0.367232, -0.557046, 4.828013, 2.062868);ltc_mat[183] = vec4(0.491527, -0.613045, 3.855389, 1.857274);ltc_mat[184] = vec4(0.612133, -0.614251, 2.963375, 1.585410);ltc_mat[185] = vec4(0.718322, -0.573696, 2.270186, 1.297383);ltc_mat[186] = vec4(0.810408, -0.509045, 1.786037, 1.022843);ltc_mat[187] = vec4(0.902686, -0.422909, 1.459304, 0.764157);ltc_mat[188] = vec4(0.993908, -0.327291, 1.255075, 0.533327);ltc_mat[189] = vec4(1.088057, -0.228315, 1.129535, 0.330989);ltc_mat[190] = vec4(1.190195, -0.119510, 1.059789, 0.160637);ltc_mat[191] = vec4(1.227317, 0.000235, 0.999851, 0.000016);ltc_mat[192] = vec4(0.000164, -0.000503, 5.293105, 3.077621);ltc_mat[193] = vec4(0.008895, -0.027352, 10.469983, 3.077425);ltc_mat[194] = vec4(0.035984, -0.108966, 10.448308, 3.074616);ltc_mat[195] = vec4(0.084496, -0.241460, 10.348615, 3.061411);ltc_mat[196] = vec4(0.162047, -0.410303, 9.980741, 3.017045);ltc_mat[197] = vec4(0.269924, -0.570517, 8.791401, 2.887105);ltc_mat[198] = vec4(0.397298, -0.673387, 6.906163, 2.610143);ltc_mat[199] = vec4(0.529570, -0.705743, 5.040496, 2.214274);ltc_mat[200] = vec4(0.655350, -0.680781, 3.601354, 1.791052);ltc_mat[201] = vec4(0.764641, -0.616027, 2.610109, 1.404757);ltc_mat[202] = vec4(0.854902, -0.530548, 1.965555, 1.074764);ltc_mat[203] = vec4(0.932581, -0.438693, 1.557097, 0.799008);ltc_mat[204] = vec4(1.012808, -0.343260, 1.304194, 0.560047);ltc_mat[205] = vec4(1.114602, -0.236086, 1.151705, 0.343508);ltc_mat[206] = vec4(1.221350, -0.121970, 1.065982, 0.165171);ltc_mat[207] = vec4(1.263520, 0.000235, 1.000070, -0.000162);ltc_mat[208] = vec4(0.000140, -0.000661, 6.755595, 4.704470);ltc_mat[209] = vec4(0.008917, -0.041859, 23.185562, 4.703964);ltc_mat[210] = vec4(0.036622, -0.166130, 23.023041, 4.693710);ltc_mat[211] = vec4(0.090453, -0.363370, 22.487141, 4.644106);ltc_mat[212] = vec4(0.182204, -0.583942, 19.991449, 4.460125);ltc_mat[213] = vec4(0.307022, -0.739456, 15.005686, 3.982741);ltc_mat[214] = vec4(0.449611, -0.807855, 10.181218, 3.280072);ltc_mat[215] = vec4(0.591065, -0.802528, 6.677411, 2.568557);ltc_mat[216] = vec4(0.716057, -0.742778, 4.401914, 1.962837);ltc_mat[217] = vec4(0.822156, -0.653710, 3.013064, 1.480438);ltc_mat[218] = vec4(0.908317, -0.548941, 2.167578, 1.103301);ltc_mat[219] = vec4(0.983767, -0.441434, 1.659860, 0.804935);ltc_mat[220] = vec4(1.062802, -0.337561, 1.357608, 0.558419);ltc_mat[221] = vec4(1.159019, -0.237893, 1.172514, 0.347479);ltc_mat[222] = vec4(1.266213, -0.133130, 1.071717, 0.171611);ltc_mat[223] = vec4(1.317598, -0.006755, 0.999856, 0.003237);ltc_mat[224] = vec4(0.000111, -0.001053, 10.587459, 9.513545);ltc_mat[225] = vec4(0.008481, -0.079989, 74.611252, 9.446982);ltc_mat[226] = vec4(0.038485, -0.320126, 85.505035, 9.380105);ltc_mat[227] = vec4(0.111758, -0.653930, 75.570328, 8.882535);ltc_mat[228] = vec4(0.233975, -0.865266, 47.568932, 7.306486);ltc_mat[229] = vec4(0.393141, -0.962179, 27.331427, 5.425194);ltc_mat[230] = vec4(0.553720, -0.963848, 15.483647, 3.911389);ltc_mat[231] = vec4(0.689320, -0.895885, 8.935380, 2.827276);ltc_mat[232] = vec4(0.804318, -0.800475, 5.462428, 2.064344);ltc_mat[233] = vec4(0.889640, -0.683606, 3.500154, 1.523521);ltc_mat[234] = vec4(0.962199, -0.565514, 2.402228, 1.122033);ltc_mat[235] = vec4(1.038259, -0.453896, 1.780805, 0.811347);ltc_mat[236] = vec4(1.115567, -0.342479, 1.403633, 0.559417);ltc_mat[237] = vec4(1.230412, -0.234388, 1.182233, 0.342490);ltc_mat[238] = vec4(1.356005, -0.114106, 1.077392, 0.163457);ltc_mat[239] = vec4(1.416097, 0.020396, 1.000096, -0.010603);ltc_mat[240] = vec4(0.000101, -0.117111, 1171.109863, 1171.109375);ltc_mat[241] = vec4(0.025775, -1.183993, 11842.732422, 200.885010);ltc_mat[242] = vec4(0.200461, -2.229295, 7482.495117, 14.348876);ltc_mat[243] = vec4(0.306880, -1.543576, 474.435883, 21.472698);ltc_mat[244] = vec4(0.473047, -1.406313, 149.314774, 10.531585);ltc_mat[245] = vec4(0.633393, -1.290295, 57.961525, 6.486299);ltc_mat[246] = vec4(0.781742, -1.181989, 27.042383, 4.300042);ltc_mat[247] = vec4(0.889530, -1.039685, 13.823654, 2.970346);ltc_mat[248] = vec4(0.967213, -0.890533, 7.678234, 2.121588);ltc_mat[249] = vec4(1.022426, -0.745031, 4.588925, 1.550315);ltc_mat[250] = vec4(1.053039, -0.602697, 2.901296, 1.149385);ltc_mat[251] = vec4(1.127651, -0.496024, 2.047898, 0.845075);ltc_mat[252] = vec4(1.191029, -0.385807, 1.503557, 0.600781);ltc_mat[253] = vec4(1.350495, -0.296642, 1.207134, 0.384524);ltc_mat[254] = vec4(1.488451, -0.184153, 1.055333, 0.200477);ltc_mat[255] = vec4(1.670859, -0.056400, 0.999631, 0.033783);
#endif
}