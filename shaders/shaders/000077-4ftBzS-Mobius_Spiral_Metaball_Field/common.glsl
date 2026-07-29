// Common (common) — Mobius Spiral Metaball Field by Shane
// https://www.shadertoy.com/view/4ftBzS

// Standard 2D rotation formula.
mat2 rot2(in float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

// Fabrice's fork of "Integer Hash - III" by IQ: https://shadertoy.com/view/4tXyWN
float hash21(vec2 f){
    //f = mod(f + 16384., 16384.); // Annoying GPU hash related hack.
    uvec2 p = floatBitsToUint(f + 1024.);
    p = 1664525U*(p>>1U^p.yx);
    return float(1103515245U*(p.x^(p.y>>3U)))/float(0xffffffffU);
}

// IQ's box formula, wich rounding.
float sBoxS(in vec2 p, in vec2 b, in float rf){
  
  vec2 d = abs(p) - b + rf;
  return min(max(d.x, d.y), 0.) + length(max(d, 0.)) - rf;
}

