// Buffer A (buffer) — [SESSIONS] Syobon's Lobby by Kamoshika
// https://www.shadertoy.com/view/ctt3zX

#define FC fragCoord
#define o fragColor

// vをPI/4.だけ回転
#define rotpi4(v) (vec2((v).x + (v).y, -(v).x + (v).y) / sqrt(2.))

// オブジェクトの種類
#define FLOOR   1
#define WALL    2
#define CEILING 3
#define SYOBON  4

// 壁の配置（マップ）は、対角線のTruchet tilesをベースとしています。
// すべての壁の法線ベクトルは(±1, 0, ±1)の４種類。
// ※ミニマップは45°傾いており、斜め右下がx軸の正方向、斜め左下がz軸の正方向となっています。

// 壁（タイル）の種類
// 四隅のみ
#define FOURCORNERS   11.0
// 四隅と対角線(平面x=z)
#define DIAGPLUS      12.0
// 四隅と対角線(平面x=-z)
#define DIAGMINUS     13.0

// Change according to the processing capability of the GPU.
//----------GPUの処理能力に応じて変更してください。----------
const int numSamples = 50;  // パストレーシングのサンプル数
//------------------------------------------------------------

const int maxDepth = 3;     // レイの経路の深さの最大値（反射回数+1の値）

const float sceneTime1 = 5.;  // 画面ノイズの終了時間
const float sceneTime2 = 8.;  // グリッチの終了時間
const float sceneTime3 = 10.; // HUDの開始時間
const float sceneTime4 = 11.; // タイマー、プレイヤー（カメラ）の移動の開始時間
const float sceneTime5 = 14.; // ショボンの追跡の開始時間
//const float sceneTime5 = 1e5; // ショボンの追跡の開始時間

const float PI = acos(-1.); // 円周率
const float PI2 = acos(-1.) * 2.;

const float EPS = 0.0001;           // レイトレースなどに使う微小量
const float FOV = 60. / 360. * PI;  // 視野角(ラジアン) 範囲：(0./360.*PI, 180./360.*PI)
const float wallRate = 0.7;         // 壁の割合　範囲：[0., 1.]
const float wallWidth = 0.1;        // 壁の厚さ　範囲：(0., 0.5)
//const float mapSeed = 5.;           // マップ生成に使う乱数のシード
const float mapSeed = 4.;           // マップ生成に使う乱数のシード
const float ceilHeight = 0.5;       // 天井の高さ
const float damageRate = 0.01;      // 1フレームあたりのダメージ量
const float enemySize = 0.2;        // ショボン（敵）の大きさ（球の半径）
vec3 enemyPos;                      // ショボンの位置
float enemyDirA;                    // ショボンの向き(ラジアン)
float pathSeed = 0.;                // パストレーシングで使う乱数のシード

// 1Dの乱数
float hash11(float p)
{
    return fract(sin(p) * 43758.5453);
}

// 2Dの乱数
float hash12(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
    // return fract(sin(dot(p + 0.2, vec2(12.9898, 78.233))) * 43758.5453);
}

// 1Dの乱数(シードを更新)
float random() {
    return hash11(pathSeed++);
}

// 2次元の回転行列
mat2 rotate2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

const float segScale = 0.03; // セグメント数字の大きさ
// 数字のセグメントの距離関数
float sdSeg(vec2 p) {
    p = abs(p);
    return max(p.x - segScale / 3., p.x + p.y - segScale);
}

// "0"の距離関数
float sd0(vec2 p) {
    p = abs(p);
    p.y -= segScale;
    p = p.y > p.x ? p.yx : p;
    p.x -= segScale;
    return sdSeg(p);
}

// "1"の距離関数
float sd1(vec2 p) {
    p.y = abs(p.y);
    p -= segScale;
    return sdSeg(p);
}

// "2"の距離関数
float sd2(vec2 p) {
    p = p.y < 0. ? -p : p;
    p.y = abs(p.y - segScale);
    p = p.y > p.x ? p.yx : p;
    p.x -= segScale;
    return sdSeg(p);
}

// "3"の距離関数
float sd3(vec2 p) {
    p.y = abs(abs(p.y) - segScale);
    p = p.y > p.x ? p.yx : p;
    p.x -= segScale;
    return sdSeg(p);
}

// "4"の距離関数
float sd4(vec2 p) {
    float d = sdSeg(p - vec2(-segScale, segScale));
    p.y = abs(p.y) - segScale;
    p = p.y < -p.x ? -p.yx : p;
    p.x -= segScale;
    return min(d, sdSeg(p));
}

// "5"の距離関数
float sd5(vec2 p) {
    p = p.y < 0. ? -p : p;
    p.y = abs(p.y - segScale);
    p = p.y > -p.x ? -p.yx : p;
    p.x += segScale;
    return sdSeg(p);
}

// "6"の距離関数
float sd6(vec2 p) {
    float d = sdSeg(p - vec2(segScale, -segScale));
    p.y = abs(abs(p.y) - segScale);
    p = p.y > -p.x ? -p.yx : p;
    p.x += segScale;
    return min(d, sdSeg(p));
}

// "7"の距離関数
float sd7(vec2 p) {
    float d = sdSeg(p - vec2(segScale, -segScale));
    p.y -= segScale;
    p = p.y > p.x ? p.yx : p;
    p.x -= segScale;
    return min(d, sdSeg(p));
}

// "8"の距離関数
float sd8(vec2 p) {
    p = abs(p);
    p.y = abs(p.y - segScale);
    p = p.y > p.x ? p.yx : p;
    p.x -= segScale;
    return sdSeg(p);
}

// "9"の距離関数
float sd9(vec2 p) {
    float d = sdSeg(p - vec2(-segScale, segScale));
    p.y = abs(abs(p.y) - segScale);
    p = p.y > p.x ? p.yx : p;
    p.x -= segScale;
    return min(d, sdSeg(p));
}

// 数字N（0～9）の距離関数
float sdDigit(vec2 p, int N) {
    if(N == 0) return sd0(p);
    if(N == 1) return sd1(p);
    if(N == 2) return sd2(p);
    if(N == 3) return sd3(p);
    if(N == 4) return sd4(p);
    if(N == 5) return sd5(p);
    if(N == 6) return sd6(p);
    if(N == 7) return sd7(p);
    if(N == 8) return sd8(p);
    if(N == 9) return sd9(p);
    return 1e5;
}

// タイマーの色
vec3 colTimer(vec3 col, vec2 uv, vec2 pos, float size, float Time) {
    uv -= pos;
    uv /= size;
    vec2 uvp = uv;
    uv.x -= uv.y * 0.2;

    float segGap = 0.002;
    float interval = 0.09;
    float interval2 = interval * 1.3;
    float ra = 0.01;

    float hundredths = fract(Time) * 100.;
    float seconds = mod(Time, 60.);
    float minutes = mod(Time / 60., 60.);
    float hours = mod(Time / 3600., 100.);

    int digit1 = int(mod(hundredths, 10.));
    int digit2 = int(hundredths / 10.);
    int digit3 = int(mod(seconds, 10.));
    int digit4 = int(seconds / 10.);
    int digit5 = int(mod(minutes, 10.));
    int digit6 = int(minutes / 10.);
    int digit7 = int(mod(hours, 10.));
    int digit8 = int(hours / 10.);

    float d = length(uvp - vec2(-0.159, -0.06)) - ra; // ピリオド
    uvp -= vec2(-interval * 5.1, 0);
    uvp.x -= sign(uvp.y) * 0.007;
    uvp = abs(uvp) - vec2(interval * 1.15, 0.035);
    d = min(d, length(uvp) - ra); // コロン

    vec2 uv12 = (uv - vec2(-0.036, -0.021)) * 1.5;
    d = min(d, sdDigit(uv12, digit1));

    uv.x += interval;
    uv12.x += interval;
    d = min(d, sdDigit(uv12, digit2));

    uv.x += interval2;
    d = min(d, sdDigit(uv, digit3));

    uv.x += interval;
    d = min(d, sdDigit(uv, digit4));

    uv.x += interval2;
    d = min(d, sdDigit(uv, digit5));

    uv.x += interval;
    d = min(d, sdDigit(uv, digit6));

    uv.x += interval2;
    d = min(d, sdDigit(uv, digit7));

    uv.x += interval;
    d = min(d, sdDigit(uv, digit8));

    col = mix(vec3(0.2), col, smoothstep(0.009, 0.0091, d + segGap)); // 枠
    col += smoothstep(0.001, 0., d + segGap);

    return col;
}

const float serifThin = 4.; // 文字のセリフの細さ
// 文字のセリフの距離関数
float sdSerif(vec2 p, vec2 pos, float width, float height) {
    p -= pos;
    p.x = abs(p.x);
    float d = p.x - exp(-p.y * p.y * serifThin) - width;
    d = max(d, -p.y);
    return max(d, p.y - height);
}

// "Y"の距離関数
float sdCY(vec2 p) {
    float d = sdSerif(p, vec2(0, -5.), 0.7, 4.5);
    p.y = -p.y;
    vec2 q = p;
    q.x += q.y * 0.6 - 0.8;
    d = min(d, sdSerif(q, vec2(0, -5.), 0.45, 6.));
    q = p;
    q.x -= q.y * 0.6 - 0.5;
    return min(d, sdSerif(q, vec2(0, -5.), 0.7, 5.8));
}

// "O"の距離関数
float sdCO(vec2 p) {
    p.x *= 1.1;
    float d = length(p) - 5.;
    p.x *= 1.4;
    return max(d, 4.5 - length(p));
}

// "U"の距離関数
float sdCU(vec2 p) {
    vec2 q = p;
    q.y += 2.2;
    q.y *= 1.2;
    float r1 = 3.7;
    float r2 = 2.6;
    float of = 0.25;
    q.y -= max(q.y, 0.);
    float d = length(q) - r1;
    q.x -= of;
    d = max(d, r2 - length(q));
    d = max(d, p.y - 5.);
    q = p;
    q.y = 5. - q.y;
    float temp = of - r2;
    d = min(d, sdSerif(q, vec2((temp - r1) * 0.5, 0), (temp + r1) * 0.5, 3.));
    temp = of + r2;
    return min(d, sdSerif(q, vec2((r1 + temp) * 0.5, 0), (r1 - temp) * 0.5, 3.));
}

// "D"の距離関数
float sdCD(vec2 p) {
    p.y = abs(p.y);
    vec2 q = p;
    q.x -= min(q.x, 0.2);
    float d = length(q) - 5.;
    d = max(d, -p.x - 2.5);
    q = p;
    q.x += 1.;
    d = max(d, 4.5 - length(q));
    q.y = 5. - q.y;
    return min(d, sdSerif(q, vec2(-1.7, 0), 0.7, 6.));
}

// "I"の距離関数
float sdCI(vec2 p) {
    p.y = 5. - abs(p.y);
    return sdSerif(p, vec2(0, 0), 0.7, 6.);
}

// "E"の距離関数
float sdCE(vec2 p) {
    vec2 q = vec2(p.y, -p.x);
    float d = sdSerif(q, vec2(0.5, -4.), 0.42, 6.);
    q = p;
    q.y = 5. - abs(q.y);
    d = min(d, sdSerif(q, vec2(-1.5, 0), 0.7, 6.));
    q = vec2(p.y - 5., 4.5 - p.x);
    q.y -= q.x *.1;
    d = min(d, sdSerif(q, vec2(0, 0), 0.7, 6.));
    q = vec2(p.y + 5., 4.5 - p.x);
    q.y += q.x *.3;
    d = min(d, sdSerif(q, vec2(0, 0), 0.7, 6.));
    return max(d, abs(p.y) - 5.);
}

// 死亡時のメッセージの色
vec3 colDeathMsg(vec3 col, vec2 uv, vec2 pos, float size) {
    uv -= pos;
    uv /= size * 0.05;
    uv.x += 30.;

    float d = sdCY(uv); // Y
    uv.x -= 10.;
    d = min(d, sdCO(uv)); // O
    uv.x -= 10.5;
    d = min(d, sdCU(uv)); // U
    uv.x -= 14.5;
    d = min(d, sdCD(uv)); // D
    uv.x -= 8.5;
    d = min(d, sdCI(uv)); // I
    uv.x -= 6.5;
    d = min(d, sdCE(uv)); // E
    uv.x -= 11.;
    d = min(d, sdCD(uv)); // D

    col *= mix(0.2, 1., smoothstep(5., 14., abs(uv.y)));
    col = mix(vec3(0.7,0.,0.) + col, col, smoothstep(0., 0.01, d));

    return col;
}

// 壁の種類
vec2 wallType(vec2 ID) {
    float hash = hash12(ID + mapSeed * PI);

    if(hash > wallRate) {
        return vec2(FOURCORNERS, 1.);
    }

    if(hash > wallRate * 0.5) {
        return vec2(DIAGPLUS, 1.);
    }

    return vec2(DIAGMINUS, -1.);
}

// 壁の距離関数（2次元）
// 対角線のTruchet tilesをベースとしています。
float sdWall(vec2 p) {
    vec2 ID = floor(p);
    vec2 q = fract(p) - 0.5;
    vec2 wType = wallType(ID);

    q.y *= wType.y;

    if(wType.x != FOURCORNERS) {
        // DIAGMINUS or DIAGPLUS
        return (0.5 - wallWidth - abs(fract(q.y - q.x) - 0.5)) / sqrt(2.);
    }

    // FOURCORNERS
    q = abs(q);
    return (1. - q.x - q.y - wallWidth) / sqrt(2.);
}

// 壁の法線ベクトル（2次元）
vec2 wallNormal(vec2 p) {
    vec2 e = vec2(0, 0.1);
    return normalize(vec2(sdWall(p + e.yx) - sdWall(p - e.yx),
                          sdWall(p + e.xy) - sdWall(p - e.xy)));
}

// 画面上のミニマップの色
vec3 colMiniMap(vec3 col, vec2 uv, vec2 pos, float size, vec2 ro, float dirA) {
    uv -= pos;
    uv /= size;

    float L = length(uv);
    float R = 0.4;

    col = mix(vec3(0.5), col, smoothstep(0., 0.02, abs(L - R))); // 丸い枠
    if(L < R) {
        vec3 mapCol = vec3(0.7, 0.7, 0.9);
        uv.y = -uv.y;
        uv = rotpi4(uv); // PI/4.だけ回転
        uv *= 15.;

        col = mix(vec3(1.), col * mapCol, smoothstep(0., 0.01, sdWall(uv + ro))); // 壁

        col =  mix(vec3(1, 1, 0), col, smoothstep(0.2, 0.25, length(uv))); // プレイヤー

        vec2 q = uv * rotate2D(dirA);
        float width = 0.02;
        float a = abs(atan(q.y, q.x));
        if(a < FOV + width && col.x < 0.99) {
            float cFOV = smoothstep(1., 6., length(q)) * smoothstep(0., width, abs(a - FOV));
            col = mix(vec3(0.6, 0.6, 0), col, cFOV); // 視界
        }
    }

    return col;
}

// HPバーの色
vec3 colHPBar(vec3 col, vec2 uv, vec2 pos, vec2 size, float HP) {
    uv -= pos;

    vec2 uvb = uv;
    uv = abs(uv) - size;
    uvb /= size * 2.;
    uvb += 0.5;

    float d = max(uv.x, uv.y);

    if(d < 0.) {
        col = mix(vec3(0), col, 0.4);
        if(uvb.x < HP) {
            col = vec3(1, .0, .0);
            col += uvb.y * 1.5 - 0.75;
        }
    }

    col = mix(vec3(0.8), col, smoothstep(0., 0.01, abs(d))); // 枠

    return col;
}

// HUDの色
vec3 colHUD(vec3 col, vec2 uv, vec2 ro, float dirA, float HP) {
    col = colMiniMap(col, uv, vec2(0.8, -0.55), 1., ro, dirA); // ミニマップを表示
    col = colHPBar(col, uv, vec2(0, 0.85), vec2(0.8, 0.05),  HP); // HPバーを表示

    float Time = max(iTime - sceneTime4, 0.);
    col = colTimer(col, uv, vec2(1.18, -0.03), 1., Time); // タイマーを表示

    if(HP >= damageRate) { // 生きている間は死亡時のメッセージを表示しない
        return col;
    }

    return colDeathMsg(col, uv, vec2(0, 0.4), 0.6); // 死亡時のメッセージを表示
}

// 物体の表面上の座標rpにおける法線ベクトル
vec3 objNormal(vec3 rp, out int objType) {
    vec3 n = vec3(0, 1, 0);

    if(rp.y > ceilHeight - EPS) {
        objType = CEILING;
        return vec3(0, -1, 0);
    }
    if(rp.y < EPS) {
        objType = FLOOR;
        return vec3(0, 1, 0);
    }

    vec3 ep = rp - enemyPos;
    if(dot(ep, ep) < (enemySize + EPS) * (enemySize + EPS)) {
        objType = SYOBON;
        return ep / enemySize; // 球体なので半径で割ると法線ベクトルになる
    }

    vec2 frp = fract(rp.xz) - 0.5;
    vec2 ID = floor(rp.xz);
    vec2 wType = wallType(ID);

    objType = WALL;
    n.y = 0.;
    n.xz = -sign(frp) / sqrt(2.);

    if(wType.x == FOURCORNERS) {
        return n;
    }

    // DIAGMINUS or DIAGPLUS
    float temp = frp.y - wType.y * frp.x;
    float signNormal = sign(temp);
    n.xz = (abs(temp) < wallWidth + EPS) ? vec2(-wType.y * signNormal, signNormal) / sqrt(2.) : n.xz;

    return n;
}

// レイと球の表面の交差判定関数
// ref: sphIntersect() by iq
// https://iquilezles.org/articles/intersectors/
float sphIntersect(vec3 ro, vec3 rd, vec3 ce, float ra) {
    vec3 oc = ro - ce;
    float e = dot(oc, rd);
    float c = dot(oc, oc) - ra * ra;
    float h = e * e - c;
    if(h < 0.) {
        return -1.0;
    }
    return -e - sqrt(h);
}

// エミッションの色
vec3 emission(vec3 rp, int objType, out float ceilPattern) {
    if(objType != CEILING) { // 光源は天井のみ
        return vec3(0);
    }

    // 光源のタイルの端を壁に合わせる
    vec2 uv = rp.xz;
    uv /= wallWidth * sqrt(2.);
    uv = rotpi4(uv);
    uv -= 0.5;

    float hash = hash12(floor(uv));
    uv = abs(fract(uv) - 0.5);

    ceilPattern = smoothstep(0.5, 0.43, max(uv.x, uv.y));
    if(fract(hash + iTime * 0.05) < 0.05) { // 点滅
        return vec3(ceilPattern * 10.);
    }

    return vec3(0);
}

// ショボンの目の距離関数
float sdSyobonEye(vec2 p, vec2 pos, float radius) {
    p.x = abs(p.x);
    return length(p - pos) - radius;
}

// ショボンの眉毛の距離関数
float sdSyobonEyebrow(vec2 p, vec2 pos, float L, float angle) {
    p.x = abs(p.x);
    p -= pos;
    p *= rotate2D(angle);
    p.x -= clamp(p.x, -L, L);
    return length(p);
}

// ショボンの口の距離関数
// reference: "Arc - exact" by iq
// https://iquilezles.org/articles/distfunctions2d/
float sdSyobonMouth(vec2 p, float posY, float radius) {
    p.x = abs(p.x);
    p.y -= posY;
    p *= rotate2D(0.5);

    float a = 1.1;
    float s = sin(a);
    float c = cos(a);
    vec2 cp = vec2(s, c) * radius;
    p -= vec2(cp.x, -cp.y);

    p.x = abs(p.x);

    if(p.y * s > p.x * c) {
        return length(p - cp);
    }
    return abs(length(p) - radius);
}

// ショボンの顔の距離関数
float sdSyobon(vec2 p) {
    float d;
    d = sdSyobonEye(p, vec2(0.5, 0), 0.06);
    d = min(d, sdSyobonEyebrow(p, vec2(0.8, 0.3), 0.13, -0.5));
    return min(d, sdSyobonMouth(p, -0.3, 0.1));
}

// 物体の色
vec3 objColor(vec3 rp, int objType, float ceilPattern) {
    if(objType == FLOOR) { // 床
        return vec3(0.7, 0.4, 0.2);
    }

    if(objType == CEILING) { // 天井
        return vec3(mix(0.5, 1.0, ceilPattern));
    }

    if(objType == WALL) { // 壁
        if(abs(rp.y - ceilHeight * 0.5) > ceilHeight * 0.47) {
            return vec3(1.0);
        }
        rp.x = abs(fract(rp.x / wallWidth * 5. - 0.5) - 0.5); // 縦の縞模様にする
        return mix(vec3(0.95), vec3(0.1, 0.6, 0.3), smoothstep(0., 0.2, rp.x));
    }

    vec3 p = rp - enemyPos;
    if(objType == SYOBON) { // ショボン
        p.xz *= rotate2D(enemyDirA);
        if(p.x < 0.) {
            return vec3(1);
        }
        vec2 uv = p.zy;
        uv *= 1.3 / enemySize;
        float d = sdSyobon(uv);
        return vec3(smoothstep(0.05, 0.1, d));
    }

    return vec3(0);
}

// vを天頂として極座標phi, thetaだけ回転させたベクトル
// ※引数vは長さ1のベクトルである必要あり
vec3 jitter(vec3 v, float phi, float sinTheta, float cosTheta) {
    vec3 xAxis = normalize(cross(v.yzx, v));
    vec3 yAxis = cross(v, xAxis);
    vec3 zAxis = v;
    return (xAxis * cos(phi) + yAxis * sin(phi)) * sinTheta + zAxis * cosTheta;
}

// roから物体表面まで飛ばしたレイの長さ
// 2DのVoxel Traversalをベースとしています。
float castRay(vec3 ro, vec3 rd, const int itr) {
    float t = 0.; // レイの長さ
    vec2 ri = 1.0 / rd.xz;
    vec2 rs = sign(rd.xz);

    // 壁を無視したレイの長さ
    float tLimit = (rd.y > 0.) ? (ceilHeight - ro.y) : -ro.y;
    tLimit = (rd.y == 0.) ? 1e5 : tLimit / rd.y; // 天井または床までのレイの長さ

    // ショボンまでのレイの長さ
    float tEnemy = sphIntersect(ro, rd, enemyPos, enemySize);
    tLimit = (tEnemy > 0.) ? min(tLimit, tEnemy) : tLimit; // レイがショボンに衝突したらtLimitを更新

    vec2 ID = floor(ro.xz); // セルのID（レイの座標の整数部分）

    for(int i = 0; i < itr; i++) {
        vec2 rp = ro.xz + rd.xz * t;  // レイの先端の座標
        vec2 wType = wallType(ID);    // 壁の種類
        vec2 frp = rp - ID - 0.5;     // レイの先端の座標の小数部分-0.5
        float tWall = 1e5;            // 次の壁までのレイの長さ

        vec2 v = (0.5 * rs - frp) * ri; // 次のセルの境界までのレイの長さ(X方向とZ方向)
        vec2 vCell = vec2(step(v.x, v.y), step(v.y, v.x)); // X方向とZ方向のうち、どちらのセルに進むか
        float tCell = dot(v, vCell); // 次のセルの境界までのレイの長さ（v.x or v.y）

        vec2 normal = -sign(frp + tCell * rd.xz); // 長さを計算式に反映済みのためnormalize()は不要
        float tWallFourCorners = (wallWidth - 1. - dot(frp, normal)) / dot(rd.xz, normal); // 四隅の壁までのレイの長さ
        tWall = (tWallFourCorners > 0.) ? tWallFourCorners : tWall; // tWallを更新する

        float signNormal = sign(frp.y - wType.y * frp.x);
        normal = vec2(-wType.y * signNormal, signNormal); // 長さを計算式に反映済みのためnormalize()は不要
        float tWallDiag = (wallWidth - dot(frp, normal)) / dot(rd.xz, normal); // 対角線の壁までのレイの長さ
        tWall = (tWallDiag > 0. && wType.x != FOURCORNERS) ? min(tWall, tWallDiag) : tWall; // 壁の種類が対角の場合はtWallを更新する

        if(tWall < tCell) { // 次のセルの境界よりも、壁の方が近い
            return min(t + tWall, tLimit);
        }

        // 次のセルの境界に進む
        t += tCell;
        ID += vCell * rs;

        if(t >= tLimit) { // 次のセルの境界よりも、天井 or 床 or ショボンの方が近い
            return tLimit;
        }
    }

    return -1.0;
}

// ref: "パストレーシング - Computer Graphics - memoRANDOM" by Shocker_0x15
// (Japanese article)
// https://rayspace.xyz/CG/contents/path_tracing/

// ref: "GLSL smallpt" by Zavie
// https://www.shadertoy.com/view/4sfGDB
// ※参考にはしているがコードは異なる

// パストレーシングで得られる色
vec3 pathTrace(vec3 ro, vec3 rd) {
    vec3 acc = vec3(0);
    vec3 mask = vec3(1);

    // 最初にカメラからレイを飛ばす
    float t = castRay(ro, rd, 20);
    if(t < 0.) { // レイが物体に衝突しなかった
        return vec3(0.1, 0.6, 0.3) * 0.1;
    }
    ro += t * rd; // レイの原点を物体表面まで進める
    int objType;
    float ceilPattern;
    vec3 n = objNormal(ro, objType);
    // ※本来はサンプル数の分だけカメラからレイを飛ばすため、numSamplesをかける
    acc += mask * emission(ro, objType, ceilPattern) * float(numSamples);
    mask *= objColor(ro, objType, ceilPattern);

    // 次に、物体表面からランダムにレイを飛ばす
    vec3 ro0 = ro + n * EPS;
    vec3 n0 = n;
    vec3 mask0 = mask;
    for(int i = 0; i < numSamples; i++) {
        ro = ro0;
        n = n0;
        mask = mask0;
        for(int depth = 1; depth < maxDepth; depth++) {
            float ur = random(); // 一様乱数
            // 重点的サンプリングを行うため、半球面内cos分布を使用する
            rd = jitter(n, random() * PI2, sqrt(1. - ur), sqrt(ur)); // 次のレイの方向

            t = castRay(ro, rd, 4);
            if(t < 0.) { // レイが物体に衝突しなかった
                break;
            }
            ro += t * rd;
            n = objNormal(ro, objType);
            acc += mask * emission(ro, objType, ceilPattern);
            mask *= objColor(ro, objType, ceilPattern);
            ro += n * EPS; // 現在の物体表面を避けるために、少し浮かせる
        }
    }

    acc /= float(numSamples);
    acc = clamp(acc, 0., 1.);

    return acc;
}

// カメラの位置と向きを初期化・更新する
void doCamera(in vec2 uv, out vec3 ro, out float dirA, out float dirY, out vec3 dir, out vec3 rd) {
    // カメラの座標を初期化
    ro = vec3(wallWidth + 0.2, ceilHeight * 0.5, 0.);

    // カメラの向きを初期化
    dir.y = 0.;
    dirA = 0.;
    dir.xz = vec2(cos(dirA), sin(dirA));

    if(iTime > sceneTime4) {
        // 前フレームのカメラの位置・向きを取得
        vec4 camInfo = texture(iChannel0, vec2(0.5, 0.5) / iResolution.xy);
        vec2 mouse = (iMouse.xy - abs(iMouse.zw)) / iResolution.x * vec2(20., 10.);
        //dir.y = (mouse.y - 0.5) * 2.;
        dirA = camInfo.z;
        dirY = camInfo.w;
        if(iMouse.z > 0.) {
            // カメラの向きをマウスで変える
            //dirA = mouse.x * PI2 * 4.;
            dirA = mouse.x;
            dirY = mouse.y;
        }
        dir.xz = vec2(cos(dirA), sin(dirA));
        dir.y = dirY;        
        
        //ro.xz = texture(iChannel0, vec2(0.5, 0.5) / iResolution.xy).rg;
        ro.xz = camInfo.xy;

        // カメラを移動させる
        vec2 v = dir.xz;
        vec2 n = wallNormal(ro.xz);
        float d = sdWall(ro.xz);
        if(d < 0.) { // 壁に埋まっているので法線方向に進んで抜け出す
            v = n;
        } else if(d < 0.15 && dot(v, n) < 0.) { // 壁に近い場合、壁と平行にしか進めないようにする
            vec2 nv = vec2(n.y, -n.x);
            v = nv * dot(nv, v);
        }
        
        if(iMouse.z > 0.) {
            ro.xz += v * 0.01;
            ro.y += abs(sin(fract(iTime * 4.) * PI) * 0.01); // プレイヤーが走っているように、カメラを上下に揺らす
        }
    }

    // 画面のuv座標とカメラの向きからレイベクトルを求める
    dir = normalize(dir);
    vec3 side = normalize(cross(dir, vec3(0, 1, 0)));
    vec3 up = cross(side, dir);
    rd = normalize(vec3(uv.x * side + uv.y * up + dir / tan(FOV)));
}

// ショボンの位置と向きを初期化・更新する
void doEnemy() {
    enemyPos.y = abs(sin(iTime * 3.)) * 0.1 + enemySize; // 床の上で跳ねる
    enemyPos.xz = vec2(1e5);
    enemyDirA = 0.;
    if(iTime > sceneTime5) { // プレイヤーを追跡
        vec3 texE = texture(iChannel0, vec2(200.5, 0.5) / iResolution.xy).rgb; // プレイヤーの過去の位置・向きを取得
        enemyPos.xz = texE.rg;
        enemyDirA = texE.b;
    }
}

// uvをずらしてグリッチ
vec2 glitch(vec2 uv, float rate) {
    float T = fract(iTime / 10.) * 10.;
    float vx = hash12(vec2(floor(uv.y * 20.), T));
    float vy = hash12(vec2(floor(uv.y * 20.), T + 500.));
    float v = floor(hash12(vec2(floor(uv.y * 6. - T * 3.))) * 6.) - 2.5;
    vec2 shift = vec2(vx, vy) * v / 2.5;
    uv -= shift * rate;
    return uv;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (FC.xy * 2. - iResolution.xy) / min(iResolution.x, iResolution.y); // 座標の正規化

    // HPが0になったら画面を停止して、全ての処理を終了する
    float HP = 1.; // HPを初期化
    if(iTime > sceneTime5) {
        HP = texture(iChannel0, vec2(0.5, 1.5) / iResolution.xy).a;
        //HP = texture(iChannel0, (iResolution.xy / 2. + 0.5) / iResolution.xy).a;
        if(HP < damageRate) {
            o = texture(iChannel0, FC.xy / iResolution.xy);
            return;
        }
    }

    float T = fract(iTime / 10.) * 500.;
    // 最初の時間は画面にノイズを表示する
    if(iTime + hash11(T) * 2.5 < sceneTime1) {
        vec2 i = floor(uv * 100.);
        i += hash12(i) * 500.;
        o = vec4(vec3(hash12(i + T)), 1.);
        return;
    }
    // グリッチのエフェクトをかける
    uv = glitch(uv, smoothstep(sceneTime2 + EPS, sceneTime1, iTime));

    vec3 ro;  // カメラの位置（レイの原点）
    vec3 rd;  // レイの向き
    vec3 dir; // カメラの向き
    float dirA; // カメラの向き（XZ平面内での角度（ラジアン））
    float dirY;
    //doCamera(uv, ro, dirA, dir, rd); // カメラの位置・向きを初期化・更新する
    doCamera(uv, ro, dirA, dirY, dir, rd); // カメラの位置・向きを初期化・更新する
    doEnemy(); // ショボンの位置・向きを初期化・更新する

    // パストレーシングで使う乱数のシードを初期化する
    pathSeed = hash12(FC.xy * PI) * 500.;
    pathSeed += hash12(FC.xy + pathSeed + T) * 500.;

    // パストレーシングをする
    vec3 col = vec3(0);
    col = pathTrace(ro, rd);
    col = pow(col, vec3(1. / 2.2)); // ガンマ補正

    // パストレーシングで得られた色の分散を低減するために前のフレームの色を合成する
    float tex = 0.7;
    //col *= 1. - tex;
    //col += texture(iChannel0, FC.xy / iResolution.xy).rgb * tex;
    col = mix(col, texture(iChannel0, FC.xy / iResolution.xy).rgb, tex);

    // ダメージの処理
    if(iTime > sceneTime5) {
        // 敵に接近するとダメージを受ける
        if(length(enemyPos - ro) < enemySize + 0.2) {
            HP = max(HP - damageRate, 0.); // HP減少
            col = mix(col, vec3(1, 0, 0), 0.15); // ダメージエフェクト
        }
    }

    // HUDを表示
    if(iTime > sceneTime3) {
        col = colHUD(col, uv, ro.xz, dirA, HP);
    }

    col = clamp(col, 0., 1.);
    o.rgb = col;

    // プレイヤー（カメラ）の位置・向き・HPを保存
    if(FC.y < 0.6) {
        if(FC.x < 0.6) {
            //o.rgb = vec3(ro.xz, dirA); // プレイヤーの位置と向きを保存
            o = vec4(ro.xz, dirA, dirY); // プレイヤーの位置と向きを保存
        } else {
            // プレイヤーの過去の状態をショボンの状態として使うため、ずらして過去の状態を保持する
            o.rgb = texture(iChannel0, vec2(FC.x - 1., 0.5) / iResolution.xy).rgb;
        }
    }
    if(FC.x < 0.6 && FC.y > 0.6 && FC.y < 1.6) {
        o.a = HP; // HPを保存
    }
}