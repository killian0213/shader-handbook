// Image (image) — [SESSIONS] Syobon's Lobby by Kamoshika
// https://www.shadertoy.com/view/ctt3zX

// ショボンから逃げ回るゲームです。
// 生き延びた時間が得点となります。
// This is a game in which you run away from Syobon.
// Survival time is your score.


// 元のシェーダーはtwiglで動作するものであり、マウスのクリックの入力はありません。
// このシェーダーでは、マウスを押下していないときに立ち止まるような変更が加えられています。
// 元のシェーダーはサウンドもありません。
// Original shader works on twigl, and does not have a mouse press input.
// This shader has been modified to stand still when the mouse is not pressed down.
// Original shader has no sound.

// Original shader (twigl link):
// https://twigl.app?ol=true&ss=-NUH6X_5lvRnUYhwSX3F

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}