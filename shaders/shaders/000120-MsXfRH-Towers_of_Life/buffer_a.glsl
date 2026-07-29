// Buffer A (buffer) — Towers of Life by Polygon
// https://www.shadertoy.com/view/MsXfRH

//This buffer runs the game and saves the past 96 states.


//Width and height of the area of the "game board"
//I suggest matching them with the width and height of Image.
#define width 64
#define height 64

//Chance of a cell being alive at start. Kinda complicated to explain the specifics.
#define INITIAL_CHANCE 1.15

float rand(vec2 co);
bool check(vec3 pos);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    ivec4 col = ivec4(texelFetch(iChannel0, ivec2(fragCoord), 0));
    
    if (texelFetch(iChannel2, ivec2(0), 0).y == 1.0) {
        int neighbors = 0;
        if (check(vec3(mod(fragCoord + vec2(-1., -1.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(-1., 0.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(-1., 1.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(0., -1.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(0., 1.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(1., -1.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(1., 0.), vec2(width, height)), 0.0))) neighbors++;
        if (check(vec3(mod(fragCoord + vec2(1., 1.), vec2(width, height)), 0.0))) neighbors++;

        if ((col.w & (1 << 23)) == (1 << 23)) {
            col.w -= (1 << 23);
        }

        col.w = col.w << 1;

        if ((col.z & (1 << 23)) == (1 << 23)) {
            col.z -= (1 << 23);
            col.w++;
        }

        col.z = col.z << 1;

        if ((col.y & (1 << 23)) == (1 << 23)) {
            col.y -= (1 << 23);
            col.z++;
        }

        col.y = col.y << 1;

        if ((col.x & (1 << 23)) == (1 << 23)) {
            col.x -= (1 << 23);
            col.y++;
        }

        col.x = col.x << 1;

        if ((check(vec3(fragCoord, 0.0)) && neighbors > 1 && neighbors < 4) || (!check(vec3(fragCoord, 0.0)) && neighbors == 3)) {
            col.x ++;
        }
    }
    
    fragColor = vec4(col);
    
    if (iFrame == 0 || texelFetch(iChannel1, ivec2(13, 1), 0).x == 1.0) {
        fragColor.x = sign(floor(INITIAL_CHANCE * rand(fragCoord)));
        fragColor.yzw = vec3(0);
    }
}

bool check(vec3 pos) {
    int xy = int(texelFetch(iChannel0, ivec2(pos.xy), 0).x);
    return ((xy & 1) == 1);
}




float rand(vec2 co) {
   	//															    ###########################
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453 * mod(iDate.w, 100.) / 100.);
}