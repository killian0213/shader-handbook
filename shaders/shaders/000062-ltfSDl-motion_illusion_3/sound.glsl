// Sound (sound) — motion illusion 3 by FabriceNeyret2
// https://www.shadertoy.com/view/ltfSDl

// grabbed from my Shepard shader https://www.shadertoy.com/view/XdlXWX

#define T 8.    // cycling time
#define N 56.   // number of peaks
#define O 1.23  // octaves
#define dPI 6.283185

vec2 mainSound( in int samp,float time)
{
 // time = -time;  // suppress the comment for rising sound
    float v = 0.;
    for (float i=0.; i<=N; i++) {
        float enveloppe = ( 1.-cos(dPI*i/N)) /2.;
        //float freq = pow(O,fract(time/T));
        // phase = int of freq
        float phase = floor(time/T) + pow(O,-fract(time/T))-1.;
        phase = phase * pow(O,i) * T/log(O) + i;
        v += enveloppe*sin(dPI*phase);
    }
    
    return vec2( v/N );
}
