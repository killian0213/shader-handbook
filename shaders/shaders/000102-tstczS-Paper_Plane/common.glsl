// Common (common) — Paper Plane by zduny
// https://www.shadertoy.com/view/tstczS

vec3 toLinear(in vec3 color) { return pow(color, vec3(2.2)); }
vec3 toSRGB(in vec3 color) { return pow(color, vec3(1.0 / 2.2)); }

#define INCLUDE_TEXTURE_GRID_WIDTH                                       \
  const int textureGridWidth = 6;

#define loadVariable(location)                                           \
  texelFetch(iChannel0, ivec2(location, 0), 0)

#define isKeyDown(keyCode)                                               \
  (texelFetch(iChannel1, ivec2(keyCode, 0), 0).x > 0.0)
 
const int resolutionLocation = 0; 
#define INCLUDE_GAME_CONSTANTS                                           \
  const int pipesCount = 6;                                              \
  const float pipeSize = 0.5;                                            \
  const float pipesStart = -2.5;                                         \
  const float pipesGap = 1.05;                                           \
  const float planeMinPosition = 1.0;                                    \
  const float planeSize = 0.5;                                           \
  const float turningSpeed = 2.0;                                        \
  const vec2 startingPosition = vec2(-3.0, 4.0);                         \
  const float startingAngle = 0.5;                                       \
  const float startingOffset = -3.2;                                     \
                                                                         \
  const int variousLocation = 1;                                         \
  const int planeDataLocation = 2;                                       \
  const int keysLocation = 3;                                            \
  const int pipesLocation = 4;                                           \
  const int endOfData = pipesLocation + pipesCount;
  
#define STATE_INTRO 0
#define STATE_MENU 1
#define STATE_OUTRO 2
#define STATE_IN_GAME 3
#define STATE_GAME_OVER 4
  
#define INCLUDE_STATE_STRUCT                                             \
  struct Gap {                                                           \
    float position;                                                      \
    float size;                                                          \
  };                                                                     \
                                                                         \
  struct Plane {                                                         \
    vec2 position;                                                       \
    float angle;                                                         \
  };                                                                     \
                                                                         \
  struct State {                                                         \
    vec2 oldResolution;                                                  \
    vec2 newResolution;                                                  \
    Plane plane;                                                         \
    int animationState;                                                  \
    float animationTime;                                                 \
    float pipesOffset;                                                   \
    int score;                                                           \
    int highScore;                                                       \
    float traveledDistance;                                              \
    bool isPlayPressed;                                                  \
    Gap[pipesCount] gaps;                                                \
  };
  
#define INCLUDE_STATE_LOAD_FUNCTION                                      \
  State loadState() {                                                    \
    State state;                                                         \
                                                                         \
    vec4 resolutionData = loadVariable(resolutionLocation);              \
    state.oldResolution = resolutionData.zw;                             \
    state.newResolution = resolutionData.xy;                             \
                                                                         \
    vec4 planeData = loadVariable(planeDataLocation);                    \
                                                                         \
    Plane plane;                                                         \
    plane.position = planeData.xy;                                       \
    plane.angle = planeData.z;                                           \
                                                                         \
    state.plane = plane;                                                 \
                                                                         \
    vec4 variousData = loadVariable(variousLocation);                    \
    state.animationState = int(variousData.x);                           \
    state.animationTime = variousData.y;                                 \
    state.pipesOffset = variousData.z;                                   \
    state.score = int(variousData.w);                                    \
                                                                         \
    vec4 keysData = loadVariable(keysLocation);                          \
    state.isPlayPressed = keysData.x > 0.0;                              \
    state.highScore = int(keysData.y);                                   \
    state.traveledDistance = keysData.z;                                 \
                                                                         \
    for (int i = 0; i < pipesCount; i++) {                               \
      vec2 pipesData = loadVariable(pipesLocation + i).xy;               \
                                                                         \
      Gap gap;                                                           \
      gap.position = pipesData.x;                                        \
      gap.size = pipesData.y;                                            \
                                                                         \
      state.gaps[i] = gap;                                               \
    }                                                                    \
                                                                         \
    return state;                                                        \
  }
  
#define INCLUDE_STATE_SAVE_FUNCTION                                      \
  int fragmentCoordinates = 0;                                           \
  vec4 outputColor = vec4(0.0);                                          \
                                                                         \
  void saveState(in State state) {                                       \
    switch (fragmentCoordinates) {                                       \
      case resolutionLocation:                                           \
        outputColor.xy = state.newResolution;                            \
        outputColor.zw = state.oldResolution;                            \
        return;                                                          \
      case planeDataLocation:                                            \
        outputColor.xy = state.plane.position;                           \
        outputColor.z = state.plane.angle;                               \
        return;                                                          \
      case variousLocation:                                              \
        outputColor.x = float(state.animationState);                     \
        outputColor.y = state.animationTime;                             \
        outputColor.z = state.pipesOffset;                               \
        outputColor.w = float(state.score);                              \
        return;                                                          \
      case keysLocation:                                                 \
        outputColor.x = state.isPlayPressed ? 1.0 : 0.0;                 \
        outputColor.y = float(state.highScore);                          \
        outputColor.z = state.traveledDistance;                          \
        return;                                                          \
    }                                                                    \
                                                                         \
    if (fragmentCoordinates >= pipesLocation &&                          \
        fragmentCoordinates < endOfData) {                               \
      int i = fragmentCoordinates - pipesLocation;                       \
                                                                         \
      Gap gap = state.gaps[i];                                           \
                                                                         \
      outputColor.x = gap.position;                                      \
      outputColor.y = gap.size;                                          \
    }                                                                    \
  }     


#define MS_STANDARD_1  vec2[](vec2(0.0))
#define MS_STANDARD_2  vec2[](vec2(-0.25), vec2(0.25))
#define MS_STANDARD_4  vec2[](                                           \
                         vec2(-0.125, -0.375), vec2(0.375, -0.125),      \
                         vec2(-0.375,  0.125), vec2(0.125,  0.375)       \
                       )
#define MS_STANDARD_8  vec2[](                                           \
                         vec2( 0.0625, -0.1875), vec2(-0.0625,  0.1875), \
                         vec2( 0.3125,  0.0625), vec2(-0.1875, -0.3125), \
                         vec2(-0.3125,  0.3125), vec2(-0.4375, -0.0625), \
                         vec2( 0.1875,  0.4375), vec2( 0.4375, -0.4375)  \
                       )
                            
#define MS_STANDARD_16 vec2[](                                           \
                         vec2( 0.0625,  0.0625), vec2(-0.0625, -0.1875), \
                         vec2(-0.1875,  0.125 ), vec2( 0.25  , -0.0625), \
                         vec2(-0.3125, -0.125 ), vec2( 0.125 ,  0.3125), \
                         vec2( 0.3125,  0.1875), vec2( 0.1875, -0.3125), \
                         vec2(-0.125 ,  0.375 ), vec2( 0.0   , -0.4375), \
                         vec2(-0.25  , -0.375 ), vec2(-0.375 ,  0.25  ), \
                         vec2(-0.5   ,  0.0   ), vec2( 0.4375, -0.25  ), \
                         vec2( 0.375 ,  0.4375), vec2(-0.4375, -0.5   )  \
                       )
                             
#define AA_1                                                             \
  const int sampleCount = 1;                                             \
  const vec2[] samplePositions = MS_STANDARD_1;

#define AA_2                                                             \
  const int sampleCount = 2;                                             \
  const vec2[] samplePositions = MS_STANDARD_2;

#define AA_4                                                             \
  const int sampleCount = 4;                                             \
  const vec2[] samplePositions = MS_STANDARD_4;

#define AA_8                                                             \
  const int sampleCount = 8;                                             \
  const vec2[] samplePositions = MS_STANDARD_8;

#define AA_16                                                            \
  const int sampleCount = 16;                                            \
  const vec2[] samplePositions = MS_STANDARD_16;

#define INCLUDE_SUPER_SAMPLE_FUNCTION(name, quality, takeSample)         \
  vec4 name(in vec2 fragCoord) {                                         \
    quality                                                              \
    vec4 result = vec4(0.0);                                             \
    for (int i = 0; i < sampleCount; i++) {                              \
      result += takeSample(fragCoord + samplePositions[i]);              \
    }                                                                    \
                                                                         \
    return result / float(sampleCount);                                  \
  }

#define INCLUDE_GRID_SUPER_SAMPLE_FUNCTION(name, takeSample)             \
  vec4 name(in vec2 fragCoord, in int samplesSqrt) {                     \
    vec4 outColor = vec4(0.0);                                           \
    for (int x = 0; x < samplesSqrt; x++) {                              \
      for (int y = 0; y < samplesSqrt; y++) {                            \
        vec2 offset =                                                    \
          vec2((float(x) + 0.5) * (1.0 / float(samplesSqrt)) - 0.5,      \
               (float(y) + 0.5) * (1.0 / float(samplesSqrt)) - 0.5);     \
        vec2 samplePosition = fragCoord + offset;                        \
        outColor += takeSample(samplePosition);                          \
      }                                                                  \
    }                                                                    \
                                                                         \
    return outColor / float(samplesSqrt * samplesSqrt);                  \
  }