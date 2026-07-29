// Buffer A (buffer) — Brick Driver by spolsh
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



// Brick Game Racer in shader by Michal Klos

// control loop
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    if (fragCoord.x >= 3. || fragCoord.y >= 1.) 
    {
        discard;    
    }

    AppState s;
    LoadState(iChannel0, s); 
	
	// read keys that people usually press instead of space    
    float key = 0.0;
    for (int i = 0; i < keys.length(); ++i)
        key = max( key, step( 0.1, texture( iChannel1, vec2( keys[i] / 256.0, 0.5 ) ).x ) );

	s.isSpacePressed = key;
    
    if (s.stateID == GS_SPLASH) // splash
    {        
        if (s.isSpacePressed > 0.5)
        {
            s.stateID = GS_GAME;
			s.isFailed = 0.0;
            s.timeFailed = 0.0;
			s.timeAccumulated = 0.0;
            s.score = 0.0;
			s.paceScale = 0.0;
            s.timeStarted = iTime;
        }
    }
    else if (s.stateID == GS_GAME) // game
    {       
        if (s.isFailed < 0.5)
        {
            if (s.isSpacePressed > 0.5)
                s.isLeftLine = mod(s.isLeftLine + 1.0, 2.0);
        
            // game logic
            s.paceScale = clamp((s.playerCell - 10.0) / 100.0, 0.0, 1.0);
            float timeMultiplier = mix(1.0, 3.0, pow(s.paceScale, 1.0) );
            
            float timeStep = timeMultiplier * iTimeDelta;
            s.timeAccumulated += timeStep;
            s.playerCell = floor( 2.0 * s.timeAccumulated );
            
#ifdef AI
            {
				float playerCellState = GetCellState(s.playerCell + 1.0, s.seed);
                if (playerCellState < CS_EMPTY_LANE
                    && s.isLeftLine == playerCellState)
                {
                    s.isLeftLine = mod(s.isLeftLine + 1.0, 2.0);
                }
            }
#endif
            
            float playerCellState = GetCellState(s.playerCell, s.seed);

            if (playerCellState < CS_EMPTY_LANE
                && s.isLeftLine == playerCellState)
            {
                s.isFailed = 1.0;
                s.timeFailed = iTime;
				s.stateID = GS_SPLASH;
            }
            else
            {
                s.score = s.playerCell - CELLS_HEADSTART;
                s.highscore = max(s.score, s.highscore);
            }
    	}
    }
  
    fragColor = SaveState(s, fragCoord, iFrame);
}