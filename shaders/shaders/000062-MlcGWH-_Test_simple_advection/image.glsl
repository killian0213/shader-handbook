// Image (image) — [Test] simple advection by Ultraviolet
// https://www.shadertoy.com/view/MlcGWH

/*
  __  __       _         _____                            
 |  \/  |     (_)       |_   _|                           
 | \  / | __ _ _ _ __     | |  _ __ ___   __ _  __ _  ___ 
 | |\/| |/ _` | | '_ \    | | | '_ ` _ \ / _` |/ _` |/ _ \
 | |  | | (_| | | | | |  _| |_| | | | | | (_| | (_| |  __/
 |_|  |_|\__,_|_|_| |_| |_____|_| |_| |_|\__,_|\__, |\___|
                                                __/ |     
                                               |___/      
*/

vec2 screen2uv(in vec2 fragCoord)
{
    return fragCoord / iResolution.xy;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = screen2uv(fragCoord);
    fragColor = texture(iChannel0,  uv);
    //fragColor = abs(texture(iChannel1,  uv)*100.0);
}



