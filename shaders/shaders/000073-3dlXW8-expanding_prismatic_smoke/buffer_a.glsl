// Buffer A (buffer) — expanding prismatic smoke by morisil
// https://www.shadertoy.com/view/3dlXW8

// true if the space is pressed
bool reset() {
    return texture(iChannel3, vec2(32.5/256.0, 0.5) ).x > 0.5;
}

vec4 getInitialState(
    const int row,
    const int particle, // not used here, but might be useful for other shaders
    vec2 seed
) {
    vec4 state;
    if (row == POSITION_ROW) {
        state = encode2(VEC2_ZERO);        
    } else if (row == VELOCITY_ROW) {
        state = encode2(VEC2_ZERO);
    } else if (row == COLOR_ROW) {
        state = vec4(
            rand(seed + .101),
            rand(seed + .102),
            rand(seed + .103),
            1.
        );
    } else {
        state = COLOR_ZERO;
    }
    return state;
}

vec4 calculateNewState(
    const int row,
    const int particle,
    const vec2 seed
) {
    vec4 state;
    if (row == POSITION_ROW) {
        state = encode2(
            getParticlePosition(particle)
            + getParticleVelocity(particle)
        );
    } else if (row == VELOCITY_ROW) {
        vec2 velocity = getParticleVelocity(particle);
        vec2 coord  = getParticlePosition(particle);
        velocity += vec2(
            rand(seed + .111) * MAX_VELOCITY_CHANGE * 2. - MAX_VELOCITY_CHANGE,
            rand(seed + .112) * MAX_VELOCITY_CHANGE * 2. - MAX_VELOCITY_CHANGE
        );
        vec2 focalPoint = coord; // might be different for other shaders, e.g. mouse
        velocity -= focalPoint * FOCAL_POINT_TENDENCY;
        // TODO is there a better way to clamp the vector?
		velocity = vec2(
            clamp(velocity.x, -MAX_VELOCITY, MAX_VELOCITY),
            clamp(velocity.y, -MAX_VELOCITY, MAX_VELOCITY)
        );
        vec2 prediction = coord + velocity;
        if ((prediction.x < -.5) || (prediction.x > .5)) {
            velocity *= HORIZONTAL_REVERSE;
        }
        if ((prediction.y < -.5) || (prediction.y > .5)) {
            velocity *= VERTICAL_REVERSE;
        }
        state = encode2(velocity);
    } else if (row == COLOR_ROW) {
        state = getParticleColor(particle); // will copy over
    } else { // should never happen
        state = COLOR_ZERO;
    }
    return state;
}        

vec4 getEncodedState(
    const int row,
    const int particle,
    const vec2 seed
) {        
    vec4 state;    
    if ((iFrame == 0) || reset()) {
        state = getInitialState(row, particle, seed);
    } else {
        state = calculateNewState(row, particle, seed);
    }
    return state;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    int particle = int(fragCoord.x);
    int row = int(fragCoord.y);    
    if ((row <= LAST_ROW) && (particle < PARTICLE_COUNT)) {
    	fragColor = getEncodedState(row, particle, fragCoord);        
    }
}
