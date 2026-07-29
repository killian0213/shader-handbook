// Image (image) — BattleShips by skaplun
// https://www.shadertoy.com/view/7dscD2

#define BULLSEYE_CLR (vec3(1.000,0.482,0.000) * 10.)
struct World{
    Ray viewRay;
    vec4 boatsBBHitDistances; //draw max 2 boat per ray [closestBoatBBDst, closestBoatBBID, nextBoatBBDst, nextBoatBBID]
} world;

void constructWorld(Ray r, vec2 mouse){
    world.viewRay = r;
    vec4 dst = vec4(MAX_FLOAT);
    for(int i = ZERO; i<SHIPS_CNT; i++){
        Boat bb = boatFromId(i);
        vec4 pos = texelFetch(iChannel0, ivec2(i, SHIP_POSITION_LINE), 0);
        
        vec3 rots = texelFetch(iChannel0, ivec2(i, SHIP_ROTATION_LINE), 0).xyz;
        mat4 rot = mat4(rx(rots.x) * ry(rots.y) * rz(rots.z));
        mat4 tra = translate(pos.xyz);
        mat4 txi = tra * rot;
        mat4 txx = inverse(txi);
        vec2 boxHitDst = iBox(r, bb.boundingBox, txx, txi);
        
        if(boxHitDst.x >= 0.){
            if(boxHitDst.x < dst.x){
                dst.zw = dst.xy;
                dst.xy = vec2(boxHitDst.x, float(i));
            }if(boxHitDst.x == dst.x){
            
            }else if(boxHitDst.x < dst.z){
                dst.zw = vec2(boxHitDst.x, float(i));
            }
        }
    }
    
    if(dst.x == MAX_FLOAT)
        dst = vec4(-1.);
    if(dst.z == MAX_FLOAT)
        dst.zw = vec2(-1.);
    world.boatsBBHitDistances = dst;
}

float perlin(in vec3 x){
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
	vec2 rg = textureLod( iChannel1, (uv+ 0.5)/256.0, 0.0 ).yx;
	return -1.0+2.4*mix( rg.x, rg.y, f.z );
}

float fractalPerlin(vec3 p) {
   return perlin(p*.06125)*.5 + perlin(p*.125)*.25 + perlin(p*.25)*.125;
}

#define INCLUDE_VOLMETRIC_MARCH(funcName, minMaxDistFuncName, densityFunc, lightingFunc, fogColorFunc, densityThresh, marchStepsCount, densityMultiplier) vec4 funcName(Ray ray, float maxDepth, vec2 mouseHitCell) {    \
    vec2 dst = minMaxDistFuncName(ray);                                                                              \
    if(dst.x < 0.)                                                                                                   \
        return vec4(0.);                                                                                             \
    float sampleStep = (min(dst.y, maxDepth) - dst.x)/float(marchStepsCount);                                        \
    float totalDensity = 0.;                                                                                         \
    vec3 totalColor = vec3(0.);                                                                                      \
    float localDensity = 0.;                                                                                         \
    for (int i = ZERO; i<marchStepsCount; i++) {                                                                     \
        vec3 samplePos = ray.o + ray.dir * (dst.x + sampleStep * float(i));                                          \
        float curDensity = densityFunc(samplePos) * densityMultiplier;                                               \
        localDensity = (densityThresh - curDensity) * step(curDensity, densityThresh);                               \
        float weight = (1. - totalDensity) * localDensity;                                                           \
        vec4 light = lightingFunc(samplePos, mouseHitCell);                                                          \
        totalColor += weight * mix(fogColorFunc(), light.rgb, light.a);                                              \
        totalDensity += weight;                                                                                      \
        if(totalDensity > .95 || samplePos.y < 0.)                                                                   \
           break;                                                                                                    \
    }                                                                                                                \
    totalColor *= (1.5) / exp(localDensity * 4.) * 1.25;                                                             \
    return vec4(totalColor, totalDensity);                                                                           \
}

vec3 warFogColor(){
    return vec3(1.);
}

vec4 warFogLights(vec3 p, vec2 mouseHitCell){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    int gs = int(gameState.x);
    if(gs == GAME_STATE_FIRE || gs == GAME_STATE_AIMING){
        float brightness = 1.;
        if(gs == GAME_STATE_FIRE)
            brightness *= max(smoothstep(.3, 0., iTime - gameState.y), .00001);
        vec2 toMouse = p.xz - mouseHitCell;
        toMouse *= r2d(iTime);
        toMouse *= brightness;
        
        return vec4(BULLSEYE_CLR, bullsEye(toMouse) * brightness);
    }else{
        return vec4(0.);
    }
}

float warFogDensity(vec3 p) {
   float wholeField = smax(max(distance(p.x, 21.) - 5., abs(p.z) - 5.), abs(p.y) - 1., 1.);
   ivec2 cellId = ivec2(floor(p.xz) - vec2(16., -5.));
   cellId.y = 10 - cellId.y;
   vec4 gameField = texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0);
   vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
   float hitTime = gameField.w;
   float cutOut = -1.;
   if(gameField.y >= 0. || lastMove.x < 0.){
       float targetY = 3. - saturate(iTime - hitTime) * 3. * step(MIN_FLOAT, hitTime);
       cutOut = distance(p, vec3(floor(p.x) + .5, targetY, floor(p.z) + .5));
       cutOut = -cutOut + 1.5;
   }else if(hitTime >= 0.){
       vec2 cntr = lastMove.zw;
       cutOut = distance(p, vec3(cntr.x, 0., cntr.y));
       cutOut = -cutOut + 10. * (distance(hitTime, iTime) - .5);
   }
   
   wholeField = smax(wholeField, cutOut, .5);
   return wholeField + fractalPerlin(p * 25. + iTime * 2.) * .25;
}

vec2 warFogBBMinMax(Ray r){
    return iBox(r, Box(vec3(21., 0., 0.), vec3(5., 1., 5.)));
}

INCLUDE_VOLMETRIC_MARCH(marchWarFog, warFogBBMinMax, warFogDensity, warFogLights, warFogColor, .05, 32, 1.5)

vec3 rocketTrailColor(){
    return vec3(.1);
}

vec4 rocketLights(vec3 p, vec2 mouseHitCell){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    int gs = int(gameState.x);
    if(gs == GAME_STATE_FIRE){
        Ray mouseRay = createRay(iMouse.xy, iResolution.xy, iTime, gameState);

        float mouseHitOcean = (-mouseRay.o.y)/mouseRay.dir.y;
        vec3 mouseHitPoint = (mouseRay.o + mouseRay.dir * mouseHitOcean);
        vec2 mouseHitCell = floor(mouseHitPoint.xz) + .5;
    
        vec3 startPoint = vec3(10., 10., 0.);
        vec3 endPoint = vec3(mouseHitCell.x, 0., mouseHitCell.y);
        float time = iTime - gameState.y;
        float dst = distance(p, mix(startPoint, endPoint, smoothstep(0., .5, time) * 1.5));
        return vec4(vec3(1., .6, .2), smoothstep(4., 0., dst));
    }else if(gs == GAME_STATE_ENEMY_FIRE){
        vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
        vec3 startPoint = vec3(10., 10., 0.);
        vec3 endPoint = vec3(lastMove.z + .5, 0., lastMove.w + .5);
        
        float time = iTime - gameState.y;
        float dst = distance(p, mix(startPoint, endPoint, smoothstep(0., .5, time) * 1.5));
        return vec4(vec3(1., .6, .2), smoothstep(4., 0., dst));
    }else{
        return vec4(0.);
    }
}

float rocketDensity(vec3 p){
    vec4 savedGameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    Ray mouseRay = createRay(iMouse.xy, iResolution.xy, iTime, savedGameState);

    float mouseHitOcean = (-mouseRay.o.y)/mouseRay.dir.y;
    vec3 mouseHitPoint = (mouseRay.o + mouseRay.dir * mouseHitOcean);
    vec2 mouseHitCell = floor(mouseHitPoint.xz) + .5;
    
    int gs = int(savedGameState.x);
    if(gs == GAME_STATE_FIRE){
        vec3 startPoint = vec3(10., 10., 0.);
        vec3 endPoint = vec3(mouseHitCell.x, 0., mouseHitCell.y);
        float time = iTime - savedGameState.y;
        return sdCylinder(p, mix(startPoint, endPoint, smoothstep(0., .5, time) * 1.5), mix(startPoint, endPoint, smoothstep(.4, .75, time)), .1) + fractalPerlin(p * 20. + iTime * 50.) * .35;
    }else if(gs == GAME_STATE_ENEMY_FIRE){
        vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
        vec3 startPoint = vec3(10., 10., 0.);
        vec3 endPoint = vec3(lastMove.z + .5, 0., lastMove.w + .5);
        float time = saturate(iTime - savedGameState.y);
        vec3 a = mix(startPoint, endPoint, smoothstep(MIN_FLOAT, .5, time) * 1.5);//startPoint
        vec3 b = mix(startPoint, endPoint, smoothstep(.4, .75, time));//endPoint;
        return sdCylinder(p, a, b, .1) + fractalPerlin(p * 20. - iTime * 50.) * .35;
    }else{
        return 0.;
    }
}

vec2 rocketTrailMinMax(Ray cameraRay){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    int gs = int(gameState.x);
    if(gs == GAME_STATE_FIRE){
        Ray mouseRay = createRay(iMouse.xy, iResolution.xy, iTime, gameState);

        float mouseHitOcean = (-mouseRay.o.y)/mouseRay.dir.y;
        vec3 mouseHitPoint = (mouseRay.o + mouseRay.dir * mouseHitOcean);
        vec2 mouseHitCell = floor(mouseHitPoint.xz) + .5;
        
        vec3 startPoint = vec3(10., 10., 0.);
        vec3 endPoint = vec3(mouseHitCell.x, 0., mouseHitCell.y);
        float time = iTime - gameState.y;
        vec3 a = mix(startPoint, endPoint, smoothstep(0., .5, time) * 1.5);
        vec3 b = mix(startPoint, endPoint, smoothstep(.4, .75, time));
        
        return cylinderHit(cameraRay, Cylinder(a, b, .5));
    }else if(gs == GAME_STATE_ENEMY_FIRE){
        vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
        vec3 startPoint = vec3(10., 10., 0.);
        vec3 endPoint = vec3(lastMove.z + .5, 0., lastMove.w + .5);
        float time = saturate(iTime - gameState.y);
        vec3 a = mix(startPoint, endPoint, smoothstep(0., .5, time) * 1.5);
        vec3 b = mix(startPoint, endPoint, smoothstep(.4, .75, time));
        
        return cylinderHit(cameraRay, Cylinder(a, b, .5));
    }else{
        return vec2(-1.);
    }
}

INCLUDE_VOLMETRIC_MARCH(marchRocket, rocketTrailMinMax, rocketDensity, rocketLights, rocketTrailColor, .2, 32, .5)

vec3 boats(vec3 p, float dist){
    vec3 res = vec3(MAX_FLOAT);
    for(int k=ZERO; k<2; k++){
        float curBoatMinDist = world.boatsBBHitDistances[k * 2];
        if(curBoatMinDist < 0. && dist >= curBoatMinDist)
            continue;
        int id = int(world.boatsBBHitDistances[k * 2 + 1]);
        
        Boat b = boatFromId(id);
        vec4 pos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0);
        b.boundingBox.o = pos.rgb;
        
        vec3 rots = texelFetch(iChannel0, ivec2(id, SHIP_ROTATION_LINE), 0).xyz;
        mat4 rot = mat4(rx(rots.x) * ry(rots.y) * rz(rots.z));
        mat4 tra = translate(b.boundingBox.o);
        mat4 txi = tra * rot;
        mat4 txx = inverse(txi);
        
        switch(b.boatType){
            case 1:
                res = opMin(res, vec3(boat1(p, txx, iTime), float(id)));
                break;
            case 2:
                res = opMin(res, vec3(boat2(p, txx, iTime), float(id)));
                break;
            case 3:
                res = opMin(res, vec3(boat3(p, txx), float(id)));
                break;
            case 4:
                res = opMin(res, vec3(boat4(p, txx, iTime), float(id)));
                break;
            default:
                break;
        }
    }
    
    if(max(abs(p.x), abs(p.z)) <= 5.){
        ivec2 cellId = ivec2(floor(p.xz) + 5.);
        cellId.y = 10 - cellId.y;
        float hitTime = texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0).z;
        if(hitTime >= 0.){
            float dst = distance(p.yz, floor(p.yz) + vec2(.1, .5)) - (1.3 - smoothstep(.25, .65, saturate(iTime - hitTime))) + perlin(p * 5.) * .1;
            res.x = smax(res.x, dst, .1);
        }
    }
    
    return res;
}

float certainBoat(vec3 p, int id){
    Boat b = boatFromId(id);
    vec4 pos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0);
    b.boundingBox.o = pos.rgb;

    vec3 rots = texelFetch(iChannel0, ivec2(id, SHIP_ROTATION_LINE), 0).xyz;
    mat4 rot = mat4(rx(rots.x) * ry(rots.y) * rz(rots.z));
    mat4 tra = translate(b.boundingBox.o);
    mat4 txi = tra * rot;
    mat4 txx = inverse(txi);

    switch(b.boatType){
        case 1:
            return boat1(p, txx, iTime).x;
        case 2:
            return boat2(p, txx, iTime).x;
        case 3:
            return boat3(p, txx).x;
            break;
        case 4:
            return boat4(p, txx, iTime).x;
        default:
            return MAX_FLOAT;
    }
}

vec3 normals(vec3 pos, int id){
    vec2 eps = vec2(0.0, EPSILON);
    vec3 n = normalize(vec3(
        certainBoat(pos + eps.yxx, id) - certainBoat(pos - eps.yxx, id),
        certainBoat(pos + eps.xyx, id) - certainBoat(pos - eps.xyx, id),
        certainBoat(pos + eps.xxy, id) - certainBoat(pos - eps.xxy, id)));
    return n;
}

const int MAX_MARCHING_STEPS = 32;
vec3 march(float maxDist){
    if(world.boatsBBHitDistances.x < 0.)
        return vec3(MAX_FLOAT);
    float t = world.boatsBBHitDistances.x;
    for(int i = ZERO; i <= MAX_MARCHING_STEPS; i++){
        vec3 p = world.viewRay.o + world.viewRay.dir * t;
        vec3 dst = boats(p, t);
        if(abs(dst.x) < .001)
            return vec3(t, dst.y, dst.z);
        t += dst.x;
        if(p.y < 0. || t > maxDist)
            break;
    }
    return vec3(MAX_FLOAT);
}

void letter(inout vec4 fragColor, in vec2 fragCoord, 
            in vec2 position, in vec2 size, in int code, float w, vec4 color) {
    vec2 uv = fragCoord - position;
    uv += size * 0.5;
    uv /= size;

    if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
        uv.x += float(code % 16);
        uv.y += float(15 - code / 16);

        uv *= 0.0625;

        float sd = abs(texture(iChannel3, uv).a);
        fragColor = blend(fragColor, vec4(color.rgb, color.a * smoothstep(0.0, 4., (0.52 + w - sd) * 50.0)));
    }
}

void letter(inout vec4 fragColor, in vec2 fragCoord, 
            in vec2 position, in vec2 size, in int code, float w, vec3 color) {
    letter(fragColor, fragCoord, position, size, code, w, vec4(color, 1.));
}

const vec3 SHIP_GREY = vec3(111., 116., 141.)/255.;
const vec3 SHIP_BLACK = vec3(38.)/255.;
const vec3 HELI_YELLOW = vec3(246., 215., 21.)/255.;
const vec3 SHIP_BLUE = vec3(42., 93., 148.)/255.;
const vec3 SHIP_RED = vec3(168., 40., 38.)/255.;
vec3 albedo(vec3 pos, vec3 nrm, int id, int matId){
    int type = boatFromId(id).boatType;
    
    vec4 cntr = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0);
    pos -= cntr.xyz;
    vec3 rots = texelFetch(iChannel0, ivec2(id, SHIP_ROTATION_LINE), 0).xyz;
    
    mat3 rm = rx(rots.x) * ry(rots.y) * rz(rots.z);
    pos *= rm;
    
    vec3 overlayClr = hsv2rgb(vec3(cntr.w, step(cntr.w, .1), 1.));
    
    switch(type){
        case 1:
            {
                if(matId == MAT_BOAT1_CAB){
                    float window = step(dot(nrm, vec3(-1., 0., 0.)), .05)
                                 * step(dot(nrm, vec3(0., 1., 0.)), .95);
                    return mix(SHIP_GREY, SHIP_BLUE * .5, window) * overlayClr;
                }else{
                    vec3 res = mix(SHIP_GREY, SHIP_RED, step(pos.y, 0.));
                    res = mix(res, SHIP_BLACK, step(.95, dot(nrm, vec3(0., 1., 0.))));
                    return res * overlayClr;
                }
            }
            break;
        case 2:
            float heli = smoothstep(.025, .015, distance(distance(pos.xz, vec2(.3, 0.)), .175));
            heli = max(heli, smoothstep(.025, .015, distance(abs(pos.x - .3), .065)) * smoothstep(.1, .09, abs(pos.z)));
            heli = max(heli, smoothstep(.025, .015, abs(pos.z)) * step(abs(pos.x - .3), .075));
            vec3 floorColor = mix(SHIP_BLACK, HELI_YELLOW, heli);
            float window = smoothstep(.4, .35, length(fract(pos.xy * 7. + vec2(-.5, -.25)) - .5)) * step(abs(pos.y + .035), .055)
                         * step(distance(pos.x, -.3), .47);
            window = max(window, smoothstep(.4, .35, length(fract(pos.xy * 7. + vec2(-.5, -.3)) - .5)) * step(abs(pos.y - .11), .055)
                                       * step(distance(pos.x, -.45), .2));
            window = max(window, smoothstep(.05, .04, distance(pos.y, .11)) * smoothstep(.15, .14, abs(pos.z)) * step(pos.x, -.5));
            window = max(window, smoothstep(.065, .06, distance(pos.y, -.04)) * smoothstep(.15, .14, abs(pos.z)) * step(pos.x, -.5));
            
            vec3 bodyColor = mix(SHIP_GREY * 2., SHIP_BLUE * .5, window);
            vec4 res = vec4(mix(floorColor, bodyColor, step(dot(nrm, vec3(0., 1., 0.)), .99)), 1.);
            float stripes = smoothstep(.02, .01, abs(pos.y + .2)) * step(.14, abs(pos.x - .78));
            res = blend(res, vec4(vec3(2.), stripes));
            letter(res, pos.xy, vec2(.7, -.2), vec2(.15), 49, 0.03, vec3(2.));
            letter(res, pos.xy, vec2(.76, -.2), vec2(.15), 55, 0.03, vec3(2.));
            letter(res, pos.xy, vec2(.82, -.2), vec2(.15), 49, 0.03, vec3(2.));
            letter(res, pos.xy, vec2(.88, -.2), vec2(.15), 50, 0.03, vec3(2.));
            return res.rgb * overlayClr;
            break;
        case 3:
            return SHIP_BLACK * overlayClr;
            break;
        case 4:
            {
                if(matId == MAT_PLANE_MAIN)
                    return vec3(.7);
                else if(matId == MAT_PLANE_CABIN)
                    return vec3(.1);

                float deckLines = smoothstep(.02, .005, abs(pos.z - .05)) * smoothstep(.1, .05, fract(pos.x * 3.) - .5);
                deckLines = max(deckLines, smoothstep(.02, .005, abs(pos.z - .29)) * step(0., pos.x));
                deckLines = max(deckLines, smoothstep(.02, .005, abs(pos.z - pos.x * .1 - .29)) * step(0., pos.x));
                deckLines = max(deckLines, smoothstep(.02, .005, abs(pos.z + .19)) * step(-.4, pos.x));
                
                deckLines = max(deckLines, smoothstep(.02, .005, distance(.2, abs(pos.z + pos.x * .2 + .48))) * step(pos.z, -.175));// * step(0., pos.x)
                deckLines = max(deckLines, smoothstep(.015, .0, distance(.02, abs(pos.z + pos.x * .2 + .48))));
                vec3 deck = mix(SHIP_BLACK, vec3(2.), deckLines);
                vec3 body = mix(SHIP_GREY, SHIP_RED, step(pos.y, -.35));
                body = mix(body, SHIP_BLUE, step(.1, distance(fract(pos.x * 10.), .5)) * smoothstep(.05, .04, distance(.075, abs(pos.y - .4))));
                vec3 res = mix(deck, body, step(dot(nrm, vec3(0., 1., 0.)), .99));
                return res * overlayClr;
            }
            break;
        default:
            break;
    }
    return vec3(0.);
}

#define SUN_DIR normalize(vec3(0., 20., 2.))
vec4 ships(float maxDist){
    vec3 marchBoats = march(maxDist);
    if(marchBoats.x < MAX_FLOAT){
        vec3 pos = world.viewRay.o + world.viewRay.dir * marchBoats.x;
        //return vec4(vec3(fract(marchBoats.x)), marchBoats.x);
        vec3 nrm = normals(pos, int(marchBoats.z));
        vec3 albedo = albedo(pos, nrm, int(marchBoats.z), int(marchBoats.y));
        float diff = clamp(dot(nrm, SUN_DIR), .3, 1.);
        return vec4(albedo * diff, marchBoats.x);
    }else{
        return vec4(MAX_FLOAT);
    }
}

vec4 shipBounds(vec2 pos, out float shape){
    shape = MAX_FLOAT;
    ivec2 cellId = ivec2(pos + 5.);
    cellId.y = 10 - cellId.y;
    float ocupiedBy = texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0).x;
    vec4 boundColor = vec4(MAX_FLOAT); 
    if(ocupiedBy >= 0.){
        float tmp = ocupiedBy;
        int neigh = 0;
        //this is awful but it works
        if(tmp > 1000.) neigh = 4; else if(tmp > 100.) neigh = 3;else if(tmp > 10.) neigh = 2; else neigh = 1;
        for(int i=ZERO; i<neigh; i++){
            tmp *= .1;
            int curOcupation = int(fract(tmp) * 10.);
            vec4 curBoatPos = texelFetch(iChannel0, ivec2(curOcupation, SHIP_POSITION_LINE), 0) - vec4(boatOffsetsFromPos(curOcupation), 0., 0.);
            if(abs(curBoatPos.y) < 5.){
                float curBoatSpan =  boatSpanFromId(curOcupation);

                float left = curBoatPos.x - step(1.5, curBoatSpan) - 1.;
                float right = curBoatPos.x + curBoatSpan - step(1.5, curBoatSpan) + 1.;
                float top = curBoatPos.z + 1.;
                float bottom = curBoatPos.z - 1.;

                vec2 interaction = texelFetch(iChannel0, ivec2(curOcupation, SHIP_INTERACTION_LINE), 0).xy;
                float shapeWidth = .5 + smoothstep(.3, .7, distance(interaction.RELEASE_TIME, iTime)) * .7 * step(interaction.PRESSED, MIN_FLOAT);
                float shapeStencil = smax(distance(pos.x, (floor(left) + ceil(right)) * .5) - (shapeWidth + .5 * curBoatSpan),
                                          distance(pos.y, (floor(bottom) + ceil(top)) * .5) - shapeWidth, .125);
                shapeStencil = smax(shapeStencil, abs(pos.x) - 5., .125);
                shapeStencil = smax(shapeStencil, abs(pos.y) - 5., .125);
                
                float clr = curBoatPos.w;
                if(clr < .1)
                    shapeStencil = max(shapeStencil, (.25 - distance(fract(pos.x * 2. + pos.y), .5)) * step(clr, .1));
                vec4 curShapeColor = vec4(shapeStencil, mix(vec3(1.), vec3(1., 0., 0.), step(clr, .1)));
                boundColor = opMin(boundColor, curShapeColor);
                
                shape = smin(shape, shapeStencil, .125);
            }
        }
    }
    return vec4(boundColor.gba, smoothstep(.05, .0, abs(shape)) * .75);
}

#define AA .35
vec2 shipRipple(vec2 pos){
    float res = MAX_FLOAT;
    ivec2 cellId = ivec2(pos + 5.);
    cellId.y = 10 - cellId.y;
    float ocupiedBy = texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0).x;
    if(ocupiedBy >= 0.){
        float tmp = ocupiedBy;
        int neigh = 0;
        //this is awful but it works
        if(tmp > 1000.) neigh = 4; else if(tmp > 100.) neigh = 3;else if(tmp > 10.) neigh = 2; else neigh = 1;
        for(int i=ZERO; i<neigh; i++){
            tmp *= .1;
            int curOcupation = int(fract(tmp) * 10.);
            vec2 curBoatPos = texelFetch(iChannel0, ivec2(curOcupation, SHIP_POSITION_LINE), 0).rb - boatOffsetsFromPos(curOcupation);
            if(abs(curBoatPos.y) < 5.){
                float curBoatSpan =  boatSpanFromId(curOcupation);
                float left = curBoatPos.x - step(1.5, curBoatSpan);
                float right = curBoatPos.x + curBoatSpan - step(1.5, curBoatSpan);
                vec2 cntr = vec2((floor(left) + ceil(right)) * .5, curBoatPos.y);
                float shapeDistance = smax(distance(pos.x, cntr.x) - (1. + .5 * curBoatSpan), distance(pos.y, cntr.y) - 1., 1.);
                vec2 diff = cntr - pos;
                float ang = atan(diff.y, diff.x) + QPI;
                float width = distance(abs(ang), HPI)/PI * 2.;
                float releaseTime = texelFetch(iChannel0, ivec2(curOcupation, SHIP_INTERACTION_LINE), 0).RELEASE_TIME;
                return vec2(step(MIN_FLOAT, releaseTime)
                          * smoothstep(.2, .5, distance(iTime, releaseTime))
                          * smoothstep(.4, .1, distance(shapeDistance + 1., distance(iTime, releaseTime) * 2.))
                          * smoothstep(.65, 0., shapeDistance)
                          * abs(sin(ang + iTime * 4.)),
                          (iTime - releaseTime) * step(MIN_FLOAT, releaseTime));
            }
        }
    }
    return vec2(res) * step(res, 1.);
}

//===================================================OCEAN============================================================

#define STEPS 80.0
#define MDIST 35.0
#define pi 3.1415926535
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define sat(a) clamp(a,0.0,1.0)

#define ITERS_TRACE 9
#define ITERS_NORM 15

#define HOR_SCALE 7.5
#define OCC_SPEED .8
#define DX_DET .5

#define FREQ .6
#define HEIGHT_DIV 15.
#define WEIGHT_SCL 0.8
#define FREQ_SCL 1.2
#define TIME_SCL 1.095
#define WAV_ROT 1.21
#define DRAG 0.6
#define SCRL_SPEED 1.5
vec2 scrollDir = vec2(0, 0);

vec2 wavedx(vec2 wavPos, int iters, float t){
    vec2 dx = vec2(0);
    vec2 wavDir = vec2(1,0);
    float wavWeight = 1.0; 
    wavPos+= t*SCRL_SPEED*scrollDir;
    wavPos*= HOR_SCALE;
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED*t;
    for(int i=ZERO;i<iters;i++){
        wavDir*=rot(WAV_ROT);
        float x = dot(wavDir,wavPos)*wavFreq+wavTime; 
        float result = exp(sin(x)-1.)*cos(x)*wavWeight; 
        dx += result * wavDir/pow(wavWeight, DX_DET); 
        wavFreq *= FREQ_SCL; 
        wavTime *= TIME_SCL;
        wavPos -= wavDir*result*DRAG; 
        wavWeight *= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL, float(iters)) - 1.) * HEIGHT_DIV; 
    return dx/pow(wavSum,1.-DX_DET);
}

float wave(vec2 wavPos, int iters, float t){
    float wav = 0.0;
    vec2 wavDir = vec2(1,0);
    float wavWeight = 1.0;
    wavPos+= t*SCRL_SPEED*scrollDir;
    wavPos*= HOR_SCALE; 
    float wavFreq = FREQ;
    float wavTime = OCC_SPEED * t;
    for(int i=ZERO;i<iters;i++){
        wavDir *= rot(WAV_ROT);
        float x = dot(wavDir,wavPos)*wavFreq+wavTime;
        float wave = exp(sin(x) - 1.0) * wavWeight;
        wav += wave;
        wavFreq *= FREQ_SCL;
        wavTime *= TIME_SCL;
        wavPos -= wavDir*wave*DRAG*cos(x);
        wavWeight *= WEIGHT_SCL;
    }
    float wavSum = -(pow(WEIGHT_SCL, float(iters)) - 1.) * HEIGHT_DIV; 
    return wav/wavSum;
}

vec3 norm(vec3 p, int iters){
    vec2 wav = -wavedx(p.xz, iters, iTime);
    return normalize(vec3(wav.x,1.0,wav.y));
}

float mapOcean(vec3 p){
    float a = 0.;
    int steps = ITERS_TRACE;
    vec2 ripple = shipRipple(p.xz);
    float h = wave(p.xz, steps, iTime) + ripple.x * .25;
    return p.y - h;
}

//===================================================OCEAN============================================================

vec3 Sky(vec3 ray){
	return mix(vec3(.4, .45, .5), vec3(.7), step(dot(ray, SUN_DIR), .05));
}

vec3 ShadeOcean(vec3 pos, vec3 ray,vec3 norm){
	float ndotr = dot(ray,norm);
	float fresnel = pow(1. - abs(ndotr), 4.);

    vec3 reflectedRay = ray - 2. * norm * ndotr;
	vec3 reflection = Sky(reflectedRay);
	return mix(vec3(0,.04,.04), reflection, fresnel);
}

vec4 ocean(Ray r, float start, out vec3 normal){
    float hitDistance = start;
    bool hit = false;
    float maxDist = (-.5-r.o.y)/r.dir.y;
    if(start > 0.){
        for(float i = 0.; i<32.; i++){
            vec3 p = r.o + r.dir * hitDistance;
            float d = mapOcean(p);
            hitDistance += d;
            if(abs(d) < 0.01){
                hit = true;
                break;
            }
            if(hitDistance > maxDist)
                return vec4(MAX_FLOAT);
        }
    }
    
    if(hit){
        vec3 p = r.o + r.dir * hitDistance;
        normal = norm(p, ITERS_NORM);
        vec4 ocean = vec4(ShadeOcean(p, r.dir, normal), 1.);
        
        float shipOutlinesShape = 0.;
        vec4 shipOutlinesColor = shipBounds(p.xz, shipOutlinesShape);
        ocean = blend(ocean, shipOutlinesColor);
        
        float scull = 0.;
        if(max(abs(p.x - 21.), abs(p.z)) <= 5.){
            ivec2 cellId = ivec2(p.xz - vec2(16., -5.));
            cellId.y = 10 - cellId.y;
            float ocupied = texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0).y;
            scull = ASCIIskull((fract(p.xz) - .5) * 3.) * step(abs(p.z), 5.) * step(distance(p.x, 21.), 5.)
                  * step(0., ocupied) * .5;
        }
        
        float playerFieldHit = 0.;
        if(max(abs(p.x), abs(p.z)) <= 5.)
        {
            vec2 cellId = p.xz + 5.;
            cellId.y = 10. - cellId.y;
            float ocupied = texelFetch(iChannel0, ivec2(cellId.x, iResolution.y - cellId.y), 0).z;
            playerFieldHit = step(0., ocupied) * smoothstep(.11, .1, distance(fract(p.xz), vec2(.5)));
        }
        
        {
            p.z *= -1.;
            if(p.x > 12. && p.x < 27.)
                p.x = mod(p.x, 15.) - 6.;
        }
        
        float w = .075;
        float ww = .5;
        float grid = smoothstep(ww - w, ww, distance(fract(p.x), .5));
        grid = max(grid, smoothstep(ww - w, ww, distance(fract(p.z), .5)));
        grid *= smoothstep(5. + w, 5., max(abs(p.x), abs(p.z)));
        grid *= smoothstep(0., 0. + w, shipOutlinesShape);
        
        ocean = blend(ocean, vec4(vec3(.8), grid));
        ocean = blend(ocean, vec4(vec3(1.), max(scull, playerFieldHit)));
        
        if(floor(p.x) == -6. && abs(p.z) < 5.){
            letter(ocean, p.xz,  floor(p.xz) + .5, vec2(1.), 64 - (int(floor(p.z)) - 5), 0., vec3(1.));
        }
        
        if(floor(p.z) == -6. && abs(p.x) < 5.){
            letter(ocean, p.xz,  floor(p.xz) + .5, vec2(1.), 48 + (int(floor(p.x)) + 5), 0., vec3(1.));
        }
        return vec4(ocean.rgb, hitDistance);
    }
    return vec4(MAX_FLOAT);
}

vec3 gameScene(in vec2 fragCoord){
    vec4 savedGameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    Ray cameraRay = createRay(fragCoord, iResolution.xy, iTime, savedGameState);
    Ray mouseRay = createRay(iMouse.xy, iResolution.xy, iTime, savedGameState);
    
    float mouseHitOcean = (-mouseRay.o.y)/mouseRay.dir.y;
    vec3 mouseHitPoint = (mouseRay.o + mouseRay.dir * mouseHitOcean);
    vec2 mouseHitCell = clamp(floor(mouseHitPoint.xz) + .5, -4.5, 4.5);
    vec3 color = vec3(0.);
    
    constructWorld(cameraRay, mouseHitCell);
    
    float hitOcean = (-cameraRay.o.y)/cameraRay.dir.y;
    if(hitOcean >= 0.0) {
        {
            vec3 pos = cameraRay.o + hitOcean * cameraRay.dir;
            vec3 normal;
            vec4 oc = ocean(cameraRay, hitOcean, normal);
            color = oc.rgb;
            hitOcean = oc.a;
#ifdef REFLECTIONS
            pos.y = MIN_FLOAT;
            constructWorld(Ray(pos, reflect(cameraRay.dir, normal)), mouseHitCell);
#endif            
        }
    }
    vec4 shipssss;
#ifdef REFLECTIONS
    shipssss = ships(hitOcean);
    if(shipssss.w < hitOcean)
        color += shipssss.rgb * .35;
    constructWorld(cameraRay, mouseHitCell);
#endif
    
    shipssss = ships(hitOcean);
    if(shipssss.w < hitOcean)
        color = shipssss.rgb;
    
    {
        vec2 enemyField = floor(mouseHitPoint.xz) + .5;
        enemyField.x = clamp(enemyField.x, 16.5, 25.5);
        enemyField.y = clamp(enemyField.y, -4.5, 4.5);
        
        vec4 warFog = marchWarFog(cameraRay, hitOcean, enemyField);
        color = mix(color, warFog.rgb, warFog.a);
        
        vec4 rocketTrail = marchRocket(cameraRay, hitOcean, enemyField);
        color = mix(color, rocketTrail.rgb, rocketTrail.a);
    }
    
    return pow(color, vec3(1./2.2));
}

#define INCLUDE_DRAW_STRING_FUNCTION(name, arrayName, arrayLength)                   \
  void name(inout vec4 fragColor, in vec2 fragCoord, float offset) {                 \
    float size = 1.0 / float(arrayLength);                                           \
                                                                                     \
    fragCoord.y -= - size * (1.0 + offset) - 0.2;                                    \
    fragCoord.x = clamp(fragCoord.x, -1.0, 1.0);                                     \
    fragCoord.x += 1.0;                                                              \
    fragCoord *= 0.5;                                                                \
                                                                                     \
    int code = arrayName[int(fragCoord.x / size - 0.01)];                            \
    fragCoord.x = mod(fragCoord.x, size) - size * 0.5;                               \
                                                                                     \
    letter(fragColor, fragCoord, vec2(0.0), vec2(size * 1.4), code, .05, vec3(1.));  \
  }

const int battleWordLength = 6;
const int[] battleWordLetters = int[](66, 65, 84, 84, 76, 69);
INCLUDE_DRAW_STRING_FUNCTION(battleButton, battleWordLetters, battleWordLength)

const int playerTroopsLength = 13;
const int[] playerTroopsLetters = int[](80, 76, 65, 89, 69, 82, 32, 84, 82, 79, 79, 80, 83);
INCLUDE_DRAW_STRING_FUNCTION(playerTroopsWord, playerTroopsLetters, playerTroopsLength)

const int enemyTroopsLength = 12;
const int[] enemyTroopsLetters = int[](69, 78, 69, 77, 89, 32, 84, 82, 79, 79, 80, 83);
INCLUDE_DRAW_STRING_FUNCTION(enemyTroopsWord, enemyTroopsLetters, enemyTroopsLength)

const int victoryLength = 8;
const int[] victoryLetters = int[](86, 73, 67, 84, 79, 82, 89, 33);
INCLUDE_DRAW_STRING_FUNCTION(victoryWord, victoryLetters, victoryLength)

const int playAgainLength = 10;
const int[] playAgainLetters = int[](80, 76, 65, 89, 32, 65, 71, 65, 73, 78);
INCLUDE_DRAW_STRING_FUNCTION(playAgainWord, playAgainLetters, playAgainLength)

const int loseLength = 9;
const int[] loseLetters = int[](89, 79, 85, 32, 76, 79, 83, 69, 40);
INCLUDE_DRAW_STRING_FUNCTION(loseWord, loseLetters, loseLength)

vec4 ui(vec2 fragCoord){
    vec2 uv = fragCoord/iResolution.y;
    vec4 color = vec4(0.);
    
    {//BATTLE_BUTTON
        vec4 bb = texelFetch(iChannel0, ivec2(BUTTONS_BATTLE_ID, BUTTONS_LINE), 0);
        if(bb.x == 1.)
        {
            vec2 bbPos = vec2(bb.y, BATTLE_BUTTON.CENTER_Y);
        
            float xd = distance(uv.x, bbPos.x) - BATTLE_BUTTON.WIDTH;
            float yd = distance(uv.y, bbPos.y) - BATTLE_BUTTON.HEIGHT;
            float buttonStencil = step(smax(xd, yd, .025), 0.);

            color = blend(color, vec4(vec3(0.086,0.596,0.467), buttonStencil));
            color = blend(color, vec4(vec3(1.), bullsEye((uv - bbPos + vec2(.17, 0.)) * 16.)));
            battleButton(color, (uv - vec2(bbPos.x + .07, .19)) * 6., 0.);
        }
    }
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    int state = int(gameState.x);
#ifdef RENDER_SWAP_BTN
    if(state >= GAME_STATE_AIMING){
        vec2 bbPos = vec2(SWAP_BUTTON.CENTER_X, SWAP_BUTTON.CENTER_Y);
        float xd = distance(uv.x, bbPos.x) - SWAP_BUTTON.WIDTH;
        float yd = distance(uv.y, bbPos.y) - SWAP_BUTTON.HEIGHT;
        float buttonStencil = step(smax(xd, yd, .025), 0.);
        color = blend(color, vec4(vec3(0., .6, 1.), buttonStencil));
        letter(color, uv, SWAP_BUTTON.xy, vec2(.15), 20, .03, vec3(1.));
    }
#endif

#ifdef RENDER_RANDOM_BTN
    if(state == GAME_STATE_POSITIONING || state == GAME_STATE_READY_TO_PLAY){
        vec2 bbPos = vec2(RANDOM_BUTTON.CENTER_X, RANDOM_BUTTON.CENTER_Y);
        float xd = distance(uv.x, bbPos.x) - RANDOM_BUTTON.WIDTH;
        float yd = distance(uv.y, bbPos.y) - RANDOM_BUTTON.HEIGHT;
        float buttonStencil = step(smax(xd, yd, .025), 0.);
        color = blend(color, vec4(vec3(.6, .4, .2), buttonStencil));
        letter(color, uv, RANDOM_BUTTON.xy, vec2(.1), 35, .03, vec3(1.));
    }
#endif

#ifdef RENDER_SHIP_INDICATORS
    if(gameState.x >= float(GAME_STATE_AIMING)){
        float centerPoint = .39;
        
        if(gameState.x >= float(GAME_STATE_ENEMY_TURN)){
            centerPoint += easeInExpo(saturate(iTime - gameState.y + gameState.x - float(GAME_STATE_ENEMY_TURN)));
        }else if(gameState.x == float(GAME_STATE_AIMING)){
            centerPoint += 1. - easeInExpo(saturate(iTime - gameState.y));
        }
        
        if(gameState.x == float(GAME_STATE_END)){
            if(gameState.z == float(GAME_STATE_FIRE)){
                centerPoint = .39;
            }else{
                centerPoint = 1.39;
            }
        }
        
        vec2 reflectedUV = uv;
        reflectedUV.x = abs(reflectedUV.x - centerPoint) - .88;
        
        if(gameState.z != float(GAME_STATE_READY_TO_PLAY) || (iTime - gameState.y) > .9){
            float panel = step(0., reflectedUV.x  - .6 + reflectedUV.y * .8) * step(.35, reflectedUV.y);
            color = blend(color, vec4(vec3(0.), .5 * panel));
        }

        vec4 playerDamageCount = texelFetch(iChannel0, ivec2(0, ENEMY_HIT_COUNT_LINE), 0);
        vec4 enemyDamageCount = texelFetch(iChannel0, ivec2(1, ENEMY_HIT_COUNT_LINE), 0);
        vec4 damageCount = vec4(0.);
        if(gameState.x >= float(GAME_STATE_ENEMY_TURN)){
            damageCount = mix(enemyDamageCount, playerDamageCount, step(float(GAME_STATE_ENEMY_TURN) + .8, gameState.x + iTime - gameState.y));
        }else if(gameState.x >= float(GAME_STATE_AIMING)){
            damageCount = mix(playerDamageCount, enemyDamageCount, step(float(GAME_STATE_AIMING) + .8, gameState.x + iTime - gameState.y));
        }
        
        if(gameState.x == float(GAME_STATE_END)){
            if(gameState.z == float(GAME_STATE_FIRE)){
                damageCount = enemyDamageCount;
            }else{
                damageCount = playerDamageCount;
            }
        }

        if(gameState.z != float(GAME_STATE_READY_TO_PLAY) || (iTime - gameState.y) > .9){
            color = blend(color, vec4(vec3(1.), smoothstep(.00251, .0025, distance(reflectedUV.y, .92)) * smoothstep(.251, .25, distance(reflectedUV.x, .22))));
            color = blend(color, ship4_2d((reflectedUV - vec2(.25, .8)) * 8., damageCount[3]));
            color = blend(color, ship3_2d((reflectedUV - vec2(.3, .69)) * 8., damageCount[2]));
            color = blend(color, ship2_2d_alt((reflectedUV - vec2(.33, .55)) * 8., damageCount[1]));
            color = blend(color, ship1_2d_alt((reflectedUV - vec2(.375, .41)) * 12., damageCount[0]));
        }
        
        if(gameState.z != float(GAME_STATE_READY_TO_PLAY))
            playerTroopsWord(color, (uv - vec2(-1.075 + centerPoint, 1.04)) * 3.5, 0.);
        enemyTroopsWord(color, (uv - vec2(1.075 + centerPoint, 1.04)) * 3.5, 0.);
    }
#endif

    if(gameState.x >= float(GAME_STATE_AIMING)){
        Ray mouseRay = createRay(iMouse.xy, iResolution.xy, iTime, gameState);
        float mouseHitOcean = (-mouseRay.o.y)/mouseRay.dir.y;
        vec3 mouseHitPoint = (mouseRay.o + mouseRay.dir * mouseHitOcean);
        bool isInside = max(distance(mouseHitPoint.x, 21.), abs(mouseHitPoint.z)) <= 5.;
        if(isInside)
            mouseHitPoint.xz = floor(mouseHitPoint.xz) + .5;

        vec3 wa = mouseHitPoint, wb = wa + vec3(.5, 1.5, abs(mouseHitPoint.z * .5) * step(mouseHitPoint.z, 0.)), wc = wb + vec3(1.5, 0., 0.);
        vec2 sa = projectPoint(wa, fragCoord, iResolution.xy, iTime, gameState);
        vec2 sb = projectPoint(wb, fragCoord, iResolution.xy, iTime, gameState);
        vec2 sc = projectPoint(wc, fragCoord, iResolution.xy, iTime, gameState);
        sa.y += .5;
        sb.y += .5;
        sc.y += .5;

        float time = pow(saturate(iTime - gameState.y), .5);
        float gsf = float(GAME_STATE_FIRE);
        float gsa = float(GAME_STATE_AIMING);
        float opacity = smoothstep(gsa + .85, gsf, gameState.x + time)
                      * smoothstep(gsf + .4, gsf, gameState.x + time);

        vec2 b = mix(sb, sc, smoothstep(.5, 1., 1. - opacity));
        vec2 a = mix(sa, b, smoothstep(0., .5, 1. - opacity));
        vec2 c = sc;

        uv = (2. * fragCoord - iResolution.xy)/iResolution.y;
        color = mix(color, vec4(BULLSEYE_CLR, 1.), step(.01, opacity) * smoothstep(.015, .005, line(uv, a, b)));
        color = mix(color, vec4(BULLSEYE_CLR, 1.), step(.01, opacity) * smoothstep(.015, .005, line(uv, b, c)));
        
        {
            vec2 warFogHitCell = floor(mouseHitPoint.xz - vec2(16., -5.));
            warFogHitCell.y = 10. - warFogHitCell.y;
            vec2 hitCell = vec2(warFogHitCell.x, iResolution.y - warFogHitCell.y);
            vec4 hitCellOcupation = texelFetch(iChannel0, ivec2(hitCell), 0);
            if(hitCellOcupation.w >= 0.)
                isInside = false;
        }
        
        if(isInside){
            vec4 clr = vec4(BULLSEYE_CLR, opacity);
            letter(color, uv, (sb + sc) * .5 + vec2(-.08, .08), vec2(.2), 70 + int(floor(mouseHitPoint.z)), .03, clr);
            letter(color, uv, (sb + sc) * .5 + vec2(.08, .08), vec2(.2), 32 + int(floor(mouseHitPoint.x)), .03, clr);
            letter(color, uv, (sb + sc) * .5 + vec2(0., .09), vec2(.2), 45, .03, clr);
        }else{
            float shape = opacity * nogologo(uv - (sb + sc) * .5 - vec2(0., .1));
            vec4 clr = vec4(BULLSEYE_CLR, shape);
            color = blend(color, clr);
        }
    }

#ifdef RENDER_EXPLOSIONS
    if(gameState.x >= float(GAME_STATE_ENEMY_FIRE)){
        vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
        if(lastMove.x >= 0.){
            vec2 pos = projectPoint(vec3(lastMove.z + .5, .5, lastMove.w + .5), fragCoord, iResolution.xy, iTime, gameState);
            color = blend(color, explosion((uv - pos) * 10., smoothstep(.25, 1., saturate(iTime - lastMove.y))));
        }
    }
#endif

    if(gameState.x >= float(GAME_STATE_END)){
        float fade = saturate((iTime - gameState.y) * 4.);
        float move = (1. - fade) * .5;
        vec2 uv = fragCoord/iResolution.y;
        color = blend(color, vec4(0., 0., 0., .8 * fade));
        if(gameState.z == float(GAME_STATE_FIRE))
            victoryWord(color, uv * 2. - vec2(iResolution.x/iResolution.y, move + 1.75), 0.);
        else
            loseWord(color, uv * 2. - vec2(iResolution.x/iResolution.y, move + 1.75), 0.);
        
        vec2 bbPos = vec2(PLAY_AGAIN_BUTTON.CENTER_X, PLAY_AGAIN_BUTTON.CENTER_Y);
        float xd = distance(uv.x, bbPos.x) - PLAY_AGAIN_BUTTON.WIDTH;
        float yd = distance(uv.y, bbPos.y + move) - PLAY_AGAIN_BUTTON.HEIGHT;
        float buttonStencil = step(smax(xd, yd, .025), 0.);
        color = blend(color, vec4(vec3(.6, .4, .2), buttonStencil));
        playAgainWord(color, (uv - PLAY_AGAIN_BUTTON.xy - vec2(0., move + .07)) * 4., 0.);
    }

    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    fragColor = vec4(gameScene(fragCoord), 1.);
    vec4 uiOverlay = ui(fragCoord);
    fragColor.rgb = mix(fragColor.rgb, uiOverlay.rgb, uiOverlay.a);
}

/*
#define SS 1
void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    fragColor = vec4(0.);
    for(int y = ZERO; y < SS; ++y)
        for(int x = ZERO; x < SS; ++x){
            fragColor.rgb += clamp(color(fragCoord + vec2(x, y) / float(SS)), 0., 1.);
        }
    
    fragColor.rgb /= float(SS * SS);
}
*/