// Image (image) — [SH17C] Schooling by P_Malin
// https://www.shadertoy.com/view/Md2fzV

// [SH17C] Schooling
// @P_Malin
// Entry for round #3 of the Shadertoy competition 2017

// References:

// "Flocks, Herds, and Schools: A Distributed Behavioral Model"
// Craig Reynolds
// http://www.cs.toronto.edu/~dt/siggraph97-course/cwr87/

// "Steering Behaviors For Autonomous Characters"
// Craig Reynolds
// http://www.red3d.com/cwr/steer/gdc99/


// The code for the boid update is in "Buf B"


// Image shader

// Image composision
// UI composition
// Text composition

#define iChannelUI iChannel0
#define iChannelRender iChannel1
#define iChannelFont iChannel3

// ---------------------- 8< --------------------- 8< --------------------------

///////////////////////////
// UI Data
///////////////////////////

float UI_GetFloat( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).x;
}

bool UI_GetBool( int iData )
{
    return UI_GetFloat( iData ) > 0.5;
}

vec3 UI_GetColor( int iData )
{
    return texelFetch( iChannelUI, ivec2(iData,0), 0 ).rgb;
}


void UI_Compose( vec2 fragCoord, inout vec3 vColor, out int windowId, out vec2 vWindowCoord )
{
    vec4 vUISample = texelFetch( iChannelUI, ivec2(fragCoord), 0 );
    
    if ( fragCoord.y < 2.0 )
    {
        // Hide data
        vUISample = vec4(1.0, 1.0, 1.0, 1.0);
    }
    
    vColor.rgb = vColor.rgb * (1.0f - vUISample.w) + vUISample.rgb;
    
    windowId = -1;
    vWindowCoord = vec2(0);
    
    if ( vUISample.a < 0.0 )
    {
        vWindowCoord = vUISample.rg;
        windowId = int(round(vUISample.b));
    }
}

///////////////////////////
// UI Data Definitions
///////////////////////////

// ---------------------- 8< --------------------- 8< --------------------------

const int
     DATA_UICONTEXT						= 0
	,DATA_WINDOW_CONTROLS   			= 2
    ,DATA_PAGE_NO						= 4
    ,DATA_FADE							= 5
	,DATA_SEPARATION					= 6
	,DATA_COHESION						= 7
	,DATA_ALIGNMENT						= 8
    ,DATA_COUNT							= 9
    ,DATA_WALLS 						= 10
    ;    

// ---------------------- 8< --------------------- 8< --------------------------



///////////////////////////
// Font Printing
///////////////////////////
struct TextLine
{
    int firstChar;
    int charCount;
};

struct TextPage
{
    int firstLine;
    int lineCount;
};

struct TextPages
{
    TextPage pages[18];
    TextLine lines[81];
    uint characters[539];
};
const TextPages textPages = TextPages (
   TextPage[18](
       TextPage( 0, 1 ),
       TextPage( 1, 2 ),
       TextPage( 3, 1 ),
       TextPage( 4, 10 ),
       TextPage( 14, 1 ),
       TextPage( 15, 5 ),
       TextPage( 20, 1 ),
       TextPage( 21, 11 ),
       TextPage( 32, 1 ),
       TextPage( 33, 7 ),
       TextPage( 40, 1 ),
       TextPage( 41, 8 ),
       TextPage( 49, 1 ),
       TextPage( 50, 13 ),
       TextPage( 63, 1 ),
       TextPage( 64, 11 ),
       TextPage( 75, 0 ),
       TextPage( 75, 6 )
   ),
   TextLine[81](
       TextLine( 0, 17 ), // "[SH17C] Schooling"
       TextLine( 17, 0 ), // ""
       TextLine( 17, 23 ), // "Press Space to continue"
       TextLine( 40, 17 ), // "[SH17C] Schooling"
       TextLine( 57, 0 ), // ""
       TextLine( 57, 57 ), // "This shadertoy illustrates a simplified implementation of"
       TextLine( 114, 33 ), // "the 1987 paper by Craig Reynolds."
       TextLine( 147, 0 ), // ""
       TextLine( 147, 59 ), // ""Flocks, herds and schools: A distributed behavioral model""
       TextLine( 206, 0 ), // ""
       TextLine( 206, 50 ), // "I always found this work fascinating in many ways."
       TextLine( 256, 57 ), // "To me this is the embodiment of a complex system, showing"
       TextLine( 313, 54 ), // "how a set of agents with simple rules can give rise to"
       TextLine( 367, 26 ), // "complex emergent behavior."
       TextLine( 393, 5 ), // "Boids"
       TextLine( 398, 0 ), // ""
       TextLine( 398, 51 ), // "We model a number of "Boids". Each boid just stores"
       TextLine( 449, 57 ), // "a position and velocity. These are updated each frame. A "
       TextLine( 506, 61 ), // "simple set of steering rules that modify the velocities gives"
       TextLine( 567, 39 ), // "rise to the lifelike flocking behavior."
       TextLine( 606, 14 ), // "Flocking Rules"
       TextLine( 620, 0 ), // ""
       TextLine( 620, 28 ), // "We update each boid in turn."
       TextLine( 648, 57 ), // "Three steering rules produce the basic flocking behavior:"
       TextLine( 705, 0 ), // ""
       TextLine( 705, 13 ), // " - Separation"
       TextLine( 718, 11 ), // " - Cohesion"
       TextLine( 729, 12 ), // " - Alignment"
       TextLine( 741, 0 ), // ""
       TextLine( 741, 34 ), // "We weight each rule to control its"
       TextLine( 775, 35 ), // "influence. Each of these rules only"
       TextLine( 810, 27 ), // "considers nearby neighbors."
       TextLine( 837, 10 ), // "Separation"
       TextLine( 847, 0 ), // ""
       TextLine( 847, 46 ), // "The separation rule keeps flockmates apart. We"
       TextLine( 893, 48 ), // "apply a force to the boid we are updating in the"
       TextLine( 941, 48 ), // "direction pointing away from each local neighbor"
       TextLine( 989, 0 ), // ""
       TextLine( 989, 36 ), // "The strength of the separation force"
       TextLine( 1025, 34 ), // "increases as the boids get closer."
       TextLine( 1059, 8 ), // "Cohesion"
       TextLine( 1067, 0 ), // ""
       TextLine( 1067, 52 ), // "The cohesion rule keeps the flock together, stopping"
       TextLine( 1119, 24 ), // "boids wandering too far."
       TextLine( 1143, 0 ), // ""
       TextLine( 1143, 30 ), // "The average position of nearby"
       TextLine( 1173, 30 ), // "flockmates is calculated and a"
       TextLine( 1203, 33 ), // "steering force is applied towards"
       TextLine( 1236, 14 ), // "this location."
       TextLine( 1250, 9 ), // "Alignment"
       TextLine( 1259, 0 ), // ""
       TextLine( 1259, 53 ), // "The alignment rule keeps the flock moving in the same"
       TextLine( 1312, 10 ), // "direction."
       TextLine( 1322, 0 ), // ""
       TextLine( 1322, 32 ), // "The average velocity (or forward"
       TextLine( 1354, 31 ), // "direction) of flockmates in the"
       TextLine( 1385, 34 ), // "nearby neighborhood is calculated."
       TextLine( 1419, 31 ), // "This is the "ideal" or "target""
       TextLine( 1450, 36 ), // "velocity for this steering behavior."
       TextLine( 1486, 33 ), // "By subtracting the current boid's"
       TextLine( 1519, 35 ), // "velocity from this target velocity,"
       TextLine( 1554, 29 ), // "we get the alignment steering"
       TextLine( 1583, 15 ), // "force to apply."
       TextLine( 1598, 8 ), // "Flocking"
       TextLine( 1606, 0 ), // ""
       TextLine( 1606, 47 ), // "These three simple rules give rise to the basic"
       TextLine( 1653, 47 ), // "flocking behavior. With this model, there is no"
       TextLine( 1700, 44 ), // "leader and each boid is just considering its"
       TextLine( 1744, 45 ), // "local neighbors and yet we see flocks forming"
       TextLine( 1789, 45 ), // "And we start to see emergent behavior such as"
       TextLine( 1834, 29 ), // "flocks splitting and merging."
       TextLine( 1863, 0 ), // ""
       TextLine( 1863, 51 ), // "By adding additional rules such as random wandering"
       TextLine( 1914, 47 ), // "and collision avoidance we see more interesting"
       TextLine( 1961, 17 ), // "behaviors emerge."
       TextLine( 1978, 45 ), // "The links to the original papers can be found"
       TextLine( 2023, 26 ), // "In the "Image" shader tab."
       TextLine( 2049, 46 ), // "The boid simulation code is in the "Buf B" tab"
       TextLine( 2095, 0 ), // ""
       TextLine( 2095, 38 ), // "Use the sliders to experiment with the"
       TextLine( 2133, 23 ) // "influence of each rule."

   ),
   uint[539](0x3148535bu, 0x205d4337u, 0x6f686353u, 0x6e696c6fu, 0x65725067u, 0x53207373u, 0x65636170u, 0x206f7420u, 0x746e6f63u, 0x65756e69u, 0x3148535bu, 0x205d4337u, 0x6f686353u, 0x6e696c6fu, 0x69685467u, 0x68732073u, 0x72656461u, 0x20796f74u, 0x756c6c69u, 0x61727473u, 0x20736574u, 0x69732061u, 0x696c706du, 0x64656966u, 0x706d6920u, 0x656d656cu, 0x7461746eu, 0x206e6f69u, 0x6874666fu, 0x39312065u, 0x70203738u, 0x72657061u, 0x20796220u, 0x69617243u, 0x65522067u, 0x6c6f6e79u, 0x222e7364u, 0x636f6c46u, 0x202c736bu, 0x64726568u, 0x6e612073u, 0x63732064u, 0x6c6f6f68u, 0x41203a73u, 0x73696420u, 0x62697274u, 0x64657475u, 0x68656220u, 0x6f697661u, 0x206c6172u, 0x65646f6du, 0x2049226cu, 0x61776c61u, 0x66207379u, 0x646e756fu, 0x69687420u, 0x6f772073u, 0x66206b72u, 0x69637361u, 0x6974616eu, 0x6920676eu, 0x616d206eu, 0x7720796eu, 0x2e737961u, 0x6d206f54u, 0x68742065u, 0x69207369u, 0x68742073u, 0x6d652065u, 0x69646f62u, 0x746e656du, 0x20666f20u, 0x6f632061u, 0x656c706du, 0x79732078u, 0x6d657473u, 0x6873202cu, 0x6e69776fu, 0x776f6867u, 0x73206120u, 0x6f207465u, 0x67612066u, 0x73746e65u, 0x74697720u, 0x69732068u, 0x656c706du, 0x6c757220u, 0x63207365u, 0x67206e61u, 0x20657669u, 0x65736972u, 0x636f7420u, 0x6c706d6fu, 0x65207865u, 0x6772656du, 0x20746e65u, 0x61686562u, 0x726f6976u, 0x696f422eu, 0x65577364u, 0x646f6d20u, 0x61206c65u, 0x6d756e20u, 0x20726562u, 0x2220666fu, 0x64696f42u, 0x202e2273u, 0x68636145u, 0x696f6220u, 0x756a2064u, 0x73207473u, 0x65726f74u, 0x70206173u, 0x7469736fu, 0x206e6f69u, 0x20646e61u, 0x6f6c6576u, 0x79746963u, 0x6854202eu, 0x20657365u, 0x20657261u, 0x61647075u, 0x20646574u, 0x68636165u, 0x61726620u, 0x202e656du, 0x69732041u, 0x656c706du, 0x74657320u, 0x20666f20u, 0x65657473u, 0x676e6972u, 0x6c757220u, 0x74207365u, 0x20746168u, 0x69646f6du, 0x74207966u, 0x76206568u, 0x636f6c65u, 0x65697469u, 0x69672073u, 0x72736576u, 0x20657369u, 0x74206f74u, 0x6c206568u, 0x6c656669u, 0x20656b69u, 0x636f6c66u, 0x676e696bu, 0x68656220u, 0x6f697661u, 0x6c462e72u, 0x696b636fu, 0x5220676eu, 0x73656c75u, 0x75206557u, 0x74616470u, 0x61652065u, 0x62206863u, 0x2064696fu, 0x74206e69u, 0x2e6e7275u, 0x65726854u, 0x74732065u, 0x69726565u, 0x7220676eu, 0x73656c75u, 0x6f727020u, 0x65637564u, 0x65687420u, 0x73616220u, 0x66206369u, 0x6b636f6cu, 0x20676e69u, 0x61686562u, 0x726f6976u, 0x202d203au, 0x61706553u, 0x69746172u, 0x2d206e6fu, 0x686f4320u, 0x6f697365u, 0x202d206eu, 0x67696c41u, 0x6e656d6eu, 0x20655774u, 0x67696577u, 0x65207468u, 0x20686361u, 0x656c7572u, 0x206f7420u, 0x746e6f63u, 0x206c6f72u, 0x69737469u, 0x756c666eu, 0x65636e65u, 0x6145202eu, 0x6f206863u, 0x68742066u, 0x20657365u, 0x656c7572u, 0x6e6f2073u, 0x6f63796cu, 0x6469736eu, 0x20737265u, 0x7261656eu, 0x6e207962u, 0x68676965u, 0x73726f62u, 0x7065532eu, 0x74617261u, 0x546e6f69u, 0x73206568u, 0x72617065u, 0x6f697461u, 0x7572206eu, 0x6b20656cu, 0x73706565u, 0x6f6c6620u, 0x616d6b63u, 0x20736574u, 0x72617061u, 0x57202e74u, 0x70706165u, 0x6120796cu, 0x726f6620u, 0x74206563u, 0x6874206fu, 0x6f622065u, 0x77206469u, 0x72612065u, 0x70752065u, 0x69746164u, 0x6920676eu, 0x6874206eu, 0x72696465u, 0x69746365u, 0x70206e6fu, 0x746e696fu, 0x20676e69u, 0x79617761u, 0x6f726620u, 0x6165206du, 0x6c206863u, 0x6c61636fu, 0x69656e20u, 0x6f626867u, 0x65685472u, 0x72747320u, 0x74676e65u, 0x666f2068u, 0x65687420u, 0x70657320u, 0x74617261u, 0x206e6f69u, 0x63726f66u, 0x636e6965u, 0x73616572u, 0x61207365u, 0x68742073u, 0x6f622065u, 0x20736469u, 0x20746567u, 0x736f6c63u, 0x432e7265u, 0x7365686fu, 0x546e6f69u, 0x63206568u, 0x7365686fu, 0x206e6f69u, 0x656c7572u, 0x65656b20u, 0x74207370u, 0x66206568u, 0x6b636f6cu, 0x676f7420u, 0x65687465u, 0x73202c72u, 0x70706f74u, 0x62676e69u, 0x7364696fu, 0x6e617720u, 0x69726564u, 0x7420676eu, 0x66206f6fu, 0x542e7261u, 0x61206568u, 0x61726576u, 0x70206567u, 0x7469736fu, 0x206e6f69u, 0x6e20666fu, 0x62726165u, 0x6f6c6679u, 0x616d6b63u, 0x20736574u, 0x63207369u, 0x75636c61u, 0x6574616cu, 0x6e612064u, 0x73612064u, 0x72656574u, 0x20676e69u, 0x63726f66u, 0x73692065u, 0x70706120u, 0x6465696cu, 0x776f7420u, 0x73647261u, 0x73696874u, 0x636f6c20u, 0x6f697461u, 0x6c412e6eu, 0x6d6e6769u, 0x54746e65u, 0x61206568u, 0x6e67696cu, 0x746e656du, 0x6c757220u, 0x656b2065u, 0x20737065u, 0x20656874u, 0x636f6c66u, 0x6f6d206bu, 0x676e6976u, 0x206e6920u, 0x20656874u, 0x656d6173u, 0x65726964u, 0x6f697463u, 0x68542e6eu, 0x76612065u, 0x67617265u, 0x65762065u, 0x69636f6cu, 0x28207974u, 0x6620726fu, 0x6177726fu, 0x69646472u, 0x74636572u, 0x296e6f69u, 0x20666f20u, 0x636f6c66u, 0x74616d6bu, 0x69207365u, 0x6874206eu, 0x61656e65u, 0x20796272u, 0x6769656eu, 0x726f6268u, 0x646f6f68u, 0x20736920u, 0x636c6163u, 0x74616c75u, 0x542e6465u, 0x20736968u, 0x74207369u, 0x22206568u, 0x61656469u, 0x6f20226cu, 0x74222072u, 0x65677261u, 0x65762274u, 0x69636f6cu, 0x66207974u, 0x7420726fu, 0x20736968u, 0x65657473u, 0x676e6972u, 0x68656220u, 0x6f697661u, 0x79422e72u, 0x62757320u, 0x63617274u, 0x676e6974u, 0x65687420u, 0x72756320u, 0x746e6572u, 0x696f6220u, 0x76732764u, 0x636f6c65u, 0x20797469u, 0x6d6f7266u, 0x69687420u, 0x61742073u, 0x74656772u, 0x6c657620u, 0x7469636fu, 0x65772c79u, 0x74656720u, 0x65687420u, 0x696c6120u, 0x656d6e67u, 0x7320746eu, 0x72656574u, 0x66676e69u, 0x6563726fu, 0x206f7420u, 0x6c707061u, 0x6c462e79u, 0x696b636fu, 0x6854676eu, 0x20657365u, 0x65726874u, 0x69732065u, 0x656c706du, 0x6c757220u, 0x67207365u, 0x20657669u, 0x65736972u, 0x206f7420u, 0x20656874u, 0x69736162u, 0x6f6c6663u, 0x6e696b63u, 0x65622067u, 0x69766168u, 0x202e726fu, 0x68746957u, 0x69687420u, 0x6f6d2073u, 0x2c6c6564u, 0x65687420u, 0x69206572u, 0x6f6e2073u, 0x6461656cu, 0x61207265u, 0x6520646eu, 0x20686361u, 0x64696f62u, 0x20736920u, 0x7473756au, 0x6e6f6320u, 0x65646973u, 0x676e6972u, 0x73746920u, 0x61636f6cu, 0x656e206cu, 0x62686769u, 0x2073726fu, 0x20646e61u, 0x20746579u, 0x73206577u, 0x66206565u, 0x6b636f6cu, 0x6f662073u, 0x6e696d72u, 0x646e4167u, 0x20657720u, 0x72617473u, 0x6f742074u, 0x65657320u, 0x656d6520u, 0x6e656772u, 0x65622074u, 0x69766168u, 0x7320726fu, 0x20686375u, 0x6c667361u, 0x736b636fu, 0x6c707320u, 0x69747469u, 0x6120676eu, 0x6d20646eu, 0x69677265u, 0x422e676eu, 0x64612079u, 0x676e6964u, 0x64646120u, 0x6f697469u, 0x206c616eu, 0x656c7572u, 0x75732073u, 0x61206863u, 0x61722073u, 0x6d6f646eu, 0x6e617720u, 0x69726564u, 0x6e61676eu, 0x6f632064u, 0x73696c6cu, 0x206e6f69u, 0x696f7661u, 0x636e6164u, 0x65772065u, 0x65657320u, 0x726f6d20u, 0x6e692065u, 0x65726574u, 0x6e697473u, 0x68656267u, 0x6f697661u, 0x65207372u, 0x6772656du, 0x68542e65u, 0x696c2065u, 0x20736b6eu, 0x74206f74u, 0x6f206568u, 0x69676972u, 0x206c616eu, 0x65706170u, 0x63207372u, 0x62206e61u, 0x6f662065u, 0x49646e75u, 0x6874206eu, 0x49222065u, 0x6567616du, 0x68732022u, 0x72656461u, 0x62617420u, 0x6568542eu, 0x696f6220u, 0x69732064u, 0x616c756du, 0x6e6f6974u, 0x646f6320u, 0x73692065u, 0x206e6920u, 0x20656874u, 0x66754222u, 0x20224220u, 0x55626174u, 0x74206573u, 0x73206568u, 0x6564696cu, 0x74207372u, 0x7865206fu, 0x69726570u, 0x746e656du, 0x74697720u, 0x68742068u, 0x666e6965u, 0x6e65756cu, 0x6f206563u, 0x61652066u, 0x72206863u, 0x2e656c75u)
);




///////////////////////////
// Font Printing
///////////////////////////

void PrintChar( inout vec2 vOutCharUV, vec2 vUV, uint uChar )
{
    if ( any( lessThan( vUV, vec2(0) ) ) ) return;
    if ( any( greaterThanEqual( vUV, vec2(1) ) ) ) return;
        
    uint uCharX = uChar % 16u;
    uint uCharY = uChar / 16u;
    
    vec2 vCharPos = vec2(uCharX, uCharY) / 16.0;
    vec2 vCharSize = vec2(1,1) / 16.0;
    
    vec2 vInset = vec2( 0.25, 0.0 );
    
    if ( uChar == 87u || uChar == 119u )
        vInset.x -= 0.05; // thinner 'W'
    
    vCharPos += vCharSize * vInset;
    
    vCharSize *= 1.0 - vInset * 2.0;
    
    vOutCharUV = vUV * vCharSize + vCharPos;    
}

void PrintPage( inout vec2 vCharUV, vec2 vFontUV, int pageNo )
{
    int lineCharPos = int(floor(vFontUV.x));
    int pageLine = int(floor(vFontUV.y));
    
    TextPage currPage = textPages.pages[pageNo];
    
	if ( pageLine < 0 || pageLine >= currPage.lineCount )
        return;
    
    TextLine currLine = textPages.lines[currPage.firstLine + pageLine];
    
	if ( lineCharPos < 0 || lineCharPos >= currLine.charCount )
        return;
    
    int charIndex = currLine.firstChar + lineCharPos;
    
    int charPos = charIndex / 4 ;
    int charShift = 8 * (charIndex %4);
    
    uint char = ( textPages.characters[ charPos ] >> charShift ) % 256u;
    
    PrintChar( vCharUV, fract(vFontUV), char );
}

float DrawText( vec2 fragCoord, int pageNo )
{
    vec2 vFontUV = fragCoord / iResolution.xy;
    vFontUV.y = 1.0 - vFontUV.y;
    vFontUV *= 15.0;
    vFontUV.x *= 3.0;
    
    vFontUV -= vec2(2.0, 1.0);
    
    vec2 vCharUV = vec2(0);
    
    int headingPage = pageNo * 2;
    int bodyPage = headingPage + 1;
        
    if ( pageNo < 9 )
    {
        PrintPage( vCharUV, vFontUV, headingPage );
        vFontUV *= 1.5;
        vFontUV.y -= 1.0;
        if ( pageNo == 8 )
        {
        	vFontUV.x -= 8.0;
        	vFontUV.y -= 13.0;
        }
        
        PrintPage( vCharUV, vFontUV, bodyPage );        
    }

    float fFont = textureLod( iChannelFont, vCharUV, 0.0 ).w;
	
	return fFont;
}


const ivec2 GRID_SIZE = ivec2( 100 );

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 vResult = vec3(0.0);
      
    vResult = texelFetch( iChannelRender, ivec2(fragCoord), 0 ).rgb;

	int windowId;
    vec2 vWindowCoord;
    UI_Compose( fragCoord, vResult, windowId, vWindowCoord );

    float fFont = DrawText( fragCoord, int( UI_GetFloat(DATA_PAGE_NO)) );

    float fOutline = clamp ( (0.56 - fFont) * 20.0, 0.0, 1.0 );
    float fMain = clamp ( (0.52 - fFont) * 20.0, 0.0, 1.0 );
    
    vResult = mix( vResult, vec3(0), fOutline );
    vResult = mix( vResult, vec3(1,1,1), fMain );
    
	fragColor = vec4(vResult,1.0);
}
