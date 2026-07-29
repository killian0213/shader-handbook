// Buffer C (buffer) — Liquid stuff by Nrx
// https://www.shadertoy.com/view/4sK3zm

// Handle player inputs

#define KEY_R		(vec2 (82.5, 0.5) / 256.0)
#define KEY_LEFT	(vec2 (37.5, 0.5) / 256.0)
#define KEY_RIGHT	(vec2 (39.5, 0.5) / 256.0)
#define KEY_SPACE	(vec2 (32.5, 0.5) / 256.0)
#define PI			3.14159265359

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

	// Don't waste time
	if (fragCoord.x > 2.0 || fragCoord.y > 1.0) {
		discard;
	}

	// Get the status of the reset (R) key
	float reset = texture (iChannel3, KEY_R).r;

	// Check what to do
	if (fragCoord.x < 1.0) {

		// Update the fragment
		fragColor = vec4 (iMouse.xyz, reset);
	} else {

		// Set the direction of the gravity
		float gravityDirection;
		float gravityTimer;
		if (iFrame == 0 || reset > 0.5) {

			// Reset the gravity
			gravityDirection = -PI * 0.5;
			gravityTimer = 0.0;
		} else {

			// Get the current values
			vec2 data = texture (iChannel2, fragCoord / iResolution.xy).rg;
			gravityDirection = data.r;
			gravityTimer = data.g;

			// Get the status of the left, right and space keys
			float keyLeft = texture (iChannel3, KEY_LEFT).r;
			float keyRight = texture (iChannel3, KEY_RIGHT).r;
			float keySpace = texture (iChannel3, KEY_SPACE).r;
			if (keyLeft + keyRight + keySpace < 0.5) {
				gravityTimer = max (0.0, gravityTimer - iTimeDelta * 5.0);
			} else {
				if (keyLeft > 0.5) {
					gravityDirection -= PI * 0.5 * iTimeDelta;
				} else if (keyRight > 0.5) {
					gravityDirection += PI * 0.5 * iTimeDelta;
				} else if (gravityTimer == 0.0) {
					gravityDirection += PI;
				}
				gravityTimer = 1.0;
			}
		}

		// Update the fragment
		fragColor = vec4 (gravityDirection, gravityTimer, 0.0, 0.0);
	}
}