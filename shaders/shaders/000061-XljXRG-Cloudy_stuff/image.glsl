// Image (image) — Cloudy stuff by Nrx
// https://www.shadertoy.com/view/XljXRG

// From https://www.shadertoy.com/view/XdBGDd
// From https://www.shadertoy.com/view/MljXDw (from Duke)

// Rendering parameters
#define CAMERA_FOCAL_LENGTH	3.0
#define RAY_STEP_MAX		100.0
#define RAY_LENGTH_MAX		150.0
#define NOISE_FACTOR		2.0
#define DIST_CORRECTION		0.6
#define DIST_MIN			0.6
#define DENSITY_FACTOR_STEP	0.01
#define DENSITY_FACTOR_DIST	0.3

// Math constants
#define PI	3.14159265359

// Rotation on the Z axis
vec3 vRotateZ (in vec3 p, in float angle) {
	float c = cos (angle);
	float s = sin (angle);
	return vec3 (c * p.x + s * p.y, c * p.y - s * p.x, p.z);
}

// Noise (from iq)
float noise (in vec3 p) {
	vec3 f = fract (p);
	p = floor (p);
	f = f * f * (3.0 - 2.0 * f);
	f.xy += p.xy + p.z * vec2 (37.0, 17.0);
	f.xy = texture (iChannel0, (f.xy + 0.5) / 256.0, -256.0).yx;
	return mix (f.x, f.y, f.z);
}

// FBM
float fbm (in vec3 p) {
	return noise (p) + noise (p * 2.0) / 2.0 + noise (p * 4.0) / 4.0;
}

// HSV to RGB
vec3 hsv2rgb (in vec3 hsv) {
	hsv.yz = clamp (hsv.yz, 0.0, 1.0);
	return hsv.z * (1.0 + hsv.y * clamp (abs (fract (hsv.x + vec3 (0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 2.0, -1.0, 0.0));
}

// Distance to the scene
float distScene (in vec3 p, out float hue) {

	// Global deformation
	p.xy += vec2 (3.0 * sin (p.z * 0.1 + 2.0 * iTime), 2.0 * sin (p.z * 0.2 + iTime));

	// Cylinder
	float cylinder = 6.0 - length (p.xy) + sin (atan (p.y, p.x) * 6.0) * sin (p.z);
	float d = max (cylinder, -cylinder - 6.0);
	hue = 0.3 + 0.3 * noise (p * 0.2);

	// Rotating spheres
	vec3 q = vRotateZ (p, sin (iTime * 4.0));
	q.xy = mod (q.xy, 6.5) - 0.5 * 6.5;
	q.z = mod (q.z + 0.5 * 32.0, 32.0) - 0.5 * 32.0;
	float sphereTorus = max (length (q) - 3.0, -cylinder);

	// Torus
	q.xy = vec2 (length (p.xy) - 6.0, q.z);
	sphereTorus = min (sphereTorus, length (q.xy) - 3.0);
	if (sphereTorus < d) {
		d = sphereTorus;
		hue = 0.3;
	}

	// Return the distance
	return d;
}

// Main function
void mainImage (out vec4 fragColor, in vec2 fragCoord) {

	// Define the position and orientation of the camera
	vec3 rayOrigin = vec3 (6.0 * cos (iTime * 1.5) + 0.1 * cos (iTime * 10.0), 0.1 * cos (iTime * 20.0), iTime * 20.0 + 5.0 * cos (iTime * 2.0));
	vec3 cameraForward = vec3 (-rayOrigin.xy, 15.0 * cos (iTime * 0.6));
	vec3 cameraUp = vRotateZ (vec3 (0.0, 1.0, 0.0), PI * sin (iTime) * sin (iTime * 0.2));
	mat3 cameraOrientation;
	cameraOrientation [2] = normalize (cameraForward);
	cameraOrientation [0] = normalize (cross (cameraUp, cameraForward));
	cameraOrientation [1] = cross (cameraOrientation [2], cameraOrientation [0]);
	vec3 rayDirection = cameraOrientation * normalize (vec3 ((2.0 * fragCoord.xy - iResolution.xy) / iResolution.y, CAMERA_FOCAL_LENGTH));

	// Set the background color
	vec3 colorBackground = vec3 (0.0);

	// Ray marching
	float densityTotal = 0.0;
	vec3 colorTotal = vec3 (0.0);
	float rayLength = 0.0;
	for (float rayStep = 0.0; rayStep < RAY_STEP_MAX; ++rayStep) {

		// Compute the maximum density
		float densityMax = 1.0 - rayLength / RAY_LENGTH_MAX - rayStep * DENSITY_FACTOR_STEP;
		if (densityTotal > densityMax) {
			break;
		}

		// Get the scene information
		vec3 p = rayOrigin + rayDirection * rayLength;
		float hue;
		float dist = (distScene (p, hue) + NOISE_FACTOR * (fbm (p) - 0.5)) * DIST_CORRECTION;
		if (dist < 0.0) {

			// Compute the local density
			float densityLocal = (densityTotal - densityMax) * dist * DENSITY_FACTOR_DIST;
			densityTotal += densityLocal;

			// Update the color
			vec3 colorLocal = hsv2rgb (vec3 (hue, 0.5, 0.8));
			colorTotal += colorLocal * densityLocal;
		}

		// Go ahead
		rayLength += max (dist, DIST_MIN);
	}
	colorTotal += colorBackground * (1.0 - densityTotal);

	// Set the fragment color
	fragColor = vec4 (colorTotal, 1.0);
}