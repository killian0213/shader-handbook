// Image (image) — [SESSIONS] Stairway to SESSIONS by Kamoshika
// https://www.shadertoy.com/view/4cGcDm

// If you don't hear the sound, please click on ⏸→⏮→▶.
// 音が聞こえない場合、 ⏸→⏮→▶ を順にクリックしてください


// 光源（球体）が動く速さをShadertoyのMusicに合うように変更済み
// 元のコード original code:
// https://twigl.app?ol=true&ss=-OByoIJjHjrBlwts2Y5p

//#define DEBUG

#ifdef DEBUG
  #define AA 0
#else
//-----------------GPUの処理能力に応じて変更-------------------
  #define AA 2
//-----------------------------------------------------------
#endif

// 乱数
#define hash(x) fract(sin(x) * 43758.5453123)

// オブジェクトの種類
#define SPHERE 0
#define WALL 1
#define STAIR_UP 2
#define STAIR_SIDE 3

// 文字のサイズ
#define CHAR_SIZE ivec2(4, 8)

const float BPM = 114.; // 追加

const int maxDepth = 6;               // レイの経路の深さの最大値
const float PI = acos(-1.);           // 円周率
const float PI2 = PI * 2.;            // τ
const float EPS = 0.0001;             // パストレーシングなどに使う微小量
const float FAR = 1e3;                // 最大描画距離
const float stairWidth = 2.;          // 階段の横幅
const float tileGrooveWidth = 0.005;  // タイルの溝の幅
const float tileRaCurvature = 0.03;   // タイルの縁の曲率半径
const float lightSize = 0.4;          // 光源（球体）の半径
const vec3 lightColor = vec3(30.);    // 光源（球体）の発光色
vec3 lightPos = vec3(0);              // 光源（球体）の中心の座標
float pathSeed = 0.;                  // パストレーシングで使う乱数のシード

// ピクセルフォント
// 参考：美咲フォント "misaki_gothic_2nd_4x8"
// https://littlelimit.net/misaki.htm
const uint ch_2 = 0x4A2448E0u;
const uint ch_0 = 0x4AAEAA40u;
//const uint ch_4 = 0x26AAE220u;
const uint ch_4 = 0x26AAF220u;
const uint ch_C = 0x4A888A40u;
const uint ch_E = 0xE88C88E0u;
const uint ch_I = 0xE44444E0u;
const uint ch_L = 0x888888E0u;
const uint ch_M = 0xAEEEAAA0u;
const uint ch_N = 0xCAAAAAA0u;
const uint ch_O = 0x4AAAAA40u;
const uint ch_S = 0x4A842A40u;
const uint ch_T = 0xE4444440u;
const uint ch_W = 0xAAAEEEA0u;

// nの各ビットを出力
bool extract_bit(uint n, int b) {
    return bool(1U & (n >> b));
}

// 単一の文字を出力
bool sprite(uint spr, ivec2 I) {
    int bit = (CHAR_SIZE.x - 1 - I.x) + I.y * CHAR_SIZE.x;
    bool bounds = 0 <= I.x && I.x < CHAR_SIZE.x && 0 <= I.y && I.y < CHAR_SIZE.y;
    return bounds && extract_bit(spr, bit);
}

// 1Dの乱数（シードを更新）
float random() {
    return hash(pathSeed++);
}

// 3Dの乱数
float hash13(vec3 p) {
    return hash(dot(p, vec3(127.1, 311.7, 74.7)));
}

// HSVからRGBへの変換
vec3 hsv(float h, float s, float v) {
    vec3 res = fract(h + vec3(0, 2, 1) / 3.);
    res = clamp(abs(res * 6. - 3.) - 1., 0., 1.);
    res = (res - 1.) * s + 1.;
    return res * v;
}

// 画面上の座標からレイの方向を算出
vec3 rayDir(vec2 uv, inout vec3 dir, float fov) {
    dir = normalize(dir);
    vec3 u = abs(dir.y) < 0.999 ? vec3(0, 1, 0) : vec3(0, 0, 1);
    vec3 side = normalize(cross(dir, u));
    vec3 up = cross(side, dir);
    return normalize(uv.x * side + uv.y * up + dir / tan(fov / 360. * PI));
}

// ベクトルvを回転軸axで角度aだけ回転
vec3 rot3D(vec3 v, float a, vec3 ax) {
    ax = normalize(ax);
    return mix(dot(ax, v) * ax, v, cos(a)) - sin(a) * cross(ax, v);
}

// 被写界深度
void dof(inout vec3 ro, inout vec3 rd, vec3 dir, float L, float factor) {
    float r = sqrt(random());
    float a = random() * PI2;
    vec3 v = vec3(r * vec2(cos(a), sin(a)) * factor, 0);
    vec3 diro = vec3(0, 0, -1);
    float d = dot(dir, diro);
    float va = acos(d);
    vec3 vax = abs(d) < 0.999 ? cross(dir, diro) : dir.yzx;
    v = rot3D(v, va, vax);
    ro += v;
    rd = normalize(rd * L - v);
}

// 物体の色を算出
vec3 objColor(vec3 p, int type, bool isGroove, vec3 n) {
    if(isGroove) {
        return vec3(0.8);
    }
    
    if(type == SPHERE) {
        return vec3(0);
    }
    
    vec3 ID = floor(p * float(CHAR_SIZE.y) + n * 0.5);
    //float h = hash13(mod(ID, 1e3) + float(type) * 0.1328); // 長時間経過時の精度対策でmod()
    float h = hash13(mod(ID, 5e2) + float(type) * 0.1328); // 長時間経過時の精度対策でmod()
    if(ID.y + ID.z > h * 40. + 8.) {
        return vec3(0.9, 0.7, 0.5);
    }
    
    vec3 col = hsv(0.4 - h * 0.1, 0.9, 0.1 + h * 0.5);
    if(type != STAIR_SIDE) {
        return col;
    }
    
    const uint[] str = uint[](ch_W, ch_E, ch_L, ch_C, ch_O, ch_M, ch_E, // len = 7
                              ch_T, ch_O, // len = 2
                              ch_S, ch_E, ch_S, ch_S, ch_I, ch_O, ch_N, ch_S, // len = 8
                              ch_2, ch_0, ch_2, ch_4); // len = 4
    const int numLine = 4;
    const int[numLine] lenArr = int[](7, 2, 8, 4);
    const int[numLine] posArr = int[](0, lenArr[0], lenArr[0] + lenArr[1], lenArr[0] + lenArr[1] + lenArr[2]);
    
    ivec2 I = ivec2(ID.x, mod(ID.y, float(CHAR_SIZE.y * (numLine + 1))));
    
    int line = numLine - I.y / CHAR_SIZE.y;
    if(line == numLine) {
        return col;
    }
    int len = lenArr[line];
    I.x += len * CHAR_SIZE.x / 2 - 1;
    int index = I.x / CHAR_SIZE.x;
    if(index < 0 || index >= len) {
        return col;
    }
    
    I.y = I.y % CHAR_SIZE.y;
    I.x -= index * CHAR_SIZE.x;
    index += posArr[line];
    
    return sprite(str[index], I) ? vec3(0.9) : col;
}

// エミッションの色
vec3 emission(int type) {
    return type == SPHERE ? lightColor : vec3(0);
}

// 3次元空間上の点ceを通り、normalを法線ベクトルとする平面とレイの交差判定関数
// （normalは正規化されていなくてもよい）
float plaIntersect(vec3 ro, vec3 rd, vec3 ce, vec3 normal) {
    float front1 = -dot(rd, normal);
    vec3 oc = ro - ce;
    float front2 = dot(oc, normal);
    return front2 / front1;
}

// 3次元空間上の点ceを通り、normalを法線ベクトルとする平面とレイの交差判定関数
// （normalは正規化されていなくてもよい）
float plaIntersect2(vec3 ro, vec3 rd, vec3 ce, vec3 normal) {
    float front1 = -dot(rd, normal);
    vec3 oc = ro - ce;
    float front2 = dot(oc, normal);
    if(front1 <= 0. || front2 <= 0.) {
        return -1.; // 平面の裏側が見えている場合、または平面がカメラの後方にある場合は負の値を返す
    }
    return front2 / front1;
}

// 球面とレイの交差判定関数
float sphIntersect2(vec3 ro, vec3 rd, vec3 ce, float ra) {
    vec3 oc = ro - ce;
    float c = dot(oc, oc) - ra * ra;
    if(c <= 0.) { // 球面の裏側は描画しない
        return -1.;
    }
    float b = dot(oc, rd);
    float h = b * b - c;
    if(h < 0.) {
        return -1.;
    }
    return -b - sqrt(h);
}

// カメラ（ro）から物体表面まで飛ばしたレイの長さ
float castRay(vec3 ro, vec3 rd) {
    float t = FAR;
    
    float w = 0.5 - step(0., rd.x);
    float tWall = plaIntersect2(ro, rd, vec3(-w * 2. * stairWidth, 0, 0), vec3(w, 0, 0));
    if(tWall > 0.) {
        t = min(t, tWall);
    }
    
    float tLight = sphIntersect2(ro, rd, lightPos, lightSize);
    if(tLight > 0.) {
        t = min(t, tLight);
    }
    
    float tBound = 0.;
    if(ro.y > -ro.z) {
        vec2 rp = ro.yz + t * rd.yz;
        if(rp.x > -rp.y) {
            return t;
        }
        tBound = plaIntersect2(ro, rd, vec3(0), vec3(0, 1, 1));
    }
    
    vec2 rp = ro.yz + tBound * rd.yz;
    float i = floor((rp.x - rp.y) * 0.5);
    vec3 ce = vec3(0, i, -1. - i);
    float tStairUp = plaIntersect2(ro, rd, ce, vec3(0, 1, 0));
    float tStairSide = plaIntersect2(ro, rd, ce, vec3(0, 0, 1));
    float tStair = (tStairUp > 0. && tStairSide > 0.) ? min(tStairUp, tStairSide) : max(tStairUp, tStairSide);
    
    float temp = t;
    if(tStair > 0.) {
        t = min(t, tStair);
    }
    rp = ro.yz + t * rd.yz;
    if(rp.x > -rp.y) {
        return temp;
    }
    
    return t;
}

// 被写界深度の焦点まで伸ばしたレイの長さ
float focusIntersect(vec3 ro, vec3 rd) {
    float t = FAR;
    // ro.yとro.zがともに整数でDOF無しのとき、この関数内でplaIntersectの代わりにplaIntersect2を使うとなぜかバグる
    // どうして？…Why?
    float w = 0.5 - step(0., rd.x);
    //float tWall = plaIntersect2(ro, rd, vec3(-w * 2. * stairWidth, 0, 0), vec3(w, 0, 0));
    float tWall = plaIntersect(ro, rd, vec3(-w * 2. * stairWidth, 0, 0), vec3(w, 0, 0));
    if(tWall > 0.) {
        t = min(t, tWall);
    }
    
    const float height = -0.5;
    //float tBound = plaIntersect2(ro, rd, vec3(0, height, 0), vec3(0, 1, 1));
    float tBound = plaIntersect(ro, rd, vec3(0, height, 0), vec3(0, 1, 1));
    if(tBound > 0.) {
        t = min(t, tBound);
    }
    
    return t;
}

// 物体の種類
int objType(vec3 p) {
    if(abs(p.x) > stairWidth - EPS) {
        return WALL;
    }
    
    vec3 q = p - lightPos;
    const float r = lightSize + EPS;
    if(dot(q, q) < r * r) {
        return SPHERE;
    }
    
    p.yz = abs(fract(p.yz) - 0.5);
    if(p.y < p.z) {
        return STAIR_SIDE;
    }
    
    return STAIR_UP;
}

// 法線ベクトルを計算する（タイルの凹凸は含まない）
vec3 calcNormal(vec3 p, int type) {
    if(type == WALL) {
        return vec3(-sign(p.x), 0, 0);
    }
    
    if(type == STAIR_SIDE) {
        return vec3(0, 0, 1);
    }
    
    if(type == STAIR_UP) {
        return vec3(0, 1, 0);
    }
    
    return (p - lightPos) / lightSize;
}

// タイルの凹凸
float bumpFunc(vec3 p, vec3 n) {
    p = abs(p);
    vec2 uv = n.y > 0.5 ? p.zx : n.z > 0.5 ? p.xy : p.yz;
    if(uv.y > uv.x) {
        uv = uv.yx;
    }
    uv.y -= tileGrooveWidth + tileRaCurvature;
    const float ra2 = tileRaCurvature * tileRaCurvature;
    if(uv.y > 0.) {
        return EPS + ra2;
    }
    
    if(uv.y < -tileRaCurvature) {
        return EPS;
    }
    
    float h = -uv.y * uv.y;
    return EPS + ra2 + h;
}

// 参考: "Maze Lattice" by Shane
// https://www.shadertoy.com/view/llGGzh
// タイルの凹凸ベクトル
// コードは改変済み
vec3 bumpMap(vec3 p, vec3 n, out bool isGroove) {
    const float bumpFactor = 0.5;
    const vec2 e = vec2(EPS, 0);
    
    const float interval = 1. / 8.;
    const float h = interval * 0.5;
    p = mod(p - h, interval) - h;
    float ref = bumpFunc(p, n);
    isGroove = (ref == EPS);
    vec3 grad = (vec3(bumpFunc(p - e.xyy, n),
                      bumpFunc(p - e.yxy, n),
                      bumpFunc(p - e.yyx, n)) - ref) / e.x;
    grad /= 2. * sqrt(ref); // sqrt(x) の微分
    grad -= n * dot(n, grad);
    return normalize(n + grad * bumpFactor);
}

// 三角波 周期:2, 振幅:1
float triWave(float x) {
    x -= 0.5;
    x *= 0.5;
    float res = abs(fract(x) - 0.5) - 0.25;
    return res * 4.;
}

// 範囲[-1, 1.]の間で等間隔にn個の値を取る滑らかな階段状のノイズ
float stepNoise(float x, float n) {
    const float factor = 0.3;
    float i = floor(x);
    float f = x - i; // fract(x)
    float u = smoothstep(0.5 - factor, 0.5 + factor, f);
    float res = mix(floor(hash(i) * n), floor(hash(i + 1.) * n), u);
    res /= (n - 1.) * 0.5;
    return res - 1.;
}

// 光源（球体）の位置を動かす
void moveLightPos() {
    //float T = iTime - 0.7829;
    //float T = iTime * BPM / 60. * 0.5 - 0.15; // 追加
    float T = - 1.25 - 0.7829 + iTime * BPM / 60. * 0.5; // 追加
    lightPos.y += abs(sin(T * PI2)) * 1.3;
    T += triWave(T / 4.) * 2.; // 時間停止のために三角波を足す
    lightPos += vec3(0, 1, -1) * T;
    lightPos.x += cos(T * PI) * 0.5;
}

// カメラの位置・向きを動かす
void moveCamera(inout vec3 ro, inout vec3 dir) {
    float T = - 1.25 + iTime * BPM / 60. * 0.5; // 追加
    //ro.yz += vec2(1, -1) * iTime;
    ro.yz += vec2(1, -1) * T;
    ro.y += abs(sin(ro.z * PI)) * 0.13;
    ro += sin(vec3(5, 7, 9) * iTime) * 0.01;
    dir.x += stepNoise(iTime * 0.4, 3.) * 0.8;
    dir.y += stepNoise(iTime * 0.4 - 500., 3.) * 0.4;
    dir += sin(vec3(7, 9, 5) * iTime - 500.) * 0.01;
    dir = normalize(dir);
}

// vを天頂として極座標phi, thetaだけ回転させたベクトル
vec3 jitter(vec3 v, float phi, float sinTheta, float cosTheta) {
    vec3 zAxis = normalize(v);
    vec3 xAxis = normalize(cross(zAxis.yzx, zAxis));
    vec3 yAxis = cross(zAxis, xAxis);
    return (xAxis * cos(phi) + yAxis * sin(phi)) * sinTheta + zAxis * cosTheta;
}

// パストレーシングをする
// 参考: "パストレーシング - Computer Graphics - memoRANDOM" by Shocker_0x15
// https://rayspace.xyz/CG/contents/path_tracing/
// 参考: "GLSL smallpt" by Zavie
// https://www.shadertoy.com/view/4sfGDB
// コードは改変済み
vec3 pathTrace(vec3 ro, vec3 rd) {
    vec3 acc = vec3(0);
    vec3 mask = vec3(1);
    
    for(int depth = 0; depth < maxDepth; depth++) {
        float t = castRay(ro, rd);
        if(t >= FAR) {
            break;
        }
        ro += t * rd;
        int type = objType(ro);
        vec3 n0 = calcNormal(ro, type);
        vec3 n = n0;
        bool isGroove = false;
        if(type != SPHERE) {
            n = bumpMap(ro, n0, isGroove);
        }
        
        ro += n0 * EPS;
        vec3 objC = objColor(ro, type, isGroove, n0);
        vec3 objE = emission(type);
        
        vec3 e = vec3(0);
        vec3 l0 = lightPos - ro;
        float cosA_max = sqrt(1. - lightSize * lightSize / dot(l0, l0));
        float cosA = mix(cosA_max, 1., random());
        vec3 l = jitter(l0, random() * PI2, sqrt(1. - cosA * cosA), cosA);
        
        float tl = castRay(ro, l);
        type = objType(ro + tl * l);
        
        if(type == SPHERE) {
            vec3 em = emission(type);
            float omega = PI2 * (1. - cosA_max); // オブジェクトの表面から見たときの光源（球体）の立体角
            // おそらく正規化LambertだがPIで割らなくてもいいかも(その場合emの値を変えるだけ)
            e += (em * max(dot(l, n), 0.) * omega) / PI;
        }
        
        const float rough = 0.01;
        vec3 nl = reflect(rd, n);
        //if(isGroove) {rough = 0.9; nl = n;}
        
        const float c = 1.; // GlossyなマテリアルのNext Event Estimationについて要検証
        //float c = rough;
        acc += mask * (objE + objC * e * c); // 要検証
        mask *= objC;
        
        float ur = random() * rough; // 要検証
        rd = jitter(nl, random() * PI2, sqrt(ur), sqrt(1. - ur));
    }
    
    return acc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col = vec3(0); // 画面上の色
    
    lightPos = vec3(0, lightSize, 0.);
    moveLightPos(); // 光源（球体）を動かす
    
    vec3 ro = vec3(0, 0, 5); // カメラの位置（レイの原点）
    vec3 dir = vec3(0, 0, -1); // カメラの向き
    moveCamera(ro, dir); // カメラの位置と向きを動かす
    float fov = 60.; // FOV（視野角）範囲：(0., 180.)
    
    float L = focusIntersect(ro, dir); // 被写界深度の焦点まで伸ばしたレイの長さ
    
    for(int m = 0; m < AA; m++) { // アンチエイリアシング
        for(int n = 0; n < AA; n++) {
            vec2 of = vec2(m, n) / float(AA) - 0.5; // オフセット
            vec2 uv = ((fragCoord + of) * 2. - iResolution.xy) / min(iResolution.x, iResolution.y); // 画面上の座標を正規化
            pathSeed += hash13(vec3(uv + of, fract(iTime * 0.1)));
            
            vec3 rd = rayDir(uv, dir, fov); // レイの向き
            
            // 被写界深度
            vec3 ros = ro;
            vec3 rds = rd;
            dof(ros, rds, dir, L, 0.15);
            
            col += pathTrace(ros, rds); // パストレーシング
        }
    }
    col /= float(AA * AA); // 色の平均をとる
    
    //if(col.r > 1. || col.g > 1. || col.b > 1.) col = vec3(1, 0, 0); // saturationチェック
    col = clamp(col, 0., 1.);
    
    col = pow(col, vec3(1. / 2.2)); // ガンマ補正
    
    // 口径食（vignetting）
    vec2 p = fragCoord / iResolution.xy;
    col *= 0.5 + 0.5 * pow(16.0 * p.x * p.y * (1.0 - p.x) * (1.0 - p.y), 0.5);
    
    // パストレーシングで得られた色の分散を低減するために前のフレームの色を合成する
    //col = mix(col, texture(backbuffer, gl_FragCoord.xy / resolution).rgb, 0.2);
    
#ifdef DEBUG
    col = vec3(0);
    vec2 uv = (fragCoord * 2. - iResolution.xy) / min(iResolution.x, iResolution.y); // 画面上の座標を正規化
    vec3 rd = rayDir(uv, dir, fov); // レイの向き
    float t = castRay(ro, rd);
    ro += t * rd;
    int type = objType(ro);
    vec3 n0 = calcNormal(ro, type);
    bool isGroove = false;
    vec3 n = n0;
    if(type != SPHERE) {
        n = bumpMap(ro, n0, isGroove);
    }
    col += exp(-t * t * 0.03) * (n * 0.5 + 0.5);
#endif
    
    fragColor = vec4(col, 1);
}