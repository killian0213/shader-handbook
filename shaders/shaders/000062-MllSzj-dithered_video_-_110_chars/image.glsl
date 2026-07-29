// Image (image) — dithered video - 110 chars by FabriceNeyret2
// https://www.shadertoy.com/view/MllSzj

// inspired by https://www.shadertoy.com/view/lllSRj


void mainImage( out vec4 o, vec2 i ) { 

// --- color version (base = 110 chars)
    o = step(texture(iChannel0, i/8.).r, texture(iChannel1,i/iResolution.xy));

    
    
// --- color version + gamma correction ( + 15 chars):     
//   o += step(pow(texture(iChannel0, i/8.),vec4(.45)), texture(iChannel1,i/iResolution.xy));

    
    
// --- B&W version ( base + 1 chars): 
// texture(iChannel0, i/8.).r < texture(iChannel1,i/iResolution.xy).r  ? o++ : o;
    

    
// --- B&W version + gamma correction ( + 9 chars): 
// pow(texture(iChannel0, i/8.).r, .45) < texture(iChannel1,i/iResolution.xy).r  ? o++ : o;
}