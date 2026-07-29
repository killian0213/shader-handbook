// Image (image) — City in a Bottle HD (256 bytes) by KilledByAPixel
// https://www.shadertoy.com/view/7dccRj

// City in a Bottle by Frank Force
// Minified to 256 bytes with help from Xor

void mainImage(out vec4 c, vec2 f)
{
  for (                         // loop
    vec3 p                      // everything is a vec3
    = vec3(f+f, 2)/iResolution, // ray direction
    t = --p,                    // texture
    a = vec3(30.*iTime, 17, 4), // position
    s = p/p,                    // shading
    w = 99.*s;                  // max Z
    a.z < w.z;                  // loop until ray hits max Z
    c.rgb = s*a.z/99.-t.y)      // set pixel color
  {
    ivec3 b = ivec3(a += p);    // advance ray, convert to int
    b.y < (32<b.z && 27<b.x%99 ? b.x/9^b.z/8 : 0)*8%46 ? // collision test
        s != (t = vec3((b&b.x&b.z)%3)/a.z, p /= p) ?     // set texture, cast to light
        w = s : s = a.z/w : s;                           // stop : shading : unused
  }
}