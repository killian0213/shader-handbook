// Buffer A (buffer) — Liquid stuff by Nrx
// https://www.shadertoy.com/view/4sK3zm

// Update the velocity and position of each particle

#define COLLISION_SPRING_STIFFNESS_COLLIDER	5000.0
#define COLLISION_SPRING_STIFFNESS_PARTICLE	1500.0
#define COLLISION_SPRING_DAMPING			10.0
#define RADIUS_COLLIDER						0.5
#define RADIUS_PARTICLE						1.0
#define PACKED
#define GRAVITY								10.0
#define TIME_STEP_MAX						0.01
#define VELOCITY_MAX						1.0
#define SPAWN_VELOCITY						vec2 (-200.0, 0.0)
#define SPAWN_POSITION						iResolution.xy - 12.5
#define SQRT3								1.732

#define CEIL(x) float (int (x + 0.9999)) // To workaround a bug with Firefox on Windows...

vec2 particleVelocity;
vec2 particlePosition;
vec2 particleForce;
vec2 particleIdCheck;

void collide (in vec2 offset) {

	// Get the position of the cell
	vec2 cellPosition = floor (particlePosition + offset) + 0.5;

	// Get the particle ID and the collider
	vec4 data = texture (iChannel1, cellPosition / iResolution.xy);
	vec2 particleId = data.rg;
	float collider = data.a;

	// Check whether there is a particle here
	if (offset == vec2 (0.0)) {

		// This is the current particle
		particleIdCheck = particleId;
	}
	else if (particleId.x > 0.0) {

		// Get the velocity and position of this other particle
		data = texture (iChannel0, particleId / iResolution.xy);
		vec2 otherParticleVelocity = data.rg;
		vec2 otherParticlePosition = data.ba;

		// Compute the distance between these 2 particles
		vec2 direction = otherParticlePosition - particlePosition;
		float distSquared = dot (direction, direction);

		// Check whether these 2 particles touch each other
		if (distSquared < 4.0 * RADIUS_PARTICLE * RADIUS_PARTICLE) {

			// Normalize the direction
			float dist = sqrt (distSquared);
			direction /= dist;

			// Apply the collision force (spring)
			float compression = 2.0 * RADIUS_PARTICLE - dist;
			particleForce -= direction * (compression * COLLISION_SPRING_STIFFNESS_PARTICLE - dot (otherParticleVelocity - particleVelocity, direction) * COLLISION_SPRING_DAMPING);
		}
	}

	// Collision with a collider?
	if (collider > 0.5) {

		// Compute the distance between the center of the particle and the collider
		vec2 direction = cellPosition - particlePosition;
		vec2 distCollider = max (abs (direction) - RADIUS_COLLIDER, 0.0);
		float distSquared = dot (distCollider, distCollider);

		// Check whether the particle touches the collider
		if (distSquared < RADIUS_PARTICLE * RADIUS_PARTICLE) {

			// Normalize the direction
			float dist = sqrt (distSquared);
			direction = sign (direction) * distCollider / dist;

			// Apply the collision force (spring)
			float compression = RADIUS_PARTICLE - dist;
			particleForce -= direction * (compression * COLLISION_SPRING_STIFFNESS_COLLIDER + dot (particleVelocity, direction) * COLLISION_SPRING_DAMPING);
		}
	}
}

vec2 rand (in float seed) {
	vec2 n = seed * vec2 (12.9898, 78.233);
	return fract (n.yx * fract (n));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

	// Check for a reset
	bool reset = iFrame == 0 || texture (iChannel2, vec2 (0.5) / iResolution.xy).a > 0.5;

	// Define the particle data
	if (reset) {

		// Define the particle spawning area
		float liquid =
			step (abs (fragCoord.x - iResolution.x * 0.5), iResolution.x * 0.5 - 5.0 - RADIUS_PARTICLE)
			* step (iResolution.y * 0.5, fragCoord.y)
			* step (fragCoord.y, iResolution.y - 5.0 - RADIUS_PARTICLE)
#ifndef PACKED
			* step (mod (fragCoord.x + SQRT3 * fragCoord.y, ceil (2.0 * RADIUS_PARTICLE)), 1.0)
			* step (mod (fragCoord.y, ceil (SQRT3 * RADIUS_PARTICLE)), 1.0);
#else
			* step (mod (fragCoord.x + fragCoord.y, 2.0), 0.5);
#endif
		float rand = 0.01 * cos (fragCoord.x * 13.37 + fragCoord.y * 17.73);

		// Initialize the particle
		particleVelocity = vec2 (0.0);
		particlePosition = liquid > 0.5 ? fragCoord + rand: vec2 (-1.0);
	} else {

		// Get the particle data
		vec4 data = texture (iChannel0, fragCoord / iResolution.xy);
		particleVelocity = data.rg;
		particlePosition = data.ba;
		if (particlePosition.x > 0.0) {

			// Get the gravity
			float gravityDirection = texture (iChannel2, vec2 (1.5, 0.5) / iResolution.xy).r;
			particleForce = GRAVITY * vec2 (cos (gravityDirection), sin (gravityDirection));

			// Check for collisions with nearby particles and colliders
			const float collisionRadius = CEIL (RADIUS_PARTICLE * 2.0);
			for (float i = -collisionRadius; i <= collisionRadius; ++i) {
				for (float j = -collisionRadius; j <= collisionRadius; ++j) {
					collide (vec2 (i, j));
				}
			}

			// Make sure the particle is still tracked
			if (particleIdCheck != fragCoord) {

				// The particle is lost...
				particlePosition = vec2 (-1.0);
			} else {

				// Limit the time step
				float timeStep = min (iTimeDelta, TIME_STEP_MAX);

				// Update the velocity of the particle
				particleVelocity += particleForce * timeStep;

				// Limit the velocity (to avoid losing track of the particle)
				vec2 delta = particleVelocity * timeStep;
				float dist = length (delta);
				if (dist > VELOCITY_MAX) {
					particleVelocity *= VELOCITY_MAX / dist;
				}

				// Update the position of the particle
				particlePosition += particleVelocity * timeStep;
			}
		} else {

			// Spawn a new particle?
			vec2 particleId = 0.5 + floor (iResolution.xy * rand (iTime));
			if (fragCoord == particleId) {
				particleVelocity = SPAWN_VELOCITY;
				particlePosition = SPAWN_POSITION;
			}
		}
	}

	// Update the fragment
	fragColor = vec4 (particleVelocity, particlePosition);
}