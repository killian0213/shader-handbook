// Image (image) — Quake / Introduction by adx
// https://www.shadertoy.com/view/lsKfWd

#if __VERSION__ < 300
#	error Sorry, this shader requires WebGL 2.0!
#endif

/***************************************************************
  Quake / Introduction
  A textureless* shader recreating the first room of Quake (1996)
  Andrei Drexler 2018

  For some details on how this shader was made, see this Twitter thread:
  https://twitter.com/andrei_drexler/status/1217945589989748742

  Many thanks to:

- id Software - for creating not only a great game/series, but also
  a thriving modding community around it through the release of
  dev tools, code, and specs, inspiring new generations of game developers:
  https://github.com/id-Software/Quake

- John Romero - for creating such memorable designs in the first place,
  and then releasing the original map files:
  https://rome.ro/news/2016/2/14/quake-map-sources-released

- Inigo Quilez (@iq) - for his many articles/code samples on signed distance fields,
  ray-marching, noise and more:
  https://iquilezles.org/articles/distfunctions
  https://iquilezles.org/articles/smin
  https://iquilezles.org/articles/voronoilines
  https://iquilezles.org/www/index.htm

- Jamie Wong (@jlfwong) - for his article on ray-marching/SDF's (and accompanying samples):
  http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/

- Mercury - for the hg_sdf library:
  http://mercury.sexy/hg_sdf

- Paul Malin (@P_Malin) - for his awesome QTest shader, that prompted me to resume work and replace
  the AO+TSS+negative/capsule lights combo with proper lightmaps, somewhat similar to his solution:
  https://www.shadertoy.com/view/MdGXDK

- Brian Sharpe - for his GPU noise library/blog:
  https://github.com/BrianSharpe/GPU-Noise-Lib
  https://briansharpe.wordpress.com

- Dave Hoskins (@Dave_Hoskins) - for his 'Hash without Sine' functions:
  https://www.shadertoy.com/view/4djSRW

- Marc B. Reynolds (@MBR) - for his 2D Weyl hash code
  https://www.shadertoy.com/view/Xdy3Rc
  http://marc-b-reynolds.github.io/math/2016/03/29/weyl_hash.html

- Morgan McGuire (@morgan3d) - hash functions:
  https://www.shadertoy.com/view/4dS3Wd
  http://graphicscodex.com

- Fabrice Neyret (@FabriceNeyret2) - for his 'Shadertoy - Unofficial' blog:
  https://shadertoyunofficial.wordpress.com

- Alan Wolfe (@demofox) - for his blog post on making a ray-traced snake game in Shadertoy,
  which inspired me to get started with this shader:
  https://blog.demofox.org/2016/01/16/making-a-ray-traced-snake-game-in-shadertoy/
  https://www.shadertoy.com/view/XsdGDX

- Playdead - for their presentation/code on temporal reprojection antialiasing:
  http://twvideo01.ubm-us.net/o1/vault/gdc2016/Presentations/Pedersen_LasseJonFuglsang_TemporalReprojectionAntiAliasing.pdf
  https://github.com/playdeadgames/temporal

- Sebastian Aaltonen (@sebbbi) - for his 'Advection filter comparison' shader:
  https://www.shadertoy.com/view/lsG3D1

- Bart Wronski - for his Poisson sampling generator:
  https://github.com/bartwronski/PoissonSamplingGenerator

- And, of course, Inigo Quilez and Pol Jeremias - for Shadertoy.
  
  ---

  If you're interested in other recreations of id Software games,
  you might also like:
  
- Wolfenstein 3D by @reinder:
  https://www.shadertoy.com/view/4sfGWX

- [SH16C] Doom by @P_Malin - fully playable E1M1, pushing the Shadertoy game concept to its limits:
  https://www.shadertoy.com/view/lldGDr

- Doom 2 by @reinder:
  https://www.shadertoy.com/view/lsB3zD

- QTest by @P_Malin:
  https://www.shadertoy.com/view/MdGXDK

  ---

  * The blue noise texture doesn't count!
***************************************************************/

////////////////////////////////////////////////////////////////
// Image buffer:
// - loading screen/console
// - rendered image presentation + motion blur
// - pain blend
// - performance graph
// - text (console/skill selection/demo stage)
////////////////////////////////////////////////////////////////

// config.cfg //////////////////////////////////////////////////

#define FPS_GRAPH_MAX			60
#define PRINT_SKILL_MESSAGE		1
#define GAMMA_MODE				0		// [0=RGB; 1=luma]

#define USE_CRT_EFFECT			1
#define CRT_MASK_WEIGHT			1./16.
#define CRT_SCANLINE_WEIGHT		1./16.

#define USE_MOTION_BLUR			1
#define MOTION_BLUR_FPS			60
#define MOTION_BLUR_AMOUNT		0.5		// fraction of frame time the shutter is open
#define MOTION_BLUR_SAMPLES		9		// recommended range: 7..31

#define DEBUG_LIGHTMAP			0		// 1=packed (RGBA); 2=unpacked (greyscale)
#define DEBUG_ATLAS				0
#define DEBUG_TEXTURE			-1
#define DEBUG_CLICK_ZOOM		4.0		// zoom factor when clicking

// For key bindings/input settings, check out Buffer A

// For a more enjoyable experience, try my Shadertoy FPS mode script
// https://github.com/andrei-drexler/shadertoy-userscripts

// TODO (maybe) ////////////////////////////////////////////////

// - Improve texture quality
// - Clean-up & optimizations
// - Functional console
// - Gameplay & HUD polish

// Snapshots ///////////////////////////////////////////////////

// For a comparison with the initial release, check out
// https://www.shadertoy.com/view/MtVBzV

// For a comparison with the last version to use negative/capsule lights,
// ambient occlusion and temporal reprojection (for denoising), check out
// https://www.shadertoy.com/view/Ws2SR1

// Changelog ///////////////////////////////////////////////////

// 2021-01-06
// - Added support for +/- in Firefox (different keycodes...)
//
// 2020-11-15
// - Changed mouselook code to be compatible with recent Shadertoy update
//
// 2020-03-26
// - Slightly more Quake-like acceleration/friction
//
// 2020-03-21
// - Improved mouse movement handling for less common aspect ratios (e.g. portrait)
// - Switched to centered motion blur sampling (better near screen edges)
// - Moved scene quantization to Buffer D (before motion blur)
//
// 2020-03-20
// - Added workarounds for old ANGLE error (length can only be called on array names, not on array expressions)
//   https://github.com/google/angle/commit/bb2bbfbbf443fe0c1f8af12bacfdf1a945aea5a4#diff-b7bae477c1aea4edd01d4479fda69a87L5488
//
// 2019-09-03
// - Added window projection when light shafts are enabled
//
// 2019-09-01
// - Added basic/subtle CRT effect, with menu option (off by default)
//
// 2019-08-26
// - Added subtle light shaft animation (VOLUMETRIC_ANIM in Buffer D)
//
// 2019-08-24
// - Bumped default brightness up another notch
// - Fixed muzzle flash texture
//
// 2019-08-22
// - Added 'light shafts' menu option (off by default)
//
// 2019-08-21
// - Added volumetric lighting player shadow
// - Tweaked volumetric lighting falloff
//
// 2019-08-20
// - Added light shafts (RENDER_VOLUMETRICS 1 in Buffer D)
//
// 2019-07-02
// - Switched entity rotations to quaternions in order to reduce register
//   pressure => ~35% GPU usage @800x450, down from ~40% (both at 1974 MHz)
// - Bumped default brightness up a notch
// - Tweaked WINDOW02_1 texture
//
// 2019-06-30
// - Added texture filter menu option (shortcut: T)
//
// 2019-06-19
// - Tweaked console id logo background
// - Added motion blur menu option
//
// 2019-06-12
// - Tweaked QUAKE, WINDOW02_1 and WBRICK1_5 textures
// - Tweaked weapon model SDF, textures and movement anim range
// - Tweaked console background and text
// - Added back optional motion blur (USE_MOTION_BLUR 1 in Image tab)
// - Simplified naming scheme for Dave Hoskins' Hash without Sine functions
//
// 2019-06-07
// - Replaced FOV-based weapon model offset with pitch adjustment, eliminating
//   severe perspective distortion at higher vertical FOV's (e.g portrait mode)
// - Fixed console version string misalignment on aspect ratios other than 16:9
//
// 2019-06-06
// - Added FOV-based weapon model offset
// - Added BAKE_LIGHTMAP macro in Buffer B (for lower iteration times)
// - Tweaked weapon model SDF
// - Tweaked QUAKE texture
//
// 2019-06-04
// - Baked collision map planes to Buffer A, reducing its compilation time by ~6%
//   (~8.3 vs ~8.8 seconds) on my system
// - Baked font glyphs to Buffer C, reducing Image buffer compilation time by ~14%
//   (~3.7 vs ~4.3 seconds)
// - Removed unused UV visualisation code, reducing Buffer D compilation time by ~47%
//   (~1.0 vs ~1.9 seconds)
// - Optimized pow10 function used in number printing
//
// 2019-05-10
// - Fixed infinite loading screen on OpenGL (out vs inout)
//
// 2019-05-05
// - Freeze entity and texture animations when menu is open
//
// 2019-05-02
// - Added 'Show weapon' and 'Noclip' options
// - Tweaked WBRICK1_5 texture
//
// 2019-04-24
// - Switched to MBR's 2D Weyl hash for UI textures (for consistency across platforms)
// - More UI texture tweaks
//
// 2019-04-22
// - Tweaked engraved textures (QUAKE, Options title)
// - Added QUAKE/id image on the left side of the menu
// - Added 'Show lightmap' menu option
// - Removed left-over guard band code
//
// 2019-04-18
// - Tweaked brushwork for slightly better lightmap utilization
// - Changed lightmap dimensions to potentially accomodate another UI texture
//   in Buffer C even in 240x135 mode (smallest? Shadertoy thumbnail size)
// - Tweaked menu title texture
//
// 2019-04-17
// - Wired all options
// - Changed menu definition to array of structs (from array of ints), fixing menu
//   behavior on Surface 3 (codegen bug?)
// - Paused gameplay when menu is open
// - Changed default GAMMA_MODE (Image tab) to RGB (authentic)
//
// 2019-04-16
// - Added Options menu stub
//
// 2019-04-11
// - Added strafe key (Alt)
// - Added FPS display in demo mode
//
// 2019-04-10
// - Added macro-based RLE for runs of 0 in the lightmap tile array (-~270 chars)
// - Changed lightmap encoding and sample weighting
// - Changed lightmap padding to 0.5 texels (from 2), reduced number of dilation
//   passes to 1 (from 2) and disabled lightmap blur pass
// - Added zoom click for DEBUG_* modes (Image tab)
//
// 2019-04-09
// - More texture tweaks
// - Added LOD_SLOPE_SCALE option (Buffer D)
// - Reduced potentially lit surface set (4.3k smaller shader code)
// - Added basic compression for the lightmap tile array in Buffer A (-1k)
// - Changed default rendering scale to 1 (was 0.5)
//
// 2019-03-31
// - Changed GENERATE_TEXTURES macro (Buffer A) from on/off switch to bit mask,
//   enabling selective texture compilation (for faster iteration)
// - Tweaked WBRICK1_5 and WIZMET1_1 textures
//
// 2019-03-26
// - Tweaked CITY4_6, BRICKA2_2 and WINDOW02_1 textures
//
// 2019-03-24
// - Snapped console position to multiples of 2 pixels to avoid shimmering
//
// 2019-03-23
// - Robust thumbnail mode detection (based on iTime at iFrame 0)
// - Increased brightness, especially in thumbnail mode
// - Disabled weapon rendering for demo mode cameras 1 and 3 and tweaked their locations
//
// 2019-03-22
// - Fixed shadow discontinuities on the floor at the start of the skill hallways
// - Increased lightmap padding to 2 px
// - Optimized brushwork to reduce lightmapped area
// - Added 3 more viewpoints for the demo mode/thumbnail view
//
// 2019-03-20
// - Lightmap baking tweaks: 8xAA + 1 blur step, ignored solid samples,
//   extrapolation, better (but still hacky) handling of liquid brushes,
//   uv quantization, reduced baking time on low-end devices (e.g. Surface 3)
// - Added color quantization for console & composited scene
//
// 2019-03-18
// - Replaced AO+TSS combo with actual lightmaps. Saved old version as
//   https://www.shadertoy.com/view/Ws2SR1
//
// 2019-03-17
// - Octahedral encoding for gbuffer normals
//
// 2019-03-15
// - Major performance improvement for Intel iGPUs: 45+ fps
//   on a Surface 3 (Atom x7-Z8700), up from ~1.4 fps (window mode)
// - Added luminance gamma option (GAMMA_MODE in Image tab)
//
// 2019-03-07
// - Tighter encoding for axial brushes & atlas tiles
// - Added experimental TSS_FILTER (Buffer D), based on
//   https://www.shadertoy.com/view/lsG3D1 (by sebbbi)
//
// 2019-01-10
// - Added workaround for Shadertoy double-buffering bug on resize.
//   This fixes partially black textures when pausing the shader,
//   shrinking the window and then maximizing it again
//
// 2019-01-05
// - Reduced overall compilation time by ~30% on my system (~28.5s -> ~20s),
//   mostly from Buffer A optimizations (~14s -> ~6s) :>
//
// 2019-01-03
// - Minor map compiler tweaks: flat (degenerate) liquid brushes,
//   improved precision of certain operations
// - Added extra wall sliding friction
//
// 2018-12-21
// - Added Z/Q bindings for AZERTY users
//
// 2018-12-20
// - Added # of targets left to HUD
// - Added HUD line spacing, shadow box and color highlight effect
//
// 2018-12-16
// - Blue noise (instead of white) for the motion blur trail offset
//
// 2018-12-14
// - Disabled TSS/motion blur when teleporting
// - Minor motion blur tweaks
//
// 2018-12-10
// - Added experimental motion blur code (Buffer D),
//   mostly for video recording; off by default
//
// 2018-12-04
// - Slightly more compact map material assignment
// - Removed overly cautious fudge factor (-5%) from slide move code
//
// 2018-11-28
// - Disabled continuous texture generation (~11% perf boost)
//
// 2018-11-26
// - Changed USE_PARTITION macro (in Buffer B) to axial/non-axial bitmask
//
// 2018-11-25
// - Added BVL for axial brushes
// - Removed BVH code (USE_PARTITION 2), keeping just the BVLs
//
// 2018-11-24
// - Minor map brushwork optimization
// - Increased number of leaves in non-axial brush BVH from 7 to 10
// - Further reduced Buffer B compilation time by about 40%
//
// 2018-11-22
// - Reduced Buffer B compilation time (~10.8s vs ~12.6s) using Klems'
//   loop trick in normal estimation function
// - Added USE_ENTITY_AABB macro in Buffer B
//
// 2018-11-19
// - Resolution-dependent ray marching epsilon scale
//
// 2018-11-18
// - Tweaked loading screen sparks
// - Disabled weapon firing before console slide-out
// - Invalidated ground plane when noclipping
//
// 2018-11-14
// - More BVH/BVL tweaks: greedy split node selection instead of recursive,
//   leaf count limit instead of primitive count, sorted BVL elements
//   based on distance to world center
//
// 2018-11-13
// - Tweaked SAH builder to consider all axes, not just the largest one
//
// 2018-11-12
// - Added non-axial brush partition (USE_PARTITION in Buffer B)
//
// 2018-11-10
// - Fixed weapon model TSS ghosting
//
// 2018-11-09
// - Moved teleporter effect to Buffer C (lower resolution) and optimized
//   its hashing
// - Added lightning flash on game start
//
// 2018-11-08
// - Added fast path for axial brush rendering
//
// 2018-11-07
// - Added entity AABB optimization (and DEBUG_ENTITY_AABB option in Buffer B)
//
// 2018-11-06
// - Slightly optimized raymarching using bounding spheres
//   (~5% lower overall GPU usage at max frequency for 800x450 @144 fps)
//
// 2018-11-03
// - Started adding persistent state structs/macros to improve
//   code readability (e.g. game_state.level instead of fragColor.x);
//   see end of Common buffer
// - Reduced Buffer B compilation time (~6.9s vs ~7.5s on my system)
//
// 2018-11-02
// - Added credits
//
// 2018-10-29
// - Removed demo mode voronoi halftoning
// - Added two more balloon sets to provide some round-to-round variation
// - Tweaked round timing: can you make it to level 18?
//
// 2018-10-27
// - Added INVERT_MOUSE option (Buffer A)
// - Desaturated/darkened balloons during the game over transition
//
// 2018-10-26
// - Fixed bug that caused popped balloons to reappear during
//   the game over animation
// - Disabled balloon popping during game over animation
// - Added 'Game over' message
//
// 2018-10-25
// - Minor polish: blinking timer when almost out of time,
//   animated balloon scale-out when game is over
//
// 2018-10-24
// - Added level start countdown
// - Added game timer; game is over when time expires
// - Match particle color with balloon color, if a balloon was hit
//
// 2018-10-23
// - Added very basic target practice mode and reduced shotgun spread;
//   aim for the sky!
//
// 2018-10-17
// - Added automatic pitch adjustment when moving and not using the mouse
//   for looking around; see LOOKSPRING_DELAY in Buffer A
//
// 2018-10-16
// - Fixed occasional stair detection stutter at low FPS
//
// 2018-10-12
// - Optimized entity normal estimation: ~6.2 seconds to compile Buffer B,
//   down from ~8.6
//
// 2018-10-11
// - Sample weapon lighting at the ground level instead of a fixed distance
//   below the camera
// - Added sliding down slopes
//
// 2018-10-10
// - Fixed weapon model lighting seam when crossing a power-of-two boundary
// - Clamped lighting to prevent weapon model overdarkening from negative lights
// - Minor collision map brushwork tweak
//
// 2018-10-09
// - Optimized Buffer A compilation time a bit (~14.1 vs ~14.8 seconds on my system)
// - Fixed cloud tiling on Linux
//
// 2018-10-08
// - Added weapon firing on E/F (not Ctrl, to avoid closing the window on Ctrl+W)
// - Fixed TSS artifact when climbing stairs
//
// 2018-10-07
// - Tweaked ray-marching loop to eliminate silhouette sparkles
// - Tweaked weapon model colors (this time without f.lux...)
// - Disabled TSS for the weapon model
//
// 2018-10-06
// - Added shotgun model. Set RENDER_WEAPON to 0 in Buffer B to disable it
// - Minor brushwork optimizations
//
// 2018-10-04
// - Fixed brushwork that deviated from the original design in the playable area
// - Tightened up map definition some more (-13 lines)
//
// 2018-10-03
// - Added NOCLIP option (Buffer A)
//
// 2018-10-01
// - Faked two-sided lava/water surfaces
// - Added simple lava pain effect
//
// 2018-09-30
// - Tweaked player movement a bit (air control, smoother accel/decel, head bobbing)
// - Changed console typing animation :>
//
// 2018-09-29
// - Added basic collision detection; needs more work
//
// 2018-09-19
// - Reduced BufferC compilation time (~3s vs ~4.2s on my system)
//
// 2018-09-18
// - Added particle trail early-out (using screen-space bounds)
//
// 2018-09-17
// - Tightened up map definition even more (<100 lines now)
//
// 2018-09-15
// - Particle trail tweaks
//
// 2018-09-14
// - Made particles squares instead of disks (more authentic)
// - Added proper occlusion between particles
//
// 2018-09-11
// - Added fireball particle trail (unoptimized)
//
// 2018-09-10
// - Lighting tweaks
//
// 2018-09-08
// - Added option to reduce TSS when in motion (by 50% by default).
//   Seems counter-intuitive, but the end result is that the image
//   stays sharp in motion, and static shots are still denoised
// - Fixed temporal supersampling artifacts due to unclamped RGB input
// - Increased sky layer resolution (128x128, same as in Quake) and
//   adjusted atlas accordingly (mip 0 is 512x256 now, filled 100%)
// - Increased sky speed to roughly match Quake (super fast)
// - Added manual shadows for the spikes in the 'hard' area
//
// 2018-09-07
// - YCoCg for temporal supersampling (USE_YCOCG in the Common tab)
// - More map optimizations (~23% smaller now compared to first version)
//
// 2018-09-06
// - Added temporal supersampling (Buffer D), mostly to denoise AO
// - Disabled map rendering during loading screen
//
// 2018-09-05
// - Map optimizations: ~17% fewer brushes/planes, tweaked material
//   assignment, aligned some non-axial planes
// - Added basic FPS display (mostly for full-screen mode)
// - Added text scaling based on resolution
//
// 2018-09-03
// - Added depth/depth+angle mip-mapping (USE_MIPMAPS 2/3 in Buffer C)
// - Added mip level dithering (LOD_DITHER in Buffer C)
// - Even more compact map data storage (Buffer B)
// - Tweaked lava and water textures a bit
//
// 2018-08-30
// - Tweaked entity SDF's a bit
// - Slightly more compact map data formatting
//
// 2018-08-27
// - Added version number and id logo to console
// - More thumbnail time-shifting
//
// 2018-08-26
// - Rewrote font code
// - Added console loading/typing intro
//
// 2018-08-24
// - Added (static) console text
// - Added skill selection message triggers
//
// 2018-08-23
// - Added demo mode captions (with basic fixed-width font code).
//   Had to move some of the demo code, including the master switch,
//   to the Common tab.
//
// 2018-08-22
// - Enabled demo mode automatically for thumbnails and adjusted
//   thumbnail time again
//
// 2018-08-21
// - Added mouse filtering (Buffer A). Useful for video recording;
//   off by default
// - Added voronoi halftoning and DEMO_MODE_HALFTONE in Buffer C
//
// 2018-08-20
// - Use halftoning instead of blue noise dither for demo mode
//   transition (doesn't confuse video encoders as much)
//
// 2018-08-19
// - Reduced compilation time for Buffer B by almost 5 seconds
//   on my machine (~7.6 vs ~12.5)
//
// 2018-08-18
// - Generate lower-res atlas/mip chain when resolution is too low
//   to fit a full-res one (e.g. thumbnails, really small windows)
// - Show intro in thumbnail mode (by offsetting time by ~10s)
//

////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////
////////////////////////////////////////////////////////////////

#define SETTINGS_CHANNEL	iChannel0
#define PRESENT_CHANNEL		iChannel2
#define NOISE_CHANNEL		iChannel1
#define LIGHTMAP_CHANNEL	iChannel3

////////////////////////////////////////////////////////////////

float g_downscale = 2.;
float g_animTime = 0.;

vec4 load(vec2 address)
{
    return load(address, SETTINGS_CHANNEL);
}

// Font ////////////////////////////////////////////////////////

const int
    _A_= 1, _B_= 2, _C_= 3, _D_= 4, _E_= 5, _F_= 6, _G_= 7, _H_= 8, _I_= 9, _J_=10, _K_=11, _L_=12, _M_=13,
    _N_=14, _O_=15, _P_=16, _Q_=17, _R_=18, _S_=19, _T_=20, _U_=21, _V_=22, _W_=23, _X_=24, _Y_=25, _Z_=26,
    _0_=27, _1_=28, _2_=29, _3_=30, _4_=31, _5_=32, _6_=33, _7_=34, _8_=35, _9_=36,
    _SPACE_         =  0,
    _CARET_         = 45,
    _PLUS_          = 37,
    _MINUS_         = 38,
    _SLASH_         = 39,
    _DOT_           = 40,
    _COMMA_         = 41,
    _SEMI_          = 42,
    _EXCL_          = 43,
    _LPAREN_        = 46,
    _RPAREN_        = 47,
    _LBRACKET_      = 49,
    _RBRACKET_      = 50,
    _HOURGLASS_     = 53,
    _BALLOON_       = 54,
    _RIGHT_ARROW_   = 55
;

const ivec2 CHAR_SIZE						= ivec2(8);
int g_text_scale_shift						= 0;

ivec2 raw_text_uv(vec2 fragCoord)			{ return ivec2(floor(fragCoord)); }
ivec2 text_uv(vec2 fragCoord)				{ return ivec2(floor(fragCoord)) >> g_text_scale_shift; }
int text_width(int num_chars)				{ return num_chars << 3; }
int line_index(int pixels_y)				{ return pixels_y >> 3; }
int glyph_index(int pixels_x)				{ return pixels_x >> 3; }
int cluster_index(int pixels_x)				{ return pixels_x >> 5; }
int get_byte(int index, int packed)			{ return int((uint(packed) >> (index<<3)) & 255u); }

void init_text_scale()
{
	g_text_scale_shift = int(max(floor(log2(iResolution.x)-log2(799.)), 0.));
}

vec2 align(int num_chars, vec2 point, vec2 alignment)
{
    return point + alignment*-vec2(num_chars<<(3+g_text_scale_shift), 8<<g_text_scale_shift);
}

vec4 glyph_color(uint glyph, ivec2 pixel)
{
    uint x = glyph & 7u,
         y = glyph >> 3u;
    pixel = ivec2(ADDR2_RANGE_FONT.xy) + (ivec2(x, y) << 3) + (pixel & 7);
    return texelFetch(LIGHTMAP_CHANNEL, pixel, 0);
}

void print_glyph(inout vec4 fragColor, ivec2 pixel, int glyph, vec4 color)
{
    color *= glyph_color(uint(glyph), pixel);
    fragColor.rgb = mix(fragColor.rgb, color.rgb, color.a);
}

const int MAX_POW10_EXPONENT = 7;

uint pow10(uint e)
{
    uint result = (e & 1u) != 0u ? 10u : 1u;
    if ((e & 2u) != 0u) result *= 100u;
    if ((e & 4u) != 0u) result *= 10000u;
    return result;
}

int int_glyph(int number, int index)
{
    if (uint(index) >= uint(MAX_POW10_EXPONENT))
        return _SPACE_;
    if (number <= 0)
        return index == 0 ? _0_ : _SPACE_;
    uint power = pow10(uint(index));
    return uint(number) >= power ? _0_ + int((uint(number)/power) % 10u) : _SPACE_;
}

// Perf overlay ////////////////////////////////////////////////

vec3 fps_color(float fps)
{
    return
        fps >= 250. ? vec3(.75, .75,  1.) :
        fps >= 144. ? vec3( 1., .75,  1.) :
        fps >= 120. ? vec3( 1.,  1.,  1.) :
    	fps >= 60.  ? vec3( .5,  1.,  .5) :
    	fps >= 30.  ? vec3( 1.,  1.,  0.) :
    	              vec3( 1.,  0.,  0.);
}

float shadow_box(vec2 fragCoord, vec4 box, float border)
{
    vec2 clamped = clamp(fragCoord, box.xy, box.xy + box.zw);
    return clamp(1.25 - length(fragCoord-clamped)*(1./border), 0., 1.);
}

void draw_shadow_box(inout vec4 fragColor, vec2 fragCoord, vec4 box, float border)
{
    fragColor.rgb *= mix(1.-shadow_box(fragCoord, box, border), 1., .5);
}

const float DEFAULT_SHADOW_BOX_BORDER = 8.;

void draw_shadow_box(inout vec4 fragColor, vec2 fragCoord, vec4 box)
{
    draw_shadow_box(fragColor, fragCoord, box, DEFAULT_SHADOW_BOX_BORDER);
}

void draw_perf(inout vec4 fragColor, vec2 fragCoord)
{
    Options options;
    LOAD(options);

    if (uint(g_demo_stage - DEMO_STAGE_FPS) < 2u)
        options.flags |= OPTION_FLAG_SHOW_FPS;
    
    if (!test_flag(options.flags, OPTION_FLAG_SHOW_FPS|OPTION_FLAG_SHOW_FPS_GRAPH))
        return;

    float margin = 16. * min(iResolution.x * (1./400.), 1.);
    vec2 anchor = iResolution.xy  - margin;
    
    if (test_flag(options.flags, OPTION_FLAG_SHOW_FPS_GRAPH))
    {
        const vec2 SIZE = vec2(ADDR_RANGE_PERF_HISTORY.z, 32.);
        vec4 box = vec4(anchor - SIZE, SIZE);
        draw_shadow_box(fragColor, fragCoord, box);

        if (is_inside(fragCoord, box) > 0.)
        {
            vec2 address = ADDR_RANGE_PERF_HISTORY.xy + vec2(ADDR_RANGE_PERF_HISTORY.z-(fragCoord.x-box.x),0.);
            vec4 perf_sample = load(address);
            if (perf_sample.x > 0.)
            {
                float sample_fps = 1000.0/perf_sample.x;
                float fraction = sample_fps * (1./float(FPS_GRAPH_MAX));
                //fraction = 1./sqr(perf_sample.y/MIN_DOWNSCALE);
                if ((fragCoord.y-box.y) / box.w <= fraction)
                    fragColor.rgb = fps_color(sample_fps);
            }
            return;
        }
        
        anchor.y -= SIZE.y + DEFAULT_SHADOW_BOX_BORDER * 2.;
    }

    int fps = int(round(iFrameRate));
    if (test_flag(options.flags, OPTION_FLAG_SHOW_FPS) && uint(fps - 1) < 9999u)
    {
        const int FPS_TEXT_LENGTH = 8; // 1234 FPS
        const int FPS_SUFFIX_GLYPHS = (_SPACE_<<24) | (_F_<<16) | (_P_<<8) | (_S_<<0);
    
    	vec2 text_pos = anchor - vec2((CHAR_SIZE << g_text_scale_shift) * ivec2(FPS_TEXT_LENGTH,1));
    
        ivec2 uv = text_uv(fragCoord - text_pos);
        if (line_index(uv.y) == 0)
        {
            int glyph = FPS_TEXT_LENGTH - 1 - glyph_index(uv.x);
            if (uint(glyph) < 4u)
                glyph = get_byte(glyph, FPS_SUFFIX_GLYPHS);
            else if (uint(glyph) < uint(FPS_TEXT_LENGTH))
                glyph = int_glyph(fps, glyph-4);
            else
                glyph = _SPACE_;

			if (glyph != _SPACE_)
            {
                vec4 color = vec4(vec3(.875), 1.);
                print_glyph(fragColor, uv, glyph, color);
            }
        }
    }
}

// Console state ///////////////////////////////////////////////

struct Console
{
    float loaded;
    float expanded;
    float typing;
};
    
Console g_console;

void update_console()
{
    const float
        T0 = 0.,
    	T1 = T0 + CONSOLE_XFADE_DURATION,
    	T2 = T1 + CONSOLE_SLIDE_DURATION,
    	T3 = T2 + CONSOLE_TYPE_DURATION,
    	T4 = T3 + CONSOLE_SLIDE_DURATION;
    
    // snap console position to multiples of 2 pixels to avoid shimmering
    // due to the use of noise and dFd* functions
    float ysnap = iResolution.y * .5;
    
    g_console.loaded = linear_step(T0, T1, g_time);
    g_console.expanded = 1.+-.5*(linear_step(T1, T2, g_time) + linear_step(T3, T4, g_time));
    g_console.expanded = floor(g_console.expanded * ysnap + .5) / ysnap;
    g_console.typing = linear_step(0., CONSOLE_TYPE_DURATION, g_time - T2);
}

// Console text ////////////////////////////////////////////////

WRAP(GCONSOLE_TEXT,CONSOLE_TEXT,int,145)(33,0,9,16,16,28,28,29,29,60,60,60,80,98,117,133,151,179,179,203,203,204,204,230
,250,269,289,289,305,328,355,373,398,423,439,0xc030f0e,0xf001009,0xf0e320e,269028355,303304201,51708943,0xe0f0914,
302323238,0xe0f0913,455613440,85131297,302323218,522006016,2302498,788730371,50665477,462345,0xf141501,50665477,
0x7060328,50665477,462345,0x60e0f03,52954889,402982662,0xe090305,84148231,0xc150106,0x6032814,85460231,0x70e0903,
18157824,304612619,420416003,50926611,0xf0e000b,0xf060014,0x9040e15,85078030,0xf0a0401,0x9141319,2755331,301993742,
0xf101305,470094606,336921126,921364,320147213,369164293,17565953,637864962,0xe150f13,18022404,0x90c100d,301991694,
704975873,454827008,85336093,0xf091312,2031630,318767635,336724244,320147477,462345,68868,0xe010803,787726,353309470,
0x900040e,0x914090e,436800513,0xf091401,403968526,336530944,335873024,85197573,1970948,0xf030e09,302977042,67441665,
303300648,522260233,18023702,455613696,0xd0f0300,17370128,16782350,336593156,472519173,2369566,17237261,85203202,
17106944,85460240,488308778,707010602,318775067,503320581,605814811,85139748,0xc010912,0x9120400,1180950,336137737,
0x90c0109,0x904051a,0xe001810,67113999,50664453,263444));

vec2 closest_point_on_segment(vec2 p, vec2 a, vec2 b)
{
    vec2 ab = b-a;
    vec2 ap = p-a;
    float t = clamp(dot(ap, ab)/dot(ab, ab), 0., 1.);
    return ab*t + a;
}

vec2 lit_line(vec2 uv, vec2 a, vec2 b, float thickness)
{
    const vec2 LIGHT_DIR = vec2(0, 1);
    uv -= closest_point_on_segment(uv, a, b);
    float len = length(uv);
    return vec2(len > 0. ? dot(uv/len, LIGHT_DIR) : 1., len + -.5*thickness);
}

void print_console_version(inout vec4 fragColor, vec2 uv, vec2 mins, vec2 size)
{
    size.y *= .25;
    mins.y -= size.y * 1.75;
    
    if (is_inside(uv, vec4(mins, size)) < 0.)
        return;
    uv -= mins;
    uv *= 1./size;
    
    ivec2 iuv = ivec2(vec2(CHAR_SIZE) * vec2(4, 1) * uv);
    
    int glyph = glyph_index(iuv.x);
    if (uint(glyph) >= 4u)
        return;
    
    const int GLYPHS = (_1_) | (_DOT_<<8) | (_0_<<16) | (_6_<<24);
    const vec4 color = vec4(.62, .30, .19, 1);
    
    fragColor.rgb *= .625;
    glyph = get_byte(glyph, GLYPHS);
    print_glyph(fragColor, iuv, glyph, color);
}

void print_console_text(inout vec4 fragColor, vec2 fragCoord)
{
    float MARGIN = 12. * iResolution.x/800.;
    const vec4 COLORS[2] = vec4[2](vec4(vec3(.54), 1), vec4(.62, .30, .19, 1));
    const uint COLORED = (1u<<3) | (1u<<7);
    const int TYPING_LINE = 1;
    
    fragCoord.y -= iResolution.y * (1. - g_console.expanded);
    ivec2 uv = text_uv(fragCoord - MARGIN);
    bool typing = g_console.typing < 1.;
    int cut = int(mix(float(CONSOLE_TEXT.data[0]-1), 2., g_console.loaded));
    if (g_console.typing > 0.)
        --cut;
    
    int line = line_index(uv.y);
    if (uint(line) >= uint(CONSOLE_TEXT.data[0]-cut))
        return;
    line += cut;
    int start = CONSOLE_TEXT.data[1+line];
    int num_chars = CONSOLE_TEXT.data[2+line] - start;
    
    if (num_chars == 1)
    {
        const vec3 LINE_COLOR = vec3(.17, .13, .06);
        float LINE_END = min(iResolution.x - MARGIN*2., 300.);
        vec2 line = lit_line(vec2(uv.x, uv.y & 7) + .5, vec2(4. ,4.), vec2(LINE_END-4., 4.), 4.);
        line.x = mix(1. + .5 * line.x, 1., linear_step(-.5, -1.5, line.y));
        line.x *= 1. + -.25*random(vec2(uv));
		fragColor.rgb = mix(fragColor.rgb, LINE_COLOR * line.x, step(line.y, 0.));
        return;
    }
    
    int glyph = glyph_index(uv.x);
    if (line == TYPING_LINE)
    {
        float type_fraction = clamp(2. - abs(g_console.typing * 4. + -2.), 0., 1.);
        num_chars = clamp(int(float(num_chars-1)*type_fraction) + int(typing), 0, num_chars + int(typing));
    }
    if (uint(glyph) >= uint(num_chars))
        return;

    if (typing && line == TYPING_LINE && glyph == num_chars - 1)
    {
        glyph = fract(iTime*2.) < .5 ? _CARET_ : _SPACE_;
    }
    else
    {
        glyph += start;
        glyph = get_byte(glyph & 3, CONSOLE_TEXT.data[CONSOLE_TEXT.data[0] + 2 + (glyph>>2)]);
    }
    
    uint is_colored = line < 32 ? ((COLORED >> line) & 1u) : 0u;
    vec4 color = COLORS[is_colored];
    print_glyph(fragColor, uv, glyph, color);
}

// Menu ////////////////////////////////////////////////////////

WRAP(GOPTIONS,OPTIONS,int,53)(13,0,11,23,33,44,58,72,86,97,109,119,132,143,149,320147213,269680645,0x9040505,302323214,0xf0d0014
,33886997,0x8070912,319098388,302191379,918789,85592339,386861075,17958400,17958157,0x8130514,0x600170f,0x7001310,0x8100112,
337118484,332309,336333062,0xf0d1205,0xe0f0914,353108480,0x7090c12,318772232,335937800,336724755,0x6060500,320078597,1511176,
0x807090c,268504340,386861075,17110784,0xe0e0f10,0x90c030f,16));

void draw_menu(inout vec4 fragColor, vec2 fragCoord, Timing timing)
{
    MenuState menu;
    LOAD(menu);

    if (menu.open <= 0)
        return;

    vec4 options = load(ADDR_OPTIONS);

    if (!test_flag(int(options[get_option_field(OPTION_DEF_SHOW_LIGHTMAP)]), OPTION_FLAG_SHOW_LIGHTMAP))
    {
        // vanilla
        fragColor.rgb *= vec3(.57, .47, .23);
        fragColor.rgb = ceil(fragColor.rgb * 24. + .01) / 24.;
    }
    else
    {
        // GLQuake
       	fragColor.rgb *= .2;
    }

    //g_text_scale_shift = 1;
    int text_scale = 1 << g_text_scale_shift;
    float image_scale = float(text_scale);
    vec2 header_size = ADDR2_RANGE_TEX_OPTIONS.zw * image_scale;
    vec2 left_image_size = ADDR2_RANGE_TEX_QUAKE.wz * image_scale;
    float left_image_offset = 120. * image_scale;

    vec2 ref = iResolution.xy * vec2(.5, 1.);
    ref.y -= min(float(CHAR_SIZE.y) * 4. * image_scale, iResolution.y / 16.);

    ref.x += left_image_size.x * .5;
    if (fragCoord.x < ref.x - left_image_offset)
    {
        fragCoord.y -= ref.y - left_image_size.y;
        fragCoord.x -= ref.x - left_image_offset - left_image_size.x;
        ivec2 addr = ivec2(floor(fragCoord)) >> g_text_scale_shift;
        if (uint(addr.x) < uint(ADDR2_RANGE_TEX_QUAKE.w) && uint(addr.y) < uint(ADDR2_RANGE_TEX_QUAKE.z))
	        fragColor.rgb = texelFetch(LIGHTMAP_CHANNEL, addr.yx + ivec2(ADDR2_RANGE_TEX_QUAKE.xy), 0).rgb;
        return;
    }

    ref.y -= header_size.y;
    if (fragCoord.y >= ref.y)
    {
        fragCoord.y -= ref.y;
        fragCoord.x -= ref.x - header_size.x * .5;
        ivec2 addr = ivec2(floor(fragCoord)) >> g_text_scale_shift;
        if (uint(addr.x) < uint(ADDR2_RANGE_TEX_OPTIONS.z) && uint(addr.y) < uint(ADDR2_RANGE_TEX_OPTIONS.w))
	        fragColor.rgb = texelFetch(LIGHTMAP_CHANNEL, addr + ivec2(ADDR2_RANGE_TEX_OPTIONS.xy), 0).rgb;
        return;
    }

    ref.y -= float(CHAR_SIZE.y) * 1. * image_scale;

    const int
        BASE_OFFSET		= CHAR_SIZE.x * 0,
        ARROW_OFFSET	= CHAR_SIZE.x,
        VALUE_OFFSET	= CHAR_SIZE.x * 3,
        MARGIN			= 0,
        LINE_HEIGHT		= MARGIN + CHAR_SIZE.y;

    ivec2 uv = text_uv(fragCoord - ref);
    uv.x -= BASE_OFFSET;
    int line = -uv.y / LINE_HEIGHT;
    if (uint(line) >= uint(NUM_OPTIONS))
        return;
    
    uv.y = uv.y + (line + 1) * LINE_HEIGHT;
    if (uint(uv.y - MARGIN) >= uint(CHAR_SIZE.y))
        return;
    uv.y -= MARGIN;
    
    int glyph = 0;
    if (uv.x < 0)
    {
        int begin = OPTIONS.data[1 + line];
        int end = OPTIONS.data[2 + line];
        int num_chars = end - begin;
        uv.x += num_chars * CHAR_SIZE.x;
    	glyph = glyph_index(uv.x);
        if (uint(glyph) >= uint(num_chars))
            return;
        glyph += begin;
        glyph = get_byte(glyph & 3, OPTIONS.data[OPTIONS.data[0] + 2 + (glyph>>2)]);
    }
    else if (uint(uv.x - ARROW_OFFSET) < uint(CHAR_SIZE.x))
    {
        const float BLINK_SPEED = 2.;
        uv.x -= ARROW_OFFSET;
        if (menu.selected == line && (fract(iTime * BLINK_SPEED) < .5 || test_flag(timing.flags, TIMING_FLAG_PAUSED)))
            glyph = _RIGHT_ARROW_;
    }
    else if (uv.x >= VALUE_OFFSET)
    {
        uv.x -= VALUE_OFFSET;

        int item_height = CHAR_SIZE.y << g_text_scale_shift;

        MenuOption option = get_option(line);
        int option_type = get_option_type(option);
        int option_field = get_option_field(option);
        if (option_type == OPTION_TYPE_SLIDER)
        {
            const float RAIL_HEIGHT = 7.;
            vec2 p = vec2(uv.x, uv.y & 7) + .5;
            vec2 line = lit_line(p, vec2(8, 4), vec2(8 + 11*CHAR_SIZE.x, 4), RAIL_HEIGHT);
            float alpha = linear_step(-.5, .5, -line.y);
            line.y /= RAIL_HEIGHT;
            float intensity = 1. + line.x * step(-.25, line.y);
            intensity = mix(intensity, 1. - line.x * .5, line.y < -.375);
            fragColor.rgb = mix(fragColor.rgb, vec3(.25, .23, .19) * intensity, alpha);

            float value = options[option_field] * .1;
            float thumb_pos = 8. + value * float(CHAR_SIZE.x * 10);
            p.x -= thumb_pos;
            p -= vec2(4);
            float r = length(p);
            alpha = linear_step(.5, -.5, r - 4.);
            intensity = normalize(p).y * .25 + .75;
            p *= vec2(3., 1.5);
            r = length(p);
            intensity += linear_step(.5, -.5, r - 4.) * (safe_normalize(p).y * .125 + .875);

            fragColor.rgb = mix(fragColor.rgb, vec3(.36, .25, .16) * intensity, alpha);
            return;
        }
        else if (option_type == OPTION_TYPE_TOGGLE)
        {
            glyph = glyph_index(uv.x);
            if (uint(glyph) >= 4u)
                return;
    		const int
                OFF = (_O_<<8) | (_F_<<16) | (_F_<<24),
    			ON  = (_O_<<8) | (_N_<<16);
            int value = test_flag(int(options[option_field]), get_option_range(option)) ? ON : OFF;
            glyph = get_byte(glyph & 3, value);
        }
    }
    else
    {
        return;
    }
    
    vec4 color = vec4(.66, .36, .25, 1);
    print_glyph(fragColor, uv, glyph, color);
}

// Loading screen/console //////////////////////////////////////

vec3 loading_spinner(vec2 fragCoord)
{
    float radius = max(32./1920. * iResolution.x, 8.);
    float margin = max(96./1920. * iResolution.x, 12.);
    vec2 center = iResolution.xy - vec2(margin + radius);
    float angle = atan(fragCoord.y-center.y, fragCoord.x-center.x) / (PI*2.);
    float dist = length(fragCoord - center)/radius;
    angle += smoothen(fract(iTime*SQRT2));
    angle = fract(-angle);

    const float MAX_ANGLE = .98;
    const float MIN_ANGLE = .12;
    float angle_alpha = angle < MAX_ANGLE ? max((angle-MIN_ANGLE)/(MAX_ANGLE-MIN_ANGLE), 0.) :
    	1.-(angle-MAX_ANGLE)/(1.-MAX_ANGLE);
    float radius_alpha = around(.85, mix(.09, .1, angle_alpha), dist);

    vec3 color = sqr(1.-clamp(dist*.375, 0., 1.)) * vec3(.25,.125,0.);
    color += sqrt(radius_alpha) * angle_alpha;
    
    return color;
}

vec3 burn_xfade(vec3 from, vec3 to, float noise_mask, float fraction)
{
    const float HEADROOM = .7;
    fraction = mix(-HEADROOM, 1.+HEADROOM, fraction);
    float burn_mask = linear_step(fraction-HEADROOM, fraction, noise_mask);
    from *= burn_mask;
    to = mix(from, to, linear_step(fraction, fraction-HEADROOM, noise_mask));
    
    const bool GARISH_FLAMES = false;
    if (GARISH_FLAMES)
    {
        to *= 1. - around(.5, .49, burn_mask);
        to += vec3(1.,.3,.2) * around(.80, .19, burn_mask);
        to += vec3(1.,.5,.3) * around(.84, .15, burn_mask) * .25;
        to += vec3(1.,1.,.4) * around(.94, .05, burn_mask);
    }

    return to;
}

float sdf_apply_light(float sdf, vec2 dir)
{
    vec2 grad = normalize(vec2(dFdx(sdf), dFdy(sdf)));
    return dot(dir, grad);
}

float sdf_shadow(float sdf, float size, vec2 light_dir)
{
    vec2 n = sdf_normal(sdf);
    float thresh = size * max(abs(dFdx(sdf)), abs(dFdy(sdf)));
    float mask = clamp(sdf/thresh, 0., 1.);
    return clamp(1. - sdf/size, 0., 1.) * clamp(-dot(light_dir, n), 0., 1.) * mask;
}

float sdf_modern_nail(vec2 uv, vec2 top, vec2 size)
{
    const float head_flat_frac = .025;
    const float head_round_frac = .05;
    const float body_thickness = .5;

    float h = clamp((top.y - uv.y) / size.y, 0., 1.);
    float w = (h < head_flat_frac) ? 1. :
        (h < head_flat_frac + head_round_frac) ? mix( body_thickness, 1., sqr(1.-(h-head_flat_frac)/head_round_frac)) :
    	h > .6 ? ((1.05 - h) / (1.05 - .6)) * body_thickness : body_thickness;
    return sdf_centered_box(uv, top - vec2(0., size.y*.5), size*vec2(w, .5));
}

float sdf_modern_Q(vec2 uv, float age)
{
    float aspect_ratio = iResolution.x/iResolution.y;
    float noise = turb(uv * vec2(31.7,27.9)/aspect_ratio, .7, 1.83);
    float dist = sdf_disk(uv, vec2(.5, .68), .315);
    dist = sdf_exclude(dist, sdf_disk(uv, vec2(.5, .727), .267));
    dist = sdf_exclude(dist, sdf_disk(uv, vec2(.5, 1.1), .21));
    dist = sdf_union(dist, sdf_modern_nail(uv, vec2(.5, .59), vec2(.08, .52)));
    return dist + (noise * .01 - .005) * sqr(age);
}

vec2 embossed_modern_Q(vec2 uv, float age, float bevel, vec2 light_dir)
{
    float px = 2./iResolution.y, EPS = .1 * px;
    vec3 sdf;
    for (int i=0; i<3; ++i)
    {
        vec2 uv2 = uv;
        if (i != 2)
            uv2[i] += EPS;
        sdf[i] = sdf_modern_Q(uv2, age);
    }
    vec2 gradient = normalize(sdf.xy - sdf.z);
    float mask = sdf_mask(sdf.z, px);
    bevel = clamp(1. + sdf.z/bevel, 0., 1.);
    return vec2(mask * (.5 + sqrt(bevel) * dot(gradient, light_dir)), mask);
}

void print_console_logo(inout vec4 fragColor, vec2 uv, vec2 mins, vec2 size, float noise)
{
    float inside = is_inside(uv, vec4(mins, size));
    float fade = noise * -.01;
    if (inside < fade)
        return;
    vec3 background = mix(vec3(.09, .05, 0), vec3(.38, .17, .11), sqr(smoothen(noise)));
    fragColor.rgb = mix(fragColor.rgb, background, sqr(linear_step(fade, .001, inside)));
    const float QUANTIZE = 32.;
    uv = (uv - mins) / size;
    uv = round(uv * QUANTIZE) * (1./QUANTIZE);
    float logo = (sdf_id(uv) + noise*.015) * QUANTIZE;
    float mask = clamp(2.-logo, 0., 1.) * linear_step(1., .25, noise);
    fragColor.rgb = mix(fragColor.rgb, vec3(0), mask * .5);
    mask = clamp(1.-logo, 0., 1.) * linear_step(1., .25, noise);
    fragColor.rgb = mix(fragColor.rgb, vec3(.43, .22, .14), mask);
}

float sparks(vec2 uv, vec2 size)
{
    vec2 cell = floor(uv) + .5;
    vec2 variation = hash2(cell);
    cell += (variation-.5) * .9;
    return sqr(variation.x) * clamp(1.-length((cell - uv)*(1./size)), 0., 1.);
}

void draw_console(inout vec4 fragColor, vec2 fragCoord, Lighting lighting)
{
    fragColor.rgb *= linear_step(1., .5, g_console.expanded);

   	vec2 uv = fragCoord.xy / iResolution.xy;
	if (uv.y < 1. - g_console.expanded)
        return;
    
    float loaded = lighting.progress;
    float xfade = clamp(g_time / CONSOLE_XFADE_DURATION, 0., 1.);
    
    uv.y -= 1. - g_console.expanded;
    float vignette = 1. - clamp(length(uv - .5)*2., 0., 1.);
  
    float aspect_ratio = iResolution.x/iResolution.y;
    uv.x = (uv.x - 0.5) * aspect_ratio + 0.5;

    float base = turb(uv * vec2(31.7,27.9)/aspect_ratio, .7, 2.5);
    
    // loading screen (modern style) //
    
    vec3 modern = vec3(linear_step(.45, .7, base) * 0.1);
    if (xfade < 1.)
    {
        modern *= sqr(vignette);

        const float MODERN_LOGO_SCALE = .75;

        vec2 logo_uv = (uv - .5) * (1./MODERN_LOGO_SCALE) + .5;
        vec4 modern_logo = embossed_modern_Q(logo_uv, loaded, .006, vec2(.7, .3)).xxxy;

        float flame_flicker = mix(.875, 1., smooth_noise(2.+iTime*7.3));
        float scratches = linear_step(.35, .6, turb(vec2(480.,8.)*rotate(uv, 22.5), .5, 2.) * base);
        scratches += linear_step(.25, .9, turb(vec2(480.,16.)*rotate(uv, -22.5), .5, 2.) * base);

        modern_logo.rgb *= vec3(.32,.24,.24);
        modern_logo.rgb *= smoothstep(.75, .0, abs(uv.x-.5));
        modern_logo.rgb *= 1.8 - 0.8 * linear_step(.55, mix(.15, .35, loaded), base);
        modern_logo.rgb *= 1. - scratches * .4;
        modern_logo.rgb *= 1. + 4. * sqr(clamp(1. - length(uv - vec2(.76, .37))*2.3, 0., 1.));
        modern_logo.rgb *= 1. + flame_flicker*2.5*vec3(1.,0.,0.) * sqr(clamp(1. - length(uv - vec2(.20, .40))*3., 0., 1.));

        modern = mix(modern, modern_logo.rgb, modern_logo.a);

        float flame_vignette = length((uv - vec2(.5,0.))*vec2(.5, 1.3));
        float flame_intensity = flame_vignette;
        flame_intensity = sqr(sqr(clamp(1.-flame_intensity, 0., 1.)) * flame_flicker);
        flame_intensity *=
            turb(uv * vec2(41.3,13.6)/aspect_ratio + vec2(0.,-iTime), .5, 2.5) +
            turb(uv * vec2(11.3,7.6)/aspect_ratio + vec2(0.,-iTime*.9), .5, 2.5);
        modern += vec3(.25,.125,0.) * flame_intensity;

        vec2 spark_uv = vec2(uv + vec2(turb(uv*1.3, .5, 2.)*.6, -iTime*.53));
        float spark_intensity =
            sparks(vec2(11.51, 3.13) * spark_uv,				vec2(.06,.05)) * 2. +
            sparks(vec2(4.19, 1.37) * spark_uv + vec2(1.3,3.7),	vec2(.06,.05)) * 1.;
        spark_intensity *= flame_intensity;

        spark_uv = vec2(uv*.73 + vec2(turb(uv*1.25, .7, 1.9)*.4, -iTime*.31));
        float spark_intensity2 = turb(vec2(25.1, 11.5) * spark_uv, .5, 2.);
        spark_intensity2 = 0.*linear_step(.43, .95, spark_intensity2) * flame_intensity*.2;
        modern += vec3(1.,1.,.3) * (spark_intensity + spark_intensity2);

        modern += loading_spinner(fragCoord);
    }
    
    // console (classic style) //

    const float CLASSIC_LOGO_SCALE = 1.1;
    const vec2 CLASSIC_LOGO_CENTER = vec2(.5, .45);
    const vec2 CLASSIC_LIGHT_DIR = vec2(0, 1.5);
    float classic_shadow_size = mix(.01, .05, base);
    vec2 CLASSIC_SHADOW_OFFSET = CLASSIC_LIGHT_DIR * classic_shadow_size;
    float classic_logo_distortion = base * .015 - .01;
    float classic_logo = sdf_Q((uv-CLASSIC_LOGO_CENTER) / CLASSIC_LOGO_SCALE + .5) + classic_logo_distortion;
    
    vec2 aspect = vec2(iResolution.x / iResolution.y, 1.);
    vec2 box_size = vec2(.5) * aspect - mix(.005, .03, sqr(base));
    float classic_console_box = sdf_centered_box(uv, vec2(.5), box_size);
    
    const vec2 CLASSIC_ID_LOGO_MARGIN = vec2(24./450., 48./450.);
    const float CLASSIC_ID_LOGO_SIZE = 64./450.;
    const float CLASSIC_ID_LOGO_BOX_JAGGEDNESS = 0.; //0.02;
    
    vec2 logo_mins = vec2((.5+.5*aspect.x)-CLASSIC_ID_LOGO_MARGIN.x-CLASSIC_ID_LOGO_SIZE, CLASSIC_ID_LOGO_MARGIN.y);
    
    classic_console_box = sdf_exclude(classic_console_box,
                                      4.*sdf_box(uv, logo_mins, logo_mins + CLASSIC_ID_LOGO_SIZE) +
                                      (base*2.-1.) * CLASSIC_ID_LOGO_BOX_JAGGEDNESS);
   
    float noise2 = turb(uv*43.7, .5, 2.0)-.15;
    classic_console_box = sdf_exclude(classic_console_box, noise2*.1);
    
    float bevel_size = mix(.001, .07, sqr(base));
    float classic_sdf = sdf_exclude(classic_console_box, classic_logo+.01);
    float classic_base = sdf_emboss(classic_sdf, bevel_size, CLASSIC_LIGHT_DIR).x;

#if 1
    // slightly odd, gradient-based automatic shadow
    float classic_shadow = sdf_shadow(classic_sdf, classic_shadow_size, CLASSIC_LIGHT_DIR);
#else
    // smooth version with secondary SDF sample
    // only sampling the Q logo SDF, not the composite one!
    float classic_shadow_sample = sdf_Q((uv+CLASSIC_SHADOW_OFFSET-CLASSIC_LOGO_CENTER) / CLASSIC_LOGO_SCALE + .5) + classic_logo_distortion;
    float classic_shadow = sdf_mask(classic_logo) * clamp(classic_shadow_sample/classic_shadow_size+.3, 0., 1.);
#endif

    vec4 classic = vec4(mix(vec3(.07,.03,.02)*(1.+base*2.)*(1.-classic_shadow), vec3(.24,.12,.06), classic_base), 1.);
    classic.rgb *= 1. - .05*linear_step(.35, .3, base);
    classic.rgb *= 1. + .05*linear_step(.6, .65, base);
    
    print_console_logo(classic, uv, logo_mins, vec2(CLASSIC_ID_LOGO_SIZE), base);
	print_console_version(classic, uv, logo_mins, vec2(CLASSIC_ID_LOGO_SIZE));
    print_console_text(classic, fragCoord);
    
    classic.rgb = floor(classic.rgb * 64. + random(floor(uv*128.))) * (1./64.);

	float burn_fraction = xfade * (2.-clamp(length(uv-vec2(.5,0.)), 0., 1.));
    fragColor.rgb = burn_xfade(modern, classic.rgb, base, burn_fraction);
}

// Skill selection message /////////////////////////////////////

WRAP(GSKILL_MESSAGES,SKILL_MESSAGES,int,27)(3,0,28,58,86,319358996,0xc010800,85131276,335742220,17104915,318773523,
0xc0c090b,319358996,0xc010800,85131276,335742220,0xf0e0013,0xc010d12,0x90b1300,0x8140c0c,0x8001309,789505,84673811,
1250307,68288776,0x90b1300,3084));

void print_skill_message(inout vec4 fragColor, in vec2 fragCoord, vec3 cam_pos)
{
#if PRINT_SKILL_MESSAGE
    float time = fract(iTime*.5);
    if (time > .9375)
        return;

    MenuState menu;
    LOAD_PREV(menu);
    if (menu.open > 0)
        return;
    
    ivec2 uv = text_uv(fragCoord - iResolution.xy*vec2(.5,.64));
    if (line_index(uv.y) != 0)
        return;
    
	vec4 cam_angles = load(ADDR_CAM_ANGLES);
    if (min(cam_angles.x, 360.-cam_angles.x) >= 90.)
        return;

    const vec3 PLAYER_DIMS = vec3(16., 16., 48.);
    const vec3 SKILL_TRIGGER_BOUNDS[] = vec3[](
        vec3(112,832,-32),vec3(336,1216,16),
        vec3(448,832,-8),vec3(656,1232,40),
        vec3(752,800,-24),vec3(976,1248,24)
	);
    
    int line = -1;
    int num_skills = NO_UNROLL(3);
    for (int i=0; i<num_skills; ++i)
    {
        int i2 = i + i;
        vec3 mins = SKILL_TRIGGER_BOUNDS[i2];
        vec3 maxs = SKILL_TRIGGER_BOUNDS[i2+1];
        vec3 delta = clamp(cam_pos.xyz, mins, maxs) - cam_pos.xyz;
        if (max_component(abs(delta) - PLAYER_DIMS) <= 0.)
            line = i;
    }
    
    if (line == -1)
        return;

    int start = SKILL_MESSAGES.data[1+line];
    int num_chars = SKILL_MESSAGES.data[2+line] - start;
    uv.x += text_width(num_chars) >> 1;
    
    int glyph = glyph_index(uv.x);
    if (uint(glyph) >= uint(num_chars))
        return;
    
    glyph += start;
    glyph = get_byte(glyph & 3, SKILL_MESSAGES.data[SKILL_MESSAGES.data[0] + 2 + (glyph>>2)]);

    vec4 color = vec4(vec3(.6), 1);
    print_glyph(fragColor, uv, glyph, color);
#endif // PRINT_SKILL_MESSAGE
}

// Level start countdown ///////////////////////////////////////

WRAP(GGAME_OVER,GAME_OVER,int,4)(9,84738311,85331712,18));

bool print_countdown(inout vec4 fragColor, vec2 fragCoord)
{
    GameState game_state;
    MenuState menu;
    LOAD(game_state);
    LOAD(menu);
    if (game_state.level <= 0. && game_state.level == floor(game_state.level) || menu.open > 0)
        return false;
    
    float remaining = fract(abs(game_state.level)) * 10.;
    if (remaining <= 0. || remaining >= BALLOON_SCALEIN_TIME + LEVEL_COUNTDOWN_TIME)
        return true;
    
    ivec2 uv = text_uv(fragCoord - iResolution.xy*vec2(.5,.66)) >> 1;
    if (line_index(uv.y) != 0)
        return true;
    
    bool go = remaining < BALLOON_SCALEIN_TIME;
    
    int num_chars = (game_state.level < 0.) ? GAME_OVER.data[0] : go ? 4 : 1;
    
    uv.x += (num_chars * CHAR_SIZE.x) >> 1;

    int glyph = glyph_index(uv.x);
    if (uint(glyph) >= uint(num_chars))
        return true;
    
    const int GO_MESSAGE = (_SPACE_<<0) | (_G_<<8) | (_O_<<16) | (_SPACE_<<24);
    
    if (game_state.level < 0.)
    	glyph = get_byte(glyph & 3, GAME_OVER.data[1 + (glyph>>2)]);
    else if (go)
        glyph = (GO_MESSAGE >> (glyph<<3)) & 255;
    else
    	glyph = _0_ + int(ceil(remaining - BALLOON_SCALEIN_TIME));
    
    vec4 color = vec4(vec3(.875), 1.);
    if (fract(remaining - BALLOON_SCALEIN_TIME) > .875)
        color.rgb = vec3(.60, .30, .23);
    print_glyph(fragColor, uv, glyph, color);
    
    return true;
}

// Pain blend, skill message ///////////////////////////////////

void add_effects(inout vec4 fragColor, vec2 fragCoord, bool is_thumbnail)
{
    if (is_demo_mode_enabled(is_thumbnail))
        return;

    vec4 cam_pos = load(ADDR_CAM_POS);
    vec3 fireball = get_fireball_offset(g_animTime) + FIREBALL_ORIGIN;
    float pain = linear_step(80., 16., length(cam_pos.xyz - fireball));
    vec3 lava_delta = abs(cam_pos.xyz - clamp(cam_pos.xyz, LAVA_BOUNDS[0], LAVA_BOUNDS[1]));
    float lava_dist = max3(lava_delta.x, lava_delta.y, lava_delta.z);
    if (lava_dist <= 32.)
        pain = mix(.5, .75, clamp(fract(g_animTime*4.)*2.+-1., 0., 1.));
    if (lava_dist <= 0.)
        pain += .45;
   	fragColor.rgb = mix(fragColor.rgb, vec3(1., .125, .0), sqr(clamp(pain, 0., 1.)) * .75);
    
    if (!print_countdown(fragColor, fragCoord))
    	print_skill_message(fragColor, fragCoord, cam_pos.xyz);
}

// Demo stage descriptions /////////////////////////////////////

WRAP(GDEMO_STAGES,DEMO_STAGES,int,24)(6,0,12,19,29,37,45,64,1638674,336791812,84086273,0xd120f0e,353569793,17638934,
0xe091010,402985991,85071124,0x7090c13,0xe091408,402985991,85071124,2424851,0x807090c,0x70e0914));

void describe_demo_stage(inout vec4 fragColor, vec2 fragCoord)
{
    int line = -1;
    switch (g_demo_stage)
    {
        case DEMO_STAGE_DEPTH:		line = 0; break;
        case DEMO_STAGE_NORMALS:	line = 1; break; 
        case DEMO_STAGE_UV:			line = 2; break; 
        case DEMO_STAGE_TEXTURES:	line = 3; break;
        case DEMO_STAGE_LIGHTING:	line = 4; break;
        case DEMO_STAGE_COMPOSITE:	line = 5; break;
        default:					return;
    }

    int start = DEMO_STAGES.data[1+line];
    int num_chars = DEMO_STAGES.data[2+line] - start;

    vec2 margin = iResolution.xy * 16./450.;
    vec2 ref = vec2(iResolution.x - margin.x, margin.y);
    vec2 pos = align(num_chars, ref, vec2(1, 0));

    vec4 box = vec4(pos, (ivec2(num_chars, 1) * CHAR_SIZE) << g_text_scale_shift);
    float radius = 16. * exp2(float(g_text_scale_shift));
    box += radius * (.25 * vec4(1, 1, -2, -2));
    float intensity = (g_demo_stage == DEMO_STAGE_LIGHTING) ? .5 : .625;
    fragColor.rgb *= mix(1., intensity, sqr(shadow_box(fragCoord, box, radius)));

    ivec2 uv = text_uv(fragCoord - pos);
    if (line_index(uv.y) != 0)
        return;
    int glyph = glyph_index(uv.x);
    if (uint(glyph) >= uint(num_chars))
        return;

    glyph += start;
    glyph = get_byte(glyph & 3, DEMO_STAGES.data[DEMO_STAGES.data[0] + 2 + (glyph>>2)]);

    vec4 color = vec4(1);
    print_glyph(fragColor, uv, glyph, color);
}

////////////////////////////////////////////////////////////////

WRAP(GGAME_HUD_STATS,GAME_HUD_STATS,int,12)(3,0,9,18,27,85329164,12,302060544,320079111,581<<18,1293,0));

void draw_game_info(inout vec4 fragColor, vec2 fragCoord)
{
    GameState game_state;
    LOAD(game_state);
    if (game_state.level == 0.)
        return;

    const int NUM_LINES = GAME_HUD_STATS.data[0];
    const int PREFIX_LENGTH = GAME_HUD_STATS.data[2] - GAME_HUD_STATS.data[1];
    const int NUM_DIGITS = 4;
    const int LINE_LENGTH = PREFIX_LENGTH + NUM_DIGITS;
    
    const float MARGIN = 16.;
    vec2 anchor = vec2(MARGIN, iResolution.y - MARGIN - float((CHAR_SIZE*NUM_LINES) << g_text_scale_shift));
    
    ivec2 uv = text_uv(fragCoord - anchor);
    int line = NUM_LINES - 1 - line_index(uv.y);
    
    // ignore last 2 lines (time/targets left) if game is over
    int actual_num_lines = NUM_LINES - (int(game_state.level < 0.) << 1);
    
    vec4 box = vec4(MARGIN, iResolution.y-MARGIN, ivec2(LINE_LENGTH, (actual_num_lines<<1)-1)<<g_text_scale_shift);
    box.zw *= vec2(CHAR_SIZE);
    box.y -= box.w;
    draw_shadow_box(fragColor, fragCoord, box);
    
    // line spacing
    if ((line & 1) != 0)
        return;
    line >>= 1;
    
    if (uint(line) >= uint(actual_num_lines))
        return;
       
    int start = GAME_HUD_STATS.data[1+line];
    int num_chars = GAME_HUD_STATS.data[2+line] - start;
    int glyph = glyph_index(uv.x);
    if (uint(glyph) < uint(num_chars))
    {
        glyph += start;
        glyph = get_byte(glyph & 3, GAME_HUD_STATS.data[GAME_HUD_STATS.data[0] + 2 + (glyph>>2)]);
    }
    else
    {
        glyph -= num_chars;
        if (uint(glyph) >= uint(NUM_DIGITS))
            return;
        
        int stat;
        switch (line)
        {
            case 0: stat = int(abs(game_state.level)); break;
            case 1: stat = int(game_state.targets_left); break;
            case 2: stat = int(game_state.time_left); break;
            default: stat = 0; break;
        }
		glyph = NUM_DIGITS - 1 - glyph;
        glyph = int_glyph(stat, glyph);
    }

    const vec3 HIGHLIGHT_COLOR = vec3(.60, .30, .23);
    vec4 color = vec4(vec3(.75), 1.);
    if ((line == 0 && fract(game_state.level) > 0.) ||
        (line == 1 && fract(game_state.targets_left) > 0.))
    {
		color.rgb = HIGHLIGHT_COLOR;
    }
    else if (line == 2 && game_state.time_left < 10.)
    {
        float blink_rate = game_state.time_left < 5. ? 2. : 1.;
        if (fract(game_state.time_left * blink_rate) > .75)
            color.rgb = HIGHLIGHT_COLOR;
    }

    print_glyph(fragColor, uv, glyph, color);
}

////////////////////////////////////////////////////////////////

void apply_motion_blur(inout vec4 fragColor, vec2 fragCoord, vec4 camera_pos)
{
#if !USE_MOTION_BLUR
    return;
#endif

    // not right after teleporting
    float teleport_time = camera_pos.w;
    if (teleport_time > 0. && abs(iTime - teleport_time) < 1e-4)
        return;
    
    vec3 camera_angles = load(ADDR_CAM_ANGLES).xyz;
    vec3 prev_camera_pos = load(ADDR_PREV_CAM_POS).xyz;
    vec3 prev_camera_angles = load(ADDR_PREV_CAM_ANGLES).xyz;
    mat3 view_matrix = rotation(camera_angles.xyz);
    mat3 prev_view_matrix = rotation(prev_camera_angles.xyz);

    vec4 ndc_scale_bias = get_viewport_transform(iFrame, iResolution.xy, g_downscale);
    ndc_scale_bias.xy /= iResolution.xy;
    vec2 actual_res = ceil(iResolution.xy / g_downscale);
    vec4 coord_bounds = vec4(vec2(.5), actual_res - .5);

    vec3 dir = view_matrix * unproject(fragCoord * ndc_scale_bias.xy + ndc_scale_bias.zw);
    vec3 surface_point = camera_pos.xyz + dir * VIEW_DISTANCE * fragColor.w;
    dir = surface_point - prev_camera_pos;
    dir = dir * prev_view_matrix;
    vec2 prev_coord = project(dir).xy;
    prev_coord = (prev_coord - ndc_scale_bias.zw) / ndc_scale_bias.xy;
    float motion = length(prev_coord - fragCoord);

    if (fragColor.w <= 0. || motion * g_downscale < 4.)
        return;
    
    // Simulating a virtual shutter to avoid excessive blurring at lower FPS
    const float MOTION_BLUR_SHUTTER = MOTION_BLUR_AMOUNT / float(MOTION_BLUR_FPS);
    float shutter_fraction = clamp(MOTION_BLUR_SHUTTER/iTimeDelta, 0., 1.);

    vec2 rcp_resolution = 1./iResolution.xy;
    vec4 uv_bounds = coord_bounds * rcp_resolution.xyxy;
    vec2 trail_start = fragCoord * rcp_resolution;
    vec2 trail_end = prev_coord * rcp_resolution;
    trail_end = mix(trail_start, trail_end, shutter_fraction * linear_step(4., 16., motion * g_downscale));

    float mip_level = log2(motion / (float(MOTION_BLUR_SAMPLES) + 1.)) - 1.;
    mip_level = clamp(mip_level, 0., 2.);

    const float INC = 1./float(MOTION_BLUR_SAMPLES);
    float trail_offset = BLUE_NOISE(fragCoord).x * INC - .5;
    float trail_weight = 1.;
    for (float f=0.; f<float(MOTION_BLUR_SAMPLES); ++f)
    {
        vec2 sample_uv = mix(trail_start, trail_end, trail_offset + f * INC);
        if (is_inside(sample_uv, uv_bounds) < 0.)
            continue;
        vec4 s = textureLod(iChannel2, sample_uv, mip_level);
        // Hack: to avoid weapon model ghosting we'll ignore samples landing in that area.
        // This introduces another artifact (sharper area behind the weapon model), but
        // this one is harder to notice in motion...
        float weight = step(0., s.w);
        fragColor.rgb += s.xyz * weight;
        trail_weight += weight;
    }
    
    fragColor.rgb /= trail_weight;
}

void present_scene(out vec4 fragColor, vec2 fragCoord, Options options)
{
    fragCoord /= g_downscale;
    vec2 actual_res = ceil(iResolution.xy / g_downscale);

    // cover up our viewmodel lighting hack
    bool is_ground_sample = is_inside(fragCoord, iResolution.xy - 1.) > 0.;
    if (is_ground_sample)
        fragCoord.x--;

    vec4 camera_pos = load(ADDR_CAM_POS);
    vec3 lava_delta = abs(camera_pos.xyz - clamp(camera_pos.xyz, LAVA_BOUNDS[0], LAVA_BOUNDS[1]));
    float lava_dist = max3(lava_delta.x, lava_delta.y, lava_delta.z);
    if (lava_dist <= 0.) 
    {
        fragCoord += sin(iTime + 32. * (fragCoord/actual_res).yx) * actual_res * (1./192.);
        fragCoord = clamp(fragCoord, vec2(.5), actual_res - .5);
    }

    fragColor = texelFetch(PRESENT_CHANNEL, ivec2(fragCoord), 0);
    
    if (test_flag(options.flags, OPTION_FLAG_MOTION_BLUR))
    	apply_motion_blur(fragColor, fragCoord, camera_pos);

    fragColor.rgb = linear_to_gamma(fragColor.rgb);
}

////////////////////////////////////////////////////////////////

void color_correction(inout vec4 fragColor, vec2 fragCoord, bool is_thumbnail)
{
    if (g_demo_stage != DEMO_STAGE_NORMALS)
    {
        Options options;
        LOAD(options);
    	
        float gamma = is_thumbnail ? .8 : 1. - options.brightness * .05;
#if GAMMA_MODE
    	fragColor.rgb = gamma_to_linear(fragColor.rgb);
    	float luma = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    	if (luma > 0.)
	    	fragColor.rgb *= pow(luma, gamma) / luma;
	    fragColor.rgb = linear_to_gamma(fragColor.rgb);
#else
	    fragColor.rgb = pow(fragColor.rgb, vec3(gamma));
#endif
    }
    
    // dithering, for smooth depth/lighting visualisation (when not quantized!)
    fragColor.rgb += (BLUE_NOISE(fragCoord).rgb - .5) * (1./127.5);
}

////////////////////////////////////////////////////////////////

bool draw_debug(out vec4 fragColor, vec2 fragCoord)
{
    if (iMouse.z > 0.)
        fragCoord = (fragCoord - iMouse.xy) / DEBUG_CLICK_ZOOM + iMouse.xy;
    ivec2 addr = ivec2(fragCoord);

#if defined(DEBUG_TEXTURE) && (DEBUG_TEXTURE >= 0) && (DEBUG_TEXTURE < NUM_MATERIALS)
    vec4 atlas_info = load(ADDR_ATLAS_INFO);
    float atlas_lod = atlas_info.y;
    float atlas_scale = exp2(-atlas_lod);
    vec4 tile = get_tile(DEBUG_TEXTURE);
    vec2 uv = fragCoord / min_component(iResolution.xy/tile.zw) + tile.xy;
    fragColor = is_inside(uv, tile) < 0. ? vec4(0) :
    	texelFetch(SETTINGS_CHANNEL, ivec2(ATLAS_OFFSET + uv * atlas_scale), 0);
    return true;
#endif

#if DEBUG_ATLAS
    fragColor = texelFetch(SETTINGS_CHANNEL, addr, 0);
    return true;
#endif

#if DEBUG_LIGHTMAP >= 2
    int channel = addr.x & 3;
    addr.x >>= 2;
    if (uint(addr.y) < LIGHTMAP_SIZE.x && uint(addr.x) < LIGHTMAP_SIZE.y/4u)
    {
        LightmapSample s = decode_lightmap_sample(texelFetch(LIGHTMAP_CHANNEL, addr.yx, 0));
        float l = s.values[channel], w = s.weights[channel];
#if DEBUG_LIGHTMAP >= 3
    	fragColor = vec4(w <= 0. ? vec3(1,0,0) : l == 0. ? vec3(0,0,1) : vec3(l), 1);
#else
        fragColor = vec4(vec3(clamp(l, 0., 1.)), 1);
#endif
    }
    else
    {
        fragColor = vec4(0,0,0,1);
    }
    return true;
#elif DEBUG_LIGHTMAP
    vec4 texel = texelFetch(LIGHTMAP_CHANNEL, addr, 0);
    fragColor =
        uint(addr.x) < LIGHTMAP_SIZE.x && uint(addr.y) < LIGHTMAP_SIZE.y/4u ?
        	decode_lightmap_sample(texel).values :
    		texel;
    return true;
#endif

    return false;
}

////////////////////////////////////////////////////////////////

void crt_effect(inout vec4 fragColor, vec2 fragCoord, Options options)
{
#if USE_CRT_EFFECT
	if (!test_flag(options.flags, OPTION_FLAG_CRT_EFFECT))
        return;
    
    vec2 uv = fragCoord / iResolution.xy, offset = uv - .5;
    fragColor.rgb *= 1. + sin(fragCoord.y * (TAU/4.)) * (CRT_SCANLINE_WEIGHT);
    fragColor.rgb *= clamp(1.6 - sqrt(length(offset)), 0., 1.);
    
    const float
        MASK_LO = 1. - (CRT_MASK_WEIGHT) / 3.,
        MASK_HI = 1. + (CRT_MASK_WEIGHT) / 3.;

    vec3 mask = vec3(MASK_LO);
    float i = fract((floor(fragCoord.y) * 3. + fragCoord.x) * (1./6.));
    if (i < 1./3.)		mask.r = MASK_HI;
    else if (i < 2./3.)	mask.g = MASK_HI;
    else				mask.b = MASK_HI;

	fragColor.rgb *= mask;
#endif // USE_CRT_EFFECT
}

////////////////////////////////////////////////////////////////

void mainImage( out vec4 fragColor, vec2 fragCoord )
{
    if (draw_debug(fragColor, fragCoord))
        return;
    
    Options options;
    LOAD(options);
    
    g_downscale = get_downscale(options);
    bool is_thumbnail = test_flag(int(load(ADDR_RESOLUTION).z), RESOLUTION_FLAG_THUMBNAIL);
    
    Lighting lighting;
    LOAD(lighting);

    UPDATE_TIME(lighting);
    UPDATE_DEMO_STAGE_EX(fragCoord/g_downscale, g_downscale, is_thumbnail);
    init_text_scale();
    update_console();

    Timing timing;
    LOAD(timing);
    g_animTime = timing.anim;

    present_scene		(fragColor, fragCoord, options);
    add_effects			(fragColor, fragCoord, is_thumbnail);
    describe_demo_stage	(fragColor, fragCoord);
    draw_game_info		(fragColor, fragCoord);
    draw_perf			(fragColor, fragCoord);
    draw_menu			(fragColor, fragCoord, timing);
    draw_console		(fragColor, fragCoord, lighting);
    color_correction	(fragColor, fragCoord, is_thumbnail);
    crt_effect			(fragColor, fragCoord, options);
}
