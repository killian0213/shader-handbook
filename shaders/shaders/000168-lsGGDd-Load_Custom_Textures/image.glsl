// Image (image) — Load Custom Textures by AntoineC
// https://www.shadertoy.com/view/lsGGDd

// ----------------------------------------------------------------------------------------
//	"Load Custom Textures" by Antoine Clappier - March 2015
//
//	Licensed under a Creative Commons Attribution-ShareAlike 4.0 International License
//	http://creativecommons.org/licenses/by-sa/4.0/
// ----------------------------------------------------------------------------------------

// Image credits:
//  Nasa, http://visibleearth.nasa.gov/


/*

A simple method to load custom image textures in Shadertoy!
-----------------------------------------------------------

The idea is to call directly the SetTexture function found in Shadertoy js code.

Here is how to loads the three textures needed for this shader:
 - Open the javascript console of your browser:
				   Mac      /     Windows
	Chrome:  cmd + opt + J  /  ctrl + shift J
	Firefox: cmd + opt + K  /  ctrl + shift K
    IE:          na         /  F12   

- Then copy the following lines in the console to load custom 2048x2048 textures:

gShaderToy.SetTexture(0, {mSrc:'https://dl.dropboxusercontent.com/s/88u2uo8dxdmgzxo/world2.jpg?dl=0', mType:'texture', mID:1, mSampler:{ filter: 'mipmap', wrap: 'repeat', vflip:'true', srgb:'false', internal:'byte' }});
gShaderToy.SetTexture(1, {mSrc:'https://dl.dropboxusercontent.com/s/5rdhhnvnr5mochq/cloud2.jpg?dl=0', mType:'texture', mID:1, mSampler:{ filter: 'mipmap', wrap: 'repeat', vflip:'true', srgb:'false', internal:'byte' }});
gShaderToy.SetTexture(2, {mSrc:'https://dl.dropboxusercontent.com/s/ojl5zoxgbdn5w5s/light2.jpg?dl=0', mType:'texture', mID:1, mSampler:{ filter: 'mipmap', wrap: 'repeat', vflip:'true', srgb:'false', internal:'byte' }});

- Or, the following lines for 1024x1024 textures:

gShaderToy.SetTexture(0, {mSrc:'https://dl.dropboxusercontent.com/s/0j4q7p4x0upj40q/world1.jpg?dl=0', mType:'texture', mID:1, mSampler:{ filter: 'mipmap', wrap: 'repeat', vflip:'true', srgb:'false', internal:'byte' }});
gShaderToy.SetTexture(1, {mSrc:'https://dl.dropboxusercontent.com/s/26xr0l2ly68xgzh/cloud1.jpg?dl=0', mType:'texture', mID:1, mSampler:{ filter: 'mipmap', wrap: 'repeat', vflip:'true', srgb:'false', internal:'byte' }});
gShaderToy.SetTexture(2, {mSrc:'https://dl.dropboxusercontent.com/s/b67udjdsw4gzf99/light1.jpg?dl=0', mType:'texture', mID:1, mSampler:{ filter: 'mipmap', wrap: 'repeat', vflip:'true', srgb:'false', internal:'byte' }});

- hit return to execute and load the textures.


Using your own images:
 - The first argument of gShaderToy.SetTexture() is the iChannel index from 0 to 3
 - The second argument defines the url and additional parameters of the texture.
 - Your images must be hosted on a server (such as Dropbox) that allows direct link 
   from a different domain in javascript. Otherwise, you will get an error message:
   "'example.com has been blocked from loading by Cross-Origin Resource Sharing policy"

*/




#define Pi 3.14159265359
#define d2r(a) ((a)*180.0/Pi)
#define RGB(r,g,b) pow(vec3(float(r), float(g), float(b))/255.0, vec3(2.22))

#define R0 1.0000	// Nomralized Earth radius (6360 km)
#define R1 1.0094	// Atmosphere radius (6420 km) 

vec3 Render(in vec2 uv)
{
    vec3 Color = vec3(0.0);
    float t = 1.0*iTime;

    // Sun:
    vec3 L0 = vec3(cos(0.1*t), 0.0, sin(0.1*t));
    float cs = cos(d2r(90.0 + 23.4)), sn = sin(d2r(90.0 + 23.4));
    vec3 LightDir = vec3(cs*L0.x + sn*L0.y, cs*L0.y - sn*L0.x, L0.z);

    vec2 SunC = -5.0*LightDir.xy/LightDir.z - uv;
    float Halo = max(0.0, dot(LightDir, normalize(vec3(uv.x, uv.y, -5.0))));
	float SunRay = pow(texture(iChannel1, vec2(0.1*t, atan(SunC.x,SunC.y))).xyz, vec3(2.22)).x;
    float Sun = 0.05*(1.0 + SunRay)*pow(Halo, 1000.0)*smoothstep(0.85, 1.3, length(SunC+uv));
   
    // Sphere hit:
    float z = 1.0 - dot(uv, uv);
    if(z < 0.0)
    {
        Sun += 1.5*pow(Halo, 10000.0);
        return Sun*RGB(255,250,230);
    }
    
    // Intersection:
    vec3 Normal     = vec3(uv.x, uv.y, sqrt(z));
    vec3 Reflection = reflect(vec3(0.0, 0.0, 1.0), Normal);


    // Textures:
	float U = 1.0-atan(Normal.z, Normal.x) / (2.0*Pi);
	float V = 1.0-(atan(length(Normal.xz), Normal.y)) / Pi;
 	vec3 Ground = pow(texture(iChannel0, vec2(U-t/80.0, V)).xyz, vec3(2.22));
	vec3 Cloud  = pow(texture(iChannel1, vec2(U-t/75.0, V)).xyz, vec3(2.22));
	vec3 Cloud2 = pow(texture(iChannel1, vec2(U-t/75.0+0.001, V)).xyz, vec3(2.22));
	vec3 KsMap  = pow(texture(iChannel1, vec2( -t/200.0, 0.8)).xyz, vec3(2.22));
	vec3 Night  = pow(texture(iChannel2, vec2(U-t/80.0, V)).xyz, vec3(2.22));
	
    // Shading
	float Diffuse     = max(0.0, dot(Normal, LightDir));
	float Specular    = max(0.0, dot(-Reflection, LightDir));
    float Scatter     = 4.0*pow((sqrt(R1 - dot(uv, uv)) - Normal.z) / sqrt(R1-R0), 1.35);
    float Extinct     = pow(1.0 - Diffuse, 4.0);
    float Sea         = smoothstep(1.0, 0.0, 100.0*length(Ground - RGB(2,5,20)));
    float Shadow      = 1.0 - pow(Cloud2.x, 0.2);
    
    vec3 Light = mix(vec3(1.0), RGB(255, 150, 40), Extinct);
 
    Color = Shadow*(Ground + 0.8*Sea*RGB(19,35,60));
    Color = mix(Color, vec3(1.0), 2.0*Cloud);
    Color *= Light*Diffuse;
    Color += 2.0*Light*Diffuse*(0.3 + 0.7*KsMap.x)*mix(0.03, 0.4, Sea)*pow(Specular, (0.8 + 0.2*KsMap.x)*mix(9.0, 200.0, Sea));
    Color += pow(max(0.0, dot(Normal, -LightDir)), 2.0)*Night*(1.0-pow(Cloud.x, 0.2));
    Color *= mix(vec3(1.0), RGB(255-58,255-72,255-90), 1.0*Scatter);
    Color += 4.0*Diffuse*(1.0 + Sea)*Scatter*RGB(58,72,90);

    Color += Sun*RGB(255,250,230);
    
    return Color;
}

void mainImage( out vec4 fragColor, in vec2 In )
{
	vec2 uv = (2.0*In.xy - iResolution.xy) / iResolution.y;
    vec3 Color = pow(Render(1.05*uv),  vec3(0.45));
	fragColor = vec4(Color, 1.0);
}