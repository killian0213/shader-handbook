// Common (common) — The Evil Gorgon Of Tindalos by msm01
// https://www.shadertoy.com/view/XcdBDS

#define PI 3.14159

float TimeVar;
float TiltX;
float AltiY;
bool FIRE_JAWS = false;
bool FIRE_SEAL = false;
bool FIRE_SYNC = false;
bool FIRE_PHAS = false;
bool MAGN_FAIL = false;
bool PINB_MODE = false;

// Main Shaft - Hyperspectral Mode - B=9.71T(MAX) - P=0.000100mB
int Data01[61]    = int[] ( 77, 97, 105, 110, 32, 83, 104, 97, 102, 116, 32, 45, 32, 72, 121, 112, 101, 114, 115, 112, 101, 99, 116, 114, 97, 108, 32, 77, 111, 100, 101, 32, 45, 32, 66, 61, 57, 46, 55, 49, 84, 40, 77, 65, 88, 41, 32, 45, 32, 80, 61, 48, 46, 48, 48, 48, 49, 48, 48, 109, 66 );
// CERN Antiproton Decelerator - Advanced Penning Trap
int Data02[51]    = int[] ( 67, 69, 82, 78, 32, 65, 110, 116, 105, 112, 114, 111, 116, 111, 110, 32, 68, 101, 99, 101, 108, 101, 114, 97, 116, 111, 114, 32, 45, 32, 65, 100, 118, 97, 110, 99, 101, 100, 32, 80, 101, 110, 110, 105, 110, 103, 32, 84, 114, 97, 112 );
// 31/10/2024 23:59
int Data03[16]    = int[] ( 51, 49, 47, 49, 48, 47, 50, 48, 50, 52, 32, 50, 51, 58, 53, 57 );
// GAMMA RAY ALERT !
int Alert01[17] = int[] ( 71, 65, 77, 77, 65, 32, 82, 65, 89, 32, 65, 76, 69, 82, 84, 32, 33 );
// MAG FIELD FAILURE !
int Alert02[19] = int[] ( 77, 65, 71, 32, 70, 73, 69, 76, 68, 32, 70, 65, 73, 76, 85, 82, 69, 32, 33 );
// EMERGENCY SUPERCONTINUUM SEAL BLAST
int Alert03[35] = int[] ( 69, 77, 69, 82, 71, 69, 78, 67, 89, 32, 83, 85, 80, 69, 82, 67, 79, 78, 84, 73, 78, 85, 85, 77, 32, 83, 69, 65, 76, 32, 66, 76, 65, 83, 84 );
// The magical seal text actually says : "FOR ONLY 20 EUROS A MONTH THIS CAN STOP - SUBSCRIBE TO OUR SERVICE - LOVE, CERN MAGICAL SECURE TEAM - "
// with a ROT-63 to use greek letters instead of roman ones, hence maximum spookiness and obscurity ! :D
int SealTxt[102] = int[] ( 70, 79, 82, 32, 79, 78, 76, 89, 32, 50, 48, 32, 69, 85, 82, 79, 83, 32, 65, 32, 77, 79, 78, 84, 72, 32, 84, 72, 73, 83, 32, 67, 65, 78, 32, 83, 84, 79, 80, 32, 45, 32, 83, 85, 66, 83, 67, 82, 73, 66, 69, 32, 84, 79, 32, 79, 85, 82, 32, 83, 69, 82, 86, 73, 67, 69, 32, 45, 32, 76, 79, 86, 69, 44, 32, 67, 69, 82, 78, 32, 77, 65, 71, 73, 67, 65, 76, 32, 83, 69, 67, 85, 82, 69, 32, 84, 69, 65, 77, 32, 45, 32);

// The Usual Tools ;)
mat2 r2d(float a){float c=cos(a), s=sin(a); return mat2(c,s,-s,c);}
float noise(vec2 st){return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);}
float TriangleWave(float p){ return abs(mod(p,2.0) - 1.0 );}

// This is actually not fbm at all, just smoothed single-octave 1D noise.
float fbm(in vec2 v_p)
{
      float pvpx = 2.0*v_p.x;
      vec2 V1 = vec2(0.5*floor(pvpx      ));
      vec2 V2 = vec2(0.5*floor(pvpx + 1.0));
      return mix(noise(V1),noise(V2),smoothstep(0.0,1.0,fract(pvpx)));
}

// This belongs to Iq...
float sdStar5(in vec2 p, in float r, in float rf)
{
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x,k1.y);
    p.x = abs(p.x);
    p -= 2.0*max(dot(k1,p),0.0)*k1;
    p -= 2.0*max(dot(k2,p),0.0)*k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf*vec2(-k1.y,k1.x) - vec2(0,1);
    float h = clamp( dot(p,ba)/dot(ba,ba), 0.0, r );
    return length(p-ba*h) * sign(p.y*ba.x-p.x*ba.y);
}

// Still searching for the unknown Shadertoyer that wrote this :
float metaDiamond(vec2 p, vec2 pixel, float r)
{
      vec2 d = abs(p-pixel);
      return 1.0*r / (d.x + d.y);
}

// ------------------> 1st Scifi Story :

// /////////////////////////////////////////////////////////////////////////////
// Status : ULTRASECRET
// /////////////////////////////////////////////////////////////////////////////
// Title : ACCIDENTAL TINDALOS GORGON CAPTURE IN LHC'S ADVANCED PENNING TRAP.
// /////////////////////////////////////////////////////////////////////////////
// Date : 31/10/2024
// /////////////////////////////////////////////////////////////////////////////
// Author : Agent 147, at CERN-LHC
// /////////////////////////////////////////////////////////////////////////////
// Report : Antimatter mass-production and storage is now routine at the LHC. So
// the setup of the new Advanced Penning Trap at the Antiproton Decelerator Ring
// should have been a matter of hours. A day at most.
// During the first activation though, we noticed very abnormal readings in both
// magnetic and electric fields, as well as some loud, disturbing sounds coming
// from the main shaft of the new device. Using the inner multispectral imager,
// we quickly discovered that a kind of creature had been caught in the middle
// section (i.e. where the antiprotons should nominally come at rest).
// I immediately assumed authority, locked down the facility, secured the area
// under protocol 59, and requested support. Within less than two hours we had
// total control over the site.
// For the last week, we've been investigating the physical nature and origin of
// said "creature" which at the moment is still confined within the main chamber
// of the trap.
// In this paper, we describe and discuss the properties of this organism which
// seems alive in every sense of the word, and also extremely agitated. Its very
// existence defies many well-established laws of Nature, such as gravity (it is
// floating in near vacuum !) or thermodynamics (it generates incredible amounts
// of light, heat and radiations for such a limited size).
// We don't know much yet, but the first results presented here show that it is
// composed entirely of small micrometric magnetic domains rotating, somehow, at
// relativistic speeds (!). Those fields are weaved in complicated patterns (see
// ANNEXE 2). Stranger : the creature seems able to "phase out" of our sight for
// a few milliseconds at a time. We first thought it was basic optical stealth,
// although now we understand that it's a deeper process, possibly a topological
// transform, one of those "space-metric hacks" we've already seen in few other
// cases. Its metabolism, or energy source, is genuinely phenomenal. We have
// estimated its daily output, and the numbers are quite frightening (ANNEXE 4),
// typically in the multi-megawatt range. Probably more. This has put serious
// strain on the cryostats of the trap's superconducting coils, but the initial
// security margins were extended using spare modular cooling units as required.
// We still have no idea what keeps it inside the Penning Trap. We suppose it is
// somehow related to the peculiar, extremely advanced magnetic field modulation
// in this new model, creating a puzzling omnidirectional threadmill cell with a
// lot of echo. B strength is currently at 9.7 Teslas (9.7T). We had to increase
// it substantially from the nominal value (5T) since this lifeform can generate
// its own, intricate field with sharp, sudden peaks in the 5 to 8T range... The
// creature exhibits very aggressive behaviour, can generate force-field jaws on
// -the-fly at short range and a crude but relatively efficient beam of reddish
// synchrotron light ! We suppose this beam is extremely powerful but for some
// reason, its interactions with the metal enclosure have been limited. It could
// change, though. And even so, at the current rate of abrasion (which is NOT
// insignificant) we estimate that the metal will fail in about 30 days. So we
// still have a few weeks to find a new place for our little radioactive friend.
// Though its size, within the trap, stays around 30-50 centimeters, it seems to
// be able to scale up pretty fast. It already has, in fact, tested this attack
// several times in the last few days in order to burst out of its cage! The 9.7
// Teslas field has kept it confined... So far.
// In conclusion, we mention multiple options to store the thing inside a larger
// and more sturdy container. We also demand to resume normal activities at the
// Antiproton Decelerator ASAP, before drawing too much attention. Finally, we
// require additional funds and human resources to deal with the emotional and
// psychological damage. This creature currently creates high-levels of stress
// and despair in a radius of 10 meters even after being sound-proofed ! Impacts
// of the beam on the metal were causing all sorts of sinister noises, and it
// got to the point where some of us reported ghastly auditory hallucinations...
// Our main engineer had to endure horrendous, crushing visions repeatedly when
// making necessary upgrades or modifications to the setup. His cerebral stroke,
// three days ago, has left our team in shock and severely worried. We must keep
// up with the investigations, but we also have a duty to elaborate new methods
// to protect us from the foul influence of such lifeforms. This creature is an
// opportunity, but also a serious danger. If we can't control it, then we need
// to know HOW TO KILL IT. The supercontinuum electrolaser seal has proved, in
// this specific matter, to be an effective (albeit temporary) countermeasure.
// I must admit I was sceptical when Agent 145 deployed the steering coils and
// the axicons, but I stand corrected. He's still totally unable to explain HOW
// and WHY it works, though. Further research is therefore needed.
//
// P.S. The Spengler Beam, for God's sake ! I've been asking for the schematics
// FOR YEARS ! You know I won't back up this time, Roger. We have a true Class-5
// Full-Roaming Vapor (C5-FRV) in our grasp for the first time, so I want the
// beam NOW, or I QUIT !
//
// /////////////////////////////////////////////////////////////////////////////


// ------------------> 2nd "Bonus" Scifi Story :

// Same universe, a bit later :

// Room full of higher politicians and military officers. A scientist is giving
// a lecture :
// "This is a Tindalos Gorgon, distant relative of the Hound, and direct cousin
// of the Langoliers that we documented more than 30 years ago. It can move in
// any direction of space, access the most difficult places. Luckily, it's very
// stupid, a rabid animal, really. But the A.T. field it generates is off-the-
// charts ! We believe these are merely drones from a bigger, vastly more
// intelligent entity, and that this dread they produce around them is, in fact,
// a local, scaled-down projection of this greater, malevolent mind.
// —So... a kind of spooky wifi ? Remote-control based on pure, abject terror ?
// —...and rage. But yes, that is essentially correct. ... Well, that's what we
// have infered from the LHC incident, Sir.
// —Any idea what bigger entity we're dealing with, here ?
// A cold, uneasy silence falls onto the room. Everybody remembers the horrific
// Nyarlathotep meltdown of 2013. Global extinction event avoided at the very
// last second by an unknown hero that had to seal the unholy Gates of Yog with
// his own blood. Protocols were in place, now, sure, but we weren't much more
// advanced than back then, on a strictly technical level.
// —We have... clues. Nothing certain. But the energy signature is very unusual.
// And it's slowly rising.
// —What do you mean ?
// —The consensus within our group is... *he hesitates, lets out a deep sigh,
// wipes sweaty, trembling hands on his shirt, then in a breath :
// "We think it's coming for us !"