// Sound (sound) — The Evil Gorgon Of Tindalos by msm01
// https://www.shadertoy.com/view/XcdBDS

vec2 mainSound( int samp, float time )
{
     TimeVar = 0.75*time;
     FIRE_SYNC = (fbm(vec2(    TimeVar)) < 0.15)?true:false;
     MAGN_FAIL = (fbm(vec2(0.1*TimeVar)) > 0.60)?true:false;
     FIRE_SEAL = (fbm(vec2(0.1*TimeVar)) > 0.85)?true:false;

     vec2 DaSoundStream = vec2(0.0,0.0);

     if(time < 60.0) // No more than 1 min otherwise it gets really, really annoying !
     {
        // Basic Alarm
        DaSoundStream += 0.01*sin(floor( 220.0*sin((2.5*time))));

        if( MAGN_FAIL ) DaSoundStream += vec2(0.150*floor(sin(110.0*sin(( 2.5*time)))))
                                        +vec2(0.500*sin(fract(220.0*sin(( 2.5*time))))
                                             +0.050*sin(fract(110.0*sin(( 5.0*time)))));
        if(FIRE_SYNC)
        {
           DaSoundStream *= clamp(sin(5.0*time),0.1,1.0);
           DaSoundStream += vec2( 0.20*sin(110.0*floor(110.0*sin(150.0*time) + 0.90*sin(220.0*sin( 1.25*time)))));
        };

        if(FIRE_SEAL)DaSoundStream += 0.90*sin(fract(880.0*sin(( 50.0*time))));
     };
     
     return DaSoundStream;
}