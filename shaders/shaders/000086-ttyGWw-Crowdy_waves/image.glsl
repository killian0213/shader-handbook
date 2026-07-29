// Image (image) — Crowdy waves by rory618
// https://www.shadertoy.com/view/ttyGWw

bool keyIsDown( float key ) {
    return texture( iChannel3, vec2(key,0.75) ).x > .5;
}

vec4 A(int i){
    return texture(iChannel0, (vec2((i-1)%int(R.x),(i-1)/int(R.x))+.5)/R.xy);
}

void mainImage( out vec4 O, in vec2 I )
{
    if(keyIsDown( 32.5/256.0 )){
        O = texture(iChannel1, I/R.xy)/R.x/R.y*10.;
    } else {
    	O = texture(iChannel2, I/R.xy);
    }
}