// Buffer A (buffer) — Quake / Introduction by adx
// https://www.shadertoy.com/view/lsKfWd

////////////////////////////////////////////////////////////////
// Buffer A: persistent state handling
// - procedural texture generation
// - mipmap generation
// - player input/physics
// - partial map data serialization
// - perf stats
////////////////////////////////////////////////////////////////

// config.cfg //////////////////////////////////////////////////

#define INVERT_MOUSE			0
#define NOCLIP					0

#define MOVE_FORWARD_KEY1		KEY_W
#define MOVE_FORWARD_KEY2		KEY_UP
#define MOVE_FORWARD_KEY3		KEY_Z			// azerty
#define MOVE_LEFT_KEY1			KEY_A
#define MOVE_LEFT_KEY2			KEY_Q			// azerty
#define MOVE_BACKWARD_KEY1		KEY_S
#define MOVE_BACKWARD_KEY2		KEY_DOWN
#define MOVE_RIGHT_KEY1			KEY_D
#define MOVE_RIGHT_KEY2			unassigned
#define MOVE_UP_KEY1			KEY_SPACE
#define MOVE_UP_KEY2			unassigned
#define MOVE_DOWN_KEY1			KEY_C
#define MOVE_DOWN_KEY2			unassigned
#define RUN_KEY1				KEY_SHIFT
#define RUN_KEY2				unassigned
#define LOOK_LEFT_KEY1			KEY_LEFT
#define LOOK_LEFT_KEY2			unassigned
#define LOOK_RIGHT_KEY1			KEY_RIGHT
#define LOOK_RIGHT_KEY2			unassigned
#define LOOK_UP_KEY1			KEY_PGDN
#define LOOK_UP_KEY2			unassigned
#define LOOK_DOWN_KEY1			KEY_DELETE
#define LOOK_DOWN_KEY2			unassigned
#define CENTER_VIEW_KEY1		KEY_END
#define CENTER_VIEW_KEY2		unassigned
#define STRAFE_KEY1				KEY_ALT
#define STRAFE_KEY2				unassigned
#define RESPAWN_KEY1			KEY_BKSP
#define RESPAWN_KEY2			KEY_HOME
#define ATTACK_KEY1				KEY_E
#define ATTACK_KEY2				KEY_F

#define MENU_KEY1				KEY_ESC
#define MENU_KEY2				KEY_TAB

#define SHOW_PERF_STATS_KEY		KEY_P
#define TOGGLE_TEX_FILTER_KEY	KEY_T
#define TOGGLE_LIGHT_SHAFTS_KEY	KEY_L
#define TOGGLE_CRT_EFFECT_KEY	KEY_V

const float
	SENSITIVITY					= 1.0,
	MOUSE_FILTER				= 0.0,		// mostly for video recording
	TURN_SPEED					= 180.0,	// keyboard turning rate, in degrees per second
	WALK_SPEED					= 400.0,
	JUMP_SPEED					= 270.0,
    STAIR_CLIMB_SPEED			= 128.0,
    STOP_SPEED					= 100.0,
    
    GROUND_ACCELERATION			= 10.0,
    AIR_ACCELERATION			= 1.0,

    GROUND_FRICTION				= 4.0,
	NOCLIP_START_FRICTION		= 18.0,
	NOCLIP_STOP_FRICTION		= 12.0,

    ROLL_ANGLE					= 2.0,		// maximum roll angle when moving sideways
	ROLL_SPEED					= 200.0,	// sideways speed at which the roll angle reaches its maximum
	BOB_CYCLE					= 0.6,		// seconds
	BOB_SCALE					= 0.02,

    AUTOPITCH_DELAY				= 2.0,		// seconds between last mouse look and automatic pitch adjustment
    STAIRS_PITCH				= 10.0,

    RECOIL_ANGLE				= 2.0,
    WEAPON_SPREAD				= 0.05,		// slightly higher than in Quake, for dramatic effect
    RATE_OF_FIRE				= 2.0;

////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////
////////////////////////////////////////////////////////////////

//#define GENERATE_TEXTURES		(1<<MATERIAL_WIZMET1_1) | (1<<MATERIAL_WBRICK1_5)
#define GENERATE_TEXTURES		-1
#define ALWAYS_REFRESH			0
#define WRITE_MAP_DATA			1
#define ENABLE_MENU				1

////////////////////////////////////////////////////////////////

const int
	KEY_A = 65, KEY_B = 66, KEY_C = 67, KEY_D = 68, KEY_E = 69, KEY_F = 70, KEY_G = 71, KEY_H = 72, KEY_I = 73, KEY_J = 74,
	KEY_K = 75, KEY_L = 76, KEY_M = 77, KEY_N = 78, KEY_O = 79, KEY_P = 80, KEY_Q = 81, KEY_R = 82, KEY_S = 83, KEY_T = 84,
	KEY_U = 85, KEY_V = 86, KEY_W = 87, KEY_X = 88, KEY_Y = 89, KEY_Z = 90,

    KEY_0 = 48, KEY_1 = 49, KEY_2 = 50, KEY_3 = 51, KEY_4 = 52, KEY_5 = 53, KEY_6 = 54, KEY_7 = 55, KEY_8 = 56, KEY_9 = 57,

	KEY_PLUS		= 187,
	KEY_MINUS		= 189,
	KEY_EQUAL		= KEY_PLUS,

    // firefox...
    KEY_PLUS_FF		= 61,
    KEY_MINUS_FF	= 173, 

    KEY_SHIFT		= 16,
	KEY_CTRL		= 17,
	KEY_ALT			= 18,
    
    KEY_ESC			= 27,
	
    KEY_BKSP 		=  8,
    KEY_TAB			=  9,
	KEY_END			= 35,
	KEY_HOME		= 36,
	KEY_INS			= 45,
	KEY_DEL			= 46,
	KEY_INSERT		= KEY_INS,
	KEY_DELETE		= KEY_DEL,

	KEY_ENTER		= 13,
	KEY_SPACE 		= 32,
	KEY_PAGE_UP 	= 33,
	KEY_PAGE_DOWN 	= 34,
	KEY_PGUP 		= KEY_PAGE_UP,
	KEY_PGDN 		= KEY_PAGE_DOWN,

	KEY_LEFT		= 37,
	KEY_UP			= 38,
	KEY_RIGHT		= 39,
	KEY_DOWN		= 40,
	
	unassigned		= 0;

////////////////////////////////////////////////////////////////

float is_key_down(int code)				{ return code != 0 ? texelFetch(iChannel0, ivec2(code, 0), 0).r : 0.; }
float is_key_pressed(int code)			{ return code != 0 ? texelFetch(iChannel0, ivec2(code, 1), 0).r : 0.; }

////////////////////////////////////////////////////////////////

float cmd(int code1, int code2)			{ return max(is_key_down(code1), is_key_down(code2)); }
float cmd(int c1, int c2, int c3)		{ return max(is_key_down(c1), max(is_key_down(c2), is_key_down(c3))); }
float cmd_press(int code1, int code2)	{ return max(is_key_pressed(code1), is_key_pressed(code2)); }

float cmd_move_forward()				{ return cmd(MOVE_FORWARD_KEY1,		MOVE_FORWARD_KEY2,		MOVE_FORWARD_KEY3); }
float cmd_move_backward()				{ return cmd(MOVE_BACKWARD_KEY1,	MOVE_BACKWARD_KEY2); }
float cmd_move_left()					{ return cmd(MOVE_LEFT_KEY1,		MOVE_LEFT_KEY2); }
float cmd_move_right()					{ return cmd(MOVE_RIGHT_KEY1,		MOVE_RIGHT_KEY2); }
float cmd_move_up()						{ return cmd(MOVE_UP_KEY1,			MOVE_UP_KEY2); }
float cmd_move_down()					{ return cmd(MOVE_DOWN_KEY1,		MOVE_DOWN_KEY2); }
float cmd_run()							{ return cmd(RUN_KEY1,				RUN_KEY2); }
float cmd_look_left()					{ return cmd(LOOK_LEFT_KEY1,		LOOK_LEFT_KEY2); }
float cmd_look_right()					{ return cmd(LOOK_RIGHT_KEY1,		LOOK_RIGHT_KEY2); }
float cmd_look_up()						{ return cmd(LOOK_UP_KEY1,			LOOK_UP_KEY2); }
float cmd_look_down()					{ return cmd(LOOK_DOWN_KEY1,		LOOK_DOWN_KEY2); }
float cmd_center_view()					{ return cmd(CENTER_VIEW_KEY1,		CENTER_VIEW_KEY2); }
float cmd_strafe()						{ return cmd(STRAFE_KEY1,			STRAFE_KEY2); }
float cmd_respawn()						{ return cmd_press(RESPAWN_KEY1,	RESPAWN_KEY2); }
float cmd_attack()						{ return cmd(ATTACK_KEY1,			ATTACK_KEY2); }
float cmd_menu()						{ return cmd_press(MENU_KEY1,		MENU_KEY2); }

float is_input_enabled()				{ return step(INPUT_ACTIVE_TIME, g_time); }

////////////////////////////////////////////////////////////////

#define SETTINGS_CHANNEL iChannel1

vec4 load(vec2 address)
{
    return load(address, SETTINGS_CHANNEL);
}

////////////////////////////////////////////////////////////////
//
// World data
//
// Generated from a trimmed/tweaked version of
// the original map by John Romero
// https://rome.ro/news/2016/2/14/quake-map-sources-released
//
// Split between Buffer A and B to even out compilation time
////////////////////////////////////////////////////////////////

const float H0=0.707107,H1=0.992278,H2=0.124035,H3=0.83205,H4=0.5547,H5=0.948683,H6=0.316228,H7=0.894427,
H8=0.447214,H9=0.863779,H10=0.503871,H11=0.913812,H12=0.406138,H13=0.970143,H14=0.242536;

#define V(x,y,z,w) vec4(x,y,z,w),
#define D(w) V( 1,0,0,float(w)*16.+-1040.)
#define G(w) V(-1,0,0,float(w)*16.+48.)
#define E(w) V(0, 1,0,float(w)*16.+-1424.)
#define H(w) V(0,-1,0,float(w)*16.+176.)
#define F(w) V(0,0, 1,float(w)*16.+-336.)
#define I(w) V(0,0,-1,float(w)*16.+-192.)
#define X(v0,v1) D(v0)G(v1)
#define Y(v0,v1) E(v0)H(v1)
#define Z(v0,v1) F(v0)I(v1)

WRAP(Planes,planes,vec4,NUM_MAP_NONAXIAL_PLANES+1)(X(6.5,53.5)Y(55,21)V(.6,0,-.8,-574.4)V(-.6,0,.8,561.6)X(1.5,58.5)Y(55,21)V(.6
,0,.8,-590.4)V(-.6,0,-.8,577.6)Z(20,10)V(H0,H0,0,-1052.17)V(H0,-H0,0,-305.47)V(H3,0,H4,-781.018)V(-H3,0,-H4,767.705)Z(20,10)V(H3
,0,-H4,-829.832)V(-H0,H0,0,305.47)V(-H0,-H0,0,1052.17)V(-H3,0,H4,816.519)Z(20,10)V(H0,-H0,0,-305.47)V(-H0,-H0,0,1052.17)V(0,H3,
-H4,-470.386)V(0,-H3,H4,457.073)Z(20,10)V(H0,H0,0,-1052.17)V(-H0,H0,0,305.47)V(0,H3,H4,-421.572)V(0,-H3,-H4,408.259)X(56,4)Y(
57.5,18.5)V(0,.6,-.8,-315.2)V(0,-.6,.8,302.4)X(56,4)Y(52.5,23.5)V(0,.6,.8,-331.2)V(0,-.6,-.8,318.4)X(58.5,1.5)Y(55,21)V(.6,0,-.8
,-75.2)V(-.6,0,.8,62.4)X(53.5,6.5)Y(55,21)V(.6,0,.8,-91.2)V(-.6,0,-.8,78.4)Z(20,10)V(H0,H0,0,-463.862)V(H0,-H0,0,282.843)V(H3,0,
H4,-88.752)V(-H3,0,-H4,75.4392)Z(20,10)V(H0,-H0,0,282.843)V(-H0,-H0,0,463.862)V(0,H3,-H4,-470.386)V(0,-H3,H4,457.073)Z(20,10)V(
H3,0,-H4,-137.566)V(-H0,H0,0,-282.843)V(-H0,-H0,0,463.862)V(-H3,0,H4,124.253)X(4,56)Y(57.5,18.5)V(0,.6,-.8,-315.2)V(0,-.6,.8,
302.4)Z(20,10)V(H0,H0,0,-463.862)V(-H0,H0,0,-282.843)V(0,H3,H4,-421.572)V(0,-H3,-H4,408.259)X(4,56)Y(52.5,23.5)V(0,.6,.8,-331.2)
V(0,-.6,-.8,318.4)Y(59,12)Z(22,10)V(H0,H0,0,-837.214)V(-H0,H0,0,-67.8823)Y(55,12)Z(24,8)V(H0,H0,0,-927.724)V(-H0,H0,0,-158.392)Y
(63,12)Z(21,11)V(H0,H0,0,-791.96)V(-H0,H0,0,-22.6274)Y(57,12)Z(23,9)V(H0,H0,0,-882.469)V(-H0,H0,0,-113.137)X(1,49)Y(63,13)F(2)V(
-H10,0,-H9,667.989)X(49,1)Y(63,13)F(2)V(H10,0,-H9,119.777)X(30,30)Y(65,1)F(2)V(0,H10,-H9,55.2819)X(46,14)Y(65,1)F(2)V(0,H10,-H9,
55.2819)X(14,46)Y(65,1)F(2)V(0,H10,-H9,55.2819)X(14.5,14.5)Y(75.5,1)V(0,H6,H5,-189.737)V(0,H6,-H5,22.7684)X(1,59.5)Z(7.5,8)V(-H6
,H5,0,-78.4245)V(-H6,-H5,0,680.522)Y(75.5,1)Z(7.5,12)V(H5,H6,0,-333.936)V(-H5,H6,0,166.968)X(59.5,1)Z(7.5,8)V(H6,H5,0,-422.48)V(
H6,-H5,0,336.466)Y(75.5,1)Z(7.5,12)V(H5,H6,0,-865.199)V(-H5,H6,0,698.231)D(14)H(14)Z(1,30)V(-H0,H0,0,271.529)G(14)H(14)Z(1,30)V(
H0,H0,0,-497.803)G(1)H(1)Z(5,8)V(H0,H0,0,-316.784)D(1)H(1)Z(5,8)V(-H0,H0,0,452.548)X(7,7)H(1)F(2)V(0,H10,-H9,69.1023)X(49,1)Y(47
,29)F(2)V(H10,0,-H9,119.777)X(59.5,1)Y(49,15)V(H6,0,H5,-149.259)V(H6,0,-H5,63.2456)X(59.5,1)Z(7.5,8)V(H6,H5,0,-665.343)V(H6,-H5,
0,579.329)G(1)Y(41,7)F(2)V(H10,0,-H9,133.598)X(1,49)Y(47,29)F(2)V(-H10,0,-H9,667.989)X(1,59.5)Y(49,15)V(-H6,0,H5,194.796)V(-H6,0
,-H5,407.301)X(1,59.5)Z(7.5,8)V(-H6,H5,0,-321.287)V(-H6,-H5,0,923.385)D(1)Y(41,7)F(2)V(-H10,0,-H9,681.809)Y(33,41)Z(24.5,7.5)V(
H7,H8,0,-1230.73)V(-H7,H8,0,314.838)X(46,15)H(37)Z(25,7)V(H7,H8,0,-658.298)X(42,19)H(37)Z(25,7)V(H8,H7,0,-887.272)H(37)Z(26,1)V(
H0,H0,0,-848.528)V(-H0,H0,0,-294.156)H(37)Z(26,1)V(H0,H0,0,-1063.49)V(-H0,H0,0,-79.196)G(7)H(37)Z(26,1)V(H0,H0,0,-678.823)D(2)H(
37)Z(26,1)V(-H0,H0,0,147.078)X(3,42)Y(37,37)Z(25,7)V(-H8,H7,0,-400.703)X(23,36)Y(29,41)V(0,H14,-H13,-271.64)V(0,-H14,H13,256.118
)X(36,23)Y(29,41)V(0,H14,-H13,-271.64)V(0,-H14,H13,256.118)X(27,27)Y(29,41)V(0,H14,-H13,-271.64)V(0,-H14,H13,256.118)E(21)Z(24,8
)V(H7,-H8,0,-343.46)V(-H4,-H3,0,1402.28)H(45)Z(24.5,7.5)V(.8,.6,0,-1280)V(-H4,H3,0,-257.381)H(45)Z(24.5,7.5)V(H7,H8,0,-1187.8)V(
-H0,H0,0,-45.2549)E(21)Z(24,8)V(H0,-H0,0,135.764)V(-H7,-H8,0,1245.04)H(45)Z(24.5,7.5)V(H4,H3,0,-1207.03)V(-H7,H8,0,314.838)E(21)
Z(24,8)V(H4,-H3,0,434.885)V(-.8,-.6,0,1292.8)Y(17,57)Z(24,8)V(H7,-H8,0,-343.46)V(-H7,-H8,0,1202.11)D(22)E(12)Z(24,1)V(-H0,-H0,0,
1335.02)X(2,2)Y(1,65)Z(23,9)V(-.524097,-.851658,0,1186.56)G(41)E(12)Z(25,1)V(H0,-H0,0,350.725)D(2)E(12)Z(25,1)V(-H0,-H0,0,
1561.29)Y(37,37)Z(5,24)V(.8,0,-.6,-217.6)V(-.8,0,-.6,409.6)X(51,2)Y(25,51)F(2)V(H12,0,-H11,172.203)X(22,31)Y(25,51)F(2)V(-H12,0,
-H11,484.117)Y(8,66)Z(5,24)V(.8,0,-.6,-217.6)V(-.8,0,-.6,409.6)Y(12,41)Z(2,27)V(H12,0,-H11,56.8594)V(-H12,0,-H11,368.774)X(31,11
)Y(25,51)Z(2,26)V(H12,0,-H11,42.2384)V(-H12,0,-H11,354.153)G(3)Y(37,37)F(5)V(.501036,0,-.865426,106.812)G(3)Y(8,66)F(5)V(.501036
,0,-.865426,106.812)X(22,2)E(1)F(2.5)V(0,-.393919,-.919145,782.586)D(22)Y(12,41)F(2)V(-H12,0,-H11,498.738)G(2)Y(12,41)F(2)V(H12,
0,-H11,186.824)Y(37,37)Z(5,24)V(.8,0,-.6,-460.8)V(-.8,0,-.6,652.8)D(2)V(-H2,H1,0,-1002.2)V(-H2,-H1,0,1220.5)V(-H2,0,H1,-128.996)
V(-H2,0,-H1,347.297)G(41)V(H2,H1,0,-992.278)V(H2,-H1,0,785.884)V(H2,0,H1,-254.023)V(H2,0,-H1,47.6293)D(2)V(-H2,H1,0,-811.683)V(
-H2,-H1,0,1029.98)V(-H2,0,H1,-41.6757)V(-H2,0,-H1,259.977)D(2)V(-H2,H1,0,-875.189)V(-H2,-H1,0,1093.49)V(-H2,0,H1,-128.996)V(-H2,
0,-H1,347.297)G(41)V(H2,H1,0,-1151.04)V(H2,-H1,0,944.649)V(H2,0,H1,-341.344)V(H2,0,-H1,134.95)D(3)Y(37,37)F(5)V(-.501036,0,
-.865426,651.939)Y(8,66)Z(5,24)V(.8,0,-.6,-460.8)V(-.8,0,-.6,652.8)G(41)V(H2,H1,0,-1278.05)V(H2,-H1,0,1071.66)V(H2,0,H1,-341.344
)V(H2,0,-H1,134.95)E(1)V(H1,-H2,0,-591.398)V(-H1,-H2,0,916.865)V(0,-H2,H1,-75.4131)V(0,-H2,-H1,400.88)E(1)V(H1,-H2,0,-797.791)V(
-H1,-H2,0,1123.26)V(0,-H2,H1,-75.4131)V(0,-H2,-H1,400.88)E(1)V(H1,-H2,0,-694.594)V(-H1,-H2,0,1020.06)V(0,-H2,H1,-51.5984)V(0,-H2
,-H1,377.066)D(3)Y(8,66)F(5)V(-.501036,0,-.865426,651.939)vec4(0)));

#define L(x,y,z) vec4(x,y,z,300),
#define LR(x,y,z,r) vec4(x,y,z,r),

WRAP(Lights,lights,vec4,NUM_LIGHTS+1)(LR(224,880,248,200)LR(224,1008,248,200)LR(224,1136,248,200)L(88,1024,64)L(362,1034,20)L(
200,712,120)LR(128,624,-32,220)LR(128,528,-48,220)L(126,526,12)LR(128,432,-32,220)LR(224,528,-32,220)L(224,352,120)L(864,352,120
)L(544,312,104)LR(544,496,40,250)LR(544,584,424,500)LR(960,432,-32,220)LR(864,528,-32,220)LR(960,624,-32,220)L(958,526,12)L(394,
762,84)LR(544,864,-8,200)L(698,762,84)LR(960,528,-48,220)LR(408,928,96,120)LR(680,1056,96,120)L(544,1016,72)LR(544,1136,248,200)
LR(544,880,248,200)L(336,1152,-144)L(336,1024,-144)L(336,896,-144)LR(448,1152,-56,120)LR(480,1032,-152,200)LR(488,840,-152,200)
LR(600,840,-152,200)LR(608,1032,-152,200)LR(608,1120,-152,200)LR(544,1192,-152,200)L(728,1080,-144)L(984,1080,-144)L(984,904,-
144)L(728,904,-144)LR(864,888,-32,120)LR(720,992,64,120)LR(864,1112,-24,150)LR(992,928,64,120)LR(992,1056,128,120)L(976,928,312)
L(976,1056,312)LR(976,1184,312,200)L(736,992,312)L(736,1120,312)LR(736,864,312,200)LR(720,1120,128,120)L(912,1360,296)L(808,1360
,296)L(888,712,120)L(864,1336,48)L(544,1336,48)LR(232,1336,48,350)vec4(0)));

// Lightmap layout /////////////////////////////////////////////

#define O2 0,0
#define O4 O2,O2

WRAP(LightmapTiles,LIGHTMAP_TILES,int,NUM_MAP_PLANES)(O2,0x8f4187a,0,1725<<18,0,68020022,32849,16467,85,51243860,0,114779,0,
28927,68013914,53467,O2,119,201,827,51242336,0,68024118,49153,81923,65541,64795,0,114699,0,12351,68020528,51246926,O2,16391,
98313,114699,57403,O2,68010330,113,147,51246920,0,201,0,877,99231,57403,0,57006602,28673,0,50935528,420042758,913857,122891,
118797,0,487963,159755,107069,O2,59542636,474001,42751174,3665,291297534,O4,O2,381,O4,O2,0xd84711e,O2,0,34466650,45217,39113892,
0,55904432,O2,0,99887226,0,0xcf4007a,O2,0,34972748,0,85321998,O2,54855936,51493674,134753,286368892,200817,553,0,190651,186557,
200891,77837,0x70dd504,147585,0x7159d04,O4,54855970,52793124,433,287679594,77825,0x81da4ee,98305,0,0x815b4ee,O4,0,38851790,
0x6510f26,3969,0x774d80a,O4,O4,0,517494784,0,0xe141956,749457,O2,84778338,0,0x70dc704,O2,0x729d8ae,O4,0,0x96d520a,O2,51753790,O2
,0,84474618,0,0xa0d515c,376049,0xa1de6ae,373553,O2,376587,401181,373707,21725,O4,0x72570dc,O4,0,38089418,0,88420998,369,41455390
,8193,O2,504403290,65,186539,O2,0,507024694,353,O2,0,0x955ec0a,O2,0xe1558a4,204801,O2,84515926,O4,O4,O4,O4,O4,0,38589724,3921,0,
88942328,404082688,246305,403757192,321,O4,38589762,978113,88942290,O2,555013120,554505728,159745,84724578,O2,0,0x6510e86,321,
89201366,321,O2,40971,973,3979,973,404059212,450577,403757208,65,O2,437611574,0,437351492,435169,85046040,O2,0,0x64d2686,337,O2,
454400512,778609,453809506,O2,0,338548804,0,336163926,O2,0,0x615ab0e,110849,O2,0,84686178,111211,O4,84522180,0x915b4dc,45057,O4,
540316746,369,537433258,0,0xd09aaaa,0,0xb1592b4,827217,O2,84489060,934497,0xd1590a4,O4,0,0x9157edc,487425,O4,457776138,0xfd001,0
,453830200,O2,408737882,O2,403284032,O2,0,546608128,O4,539530386,1889,0,537433254,O2,0xf155490,594577,0xf11549a,401505,O2,300891
,189,78059,401645,O2,336910684,0,336147546,33,O2,0,320167002,319380610,300833,O4,99366124,20481,0,251749,371263578,952497,O4,
37092458,O2,37277978,0xd39cc86,0,388028716,129,O4,O2,0,34995438,401,277923,O2,0,278219,278109,0,0x909e8e6,437265,0,0x90db2e6,
34449250,O2,382269,0,465963,391915,O4,35519150,265585,O4,265707,0,262671,0x7094806,O2,0x70dd8c2,O2,0,0x909deaa,0,0x90dd6e6,O2,0,
0x7098a06,0,0x70de4f6,O4,0,34656594,622673,O4,536651,0,549087,0x90992c4,O2,0x90dc4e6,O4,O4,O4,O4,O4,O2,0,329275598,44060278,O4,
391174312,O2,0,51242330,68274464,49217,51501628,28673,O2,81995,32845,27515,27581,0x80c3f62,50985632,68286752,16385,68791088,
69242034,0xfdcab,68017474,0,68528968,171873,109,52787528,51753810,217,85051160,86339822,69047626,520411,51500866,68528988,106683
,68791076,3965,68272416,O2,51242324,68015932,49889,85056280,0,217,0,50075,50093,O2,68286232,45505,51497294,233633,51243842,0,
127371,110989,233579,234413,0x70d9d0e,28685,68282656,98305,68530996,0,35519578,34725208,114699,249,69334106,68785496,0x811c4ee,
68012336,197943,68530976,85311758,85564758,0,68284184,0,51247804,68010318,913,52532492,34989178,85058840,106497,85815642,0xfd001
,0,180233,51231586,0,68010288,114881,39375992,0,0x990591e,0,35718476,36043976,41717966,0,0xcd400f4,0,36810926,57345,O2,74277898,
0,34700078,873377,40162374,0,0xbac766c,0,36295880,36459858,O2,0xa353cc8,817,53839534,20481,O2,0x93550ae,225057,950075,282381,O4,
0xd0daaa4,225281,0xa35e86a,30561,O2,237579,974381,435275,435389,O2,0xd0d92ae,810609,O2,59526924,0,3667,60373,0,319914586,O2,
319671904,299185,0xf11728e,O2,0,0xf0dae98,201,319894626,O2,0,319642724,299505,0xf11908e,O2,0,0xf0dae9e,193,O2,68024624,115329,
51493682,O2,51242312,41041,102739,O4,355807850,O4,356059242,O2,0,0xec418f4,0xfc4586c,O2,0x93574ae,45057,53812046,28673,54343370,
O2,0,0xf0d729e,450657,319924314,O2,0,319642748,457,O2,0,523539686,3889,O2,0xa353d30,305,53813582,450113,0,71119656,O2,0xf0dae8c,
127121,0,319914594,O2,319642736,209,O2,0,523801774,801,52793160,54342470,0x63d3c86,237569,51753800,52006746,O2,0,0xa09e6a0,69713
,34726224,O2,0,67724352,304977,34145530,O2,0,0x711b904,192449,O2,0,36873,229323,O4,0x711acfc,O4,192521,O2,37566790,0,88680222,
737,34973526,0,86339876,O2,0x911c6dc,147921,153,O2,0,90123,61453,O4,0x925d8c8,102401,0,51493706,193,34197568,34726216,0,234473,
234411,51246914,233583,0,68747612,348705,51497302,65,0,51755808,17377,34700096,340097,0,34471234,57617,51245384,50883428,0,
51750590,0xfa011,34725216,95,0,35950860,87896842,3889,34995470,175569,O4,0x911a0e6,O2,0,45631724,0xdec3400,945,37278006,O4,
0x8119cfc,O4,0x80dd4f6,0x6295148,993,O2,0x6159d4c,85309198,O2,0x62db4ae,237569,0,53334702,O2,0x62964c8,161,53042504,306177,455,
3689,O2,0x6159d24,85314318,O2,442067978,0,439146564,926545,O2,0x654fafe,369,55904390,0,53235538,794593,0,0x6296518,417,0,
86614216,0,713,619,0,61449,O4,0x99c7ece,O2,0,438897732,155649,O2,0,439197730,439459850,0x62970c8,24577,O2,0x6159d1a,85319438,0,
69819620,69566254,53042484,52793142,0,295,3769,3659,29501,0,69566272,507905,739,86339858,0,508793,508651,52793088,508511,0,
69568248,69819640,53071560,3963,0,0x62988c8,57345,0,86616776,442727,442761,O2,0x6159d38,85316878,0,69819660,69568230,355,511395,
0,52532508,0,0x811d4ee,0x711bafc,O2,395,98313,233481,0,69072110,200337,0x70de304,36865,0,0x629510c,353,0,86619336));

// Collision map ///////////////////////////////////////////////

#undef D
#undef E
#undef F
#undef G
#undef H
#undef I

#define D(w) V( 1,0,0,float(w)*16.+-1040.)
#define G(w) V(-1,0,0,float(w)*16.+48.)
#define E(w) V(0, 1,0,float(w)*16.+-1440.)
#define H(w) V(0,-1,0,float(w)*16.+176.)
#define F(w) V(0,0, 1,float(w)*16.+-320.)
#define I(w) V(0,0,-1,float(w)*16.+-192.)
#define B(x0,y0,z0,x1,y1,z1) D(x0)G(x1)E(y0)H(y1)F(z0)I(z1)

WRAP(CMPlanes,cm_planes,vec4,NUM_MAP_COLLISION_PLANES+1)(B(1,53.5,19,53.5,18.5,8)B(0,2,0,59,0,0)B(59,2,0,0,0,8)B(1,38,24,41,0,0)
B(28,2,13,28,75,10)B(47.5,2,13,8.5,75,10)B(8,2,13,48,75,10)B(20,2,0,39,37,0)B(3,76.5,0,3,0,8)B(0,0,0,0,77,0)B(3,13,31,42,37,0)B(
3,67,20,3,2.5,8)B(39,2,0,20,37,0)B(42,2,23,3,65,8)B(21,62,20,21,15,8)B(21,2,24,0,0,0)B(53.5,53.5,19,1,18.5,8)B(2,2,23,41,61,0)D(
23)G(22)E(14)F(21.5)I(8)V(0,-.242536,.970142,256.118)E(64)H(12)F(20)I(8)V(H0,H0,0,-791.96)V(-H0,H0,0,-22.6274)E(60)H(12)F(21)I(8
)V(H0,H0,0,-837.214)V(-H0,H0,0,-67.8823)E(58)H(12)F(22)I(8)V(H0,H0,0,-882.469)V(-H0,H0,0,-113.137)E(56)H(12)F(23)I(8)V(H0,H0,0,
-927.724)V(-H0,H0,0,-158.392)E(32.5)H(41)F(23.5)I(1)V(.910366,.413803,0,-1218.24)V(-.910366,.413803,0,354.877)E(18)H(55.5)F(23)I
(1)V(.910366,-.413803,0,-397.251)V(-.910366,-.413803,0,1175.86)G(3)H(2.5)F(0)I(12)V(H0,H0,0,-328.098)D(3)H(2.5)F(0)I(12)V(-H0,H0
,0,441.235)D(3)G(2)E(0)H(65)F(22)I(8)V(-.524097,-.851658,0,1186.56)vec4(0)));

#define S(d,b) b,b+d,b+d*2,b+d*3,
#define S4(d,b) S(d,b)S(d,b+d*4)S(d,b+d*8)S(d,b+d*12)

WRAP(CMBrushes,cm_brushes,int,NUM_MAP_COLLISION_BRUSHES+1)(S4(6,0)S(6,96)S(6,120)144,150,155,160,167));

// Map data serialization //////////////////////////////////////

bool is_inside(vec2 fragCoord, vec4 box, out ivec2 offset)
{
    offset = ivec2(floor(fragCoord - box.xy));
    return all(lessThan(uvec2(offset), uvec2(box.zw)));
}

void write_map_data(inout vec4 fragColor, vec2 fragCoord)
{
    if (is_inside(fragCoord, ADDR_LIGHTING) > 0.)
    {
        Lighting lighting;
        if (iFrame == 0)
            clear(lighting);
        else
            from_vec4(lighting, fragColor);

        lighting.progress = clamp(min(float(iFrame)/float(NUM_WAIT_FRAMES), iTime/LOADING_TIME), 0., 1.);
        if (lighting.progress >= 1. && lighting.bake_time <= 0.)
            lighting.bake_time = iTime;
        
        to_vec4(fragColor, lighting);
        return;
    }
    
#if WRITE_MAP_DATA
    if (iFrame > 0)
#endif
        return;
    
    ivec2 offset;

    if (is_inside(fragCoord, ADDR_RANGE_NONAXIAL_PLANES, offset))
    {
        int index = offset.y * int(ADDR_RANGE_NONAXIAL_PLANES.z) + offset.x;
        if (uint(index) < uint(NUM_MAP_NONAXIAL_PLANES + 1))
            fragColor = planes.data[index];
    }
    else if (is_inside(fragCoord, ADDR_RANGE_LIGHTS, offset))
    {
        if (uint(offset.x) < uint(NUM_LIGHTS + 1))
        	fragColor = lights.data[offset.x];
    }
    else if (is_inside(fragCoord, ADDR_RANGE_LMAP_TILES, offset))
    {
        int index = offset.y * int(ADDR_RANGE_LMAP_TILES.z) + offset.x;
        if (uint(index) < uint(NUM_MAP_PLANES))
        {
            int tile = LIGHTMAP_TILES.data[index];
            bool delta_encoded = (tile & 1) != 0;
            if (delta_encoded)
            {
                int offset = (tile >> 1) & 7;
                tile = (tile >> 3) ^ LIGHTMAP_TILES.data[index - offset - 1];
            }
            tile >>= 1;
            
            int x = tile & 255,
                y = (tile >> 8) & 511,
                w = (tile >> 17) & 63,
                h = (tile >> 23) & 63;
            
            fragColor = vec4(x, y, w, h);
        }
    }
    else if (is_inside(fragCoord, ADDR_RANGE_COLLISION_PLANES, offset))
    {
        if (uint(offset.x) < uint(NUM_MAP_COLLISION_PLANES + 1))
        	fragColor = cm_planes.data[offset.x];
    }
}


// Collision detection / response //////////////////////////////

vec4 get_collision_plane(int index)
{
    ivec2 addr = ivec2(ADDR_RANGE_COLLISION_PLANES.xy);
    addr.x += index;
    return texelFetch(SETTINGS_CHANNEL, addr, 0);
}

float get_player_radius(vec3 direction)
{
    const float HORIZONTAL_RADIUS = 16., VERTICAL_RADIUS = 48.;

    direction = abs(direction);
    return direction.z > max(direction.x, direction.y) ? VERTICAL_RADIUS : HORIZONTAL_RADIUS;
}

float get_player_distance(vec3 position, vec4 plane)
{
    return dot(position, plane.xyz) + plane.w - get_player_radius(plane.xyz);
}

bool is_touching_ground(vec3 position, vec4 ground)
{
    return ground.z > 0. && abs(get_player_distance(position, ground)) < 1.;
}

bool is_valid_ground(vec3 position, vec4 ground)
{
    return ground.z > 0. && get_player_distance(position, ground) > -1.;
}

void find_collision(inout vec3 start, inout vec3 delta, out int hit_plane, out float step_height)
{
    const float STEP_SIZE = 18.;

    // We iterate through all the collision brushes, tracking the closest plane the ray hits and the top plane
    // of the colliding brush.
    // If, at the end of the loop, the closest hit plane is vertical and the corresponding top plane
    // is within stepping distance, we move the start position up by the height difference, update the stepping
    // offset for smooth camera interpolation and defer all forward movement to the next step (handle_collision).
    // If we're not stepping up then we move forward as much as possible, discard the remaining forward movement
    // blocked by the colliding plane and pass along what's left (wall sliding) to the next phase.
    
    step_height = 0.;
    hit_plane = -1;
    float travel_dist = 1.;
    int ground_plane = -1;
    float ground_dist = 0.;
    float eps = 1./(length(delta) + 1e-6);
    vec3 dir = normalize(delta);

    int num_brushes = NO_UNROLL(NUM_MAP_COLLISION_BRUSHES);
    for (int i=0; i<num_brushes; ++i)
    {
        int first_plane = cm_brushes.data[i];
        int last_plane = cm_brushes.data[i + 1];
        int plane_enter = -1;
        int brush_ground_plane = -1;
        float brush_ground_dist = 1e+6;
        float t_enter = -1e+6;
        float t_leave = 1e+6;
        for (int j=first_plane; j<last_plane; ++j)
        {
            vec4 plane = get_collision_plane(j);
            float dist = get_player_distance(start, plane);
            
            // Note: top plane detection only takes into account fully horizontal planes.
            // This means that stair stepping won't work with brushes that have an angled top surface, 
            // such as the ramp in the 'Normal' hallway. If you stop on the ramp and let gravity slide
            // you down you'll notice the sliding continues for a bit after the ramp ends - the collision
            // map doesn't fully match the rendered geometry (and now you know why).
            
            if (abs(dir.z) < .7 && plane.z > .99 && brush_ground_dist > dist)
            {
                brush_ground_dist = dist;
                brush_ground_plane = j;
            }
            float align = dot(plane.xyz, delta);
            if (align == 0.)
            {
                if (dist > 0.)
                {
                    t_enter = 2.;
                    break;
                }
                continue;
            }
            align = -1./align;
            dist *= align;
            if (align > 0.)
            {
                if (t_enter < dist)
                {
                    plane_enter = j;
                    t_enter = dist;
                }
            }
            else
            {
                t_leave = min(t_leave, dist);
            }

            if (t_leave <= t_enter)
                break;
        }

        if (t_leave > max(t_enter, 0.) && t_enter > -eps)
        {
            if (t_enter <= travel_dist)
            {
                if (brush_ground_plane != -1 && -brush_ground_dist > ground_dist)
                {
                    ground_plane = brush_ground_plane;
                    ground_dist = -brush_ground_dist;
                }
                hit_plane = plane_enter;
                travel_dist = t_enter;
            }
        }
    }

    vec4 plane;
    bool blocked = hit_plane != -1;
    if (blocked)
    {
        plane = get_collision_plane(hit_plane);
        if (abs(plane.z) < .7 && ground_plane != -1 && ground_dist > 0. && ground_dist <= STEP_SIZE)
        {
            ground_dist += .05;	// fixes occasional stair stepping stutter at low FPS
            step_height = ground_dist;
            start.z += ground_dist;
            return; // defer forward movement to next step
        }
    }

    start += delta * clamp(travel_dist, 0., 1.);
    delta *= 1. - clamp(travel_dist, 0., 1.);

    if (blocked)
    {
        start += 1e-2 * plane.xyz;
        delta -= dot(plane.xyz, delta) * plane.xyz;
    }
}


void handle_collision(inout vec3 start, vec3 delta, int slide_plane, out int hit_plane, out int ground_plane)
{
    // We iterate again through all the collision brushes, this time performing two ray intersections:
    // one determines how far we can actually move, while the other does a ground check from the starting
    // point, giving us an approximate ground plane.
    // Note that the ground plane isn't computed from the final position - that would require another pass
    // through all the brushes!
    
    const float LARGE_NUMBER = 1e+6;

    hit_plane = -1;
    ground_plane = -1;
    float travel_dist = 1.;
    float ground_dist = LARGE_NUMBER;
    float eps = 1./(length(delta) + 1e-6);

    int num_brushes = NO_UNROLL(NUM_MAP_COLLISION_BRUSHES);
    for (int i=0; i<num_brushes; ++i)
    {
        int first_plane = cm_brushes.data[i];
        int last_plane = cm_brushes.data[i + 1];
        int plane_enter = -1;
        int plane_enter_ground = -1;
        float t_enter = -LARGE_NUMBER;
        float t_leave = LARGE_NUMBER;
        float t_enter_ground = t_enter;
        float t_leave_ground = t_leave;
        for (int j=first_plane; j<last_plane; ++j)
        {
            vec4 plane = get_collision_plane(j);
            float dist = get_player_distance(start, plane);

            // handle ground ray
            if (plane.z == 0.)
            {
                if (dist > 0.)
                    t_enter_ground = LARGE_NUMBER;
            }
            else
            {
                float height = dist / plane.z;
                if (plane.z > 0.)
                {
                    if (t_enter_ground < height)
                    {
                        plane_enter_ground = j;
                        t_enter_ground = height;
                    }
                }
                else
                {
                    t_leave_ground = min(t_leave_ground, height);
                }
            }

            // handle movement ray
            float align = dot(plane.xyz, delta);
            if (align == 0.)
            {
                if (dist > 0.)
                    t_enter = LARGE_NUMBER;
                continue;
            }
            align = -1./align;
            dist *= align;
            if (align > 0.)
            {
                if (t_enter < dist)
                {
                    plane_enter = j;
                    t_enter = dist;
                }
            }
            else
            {
                t_leave = min(t_leave, dist);
            }
        }

        if (t_leave_ground > t_enter_ground && t_enter_ground > -8.)
        {
            if (t_enter_ground < ground_dist)
            {
                ground_plane = plane_enter_ground;
                ground_dist = t_enter_ground;
            }
        }

        if (t_leave > max(t_enter, 0.) && t_enter > -eps)
        {
            if (t_enter < travel_dist)
            {
                hit_plane = plane_enter;
                travel_dist = t_enter;
            }
        }
    }

    start += delta * clamp(travel_dist, 0., 1.);
    delta *= 1. - clamp(travel_dist, 0., 1.);

    if (hit_plane != -1)
    {
        vec4 plane = get_collision_plane(hit_plane);
        start += 1e-2 * plane.xyz;
        delta -= dot(plane.xyz, delta) * plane.xyz;
    }
}

void clip_velocity(inout vec3 velocity, int first_hit_plane, int second_hit_plane, float step_size)
{
    if (step_size > 0.)
    {
        first_hit_plane = second_hit_plane;
    	second_hit_plane = -1;
    }

    if (first_hit_plane != -1)
    {
        vec4 first = get_collision_plane(first_hit_plane);
        if (second_hit_plane != -1)
        {
            vec4 second = get_collision_plane(second_hit_plane);
            vec3 crease = normalize(cross(first.xyz, second.xyz));
            velocity = dot(velocity, crease) * crease;
        }
        else
        {
            float align = dot(first.xyz, normalize(velocity));
            velocity -= 1.001 * dot(velocity, first.xyz) * first.xyz;
            velocity *= mix(1., .5, abs(align)); // extra friction
        }
    }
}

void slide_move(inout vec3 position, inout vec3 velocity, inout vec4 ground, inout float step_transition)
{
    vec3 dir = velocity * iTimeDelta;

    int first_hit_plane = -1,
    	second_hit_plane = -1,
    	ground_plane = -1;
    float step_size = 0.;

    find_collision(position, dir, first_hit_plane, step_size);
    handle_collision(position, dir, first_hit_plane, second_hit_plane, ground_plane);
    clip_velocity(velocity, first_hit_plane, second_hit_plane, step_size);
    
    ground = vec4(0);
    if (ground_plane != -1)
    {
        vec4 plane = get_collision_plane(ground_plane);
        if (is_valid_ground(position, plane))
            ground = plane;
    }

    step_transition += step_size;
}

// UV distortions //////////////////////////////////////////////

vec2 running_bond(vec2 uv, float rows)
{
    uv.x += floor(uv.y * rows) * .5;
    return uv;
}

vec2 running_bond(vec2 uv, float cols, float rows)
{
    uv.x += floor(uv.y * rows) * (.5 / cols);
    return uv;
}

vec3 herringbone(vec2 uv)
{
    uv *= 4.;
    float horizontal = step(1., mod(uv.x + floor(uv.y) + 3., 4.) - 1.);
    uv = mix(-uv.yx + vec2(3. - floor(uv.x), 0.), uv.xy + vec2(3. - floor(uv.y), 0.), horizontal);
    return vec3(uv * .25, horizontal);
}

// 3D effects //////////////////////////////////////////////////

// centered on 0; >0 for lightness, <0 for darkness
float add_bevel(vec2 uv, float cols, float rows, float thickness, float light, float dark)
{
    uv = fract(uv * vec2(cols, rows));
    vec4 d = clamp(vec4(uv.xy, 1.-uv.xy)/vec2(thickness*cols, thickness*rows).xyxy, 0., 1.);
    return light*(2. - d.x - d.w) - dark*(2. - d.y - d.z);
}

// QUAKE text //////////////////////////////////////////////////

float sdf_QUAKE(vec2 uv)
{
    uv.x *= .9375;
    float sdf						   = sdf_Q_top(uv);
    uv.x -= .875;	sdf = sdf_union(sdf, sdf_U(uv));
    uv.x -= .8125;	sdf = sdf_union(sdf, sdf_A(uv));
    uv.x -= 1.0625;	sdf = sdf_union(sdf, sdf_K(uv));
    uv.x -= .625;	sdf = sdf_union(sdf, sdf_E(uv));
    return sdf;
}

vec2 engraved_QUAKE(vec2 uv, float size, vec2 light_dir)
{
    const float EPS = .1/64.;
    vec3 sdf;
    for (int i=NO_UNROLL(0); i<3; ++i)
    {
        vec2 uv2 = uv;
        if (i != 2)
            uv2[i] += EPS;
        sdf[i] = sdf_QUAKE(uv2);
    }
    vec2 gradient = safe_normalize(sdf.xy - sdf.z);
    float mask = sdf_mask(sdf.z, 1./64.);
    float bevel = clamp(1. + sdf.z/size, 0., 1.);
    float intensity = .5 + sqr(bevel) * dot(gradient, light_dir);
    intensity = mix(1.125, intensity, mask);
    mask = sdf_mask(sdf.z - 1./64., 1./64.);
    return vec2(intensity, mask);
}

////////////////////////////////////////////////////////////////

// waves.x = amplitude; .y = frequency; .z = phase offset
float sdf_flame_segment(vec2 uv, vec2 size, vec3 waves)
{
    float h = linear_step(0., size.y, uv.y);
    float width = mix(.5, .005, sqr(h)) * size.x;
    return sdf_centered_box(uv, vec2(.5 + sin((h+waves.z)*TAU*waves.y)*waves.x, size.y*.5), vec2(width, size.y*.5));
}

float sdf_flame_segment2(vec2 uv, vec2 size, vec3 waves)
{
    float width = mix(size.x*.005, size.x*.5, smoothen(around(size.y*.5, size.y*.5, uv.y)));
    float h = linear_step(0., size.y, uv.y);
    return sdf_centered_box(uv, vec2(.5 + sin((h+waves.z)*TAU*waves.y)*waves.x, size.y*.5), vec2(width, size.y*.5));
}

float sdf_window_flame(vec2 uv)
{
    bool left = uv.x < .5;
    float sdf = uv.y - 1.;
    uv.y -= .95;
    sdf = sdf_union(sdf, sdf_flame_segment(skew(uv, -.02), vec2(.4, 1.9), vec3(.11, 1., .0)));
    sdf = sdf_union(sdf, sdf_flame_segment(skew(uv, .21)-vec2(-.13, 0.), vec2(.3, 1.2), vec3(.08, 1.2, .95)));
	sdf = sdf_union(sdf, sdf_flame_segment(skew(uv, .0)-vec2(.31, 0.), vec2(.3, 1.4), vec3(.1, 1.2, .55)));
    
    sdf = sdf_union(sdf, sdf_flame_segment(skew(uv, left ? .3 : -.3) - (left ? vec2(-.28, 0.) : vec2(.37, -.1)),
                                           vec2(.2, left ? .31 : .35), vec3(left ? -.03 : .03, 1., .5)));
    
    sdf = sdf_union(sdf, sdf_flame_segment2(uv - (left ? vec2(-.35, 1.25) : vec2(.17, 1.5)), vec2(.11, left ? .4 : .35),
                                            vec3(-.02, 1., .5)));
    sdf = sdf_union(sdf, sdf_flame_segment2(skew(uv-vec2(.35, 1.35), -.0), vec2(.11, .24), vec3(.02, 1., .5)));
    return sdf;
}

float sdf_window_emblem(vec2 uv)
{
    vec2 uv2 = vec2(min(uv.x, 1.-uv.x), uv.y);
	
    float sdf = sdf_centered_box(uv, vec2(.5, .25), vec2(.375, .1));
    sdf = sdf_exclude(sdf, sdf_disk(uv2, vec2(.36, .1), .15));
    
    float h = linear_step(.35, .8, uv.y);
    float w = mix(.27, .35, sqr(triangle_wave(.5, h))) + sqrt(h) * .15;
    sdf = sdf_union(sdf, sdf_centered_box(uv, vec2(.5, .6), vec2(w, .26)));
    
    h = linear_step(.95, .6, uv.y);
    w = .6 - around(.9, .8, h) * .5;
    sdf = sdf_exclude(sdf, .75*sdf_centered_box(uv, vec2(.5, .75), vec2(w, .21)));
    
    // eyes
    sdf = sdf_exclude(sdf, sdf_line(uv2, vec2(.45, .4), vec2(.4, .45), .04));

    sdf = sdf_exclude(sdf, sdf_disk(uv2, vec2(.15, .2), .15));
	sdf = sdf_union(sdf, sdf_line(uv, vec2(.5, .125), vec2(.5, .875), .0625));
    return sdf;
}

////////////////////////////////////////////////////////////////

float line_sqdist(vec2 uv, vec2 a, vec2 b)
{
    vec2 ab = b-a, ap = uv-a;
    float t = clamp(dot(ap, ab)/dot(ab, ab), 0., 1.);
    return length_squared(uv - (ab*t + a));
}

float sdf_chickenscratch(vec2 uv, vec2 mins, vec2 maxs, float thickness)
{
    uv -= mins;
    maxs -= mins;
    
    vec2 p0, p1, p2, p3;
    if (uv.x < maxs.x*.375)
    {
        p0 = vec2(0.);
        p1 = vec2(.3, 1.);
        p2 = vec2(.3, 0.);
        p3 = vec2(.09, .28);
    }
    else
    {
        p0 = vec2(.45, 0.);
        p1 = vec2(.45, 1.);
        p2 = vec2(.75, 0.);
        p3 = p0;
    }
    p0 *= maxs;
    p1 *= maxs;
    p2 *= maxs;
    p3 *= maxs;

    float dist = line_sqdist(uv, p0, p1);
    dist = min(dist, line_sqdist(uv, p1, p2));
    dist = min(dist, line_sqdist(uv, p2, p3));

    #define LINE(a, b) line_sqdist(uv, maxs*a, maxs*b)
    
    dist = min(dist, LINE(vec2(.65, 1.), vec2(.95, 0.)));
    dist = min(dist, LINE(vec2(.85, 1.), vec2(.65, .65)));

	#undef LINE
    
    return sqrt(dist) + thickness * -.5;
}

////////////////////////////////////////////////////////////////
//  Cellular noise code by Brian Sharpe
//  https://briansharpe.wordpress.com/
//  https://github.com/BrianSharpe/GPU-Noise-Lib
//
//  Modified to add tiling
////////////////////////////////////////////////////////////////

//
//	FAST32_hash
//	A very fast hashing function.  Requires 32bit support.
//	http://briansharpe.wordpress.com/2011/11/15/a-fast-and-simple-32bit-floating-point-hash-function/
//
//	The 2D hash formula takes the form....
//	hash = mod( coord.x * coord.x * coord.y * coord.y, SOMELARGEFLOAT ) / SOMELARGEFLOAT
//	We truncate and offset the domain to the most interesting part of the noise.
//	SOMELARGEFLOAT should be in the range of 400.0->1000.0 and needs to be hand picked.  Only some give good results.
//	A 3D hash is achieved by offsetting the SOMELARGEFLOAT value by the Z coordinate
//

const vec2 OFFSET = vec2( 26.0, 161.0 );
const vec2 SOMELARGEFLOATS = vec2( 951.135664, 642.949883 );

void FAST32_hash_2D_tile( vec2 gridcell, vec2 gridsize, out vec4 hash_0, out vec4 hash_1 )
{
    //    gridcell is assumed to be an integer coordinate
    vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0 );
    P = P - floor(P * ( 1.0 / gridsize.xyxy )) * gridsize.xyxy;
    P += OFFSET.xyxy;
    P *= P;
    P = P.xzxz * P.yyww;
    hash_0 = fract( P * ( 1.0 / SOMELARGEFLOATS.x ) );
    hash_1 = fract( P * ( 1.0 / SOMELARGEFLOATS.y ) );
}

vec4 FAST32_hash_2D_tile( vec2 gridcell, vec2 gridsize )
{
    //    gridcell is assumed to be an integer coordinate
    vec4 P = vec4( gridcell.xy, gridcell.xy + 1.0 );
    P = P - floor(P * ( 1.0 / gridsize.xyxy )) * gridsize.xyxy;
    P += OFFSET.xyxy;
    P *= P;
    P = P.xzxz * P.yyww;
    return fract( P * ( 1.0 / SOMELARGEFLOATS.x ) );
}

float FAST32_smooth_noise(vec2 P, vec2 gridsize)
{
    P *= gridsize;
    vec2 Pi = floor(P), Pf = smoothen(P - Pi);
    vec4 hash = FAST32_hash_2D_tile(Pi, gridsize);
    return mix(mix(hash.x, hash.y, Pf.x), mix(hash.z, hash.w, Pf.x), Pf.y);
}

//	convert a 0.0->1.0 sample to a -1.0->1.0 sample weighted towards the extremes
vec4 Cellular_weight_samples( vec4 samples )
{
    samples = samples * 2.0 - 1.0;
    //return (1.0 - samples * samples) * sign(samples);	// square
    return (samples * samples * samples) - sign(samples);	// cubic (even more variance)
}

//
//	Cellular Noise 2D
//	Based off Stefan Gustavson's work at http://www.itn.liu.se/~stegu/GLSL-cellular
//	http://briansharpe.files.wordpress.com/2011/12/cellularsample.jpg
//
//	Speed up by using 2x2 search window instead of 3x3
//	produces a range of 0.0->1.0
//
float Cellular2D(vec2 P, vec2 gridsize)
{
    P *= gridsize;	// adx: multiply here instead of requiring callers to do it
    //	establish our grid cell and unit position
    vec2 Pi = floor(P);
    vec2 Pf = P - Pi;

    //	calculate the hash.
    vec4 hash_x, hash_y;
    FAST32_hash_2D_tile( Pi, gridsize, hash_x, hash_y );

    //	generate the 4 random points
#if 0
    //	restrict the random point offset to eliminate artifacts
    //	we'll improve the variance of the noise by pushing the points to the extremes of the jitter window
    const float JITTER_WINDOW = 0.25;	// 0.25 will guarentee no artifacts.  0.25 is the intersection on x of graphs f(x)=( (0.5+(0.5-x))^2 + (0.5-x)^2 ) and f(x)=( (0.5+x)^2 + x^2 )
    hash_x = Cellular_weight_samples( hash_x ) * JITTER_WINDOW + vec4(0.0, 1.0, 0.0, 1.0);
    hash_y = Cellular_weight_samples( hash_y ) * JITTER_WINDOW + vec4(0.0, 0.0, 1.0, 1.0);
#else
    //	non-weighted jitter window.  jitter window of 0.4 will give results similar to Stefans original implementation
    //	nicer looking, faster, but has minor artifacts.  ( discontinuities in signal )
    const float JITTER_WINDOW = 0.4;
    hash_x = hash_x * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, 1.0-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW);
    hash_y = hash_y * JITTER_WINDOW * 2.0 + vec4(-JITTER_WINDOW, -JITTER_WINDOW, 1.0-JITTER_WINDOW, 1.0-JITTER_WINDOW);
#endif

    //	return the closest squared distance
    vec4 dx = Pf.xxxx - hash_x;
    vec4 dy = Pf.yyyy - hash_y;
    vec4 d = dx * dx + dy * dy;
    d.xy = min(d.xy, d.zw);
    return min(d.x, d.y) * ( 1.0 / 1.125 );	//	scale return value from 0.0->1.125 to 0.0->1.0  ( 0.75^2 * 2.0  == 1.125 )
}


////////////////////////////////////////////////////////////////
// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////

// XY=offset, Z=dist
vec3 voronoi(vec2 x, vec2 grid)
{
    x *= grid; // adx: multiply here instead of requiring callers to do it
    vec2 n = floor(x);
    vec2 f = x - n;

    //----------------------------------
    // first pass: regular voronoi
    //----------------------------------
	vec2 mg, mr;

    float md = 8.0;
    for (int j=-1; j<=1; j++)
    for (int i=-1; i<=1; i++)
    {
        vec2 g = vec2(i, j);
		vec2 o = hash2(mod(n + g, grid));	// adx: added domain wrapping
        vec2 r = g + o - f;
        float d = dot(r,r);

        if (d < md)
        {
            md = d;
            mr = r;
            mg = g;
        }
    }

    //----------------------------------
    // second pass: distance to borders
    //----------------------------------
    md = 8.0;
    for (int j=-2; j<=2; j++)
    for (int i=-2; i<=2; i++)
    {
        vec2 g = mg + vec2(i, j);
		vec2 o = hash2(mod(n + g, grid));	// adx: added domain wrapping
        vec2 r = g + o - f;
        float d = length_squared(mr - r);

        if (d > 0.00001)
        	md = min(md, -inversesqrt(d)*dot(mr+r, mr-r));
    }

    return vec3(mr, 0.5*md); // adx: changed order
}

////////////////////////////////////////////////////////////////

float tileable_smooth_noise(vec2 p, vec2 scale)
{
#if 0
    p *= scale;
    vec2 pi = floor(p);
    p = smoothen(p - pi);
    vec4 seed = fract(vec4(pi, pi + 1.) * (1./scale).xyxy);
    float s00 = random(seed.xy);
    float s01 = random(seed.zy);
    float s10 = random(seed.xw);
    float s11 = random(seed.zw);
    return mix(mix(s00, s01, p.x), mix(s10, s11, p.x), p.y);
#else
    return FAST32_smooth_noise(p, scale);
#endif
}

float tileable_turb(vec2 uv, vec2 scale, float gain, float lacunarity)
{
	float accum = tileable_smooth_noise(uv, scale);
    float octave_weight = gain;
    float total_weight = 1.;

    scale *= lacunarity;
    accum += tileable_smooth_noise(uv, scale) * octave_weight;
    total_weight += octave_weight;

    scale *= lacunarity; octave_weight *= gain;
    accum += tileable_smooth_noise(uv, scale) * octave_weight;
    total_weight += octave_weight;

    scale *= lacunarity; octave_weight *= gain;
    accum += tileable_smooth_noise(uv, scale) * octave_weight;
    total_weight += octave_weight;

    return accum / total_weight;
}

////////////////////////////////////////////////////////////////

vec4 generate_texture(const int material, vec2 uv)
{
    vec2 tile_size = get_tile(material).zw;

	vec3 clr;
    float shaded = 1.;	// 0 = fullbright; 0.5 = lit; 1.0 = lit+AO
    
    float grain = random(uv*128.);
    
    // gathering FBM parameters first and calling the function once
    // instead of per material reduces the compilation time for this buffer
    // by about 4 seconds (~9.4 seconds vs ~13.4) on my machine...
    
    // array-based version compiles about 0.7 seconds faster
    // than the equivalent switch (~14.1 seconds vs ~14.8)...

    const vec4 MATERIAL_SETTINGS[]=vec4[7](vec4(3,5,1,3),vec4(3,5,1,4),vec4(6,6,.5,3),vec4(10,10,.5,2),vec4(3,5,1,2),vec4(7,3,.5
    ,2),vec4(7,5,.5,2));
    const int MATERIAL_INDICES[]=int[NUM_MATERIALS+1](1,1,1,0,1,0,1,0,0,0,1,6,6,6,1,1,2,3,4,5,0);

    vec4 settings = MATERIAL_SETTINGS[MATERIAL_INDICES[min(uint(material), uint(NUM_MATERIALS))]];
    vec2 base_grid = settings.xy;
    float base_gain = settings.z;
    float base_lacunarity = settings.w;

    if (is_material_sky(material))
        uv += sin(uv.yx * (3.*PI)) * (4./128.);

    vec2 aspect = tile_size / min(tile_size.x, tile_size.y);
    float base = tileable_turb(uv * aspect, base_grid, base_gain, base_lacunarity);
    
    // this switch compiles ~2.2 seconds faster on my machine
    // than an equivalent if/else if chain (~11.5s vs ~13.7s)
    
	#define GENERATE(mat) ((GENERATE_TEXTURES) & (1<<(mat)))

    switch (material)
    {
#if GENERATE(MATERIAL_WIZMET1_2) || GENERATE(MATERIAL_QUAKE)
        case MATERIAL_WIZMET1_2:
        case MATERIAL_QUAKE:
        {
            uv.x *= tile_size.x/tile_size.y;
            uv += vec2(.125, .0625);
            base = mix(base, grain, .2);
            clr = mix(vec3(.16, .13, .06), vec3(.30, .23, .12), sqr(base));
            clr = mix(clr, vec3(.30, .23, .13), sqr(linear_step(.5, .9, base)));
            clr = mix(clr, vec3(.10, .10, .15), smoothen(linear_step(.7, .1, base)));
            if (material == MATERIAL_WIZMET1_2 || (material == MATERIAL_QUAKE && uv.y < .375))
            {
                vec2 knob_pos = floor(uv*4.+.5)*.25;
                vec2 knob = add_knob(uv, 1./64., knob_pos, 3./64., vec2(-.4, .4));
                clr = mix(clr, vec3(.22, .22, .28)*mix(1., knob.x, .8), knob.y);
                knob = add_knob(uv, 1./64., knob_pos, 1.5/64., vec2(.4, -.4));
                clr = mix(clr, .7*vec3(.22, .22, .28)*mix(1., knob.x, .7), knob.y);
            }
            if (material == MATERIAL_QUAKE)
            {
                uv -= vec2(1.375, .15625);
                uv.x = mod(uv.x, 5.);
                uv.y = fract(uv.y);
                vec2 engraved = engraved_QUAKE(uv, 5./64., vec2(0, -1));
                clr *= mix(1., mix(1., engraved.x*1.25, .875), engraved.y);
            }
        }
        break;
#endif

#if GENERATE(MATERIAL_WIZMET1_1)
        case MATERIAL_WIZMET1_1:
        {
            base = mix(base, grain, .4);
            float scratches = linear_step(.15, .9, smooth_noise(vec2(32,8)*rotate(uv, 22.5).x) * base);
            clr = vec3(.17, .17, .16) * mix(.5, 1.5, base);
            clr = mix(clr, vec3(.23, .19, .15), scratches);
            scratches *= linear_step(.6, .25, smooth_noise(vec2(16,4)*rotate(uv, -45.).x) * base);
            clr = mix(clr, vec3(.21, .21, .28) * 1.5, scratches);
            float bevel = .6 *mix(3.5/64., 11./64., base);
            float d = min(1., min(uv.x, 1.-uv.y) / bevel);
            float d2 = min(d, 3. * min(uv.y, 1.-uv.x) / bevel);
            clr *= 1. - (1. - d2) * mix(.3, .8, base);
            clr = mix(clr, vec3(.39, .39, .57) * base, around(.6, .4, d));
        }
        break;
#endif

#if GENERATE(MATERIAL_WIZ1_4)
        case MATERIAL_WIZ1_4:
        {
            base = mix(smoothen(base), grain, .3);
            clr = mix(vec3(.37, .28, .21), vec3(.52, .41, .33), smoothen(base));
            clr = mix(clr, vec3(.46, .33, .15), around(.45, .05, base));
            clr = mix(clr, vec3(.59, .48, .39), around(.75, .09, base)*.75);
            float bevel = mix(4./64., 12./64., FAST32_smooth_noise(uv, vec2(21)));
            vec2 mins = vec2(bevel, bevel * 2.);
            vec2 maxs = 1. - vec2(bevel, bevel * 2.);
            uv = running_bond(uv, 1., 2.) * vec2(1, 2);
            vec2 duv = (fract(uv) - clamp(fract(uv), mins, maxs)) * (1./bevel) * vec2(2, 1);
            float d = mix(length(duv), max_component(abs(duv)), .75);
            clr *= clamp(2.1 - d*mix(.75, 1., sqr(base)), 0., 1.);
            clr *= 1. + mix(.25, .5, base) * max(0., dot(duv, INV_SQRT2*vec2(-1,1)) * step(d, 1.2));
        }
		break;
#endif

#if GENERATE(MATERIAL_WBRICK1_5)
        case MATERIAL_WBRICK1_5:
        {
            vec2 uv2 = uv + sin(uv.yx * (3.*PI)) * (4./64.);
            uv = running_bond(uv + vec2(.5, 0), 1., 2.) * vec2(1, 2);
            base = mix(smoothen(base), grain, .3);
            float detail = tileable_smooth_noise(uv2, vec2(11));
            detail = sqr(around(.625, .25, detail)) * linear_step(.5, .17, base);
            clr = mix(vec3(.21, .17, .06)*.75, vec3(.30, .26, .15), base);
            clr *= mix(.95, 2., sqr(sqr(base)));
            clr = mix(clr, vec3(.41, .32, .14), detail);
            float bevel = mix(4./64., 8./64., base);
            vec2 mins = vec2(bevel, bevel * 1.75);
            vec2 maxs = 1. - vec2(bevel, bevel * 2.);
            vec2 duv = (fract(uv) - clamp(fract(uv), mins, maxs)) * (1./bevel) * vec2(2, 1);
            float d = length(duv);
            if (uv.y > 1. || uv.y < .5)
                d = mix(d, max_component(abs(duv)), .5);
            //clr *= mix(1., mix(.25, .625, base), linear_step(1., 2., d)*step(1.5, d));
            clr *= clamp(2.1 - d*mix(.75, 1., sqr(base)), 0., 1.);
            clr *= 1. + mix(.25, .5, base) * max(0., dot(duv, INV_SQRT2*vec2(-1,1)) * step(d, 1.2));
        }
        break;
#endif

#if GENERATE(MATERIAL_CITY4_7)
        case MATERIAL_CITY4_7:
        {
            base = mix(base, grain, .4);
            vec3 brick = herringbone(uv);
            uv = brick.xy;
            clr = mix(vec3(.23, .14, .07), vec3(.29, .16, .08), brick.z) * mix(.3, 1.7, base);
            clr = mix(clr, vec3(.24, .18, .10), linear_step(.6, .9, base));
            clr = mix(clr, vec3(.47, .23, .12), linear_step(.9, 1., sqr(grain))*.6);
            clr *= (1. + add_bevel(uv, 2., 4., mix(1.5/64., 2.5/64., base), -mix(.05, .15, grain), 0.6));
        }
        break;
#endif

#if GENERATE(MATERIAL_CITY4_6)
		case MATERIAL_CITY4_6:
        {
            base = mix(base, grain, .5);
            vec3 brick = herringbone(uv);
            uv = brick.xy;
            clr = mix(vec3(.09, .08, .01)*1.25, 2.*vec3(.21, .15, .08), sqr(base));
            clr *= mix(.85, 1., brick.z);
            clr = mix(clr, mix(.25, 1.5, sqr(base))*vec3(.11, .11, .22), around(.8, mix(.24, .17, brick.z), (grain)));
            clr = mix(clr, mix(.75, 1.5, base)*vec3(.26, .20, .10), .75*sqr(around(.8, .2, (base))));
            clr *= (1. + add_bevel(uv, 2., 4., 2.1/64., .0, .25));
            clr *= (1. + add_bevel(uv, 2., 4., mix(1.5/64., 2.5/64., base), mix(.25, .05, grain), .35));
        }
        break;
#endif

#if GENERATE(MATERIAL_DEM4_1)
        case MATERIAL_DEM4_1:
        {
            base = mix(base, grain, .2);
            clr = mix(vec3(.18, .19, .21), vec3(.19, .15, .06), linear_step(.4, .7, base));
            shaded = .75; // lit, half-strength AO
        }
        break;
#endif

#if GENERATE(MATERIAL_COP3_4)
        case MATERIAL_COP3_4:
        {
            float sdf = sdf_chickenscratch(uv, vec2(.25, .125), vec2(.75, .375), 1.5/64.);
            base = mix(base, grain, .2);
            base *= mix(1., .625, sdf_mask(sdf, 1./64.));
            clr = mix(vec3(.14, .15, .13), vec3(.41, .21, .12), base);
            clr = mix(clr, vec3(.30, .32, .34), linear_step(.6, 1., base));
            float bevel = mix(2./64., 6./64., sqr(FAST32_smooth_noise(uv, vec2(13))));
            clr *= (1. + add_bevel(uv, 1., 1., bevel, .5, .5));
            clr *= 1.5;
        }
        break;
#endif

#if GENERATE(MATERIAL_BRICKA2_2) || GENERATE(MATERIAL_WINDOW02_1)
        case MATERIAL_BRICKA2_2:
        case MATERIAL_WINDOW02_1:
        {
            vec2 grid = (material == MATERIAL_BRICKA2_2) ? vec2(6., 5.) : vec2(8., 24.);
            uv = (material == MATERIAL_WINDOW02_1) ? fract(uv + vec2(.5, .5/3.)) : uv;
            vec3 c = voronoi(uv, grid);
            if (material == MATERIAL_BRICKA2_2)
            {
                float dark_edge = linear_step(.0, mix(.05, .45, base), c.z);
                float lit_edge = linear_step(.35, .25, c.z);
                float lighting = -normalize(c.xy).y * .5;
                clr = vec3(.25, .18, .10) * mix(.8, 1.2, grain);
                clr *= (1. + lit_edge * lighting) * mix(.35, 1., dark_edge);
                uv = fract(running_bond(uv, 1., 2.) * vec2(1, 2));
                clr *=
                    mix(1., min(1., 4.*min(uv.y, 1.-uv.y)), .5) *
                	mix(1., min(1., 8.*min(uv.x, 1.-uv.x)), .3125);
                clr *= 1.25;
            }
            else
            {
                // Note: using x*48 instead of x/fwidth(x) reduces compilation time
                // for this buffer by ~23% (~10.3 seconds vs ~13.4) on my system
                float intensity = mix(1.25, .75, hash1(uv*grid + c.xy)) * (1. - .5*length(c.xy));
                uv.y *= 3.;
                float flame = sdf_window_flame(uv) * 48.;
                float emblem = sdf_window_emblem(uv) * 48.;
                float edge = linear_step(.0, .15, c.z);
                clr = mix(vec3(1., .94, .22) * 1.125, vec3(.63, .30, .19), clamp(flame, 0., 1.));
                clr = mix(clr, vec3(.55, .0, .0), clamp(1.-emblem, 0., 1.));
                clr = mix(vec3(dot(clr, vec3(1./3.))), clr, intensity);
                edge *= clamp(abs(flame), 0., 1.) * clamp(abs(emblem), 0., 1.);
                edge *= step(max(abs(uv.x - .5) - .5, abs(uv.y - 1.5) - 1.5), -2./64.);
                clr *= intensity * edge;
                shaded = .75; // lit, half-strength AO
            }
    	}
        break;
#endif

#if GENERATE(MATERIAL_LAVA1) || GENERATE(MATERIAL_WATER2) || GENERATE(MATERIAL_WATER1)
        case MATERIAL_LAVA1:
        case MATERIAL_WATER2:
        case MATERIAL_WATER1:
        {
            vec2 grid = (material == MATERIAL_WATER1) ? vec2(5., 7.) : vec2(5., 5.);
            uv += base * (1./31.) * sin(PI * 7. * uv.yx);
            float cellular = Cellular2D(uv, grid);
            float grain_amount = (material == MATERIAL_LAVA1) ? .125 : .25;
            float high_point = (material == MATERIAL_WATER2) ? .8 : .9;
            base = mix(base, grain, grain_amount);
            cellular = sqrt(cellular) + mix(-.3, .3, base);
            base = linear_step(.1, high_point, cellular);
            if (material == MATERIAL_LAVA1)
            {
                clr = mix(vec3(.24,.0,.0), vec3(1.,.40,.14), base);
                clr = mix(clr, vec3(1.,.55,.23), linear_step(.5, 1., base));
            }
            else if (material == MATERIAL_WATER2)
            {
                clr = mix(vec3(.10,.10,.14)*.8, vec3(.17,.17,.24)*.8, base);
                clr = mix(clr, vec3(.16,.13,.06)*mix(.8, 2.5, sqr(sqr(base))), around(.5, .1, grain));
                clr = mix(clr, vec3(.20,.20,.29)*.8, linear_step(.5, 1., base));
            }
            else // if (material == MATERIAL_WATER1)
            {
                clr = mix(vec3(.08,.06,.04), vec3(.30,.23,.13), base);
                clr = mix(clr, vec3(.36,.28,.21), linear_step(.5, 1., base));
            }
            shaded = 0.;
        }
        break;
#endif

#if GENERATE(MATERIAL_WIZWOOD1_5)
		case MATERIAL_WIZWOOD1_5:
        {
            const vec2 GRID = vec2(1, 4);
            uv = running_bond(fract(uv.yx), GRID.x, GRID.y);
            vec2 waviness = vec2(sin(3. * TAU * uv.y), 0) * .0;
            waviness.x += smooth_noise(uv.y * 16.) * (14./64.);
            base = tileable_turb(uv + waviness, vec2(2, 32), .5, 3.);
            clr = mix(vec3(.19, .10, .04)*1.25, vec3(.64, .26, .17), around(.5, .4, smoothen(base)));
            clr = mix(clr, vec3(.32, .17, .08), around(.7, .3, base)*.7);
            
            float across = fract(uv.y * GRID.y);
            clr *= 1. + .35 * linear_step(1.-4./16., 1.-2./16., across) * step(across, 1.-2./16.);
            across = min(across, 1. - across);
            clr *= mix(1., linear_step(0., 2./16., across), mix(.25, .75, base));
			float along = fract(uv.x * GRID.x);
            clr *= 1. + .25 * linear_step(2./64., 0., along);
            clr *= mix(1., linear_step(1., 1.-2.5/64., along), mix(.5, .75, base));
            
            const vec2 LIGHT_DIR = INV_SQRT2 * vec2(-1, 1);
            uv = fract(uv * GRID);
            vec2 side = sign(.5 - uv); // keep track of side before folding to 'unmirror' light direction
            uv = min(uv, 1. - uv) * (1./GRID);
            vec2 nail = add_knob(uv, 1./64., vec2(4./64.), 1./64., side * LIGHT_DIR);
            clr = mix(clr, vec3(.64, .26, .17) * nail.x, nail.y * .75);

            clr *= .9 + grain*.2;
            clr *= .75;
        }
        break;
#endif

#if GENERATE(MATERIAL_TELEPORT)
        case MATERIAL_TELEPORT:
        {
            uv *= 64./3.;
            vec2 cell = floor(uv);
            vec4 n = hash4(cell);
            uv -= cell;
            float radius = mix(.15, .5, sqr(sqr(n.z)));
            n.xy = mix(vec2(radius), vec2(1.-radius), smoothen(n.xy));
            uv = clamp((n.xy - uv) * (1./radius), -1., 1.);
            clr = (1.-length_squared(uv)) * (1.-sqr(sqr(n.w))) * vec3(.44, .36, .26);
            shaded = 0.;
        }
        break;
#endif

#if GENERATE(MATERIAL_FLAME)
        case MATERIAL_FLAME:
        {
            base = mix(base, grain, .1);
            clr = mix(vec3(.34, .0, .0), vec3(1., 1., .66), smoothen(base));
            clr = clamp(clr * 1.75, 0., 1.);
            shaded = 0.;
        }
        break;
#endif

#if GENERATE(MATERIAL_ZOMBIE)
        case MATERIAL_ZOMBIE:
        {
            base = mix(base, grain, .2);
            clr = vec3(.57, .35, .24) * mix(.6, 1., sqr(base));
            clr = mix(clr, vec3(.17, .08, .04), linear_step(.3, .7, base));
        }
        break;
#endif

#if GENERATE(MATERIAL_SKY1)
        case MATERIAL_SKY1:
        {
            clr = vec3(.18, .10, .12) * 1.5 * smoothen(base);
            shaded = 0.;
        }
        break;
#endif

#if GENERATE(MATERIAL_SKY1B)
        case MATERIAL_SKY1B:
        {
            clr = vec3(.36, .19, .23) * 1.125 * smoothen(base);
            shaded = 0.;
        }
        break;
#endif

        default:
        {
            clr = vec3(base * .75);
        }
        break;
    }
    
	#undef GENERATE
    
    clr = clamp(clr, 0., 1.);

    return vec4(clr, shaded);
}

void generate_tiles(inout vec4 fragColor, vec2 fragCoord, float lod)
{
    float atlas_scale = exp2(-lod);
    if (is_inside(fragCoord, atlas_mip0_bounds(atlas_scale)) < 0.)
        return;
    
    int material = -1;
    vec4 bound;
    
    int num_materials = NO_UNROLL(NUM_MATERIALS);
    for (int i=0; i<num_materials; ++i)
    {
        bound = get_tile(i) * atlas_scale;
        bound.xy += ATLAS_OFFSET;
        if (is_inside(fragCoord, bound) > 0.)
        {
            material = i;
            break;
        }
    }
    
    if (material == -1)
        return;
    
    vec2 local_uv = (fragCoord - bound.xy) / bound.zw;
    fragColor = generate_texture(material, local_uv);
}

void update_mips(inout vec4 fragColor, vec2 fragCoord, float atlas_lod, inout int available_mips)
{
    int mip_start = ALWAYS_REFRESH > 0 ? 1 : available_mips;
    available_mips = min(available_mips + 1, MAX_MIP_LEVEL + 1 - int(atlas_lod));
    
    float atlas_scale = exp2(-atlas_lod);

    if (is_inside(fragCoord, atlas_chain_bounds(atlas_scale)) < 0.)
        return;
    if (is_inside(fragCoord, atlas_mip0_bounds(atlas_scale)) > 0.)
        return;

    int mip_end = available_mips;
    int mip;
    vec2 atlas_size = ATLAS_SIZE * atlas_scale;
    vec2 ofs;
    for (mip=mip_start; mip<mip_end; ++mip)
    {
        float fraction = exp2(-float(mip));
        ofs = mip_offset(mip) * atlas_size + ATLAS_OFFSET;
        vec2 size = atlas_size * fraction;
        if (is_inside(fragCoord, vec4(ofs, size)) > 0.)
            break;
    }
    
    if (mip == mip_end)
        return;
    
    vec2 src_ofs = mip_offset(mip-1) * atlas_size + ATLAS_OFFSET;
    vec2 uv = fragCoord - ofs - .5;

    // A well-placed bilinear sample would be almost equivalent,
    // except the filtering would be done in sRGB space instead
    // of linear space. Of course, the textures could be created
    // in linear space to begin with, since we're rendering to
    // floating-point buffers anyway... but then we'd be a bit too
    // gamma-correct for 1996 :)

    ivec4 iuv = ivec2(uv * 2. + src_ofs).xyxy + ivec2(0, 1).xxyy;
    vec4 t00 = gamma_to_linear(texelFetch(iChannel1, iuv.xy, 0));
    vec4 t01 = gamma_to_linear(texelFetch(iChannel1, iuv.xw, 0));
    vec4 t10 = gamma_to_linear(texelFetch(iChannel1, iuv.zy, 0));
    vec4 t11 = gamma_to_linear(texelFetch(iChannel1, iuv.zw, 0));

    fragColor = linear_to_gamma((t00 + t01 + t10 + t11) * .25);
}

void update_tiles(inout vec4 fragColor, vec2 fragCoord)
{
    const vec4 SENTINEL_COLOR = vec4(1, 0, 1, 0);
    
    vec4 resolution = vec4(iResolution.xy, 0, 0);
    vec4 old_resolution = (iFrame==0) ? vec4(0) : load(ADDR_RESOLUTION);
    int flags = int(old_resolution.z);
    if (iFrame == 0 && iTime >= THUMBNAIL_MIN_TIME)
        flags |= RESOLUTION_FLAG_THUMBNAIL;
    vec4 atlas_info = (iFrame==0) ? vec4(0) : load(ADDR_ATLAS_INFO);
    int available_mips = int(round(atlas_info.x));
   
    vec2 available_space = (resolution.xy - ATLAS_OFFSET) / ATLAS_CHAIN_SIZE;
    float atlas_lod = max(0., -floor(log2(min(available_space.x, available_space.y))));
    if (atlas_lod != atlas_info.y)
        available_mips = 0;
    if (max(abs(resolution.x-old_resolution.x), abs(resolution.y-old_resolution.y)) > .5)
        flags |= RESOLUTION_FLAG_CHANGED;
    
    // Workaround for Shadertoy double-buffering bug on resize
    // (this.mBuffers[i].mLastRenderDone = 0; in effect.js/Effect.prototype.ResizeBuffer)
    vec2 sentinel_address = ATLAS_OFFSET + ATLAS_CHAIN_SIZE * exp2(-atlas_lod) - 1.;
    vec4 sentinel = (iFrame == 0) ? vec4(0) : load(sentinel_address);
    if (any(notEqual(sentinel, SENTINEL_COLOR)))
    {
        available_mips = 0;
        flags |= RESOLUTION_FLAG_CHANGED;
    }
    
    resolution.z = float(flags);

    if (available_mips > 0)
    	update_mips(fragColor, fragCoord, atlas_lod, available_mips);
    
    if (ALWAYS_REFRESH > 0 || available_mips == 0)
    {
        if (available_mips == 0)
        	store(fragColor, fragCoord, ADDR_RANGE_ATLAS_CHAIN, vec4(0.));
        generate_tiles(fragColor, fragCoord, atlas_lod);
        available_mips = max(available_mips, 1);
    }
    atlas_info.x = float(available_mips);
    atlas_info.y = atlas_lod;

    store(fragColor, fragCoord, ADDR_RESOLUTION, resolution);
    store(fragColor, fragCoord, ADDR_ATLAS_INFO, atlas_info);
    store(fragColor, fragCoord, sentinel_address, SENTINEL_COLOR);
}

////////////////////////////////////////////////////////////////

#define T(x0,y0,z0,x1,y1,z1) vec3(x0,y0,z0),vec3(x1,y1,z1)

WRAP(Teleporters,teleporters,vec3,6)(T(208,1368,-0,256,1384,96),T(520,1368,-0,568,1384,96),T(840,1368,-0,888,1384,96)));

bool touch_tele(vec3 pos, float radius)
{
    radius *= radius;
    bool touch = false;
    for (int i=0; i<6; i+=2)
    {
        vec3 mins = teleporters.data[i];
        vec3 maxs = teleporters.data[i+1];
        vec3 delta = clamp(pos, mins, maxs) - pos;
        if (dot(delta, delta) <= radius)
            touch = true;
    }
    return touch;
}

////////////////////////////////////////////////////////////////

// returns true if processing should stop
bool fire_weapon(inout vec4 fragColor, vec2 fragCoord,
                 vec3 old_pos, vec3 old_angles,
                 inout float attack_cycle, inout float shots_fired)
{
	const float ATTACK_DURATION = .75;
    const float ATTACK_WAIT = 1. - 1./(ATTACK_DURATION*RATE_OF_FIRE);

    if (attack_cycle > 0.)
        attack_cycle = max(0., attack_cycle - iTimeDelta * (1./ATTACK_DURATION));
    
    bool wants_to_fire = cmd_attack() > 0.;
    bool resolution_changed = any(notEqual(load(ADDR_RESOLUTION).xy, iResolution.xy));
    if (attack_cycle > ATTACK_WAIT || !wants_to_fire || iFrame <= 0 || resolution_changed)
        return false;

    attack_cycle = 1.;
    shots_fired += 1.;
    if (is_inside(fragCoord, ADDR_RANGE_SHOTGUN_PELLETS) < 0.)
        return false;
    
    Options options;
    LOAD_PREV(options);
    
    float prev_downscale = get_downscale(options);
    vec4 ndc_scale_bias = get_viewport_transform(iFrame-1, iResolution.xy, prev_downscale);
    vec2 ndc = hash2(iTime + fragCoord) * (WEAPON_SPREAD*2.) + -WEAPON_SPREAD;
    vec2 coord = iResolution.xy * (ndc - ndc_scale_bias.zw) / ndc_scale_bias.xy;
    mat3 prev_view_matrix = rotation(old_angles);
    vec3 fire_dir = prev_view_matrix * unproject(ndc);
    GBuffer gbuffer = gbuffer_unpack(texelFetch(iChannel2, ivec2(coord), 0));
    vec3 normal = gbuffer.normal;

    fragColor.xyz = old_pos + fire_dir * (gbuffer.z * VIEW_DISTANCE);
    int material = (gbuffer.z > 12./VIEW_DISTANCE) ? gbuffer.material : MATERIAL_SKY1B;
    fragColor.w = float(material);
    
    // prevent particles from clipping the ground when falling
    // not using 0 as threshold since reconstructed normal isn't 100% accurate
    if (normal.z > .01)	
        fragColor.z += 8.;
    
    return true;
}

////////////////////////////////////////////////////////////////

void update_ideal_pitch(vec3 pos, vec3 forward, vec3 velocity, inout float ideal_pitch)
{
    if (iMouse.z > 0. || length_squared(velocity.xy) < sqr(WALK_SPEED/4.))
        return;
    
    if (dot(forward, normalize(velocity)) < .7)
    {
        ideal_pitch = 0.;
        return;
    }
    
    // look up/down near stairs
    // totally ad-hoc, but it kind of works...
	const vec3 STAIRS[] = vec3[](vec3(272, 496, 24), vec3(816, 496, 24));

    vec3 to_stairs = closest_point_on_segment(pos, STAIRS[0], STAIRS[1]) - pos;
    float sq_dist = length_squared(to_stairs);
    if (sq_dist < sqr(48.))
        return;
    
    float facing_stairs = dot(to_stairs, forward);
    if (sq_dist > (facing_stairs > 0. ? sqr(144.) : sqr(64.)))
    {
        ideal_pitch = 0.;
        return;
    }
    
    if (facing_stairs * inversesqrt(sq_dist) < .7)
        return;

    ideal_pitch = to_stairs.z < 0. ? -STAIRS_PITCH : STAIRS_PITCH;
}

////////////////////////////////////////////////////////////////

#if 0 // 4:3
const vec3 SPAWN_POS		= vec3(544, 296, 49);
const vec4 DEFAULT_ANGLES	= vec4(0);
#else
const vec3 SPAWN_POS		= vec3(544, 272, 49);
const vec4 DEFAULT_ANGLES	= vec4(0, 5, 5, 0);
#endif
const vec4 DEFAULT_POS		= vec4(SPAWN_POS, 0);

void update_input(inout vec4 fragColor, vec2 fragCoord)
{
    float allow_input	= is_input_enabled();
    vec4 pos			= (iFrame==0) ? DEFAULT_POS : load(ADDR_POSITION);
    vec4 angles			= (iFrame==0) ? DEFAULT_ANGLES : load(ADDR_ANGLES);
    vec4 old_pos		= (iFrame==0) ? DEFAULT_POS : load(ADDR_CAM_POS);
    vec4 old_angles		= (iFrame==0) ? DEFAULT_ANGLES : load(ADDR_CAM_ANGLES);
    vec4 velocity		= (iFrame==0) ? vec4(0) : load(ADDR_VELOCITY);
    vec4 ground_plane	= (iFrame==0) ? vec4(0) : load(ADDR_GROUND_PLANE);
    bool thumbnail		= (iFrame==0) ? true : (int(load(ADDR_RESOLUTION).z) & RESOLUTION_FLAG_THUMBNAIL) != 0;
    
    Transitions transitions;
    LOAD_PREV(transitions);
    
    MenuState menu;
    LOAD_PREV(menu);
    if (iFrame > 0 && menu.open > 0)
        return;
    
    if (iFrame == 0 || is_demo_mode_enabled(thumbnail))
        allow_input = 0.;

    if (allow_input > 0. && fire_weapon(fragColor, fragCoord, old_pos.xyz, old_angles.xyz, transitions.attack, transitions.shot_no))
        return;
    
    Options options;
    LOAD_PREV(options);

    angles.w = max(0., angles.w - iTimeDelta);
    if (angles.w == 0.)
    	angles.y = mix(angles.z, angles.y, exp2(-8.*iTimeDelta));

	vec4 mouse_status	= (iFrame==0) ? vec4(0) : load(ADDR_PREV_MOUSE);
    if (allow_input > 0.)
    {
        float mouse_lerp = MOUSE_FILTER > 0. ?
            min(1., iTimeDelta/.0166 / (MOUSE_FILTER + 1.)) :
        	1.;
        if (iMouse.z > 0.)
        {
            float mouse_y_scale = INVERT_MOUSE != 0 ? -1. : 1.;
            if (test_flag(options.flags, OPTION_FLAG_INVERT_MOUSE))
                mouse_y_scale = -mouse_y_scale;
            float sensitivity = SENSITIVITY * exp2((options.sensitivity - 5.) * .5);
            
            if (iMouse.z > mouse_status.z)
                mouse_status = iMouse;
            vec2 mouse_delta = (iMouse.z > mouse_status.z) ?
                vec2(0) : mouse_status.xy - iMouse.xy;
            mouse_delta.y *= -mouse_y_scale;
            angles.xy += 360. * sensitivity * mouse_lerp / max_component(iResolution.xy) * mouse_delta;
            angles.z = angles.y;
            angles.w = AUTOPITCH_DELAY;
        }
        mouse_status = vec4(mix(mouse_status.xy, iMouse.xy, mouse_lerp), iMouse.zw);
    }
    
    float strafe = cmd_strafe();
    float run = (cmd_run()*.5 + .5) * allow_input;
    float look_side = cmd_look_left() - cmd_look_right();
    angles.x += look_side * (1. - strafe) * run * TURN_SPEED * iTimeDelta;
    float look_up = cmd_look_up() - cmd_look_down();
    angles.yz += look_up * run * TURN_SPEED * iTimeDelta;
    // delay auto-pitch for a bit after looking up/down
    if (abs(look_up) > 0.)
        angles.w = .5;
    if (cmd_center_view() * allow_input > 0.)
        angles.zw = vec2(0);
    angles.x = mod(angles.x, 360.);
    angles.yz = clamp(angles.yz, -80., 80.);

#if NOCLIP
    const bool noclip = true;
#else
    bool noclip = test_flag(options.flags, OPTION_FLAG_NOCLIP);
#endif

    mat3 move_axis = rotation(vec3(angles.x, noclip ? angles.y : 0., 0));

    vec3 input_dir		= vec3(0);
    input_dir			+= (cmd_move_forward() - cmd_move_backward()) * move_axis[1];
    float move_side		= cmd_move_right() - cmd_move_left();
    move_side			= clamp(move_side - look_side * strafe, -1., 1.);
    input_dir	 		+= move_side * move_axis[0];
    input_dir.z 		+= (cmd_move_up() - cmd_move_down());
    float wants_to_move = step(0., dot(input_dir, input_dir));
    float wish_speed	= WALK_SPEED * allow_input * wants_to_move * (1. + -.5 * run);

    float lava_dist		= max_component(abs(pos.xyz - clamp(pos.xyz, LAVA_BOUNDS[0], LAVA_BOUNDS[1])));

	if (noclip)
    {
        float friction = mix(NOCLIP_STOP_FRICTION, NOCLIP_START_FRICTION, wants_to_move);
        float velocity_blend = exp2(-friction * iTimeDelta);
        velocity.xyz = mix(input_dir * wish_speed, velocity.xyz, velocity_blend);
        pos.xyz += velocity.xyz * iTimeDelta;
        ground_plane = vec4(0);
    }
    else
    {
        // if not ascending, allow jumping when we touch the ground
        if (input_dir.z <= 0.)
            velocity.w = 0.;
        
        input_dir.xy = safe_normalize(input_dir.xy);
        
        bool on_ground = is_touching_ground(pos.xyz, ground_plane);
        if (on_ground)
        {
            // apply friction
            float speed = length(velocity.xy);
            if (speed < 1.)
            {
                velocity.xy = vec2(0);
            }
            else
            {
                float drop = max(speed, STOP_SPEED) * GROUND_FRICTION * iTimeDelta;
                velocity.xy *= max(0., speed - drop) / speed;
            }
        }
        else
        {
            input_dir.z = 0.;
        }

        if (lava_dist <= 0.)
            wish_speed *= .25;

        // accelerate
		float current_speed = dot(velocity.xy, input_dir.xy);
		float add_speed = wish_speed - current_speed;
		if (add_speed > 0.)
        {
			float accel = on_ground ? GROUND_ACCELERATION : AIR_ACCELERATION;
			float accel_speed = min(add_speed, accel * iTimeDelta * wish_speed);
            velocity.xyz += input_dir * accel_speed;
		}

        if (on_ground)
        {
            velocity.z -= (GRAVITY * .25) * iTimeDelta;	// slowly slide down slopes
            velocity.xyz -= dot(velocity.xyz, ground_plane.xyz) * ground_plane.xyz;

            if (transitions.stair_step <= 0.)
                transitions.bob_phase = fract(transitions.bob_phase + iTimeDelta * (1./BOB_CYCLE));

            update_ideal_pitch(pos.xyz, move_axis[1], velocity.xyz, angles.z);

            if (input_dir.z > 0. && velocity.w <= 0.)
            {
                velocity.z += JUMP_SPEED;
                // wait for the jump key to be released
                // before jumping again (no auto-hopping)
                velocity.w = 1.;
            }
        }
        else
        {
            velocity.z -= GRAVITY * iTimeDelta;
        }

        if (is_inside(fragCoord, ADDR_RANGE_PHYSICS) > 0.)
            slide_move(pos.xyz, velocity.xyz, ground_plane, transitions.stair_step);
    }

    bool teleport = touch_tele(pos.xyz, 16.);
    if (!noclip)
    	teleport = teleport || ((DEFAULT_POS.z - pos.z) > VIEW_DISTANCE); // falling too far below the map

    if (cmd_respawn() * allow_input > 0. || teleport)
    {
        pos = vec4(DEFAULT_POS.xyz, iTime);
        angles = teleport ? vec4(0) : DEFAULT_ANGLES;
        velocity.xyz = vec3(0, teleport ? WALK_SPEED : 0., 0);
        ground_plane = vec4(0);
        transitions.stair_step = 0.;
        transitions.bob_phase = 0.;
    }
    
    // smooth stair stepping
    transitions.stair_step = max(0., transitions.stair_step - iTimeDelta * STAIR_CLIMB_SPEED);

    vec4 cam_pos = pos;
    cam_pos.z -= transitions.stair_step;
    
    // bobbing
    float speed = length(velocity.xy);
    if (speed < 1e-2)
        transitions.bob_phase = 0.;
    cam_pos.z += clamp(speed * BOB_SCALE * (.3 + .7 * sin(TAU * transitions.bob_phase)), -7., 4.);
    
    vec4 cam_angles = vec4(angles.xy, 0, 0);
    
    // side movement roll
    cam_angles.z += clamp(dot(velocity.xyz, move_axis[0]) * (1./ROLL_SPEED), -1., 1.) * ROLL_ANGLE;

    // lava pain roll
    if (lava_dist <= 32.)
    	cam_angles.z += 5. * clamp(fract(iTime*4.)*-2.+1., 0., 1.);
    
    // shotgun recoil
    cam_angles.y += linear_step(.75, 1., transitions.attack) * RECOIL_ANGLE;

    store(fragColor, fragCoord, ADDR_POSITION, pos);
    store(fragColor, fragCoord, ADDR_ANGLES, angles);
    store(fragColor, fragCoord, ADDR_CAM_POS, cam_pos);
    store(fragColor, fragCoord, ADDR_CAM_ANGLES, cam_angles);
    store(fragColor, fragCoord, transitions);
    store(fragColor, fragCoord, ADDR_PREV_CAM_POS, old_pos);
    store(fragColor, fragCoord, ADDR_PREV_CAM_ANGLES, old_angles);
    store(fragColor, fragCoord, ADDR_PREV_MOUSE, mouse_status);
    store(fragColor, fragCoord, ADDR_VELOCITY, velocity);
    store(fragColor, fragCoord, ADDR_GROUND_PLANE, ground_plane);
}

////////////////////////////////////////////////////////////////

void update_perf_stats(inout vec4 fragColor, vec2 fragCoord)
{
    vec4 perf = (iFrame==0) ? vec4(0) : load(ADDR_PERF_STATS);
    perf.x = mix(perf.x, iTimeDelta*1000., 1./16.);
    store(fragColor, fragCoord, ADDR_PERF_STATS, perf);
    
	// shift old perf samples
    const vec4 OLD_SAMPLES = ADDR_RANGE_PERF_HISTORY + vec4(1,0,-1,0);
    if (is_inside(fragCoord, OLD_SAMPLES) > 0.)
        fragColor = texelFetch(iChannel1, ivec2(fragCoord)-ivec2(1,0), 0);

    // add new sample
    if (is_inside(fragCoord, ADDR_RANGE_PERF_HISTORY.xy) > 0.)
    {
        Options options;
        LOAD_PREV(options);
        fragColor = vec4(iTimeDelta*1000., get_downscale(options), 0., 0.);
    }
}

void update_game_rules(inout vec4 fragColor, vec2 fragCoord)
{
    if (is_inside(fragCoord, ADDR_RANGE_TARGETS) > 0.)
    {
        Target target;
        Transitions transitions;
        GameState game_state;
        
        from_vec4(target, fragColor);
        LOAD_PREV(game_state);
        LOAD_PREV(transitions);
        float level = floor(game_state.level);
        float index = floor(fragCoord.x - ADDR_RANGE_TARGETS.x);

        if (target.level != level)
        {
            target.level = level;
            target.shot_no = transitions.shot_no;
            if (level > 0. || index == SKY_TARGET_OFFSET.x)
            	target.hits = 0.;
            to_vec4(fragColor, target);
            return;
        }

        // already processed this shot?
        if (target.shot_no == transitions.shot_no)
            return;
        target.shot_no = transitions.shot_no;
        
        // disable popping during game over animation
        if (game_state.level < 0. && game_state.level != floor(game_state.level))
            return;

        float target_material = index < float(NUM_TARGETS) ? index + float(BASE_TARGET_MATERIAL) : float(MATERIAL_SKY1);
        int hits = 0;

        // The smart thing to do here would be to split the sum over several frames
        // in a binary fashion, but the shader is already pretty complicated,
        // so to make my life easier I'll go with a naive for loop.
        // To save face, let's say I'm doing this to avoid the extra latency
        // of log2(#pellets) frames the smart method would incur...

        for (float f=0.; f<ADDR_RANGE_SHOTGUN_PELLETS.z; ++f)
        {
            vec4 pellet = load(ADDR_RANGE_SHOTGUN_PELLETS.xy + vec2(f, 0.));
            hits += int(pellet.w == target_material);
        }
        
        // sky target is all or nothing
        if (target_material == float(MATERIAL_SKY1))
            hits = int(hits == int(ADDR_RANGE_SHOTGUN_PELLETS.z));
        
        target.hits += float(hits);
        to_vec4(fragColor, target);

        return;
    }
    
    if (is_inside(fragCoord, ADDR_GAME_STATE) > 0.)
    {
        const float
            ADVANCE_LEVEL			= 1. + LEVEL_WARMUP_TIME * .1,
        	FIRST_ROUND_DURATION	= 15.,
        	MIN_ROUND_DURATION		= 6.,
        	ROUND_TIME_DECAY		= -1./8.;
        
        GameState game_state;
        from_vec4(game_state, fragColor);
        
        MenuState menu;
        LOAD(menu);
        float time_delta = menu.open > 0 ? 0. : iTimeDelta;

        if (game_state.level <= 0.)
        {
            float level = ceil(game_state.level);
            if (level < 0. && game_state.level != level)
            {
                game_state.level = min(level, game_state.level + time_delta * .1);
                to_vec4(fragColor, game_state);
                return;
            }
            Target target;
            LOADR(SKY_TARGET_OFFSET, target);
            if (target.hits > 0. && target.level == game_state.level)
            {
                game_state.level = ADVANCE_LEVEL;
                game_state.time_left = FIRST_ROUND_DURATION;
                game_state.targets_left = float(NUM_TARGETS);
            }
        }
        else
        {
            float level = floor(game_state.level);
            if (level != game_state.level)
            {
                game_state.level = max(level, game_state.level - time_delta * .1);
                to_vec4(fragColor, game_state);
                return;
            }
            
            game_state.time_left = max(0., game_state.time_left - time_delta);
            if (game_state.time_left == 0.)
            {
                game_state.level = -(level + BALLOON_SCALEIN_TIME * .1);
                to_vec4(fragColor, game_state);
                return;
            }
            
            float targets_left = 0.;
            Target target;
            for (vec2 addr=vec2(0); addr.x<ADDR_RANGE_TARGETS.z-1.; ++addr.x)
            {
                LOADR(addr, target);
                if (target.hits < ADDR_RANGE_SHOTGUN_PELLETS.z * .5 || target.level != level)
                    ++targets_left;
            }
            
            if (floor(game_state.targets_left) != targets_left)
                game_state.targets_left = targets_left + HUD_TARGET_ANIM_TIME * .1;
            else
                game_state.targets_left = max(floor(game_state.targets_left), game_state.targets_left - time_delta * .1);

            if (targets_left == 0.)
            {
                game_state.level = level + ADVANCE_LEVEL;
                game_state.time_left *= .5;
                game_state.time_left += mix(MIN_ROUND_DURATION, FIRST_ROUND_DURATION, exp2(level*ROUND_TIME_DECAY));
                game_state.targets_left = float(NUM_TARGETS);
            }
        }

        to_vec4(fragColor, game_state);
        return;
    }
}

////////////////////////////////////////////////////////////////

void update_menu(inout vec4 fragColor, vec2 fragCoord)
{
#if ENABLE_MENU
    if (is_inside(fragCoord, ADDR_MENU) > 0.)
    {
        MenuState menu;
        if (iFrame == 0)
            clear(menu);
        else
            from_vec4(menu, fragColor);

    	if (is_input_enabled() > 0.)
        {
            if (cmd_menu() > 0.)
            {
                menu.open ^= 1;
            }
            else if (menu.open > 0)
            {
                menu.selected += int(is_key_pressed(KEY_DOWN) > 0.) - int(is_key_pressed(KEY_UP) > 0.) + NUM_OPTIONS;
                menu.selected %= NUM_OPTIONS;
            }
        }
       
        to_vec4(fragColor, menu);
        return;
    }
    
    if (is_inside(fragCoord, ADDR_OPTIONS) > 0.)
    {
        if (iFrame == 0)
        {
            Options options;
            clear(options);
            to_vec4(fragColor, options);
            return;
        }
        
        MenuState menu;
        LOAD(menu);

        int screen_size_field = get_option_field(OPTION_DEF_SCREEN_SIZE);
        float screen_size = fragColor[screen_size_field];
        if (is_key_pressed(KEY_1) > 0.) 	screen_size = 10.;
        if (is_key_pressed(KEY_2) > 0.) 	screen_size = 8.;
        if (is_key_pressed(KEY_3) > 0.) 	screen_size = 6.;
        if (is_key_pressed(KEY_4) > 0.) 	screen_size = 4.;
        if (is_key_pressed(KEY_5) > 0.) 	screen_size = 2.;
        if (max(is_key_pressed(KEY_MINUS), is_key_pressed(KEY_MINUS_FF)) > 0.)
            screen_size -= 2.;
        if (max(is_key_pressed(KEY_PLUS), is_key_pressed(KEY_PLUS_FF)) > 0.)
            screen_size += 2.;
        fragColor[screen_size_field] = clamp(screen_size, 0., 10.);
        
        int flags_field = get_option_field(OPTION_DEF_SHOW_FPS);
        int flags = int(fragColor[flags_field]);

        if (is_key_pressed(TOGGLE_TEX_FILTER_KEY) > 0.)
            flags ^= OPTION_FLAG_TEXTURE_FILTER;
        if (is_key_pressed(TOGGLE_LIGHT_SHAFTS_KEY) > 0.)
            flags ^= OPTION_FLAG_LIGHT_SHAFTS;
        if (is_key_pressed(TOGGLE_CRT_EFFECT_KEY) > 0.)
            flags ^= OPTION_FLAG_CRT_EFFECT;
        
        if (is_key_pressed(SHOW_PERF_STATS_KEY) > 0.)
        {
            const int MASK = OPTION_FLAG_SHOW_FPS | OPTION_FLAG_SHOW_FPS_GRAPH;
            // https://fgiesen.wordpress.com/2011/01/17/texture-tiling-and-swizzling/
            // The line below combines Fabian Giesen's trick (offs_x = (offs_x - x_mask) & x_mask)
            // with another one for efficient bitwise integer select (c = a ^ ((a ^ b) & mask)),
            // which I think I also stole from his blog, but I can't find the link
            flags ^= (flags ^ (flags - MASK)) & MASK;
            
            // don't show FPS graph on its own when using keyboard shortcut to cycle through options
            if (test_flag(flags, OPTION_FLAG_SHOW_FPS_GRAPH))
                flags |= OPTION_FLAG_SHOW_FPS;
        }
        
        fragColor[flags_field] = float(flags);

        if (menu.open <= 0)
            return;
        float adjust = is_key_pressed(KEY_RIGHT) - is_key_pressed(KEY_LEFT);

        MenuOption option = get_option(menu.selected);
        int option_type = get_option_type(option);
        int option_field = get_option_field(option);
        if (option_type == OPTION_TYPE_SLIDER)
        {
            fragColor[option_field] += adjust;
            fragColor[option_field] = clamp(fragColor[option_field], 0., 10.);
        }
        else if (option_type == OPTION_TYPE_TOGGLE && (abs(adjust) > .5 || is_key_pressed(KEY_ENTER) > 0.))
        {
            int value = int(fragColor[option_field]);
            value ^= get_option_range(option);
            fragColor[option_field] = float(value);
        }
        
        return;
    }
#endif // ENABLE_MENU
}

void advance_time(inout vec4 fragColor, vec2 fragCoord)
{
    if (is_inside(fragCoord, ADDR_TIMING) > 0.)
    {
        MenuState menu;
        LOAD_PREV(menu);
        
        Timing timing;
        if (iFrame == 0)
            clear(timing);
        else
        	from_vec4(timing, fragColor);

        bool paused = timing.prev == iTime;
        if (paused)
            timing.flags |= TIMING_FLAG_PAUSED;
        else
            timing.flags &= ~TIMING_FLAG_PAUSED;
        
        // Note: on 144 Hz monitors, in thumbnail mode, iTimeDelta
        // seems to be incorrect (1/60 seconds instead of 1/144)
        float time_delta = iTime - timing.prev;
        if (!paused && menu.open == 0 && g_time > WORLD_RENDER_TIME)
            timing.anim += time_delta;
        timing.prev = iTime;
        
        to_vec4(fragColor, timing);
        return;
    }
}

////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
	if (iFrame > 0 && is_inside(fragCoord, ADDR_RANGE_PARAM_BOUNDS) < 0.)
    	DISCARD;

    fragColor = (iFrame==0) ? vec4(0) : texelFetch(iChannel1, ivec2(fragCoord), 0);

    Lighting lighting;
    LOAD_PREV(lighting);
    
    UPDATE_TIME(lighting);

    write_map_data		(fragColor, fragCoord);
    update_tiles		(fragColor, fragCoord);
    update_input		(fragColor, fragCoord);
    update_game_rules	(fragColor, fragCoord);
    update_perf_stats	(fragColor, fragCoord);
    update_menu			(fragColor, fragCoord);
    advance_time		(fragColor, fragCoord);
}
