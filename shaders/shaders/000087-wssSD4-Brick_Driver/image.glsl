// Image (image) — Brick Driver by spolsh
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


// Fork of "[SH16B] Speed Drive 80" by knarkowicz. https://shadertoy.com/view/4ldGz4
// 2019-02-24 00:16:15

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 screenUV = fragCoord.xy / iResolution.xy;
    
    // chromatic abberation
    float caStrength	= 0.002;
    vec2 caOffset 		= screenUV - 0.5;
	vec2 caUVG			= screenUV + caOffset * caStrength;
	vec2 caUVB			= screenUV + caOffset * caStrength * 2.0;

    vec3 color;
    color.x = texture( iChannel0, screenUV ).x;
    color.y = texture( iChannel0, caUVG ).y;
    color.z = texture( iChannel0, caUVB ).z;    
    
    fragColor = vec4( color, 1.0 );
}