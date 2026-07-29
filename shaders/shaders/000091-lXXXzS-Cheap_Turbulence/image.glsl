// Image (image) — Cheap Turbulence by Xor
// https://www.shadertoy.com/view/lXXXzS

/*
    "Cheap Turbulence" by @XorDev

    Simulating proper fluid dynamics can be complicated and requires a back buffer or multi-pass setup.

    Sometimes, you just want to emulate some smoke or something simple, and you don't want to go through all that trouble.

    This method is very simple! Start with pixel coordinates and scale them down as desired, then with a for loop,
    you should do a sine wave offset. In my case I'm doing "p.x+=sin(p.y)".
    To animate it, you can add a time offset to the sine wave, and it also helps to shift each iteration with the
    iterator "i" to break up visible patterns.

    Next, you want to rotate the coordinates and scale down. It could be as simple as p=p.yx/0.8 or a rotation matrix like mat2(.8,-.6,.6,.8).

    Now the resulting p coordinates will appear turbulent, and you can use these coordinates in color function.
    My color equation looks like this:

    fragColor=sin(p.xyxy*.3+vec4(0,1,2,3))*.5+.5
    
    Smooth, continious equations look best
*/
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Scaled pixel coordinates
    vec2 p=fragCoord.xy/iResolution.y*6.;
    
    //8 wave passes
    for(float i=0.0; i<8.0;i++)
    {
        //Add a simple sine wave with an offset and animation
        p.x += sin(p.y+i+iTime*.3);
        //Rotate and scale down
        p *= mat2(6,-8,8,6)/8.;
    }
    //Pick a color using the turbulent coordinates
    fragColor = sin(p.xyxy*.3+vec4(0,1,2,3))*.5+.5;
}