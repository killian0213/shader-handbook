// Image (image) — geometric play -s- by YoheiNishitsuji
// https://www.shadertoy.com/view/3Xj3Dy

// Original shader by Yohei Nishitsuji (https://x.com/YoheiNishitsuji/status/1910686773564629432)
// Adapted for Shadertoy

// HSV to RGB conversion
vec3 hsv(float h, float s, float v) {
  vec4 t = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
  vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
  return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

// 3D Rotation matrix function
mat3 rotate3D(float angle, vec3 axis) {
  axis = normalize(axis);
  float s = sin(angle);
  float c = cos(angle);
  float oc = 1.0 - c;
  
  // Standard 3D rotation matrix formula
  return mat3(
    oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c
  );
}

// Main part
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 r = iResolution.xy;
  vec2 FC = fragCoord.xy;
  
  float t = iTime;
  
  // Initialize output color
  vec4 o = vec4(0, 0, 0, 1);
  
  // Rendering loop
  // i: iteration counter
  // g: geometric field value
  // e: escape multiplier
  // s: scaling factor
  for(float i=0.,g=0.,e=0.,s=0.;++i<18.;) {
    // Create 3D point from 2D coordinates
    // - Center and normalize coordinates based on resolution
    // - Scale by 3.5 to control zoom level
    // - Add g+.5 for z-coordinate (changes each iteration)
    // - Apply 3D rotation based on time for animation
    vec3 p=vec3((FC.xy-.5*r)/r.y*3.5,g+.5)*rotate3D(t*.5,vec3(1,1,0));
    
    // Reset scaling factor for this iteration
    s=1.;
    
    // Fractal iteration loop
    // This is a form of "folding space" in ray fractals
    for(int i=0;i++<40;p=vec3(0,3.01,3)-abs(abs(p)*e-vec3(2.2,3,3)))
      // Multiply scaling factor by escape value
      // e is calculated based on distance from origin (dot product)
      // This creates the "escape time" effect typical in fractals
      s*=e=max(1.,10./dot(p,p));
    
    // Update geometric field value based on current point
    // This creates the flowing/morphing effect in the animation
    g-=mod(length(p.yy-p.xy*.3),p.y)/s*.4;
    
    // Accumulate color using HSV
    o.rgb+=hsv(.08,.8+.3*p.x,s/4e3);
  }
  
  // Output the final color
  fragColor = o;
}