// Image (image) — Super Fast GI(Oren Nayar) by 834144373
// https://www.shadertoy.com/view/MdVfW3

/*
	Super Fast GI(Oren Nayar) by 834144373

	License: CC3.0 BY-NC-SA
	
	hum...it seems that the number 834... not friendly to read,
		or you can call me TNWX or 恬纳微晰,my really name is 祝元洪(YuanHong Zhu)
	
	All details you can easy find on the "common" and "BufA"

*/

/*
	And you didn't read wrong words,more and more confidential
	will be coming soon
*/

void mainImage( out vec4 C, in vec2 U )
{
    vec2 uv = U/R;
    C = texture(iChannel0,uv);
    
    /*
		We should must convert the linear RGB to gamma,
		As my think,we do all path tracing light transport is base on the linear.
    Note: Gamma is correct the luminance,
		 human's eyes just interesting in the dark eara,
		 so we must to bright the lower luminance. 

		 The simple gamma is pow(c,2.2),and the other screen with 1.8，2.4，2.6....
		 but like my screen supports sRGB.

		hum...and after class thinking,the screen already do the correct,why I must correct again? 
	*/
    
    //C.rgb = pow(C.rgb,vec3(1./2.2));
    /*
		Thanks for mantra report the bug on linux.
    	hum...I use wrong again with "clamp()" function in Linear2sRGB()
	*/
	C.rgb = Linear2sRGB(C.rgb);
	
}