// Image (image) — Liquid stuff by Nrx
// https://www.shadertoy.com/view/4sK3zm

// Display particles and colliders

#define RADIUS_PARTICLE			1.5
//#define GLOW_THICKNESS		1.0 // Choose either GLOW_THICKNESS *or* PARTICLE_COUNT_MIN
#define PARTICLE_COUNT_MIN		2.0
#define VELOCITY_COLOR_FACTOR	0.02

#define FLOOR(x) float (int (x)) // To workaround a bug with Firefox on Windows...

float rand (in vec2 seed) {
	return fract (sin (dot (seed, vec2 (12.9898, 78.233))) * 137.5453);
}

vec3 hsv2rgb (in vec3 hsv) {
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

float segDist (in vec2 p, in vec2 a, in vec2 b) {
	p -= a;
	b -= a;
	return length (p - b * clamp (dot (p, b) / dot (b, b), 0.0, 1.0));
}

vec3 particleColor (in float particleVelocity) {
	return mix (vec3 (0.5, 0.5, 1.0), vec3 (1.0), particleVelocity * VELOCITY_COLOR_FACTOR);
}

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

	// Check whether there is a collider here
	vec4 data = texture (iChannel1, fragCoord / iResolution.xy);
	vec3 color;
	if (data.a > 0.5) {

		// Collider (wood)
		vec2 uv = 0.02 * fragCoord;
		uv = uv.y * 13.0 + sin (uv * 17.0) * sin (uv.yx * 7.0) * sin (iTime * 0.2 + uv);
		color = vec3 (0.8, 0.6, 0.4) * (1.0 - 0.5 * length (fract (uv) - 0.5));
	} else {

		// Background (light squares)
		vec2 uv = 0.05 * fragCoord;
		uv += 0.5 * cos (uv.yx + iTime);
		float angle = rand (floor (uv)) * 3.14159;
		vec3 hsv = vec3 (0.6 + 0.1 * cos (angle), 1.0, 0.2 + 0.1 * cos (angle * iTime));
		color = hsv2rgb (hsv) * smoothstep (1.0, 0.2, length (fract (uv) - 0.5));

		// Check whether there is a particle here
		float particleVelocity = data.b;
		if (particleVelocity >= 0.0) {
			color += particleColor (particleVelocity);
		} else {

			// Look around (spiral loop from the current position)
			vec2 offset = vec2 (0.0);
			vec2 direction = vec2 (1.0, 0.0);
#if defined (GLOW_THICKNESS) && !defined (PARTICLE_COUNT_MIN)
			const float radiusGlow = FLOOR (RADIUS_PARTICLE + GLOW_THICKNESS);
			for (float n = 1.0; n < (2.0 * radiusGlow + 1.0) * (2.0 * radiusGlow + 1.0); ++n) {
				offset += direction;
				if (offset.x == offset.y || (offset.x < 0.0 && offset.x == -offset.y) || (offset.x > 0.0 && offset.x == 1.0 - offset.y)) {
					direction = vec2 (-direction.y, direction.x);
				}
				particleVelocity = texture (iChannel1, (fragCoord + offset) / iResolution.xy).b;
				if (particleVelocity >= 0.0) {
					color += particleColor (particleVelocity) * smoothstep (RADIUS_PARTICLE + GLOW_THICKNESS, RADIUS_PARTICLE, length (offset));
					break;
				}
			}
#elif !defined (GLOW_THICKNESS) && defined (PARTICLE_COUNT_MIN)
			float count = 0.0;
			for (float n = 1.0; n < (2.0 * FLOOR (RADIUS_PARTICLE) + 1.0) * (2.0 * FLOOR (RADIUS_PARTICLE) + 1.0); ++n) {
				offset += direction;
				if (offset.x == offset.y || (offset.x < 0.0 && offset.x == -offset.y) || (offset.x > 0.0 && offset.x == 1.0 - offset.y)) {
					direction = vec2 (-direction.y, direction.x);
				}
				if (dot (offset, offset) <= RADIUS_PARTICLE * RADIUS_PARTICLE) {
					particleVelocity = texture (iChannel1, (fragCoord + offset) / iResolution.xy).b;
					if (particleVelocity >= 0.0 && ++count >= PARTICLE_COUNT_MIN) {
						color += particleColor (particleVelocity);
						break;
					}
				}
			}
#endif
		}
	}

	// Display the direction of the gravity
	data = texture (iChannel2, vec2 (1.5, 0.5) / iResolution.xy);
	float gravityTimer = data.g;
	if (gravityTimer > 0.0) {
		float gravityDirection = data.r;
		vec2 frag = fragCoord - 0.5 * iResolution.xy;
		vec2 direction = vec2 (cos (gravityDirection), sin (gravityDirection));
		vec2 pointA = 25.0 * direction;
		vec2 pointB = 15.0 * direction;
		vec2 offset = 10.0 * vec2 (direction.y, -direction.x);
		float dist = segDist (frag, -pointA, pointA);
		dist = min (dist, segDist (frag, pointA, pointB + offset));
		dist = min (dist, segDist (frag, pointA, pointB - offset));
		color = mix (color, vec3 (smoothstep (4.0, 3.0, dist)), gravityTimer * smoothstep (6.0, 5.0, dist));
	}

	// Set the fragment color
	fragColor = vec4 (color, 1.0);
}