// Sound (sound) — 20220405_Eucredian Rhythms by 0b5vr
// https://www.shadertoy.com/view/7ljczz

vec2 kick( float t ) {
    float phase = 45.0 * t - 6.0 * exp( -40.0 * t ) - 3.0 * exp( -400.0 * t );
    float decay = exp( -3.0 * t );
    return vec2( decay * sin( TAU * phase ) );
}

vec2 hihat( float t ) {
    float decay = exp( -50.0 * t );
    vec2 sig = 1.0 - 2.0 * texture( iChannel0, vec2( vec2( 140.0, 136.0 ) * t ) ).xy;
    sig -= 1.0 - 2.0 * texture( iChannel0, vec2( vec2( 140.0, 136.0 ) * t + 0.007 ) ).xy; // pseudo high pass. shoutouts to aaaidan
    return sig * decay;
}

vec2 snare( float t ) {
    float decay = exp( -t * 20.0 );
    vec2 snappy = texture( iChannel0, vec2( vec2( 70.0, 76.0 ) * t ) ).xy;
    vec2 head = sin( TAU * ( t * 280.0 * vec2( 1.005, 0.995 ) - exp( -t * 100.0 ) ) );
  return clip( ( 3.0 * snappy * head ) * decay );
}

vec2 rimshot( float t ) {
    float attack = exp( -t * 400.0 ) * 0.6;
    vec2 wave = (
        tri( t * 450.0 * vec2( 1.005, 0.995 ) - attack ) +
        tri( t * 1800.0 * vec2( 0.995, 1.005 ) - attack )
    );
    return clip( 2.0 * wave * exp( -t * 300.0 ) );
}

vec2 tom( float t, float freq ) {
    float phase = freq * t - 5.0 * exp( -30.0 * t ) - 2.0 * exp( -100.0 * t );
    float decay = exp( -20.0 * t );
    return vec2( decay * sin( 2.0 * sin( TAU * phase ) ) );
}

vec2 mainSound( int samp, float time ) {
    float beat = time * TIME2BEAT;
    
    vec2 dest = vec2( 0.0 );
    
    float tKick = euclideanRhythmsInteg( KICK_PULSES, KICK_STEPS, 4.0 * beat - KICK_OFFSET ) / 4.0 * BEAT2TIME;
    dest += 0.5 * kick( tKick );
    
    float tHihat = euclideanRhythmsInteg( HIHAT_PULSES, HIHAT_STEPS, 4.0 * beat - HIHAT_OFFSET ) / 4.0 * BEAT2TIME;
    dest += 0.2 * hihat( tHihat );
    
    float tSnare = euclideanRhythmsInteg( SNARE_PULSES, SNARE_STEPS, 4.0 * beat - SNARE_OFFSET ) / 4.0 * BEAT2TIME;
    dest += 0.3 * snare( tSnare );
    
    float tHiTom = euclideanRhythmsInteg( HITOM_PULSES, HITOM_STEPS, 4.0 * beat - HITOM_OFFSET ) / 4.0 * BEAT2TIME;
    dest += vec2( 0.2, 0.1 ) * tom( tHiTom, 180.0 );
    
    float tLoTom = euclideanRhythmsInteg( LOTOM_PULSES, LOTOM_STEPS, 4.0 * beat - LOTOM_OFFSET ) / 4.0 * BEAT2TIME;
    dest += vec2( 0.1, 0.2 ) * tom( tLoTom, 120.0 );
    
    float tRim = euclideanRhythmsInteg( RIM_PULSES, RIM_STEPS, 4.0 * beat - RIM_OFFSET ) / 4.0 * BEAT2TIME;
    dest += 0.2 * rimshot( tRim );

    return clip( dest );
}
