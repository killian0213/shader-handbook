// Common (common) — BattleShips by skaplun
// https://www.shadertoy.com/view/7dscD2

//#define RENDER_SWAP_BTN
//#define RENDER_RANDOM_BTN
#define RENDER_SHIP_INDICATORS
//#define REFLECTIONS
#define RENDER_EXPLOSIONS

#define ZERO min(iFrame, 0)
#define MAX_FLOAT 1e5
#define MIN_FLOAT 1e-5
#define EPSILON 1e-4
#define UP vec3(0., 1., 0.)
#define rx(a) mat3(1.0, 0.0, 0.0, 0.0, cos(a),-sin(a), 0.0, sin(a), cos(a))
#define ry(a) mat3(cos(a), 0.0,-sin(a), 0.0, 1.0, 0.0, sin(a), 0.0, cos(a))
#define rz(a) mat3(cos(a),-sin(a), 0.0, sin(a), cos(a), 0.0, 0.0, 0.0, 1.0)
#define r2d(a) mat2(cos(a),-sin(a), sin(a), cos(a))
#define saturate(x) clamp(x, 0., 1.)
#define WHITE vec3(1.)
#define RED vec3(1., 0., 0.)

const float PI = acos(-1.);
const float PI2 = PI * 2.;
const float HPI = PI * .5;
const float QPI = PI * .25;

const int SHIPS_CNT = 10;
const int SHIP_POSITION_LINE = 0;
const int SHIP_ROTATION_LINE = 1;
const int SHIP_INTERACTION_LINE = 2;
#define PRESSED x
#define RELEASE_TIME y
#define DEST_POINT zw
const int SHIP_TOTAL_LINES = 3;
const int GAME_STATE_LINE = 4;
const int GAME_STATE_START = -1;
const int GAME_STATE_POSITIONING = 0;
const int GAME_STATE_READY_TO_PLAY = 1;
const int GAME_STATE_AIMING = 2;
const int GAME_STATE_FIRE = 3;
const int GAME_STATE_ENEMY_TURN = 4;
const int GAME_STATE_ENEMY_FIRE = 5;
const int GAME_STATE_END = 6;

const int BUTTONS_LINE = 5;
const int BUTTONS_BATTLE_ID = 0;
const int BUTTONS_COUNT = 1;

const int LAST_SHOT_LINE = 6;
const int ENEMY_HIT_COUNT_LINE = 7;

#define BATTLE_BUTTON vec4(.3, .125, .27, .075)
#define SWAP_BUTTON vec4(1.6, .095, .1, .05)
#define RANDOM_BUTTON vec4(1.65, .925, .1, .05)
#define PLAY_AGAIN_BUTTON vec4(iResolution.x/iResolution.y * .5, 0.5, .3, .05)
#define CENTER_X x
#define CENTER_Y y
#define WIDTH z
#define HEIGHT w

struct Ray{vec3 o, dir;};
struct Sphere{vec3 o; float rad;};
struct Box{ vec3 o; vec3 size;};
struct Cylinder{vec3 A, B; float r;};
struct Boat{Box boundingBox; int boatType;};

const Boat BOAT1 = Boat(Box(vec3(-4.2, .25, 6.2), vec3(.75, .3, .25)), 1);
const Boat BOAT2 = Boat(Box(vec3(-2.2, .45, 6.1), vec3(1., .25, .5)), 2);
const Boat BOAT3 = Boat(Box(vec3(0.4, .35, 6.1), vec3(1.5, .25, .5)), 3);
const Boat BOAT4 = Boat(Box(vec3(2.8, .6, 6.3), vec3(2.25, .5, .75)), 4);

Boat boatFromId(int id){
    if(id > 8)
        return BOAT4;
    if(id > 6)
        return BOAT3;
    if(id > 3)
        return BOAT2;
    else
        return BOAT1;
}

float boatSpanFromId(int id){
    if(id > 8)
        return 3.;
    if(id > 6)
        return 2.;
    if(id > 3)
        return 1.;
    else
        return 0.;
}

vec2 boatOffsetsFromPos(int id){
    return vec2(mod((boatSpanFromId(id)), 2.) * .5, 0.);
}

/*
float boatRotationFromId(int id){
    if(id > 8)
        return 0.;
    if(id > 6)
        return PI;
    if(id > 3)
        return 0.;
    else
        return PI;
}
*/

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

const vec3 PLAYER_FIELD_LOOK_AT = vec3(-2., 0., 1.);
const vec3 PLAYER_FIELD_CAM_POS = vec3(-2., 13., 17.);
const vec3 ENEMY_FIELD_LOOK_AT = vec3(23., 0., 1.);
const vec3 ENEMY_FIELD_CAM_POS = vec3(21., 16., 17.);

//const int GAME_STATE_POSITIONING = 0;
//const int GAME_STATE_READY_TO_PLAY = 1;
//const int GAME_STATE_PLAYER_TURN = 2;
//const int GAME_STATE_ENEMY_TURN = 3;
const float a = HPI;

void camera(out vec3 eye, out vec3 lookAt, float time, vec4 gameState){
    float t = saturate(time - gameState.y);
    switch(int(gameState.x)){
        case GAME_STATE_AIMING:
            if(int(gameState.z) == GAME_STATE_FIRE){
                lookAt = ENEMY_FIELD_LOOK_AT;
                eye = ENEMY_FIELD_CAM_POS;
            }else{
                lookAt = mix(PLAYER_FIELD_LOOK_AT, ENEMY_FIELD_LOOK_AT, t);
                eye = mix(PLAYER_FIELD_CAM_POS, ENEMY_FIELD_CAM_POS, t);
            }
            break;
        case GAME_STATE_END:
            vec3 e;
            vec3 l;
            if(gameState.z == float(GAME_STATE_FIRE)){
                l = ENEMY_FIELD_LOOK_AT;
                e = ENEMY_FIELD_CAM_POS;    
            }else{
                l = PLAYER_FIELD_LOOK_AT;
                e = PLAYER_FIELD_CAM_POS;
            }
            
            lookAt = mix(l, vec3(10., 0., 0.), t);
            eye = mix(e, vec3(10., 30., 30.), t);
            break;
        case GAME_STATE_FIRE:
            lookAt = ENEMY_FIELD_LOOK_AT;
            eye = ENEMY_FIELD_CAM_POS;
            break;
        case GAME_STATE_ENEMY_TURN:
            lookAt = mix(ENEMY_FIELD_LOOK_AT, PLAYER_FIELD_LOOK_AT, t);
            eye = mix(ENEMY_FIELD_CAM_POS, PLAYER_FIELD_CAM_POS, t);
            break;
        case GAME_STATE_ENEMY_FIRE:
            lookAt = PLAYER_FIELD_LOOK_AT;
            eye = PLAYER_FIELD_CAM_POS;
            break;
        case GAME_STATE_POSITIONING:
            if(int(gameState.z) == GAME_STATE_START){
                lookAt = mix(ENEMY_FIELD_LOOK_AT, PLAYER_FIELD_LOOK_AT, t);
                eye = mix(ENEMY_FIELD_CAM_POS, PLAYER_FIELD_CAM_POS, t);
            }else{
                lookAt = vec3(-.25, 0., 2.4);
                eye = vec3(-.1, 10., 16.);
            }
            break;
        case GAME_STATE_READY_TO_PLAY:
            lookAt = vec3(-.25, 0., 2.4);
            eye = vec3(-.1, 10., 16.);
        break;
    }
}

Ray createRay(vec2 fragCoord, vec2 res, float time, vec4 gameState){
    vec3 lookAt;
    vec3 eye;
    camera(eye, lookAt, time, gameState);
    mat3 m = viewMatrix(eye, lookAt, normalize(vec3(0., 1., 0.)));
    return Ray(eye, m * rayDirection(45., res, fragCoord));
}

vec2 projectPoint(vec3 point, vec2 fragCoord, vec2 res, float time, vec4 gameState){
    vec3 lookAt;
    vec3 eye;
    camera(eye, lookAt, time, gameState);
    //mat3 m = viewMatrix(eye, lookAt, normalize(vec3(0., 1., 0.)));
    vec3 ro = eye;
    vec3 ta = lookAt;
	vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww, vec3(0.0,1.0,0.0)));
    vec3 vv = normalize( cross(uu,ww));
	//vec3 rd = normalize( p.x * uu + p.y * vv + fov * ww );
	
    mat4 cam = mat4( uu.x, uu.y, uu.z, 0.0,
					 vv.x, vv.y, vv.z, 0.0,
					 ww.x, ww.y, ww.z, 0.0,
					 -dot(uu,ro), -dot(vv,ro), -dot(ww,ro), 1.0 );
    vec3 cpos = (cam * vec4(point, 1.)).xyz; // note inverse multiply
    //vec3 cpos = (point * m); // note inverse multiply
    //vec2 npos = cpos.xy / cpos.z  * 5. + vec2(0., .5);
    vec2 npos = cpos.xy / cpos.z  * 5.;
    //vec2 spos = npos * vec2(res.xy/res.xx);
    vec2 spos = npos;// * vec2(res.xy/res.xx);
    return spos;// * res.xy/res.x;
}

mat4 rotationMatrix(vec3 axis, float angle){
    // taken from http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    angle = radians(angle);
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float sphere_hit(const in Sphere sphere, const in Ray inray) {
    vec3 oc = inray.o - sphere.o;
    float a = dot(inray.dir, inray.dir);
    float b = dot(oc, inray.dir);
    float c = dot(oc, oc) - sphere.rad*sphere.rad;
    float discriminant = b*b - a*c;
    if (discriminant > 0.) {
        return (-b - sqrt(discriminant))/a;
    }
    return -1.;
}

#define MIN x
#define MAX y
bool box_hit(const in Box inbox, in Ray inray){
    vec2 tx, ty, tz;
    vec3 maxbounds = inbox.o + vec3( inbox.size);
    vec3 minbounds = inbox.o + vec3(-inbox.size);
    tx = ((inray.dir.x >= 0.?vec2(minbounds.x, maxbounds.x):vec2(maxbounds.x, minbounds.x)) - inray.o.x) / inray.dir.x;
	ty = ((inray.dir.y >= 0.?vec2(minbounds.y, maxbounds.y):vec2(maxbounds.y, minbounds.y)) - inray.o.y) / inray.dir.y;
    if ((tx.MIN > ty.MAX) || (ty.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, ty.MIN), min(tx.MAX, ty.MAX));
	tz = ((inray.dir.z >= 0.?vec2(minbounds.z, maxbounds.z):vec2(maxbounds.z, minbounds.z)) - inray.o.z) / inray.dir.z;
    if ((tx.MIN > tz.MAX) || (tz.MIN > tx.MAX))
        return false;
    tx = vec2(max(tx.MIN, tz.MIN), min(tx.MAX, tz.MAX));
    
    if(tx.MIN >= 0.){
    	return true;
    }
        
    return false;
}

vec2 iBox(in Ray inray, const in Box inbox){
    vec2 tx, ty, tz;
    vec3 maxbounds = inbox.o + vec3( inbox.size);
    vec3 minbounds = inbox.o + vec3(-inbox.size);
    tx = ((inray.dir.x >= 0.?vec2(minbounds.x, maxbounds.x):vec2(maxbounds.x, minbounds.x)) - inray.o.x) / inray.dir.x;
	ty = ((inray.dir.y >= 0.?vec2(minbounds.y, maxbounds.y):vec2(maxbounds.y, minbounds.y)) - inray.o.y) / inray.dir.y;
    if ((tx.MIN > ty.MAX) || (ty.MIN > tx.MAX))
        return vec2(-1.);
    tx = vec2(max(tx.MIN, ty.MIN), min(tx.MAX, ty.MAX));
	tz = ((inray.dir.z >= 0.?vec2(minbounds.z, maxbounds.z):vec2(maxbounds.z, minbounds.z)) - inray.o.z) / inray.dir.z;
    if ((tx.MIN > tz.MAX) || (tz.MIN > tx.MAX))
        return vec2(-1.);
    tx = vec2(max(tx.MIN, tz.MIN), min(tx.MAX, tz.MAX));
    
    if(tx.MIN >= 0. || tx.MAX >= 0.){
        return vec2(max(tx.MIN, MIN_FLOAT), tx.MAX);
    }
        
    return vec2(-1.);
}

mat4 rotationAxisAngle( vec3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return mat4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
			     0.0,                0.0,                0.0,                1.0 );
}

mat4 translate(vec3 to){
    return mat4( 1.0, 0.0, 0.0, 0.0,
				 0.0, 1.0, 0.0, 0.0,
				 0.0, 0.0, 1.0, 0.0,
				 to.x,to.y,to.z,1.0 );
}

vec2 iBox(Ray r, Box box, in mat4 txx, in mat4 txi){
    // convert from ray to box space
	vec3 rdd = (txx * vec4(r.dir, 0.0)).xyz;
	vec3 roo = (txx * vec4(r.o, 1.0)).xyz;

	// ray-box intersection in box space
    vec3 m = 1.0/rdd;
    vec3 n = m*roo;
    vec3 k = abs(m) * box.size;
	
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;

	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	
	if( tN > tF || tF < 0.0) return vec2(-1.0);

    return vec2(max(tN, MIN_FLOAT), tF);
	/*
    vec3 nor = -sign(rdd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);

    // convert to ray space
	
	nor = (txi * vec4(nor, 0.0)).xyz;

	return vec4( tN, nor );
    */
}

vec2 cylinderHit(const in Ray ray,  const in Cylinder cyl) {
  float cxmin, cymin, czmin, cxmax, cymax, czmax;
  if (cyl.A.z < cyl.B.z) {
      czmin = cyl.A.z - cyl.r; czmax = cyl.B.z + cyl.r;
  } else {
      czmin = cyl.B.z - cyl.r; czmax = cyl.A.z + cyl.r;
  }
  if (cyl.A.y < cyl.B.y) {
      cymin = cyl.A.y - cyl.r; cymax = cyl.B.y + cyl.r;
  } else {
      cymin = cyl.B.y - cyl.r; cymax = cyl.A.y + cyl.r;
  }
  if (cyl.A.x < cyl.B.x) {
      cxmin = cyl.A.x - cyl.r; cxmax = cyl.B.x + cyl.r;
  } else {
      cxmin = cyl.B.x - cyl.r; cxmax = cyl.A.x + cyl.r;
  }
/*
  if (optimize) {
   if (start.z >= czmax && (start.z + dir.z) > czmax) return;
   if (start.z <= czmin && (start.z + dir.z) < czmin) return;
   if (start.y >= cymax && (start.y + dir.y) > cymax) return;
   if (start.y <= cymin && (start.y + dir.y) < cymin) return;
   if (start.x >= cxmax && (start.x + dir.x) > cxmax) return;
   if (start.x <= cxmin && (start.x + dir.x) < cxmin) return;
  }
*/

    vec3 AB = cyl.B - cyl.A;
    vec3 AO = ray.o - cyl.A;
    vec3 AOxAB = cross(AO, AB);
    vec3 VxAB  = cross(ray.dir, AB);
    float ab2 = dot(AB, AB);
    float a = dot(VxAB, VxAB);
    float b = 2. * dot(VxAB, AOxAB);
    float c = dot(AOxAB, AOxAB) - (cyl.r * cyl.r * ab2);
    float d = b * b - 4. * a * c;
    if (d < 0.)
        return vec2(-1.);
    
    //rec.dist = (-b - 1. * sqrt(d)) / (2. * a);
    vec2 res = vec2(-1.);
    float[2] coef = float[2](1., -1.); 
    for(int i=0; i<2; i++){
        res[i] = (-b - coef[i] * sqrt(d)) / (2. * a);
    }
    return res;
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x,p.y);
    return length(q)-t.y;
}

float sdEllipsoid(vec3 p, vec3 r){
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundBox(vec3 p, vec3 b, float r){
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdPlane(vec3 p, vec3 n, float h ) {
    return dot(p,n) + h;
}

float sdCapsule(vec3 p, float h, float r)
{
  p.x -= clamp( p.x, 0.0, h );
  return length( p ) - r;
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r){
    vec3  ba = b - a;
    vec3  pa = p - a;
    float baba = dot(ba,ba);
    float paba = dot(pa,ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    
    float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    
    return sign(d)*sqrt(abs(d))/baba;
}

float smin(float a, float b, float k){
	float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
	return mix( b, a, h ) - k*h*(1.0-h);
}

float smax(float a, float b, float k){
    return smin(a, b, -k);
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCappedCylinder( vec3 p, float h, float r ){
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdSphere(vec3 p, float rad) {
    return length(p) - rad;
}

vec2 opMin(vec2 a, vec2 b){
    return a.x<=b.x?a:b;
}

vec3 opMin(vec3 a, vec3 b){
    return a.x<=b.x?a:b;
}

vec4 opMin(vec4 a, vec4 b){
    return a.x<=b.x?a:b;
}

float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, abs(p.z) - h );
  	return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}
/*
float dot2( in vec3 v ) { return dot(v,v); }
vec2 sdBezier(vec3 pos, vec3 A, vec3 B, vec3 C)
{    
    vec3 a = B - A;
    vec3 b = A - 2.0*B + C;
    vec3 c = a * 2.0;
    vec3 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);      

    vec2 res;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0) 
    { 
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = clamp(uv.x+uv.y-kx, 0.0, 1.0);

        // 1 root
        res = vec2(dot2(d+(c+b*t)*t),t);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = clamp( vec3(m+m,-n-m,n-m)*z-kx, 0.0, 1.0);
        
        // 3 roots, but only need two
        float dis = dot2(d+(c+b*t.x)*t.x);
        res = vec2(dis,t.x);

        dis = dot2(d+(c+b*t.y)*t.y);
        if( dis<res.x ) res = vec2(dis,t.y );
    }
    
    res.x = sqrt(res.x);
    return res;
}
*/
vec3 hsv2rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 blend(in vec4 under, in vec4 over) {
  vec4 result = mix(under, over, over.a);
  result.a = over.a + under.a * (1.0 - over.a);
    
  return result;
}

//by iq

vec2 hash( in vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

// return gradient noise (in x) and its derivatives (in yz)
vec3 noised( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );

#if 1
    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);
#else
    // cubic interpolation
    vec2 u = f*f*(3.0-2.0*f);
    vec2 du = 6.0*f*(1.0-f);
#endif    
    
    vec2 ga = hash( i + vec2(0.0,0.0) );
    vec2 gb = hash( i + vec2(1.0,0.0) );
    vec2 gc = hash( i + vec2(0.0,1.0) );
    vec2 gd = hash( i + vec2(1.0,1.0) );
    
    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

/*
float boat1(vec3 p, mat4 txx, float time){
    p = (txx * vec4(p, 1.)).xyz;
    //return length(p) - .25;
    
    float res = MAX_FLOAT;
    {
        vec3 mpos = p + vec3(p.y, 0., 0.);
        mpos.z = abs(mpos.z);
        float bodyOuter = sdEllipsoid(mpos - vec3(0., 0., -.5), vec3(1., 1., .75));
        float bodyInner = max(max(sdEllipsoid(mpos - vec3(0., 0., -.5), vec3(1., 1., .75) * .99), -mpos.y - .17), p.x - .58);
        
        bodyOuter = max(bodyOuter, -bodyInner);
        bodyOuter = max(bodyOuter, sdPlane(mpos, normalize(vec3(.1, 1., 0.)), .1));
        bodyOuter = max(bodyOuter, -sdCappedCylinder(mpos.xzy + vec3(0.2, .0, -.25), .4, .3));
        bodyOuter = max(bodyOuter, -sdBox(mpos.xzy + vec3(-.3, 0., -.1), vec3(.5, .5, .25)));
        bodyOuter = smax(bodyOuter, p.x - .6, .025);
      
        bodyOuter = smax(bodyOuter, -sdPlane(mpos, normalize(vec3(0., 1., .1)), .5), .25);
        bodyOuter = smax(bodyOuter, sdPlane(mpos, normalize(vec3(0., -1., .25)), -.3), .1);
        
        res = min(res, bodyOuter);
    }
    
    {
        vec3 mpos = p;
        mpos.z = abs(mpos.z);
        float cabin = -MAX_FLOAT;
        cabin = max(cabin, sdPlane(mpos, normalize(vec3(0., .25, 1.)), -.1));
        cabin = max(cabin, -sdPlane(mpos, normalize(vec3(1., -.3, -.5)), 0.));
        cabin = max(cabin, -max(sdPlane(mpos, normalize(vec3(1., -.3, -.5)), -.1), -p.y));
        
        cabin = max(cabin, -sdPlane(mpos, normalize(vec3(-1., -.3, -.25)), 0.45));
        cabin = max(cabin, -max(sdPlane(mpos, normalize(vec3(-1., -.3, -.25)), 0.4), -p.y));
        
        cabin = max(cabin, sdPlane(mpos, normalize(vec3(0., 1., .3)), -.15));
        cabin = max(cabin, -p.y - .2);
        
        //front lower window
        cabin = max(cabin, -max(sdBox(mpos + vec3(-.01, .06, -.055), vec3(.05)), sdPlane(mpos, normalize(vec3(1., -.3, -.5)), -.01)));
        //front upper window
        cabin = max(cabin, -max(max(sdBox(mpos + vec3(-.15, -.07, -.055), vec3(.05, .06, .05)), sdPlane(mpos, normalize(vec3(1., -.3, -.5)), -.11)), sdPlane(mpos, normalize(vec3(0., .25, 1.)), -.095)));
        //rear lower window
        cabin = max(cabin, -max(sdBox(mpos + vec3(-.5, .06, -.055), vec3(.05)), sdPlane(mpos, normalize(vec3(-1., -.3, -.25)), .44)));
        //rear upper window
        cabin = max(cabin, -max(max(sdBox(mpos + vec3(-.4, -.075, -.055), vec3(.05)), sdPlane(mpos, normalize(vec3(-1., -.3, -.25)), 0.39)), sdPlane(mpos, normalize(vec3(0., .25, 1.)), -.095)));
        
        {
            vec3 mpos = vec3(p.x, p.y, abs(p.z));
            cabin = max(cabin, -max(max(max(sdBox(mpos + vec3(-.2, -.071, -.1), vec3(.2, .06, .05)), -sdPlane(mpos, normalize(vec3(1., -.3, -.5)), -.105)), -sdPlane(mpos, normalize(vec3(-1., -.3, -.25)), 0.395)), -sdPlane(mpos, normalize(vec3(0., .25, 1.)), -.09)));
            
            mpos *= rx(radians(15.));
            float illuminator = sdTorus(mpos.xzy - vec3(.1, .1, -.09), vec2(.035, .005));
            illuminator = min(illuminator, sdTorus(mpos.xzy - vec3(.2, .1, -.09), vec2(.035, .005)));
            illuminator = min(illuminator, sdTorus(mpos.xzy - vec3(.41, .1, -.09), vec2(.035, .005)));
            cabin = min(cabin, illuminator);
            
            // door
            cabin = min(cabin, max(max(max(sdCapsule(mpos.yzx - vec3(-.28, .1, .305), .2, .05), -sdCapsule(mpos.yzx - vec3(-.28, .1, .305), .2, .04)), sdPlane(mpos, normalize(vec3(0., 0., 1.)), -.11)), -p.y - .25));
        }
        
        {
            vec3 mpos = p;
            float antenna = sdCapsule(mpos.yzx + vec3(-.1, 0., -.3), .1, .01);
            vec3 center = vec3(-.3, -.2, 0.);
            mpos += center;
            mpos *= ry(time * 2.);
            mpos -= center;
            antenna = min(antenna, sdBox(mpos + center, vec3(.1, .0025, .02)));
            res = min(res, antenna);
        }
        
        res = min(res, cabin);
    }
    
    {
        vec3 mpos = p;
        float gun = sdCapsule(mpos.yzx + vec3(0.2, 0., 0.2), .1, .025);
        vec3 gunCenter = vec3(0.2, 0.05, 0.);
        //gun = smin(gun, length(mpos + gunCenter) - .09, .01);
        mpos += gunCenter;
        mpos *= ry(sin(time) * 2.);
        mpos *= rz(cos(time) * .5 + .65);
        mpos -= gunCenter;
        
        gun = smin(gun, sdRoundBox(mpos + gunCenter, vec3(.05, .05, .075), .01), .03);
        gun = max(gun, -sdRoundBox(mpos + gunCenter + vec3(.05, 0., 0.), vec3(.05, .05, .075) * .9, .01));

        //TODO mergen into 1 call
        float rockets = sdEllipsoid(mpos + gunCenter + vec3(0., 0.031, .062), vec3(.1, .02, .02));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.031, .0225), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.031, -.0225), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.031, -.0625), vec3(.1, .02, .02)));
        
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.0, .0625), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.0, .0225), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.0, -.0225), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., 0.0, -.0625), vec3(.1, .02, .02)));
        
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., -.031, .0625), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., -.031, .0225), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., -.031, -.0225), vec3(.1, .02, .02)));
        rockets = min(rockets, sdEllipsoid(mpos + gunCenter + vec3(0., -.031, -.0625), vec3(.1, .02, .02)));
        
        rockets = max(rockets, mpos.x + gunCenter.x);
        
        gun = min(gun, rockets);
        
        res = min(res, gun);
    }
    
    if(false){
        vec3 mpos = p;
        res = max(res, -(length(mpos + vec3(.54, 0.08, 0.05)) - .04));
    
        
        mpos += vec3(.55, 0.02, .06);
        mpos *= ry(radians(35.));
        mpos.xz = abs(mpos.xz);
        
        float anchor = max(sdEllipsoid(mpos + vec3(.2, 0., 0.2), vec3(.5, .5, .25)), -(length(mpos + vec3(0.11, -.04, 0.)) - .25));
        mpos = p;
        anchor = min(anchor, sdCapsule(mpos.yzx + vec3(0.2, 0.06, 0.55), .085, .005));
        res = min(res, anchor);
    }
    
    return res;
}


float b2(vec3 p){
    vec3 mpos = p;
    mpos.z = abs(mpos.z);
    float body = sdPlane(mpos, normalize(vec3(0., -1.2, 1.)), -1.);
    
    body = smax(body, sdPlane(mpos, normalize(vec3(-.15, 0., 1.)), -.4), .1);
    body = smax(body, sdPlane(mpos, normalize(vec3(1., -1.2, 1.2)), -.2), .05);
    body = smax(body, sdPlane(mpos, normalize(vec3(-1., -.6, .4)), -.5), .1);
    
    body = max(body, p.y - .4);
    
    return body;
}
*/

#define MAT_BOAT1 101
#define MAT_BOAT2 102
#define MAT_BOAT3 103
#define MAT_BOAT4 104
#define MAT_PLANE_MAIN 105
#define MAT_PLANE_CABIN 106
#define MAT_BOAT1_CAB 107

vec2 boat1(vec3 p, mat4 txx, float time){
    p = (txx * vec4(p, 1.)).xyz;
    p.x *= -1.;
    
    float res = MAX_FLOAT;
    vec3 mpos = p;
    mpos.z = abs(mpos.z);
    mpos.y += .2;
    float body;
    {
        
        body = sdPlane(mpos, normalize(vec3(0., -1., 1.)), 0.);
        body = smax(body, sdPlane(mpos, normalize(vec3(0., 0., 1.)), -.2), .05);
        body = smax(body, sdPlane(mpos, normalize(vec3(-1., -1., 1.5)), -.2), .1);
        body = smax(body, sdPlane(mpos, normalize(vec3(1., -.1, 0.0)), -.55), .2);
    }
    
    float body2;
    {
        vec3 mpos = p * vec3(1., 1.1, 1.15) + vec3(.02, 0., 0.);
        mpos.z = abs(mpos.z);
        mpos.y += .15;
        body2 = sdPlane(mpos, normalize(vec3(0., -1., 1.)), 0.);
        body2 = smax(body2, sdPlane(mpos, normalize(vec3(0., 0., 1.)), -.2), .05);
        body2 = smax(body2, sdPlane(mpos, normalize(vec3(-1., -1., 1.5)), -.2), .1);
        body2 = smax(body2, sdPlane(mpos, normalize(vec3(1., -.1, 0.0)), -.55), .2);
    }

    res = max(body, -body2);
    res = max(res, mpos.y - .35);
    res = min(res, max(mpos.y - .25, body));
    res = max(res, -sdCylinder(p.xzy - vec3(-.275, 0., .175), vec3(0., 0., .1)));
    res = max(res, -sdBox(p - vec3(.25, .275, 0.), vec3(.5, .2, .3)));
    
    {
        vec3 center = vec3(.4, 0.1, 0.);
        vec3 mpos = p;
        mpos -= center;
        mpos *= ry(cos(time * .5)) * rz(sin(time) * .25 + 1.);
        mpos += center;
        float gun = length(mpos - center) - .1;
        gun = max(gun, mpos.y - .12);
        gun = min(gun, length(mpos - center + vec3(0., .05, 0.)) - .1);
        mpos.z = abs(mpos.z);
        float barrels = max(sdCylinder(mpos - center, vec3(0., 0.035, .025)), mpos.y - .75);
        barrels = max(barrels, -mpos.y);
        barrels = max(barrels, mpos.y - .35);
        gun = min(gun, barrels);
        
        res = min(res, gun);
    }
    
    vec2 boat = vec2(res, MAT_BOAT1);
    
    {
        float cabin;
        vec3 mpos = p - vec3(.1, 0., 0.);
        mpos.z = abs(mpos.z);
        cabin = sdPlane(mpos, normalize(vec3(0., 0., 1.)), -.125);
        cabin = max(cabin, mpos.y - .3);
        cabin = max(cabin, -mpos.y);
        cabin = max(cabin, sdPlane(mpos, normalize(vec3(-.75, .5, .75)), -.35));
        cabin = max(cabin, sdPlane(mpos, normalize(vec3(1., 0., .25)), -.1));

        float roof = sdBox(mpos - vec3(0.2, .3, 0.), vec3(1., .01, .17));
        roof = max(roof, sdPlane(mpos, normalize(vec3(-.75, -.5, .75)), -.125));
        roof = max(roof, sdPlane(mpos, normalize(vec3(1., 0., .25)), -.1));

        cabin = min(cabin, roof);
        boat = opMin(boat, vec2(cabin, MAT_BOAT1_CAB));
    }

    return boat;
}

vec2 boat2(vec3 p, mat4 txx, float time){
    p = (txx * vec4(p, 1.)).xyz;
    //return length(p) - .25;
    
    float res = MAX_FLOAT;
    
    {
        vec3 mpos = p;
        mpos.z = abs(mpos.z);
        mpos.z -= p.x * .2;
        float bodyOuter = smax(sdEllipsoid(mpos - vec3(-1.38, .5, -.35), vec3(2.5, 2.5, .75)), -p.x - .97, .05);
        float bodyInner = max(smax(sdEllipsoid(mpos - vec3(-1.38, .5, -.35), vec3(2.5, 2.5, .75) * .99),  -p.x - .96, .05), -p.y - .15);
        bodyOuter = max(bodyOuter, -bodyInner);
        
        bodyOuter = max(bodyOuter, p.y + .1);
        
        float cabin = sdEllipsoid(mpos - vec3(-1.38, .5, -.35), vec3(2.5, 2.5, .75));
        cabin = max(cabin, -sdPlane(mpos, normalize(vec3(-1., -.5, 0.)), 0.));
        cabin = max(cabin, -sdPlane(mpos, normalize(vec3(-1., -.5, -.5)), 0.08));
        
        cabin = max(cabin, -sdPlane(mpos, normalize(vec3(1., -.5, 0.)), 0.7));
        cabin = max(cabin, p.y - .05);
        
        float upperCabin = sdEllipsoid(mpos - vec3(-1.38, .5, -.35), vec3(2.5, 2.5, .75) * .95);//sdBox(mpos + vec3(.5, 0., 0.), vec3(.175, .25, .3));
        upperCabin = max(upperCabin, -sdPlane(mpos, normalize(vec3(-1., -.5, 0.)), -.2));
        upperCabin = max(upperCabin, -sdPlane(mpos, normalize(vec3(-1., -.5, -.5)), -.1));
        upperCabin = max(upperCabin, p.y - .175);
        upperCabin = max(upperCabin, -p.x - .7);
        cabin = min(cabin, upperCabin);
        
        {
            vec3 mpos = p;
            mpos.x -= .4;
            float antenna = sdCapsule(mpos.yzx + vec3(0., 0., 0.5), .15, .01);
            vec3 antennaCenter = vec3(-.5, .15, 0.);
            antenna = min(antenna, length(mpos - antennaCenter) - .05);
            mpos -= antennaCenter;
            mpos *= ry(sin(time));
            mpos += antennaCenter;
            antenna = min(antenna, max(length(mpos - antennaCenter - vec3(.21, 0., 0.)) - .2, sdEllipsoid(mpos - antennaCenter, vec3(.25, .1, .25))));
            antenna = max(antenna, -length(mpos - antennaCenter - vec3(.21, 0., 0.)) + .195);
            cabin = min(cabin, antenna);
        }
        
        {
            vec3 mpos = p;
            vec3 center = vec3(.75, -.1, 0.);
            float gun = sdRoundBox(mpos - center, vec3(.05), .05);
            gun = max(gun, p.y + .1);
            gun = min(gun, distance(mpos, center) - .075);
            mpos -= center;
            mpos *= ry(cos(time * .75));
            mpos *= rz(QPI * 1.5);
            mpos += center;
            mpos.z = abs(mpos.z);
            gun = min(gun, sdBox(mpos - center - vec3(.04, .05, 0.), vec3(.01, .03, .03)));
            gun = min(gun, sdBox(mpos - center - vec3(-.1, .08, 0.), vec3(.025, .01, .125)));
            gun = min(gun, sdBox(mpos - center - vec3(-.04, .08, 0.125), vec3(.05, .01, .05)));
            
            float barrels = max(max(sdCylinder(mpos - center, vec3(-0.04, 0.035, .025)), -sdCylinder(mpos - center, vec3(-0.04, 0.035, .023))), mpos.y - .75);
            barrels = max(barrels, mpos.y - .175);
            barrels = max(barrels, -mpos.y - .1);
            gun = min(gun, barrels);
            
            
            cabin = min(cabin, gun);
        }

        bodyOuter = min(bodyOuter, cabin);
        bodyOuter = max(bodyOuter, -p.y - .35);
        
        res = min(res, bodyOuter);
    }
    
    return vec2(res, MAT_BOAT2);
}

vec2 boat3(vec3 p, mat4 txx){
    p = (txx * vec4(p, 1.)).xyz;
    p.x *= -1.;
    p.y += .25;
    //return length(p) - .5;
    
    float res = MAX_FLOAT;
    {
        vec3 mpos = p;
        mpos.yz *= 1. + p.x * .3;
        float body = sdEllipsoid(mpos, vec3(1.5, .25, .25));
        
        mpos = p + vec3(.3, 0., 0.);
        float cabin = sdEllipsoid(mpos, vec3(.35, 5., .15));
        cabin = max(cabin, -p.y);
        cabin = smax(cabin, p.y - .5, .075);
        body = smin(body, cabin, .025);
        
        mpos.z = abs(mpos.z);
        mpos.y -= .4;
        mpos.x += .1;
        float wing = sdEllipsoid(mpos, vec3(.1, .025, 2.));
        wing = smax(wing, mpos.z - .3, .01);
        body = smin(body, wing, .02);
        
        mpos = p;
        mpos.x -= 1.2;
        mpos.x -= p.y * .7;
        float tail = sdEllipsoid(mpos, vec3(.15, 1., .025));
        tail = smax(tail, p.y - .25, .01);
        tail = max(tail, -p.y);
        tail = smax(tail, p.x - 1.4, .05);
        body = smin(body, tail, .05);
        
        mpos = p + vec3(1.2, 0., 0.);
        float antenna = sdCylinder(mpos, vec3(1., .02, .02));
        antenna = max(antenna, p.y - .8);
        antenna = min(antenna, max(sdCylinder(mpos + vec3(-.025, 0., .025), vec3(1., .02, .02)), p.y - .6));
        antenna = max(antenna, -p.y);
        body = min(body, antenna);
        res = min(res, body);
    }
    
    return vec2(res, MAT_BOAT3);
}

vec2 plane(vec3 pos){
    pos -= vec3(0., .05, 0.);
    pos.z = abs(pos.z);
    float body = sdEllipsoid(pos, vec3(.25, .05, .05));
    float cabin = sdEllipsoid(pos - vec3(.08, .035, 0.), vec3(.1, .025, .025));
    float wings = max(max(pos.y - .01, -pos.y + .01), sdPlane(pos, normalize(vec3(1., 0., 1.)), -.1));
    wings = max(wings, -sdPlane(pos, normalize(vec3(1., 0., .5)), .03));
    wings = max(wings, pos.z - .2);
    
    float tail = max(max(pos.y - .01, -pos.y + .01), sdPlane(pos, normalize(vec3(1., 0., 1.5)), .05));
    tail = max(tail, -sdPlane(pos, normalize(vec3(1., 0., .5)), .225));
    tail = min(tail, max(max(pos.z - .005, sdPlane(pos, normalize(vec3(1., 1., 0.)), .1)), -sdPlane(pos, normalize(vec3(1., 1., 0.)), .175)));
    tail = max(tail, -pos.x - .3);
    tail = max(tail, pos.y - .1);
    tail = max(tail, -pos.y - .1);
    
    body = min(min(body, wings), tail);
    vec2 res = vec2(MAX_FLOAT);
    return opMin(vec2(body, MAT_PLANE_MAIN), vec2(cabin, MAT_PLANE_CABIN));
}

vec2 boat4(vec3 p, mat4 txx, float time){
    p = (txx * vec4(p, 1.)).xyz;
    p.y += .5;
    //p.y += .5;
    //return length(p) - .5;
    
    float res = MAX_FLOAT;
    {
        vec3 mpos = p;
        float body = sdBox(mpos, vec3(2., .5, .25));
        
        mpos.z = abs(mpos.z);
        mpos.x = abs(mpos.x);
        mpos *= ry(radians(15.));
        mpos *= rz(radians(-3.));
        body = smax(body, -sdCylinder(mpos.zxy, vec3(0.7, 0.05, .35)), .1);
        
        mpos = p - vec3(0., .5, 0.);
        float deck = sdBox(mpos, vec3(2., .025, .75));
        deck = max(deck, -max(sdPlane(mpos, normalize(vec3(-.1, 0., -1.)), 0.5),
                              -sdPlane(mpos, normalize(vec3(1., 0., 1.)), -1.)));
        deck = max(deck, -max(sdPlane(mpos, normalize(vec3(-.1, 0., 1.)), .4),
                              -sdPlane(mpos, normalize(vec3(1., 0., -1.)), -.5)));
        deck = max(deck, sdPlane(mpos, normalize(vec3(-.2, 0., -1.)), -.7));
        deck = max(deck, sdPlane(mpos, normalize(vec3(-.1, 0., 1.)), -.6));
        body = min(body, deck);
        
        {
            vec3 mpos = p - vec3(-.5, .5, .3);
            float cabin = sdBox(mpos, vec3(.25, .4, .1));
            cabin = max(cabin, -mpos.y);
            cabin = min(cabin, max(mpos.y - .6, max(-mpos.y + .2, sdRoundBox(mpos - vec3(0., .4, 0.), vec3(.15, .5, .05), .2))));
            body = min(body, cabin);
        }
        
        res = min(res, body);
    }
    res = max(res, -p.y);
    vec2 ship = vec2(res, MAT_BOAT4);
    {
        vec3 mpos = p;
        mpos = p - vec3(0., .5, 0.);
        
        vec3 plane1cntr = vec3(-1.8, 0., .1);
        vec2 plane1 = plane(mpos - plane1cntr);
        
        plane1cntr = vec3(.15, 0., .3);
        mpos -= plane1cntr;
        mpos *= ry(QPI);
        mpos += plane1cntr;
        vec2 plane2 = plane(mpos - plane1cntr);


        plane1cntr = vec3(.45, 0., .65);
        vec2 plane3 = plane(mpos - plane1cntr);

        ship = opMin(ship, opMin(opMin(plane1, plane2), plane3));
    }
    
    return ship;
}

float easeInExpo(float x) {
    return x == 0. ? 0. : pow(2., 10. * x - 10.);
}

float easeOutExpo(float x) {
    return x == 1. ? 1. : 1. - pow(2., -10. * x);
}

float easeOutBounce(float x) {
    float n1 = 7.5625;
    float d1 = 2.75;

    if (x < 1. / d1) {
        return n1 * x * x;
    } else if (x < 2. / d1) {
        return n1 * (x -= 1.5 / d1) * x + 0.75;
    } else if (x < 2.5 / d1) {
        return n1 * (x -= 2.25 / d1) * x + 0.9375;
    } else {
        return n1 * (x -= 2.625 / d1) * x + 0.984375;
    }
}

float easeInBounce(float x) {
    return 1. - easeOutBounce(1. - x);
}

float easeInOutBounce(float x) {
    return x < .5
      ? (1. - easeOutBounce(1. - 2. * x)) / 2.
      : (1. + easeOutBounce(2. * x - 1.)) / 2.;
}

float easeOutElastic(float x) {
    float c4 = (2. * PI) / 3.;

    return x == 0.
      ? 0.
      : x == 1.
      ? 1.
      : pow(2., -10. * x) * sin((x * 10. - .75) * c4) + 1.;
}


vec2 button3d(vec3 p, mat4 txx){
    p = (txx * vec4(p, 1.)).xyz;
    p.z *= -1.;
    vec2 res = vec2(MAX_FLOAT);
    res = opMin(res, vec2(sdRoundBox(p, vec3(1., .1, .35), .05), vec3(0., 1., 0.)));
    
    /*
    p.x += .775;
    res = opMin(res, vec2(max(sdBox(p, vec3(.2)), letter3(p.xz, vec2(0.), vec2(.7), 66) - .52), vec3(1.)));
    p.x -= .35;
    res = opMin(res, vec2(max(sdBox(p, vec3(.2)), letter3(p.xz, vec2(0.), vec2(.7), 65) - .52), vec3(1.)));
    p.x -= .3;
    res = opMin(res, vec2(max(sdBox(p, vec3(.2)), letter3(p.xz, vec2(0.), vec2(.7), 84) - .52), vec3(1.)));
    p.x -= .35;
    res = opMin(res, vec2(max(sdBox(p, vec3(.2)), letter3(p.xz, vec2(0.), vec2(.7), 84) - .52), vec3(1.)));
    p.x -= .3;
    res = opMin(res, vec2(max(sdBox(p, vec3(.2)), letter3(p.xz, vec2(0.), vec2(.7), 76) - .52), vec3(1.)));
    p.x -= .3;
    res = opMin(res, vec2(max(sdBox(p, vec3(.2)), letter3(p.xz, vec2(0.), vec2(.7), 69) - .52), vec3(1.)));
    */
    return res;
}

float ASCIIskull(vec2 p){
    float n = 11524078.0;
	p = floor(p*vec2(4.0, -4.0) + 2.5); //[-1,1],[-1,1] => [-4,4],[4,-4] + 2.5
	if (clamp(p.x, 0.0, 4.0) == p.x && clamp(p.y, 0.0, 4.0) == p.y) //Creates a border for each character
	{
        //Read the bitmap, output 1 if there's a pixel...
		if (int(mod(n/exp2(p.x + 5.0*p.y), 2.0)) == 1) return 1.0;
	}
	return 0.0;
}

float sdEllipse(vec2 p, vec2 ab)
{
    // symmetry
	p = abs( p );
    
    // initial value
    vec2 q = ab*(p-ab);
    vec2 cs = normalize( (q.x<q.y) ? vec2(0.01,1) : vec2(1,0.01) );
    
    // find root with Newton solver (see https://www.shadertoy.com/view/4lsXDN)
    for( int i=0; i<5; i++ )
    {
        vec2 u = ab*vec2( cs.x,cs.y);
        vec2 v = ab*vec2(-cs.y,cs.x);
        
        float a = dot(p-u,v);
        float c = dot(p-u,u) + dot(v,v);
        float b = sqrt(c*c-a*a);
        
        cs = vec2( cs.x*b-cs.y*a, cs.y*b+cs.x*a )/c;
    }
    
    // compute final point and distance
    float d = length(p-ab*cs);
    
    // return signed distance
    return (dot(p/ab,p/ab)>1.0) ? d : -d;
}

float sdRoundSquare( in vec2 p, in float s, in float r ) 
{
    vec2 q = abs(p)-s+r;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float line(vec2 p, vec2 a,vec2 b) {
    p -= a, b -= a;
    float h = clamp(dot(p, b) / dot(b, b), 0., 1.);
    return length(p - b * h);
}

#define SHAPE_WIDTH .025
#define SHAPE_AA .02

vec4 ship1_2d_alt(vec2 uv, float hit){
    uv.x *= -1.;
    vec3 clr = mix(WHITE, RED, step((uv.x - uv.y * .5 + .15) * 2., floor(hit) - 2.));
    clr = mix(clr, RED, easeOutBounce(fract(hit)) * step(distance((uv.x - uv.y * .5 + .15) * 1.8, floor(hit) - 2. + .5), .5));

    float bg = step(fract((uv.x - uv.y * .5 + .15) * 1.8), .85) * .5 * step(abs((uv.x - uv.y * .5 + .15) * 1.8), 2.) * step(abs(uv.y - .25), .5);
    
    float shape = sdBox(uv + vec2(.35 + uv.y * .3, .05), vec2(.7, .2));
    shape = min(shape, sdBox(uv + vec2(-.4 - uv.y, -.025), vec2(.3, .275)));
    
    float cabin = sdBox(vec2(abs(uv.x + -.15), uv.y) - vec2(-uv.y * (.25 + .5 * step(0., uv.x)) + .35, .5), vec2(.35, .3));
    cabin = min(cabin, sdBox(uv - vec2(0.1, .8), vec2(.45, .02)));
    
    float gun = distance(uv, vec2(-.75, .25)) - .2;
    float barrel = sdBox(uv - vec2(-1., -.1 - uv.x * .5), vec2(.2, .05));
    
    bg *= step(min(gun, min(cabin, shape)), 0.);
    
    cabin = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(cabin)) * smoothstep(.05, .07, shape);
    barrel = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(barrel)) * smoothstep(.05, .07, gun);
    gun = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(gun)) * smoothstep(.05, .07, shape);
    shape = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(shape));
    float window = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, distance(distance(uv, vec2(-.2, .5)), .05));
    return vec4(clr, max(window, max(bg, max(barrel, max(gun, max(shape, cabin))))));
}

vec4 ship2_2d_alt(vec2 uv, float hit){
    uv.x *= -1.;
    vec3 clr = mix(WHITE, RED, step((uv.x - uv.y * .5 + .15) * 2.9, floor(hit) - 3.));
    clr = mix(clr, RED, easeOutBounce(fract(hit)) * step(distance((uv.x - uv.y * .5 + .15) * 2.9, floor(hit) - 3. + .5), .5));
    
    float bg = step(fract((uv.x - uv.y * .5 + .15) * 2.9), .85) * .5 * step(abs((uv.x - uv.y * .5 + .15) * 2.9), 3.) * step(abs(uv.y - .2), .42);

    float shape = sdBox(uv + vec2(.35 + uv.y * .3, .05), vec2(.7, .2));
    shape = min(shape, sdBox(uv + vec2(-.4 - uv.y, -.0125), vec2(.3, .275)));
    
    float window = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, distance(distance(uv, vec2(.55, .07)), .05));
    window = max(window, smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, distance(distance(uv, vec2(-.55, .35)), .05)));
    
    float cabin = sdBox(vec2(abs(uv.x + .45), uv.y) - vec2(-uv.y * .5 + .3, .25), vec2(.35, .15));
    cabin = min(cabin, sdBox(vec2(abs(uv.x + .55), uv.y) - vec2(-uv.y * .5 + .3, .45), vec2(.2, .15)));
    
    
    bg *= step(min(cabin, shape), 0.);
    
    cabin = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(cabin)) * smoothstep(.05, .07, shape);
    shape = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(shape));
    
    
    return vec4(clr, max(window, max(bg, max(shape, cabin))));
}

vec4 ship3_2d(vec2 uv, float hit){
    uv.x *= -1.;
    vec3 clr = mix(WHITE, RED, step((uv.x - uv.y * .5 - .1) * 1.9, floor(hit) - 3.));
    clr = mix(clr, RED, easeOutBounce(fract(hit)) * step(distance((uv.x - uv.y * .5 - .1) * 1.9, floor(hit) - 3. + .5), .5));
    
    float bg = step(fract((uv.x - uv.y * .5 - .1) * 1.9), .9) * .5 * step(abs((uv.x - uv.y * .5 - .1) * 1.9), 3.) * step(abs(uv.y - .1), .4);
    
    float body = sdEllipse(uv - vec2(.1, 0.)/* * vec2(1., 1. + uv.x * .5)*/, vec2(1.4, .2 + uv.x * .07));
    float cabin = sdRoundSquare(uv * vec2(1., 1.5) - vec2(0.35, .4),.3, .05);
    
    uv.y = abs(uv.y - .07);
    float tail = sdBox(uv + vec2(.8 + uv.y, 0.), vec2(.2, .25));
    
    bg *= step(min(tail, min(cabin, body)), 0.);
    
    tail = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(tail)) * smoothstep(.05, .07, body);
    cabin = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(cabin)) * smoothstep(.05, .07, body);
    body = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(body));
    
    return vec4(clr, max(tail, max(bg, max(body, cabin))));
}

vec4 ship4_2d(vec2 uv, float hit){
    uv.x *= -1.;
    float bg = step(fract((uv.x - uv.y * .5 + .15) * 1.1), .95) * .5 * step(abs((uv.x - uv.y * .5 + .15) * 1.1), 2.) * step(abs(uv.y - .27), .5);

    float body = sdBox(uv - vec2(0., .1), vec2(1.75, .3));//sdQuad(uv, vec2(1.75, .4), vec2(1.75, -.2), vec2(-1.75, -.2), vec2(-1.75, .4));
    body = max(body, -sdEllipse(vec2(abs(uv.x), uv.y) - vec2(1.85, -.2), vec2(1., .5)));
    float cabin = sdRoundSquare(uv - vec2(-.3, .3),.5, .05);
    bg *= step(min(cabin, body), 0.);
    cabin = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(cabin)) * smoothstep(.05, .07, body);
    body = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, abs(body));
    
    float window = smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, distance(distance(uv, vec2(-.2, .65)), .05));
    window = max(window, smoothstep(SHAPE_WIDTH + SHAPE_AA, SHAPE_WIDTH, distance(distance(uv, vec2(0., .65)), .05)));
    
    vec3 clr = mix(WHITE, RED, step((uv.x - uv.y * .5 + .15) * 1.1, floor(hit) - 2.));
    clr = mix(clr, RED, easeOutBounce(fract(hit)) * step(distance((uv.x - uv.y * .5 + .15) * 1.1, floor(hit) - 2. + .5), .5));
    
    return vec4(clr, max(bg, max(window, max(body, cabin))));
}

float nogologo(vec2 uv){
    uv *= r2d(-QPI);
    uv *= 2.;
    float circle = smoothstep(.0251, .025, distance(.1, length(uv)));
    float bar = 1. - max(smoothstep(.15, .151, abs(uv.x)), smoothstep(.025, .0251, abs(uv.y)));
    return max(circle, bar);
}

#define HASHSCALE4 vec4(.1031, .1030, .0973, .1099)
vec4 hash41(float p){
        vec4 p4 = fract(vec4(p) * HASHSCALE4);
    p4 += dot(p4, p4.wzxy+19.19);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
    
}
#define EXPLOSION_AA .01
vec4 explosion(vec2 uv, float time){
    vec4 res = vec4(0.);
    
    {
        vec2 pol = vec2(length(uv), atan(uv.x, uv.y));
        float n = floor((pol.y * 15.)/PI);
        pol.y = mod(pol.y * 15., PI)/PI;
        pol.y = 2. * pol.y - 1.;
        pol.y *= pol.x * PI;
        pol.x *= 20.;
        
        vec4 h = hash41(n * .17);
        float s = (.25 + h.y * .5) * smoothstep(.25, .3, time) * smoothstep(.55, .5, time);
        
        float start = 40. * smoothstep(.3, .5, time) * (2. - h.x);
        float end = 40. * smoothstep(.3, .4, time) * (2. - h.x);
        float width = (end - start)/2.;
        float mid = start + width;
        float v = mix(smoothstep(s + EXPLOSION_AA, s, abs(pol.y)),
                      max(smoothstep(s + EXPLOSION_AA, s, distance(vec2(start, 0.), pol)),
                          smoothstep(s + EXPLOSION_AA, s, distance(vec2(end, 0.), pol))),
                      step(width, distance(pol.x, mid)));
        res = mix(res, vec4(hsv2rgb(vec3(1. + (h.w * .2 - .1), smoothstep(.6, .4, time), 1.)), 1.), v * step(0., uv.y));
    }
    
    for(int i=0; i<12; i++){
        vec4 hash = hash41(float(i));
        
        vec3 color = hsv2rgb(vec3(time * .2 + (hash.x * .1 - .05), 1., 1.));
        
        float startTime = hash.x * .2;
        float size = smoothstep(startTime, startTime + .1, time) * (.5 + hash.z * .25)
                   * smoothstep(.65 - startTime, .6 - startTime, time);
        float ang = hash.y * PI - HPI;
        float rad = .3 + smoothstep(.3, .4, time) * (2. - hash.x) * .6;
        vec2 pos = vec2(rad * sin(ang), rad * cos(ang));
        vec4 clr = vec4(color, smoothstep(.01, 0., distance(uv, pos) - size));
        
        
        size = smoothstep(startTime + .2, startTime + .3, time) * (.5 + hash.z * .25);
        rad = smoothstep(startTime + .35, startTime + .4, time) * (2. - hash.x) * .75;
        pos = vec2(rad * sin(ang), rad * cos(ang));
        clr = mix(vec4(clr.rbg, 0.), clr, smoothstep(0., .01, distance(uv, pos) - size));
        
        res = mix(res, clr, clr.a);
    }
    
    return res;
}

float bullsEye(vec2 uv){
    float bullsEye = smoothstep(.15, .1, min(abs(uv.x), abs(uv.y))) * smoothstep(1.1, .9, length(uv));
    return max(bullsEye, step(length(uv), 1.05) * smoothstep(.25, .1, distance(fract(length(uv * 2.)), .5)));
}