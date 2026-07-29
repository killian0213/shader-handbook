// Image (image) — Evo32 SMNCA - Slackermanz by SlackermanzCA
// https://www.shadertoy.com/view/tlGBW1

//	----    ----    ----    ----    ----    ----    ----    ----
//	NAME:Evo32 Selective MNCA
//	TYPE:Selective Multiple Neighbourhood Cellular Automata
//	RULE:Pattern coordinates hardcoded into 'demo' array
//	----    ----    ----    ----    ----    ----    ----    ----
//	Specification: SlackCA_Specification_2021_02_23:
//		https://mega.nz/file/yRliVDJT#6CUlcGma4DpfXI4S8j0VoUi8Vju0vwRXwVI4klyiNXg
//	Adapted for Shadertoy. FPS compared to the C++/Vulkan application is about 20% of maximum
//
//	Text file containing other pattern coordinates:
//		https://mega.nz/file/uY0GjSjJ#-TvjklejZBh3O5DfqtLXFtjZaoVetqHPgotdYLH5xoQ
//	Visualisation of a small subset of rules recorded by Softology:
//		https://www.youtube.com/watch?v=LtdKNso0DwE
//
//	----    ----    ----    ----    ----    ----    ----    ----
//  Shader developed by Slackermanz
//
//  Info/Code:
//  ﻿ - Website: https://slackermanz.com
//  ﻿ - Github: https://github.com/Slackermanz
//  ﻿ - Shadertoy: https://www.shadertoy.com/user/SlackermanzCA
//  ﻿ - Discord: https://discord.gg/hqRzg74kKT
//  
//  Socials:
//  ﻿ - Discord DM: Slackermanz#3405
//  ﻿ - Reddit DM: https://old.reddit.com/user/slackermanz
//  ﻿ - Twitter: https://twitter.com/slackermanz
//  ﻿ - YouTube: https://www.youtube.com/c/slackermanz
//  ﻿ - Older YT: https://www.youtube.com/channel/UCZD4RoffXIDoEARW5aGkEbg
//  ﻿ - TikTok: https://www.tiktok.com/@slackermanz
//  
//  Communities:
//  ﻿ - Reddit: https://old.reddit.com/r/cellular_automata
//  ﻿ - Artificial Life: https://discord.gg/7qvBBVca7u
//  ﻿ - Emergence: https://discord.com/invite/J3phjtD
//  ﻿ - ConwayLifeLounge: https://discord.gg/BCuYCEn
//	----    ----    ----    ----    ----    ----    ----    ----

precision highp int;
precision highp float;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    vec4 bufA = texture(iChannel0, uv);

    // Output to screen
    fragColor = bufA;
}