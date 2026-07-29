// Image (image) — A Flimsy Rocket Paperplane... by msm01
// https://www.shadertoy.com/view/dlfXzl

// FUN FACT : If you put a few specks of antimatter in a clervely-designed
// container at the back of a paperplane, you can propel it at high speed
// through a moderately dense atmosphere ! The game was first invented on
// Mars at the end of the 21st century. It requires small-scale force-fields
// though...

// WARNING : Rocket paperplanes are highly unstable at hypersonic regime, due
// to the force-field being extra-slippery, but not "perfectly" so...
// SO DO NOT GO OVER THE SPEED LIMIT !

// WARNING : Antimatter is expensive, and can be tricky to handle. WEAR
// GLOVES, GLASSES AND USE EXTREME CAUTION AT ALL TIMES !

// FUN FACT : To obtain small, recreational quantities of antimatter, contact
// the nearest particle accelerator and pretend it's for educational purpose.
// Usually works better in May, when managers are drowning in administrative
// paperwork !

// Also, Happy New Year to you all !

// Use this code as you wish, just try to give proper credit when so.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

// Music is "Stingray" by Malmen, thanks A LOT for sharing your music !
// https://soundcloud.com/malmen/malmen-stingray
// https://creativecommons.org/licenses/by-nc-sa/3.0/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     vec2 p = fragCoord.xy/iResolution.xy;
     
     vec4 col = vec4(1.0,1.0,1.0,1.0);
     float chromab = length(p-vec2(0.5,0.5));
     col.r = texture(iChannel0,p + vec2( 0.004*chromab)).x;
     col.g = texture(iChannel0,p + vec2( 0.000*chromab)).y;
     col.b = texture(iChannel0,p + vec2(-0.004*chromab)).z;
     
     // This (badly) fakes the old dot matrix screens...
     // Like an old flipper.
     if( mod(TimeVar,MusicTimeBase)>MusicTimeBase/2.0 &&
         mod(fragCoord.y,4.0) > 2.0                   &&
         mod(fragCoord.x,4.0) > 2.0                       )
     {
         col *= vec4(0.7,0.7,0.7,1.0);
     };

     // POP POP THE CHAMPAGNE !
     fragColor = col;
}