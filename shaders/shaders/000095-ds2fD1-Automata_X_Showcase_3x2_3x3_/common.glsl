// Common (common) — Automata X Showcase 3x2 (3x3) by misol101
// https://www.shadertoy.com/view/ds2fD1

const float LAST_PATT = 3.;
const float cstep=1./256.;

float density=50., density2=-1.;
float liveval = 2.0;
int newmethod = 0;
float decimate = 0.;
float rp,gp,bp, rm,gm,bm, stayval;
int colch, staypatt;
int ra,ga,ba;
bool clampstay;
int setmethod;
int stayset, bornset;
int nh;
int wrap;

void setRules(int index, vec3 col) {
    int v1, v2;
    decimate = 1.;liveval=2.;

    rp=4.,gp=3.,bp=10., rm=2.,gm=2.,bm=8., ra=7,ga=7,ba=7,staypatt=1,stayval=1.,colch=0, clampstay=false, setmethod=0; nh=10, wrap=0, density2=-1.;

    // sponge
    if (index == 0) {nh=5; v1 = 1175456, v2=1910512; density=11., liveval=6., decimate=1., colch=1, staypatt=0, rp=0.24, gp=0.36, bp=0.15, rm=26., gm=41.,bm=81.,  ra=1,ga=2,ba=4; density2=15.; }

    // baby explosions
    if (index == 1) {nh=5; v1 = 1175524, v2=1910512; density=20., liveval=6., decimate=1., colch=1, staypatt=0, rp=3., gp=1.5, bp=1.5, rm=6., gm=8.,bm=13.,  ra=1,ga=2,ba=4; }

    // worms
    if (index == 2) {nh=10; v1 = 4094, v2=3966; density=90., liveval=5., decimate=0., colch=2, staypatt=0, rp=10., gp=4., bp=4., rm=16., gm=16.,bm=18.,  ra=6,ga=7,ba=6; density2=6.;}

    // generative
    if (index == 3) {nh=0; v1 = 23, v2=86; density=6., liveval=5., decimate=0., colch=2, staypatt=0, rp=10.*1.3, gp=7.*1.3, bp=20.*1.3, rm=2., gm=2.,bm=2.,  ra=1,ga=2,ba=4; }

    // pump
    if (index == 4) {nh=5; v1 = 1175552, v2=1910552; density=100., liveval=7., decimate=1., colch=3, staypatt=0, rp=11.5, gp=6.5, bp=6.5, rm=6., gm=7.5,bm=13.,  ra=1,ga=3,ba=7; density2=10.; }

    // straight lines
    if (index == 5) {nh=6; v1 = 50182, v2=16516; density=20., liveval=6., decimate=0., colch=1, staypatt=5, rp=4., gp=4., bp=8., rm=6., gm=16.,bm=18.,  ra=6,ga=7,ba=6; }

    // small worms
    if (index == 6) {nh=10, v1 = 64860, v2=4094; density=80.; liveval=2.; decimate=0.; colch=2, staypatt=6; rp=9.; rm=16.,gm=16.,bm=18.; ra=6,ga=7,ba=6; density2=10.; } 

    // straight lines II
    if (index == 7) {nh=-1, v1 = 200, v2=14; density=6.; liveval=3.; decimate=1.; staypatt=6; rp=5.; rm=8.5,gm=8.5,bm=6.; ra=1,ga=2,ba=4; density2=10.; } 

    // square critters
    if (index == 8) {nh=4, v1 = 1175537, v2=1910520; density=70.; liveval=6.; decimate=1.;  colch=1, staypatt=1, rp=10., gp=2.5, bp=1., rm=39., gm=39.,bm=39.,  ra=1,ga=2,ba=4; density2=10.; } 


    rp=rp+col.x; gp=gp+col.y; bp=bp+col.z;
    stayset = v1; bornset = v2;
}

float hash1( float n ) {
    return fract(sin(n)*138.5453123);
}

#define readKey(key) (texelFetch( iChannel1, ivec2(key, 0), 0).x > .5)

const int KEY_SPACE = 32;
const int KEY_LEFT  = 37;
const int KEY_RIGHT = 39;
const int KEY_UP    = 38;
const int KEY_DOWN  = 40;
const int KEY_ENTER = 13;
const int KEY_0     = 48;
const int KEY_1     = 49;
const int KEY_2     = 50;
const int KEY_3     = 51;
const int KEY_4     = 52;
const int KEY_5     = 53;
const int KEY_6     = 54;
const int KEY_7     = 55;
const int KEY_8     = 56;
const int KEY_9     = 57;
const int KEY_A     = 65;
const int KEY_M     = 77;
const int KEY_Z     = 90;
const int KEY_X     = 88;
const int KEY_C     = 67;
const int KEY_V     = 86;
const int KEY_B     = 66;
const int KEY_Q     = 81;
const int KEY_W     = 87;
const int KEY_E     = 69;
const int KEY_R     = 82;
const int KEY_T     = 84;
const int KEY_G     = 71;
