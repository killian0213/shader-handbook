// Image (image) — Art : Squigly by Gijs
// https://www.shadertoy.com/view/MtBSWR

//const numbers
const float Pi = 3.1415;
const float Tau = 2.*Pi;

//Colors
const vec3  Color_BackGround = vec3( 34,  30,  38)/256.;
const vec3  Color_Ring1      = vec3( 10, 205, 203)/256.;
const vec3  Color_Ring2      = vec3( 46,  72,  82)/256.;
const vec3  Color_Ring3      = vec3( 54, 147, 147)/256.;

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    //Scaling
	vec2 Scaled = (fragCoord*2.-iResolution.xy)/iResolution.y*.6;
    float t = 2./iResolution.y;
    
    //Info
    float Length = length(Scaled);
    float Angle  = atan(Scaled.y,Scaled.x)+Pi;//[-Pi,Pi]->[0,2Pi]
    float Wave = mod(iTime*2.,Tau);//[0,2Pi]
    
    //Background
	vec3 Color = Color_BackGround;  
    
    //Calculating
    float AngleDifference = abs(Wave-Angle);
    float DistanceToWave  = min(AngleDifference,Tau-AngleDifference);
    float FinalMultiplier = pow(max(1.,DistanceToWave),-4.);
    
    float Ring1 = .50  + 0.03*cos(Angle*7.       )*FinalMultiplier;
    float Ring2 = .485 + 0.03*cos(Angle*7.+Tau/3.)*FinalMultiplier;
    float Ring3 = .47  + 0.03*cos(Angle*7.-Tau/3.)*FinalMultiplier;
    
    //Drawing
    
    Color = mix(Color,Color_Ring1,smoothstep(0.01+t,0.01,abs(Ring1-Length)));
    Color = mix(Color,Color_Ring2,smoothstep(0.01+t,0.01,abs(Ring2-Length)));
    Color = mix(Color,Color_Ring3,smoothstep(0.01+t,0.01,abs(Ring3-Length)));

    //Final
	fragColor = vec4(Color,1.0);
}