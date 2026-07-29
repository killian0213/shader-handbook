// Image (image) — Beyond A Colder War, Intro Scene by msm01
// https://www.shadertoy.com/view/dssBD7

// A Colder War, by Charles Stross, is a short story set in a world where
// the Miskatonic Antarctica Expedition really happened in the 1930ies as
// described in "At The Mountains Of Madness" by H.P. Lovecraft.
// But the action takes place much later, during the 1980ies, at the peak
// of Cold War, and explores what would have happened if archeological
// artifacts (i.e. "ancient technology") had replaced nukes in the global
// strategic game...

// If you're a Cthulhu Mythos fan, try it ! It's entertaining, funny (in
// a sick, twisted, post-Lovecraftian sort-of way) plus it's filled with
// references. You can actually read it online for free :
// www.infinityplus.co.uk/stories/colderwar.htm

// This shader is a fanart for this story. At the beginning, it was just
// another attempt at 2D space art but, as I added more details, it
// started to make sense : it could be a scene taken from "A Colder War",
// or more accurately, from its sequel. Set in 1996, it would be a story
// paying tribute to this great period with all the related iconography :
// green military footage (the Gulf War), emerging computer graphics, led
// displays, and old technology pushed to new heights... like a freaking
// Super-Concorde with nuclear propulsion, orbital capability, optical
// cloaking, and a few other tricks up his wings !
// Which, by the way, would provide outstanding action scenes in case of
// Mi-Go infestation ! So I added Lovecraft's favorite crustaceous fungi
// into the shader. They swarm around the shrines of Draxakar like radio-
// active fireflies, and there must be a good reason for this... as Roger
// will soon learn.

// Anyway. Sorry for the (messy, at times seemingly illogical) code : I
// try to do things with some structure, but inspiration is doing its own
// non-linear thing, I keep adding small details and my left brain has to
// tie it all together afterwards.
// Also I'm trying new things here so if you enjoy this kind of content,
// please say it loud in the comments. It might influence what I have in
// store for you (i.e. the coming shaders may or may not include some
// story, depending on how well this one is received) I have MANY other
// 2D shaders to come, which are begging for some explanatory text... and
// extra-planetary fiction. :)

// Also : yes, someday I might really write "Beyond a Colder War". In the
// beginning, I had no inspiration, but after a while, that changed... I
// guess thinking about 90ies technology and a nuclear Super Concorde is
// just too enticing ! Skaven's soundtrack certainly had an effect too.
// Btw, have you listened to his lastest music, "Exhumed Glory" ? Or
// "Loserboy" ? These go straight into the "Beyond A Colder War" album...
// ...with "Inconsequentialize", of course !
// If I ever write the damn thing, it will obviously be released as a
// fanfic too and free to read online. Don't hold your breath, though :
// I'm quite slow and my health ain't what it used to be. But inspiration
// is there, and I get stronger flashes these days, sooooo... I guess you
// never know. :)

// Sorry for talking too much.

// Use this code as you wish, just try to give proper credit when so.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

// Music is "Inconsequentialize" by Skaven, thanks A LOT for sharing your
// productions with a creator-friendly licence. Your music ROCKS, man !
// https://soundcloud.com/skaven252/inconsequentialize
// https://creativecommons.org/licenses/by-nc-sa/3.0/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
     vec2 p = fragCoord.xy/iResolution.xy;
     
     vec4 col = texture(iChannel0,p);

     // -sigh- "At last it is done..."
     fragColor = col;
}