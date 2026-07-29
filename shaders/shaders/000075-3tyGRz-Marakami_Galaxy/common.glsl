// Common (common) — Marakami Galaxy by PixelPhil
// https://www.shadertoy.com/view/3tyGRz

mat4 rotationX( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
	return mat4(1.0, 0,	 0,	0,
			 	0, 	 c,	-s,	0,
				0, 	 s,	 c,	0,
				0, 	 0,  0,	1);
}

mat4 rotationY( in float angle ) {
    
    float c = cos(angle);
    float s = sin(angle);
    
	return mat4( c, 0,	 s,	0,
			 	 0,	1.0, 0,	0,
				-s,	0,	 c,	0,
				 0, 0,	 0,	1);
}

mat4 rotationZ( in float angle ) {
    float c = cos(angle);
    float s = sin(angle);
    
	return mat4(c, -s,	0,	0,
			 	s,	c,	0,	0,
				0,	0,	1,	0,
				0,	0,	0,	1);
}