// Common (common) — Brick Driver by spolsh
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


// from Tiny Planet: Earth by morgan3d https://www.shadertoy.com/view/lt3XDM
float hash(float n) { return fract(sin(n) * 1e4); }
float noise(vec3 x) { const vec3 step = vec3(110, 241, 171); vec3 i = floor(x); vec3 f = fract(x); float n = dot(i, step); vec3 u = f * f * (3.0 - 2.0 * f); return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x), mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y), mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x), mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z); }

#define DEFINE_FBM(name, OCTAVES) float name(vec3 x) { float v = 0.0; float a = 0.5; vec3 shift = vec3(100); for (int i = 0; i < OCTAVES; ++i) { v += a * noise(x); x = x * 2.0 + shift; a *= 0.5; } return v; }
DEFINE_FBM(fbm3, 3)


// #define DEBUG	// enables camera rotation with mouse and draws 2d game on left side of screen
// #define AI		// makes car avoid obstacles on its own
#define ZERO (min(iFrame,0))

const float keys[] = float[] ( 
     32.0, // space
	 37.0, // Arrow left
	 38.0, // Arrow up
	 39.0, // Arrow right
	 40.0, // Arrow down
	 65.0, // A
	 68.0, // D
	 87.0, // W
	 83.0, // S
	100.0, // d
	115.0, // s
	119.0, // w
	197.0  // a 
);

// Game State
const float GS_SPLASH = 0.0;
const float GS_GAME   = 1.0;

// Cell State
const float CS_RIGHT_LANE = 0.0;
const float CS_LEFT_LANE  = 1.0;
const float CS_EMPTY_LANE = 2.0;

const float CELLS_HEADSTART = 4.0;

// Based on "Cloth Shading" by knarkowicz. https://shadertoy.com/view/4tfBzn
struct AppState
{
	float stateID;    
	float isSpacePressed;    
    float timeFailed;
	float isLeftLine;
    
	float isFailed;
    float playerCell;
    float score;
    float highscore;
    
    float timeAccumulated;
    float paceScale;    
    float seed;
    float timeStarted;
};

vec4 LoadValue(sampler2D tex, int x, int y)
{
    return texelFetch(tex, ivec2(x, y), 0);
}

void LoadState(sampler2D tex, out AppState s)
{
    vec4 data;

	data = LoadValue(tex, 0, 0);
	s.isSpacePressed = data.x;
    s.stateID      = data.y;
	s.timeFailed   = data.z;
    s.isLeftLine   = data.w;
    
    data = LoadValue(tex, 1, 0);
    s.isFailed   = data.x;
    s.playerCell = data.y;
    s.score		 = data.z;
    s.highscore	 = data.w;
    
    data = LoadValue(tex, 2, 0);
    s.timeAccumulated = data.x;
    s.paceScale       = data.y;    
	s.seed            = data.z;
    s.timeStarted     = data.w;
}

void StoreValue(vec2 re, vec4 va, inout vec4 fragColor, vec2 fragCoord)
{
    fragCoord = floor(fragCoord);
    fragColor = (fragCoord.x == re.x && fragCoord.y == re.y) ? va : fragColor;
}

vec4 SaveState(in AppState s, in vec2 fragCoord, int iFrame)
{
    if (iFrame <= 0)
    {
		s.stateID = GS_SPLASH;
		s.isSpacePressed  = 0.0;
		s.timeFailed      = 0.0;
        s.isLeftLine      = 0.0;
        
        s.isFailed        = 0.0;
        s.playerCell      = 0.0;
        s.score           = 0.0;
        s.highscore       = 0.0;
        
        s.paceScale       = 0.0;
        s.timeAccumulated = 0.0;
        s.seed            = fbm3(iDate.yzw);
        s.timeStarted     = 0.0;
    }
    
    vec4 ret = vec4(0.);
	StoreValue(vec2(0., 0.), vec4(s.isSpacePressed,  s.stateID,    s.timeFailed,   s.isLeftLine),   ret, fragCoord);
	StoreValue(vec2(1., 0.), vec4(s.isFailed,        s.playerCell, s.score,        s.highscore),    ret, fragCoord);
    StoreValue(vec2(2., 0.), vec4(s.timeAccumulated, s.paceScale,  s.seed,         s.timeStarted),  ret, fragCoord);
    return ret;
}

float hash11(float p)
{
	vec3 p3  = fract(vec3(p) * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float GetCellRandomValue(float cellID, float seed)
{
    return step(0.5, hash11( cellID + seed ));
}

float GetCellState(float cellID, float seed)
{
    float rndState = GetCellRandomValue( cellID, seed );
    rndState = mix(rndState, CS_EMPTY_LANE, step(cellID, CELLS_HEADSTART));

    float cellState = CS_EMPTY_LANE;
    return mix( cellState, rndState, step(0.5, mod(cellID, 2.0)) );
}

///////////////////////////////////////////////////////////////////////////
// Utils

float saturate(float x)
{
    return clamp(x, 0., 1.);
}

void Rotate(inout vec2 p, float a) 
{
    p = cos(a) * p + sin(a) * vec2(p.y, -p.x);
}

// from http://mercury.sexy/hg_sdf/
float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = mod(p+halfsize, size) - halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}

// based on https://www.shadertoy.com/view/ll2BWz
void SpriteLeft(inout vec3 color, vec2 p)
{
    uint v = 0u;
	v = p.y == 31. ? 0u : v;
	v = p.y == 30. ? 0u : v;
	v = p.y == 29. ? 0u : v;
	v = p.y == 28. ? 0u : v;
	v = p.y == 27. ? (p.x < 8. ? 0u : (p.x < 16. ? 2004317952u : (p.x < 24. ? 2003828855u : 489335u))) : v;
	v = p.y == 26. ? (p.x < 8. ? 0u : (p.x < 16. ? 2004317952u : (p.x < 24. ? 2003830647u : 7829367u))) : v;
	v = p.y == 25. ? (p.x < 8. ? 0u : (p.x < 16. ? 30464u : (p.x < 24. ? 124782448u : 7798784u))) : v;
	v = p.y == 24. ? (p.x < 8. ? 0u : (p.x < 16. ? 2004317952u : (p.x < 24. ? 2003830647u : 7829367u))) : v;
	v = p.y == 23. ? (p.x < 8. ? 0u : (p.x < 16. ? 489216u : (p.x < 24. ? 2003830647u : 7829367u))) : v;
	v = p.y == 22. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 139537u : (p.x < 24. ? 124782448u : 7798784u))) : v;
	v = p.y == 21. ? (p.x < 8. ? 286330880u : (p.x < 16. ? 1981878545u : (p.x < 24. ? 122685303u : 34672896u))) : v;
	v = p.y == 20. ? (p.x < 8. ? 286330880u : (p.x < 16. ? 1628508433u : (p.x < 24. ? 319815799u : 18088209u))) : v;
	v = p.y == 19. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 286261248u : (p.x < 24. ? 286326784u : 286326801u))) : v;
	v = p.y == 18. ? (p.x < 8. ? 286261248u : (p.x < 16. ? 268435456u : (p.x < 24. ? 286326784u : 286330880u))) : v;
	v = p.y == 17. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 268435456u : (p.x < 24. ? 17895425u : 286331136u))) : v;
	v = p.y == 16. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 268435456u : (p.x < 24. ? 17895681u : 286331152u))) : v;
	v = p.y == 15. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 285212672u : (p.x < 24. ? 286331137u : 285282577u))) : v;
	v = p.y == 14. ? (p.x < 8. ? 17891328u : (p.x < 16. ? 286261248u : (p.x < 24. ? 286331137u : 286265617u))) : v;
	v = p.y == 13. ? (p.x < 8. ? 17891328u : (p.x < 16. ? 286326784u : (p.x < 24. ? 286330881u : 286261265u))) : v;
	v = p.y == 12. ? (p.x < 8. ? 17891328u : (p.x < 16. ? 286330880u : (p.x < 24. ? 286330880u : 286261248u))) : v;
	v = p.y == 11. ? (p.x < 8. ? 17891328u : (p.x < 16. ? 17895696u : (p.x < 24. ? 17895680u : 285212672u))) : v;
	v = p.y == 10. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 1118481u : (p.x < 24. ? 286331136u : 286261249u))) : v;
	v = p.y == 9. ? (p.x < 8. ? 286326784u : (p.x < 16. ? 4369u : (p.x < 24. ? 285282560u : 286261265u))) : v;
	v = p.y == 8. ? (p.x < 8. ? 286331136u : (p.x < 16. ? 17u : (p.x < 24. ? 268505344u : 286261521u))) : v;
	v = p.y == 7. ? (p.x < 8. ? 286331153u : (p.x < 16. ? 0u : (p.x < 24. ? 69888u : 17830161u))) : v;
	v = p.y == 6. ? (p.x < 8. ? 17895697u : (p.x < 16. ? 0u : (p.x < 24. ? 4352u : 17826064u))) : v;
	v = p.y == 5. ? (p.x < 8. ? 17895696u : (p.x < 16. ? 0u : (p.x < 24. ? 4368u : 17825792u))) : v;
	v = p.y == 4. ? (p.x < 8. ? 17891328u : (p.x < 16. ? 0u : (p.x < 24. ? 4352u : 0u))) : v;
	v = p.y == 3. ? 0u : v;
	v = p.y == 2. ? 0u : v;
	v = p.y == 1. ? 0u : v;
	v = p.y == 0. ? 0u : v;
    v = p.x >= 0. && p.x < 32. ? v : 0u;

    float i = float((v >> uint(4. * p.x)) & 15u);
    color = i == 1. ? vec3(1, 0, 0.8) : color;
    color = i == 2. ? vec3(1, 0.2, 0.8) : color;
    color = i == 3. ? vec3(1, 0.4, 0.8) : color;
    color = i == 4. ? vec3(1, 0.4, 1) : color;
    color = i == 5. ? vec3(1, 0.6, 1) : color;
    color = i == 6. ? vec3(1, 0.8, 1) : color;
    color = i == 7. ? vec3(1) : color;
}

void SpriteRight(inout vec3 color, vec2 p)
{
    uint v = 0u;
	v = p.y == 31. ? 0u : v;
	v = p.y == 30. ? 0u : v;
	v = p.y == 29. ? 0u : v;
	v = p.y == 28. ? 0u : v;
	v = p.y == 27. ? (p.x < 8. ? 2415919248u : (p.x < 16. ? 629145u : (p.x < 24. ? 2576351241u : 0u))) : v;
	v = p.y == 26. ? (p.x < 8. ? 2566914192u : (p.x < 16. ? 629145u : (p.x < 24. ? 10027017u : 0u))) : v;
	v = p.y == 25. ? (p.x < 8. ? 160432272u : (p.x < 16. ? 0u : (p.x < 24. ? 626697u : 0u))) : v;
	v = p.y == 24. ? (p.x < 8. ? 160432272u : (p.x < 16. ? 0u : (p.x < 24. ? 39321u : 0u))) : v;
	v = p.y == 23. ? (p.x < 8. ? 160432272u : (p.x < 16. ? 0u : (p.x < 24. ? 629145u : 0u))) : v;
	v = p.y == 22. ? (p.x < 8. ? 2566914192u : (p.x < 16. ? 0u : (p.x < 24. ? 10063881u : 0u))) : v;
	v = p.y == 21. ? (p.x < 8. ? 2566914192u : (p.x < 16. ? 629145u : (p.x < 24. ? 142606345u : 17895424u))) : v;
	v = p.y == 20. ? (p.x < 8. ? 144u : (p.x < 16. ? 620185u : (p.x < 24. ? 355467273u : 286265636u))) : v;
	v = p.y == 19. ? (p.x < 8. ? 272u : (p.x < 16. ? 256u : (p.x < 24. ? 286261248u : 17825809u))) : v;
	v = p.y == 18. ? (p.x < 8. ? 272u : (p.x < 16. ? 16u : (p.x < 24. ? 286261248u : 286326784u))) : v;
	v = p.y == 17. ? (p.x < 8. ? 273u : (p.x < 16. ? 286326801u : (p.x < 24. ? 17891328u : 17895424u))) : v;
	v = p.y == 16. ? (p.x < 8. ? 268435729u : (p.x < 16. ? 286330881u : (p.x < 24. ? 17895425u : 1118464u))) : v;
	v = p.y == 15. ? (p.x < 8. ? 285212945u : (p.x < 16. ? 1118465u : (p.x < 24. ? 17895424u : 69905u))) : v;
	v = p.y == 14. ? (p.x < 8. ? 285212945u : (p.x < 16. ? 1118464u : (p.x < 24. ? 286330880u : 4369u))) : v;
	v = p.y == 13. ? (p.x < 8. ? 17826065u : (p.x < 16. ? 69904u : (p.x < 24. ? 286326784u : 17u))) : v;
	v = p.y == 12. ? (p.x < 8. ? 17895696u : (p.x < 16. ? 69904u : (p.x < 24. ? 286330880u : 0u))) : v;
	v = p.y == 11. ? (p.x < 8. ? 1118464u : (p.x < 16. ? 17895696u : (p.x < 24. ? 286330880u : 0u))) : v;
	v = p.y == 10. ? (p.x < 8. ? 1118464u : (p.x < 16. ? 4368u : (p.x < 24. ? 286330880u : 1u))) : v;
	v = p.y == 9. ? (p.x < 8. ? 1118464u : (p.x < 16. ? 272u : (p.x < 24. ? 268505088u : 17u))) : v;
	v = p.y == 8. ? (p.x < 8. ? 69888u : (p.x < 16. ? 272u : (p.x < 24. ? 69632u : 273u))) : v;
	v = p.y == 7. ? (p.x < 8. ? 69632u : (p.x < 16. ? 268435728u : (p.x < 24. ? 69888u : 4368u))) : v;
	v = p.y == 6. ? (p.x < 8. ? 69632u : (p.x < 16. ? 16777488u : (p.x < 24. ? 4352u : 256u))) : v;
	v = p.y == 5. ? (p.x < 8. ? 0u : (p.x < 16. ? 69888u : (p.x < 24. ? 4352u : 0u))) : v;
	v = p.y == 4. ? (p.x < 8. ? 0u : (p.x < 16. ? 0u : (p.x < 24. ? 256u : 0u))) : v;
	v = p.y == 3. ? 0u : v;
	v = p.y == 2. ? 0u : v;
	v = p.y == 1. ? 0u : v;
	v = p.y == 0. ? 0u : v;
    v = p.x >= 0. && p.x < 32. ? v : 0u;

    float i = float((v >> uint(4. * p.x)) & 15u);
    color = i == 1. ? vec3(1, 0, 0.73) : color;
    color = i == 2. ? vec3(1, 0.0039, 0.73) : color;
    color = i == 3. ? vec3(1, 0.063, 0.75) : color;
    color = i == 4. ? vec3(1, 0.12, 0.76) : color;
    color = i == 5. ? vec3(1, 0.41, 0.84) : color;
    color = i == 6. ? vec3(1, 0.64, 0.9) : color;
    color = i == 7. ? vec3(1, 0.72, 0.93) : color;
    color = i == 8. ? vec3(1, 0.81, 0.95) : color;
    color = i == 9. ? vec3(1) : color;
}

