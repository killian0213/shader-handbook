// Buffer A (buffer) — BattleShips by skaplun
// https://www.shadertoy.com/view/7dscD2

float time;

struct {
    bool mouseDown;
    bool clickedThisFrame;
    bool releasedThisFrame;
} mouseState;


bool intersects(int a, int b){
    Boat boatA = boatFromId(a);
    vec2 boatAPos = texelFetch(iChannel0, ivec2(a, SHIP_POSITION_LINE), 0).rb;
    boatAPos.x -= boatOffsetsFromPos(a).x;
    
    Boat boatB = boatFromId(b);
    vec2 boatBPos = texelFetch(iChannel0, ivec2(b, SHIP_POSITION_LINE), 0).rb;
    boatBPos.x -= boatOffsetsFromPos(b).x;

    if(boatAPos.y < floor(boatBPos.y) - 1. || 
       boatAPos.y > ceil(boatBPos.y) + 1.)
       return false;

    float boatASpan =  boatSpanFromId(a);
    float boatBSpan =  boatSpanFromId(b);

    float aLeft = boatAPos.x - step(1.5, boatASpan);
    float aRight = boatAPos.x + boatASpan - step(1.5, boatASpan);

    float bLeft = floor(boatBPos.x) - step(1.5, boatBSpan) - 1.;
    float bRight = ceil(boatBPos.x) + boatBSpan - step(1.5, boatBSpan) + 1.;

    if(aRight < bLeft || aLeft > bRight)
       return false;

    return true;
}

bool insideGameField(int id){
    vec2 boatAPos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0).rb;
    return abs(boatAPos.y) <= 5.;
}

bool allInsideGameField(){
    for(int i=ZERO; i<SHIPS_CNT; i++){
        if(!insideGameField(i)){
            return false;
        }
    }
    return true;
}

bool canDropHere(int id){
    Boat boatA = boatFromId(id);
    vec2 boatAPos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0).rb;
    boatAPos.x -= boatOffsetsFromPos(id).x;
    
    float boatASpan =  boatSpanFromId(id);
    float aLeft = boatAPos.x - step(1.5, boatASpan);
    float aRight = boatAPos.x + boatASpan - step(1.5, boatASpan);
    
    if(aLeft < -5. || aRight > 5.)
        return false;

    for(int i=ZERO; i<SHIPS_CNT; i++){
        if(id != i){
            if(insideGameField(i) && intersects(id, i)){
                return false;
            }
        }
    }
    return true;
}

vec3 startingRotations(int id){
    return vec3(0., QPI * .5, 0.);
}

vec4 calcPosition(int id, vec2 mouseHitPos, vec2 mouseHitCell){
    float color = .5;
    Boat boat = boatFromId(id);
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    if(iFrame == 0 || gameState.x == float(GAME_STATE_START)){
        if(boat.boatType != 3){
            vec3 res = boat.boundingBox.o;
            float rad = 8.;
            float ang = startingRotations(id).y - HPI - PI;
            res.xz -= vec2(rad * sin(ang), rad * cos(ang));
            return vec4(res, color);
        }else{
            vec3 res = boat.boundingBox.o;
            res.y -= 4.;
            return vec4(res, color);
        }
    }else{
        vec4 pos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0);
        vec4 interaction = texelFetch(iChannel0, ivec2(id, SHIP_INTERACTION_LINE), 0);
        if(interaction.PRESSED == 1.){
            vec2 dstPoint = mouseHitCell + boatOffsetsFromPos(id);
            pos.rb = mix(pos.rb, dstPoint, iTimeDelta * 20.);
            pos.y = .5 + .5 * step(3.25, float(id));
            if(!canDropHere(id))
                color = 0.;
        }else if(interaction.RELEASE_TIME != 0.){
            float diff = distance(time, interaction.RELEASE_TIME);
            float y = 1. - easeOutElastic(diff * .5) + boat.boundingBox.o.y;
            vec3 dest  = vec3((interaction.DEST_POINT).x, y, (interaction.DEST_POINT).y);
            pos.xyz = mix(pos.xyz, dest, diff);
        }
        return vec4(pos.rgb, color);
    }
}

vec4 calcRotation(int id, vec2 mouseHitCell){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    if(iFrame == 0 || gameState.x == float(GAME_STATE_START)){
        return vec4(startingRotations(id), 1.);
    }else{
        vec4 pos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0);
        vec4 rots = texelFetch(iChannel0, ivec2(id, SHIP_ROTATION_LINE), 0);
        vec4 interaction = texelFetch(iChannel0, ivec2(id, SHIP_INTERACTION_LINE), 0);
        float pressed = interaction.PRESSED;
        if(pressed == 1.){
            vec2 defaultPos = boatFromId(id).boundingBox.o.xz;
            float total = max(abs(defaultPos.x), abs(defaultPos.y)) - 4.5;
            vec2 pos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0).xz;
            float cur = max(abs(pos.x), abs(pos.y)) - 4.5;
            rots.xyz = vec3(0.);
        }else if(interaction.RELEASE_TIME != 0. && (interaction.DEST_POINT).y > 5.){
            float diff = distance(time, interaction.RELEASE_TIME);
            rots = mix(rots, vec4(startingRotations(id), 1.), diff);
        }else{
            rots.x = noised(pos.xz + iTime * .5).x * .1;
            rots.z = noised(pos.xz + (iTime + 134.) * .5).x * .1;
        }
        
        return rots;
    }
}

bool buttonClicked(vec4 button){
    vec2 m = iMouse.xy/iResolution.y;
    return mouseState.releasedThisFrame && (distance(m.x, button.CENTER_X) <= button.WIDTH && distance(m.y, button.CENTER_Y) <= button.HEIGHT);
}

vec4 interaction(int id, vec2 mouseCell, Ray mouseRay){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    if(iFrame == 0 || gameState.x == float(GAME_STATE_START)){
        Boat b = boatFromId(id);
        return vec4(0., max(iTime, (float(b.boatType)) * .1), boatFromId(id).boundingBox.o.xz);
    }
    
    if(buttonClicked(RANDOM_BUTTON)){
        vec2 dst = vec2(0., 0.);
        switch(id){
            default:break;
        }
        return vec4(0., time, dst);
    }
    
    vec4 interaction = texelFetch(iChannel0, ivec2(id, SHIP_INTERACTION_LINE), 0);
    float dragging = interaction.PRESSED;
    
    if(!mouseState.mouseDown){
        if(length(interaction.DEST_POINT) == 0.){
            vec2 dstPos = mouseCell + boatOffsetsFromPos(id);
            if(!canDropHere(id)){
                Boat b = boatFromId(id);
                dstPos = b.boundingBox.o.xz;
            }
            interaction.DEST_POINT = dstPos;
        }
        
        
        if(interaction.RELEASE_TIME == 0.)
            return vec4(0., time * dragging, interaction.DEST_POINT);
        else
            return vec4(0., interaction.RELEASE_TIME * step(distance(interaction.RELEASE_TIME, time), 1.), interaction.DEST_POINT);
    }
    if(dragging == 0. && mouseState.clickedThisFrame){
        float minDist = MAX_FLOAT;
        int minID = 100;
        for(int i=ZERO; i<SHIPS_CNT; i++){
            Boat boat = boatFromId(i);
            boat.boundingBox.o.xz = texelFetch(iChannel0, ivec2(i, SHIP_POSITION_LINE), 0).rb;
            vec3 rots = texelFetch(iChannel0, ivec2(i, SHIP_ROTATION_LINE), 0).xyz;

            mat4 rot = mat4(ry(rots.y));
            mat4 tra = translate(boat.boundingBox.o);
            mat4 txi = tra * rot;
            mat4 txx = inverse(txi);

            vec2 boxHitDst = iBox(mouseRay, boat.boundingBox, txx, txi);
            if(boxHitDst.x >= 0. && boxHitDst.x < minDist){
                minDist = boxHitDst.x;
                minID = i;
            }
            if(minID == id)
                return vec4(1., 0., 0., 0.);
        }
    }
    return vec4(dragging, 0., 0., 0.);
}

bool validShot(Ray mouseRay, out vec2 hitCell){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    bool res = gameState.x == float(GAME_STATE_AIMING) && (gameState.w == 1.) && !mouseState.mouseDown;
    if(!res)
        return false;
    float warFogDist = (-mouseRay.o.y)/mouseRay.dir.y;
    vec2 warFogHitCell = floor((mouseRay.o + mouseRay.dir * warFogDist).xz - vec2(16., -5.));
    warFogHitCell.y = 10. - warFogHitCell.y;
    hitCell = vec2(warFogHitCell.x, iResolution.y - warFogHitCell.y);
    vec4 hitCellOcupation = texelFetch(iChannel0, ivec2(hitCell), 0);
    
    return hitCellOcupation.w < 0.;
}

float distanceToBoat(vec2 toGameFieldCenter, int id){
    vec2 curBoatPos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0).rb - boatOffsetsFromPos(id);
    float curBoatSpan =  boatSpanFromId(id);

    float left = curBoatPos.x - step(1.5, curBoatSpan);
    float right = curBoatPos.x + curBoatSpan - step(1.5, curBoatSpan);
    
    float res = distance(toGameFieldCenter.y, curBoatPos.y);
    float midX = (left + right) * .5;
    res = max(res, distance(toGameFieldCenter.x, midX) - max(0., curBoatSpan * .5));
    return res;
}

bool boatAllCellsHit(int id){
    vec2 curBoatPos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0).rb - boatOffsetsFromPos(id);
    float curBoatSpan =  boatSpanFromId(id);

    float left = curBoatPos.x - step(1.5, curBoatSpan);
    float right = curBoatPos.x + curBoatSpan - step(1.5, curBoatSpan);
    
    for(float x = left; x <= right; x++){
        vec2 coords = floor(vec2(x, curBoatPos.y)) + vec2(5.);
        coords.y = 10. - coords.y;
        ivec2 hitCell = ivec2(coords.x, iResolution.y - coords.y);
        vec4 curGameField = texelFetch(iChannel0, hitCell, 0);
        
        if(curGameField.w < 0.)
            return false;
    }
    return true;
}


#define INCLUDE_COUNT_FUNC(name, count, ids) float name(int field){                                                                       \
    float totalVal = 0.;                                                                                                         \
    for(int i=ZERO; i<count; i++){                                                                                                  \
        int id = ids[i];                                                                                                         \
        vec2 curBoatPos = texelFetch(iChannel0, ivec2(id, SHIP_POSITION_LINE), 0).rb - boatOffsetsFromPos(id);                   \
        float curBoatSpan =  boatSpanFromId(id);                                                                                 \
        float left = curBoatPos.x - step(1.5, curBoatSpan);                                                                      \
        float right = curBoatPos.x + curBoatSpan - step(1.5, curBoatSpan);                                                       \
        for(float x = left; x <= right; x++){                                                                                    \
            vec2 coords = floor(vec2(x, curBoatPos.y)) + vec2(5.);                                                               \
            coords.y = 10. - coords.y;                                                                                           \
            ivec2 hitCell = ivec2(coords.x, iResolution.y - coords.y);                                                           \
            vec4 curGameField = texelFetch(iChannel0, hitCell, 0);                                                               \
            if(curGameField[field] >= 0.)                                                                                             \
                totalVal += saturate(iTime - curGameField[field]);                                                                    \
        }                                                                                                                        \
    }                                                                                                                            \
    return totalVal;                                                                                                             \
}                                                                                                                                \

INCLUDE_COUNT_FUNC(countDamage1, 4, ivec4(0, 1, 2, 3))
INCLUDE_COUNT_FUNC(countDamage2, 3, ivec4(4, 5, 6, -1))
INCLUDE_COUNT_FUNC(countDamage3, 2, ivec4(7, 8, -1, -1))
INCLUDE_COUNT_FUNC(countDamage4, 1, ivec4(9, -1, -1, -1))

bool allHit(int id){
    return countDamage1(id) > 3. &&
           countDamage2(id) > 5. &&
           countDamage3(id) > 5. &&
           countDamage4(id) > 3.;
}

vec4 gameState(int id, Ray mouseRay){
    if(iFrame == 0){
        return vec4(GAME_STATE_POSITIONING, 0., GAME_STATE_POSITIONING, 0.);
    }
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    int prevGameState = int(gameState.x);
    switch(prevGameState){
        case GAME_STATE_START:
            gameState.xy = vec2(GAME_STATE_POSITIONING, iTime);
        case GAME_STATE_POSITIONING:
            if(allInsideGameField()){
                gameState.x = float(GAME_STATE_READY_TO_PLAY);
            }
            break;
        case GAME_STATE_READY_TO_PLAY:
            if(!allInsideGameField()){
                gameState.x = float(GAME_STATE_POSITIONING);
            }else if(buttonClicked(BATTLE_BUTTON)){
                gameState.x = float(GAME_STATE_AIMING);
                gameState.y = iTime;
            }
            break;
        case GAME_STATE_AIMING:
            vec2 hitCell = vec2(0.);
            if(validShot(mouseRay, hitCell)){
                gameState.xy = vec2(float(GAME_STATE_FIRE), iTime);
            }
            
#ifdef RENDER_SWAP_BTN
            if(buttonClicked(SWAP_BUTTON)){
                gameState.x = float(GAME_STATE_ENEMY_TURN);
                gameState.y = iTime;
            }
#endif
            break;
        case GAME_STATE_FIRE:
            if(iTime - gameState.y > 1.){
                vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
                if(lastMove.x >= 0.)
                    gameState.xy = vec2(float(GAME_STATE_AIMING), iTime - 1.);
                else
                    gameState.xy = vec2(float(GAME_STATE_ENEMY_TURN), iTime);
            }
            
            if(allHit(3)){
                gameState.x = float(GAME_STATE_END);
                gameState.y = iTime;
            }

            break;
        case GAME_STATE_ENEMY_TURN:
            if(iTime - gameState.y > 1.){
                gameState.xy = vec2(float(GAME_STATE_ENEMY_FIRE), iTime);
            }
            
            break;
        case GAME_STATE_ENEMY_FIRE:
            bool timeUp = iTime - gameState.y > 1.;
            vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
            if(lastMove.x >= 0. && timeUp)
                gameState.xy = vec2(float(GAME_STATE_ENEMY_FIRE), iTime);
            else if(timeUp)
                gameState.xy = vec2(float(GAME_STATE_AIMING), iTime);

#ifdef RENDER_SWAP_BTN
            if(buttonClicked(SWAP_BUTTON)){
                gameState.x = float(GAME_STATE_END);
                gameState.y = iTime;
            }
#endif
            
            
            if(allHit(2) && saturate(iTime - gameState.y) > .5){
                gameState.x = float(GAME_STATE_END);
                gameState.y = iTime;
            }

            break;
        case GAME_STATE_END:
            if(buttonClicked(PLAY_AGAIN_BUTTON)){
                gameState.x = float(GAME_STATE_START);
                gameState.y = iTime;
            }
            break;
        default:
            break;
    }
    if(gameState.x != float(prevGameState))
        gameState.z = float(prevGameState);
    gameState.w = mouseState.mouseDown ? 1. : 0.;
    return gameState;
}

vec4 gameField(vec2 coords, vec2 toGameFieldCenter, Ray mouseRay){
    vec4 gameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    if(iFrame == 0 || gameState.x == float(GAME_STATE_START)){
            return vec4(-1.);
    }
    vec4 curGameField = texelFetch(iChannel0, ivec2(coords), 0);
    switch(int(gameState.x)){
        case GAME_STATE_POSITIONING:
        case GAME_STATE_READY_TO_PLAY:
            {
                curGameField.y = -1.;
                int shipsIntersecCount = 0;
                float val = 0.;
                for(int i=ZERO; i<SHIPS_CNT; i++){
                    vec2 curBoatPos = texelFetch(iChannel0, ivec2(i, SHIP_POSITION_LINE), 0).rb - boatOffsetsFromPos(i);
                    float curBoatSpan =  boatSpanFromId(i);

                    float left = curBoatPos.x - step(1.5, curBoatSpan);
                    float right = curBoatPos.x + curBoatSpan - step(1.5, curBoatSpan);
                    float top = curBoatPos.y;
                    float bottom = curBoatPos.y;

                    if(toGameFieldCenter.y < ceil(top + 1.) &&
                       toGameFieldCenter.y > floor(bottom - 1.) &&
                       toGameFieldCenter.x > floor(left - 1.) && 
                       toGameFieldCenter.x < ceil(right + 1.))
                           val += float(i) * pow(10., float(shipsIntersecCount++));

                    if(toGameFieldCenter.y == curBoatPos.y &&
                       toGameFieldCenter.x >= left && toGameFieldCenter.x <= right){
                           curGameField.y = float(i);
                    }
                }
                if(shipsIntersecCount > 0)
                    return vec4(val + float(shipsIntersecCount) * .1, curGameField.y, curGameField.z, curGameField.w);
                else
                    return vec4(-1., curGameField.y, curGameField.z, curGameField.w);
            }
            break;
        case GAME_STATE_AIMING:
            vec2 hitPoint = vec2(0.);
            if(validShot(mouseRay, hitPoint)){
                if(floor(coords) == hitPoint){
                    curGameField.w = iTime;
                }
            }
            break;
        case GAME_STATE_FIRE:
            {
                vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
                int lastHitId = int(lastMove.x);
                if(lastHitId >= 0 && boatAllCellsHit(lastHitId)){
                    if(distanceToBoat(toGameFieldCenter, lastHitId) <= 1. && curGameField.w < 0.){
                        curGameField.w = lastMove.y;
                    }
                }
            }
            break;
        case GAME_STATE_ENEMY_FIRE:
            {
                if(curGameField.z < 0.){
                    vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
                    vec2 cell = floor(lastMove.zw) + 5.;
                    cell.y = 10. - cell.y;
                    
                    if(ivec2(coords) == ivec2(vec2(cell.x, iResolution.y - cell.y))){
                        curGameField.z = lastMove.y;
                    }
                }
            }
            break;
        default:
            break;
    }
    return curGameField;
}

float shipAtPos(vec2 toGameFieldCenter){
    ivec2 cellId = ivec2(toGameFieldCenter + 5.);
    cellId.y = 10 - cellId.y;
    return texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0).y;
}

bool alreadyHit(vec2 toGameFieldCenter){
    ivec2 cellId = ivec2(toGameFieldCenter + 5.);
    cellId.y = 10 - cellId.y;
    return texelFetch(iChannel0, ivec2(cellId.x, int(iResolution.y) - cellId.y), 0).z >= 0.;
}

vec4 lastMove(Ray mouseRay){
    vec4 savedGameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    if(iFrame == 0 || savedGameState.x == float(GAME_STATE_START))
        return vec4(-1.);
    vec4 lastMove = texelFetch(iChannel0, ivec2(0, LAST_SHOT_LINE), 0);
    int curGameState = int(savedGameState.x);
    int prevGameState = int(savedGameState.z);
    if(curGameState == GAME_STATE_AIMING){
        vec2 mouseHitCell;
        if(validShot(mouseRay, mouseHitCell)){
            float oceanHitDist = (-mouseRay.o.y)/mouseRay.dir.y;
            vec2 oceanHitCell = floor((mouseRay.o + mouseRay.dir * oceanHitDist).xz) + .5;
            
            vec4 hitCellOcupation = texelFetch(iChannel0, ivec2(mouseHitCell), 0);
            return vec4(hitCellOcupation.y, iTime, oceanHitCell);
        }
    } else if (curGameState == GAME_STATE_ENEMY_FIRE){
        vec2 hitCell = floor(hash(vec2(2.17, savedGameState.y)) * 5.);
        int counter = 0;
        while(alreadyHit(hitCell) && counter++<25){
            hitCell = floor(hash(vec2(.17, savedGameState.y)) * 5.);
        }
        
        float shipId = shipAtPos(hitCell);
        return vec4(shipId, savedGameState.y, hitCell);
    }
    return lastMove;
}

vec4 buttons(int id){
    vec4 curState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    vec4 res = vec4(0.);
    switch(id){
        case BUTTONS_BATTLE_ID:
            if(iFrame == 0 || curState.x == float(GAME_STATE_START)){
                return vec4(-1.);
            }
            vec4 curButton = texelFetch(iChannel0, ivec2(BUTTONS_BATTLE_ID, BUTTONS_LINE), 0);
            float visibility = curButton.y == -BATTLE_BUTTON.CENTER_X ? 0.: 1.;
            float dstPos = -BATTLE_BUTTON.CENTER_X;
            if(int(curState.x) == GAME_STATE_READY_TO_PLAY){
                dstPos = BATTLE_BUTTON.CENTER_X;
            }
            float curPos = mix(curButton.y, dstPos, iTimeDelta * 20.);
            return vec4(visibility, curPos, dstPos, 0.);
            break;
        default:
        break;
    }
    return vec4(0.);
}

vec4 countDamageLine(int field){
    if(iFrame == 0)
        return vec4(0.);
    return vec4(countDamage1(field), countDamage2(field), countDamage3(field), countDamage4(field));
}

#define GAME_FIELD_CELLS_CNT_HLF 5.
#define GAME_FIELD_CENTER vec2(GAME_FIELD_CELLS_CNT_HLF, iResolution.y - GAME_FIELD_CELLS_CNT_HLF)

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    vec4 lastGameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    time = iTime;
    mouseState.mouseDown = iMouse.z > 0.;
    mouseState.clickedThisFrame = mouseState.mouseDown && iMouse.w >= 0.;
    mouseState.releasedThisFrame = (lastGameState.w == 1.) && !mouseState.mouseDown;

    vec4 savedGameState = texelFetch(iChannel0, ivec2(0, GAME_STATE_LINE), 0);
    Ray cameraRay = createRay(fragCoord, iResolution.xy, iTime, savedGameState);
    Ray mouseRay = createRay(iMouse.xy, iResolution.xy, iTime, savedGameState);
    float mouseHitOcean = (-mouseRay.o.y)/mouseRay.dir.y;
    vec3 mouseHitPoint = (mouseRay.o + mouseRay.dir * mouseHitOcean);
    vec2 mouseHitCell = clamp(floor(mouseHitPoint.xz) + .5, -4.5, 4.5);
    
    ivec2 id = ivec2(fragCoord);
    vec4 res = texelFetch(iChannel0, id, 0);
    if(int(lastGameState.x) == GAME_STATE_POSITIONING || int(lastGameState.x) == GAME_STATE_READY_TO_PLAY || int(lastGameState.x) == GAME_STATE_START){
        if(id.x < SHIPS_CNT && id.y < SHIP_TOTAL_LINES){
            switch(id.y){
                case SHIP_POSITION_LINE:
                    res = calcPosition(id.x, mouseHitPoint.xz, mouseHitCell);
                    break;
                case SHIP_ROTATION_LINE:
                    res = calcRotation(id.x, mouseHitCell);
                    break;
                case SHIP_INTERACTION_LINE:
                    res = interaction(id.x, mouseHitCell, mouseRay);
                    break;
                default:
                    break;
            }
        }
    }
    
    vec2 toGameFieldCenter = fragCoord - GAME_FIELD_CENTER;
    if(max(abs(toGameFieldCenter.x), abs(toGameFieldCenter.y)) <= GAME_FIELD_CELLS_CNT_HLF){
        res = gameField(fragCoord, toGameFieldCenter, mouseRay);
    }
    
    if(id.x == 0 && id.y == GAME_STATE_LINE)
        res = gameState(id.x, mouseRay);
        
    if(id.x == 0 && id.y == LAST_SHOT_LINE)
        res = lastMove(mouseRay);
        
    if(id.x < 2 && id.y == ENEMY_HIT_COUNT_LINE)
        res = countDamageLine(id.x + 2);
        
    if(id.x <= BUTTONS_COUNT && id.y == BUTTONS_LINE)
        res = buttons(id.x);
    
    fragColor = res;
}