// Image (image) — 2D Realtime Path Tracing by Shane
// https://www.shadertoy.com/view/3tscR8

/*

	2D Realtime Path Tracing
	------------------------

	2D path tracing, or just one ultra expensive Voronoi-Truchet texture, depending on 
    your perspective. :) Technically speaking, this is a very low-sample path traced 
    rendering of a 2D distance field that has been stored in the channels of a screen 
    buffer, then camera reprojected a few times to give the impression of a much higher 
    sampling... I'll explain that in more detail further down the page. :) The 2D 
    distance field itself is an animated bidirectional Truchet pattern, encoded into 
    one of the faces of the cube map.

	I love the 2D path tracing aesthetic. In fact, I even like the low sampled realtime
    noisy imagery as well, but that's a personal thing. Not everyone likes digital noise, 
    and not everyone likes the expense of path tracing, which is fair enough, so that's 
    why you don't see too many examples on here. There's also the issue of being forced 
    to construct uninspiring low instruction scenery, which can be limiting as well.

    However, it's possible to use a buffer with precalculated values to enable better 
    scenery, which I'm sure most are aware of. What people may not know, however, is
    that there are great denoising techniques to alleviate noise issues -- Not entirely, 
    but enough so that some people might like to give realtime path tracing, or path 
    tracing in general, a try.

    In this case, each screen render is stored in a buffer and mixed with the next to 
    blend in the noise. It's very effective on static imagery for anyone who's tried it. 
    Unfortunately, with moving imagery, you see ghosting trails, which look kind of cool, 
    but don't help with the illusion. Thankfully, it's possible to calculate  where the 
    current screen render is in relation to the previous one, then blend in the previous 
    render at the new position. This alleviates ghosting to quite a large degree. The end 
	result is a low sampled moving image that looks like (or is, in fact) a high sampled, 
    much more appealing one... to most people. Ironically, I love the noisy, pixelated 
    fake 90s demo aesthetic, which means this is redundant to me. :D

	Anyway, this is just a proof of concept to show that it's possible, but I wouldn't 
    pay too much attention to the code itself... It's correct enough to get the job done, 
    but was slapped together pretty quickly. Honestly, I wouldn't want to try to
    interpret this, but I've commented it to enable anyone to get the general idea.
    
    Additionally, there are a few compiler directives in the "Common" tab to try that 
    might help.

    By the way, this can be extended to 3D situations as well, and I intend to show that 
	at some stage. In the meantime, IQ has an awesome 3D gloabally illuminated example, 
	complete with denoising camera reprojection on Shadertoy that's well worth the look, 
    especially since examples like that are thin on the ground. On a side note, I remember 
    reading somewhere that if it wasn't for IQ, the average graphics programmer would be 
    several years behind where they are today. :)


    Useful links:

	// 3D temporal reprojection: IQ puts up a lot of difficult to find code with
    // very little fanfare. This is one example.
    Some boxes - iq
    https://www.shadertoy.com/view/Xd2fzR


*/

void mainImage(out vec4 fragColor, in vec2 fragCoord){

    // Retrieving the stored color.
    vec4 col = texture(iChannel0, fragCoord/iResolution.xy);

    // Gamma correction and screen presentation.
    fragColor = pow(col, vec4(.4545));
}