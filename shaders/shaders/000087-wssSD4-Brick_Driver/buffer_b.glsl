// Buffer B (buffer) — Brick Driver by spolsh
// https://www.shadertoy.com/view/wssSD4

// Copyright © 2019 Michal Klos
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Brick Driver
//  Entry for TK Game Jam 2019
//  Endless runner with synthwave stylization originally named "Brick Game Racer"

// Awarded by the Jury
//  and 4th place based on audience votes against 55 other entries
//  https://spolsh.itch.io/bgr

// TK Game Jam 2019 is Game development challange
//  about creating game in 48h in Poland, Wrocław 22-24.02.2019
//  https://itch.io/jam/tk-game-jam-2019
//  https://web.facebook.com/events/185669952375258/250811702527749/

// Game aimed for Retro category
//  Themes used in game are synt(h)etic and development, 
//  because graphics is inspired by synthwave and car gets faster the longer you play

// Gameplay is based on Brick Game Racing,
//  https://youtu.be/EdMyKRC8qyU?t=67
//  "lagging" of red cars is somewhat on purpose but can be fixed in future version

// Based on:
// - "80's raymarching" by villedieumorgan. https://shadertoy.com/view/lsVSRt
// - "Cloth Shading" by knarkowicz. https://shadertoy.com/view/4tfBzn
// - "[SH16B] Speed Drive 80" by knarkowicz. https://shadertoy.com/view/4ldGz4
// Uses also snippets from:
// - Digit drawing function by P_Malin (https://www.shadertoy.com/view/4sf3RN)
// - Tiny Planet: Earth by morgan3d https://www.shadertoy.com/view/lt3XDM
// Thnak you guys for sharing it, hope you like the game :)

// Music: Laserhawk - King of the streets
//  https://soundcloud.com/lazerhawk/king-of-the-streets



// Fork of "80's raymarching" by villedieumorgan. https://shadertoy.com/view/lsVSRt
// 2019-02-24 01:09:41


vec3 gBoxPos; 
float gCarLampDist = 1000000.0;
AppState gS;

//-----------------------------------------------------------------
// Digit drawing function by P_Malin (https://www.shadertoy.com/view/4sf3RN)

float SampleDigit(const in float n, const in vec2 vUV)
{		
	if(vUV.x  < 0.0) return 0.0;
	if(vUV.y  < 0.0) return 0.0;
	if(vUV.x >= 1.0) return 0.0;
	if(vUV.y >= 1.0) return 0.0;
	
	float data = 0.0;
	
	     if(n < 0.5) data = 7.0 + 5.0*16.0 + 5.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
	else if(n < 1.5) data = 2.0 + 2.0*16.0 + 2.0*256.0 + 2.0*4096.0 + 2.0*65536.0;
	else if(n < 2.5) data = 7.0 + 1.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
	else if(n < 3.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
	else if(n < 4.5) data = 4.0 + 7.0*16.0 + 5.0*256.0 + 1.0*4096.0 + 1.0*65536.0;
	else if(n < 5.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
	else if(n < 6.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 1.0*4096.0 + 7.0*65536.0;
	else if(n < 7.5) data = 4.0 + 4.0*16.0 + 4.0*256.0 + 4.0*4096.0 + 7.0*65536.0;
	else if(n < 8.5) data = 7.0 + 5.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
	else if(n < 9.5) data = 7.0 + 4.0*16.0 + 7.0*256.0 + 5.0*4096.0 + 7.0*65536.0;
	
	vec2 vPixel = floor(vUV * vec2(4.0, 5.0));
	float fIndex = vPixel.x + (vPixel.y * 4.0);
	
	return mod(floor(data / pow(2.0, fIndex)), 2.0);
}

float PrintInt(const in vec2 uv, const in float value )
{
	float res = 0.0;
	float maxDigits = 1.0+ceil(log2(value)/log2(10.0));
	float digitID = floor(uv.x);
	if( digitID>0.0 && digitID<maxDigits )
	{
        float digitVa = mod( floor( value/pow(10.0,maxDigits-1.0-digitID) ), 10.0 );
        res = SampleDigit( digitVa, vec2(fract(uv.x), uv.y) );
	}

	return res;	
}

float TextSDF(vec2 p, float glyph)
{
    p = abs(p.x - .5) > .5 || abs(p.y - .5) > .5 ? vec2(0.) : p;
    return 2. * (texture(iChannel3, p / 16. + fract(vec2(glyph, 15. - floor(glyph / 16.)) / 16.)).w - 127. / 255.);
}

void HighscoreText(inout vec3 color, vec2 p, in AppState s)
{        
    vec2 scale = vec2(4., 8.);
    vec2 t = floor(p / scale);   
    
    uint v = 0u;    
	v = t.y == 0. ? ( t.x < 4. ? 1751607624u : ( t.x < 8. ? 1919902579u : 14949u ) ) : v;
	v = t.x >= 0. && t.x < 12. ? v : 0u;
    
	float c = float((v >> uint(8. * t.x)) & 255u);
    
    // vec3 textColor = vec3(.3);
	vec3 textColor = vec3(0.75);

    p = (p - t * scale) / scale;
    p.x = (p.x - .5) * .5 + .5;
    float sdf = TextSDF(p, c);
    if (c != 0.)
    {
    	color = mix(textColor, color, smoothstep(-.05, +.05, sdf));
    }
}

void CreditText(inout vec3 color, vec2 p, in AppState s)
{        
    vec2 scale = vec2(4., 8.);
    vec2 t = floor(p / scale);   
    
    uint v = 0u;    
	v = t.y == 0. ? ( t.x < 4. ? 1246186324u : ( t.x < 8. ? 959524914u : ( t.x < 12. ? 2037588026u : ( t.x < 16. ? 1747481710u : ( t.x < 20. ? 1769235753u : ( t.x < 24. ? 539369571u : ( t.x < 28. ? 1702258020u : ( t.x < 32. ? 1836085100u : ( t.x < 36. ? 544501349u : ( t.x < 40. ? 1293973858u : ( t.x < 44. ? 1634231145u : ( t.x < 48. ? 1816862828u : 29551u ) ) ) ) ) ) ) ) ) ) ) ) : v;
	v = t.x >= 0. && t.x < 52. ? v : 0u;    
    
	float c = float((v >> uint(8. * t.x)) & 255u);
    
    // vec3 textColor = vec3(.3);
	vec3 textColor = vec3(0.75);

    p = (p - t * scale) / scale;
    p.x = (p.x - .5) * .5 + .5;
    float sdf = TextSDF(p, c);
    if (c != 0.)
    {
    	color = mix(textColor, color, smoothstep(-.05, +.05, sdf));
    }
}

void SpaceText(inout vec3 color, vec2 p, in AppState s)
{        
    vec2 scale = vec2(4., 8.);
    vec2 t = floor(p / scale);   
    
    uint v = 0u;    
    v = t.y == 0. ? ( t.x < 4. ? 1936028240u : ( t.x < 8. ? 1935351923u : ( t.x < 12. ? 1701011824u : ( t.x < 16. ? 1869881437u : ( t.x < 20. ? 1635021600u : 29810u ) ) ) ) ) : v;
	v = t.x >= 0. && t.x < 24. ? v : 0u;
    
	float c = float((v >> uint(8. * t.x)) & 255u);
    
    // vec3 textColor = vec3(.3);
	vec3 textColor = vec3(1.0);

    p = (p - t * scale) / scale;
    p.x = (p.x - .5) * .5 + .5;
    float sdf = TextSDF(p, c);
    if (c != 0.)
    {
    	color = mix(textColor, color, smoothstep(-.05, +.05, sdf));
    }
}

void DrawGame(inout vec3 color, AppState s, vec2 p)
{
    {              
#ifdef DEBUG
        // game
        vec2 p2 = p;
        p2 += vec2(1.5, 0.7);
        p2 *= vec2(7.0, 4.5);
        p2.y += s.playerCell;

        float cellID = floor(p2.y);
        float rndState = step( 0.5, hash11(cellID) );
        if (cellID < CELLS_HEADSTART)
        {
            rndState = CS_EMPTY_LANE;
        }

        float cellState = CS_EMPTY_LANE;
        cellState = mix( cellState, rndState, step(0.5, mod(cellID, 2.0)) );

        // draw obstacles
        if (cellState == CS_RIGHT_LANE)
        {
            vec2 p3 = (p2 -vec2(0.5) -vec2(0.0, cellID));
            color = mix(mix(color, vec3(1.0, 0.0, 0.0), 0.2), color, smoothstep(0.0, 0.01, Circle(p3, 0.5) ));
        }

        if (cellState == CS_LEFT_LANE)
        {
            vec2 p3 = (p2 -vec2(0.5) -vec2(0.0, cellID));
            p3.x += 1.0;
            color = mix(mix(color, vec3(1.0, 0.0, 0.0), 0.2), color, smoothstep(0.0, 0.01, Circle(p3, 0.5) ));
        }

        // draw player
        if (cellID == s.playerCell)
        {
            vec2 p3 = (p2 -vec2(0.5) -vec2(0.0, cellID));
            if (s.isLeftLine == CS_LEFT_LANE)
            {
                p3.x += 1.0;
            }
            color = mix(mix(color, vec3(0.0, 1.0, 0.0), 0.2), color, smoothstep(0.0, 0.01, Circle(p3, 0.45) ));
        }
#endif
    }
}

/* 
MADE BY MORGAN VILLEDIEU
TW : https://twitter.com/VilledieuMorgan
Click and drag to rotate the camera
*/

//Raymarch settings

#define MAX_MOVEMENT_SPEED 0.9
#define MIN_RADIUS 0.01
#define MAX_RADIUS 0.3
#define STAR_COUNT 30
#define PI 3.14159265358979323
#define TWOPI 6.283185307

#define EPSILON 0.1

#define RADIUS_SEED 1337.0
#define START_POS_SEED 2468.0
#define THETA_SEED 1675.0

#define MIN_DIST 0.001
#define MAX_DIST 32.0
#define MAX_STEPS 96
#define STEP_MULT 0.9
#define FOCAL_LENGTH 0.9

//Scene settings

//#define SHOW_RAY_COST

//Colors
#define SKY_COLOR_1 vec3(49., 33., 66.)/255.
#define SKY_COLOR_2 vec3(0.00,0.05,0.20)

#define SUN_COLOR_2 vec3(87., 33., 73.)/255.
#define SUN_COLOR_1 vec3(1.00, 0.20, 0.60)/2.

#define CAR_COLOR_1 vec3(0.01, 0.2, 0.2)
#define CAR2_COLOR_1 vec3(1.00, 0.0, 0.0)

#define GRID_COLOR_1 vec3(0.00, 0.05, 0.20)
#define GRID_COLOR_2 vec3(26.00, 14.0, 122.0)/255.
#define FOG_COLOR vec3(193.00, 24.0, 123.0)/255.

//Parameters
#define GRID_SIZE 0.50
#define GRID_LINE_SIZE 1.25

#define SUN_DIRECTION vec3( 0.10,0.0,0.)

#define CLOUD_SCROLL vec2(0.002, 0.001)
#define CLOUD_BLUR 2.0
#define CLOUD_SCALE vec2(0.04, 0.10)

#define MOUNTAIN_SCALE 6.0
#define MOUNTAIN_SHIFT 5.3

#define SPEED 11.

const vec3 starColor = vec3(1.0, 1.0, 1.0);

//Color modes
//vec3(#,#,#) Number of bits per channel

//24 bit color
#define RGB888 vec3(8,8,8)
//16 bit color
#define RGB565 vec3(5,6,5)
#define RGB664 vec3(6,6,4)
//8 bit color
#define RGB332 vec3(3,3,2)
#define RGB242 vec3(2,4,2)
#define RGB222 vec3(2,2,2) //+2 unused

#define COLOR_MODE RGB242

//Object IDs
#define SKYDOME 0.
#define FLOOR 1.
#define CAR 2.
#define CAR2 3.

struct MC
{
    vec3 position;
    vec3 normal;
    float dist;
    float steps;
    float id;
};
//==== Distance field operators/functions by iq. ====
vec2 opU(vec2 d1, vec2 d2)
{
    return (d1.x < d2.x) ? d1 : d2;
}

vec2 opS(vec2 d1, vec2 d2)
{
    return (-d1.x > d2.x) ? d1*vec2(-1,1) : d2;
}


vec2 sdBox(vec3 pos, vec3 size, float id)
{
    return vec2(length(max(abs(pos) - size, 0.0)), id);
}

float Box( vec3 p, vec3 b )
{
    vec3 d = abs( p ) - b;
    return min( max( d.x, max( d.y, d.z ) ), 0.0 ) + length( max( d, 0.0 ) );
}

vec2 sdOct( vec3 p, float r, float id )
{
	vec2 s = vec2(1,-1)/sqrt(1.0);
	return vec2(max(max(max(
			abs(dot(p,s.xxx)),abs(dot(p,s.yyx))),
			abs(dot(p,s.yxy))),abs(dot(p,s.xyy))) - r*mix(1.0,1.0/sqrt(3.0),.5), id);
}

vec2 sdSphere(vec3 p, float s, float id)
{
  return vec2(length(p) - s, id);
}


float displace(vec3 p) {
	float height = 10.;
	return ((cos(1.*p.y+0.5)*clamp(sin(1.1*p.x), 0.5, 1.)*sin(0.+2.4)*height*clamp(texture(iChannel0, p.xy/10.).r*0.4, 0.0, 0.5)));
}

//float displace(vec3 p) {
//return ((cos(1.*p.x)*sin(1.1*p.y)/2.*sin(4.*p.z+1.)))*texture(iChannel2, p.xy/10.).r+0.1;
//}

float Union( float a, float b )
{
    return min( a, b );
}

float Intersect( float a, float b )
{
    return max( a, b );
}

float Substract( float a, float b )
{
    return max( a, -b );
}

float SubstractChamfer( float a, float b, float r ) 
{
    return max( max( a, -b ), ( a + r - b ) * 0.70711 );
}

float Plane( vec3 p, vec4 plane ) 
{
    return dot( p, plane.xyz ) + plane.w;
}

vec2 sdPlane(vec3 p, vec4 n, float id)
{
  // n must be normalized
 float bounce = (1.0 - gS.isFailed) * 0.05 * abs(sin(6.5*iTime));
  return vec2( dot(vec3(p.x,p.y, max(p.z + bounce + displace(vec3(p.x, p.y-10., p.z)), p.z)), vec3(n.x, n.y, n.z)) + n.y, id);
}

float Cylinder( vec3 p, float r, float height ) 
{
    float d = length( p.xz ) - r;
    d = max( d, abs( p.y ) - height );
    return d;
}

float Sphere( vec3 p, float s )
{
    return length( p ) - s;
}

vec2 sdColumn(vec3 p, float r, float id)
{
    return vec2(((abs(p.x)+abs(p.y))-r)/sqrt(2.0), id);
}

// From "[SH16B] Speed Drive 80" by knarkowicz. https://shadertoy.com/view/4ldGz4
float Car( vec3 p, float id )
{        
    p *= 3.5;
    
    p.x = -p.x;     
    p.y -= 0.3;
    
    float a = Box( p, vec3( 4.2, 0.9, 1.8 ) );   
    
    vec3 t = p + vec3( -6.0, 0.0, 0.0 );
    Rotate( t.yx, 0.2 );
    float b = Plane( t, vec4( 0.0, -1.0, 0.0, 0.0 ) );
    
    t = p + vec3( -5.0, 0.0, 0.0 );
    Rotate( t.yx, -0.4 );
    float c = Plane( t, vec4( 0.0, 1.0, 0.0, 0.0 ) );    
    
    t = p + vec3( 2.0, -0.2, 0.0 );
    Rotate( t.yx, -0.4 );
    float d = Plane( t, vec4( 0.0, -1.0, 0.0, 0.0 ) );   
    
    t = p + vec3( 2.0, -0.3, 0.0 );
    Rotate( t.yx, -0.05 );
    float e = Plane( t, vec4( 0.0, -1.0, 0.0, 0.0 ) );       
    
    t = p + vec3( 2.0, 1.0, 0.0 );
    Rotate( t.yx, 0.2 );
    float f = Plane( t, vec4( 0.0, 1.0, 0.0, 0.0 ) );     
    
    t = p;
    t.z = abs( t.z );
    t += vec3( -3.9, -0.6, 0.0 );
    float spoiler = Box( t, vec3( 0.2, 0.05, 1.7 ) );
    spoiler = Union( spoiler, Box( t - vec3( 0.0, -0.25, 1.4 ), vec3( 0.2, 0.3, 0.15 ) ) );
    
    float bloom = Box( t + vec3( -0.5, 0.7, 0.0 ), vec3( 0.1, 0.3, 1.5 ) );	
    if (id == CAR)
      gCarLampDist = min( gCarLampDist, bloom );
        
    t = p + vec3( 1.0, -0.6, 0.0 );
    Rotate( t.yx, -0.4 );
    float frontWindow = Box( t, vec3( 0.6, 0.05, 1.6 ) );
    
    t = p + vec3( -2.5, -0.7, 0.0 );
    Rotate( t.yx, 0.2 );
    float backWindow = Box( t, vec3( 1.0, 0.05, 1.6 ) );
    
    float body = Union( Substract( a, Union( Union( Union( b, c ), Intersect( d, e ) ), f ) ), spoiler );
    
    t = p;
    t.z = -abs( t.z );
    t += vec3( 0.0, -0.8, 1.2 );
    Rotate( t.yz, -0.9 );
    float sideCutPlanes = Plane( t, vec4( 0.0, -1.0, 0.0, 0.0 ) );      
    
    body = SubstractChamfer( body, Union( backWindow, frontWindow ), 0.1 );
    body = SubstractChamfer( body, sideCutPlanes, 0.05 );
    
    p.x += 0.1;
    p.xz = abs( p.xz );
    t = p.xzy - vec3( 2.4, 1.5, -0.7 );
    float wheel = Cylinder( t, 0.7, 1.0 );
    body = Substract( body, wheel );
    
    wheel = Substract( Cylinder( t, 0.55, 0.3 ), Sphere( t + vec3( 0.0, -0.15, 0.0 ), 0.35 ) );
    
    body = Union( body, wheel );
    
    body /= 3.5;
    
    return body;
}

//Distance to the scene
vec2 Scene(vec3 p)
{	
    p = vec3(p.x, p.z, -p.y); // Coord fix
    
    vec2 d = vec2(MAX_DIST, SKYDOME);    
	vec3 pEnv = p;
    d = opU(d, sdPlane(pEnv, vec4(0, 0,-1, 0), FLOOR));
                  
	vec3 boxSize = vec3(0.6*vec2(0.9, 0.6), 0.2);
    vec3 boxSizeObs = boxSize;
    boxSizeObs.z *= 5.0;

    { // obstacles 
        vec3 pObs = p - gBoxPos;		
        float c = pModInterval1(pObs.x, 8.0*boxSize.x, -5.0, 10.0);   
        float cellID = gS.playerCell + c;        
		float cellState = GetCellState(cellID, gS.seed);                

        if (cellState == CS_EMPTY_LANE)
			pObs.y = -1.0;
        else
			pObs.y -= mix( -1.0, 1.0, step(cellState, CS_LEFT_LANE - 0.1));

        pObs.y += fbm3(vec3(100000.0*cellID)) * 0.5;       
        d = opU(d, vec2( Car(vec3(pObs.x, -pObs.z, pObs.y) -vec3(0.0, 0.3, 0.0), CAR2), CAR2 )); 
    }   
	
    { // player        
        vec3 pBox = p - gBoxPos - vec3(0.0, gS.isLeftLine == CS_LEFT_LANE ? -0.5 : 0.5, 0.0);
        pBox.y += fbm3(vec3(100000.0*gS.playerCell)) * 0.2;
    	d = opU(d, vec2( Car(vec3(pBox.x, -pBox.z, pBox.y) -vec3(0.0, 0.3, 0.0), CAR), CAR )); 
    }
    
	return d;
}

//Surface normal at the current position
vec3 Normal(vec3 p)
{
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*Scene(p+0.0005*e).x;
    }
    return normalize(n);
}

//Raymarch the scene with the given ray
MC MR(vec3 orig,vec3 dir)
{
    float steps = 0.0;
    float dist = 0.0;
    float id = 0.0;
    
    for(int i = 0;i < MAX_STEPS;i++)
    {
        vec2 object = Scene(orig + dir * dist);
        
        //Add the sky dome and have it follow the camera.
        object = opU(object, -sdSphere(dir * dist, MAX_DIST, SKYDOME));        
        dist += object.x * STEP_MULT;        
        id = object.y;
        
        steps++;
        
        if(abs(object.x) < MIN_DIST * dist)
        {
            break;
        }
    }
    
    MC result;
    
    result.position = orig + dir * dist;
    result.normal = Normal(result.position);
    result.dist = dist;
    result.steps = steps;
    result.id = id;
    
    return result;
}

//Scene texturing/shading
vec3 Shade(MC hit, vec3 direction, vec3 camera)
{
    vec3 color = vec3(0.0);
    vec3 rd = color;
    vec3 skydomeColor = color;
    
    if(hit.id == SKYDOME)
    {
    	color = mix(SKY_COLOR_1*1.4, SKY_COLOR_2, hit.position.y/9.0);
       
        vec3 sunDir = normalize(SUN_DIRECTION);       
		float sun = smoothstep(0.987, 0.99, dot(direction, sunDir));
        sun -= smoothstep(0.1, 0.9, 0.5);			        
		float sunStripesPos = 2.0*pow(0.6*hit.position.y-0.1, 1.5);
        float stripes = clamp( smoothstep(0.5, 0.51, abs(-1.0+2.0*fract(sunStripesPos))), 0.0, 1.0);		        
		vec3 sunCol = mix(SUN_COLOR_1, SUN_COLOR_2*1.2, -hit.position.y/2.5);        
        color = mix(color, sunCol, min(sun, stripes)) + texture(iChannel2, vec2(2.) * 0.1).rgb * 0.07;		        
    }      

    if(hit.id == FLOOR)
    {
        vec2 uv = abs(mod(hit.position.xz + GRID_SIZE/2.0, GRID_SIZE) - GRID_SIZE/2.0); 
        
        uv /= fwidth(hit.position.xz);
                                                       
        float gln = min(min(uv.x, uv.y), 1.) / GRID_SIZE;
    	color = mix(GRID_COLOR_1, GRID_COLOR_2, 0.7 - smoothstep(0.0, GRID_LINE_SIZE / GRID_SIZE, gln));
        
		vec3 normal = vec3(0.,0.0,-0.5);
        vec3 rfld = reflect( direction, normal );
        float reflectstrength = 1.-abs(dot( direction, normal ));
        color *= reflectstrength;
        
        vec3 spotColor  = vec3( 0.54, 0.42, 0.78 ) * 300.0;
        vec3 spotPos    = gBoxPos + vec3( 0.5, -0.75, 0.0 ) + vec3(0.0, 0.0, gS.isLeftLine == CS_LEFT_LANE ? -0.5 : 0.5);
        vec3 spotDir    = normalize( spotPos.xzy - hit.position.xzy );
        float spotAtt = 1.0 / pow( length( spotPos - hit.position ), 2.0 );
        spotAtt *= saturate( -spotDir.x * 6.0 - 4.0 );
        color += color * spotColor * spotAtt * saturate( dot( normal, spotDir ) );  	

        // red trail      
        float trailX = hit.position.x - gBoxPos.x -2.0;
        color += 0.9 * vec3( 1.0, 0.0, 0.0 ) 
            * saturate( exp( -5.2 * abs( hit.position.z -(gS.isLeftLine == CS_LEFT_LANE ? -0.5 : 0.5)) ) )
            * saturate(  1.0 + trailX * 0.02 )
            * saturate( -0.6 - trailX * 0.3 );
    } 
    
	if(hit.id == CAR)
    {
        vec2 uv = abs(mod(hit.position.xz + GRID_SIZE/2.0, GRID_SIZE) - GRID_SIZE/2.0); 
        
        uv /= fwidth(hit.position.xz);
                                                       
        float gln = min(min(uv.x, uv.y), 1.) / GRID_SIZE;
    	color = mix((0.5*CAR_COLOR_1), (2.0*GRID_COLOR_2), 0.8 - smoothstep(0.0, GRID_LINE_SIZE / GRID_SIZE, gln));
        
		vec3 normal = vec3(0.,0.0,-0.5);
        vec3 rfld = reflect( direction, normal );
        float reflectstrength = 2.-abs(dot( direction, normal ));
        color *= reflectstrength;
        
        vec3 spotColor  = vec3( 0.54, 0.42, 0.78 ) * 300.0;
        vec3 spotPos    = gBoxPos + vec3( 0.5, -0.75, 0.0 ) + vec3(0.0, 0.0, gS.isLeftLine == CS_LEFT_LANE ? -0.5 : 0.5);
        vec3 spotDir    = normalize( spotPos.xzy - hit.position.xzy );
        float spotAtt = 1.0 / pow( length( spotPos - hit.position ), 2.0 );
        spotAtt *= saturate( -spotDir.x * 6.0 - 4.0 );
        color += color * spotColor * spotAtt * saturate( dot( normal, spotDir ) );         
    } 

	if(hit.id == CAR2)
    {
        vec2 uv = abs(mod(hit.position.xz + GRID_SIZE/2.0, GRID_SIZE) - GRID_SIZE/2.0);         
        uv /= fwidth(hit.position.xz);                                                       
        float gln = min(min(uv.x, uv.y), 1.) / GRID_SIZE;
    	color = mix((0.5*CAR2_COLOR_1), (2.0*GRID_COLOR_2), 0.8 - smoothstep(0.0, GRID_LINE_SIZE / GRID_SIZE, gln));
    } 
    
    //Distance fog
    color += mix(GRID_COLOR_2, FOG_COLOR, pow(hit.dist, 1.01) )/70.;
    
    return color;
}

// Based on "[SH16B] Speed Drive 80" by knarkowicz. https://shadertoy.com/view/4ldGz4
vec3 SceneBloom()
{
    return vec3( 1.0, 0.2, 0.1 ) * 1.0 * vec3( exp( -gCarLampDist * 0.5 ) );
}
    
mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void DrawScene(inout vec3 color, AppState s, vec2 p)
{
    vec2 mo = iMouse.xy/iResolution.xy;    
	   
    gBoxPos = vec3(8.0 * (s.playerCell + fract(2.0 * s.timeAccumulated)), 0.0, 0.0);
    
    float arm = mix(4.0, 8.0, s.paceScale );
    
	vec3 gOrig = gBoxPos;
   
#ifdef DEBUG
    gOrig += vec3(
        arm*cos(6.0*mo.x),
        0.0 + 4.0*mo.y,
        arm*sin(6.0*mo.x)
    );
#else
	vec3 gameOffset = vec3(
        arm*cos(1.0*3.14 + 0.1 * sin(0.5*iTime)),
        1.5 + 0.5 * s.paceScale,
        arm*sin(1.0*3.14 + 0.1 * sin(0.5*iTime))
    );
    vec3 failOffset = vec3(
        4.0*cos(0.1*iTime),
        1.5,
        4.0*sin(0.1*iTime)
    );
    
    gOrig += mix(
        gameOffset,
        mix(
            gameOffset,
            failOffset,
            smoothstep(0.0, 2.0, iTime - s.timeFailed)
        ),
        step(s.stateID, GS_SPLASH - 0.1)
    );

#endif
    
    gOrig.y += fbm3(100.0*gOrig) * 0.1 * s.paceScale;
    
    vec3 gLookat = gBoxPos + vec3( 0.0, 0.1, 0.0 );	
     
    mat3 ca = setCamera( gOrig, gLookat, 0.0);
    float fov = mix(2.2, 4.0, s.paceScale );
    vec3 dir = ca * normalize( vec3(vec2(p.x, p.y), fov) );
        
    MC hit = MR(gOrig, dir);
    
    vec3 shade = Shade(hit, dir, gOrig );
    vec3 bloom = SceneBloom();                
    color = 2.5 * shade + bloom;
    
    //particles
    float angle = atan(dir.z, dir.y)/(atan(iTime)-1.*1.*PI);
    angle -= floor(angle);
    float rad = length(vec2(dir.x * 0.02, dir.z));
 
    if (s.isFailed < 0.5)
    {
        float timeScale = mix(20.0, 50.0, s.paceScale);
        float dist3Scale = mix(100.0, 25.0, s.paceScale);
        float opacityScale = mix(0.2, 1.0, s.paceScale);

        float angleFract = fract(angle*10.5);
        float angleRnd = floor(angle*180.);
        float angleRnd1 = fract(angleRnd*fract(angleRnd*.72035)*1.1);
        float angleRnd2 = fract(angleRnd*fract(angleRnd*.82657)*1.724);
        float t = iTime*timeScale+angleRnd1*1000.;
        float radDist = sqrt(angleRnd2+.1);
        float adist = radDist/rad*.2;
        float dist = (t*.2+adist);
        dist = abs(fract(dist/20.)-.5);

        color += opacityScale * max(0.0,.7-dist*dist3Scale/adist)*(0.5-abs(angleFract-.5))*1./adist/radDist;        
    }
    
    // score counter text    
    if (s.isFailed < 0.5)
    {
        vec2 p1 = p;
        p1 *= 7.0;
        p1 -= vec2(-1.0, 5.5);
        p1 -= vec2(-0.5 * ceil(log2(s.score)/log2(10.0)), 0.0);
        p1 *= mix( 0.9, 1.0, abs(sin(2.0 * 3.14 * iTime)) * step(s.isFailed, 0.5) );
        color += PrintInt(p1, s.score);
    }
}

void DrawSplash(inout vec3 color, AppState s, vec2 p)
{
    vec2 resMult = floor(iResolution.xy / 64.);
    float resRcp = 1. / max(min(resMult.x, resMult.y), 1.);
    vec2 screenSize = floor(iResolution.xy * resRcp);
    vec2 pixel      = floor(gl_FragCoord.xy * resRcp - screenSize * .5);
    SpriteLeft(color, pixel  + vec2(32,8));
    SpriteRight(color, pixel + vec2(0,8));

    vec2 p2 = p;
    p2 *= 55. + 5. * abs(sin(2.0*iTime));
    p2 -= vec2(-40, -25.0);
    SpaceText(color, p2, s);

    vec2 p4 = p;
    p4 *= 90.;
    p4 -= vec2(-100, -80.0);
    CreditText(color, p4, s);

    if (s.highscore > 0.0)
    {
        vec2 p5 = p;
        p5 *= 50.;
        p5 -= vec2(-28, -38.0);
        HighscoreText(color, p5, s);
    }

    vec2 p3 = p;
    p3 *= 10.0;
    p3 -= vec2( 3.5, -7.3);
    p3 -= vec2(-0.5 * ceil(log2(s.score)/log2(10.0)), 0.0);
    float scoreColor = PrintInt(p3, s.highscore);
    color = mix(color, vec3(1.0), scoreColor);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
	vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1. + 2. * q;
	p.x *= iResolution.x / iResolution.y;
       
    AppState s;
    LoadState(iChannel2, s);
    
    gS = s;
    
    vec3 color = vec3(0.0);
        
    DrawScene(color, s, p);
    DrawGame(color, s, p);    
     
    if ( s.stateID == GS_SPLASH )
	 	DrawSplash(color, s, p);

	fragColor = vec4(color, 1.);
}