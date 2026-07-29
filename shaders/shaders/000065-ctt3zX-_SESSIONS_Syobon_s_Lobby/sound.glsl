// Sound (sound) — [SESSIONS] Syobon's Lobby by Kamoshika
// https://www.shadertoy.com/view/ctt3zX

#define hash(x) fract(sin(x) * 43758.5453)
const float PI2 = acos(-1.) * 2.;
const float sceneTime2 = 8.;  // グリッチの終了時間

vec2 mainSound( int samp, float time )
{
    float res = 0.;
    float T = fract(time / 10.) * 500.;
    
    if(time + hash(floor(T) * 20.) * 5.5 < sceneTime2) {
        return vec2(hash(T) - 0.5) * 0.2;
    }
    
    res = (fract(-time * 50.) - 0.5) * 0.04;
    res += (fract(-time * 100.) - 0.5) * 0.04;
    
    float N = 15.;
    for(float i = 0.; i < N; i++) {
        float T = time + i / N;
        float I = floor(T);
        float F = fract(T);
        float ID = i + I * N;
        float h = hash(ID);
        if(h < 0.2) {
            res += sin(F * PI2 * 50. * 140.) * exp(-F * 15.) * h * 0.3;
        }
    }
    
    return vec2(res);
}