// Image (image) — Paper Plane by zduny
// https://www.shadertoy.com/view/tstczS

INCLUDE_TEXTURE_GRID_WIDTH
INCLUDE_GAME_CONSTANTS
INCLUDE_STATE_STRUCT
INCLUDE_STATE_LOAD_FUNCTION

const bool showTexture = false;

const vec3 background = vec3(0.454, 0.672, 0.984);

const float aspectRatio = 8.0 / 16.0;
const float top = 1.0 / aspectRatio;

State state;
vec3 letterColor;

vec4 blend(in vec4 under, in vec4 over) {
  vec4 result = mix(under, over, over.a);
  result.a = over.a + under.a * (1.0 - over.a);
    
  return result;
}

vec2 fixUv(in vec2 uv) {
  uv = clamp(uv, 0.0, 1.0);
  uv.x *= iResolution.y / iResolution.x;
  return uv;
}

vec4 getPipeTexture(in vec2 uv) {
  return texture(iChannel1, fixUv(uv) / float(textureGridWidth));
}

vec4 getPlaneTexture(in float angle, in vec2 uv) {
  float total = float(textureGridWidth * textureGridWidth - 2);  
  float i = round((angle + 0.5) * total + 1.0);
  
  uv = fixUv(uv);
  uv.x += iResolution.y / iResolution.x * mod(i, float(textureGridWidth));
  uv.y += floor(i / float(textureGridWidth));
  
  return texture(iChannel1, uv / float(textureGridWidth));
}

void drawLetter(inout vec4 fragColor, in vec2 fragCoord, 
                in vec2 position, in vec2 size, in int code) {
  vec2 uv = fragCoord - position;
  uv += size * 0.5;
  uv /= size;
  
  if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
    uv.x += float(code % 16);
    uv.y += float(15 - code / 16);
    
    uv *= 0.0625;
    
    float sd = abs(texture(iChannel2, uv).a);
    fragColor = blend(fragColor, 
      vec4(vec3(0.0), smoothstep(0.0, 1.0, (0.55 - sd) * 50.0)));
    fragColor = blend(fragColor, 
      vec4(letterColor, smoothstep(0.0, 1.0, (0.51 - sd) * 50.0)));
  }
}

float elasticOut(float t) {
  return sin(-13.0 * (t + 1.0) * 3.1416 * 0.5) * pow(2.0, -10.0 * t) + 1.0;
}

float cubicIn(float t) {
  return t * t * t;
}

float cubicOut(float t) {
  float f = t - 1.0;
  return f * f * f + 1.0;
}

const float HALF_PI = 3.1416 * 0.5;
float elasticInOut(float t) {
  return t < 0.5
    ? 0.5 * sin(+13.0 * HALF_PI * 2.0 * t) * pow(2.0, 10.0 * (2.0 * t - 1.0))
    : 0.5 * sin(-13.0 * HALF_PI * ((2.0 * t - 1.0) + 1.0)) * pow(2.0, -10.0 * (2.0 * t - 1.0)) + 1.0;
}

void drawPipes(inout vec4 fragColor, in vec2 fragCoord, 
               in vec2 position, in float gap) {   
  float size = pipeSize;

  vec2 uv = fragCoord - position;
  if (uv.x > 0.0) {
    uv.x *= -1.0;
  }
  uv += size * 0.5;
  uv.x += size * 0.21 + gap;
  uv /= size;
  
  fragColor = blend(fragColor, getPipeTexture(uv));
}

void drawAllPipes(inout vec4 fragColor, in vec2 fragCoord) {
  vec4 outColor = fragColor;

  for (int i = 0; i < pipesCount; i++) {
    Gap gap = state.gaps[i];
    vec2 position = vec2(gap.position, 
      pipesStart + state.pipesOffset + float(i) * pipesGap);
    drawPipes(outColor, fragCoord, position, gap.size);
  }
  
  float time = clamp(max(iTime, state.animationTime) * 1.5, 0.0, 1.0);
  fragColor = mix(fragColor, outColor, cubicIn(time));
}

#define INCLUDE_DRAW_STRING_FUNCTION(name, arrayName, arrayLength)         \
  void name(inout vec4 fragColor, in vec2 fragCoord, float offset) {       \
    float size = 1.0 / float(arrayLength);                                 \
                                                                           \
    fragCoord.y -= top - size * (1.0 + offset) - 0.2;                      \
    fragCoord *= 1.08;                                                     \
    fragCoord.x = clamp(fragCoord.x, -1.0, 1.0);                           \
    fragCoord.x += 1.0;                                                    \
    fragCoord *= 0.5;                                                      \
                                                                           \
    int code = arrayName[int(fragCoord.x / size - 0.01)];                  \
    fragCoord.x = mod(fragCoord.x, size) - size * 0.5;                     \
                                                                           \
    drawLetter(fragColor, fragCoord, vec2(0.0), vec2(size * 1.4), code);   \
  }

const int paperLength = 5;
const int[] paperLetters = int[](80, 65, 80, 69, 82);

const int planeLength = 5;
const int[] planeLetters = int[](80, 76, 65, 78, 69);

INCLUDE_DRAW_STRING_FUNCTION(drawPaper, paperLetters, paperLength)
INCLUDE_DRAW_STRING_FUNCTION(drawPlane, planeLetters, planeLength)

void drawLogo(inout vec4 fragColor, in vec2 fragCoord) {
  if (state.animationState >= STATE_IN_GAME) {
    return;
  }

  bool inAnimation = state.animationState <= STATE_MENU;
  float animationTime = state.animationTime;
  
  float time = clamp(animationTime * 1.1, 0.0, 1.0);
  float position = inAnimation 
    ? mix(-8.0, 0.0, elasticOut(time))
    : mix(0.0, -8.0, cubicIn(time));
    
  letterColor = vec3(1.0);
  drawPaper(fragColor, fragCoord, position - 0.5);
  drawPlane(fragColor, fragCoord, position + 2.0);
}

void drawScore(inout vec4 fragColor, in vec2 fragCoord) {
  if (state.animationState < STATE_IN_GAME && state.highScore == 0) {
    return;
  }

  bool inAnimation = state.animationState <= STATE_MENU;
  float animationTime = state.animationTime;
  
  float time = state.animationState == STATE_GAME_OVER 
    ? 1.0
    : clamp(animationTime * (inAnimation ? 1.2 : 0.5) - 0.1, 0.0, 1.0);
  float y = inAnimation
    ? mix(2.0, 0.0, elasticOut(time))
    : mix(0.0, 1.55, elasticInOut(time));
  
  float size = 0.27;
  
  int[] scoreString = int[](0, 0, 0, 0, 0, 0, 0);
  int scoreLength = 0;
  int score;
  if (state.animationState <= STATE_MENU) {
    score = state.highScore;
  } else if (state.animationState == STATE_OUTRO && time < 0.7) {
    score = int(mix(float(state.highScore), 0.0, clamp((time - 0.5) * 4.0, 0.0, 1.0)));
  } else if (state.animationState == STATE_OUTRO) {
    score = 0;
  }else if (state.animationState >= STATE_IN_GAME) {
    score = state.score;
  }
  for (int i = 0; i < 6; i++) {
    scoreString[i] = 48 + score % 10;
    scoreLength++;
    score = score / 10;
    if (score == 0) {
      break;
    }
  }
  
  letterColor = 
    (state.animationState >= STATE_IN_GAME && state.score <= state.highScore) ||
    (state.animationState == STATE_OUTRO && time > 0.5)
    ? vec3(1.0)
    : vec3(1.0, 1.0, 0.7);
    
  vec4 outColor = vec4(0.0);
  float letterWidth = size * 0.8;
  for (int i = 0; i < scoreLength; i++) {
    vec2 position = vec2(0.0 + float(scoreLength - i - 1) * letterWidth, y + 0.21);
    position.x -= float(scoreLength) * 0.5 * letterWidth - letterWidth * 0.48;
    drawLetter(outColor, fragCoord, position, vec2(size * 1.4), scoreString[i]);
  }
  
  if (state.animationState == STATE_IN_GAME && state.highScore == 0) {
    outColor.a *= cubicIn(clamp((state.animationTime - 4.0) * 3.0, 0.0, 1.0));
  }
  if (state.animationState == STATE_GAME_OVER && 
      state.score < 2 && 
      state.highScore == 0) {
    outColor.a = 0.0;
  }
  fragColor = blend(fragColor, outColor);
}

void drawPaperPlaneButton(inout vec4 fragColor, in vec2 fragCoord, 
                          in vec2 position, bool shadow) {
  vec2 size = vec2(shadow ? 0.71 : 0.68);
  
  position -= fragCoord;
  position += size * 0.5;
  
  position /= size;
  float tmp = position.x;
  position.x = 1.0 - position.y;
  position.y = tmp;
  
  vec4 color = getPlaneTexture(0.0, position);
  
  fragColor = blend(fragColor, shadow ? vec4(vec3(0.2), color.a * 0.5) : color);
}

void drawPlayButton(inout vec4 fragColor, in vec2 fragCoord) {
  if (state.animationState >= STATE_IN_GAME) {
    return;
  }

  vec2 position = vec2(0.0, -1.0);
  
  bool inAnimation = state.animationState <= STATE_MENU;
  float animationTime = state.animationTime;
  float time = clamp(animationTime * 1.2, 0.0, 1.0);
  
  vec2 circlePosition = inAnimation
    ? mix(position - vec2(0.0, 3.0), position, elasticOut(animationTime))
    : mix(position, position - vec2(0.0, 3.0), cubicIn(animationTime));
  
  const float radius = 0.45;
  float sd = distance(circlePosition, fragCoord);
  
  fragColor = blend(fragColor, 
    vec4(vec3(0.0), smoothstep(1.0, 0.0, (sd - radius - 0.02) * 100.0)));
  fragColor = blend(fragColor, 
    vec4(vec3(0.0, 0.0, 0.85), smoothstep(1.0, 0.0, (sd - radius) * 100.0)));

  position += vec2(0.01, 0.02);
  
  time = clamp(animationTime * (inAnimation ? 3.0 : 2.0), 0.0, 1.0);
  
  vec2 shadowPosition = inAnimation
    ? mix(position - vec2(2.7, 0.0), position, cubicOut(time))
    : mix(position, position + vec2(2.7, 0.0), cubicIn(time));
  
  if (state.isPlayPressed) {
    position.y -= 0.025;
  }
  vec2 planePosition = inAnimation
    ? mix(position - vec2(3.0, 0.0), position, cubicOut(time))
    : mix(position, position + vec2(3.0, 0.0), cubicIn(time));
    
  vec4 shadow = vec4(0.0);
  drawPaperPlaneButton(shadow, fragCoord, shadowPosition + vec2(0.0, -0.03), true);
  shadow.a *= smoothstep(1.0, 0.0, (sd - radius - 0.02) * 100.0);
  fragColor = blend(fragColor, shadow);
  
  drawPaperPlaneButton(fragColor, fragCoord, planePosition, false);
}

void drawPlane(inout vec4 fragColor, in vec2 fragCoord) {
  if (state.animationState < STATE_OUTRO) {
    return;
  }
  
  vec2 size = vec2(planeSize);
  vec2 position = state.plane.position;
  
  position -= fragCoord;
  position += size * 0.5;
  
  position /= size;
  position.y = 1.0 - position.y;
  
  vec4 color = getPlaneTexture(state.plane.angle, position);
  
  fragColor = blend(fragColor, color);
}

void normalizeFragCoord(inout vec2 fragCoord) {
  fragCoord -= iResolution.xy * 0.5;
  fragCoord /= iResolution.y * 0.5;
  fragCoord /= aspectRatio;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {  
  fragColor = vec4(vec3(0.0), 1.0);
  
  if (showTexture) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = vec4(background, 1.0);
    fragColor = blend(fragColor, texture(iChannel1, uv));
    return;
  }
  
  normalizeFragCoord(fragCoord);
  bool inFrame = abs(fragCoord.x) < 1.0;
  if (inFrame) {
    state = loadState(); 
    fragColor = vec4(background, 1.0);
    drawAllPipes(fragColor, fragCoord);
    drawLogo(fragColor, fragCoord);
    drawPlayButton(fragColor, fragCoord);
    drawPlane(fragColor, fragCoord);
    drawScore(fragColor, fragCoord);
  }
}