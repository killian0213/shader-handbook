// Buffer A (buffer) — Paper Plane by zduny
// https://www.shadertoy.com/view/tstczS

INCLUDE_GAME_CONSTANTS  
INCLUDE_STATE_STRUCT
INCLUDE_STATE_LOAD_FUNCTION
INCLUDE_STATE_SAVE_FUNCTION

#define KEY_SPACE 32
#define KEY_LEFT 37
#define KEY_RIGHT 39

float timeDelta() {
  return iTimeDelta * 1.0;
}

float random(float seed) {
  return fract(sin(seed) * 43758.5453123);
}

Gap randomGap(float seed) {
  Gap gap;
  
  gap.position = (random(seed) - 0.5) * 1.3;
  gap.size = 0.2 + random(seed * 0.37) * 0.3;
  
  return gap;
}

void initPlane(inout State state) {
  float side = random(iDate.w) < 0.5 ? -1.0 : 1.0;

  Plane plane;
  plane.position = startingPosition;
  plane.position.x *= side;
  plane.angle = startingAngle * side;
  state.plane = plane;
}

State initialState() {
  State state;
  
  state.oldResolution = iResolution.xy;
  state.newResolution = iResolution.xy;
  
  initPlane(state);
  
  state.animationState = STATE_INTRO;
  state.animationTime = 0.0;
  state.pipesOffset = 0.0;
  state.score = 0;
  state.highScore = 0;
  state.traveledDistance = 0.0;
  
  state.isPlayPressed = false;
  
  for (int i = 0; i < pipesCount; i++) {
    state.gaps[i] = randomGap(float(i));
  }
  
  return state;
}

void handlePlayButton(inout State state) {
  if (state.isPlayPressed && !isKeyDown(KEY_SPACE)) {
    state.animationState = STATE_OUTRO;
    state.animationTime = 0.0;
  }
  state.isPlayPressed = isKeyDown(KEY_SPACE);
}

float planeFall(in Plane plane) {
  float speed = timeDelta() * 2.0;
  return (0.9 - pow(abs(plane.angle), 1.4)) * speed;
}

void movePlane(inout Plane plane) {
  float speed = timeDelta() * 2.0;
  plane.position.x += plane.angle * speed;
  plane.position.y -= planeFall(plane);
}

vec2 planeHitbox(in Plane plane) {
  float angle = plane.angle * 2.1 + 3.1416 * 0.5;
  vec2 hitbox = plane.position - vec2(cos(angle), sin(angle)) * planeSize * 0.39;
  hitbox.y += planeSize * 0.05;
  return hitbox;
}

bool outOfBounds(in vec2 hitbox) {
  return hitbox.x < -1.0 || hitbox.x > 1.0; 
}

bool intersectsPipes(in vec2 hitbox, in State state) {
  for (int i = 0; i < pipesCount; i++) {
    Gap gap = state.gaps[i];
    vec2 position = vec2(gap.position, 
      pipesStart + state.pipesOffset + float(i) * pipesGap);
    float deltaY = abs(hitbox.y - position.y);
    if (deltaY < pipeSize * 0.25) {
      float deltaX = abs(hitbox.x - position.x);
      if (deltaX > gap.size) {
        return true;
      }
    }
  }

  return false;
}

State updateState(in State state) {
  state.oldResolution = state.newResolution;
  state.newResolution = iResolution.xy;
  
  switch (state.animationState) {
    case STATE_INTRO:
      if (state.score > state.highScore) {
        state.highScore = state.score;
      }
      state.pipesOffset += timeDelta();
      state.animationTime += timeDelta();
      if (state.animationTime > 0.5) {
        handlePlayButton(state);
      }
      if (state.animationTime >= 1.0) {
        state.animationState = STATE_MENU;
      }
      break;
    case STATE_MENU:
      state.pipesOffset += timeDelta();
      handlePlayButton(state);
      break;
    case STATE_OUTRO:
      movePlane(state.plane);
      if (state.animationTime > 0.6) {
        if (state.animationTime < 2.5) {
          state.pipesOffset = mix(state.pipesOffset, startingOffset, 0.05);
        } else {
          state.animationState = STATE_IN_GAME;
          state.traveledDistance = 0.0;
          state.score = 0;
        }
      } else {
        state.pipesOffset += timeDelta();
      }
      state.animationTime += timeDelta();
      break;
    case STATE_IN_GAME:
      if (isKeyDown(KEY_LEFT)) {
        state.plane.angle -= turningSpeed * timeDelta();
      }
      if (isKeyDown(KEY_RIGHT)) {
        state.plane.angle += turningSpeed * timeDelta();
      }
      state.plane.angle = clamp(state.plane.angle, -0.5, 0.5);
    
      movePlane(state.plane);
    
      if (state.plane.position.y < planeMinPosition) {
        float delta = abs(state.plane.position.y - planeMinPosition);
        state.pipesOffset += delta;
        state.traveledDistance += delta;
        state.plane.position.y = planeMinPosition;
      }
     
      state.score = int((state.traveledDistance - 0.45) / pipesGap);
      
      vec2 hitbox = planeHitbox(state.plane); 
      if (outOfBounds(hitbox) || intersectsPipes(planeHitbox(state.plane), state)) {
        state.animationState = STATE_GAME_OVER;
        state.animationTime = 0.0;
      }
      state.animationTime += timeDelta();
      break;
      
    case STATE_GAME_OVER:
      state.animationTime += timeDelta();
      float delta = planeFall(state.plane);
      state.pipesOffset += delta;
      state.plane.position.y += delta;
      
      if (state.animationTime > 1.0) {
        state.animationState = STATE_INTRO;
        state.animationTime = 0.0;
        initPlane(state);
      }
      break;
  }
  
  if (state.pipesOffset > pipesGap) {
    state.pipesOffset = mod(state.pipesOffset, pipesGap);
    for (int i = pipesCount - 1; i > 0; i--) {
      state.gaps[i] = state.gaps[i - 1];
    }
    state.gaps[0] = randomGap(iTime);
  }
  
  return state;
}
  
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  fragColor = vec4(0.0);
  fragmentCoordinates = ivec2(fragCoord).x;
  if (fragmentCoordinates < endOfData) {
    if (iFrame == 0) {
      saveState(initialState());
    } else {
      saveState(updateState(loadState()));
    }
    fragColor = outputColor;
  }
}
