// Buffer A (buffer) — [SH18] Hoooman: Human head by ThomasSchander
// https://www.shadertoy.com/view/XttczS

vec2 uv;

vec2 unpackCoord(float f) 
{
    return vec2(mod(f, 512.0),floor(f / 512.0)) / 511.0;
}

vec3 unpackParams(float f) 
{
    return vec3(mod(f, 128.0),mod(floor(f / 128.0), 128.0),floor(f / (128.0*128.0)))/127.0;
}

// https://www.shadertoy.com/view/lsSSDt
vec3 barycentric(vec2 a, vec2 b, vec2 c, vec2 p)
{
    float d = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y);
    float alpha = ((b.y - c.y) * (p.x - c.x)+(c.x - b.x) * (p.y - c.y)) / d;
    float beta = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / d;
    return vec3(alpha, beta, 1.0 - alpha - beta);
}

vec3 inRange3(vec3 p)
{
    return step(p, vec3(1.0)) * step(vec3(0.0), p);
}

float inRangeAll(vec3 p)
{
    vec3 r = inRange3(p);    
    return r.x * r.y * r.z;
}

float SmoothTri(float pA, float pB, float pC, float pCol1)
{
	vec3 bar = barycentric(unpackCoord(pA), unpackCoord(pB), unpackCoord(pC), uv);
    return inRangeAll(bar) * dot(unpackParams(pCol1), bar);
}

float getHeadDepth()
{
     float col = 0.0;
    col = max(col, SmoothTri(222042., 250260.,237895., 234171.));
col = max(col, SmoothTri(135554., 138560.,103836., 1267168.));
col = max(col, SmoothTri(135554., 103836.,116663., 1795808.));
col = max(col, SmoothTri(125770., 111472.,138560., 709510.));
col = max(col, SmoothTri(39755., 59688.,45251., 24.));
col = max(col, SmoothTri(164286., 159630.,143291., 1797986.));
col = max(col, SmoothTri(205259., 198653.,245757., 1110113.));
col = max(col, SmoothTri(151508., 160705.,143291., 1798642.));
col = max(col, SmoothTri(166700., 153394.,166225., 1149713.));
col = max(col, SmoothTri(39755., 65434.,72039., 414488.));
col = max(col, SmoothTri(133117., 128979.,112125., 1980530.));
col = max(col, SmoothTri(139191., 135554.,116663., 1798249.));
col = max(col, SmoothTri(170437., 172001.,180706., 1768928.));
col = max(col, SmoothTri(198623., 195003.,189391., 1305054.));
col = max(col, SmoothTri(160705., 158169.,162244., 1799779.));
col = max(col, SmoothTri(224055., 181549.,222042., 969754.));
col = max(col, SmoothTri(187822., 191376.,184218., 1403734.));
col = max(col, SmoothTri(181549., 187241.,199532., 1336344.));
col = max(col, SmoothTri(111472., 125770.,97106., 213799.));
col = max(col, SmoothTri(245757., 250260.,232865., 1282755.));
col = max(col, SmoothTri(81833., 83435.,105469., 1793707.));
col = max(col, SmoothTri(31229., 53190.,33144., 611495.));
col = max(col, SmoothTri(141075., 141115.,141589., 278784.));
col = max(col, SmoothTri(163079., 153886.,167204., 148743.));
col = max(col, SmoothTri(172541., 186354.,174571., 2028924.));
col = max(col, SmoothTri(163809., 161767.,162799., 2029930.));
col = max(col, SmoothTri(169916., 184282.,189391., 1305822.));
col = max(col, SmoothTri(181185., 178093.,169916., 1550802.));
col = max(col, SmoothTri(33144., 1021.,31229., 647717.));
col = max(col, SmoothTri(33144., 738.,862., 1204261.));
col = max(col, SmoothTri(190238., 181549.,215328., 3072.));
col = max(col, SmoothTri(177422., 174845.,167161., 16774.));
col = max(col, SmoothTri(158169., 160705.,154594., 1864172.));
col = max(col, SmoothTri(142333., 149989.,142310., 1850097.));
col = max(col, SmoothTri(45251., 738.,39755., 401408.));
col = max(col, SmoothTri(166225., 187241.,181549., 402502.));
col = max(col, SmoothTri(135554., 139191.,159630., 1553632.));
col = max(col, SmoothTri(232865., 205259.,245757., 1110222.));
col = max(col, SmoothTri(195446., 184701.,195979., 1403090.));
col = max(col, SmoothTri(136657., 139191.,116663., 1799410.));
col = max(col, SmoothTri(137706., 142333.,142310., 1849590.));
col = max(col, SmoothTri(149501., 149989.,142333., 1866486.));
col = max(col, SmoothTri(138560., 134466.,125770., 98347.));
col = max(col, SmoothTri(65499., 31229.,82429., 971695.));
col = max(col, SmoothTri(166225., 153394.,138560., 707398.));
col = max(col, SmoothTri(141589., 150317.,154372., 100881.));
col = max(col, SmoothTri(105469., 111032.,81833., 718189.));
col = max(col, SmoothTri(112125., 128979.,117215., 1980536.));
col = max(col, SmoothTri(180076., 166225.,159630., 1549127.));
col = max(col, SmoothTri(184218., 191376.,184701., 1338197.));
col = max(col, SmoothTri(250260., 260083.,257965., 16421.));
col = max(col, SmoothTri(232865., 250260.,222042., 971470.));
col = max(col, SmoothTri(199532., 201614.,204161., 1420497.));
col = max(col, SmoothTri(195446., 195979.,201614., 1469138.));
col = max(col, SmoothTri(195003., 198623.,200653., 1568595.));
col = max(col, SmoothTri(181549., 166700.,166225., 1149080.));
col = max(col, SmoothTri(168739., 177422.,163079., 115468.));
col = max(col, SmoothTri(164301., 162799.,169440., 2047476.));
col = max(col, SmoothTri(172001., 170437.,169939., 1945723.));
col = max(col, SmoothTri(194557., 186354.,172541., 2045277.));
col = max(col, SmoothTri(31256., 10814.,40066., 4096.));
col = max(col, SmoothTri(198653., 205259.,198623., 1552608.));
col = max(col, SmoothTri(196085., 194557.,198653., 1584863.));
col = max(col, SmoothTri(39755., 72039.,72012., 3224.));
col = max(col, SmoothTri(150317., 154377.,154372., 99604.));
col = max(col, SmoothTri(163079., 177422.,162052., 49927.));
col = max(col, SmoothTri(101744., 72039.,81833., 707742.));
col = max(col, SmoothTri(103836., 81833.,111032., 1742285.));
col = max(col, SmoothTri(237895., 224055.,222042., 969998.));
col = max(col, SmoothTri(143291., 159630.,139191., 1732461.));
col = max(col, SmoothTri(141253., 146392.,143291., 1800556.));
col = max(col, SmoothTri(245757., 260083.,250260., 606275.));
col = max(col, SmoothTri(181027., 181512.,179495., 229507.));
col = max(col, SmoothTri(142638., 141589.,141115., 34967.));
col = max(col, SmoothTri(142638., 150317.,141589., 281111.));
col = max(col, SmoothTri(141589., 155902.,141075., 17.));
col = max(col, SmoothTri(169440., 164861.,172541., 2047740.));
col = max(col, SmoothTri(128979., 133117.,137706., 1948016.));
col = max(col, SmoothTri(128979., 136657.,116663., 1800560.));
col = max(col, SmoothTri(138560., 135554.,166225., 1159211.));
col = max(col, SmoothTri(135554., 159630.,166225., 1159008.));
col = max(col, SmoothTri(159741., 164861.,159216., 1883889.));
col = max(col, SmoothTri(159741., 159216.,154594., 1866097.));
col = max(col, SmoothTri(202146., 198559.,200653., 1567578.));
col = max(col, SmoothTri(208793., 205259.,232865., 1290457.));
col = max(col, SmoothTri(159630., 164286.,169916., 1552734.));
col = max(col, SmoothTri(164286., 169939.,170437., 1588066.));
col = max(col, SmoothTri(250260., 247658.,237895., 229413.));
col = max(col, SmoothTri(256414., 250260.,257965., 21120.));
col = max(col, SmoothTri(187822., 189391.,195003., 1370070.));
col = max(col, SmoothTri(183220., 187822.,178093., 1370963.));
col = max(col, SmoothTri(141253., 141270.,146392., 1881836.));
col = max(col, SmoothTri(136657., 141270.,138692., 1767154.));
col = max(col, SmoothTri(1021., 33144.,862., 1200836.));
col = max(col, SmoothTri(81833., 65499.,83435., 1005483.));
col = max(col, SmoothTri(31229., 65499.,53190., 677799.));
col = max(col, SmoothTri(222042., 199532.,212862., 1337531.));
col = max(col, SmoothTri(181549., 199532.,222042., 977048.));
col = max(col, SmoothTri(183666., 184701.,195446., 1353929.));
col = max(col, SmoothTri(180076., 179097.,181635., 1304903.));
col = max(col, SmoothTri(166700., 177942.,168739., 198161.));
col = max(col, SmoothTri(167204., 153900.,161064., 312969.));
col = max(col, SmoothTri(162799., 164301.,163809., 1751675.));
col = max(col, SmoothTri(163809., 164301.,158169., 1784426.));
col = max(col, SmoothTri(111472., 103836.,138560., 714407.));
col = max(col, SmoothTri(101744., 81833.,103836., 1267102.));
col = max(col, SmoothTri(153394., 161064.,153900., 215446.));
col = max(col, SmoothTri(154377., 150317.,153886., 166410.));
col = max(col, SmoothTri(179495., 181003.,177942., 197774.));
col = max(col, SmoothTri(179495., 177942.,166700., 280078.));
col = max(col, SmoothTri(193515., 189391.,184282., 1468384.));
col = max(col, SmoothTri(180706., 174571.,186354., 1752555.));
col = max(col, SmoothTri(198559., 191376.,187822., 1420118.));
col = max(col, SmoothTri(195979., 198559.,201614., 1469269.));
col = max(col, SmoothTri(212862., 208793.,232865., 1289425.));
col = max(col, SmoothTri(222042., 212862.,232865., 1288379.));
col = max(col, SmoothTri(28687., 10814.,31256., 4107.));
col = max(col, SmoothTri(177422., 167161.,162052., 49286.));
col = max(col, SmoothTri(247658., 250260.,254866., 4736.));
col = max(col, SmoothTri(137706., 133117.,142333., 1866102.));
col = max(col, SmoothTri(153394., 143161.,138560., 707350.));
col = max(col, SmoothTri(143161., 141115.,138560., 704790.));
col = max(col, SmoothTri(106830., 97106.,125770., 99968.));
col = max(col, SmoothTri(179097., 180076.,159630., 1549266.));
col = max(col, SmoothTri(159630., 169916.,178093., 1371998.));
col = max(col, SmoothTri(149501., 154594.,149989., 1931510.));
col = max(col, SmoothTri(151508., 143291.,146392., 1881842.));
col = max(col, SmoothTri(202146., 205259.,208793., 1470682.));
col = max(col, SmoothTri(208793., 212862.,201614., 1468633.));
col = max(col, SmoothTri(128979., 116663.,117215., 1980144.));
col = max(col, SmoothTri(112596., 105469.,117215., 1980148.));
col = max(col, SmoothTri(72039., 101744.,97106., 216857.));
col = max(col, SmoothTri(137706., 135645.,128979., 1850102.));
col = max(col, SmoothTri(135645., 137706.,142310., 1850229.));
col = max(col, SmoothTri(65434., 39755.,33144., 609318.));
col = max(col, SmoothTri(39755., 738.,33144., 614424.));
col = max(col, SmoothTri(149501., 159741.,154594., 1865974.));
col = max(col, SmoothTri(200653., 198559.,195003., 1370975.));
col = max(col, SmoothTri(195003., 198559.,187822., 1420115.));
col = max(col, SmoothTri(10814., 738.,40066., 8224.));
col = max(col, SmoothTri(193515., 180706.,186354., 1750496.));
col = max(col, SmoothTri(198623., 196085.,198653., 1585118.));
col = max(col, SmoothTri(53190., 65434.,33144., 611113.));
col = max(col, SmoothTri(65499., 81833.,53190., 677295.));
col = max(col, SmoothTri(174845., 181512.,167161., 16515.));
col = max(col, SmoothTri(181003., 179495.,181512., 18185.));
col = max(col, SmoothTri(169939., 164286.,162244., 1798518.));
col = max(col, SmoothTri(164301., 169440.,169939., 1949300.));
col = max(col, SmoothTri(158169., 154594.,159216., 1882348.));
col = max(col, SmoothTri(159216., 163809.,158169., 1783154.));
col = max(col, SmoothTri(166700., 167204.,161064., 312465.));
col = max(col, SmoothTri(161064., 153394.,166700., 281363.));
col = max(col, SmoothTri(138692., 139191.,136657., 1881323.));
col = max(col, SmoothTri(139191., 138692.,143291., 1799657.));
col = max(col, SmoothTri(181185., 169916.,189391., 1306450.));
col = max(col, SmoothTri(183220., 189391.,187822., 1419219.));
col = max(col, SmoothTri(141589., 154372.,155902., 785.));
col = max(col, SmoothTri(154372., 167161.,155902., 134.));
col = max(col, SmoothTri(738., 45251.,40066., 64.));
col = max(col, SmoothTri(172541., 174571.,172001., 2031100.));
col = max(col, SmoothTri(174571., 180706.,172001., 2029051.));
col = max(col, SmoothTri(112596., 117215.,116663., 1801332.));
col = max(col, SmoothTri(111032., 116663.,103836., 1275626.));
col = max(col, SmoothTri(164861., 169440.,162799., 2031229.));
col = max(col, SmoothTri(162799., 159216.,164861., 2062715.));
col = max(col, SmoothTri(215328., 224055.,236352., 3328.));
col = max(col, SmoothTri(181549., 224055.,215328., 3352.));
col = max(col, SmoothTri(163079., 167204.,168739., 197767.));
col = max(col, SmoothTri(166700., 168739.,167204., 149009.));
col = max(col, SmoothTri(59688., 39755.,72012., 3072.));
col = max(col, SmoothTri(212862., 199532.,204161., 1419473.));
col = max(col, SmoothTri(204161., 201614.,212862., 1338582.));
col = max(col, SmoothTri(184282., 180706.,193515., 1586649.));
col = max(col, SmoothTri(169916., 180706.,184282., 1471966.));
col = max(col, SmoothTri(250260., 256414.,254866., 37.));
col = max(col, SmoothTri(179097., 187822.,184218., 1403730.));
col = max(col, SmoothTri(179097., 184218.,181635., 1305298.));
col = max(col, SmoothTri(142310., 149989.,146392., 1882864.));
col = max(col, SmoothTri(149989., 151508.,146392., 1882485.));
col = max(col, SmoothTri(196085., 198623.,193515., 1584991.));
col = max(col, SmoothTri(189391., 193515.,198623., 1552463.));
col = max(col, SmoothTri(82429., 83435.,65499., 777915.));
col = max(col, SmoothTri(83435., 82429.,105469., 1793469.));
col = max(col, SmoothTri(202146., 208793.,201614., 1469658.));
col = max(col, SmoothTri(201614., 198559.,202146., 1485657.));
col = max(col, SmoothTri(153394., 153900.,150317., 329366.));
col = max(col, SmoothTri(153394., 150317.,142638., 379414.));
col = max(col, SmoothTri(180076., 187241.,166225., 1156167.));
col = max(col, SmoothTri(180076., 181635.,183666., 1206215.));
col = max(col, SmoothTri(97106., 81237.,72039., 411405.));
col = max(col, SmoothTri(72039., 81237.,72012., 1817.));
col = max(col, SmoothTri(153886., 153900.,167204., 149130.));
col = max(col, SmoothTri(153900., 153886.,150317., 328973.));
col = max(col, SmoothTri(142638., 143161.,153394., 363287.));
col = max(col, SmoothTri(143161., 142638.,141115., 35734.));
col = max(col, SmoothTri(186354., 194557.,196085., 1568490.));
col = max(col, SmoothTri(196085., 193515.,186354., 1749087.));
col = max(col, SmoothTri(151508., 154594.,160705., 1636594.));
col = max(col, SmoothTri(151508., 149989.,154594., 1866482.));
col = max(col, SmoothTri(513., 738.,10814., 532519.));
col = max(col, SmoothTri(27141., 513.,10814., 529291.));
col = max(col, SmoothTri(138560., 141115.,134466., 299.));
col = max(col, SmoothTri(164301., 169939.,162244., 1801076.));
col = max(col, SmoothTri(162244., 158169.,164301., 1914477.));
col = max(col, SmoothTri(164286., 143291.,160705., 1636066.));
col = max(col, SmoothTri(162244., 164286.,160705., 1634669.));
col = max(col, SmoothTri(142310., 141270.,136657., 1881840.));
col = max(col, SmoothTri(141270., 142310.,146392., 1882221.));
col = max(col, SmoothTri(138692., 141270.,141253., 1783531.));
col = max(col, SmoothTri(141253., 143291.,138692., 1767148.));
col = max(col, SmoothTri(105469., 112125.,117215., 1981549.));
col = max(col, SmoothTri(245757., 260093.,260083., 67.));
col = max(col, SmoothTri(177422., 168739.,177942., 198150.));
col = max(col, SmoothTri(177422., 177942.,181003., 148998.));
col = max(col, SmoothTri(236352., 224055.,237895., 232704.));
col = max(col, SmoothTri(236352., 237895.,247658., 1792.));
col = max(col, SmoothTri(191376., 195979.,184701., 1338070.));
col = max(col, SmoothTri(198559., 195979.,191376., 1419990.));
col = max(col, SmoothTri(97106., 101744.,111472., 642829.));
col = max(col, SmoothTri(111472., 101744.,103836., 1265447.));
col = max(col, SmoothTri(205259., 200653.,198623., 1552353.));
col = max(col, SmoothTri(205259., 202146.,200653., 1568097.));
col = max(col, SmoothTri(201614., 199532.,195446., 1353945.));
col = max(col, SmoothTri(187241., 195446.,199532., 1337672.));
col = max(col, SmoothTri(112596., 111032.,105469., 1799540.));
col = max(col, SmoothTri(111032., 112596.,116663., 1800810.));
col = max(col, SmoothTri(118091., 106830.,125770., 98304.));
col = max(col, SmoothTri(181003., 181512.,174845., 49289.));
col = max(col, SmoothTri(174845., 177422.,181003., 148227.));
col = max(col, SmoothTri(153886., 163079.,154377., 164746.));
col = max(col, SmoothTri(162052., 154377.,163079., 115971.));
col = max(col, SmoothTri(179495., 166700.,181549., 395406.));
col = max(col, SmoothTri(181549., 181027.,179495., 229784.));
col = max(col, SmoothTri(81833., 72039.,65434., 625835.));
col = max(col, SmoothTri(65434., 53190.,81833., 709798.));
col = max(col, SmoothTri(27141., 28687.,28165., 17803.));
col = max(col, SmoothTri(28687., 27141.,10814., 525707.));
col = max(col, SmoothTri(164286., 170437.,169916., 1552482.));
col = max(col, SmoothTri(180706., 169916.,170437., 1585003.));
col = max(col, SmoothTri(257965., 260083.,260050., 16385.));
col = max(col, SmoothTri(172001., 169939.,169440., 2046843.));
col = max(col, SmoothTri(169440., 172541.,172001., 2031228.));
col = max(col, SmoothTri(187822., 179097.,178093., 1370454.));
col = max(col, SmoothTri(159630., 178093.,179097., 1354206.));
col = max(col, SmoothTri(187241., 180076.,183666., 1205192.));
col = max(col, SmoothTri(187241., 183666.,195446., 1352904.));
col = max(col, SmoothTri(136657., 135645.,142310., 1850098.));
col = max(col, SmoothTri(136657., 128979.,135645., 1931378.));
col = max(col, SmoothTri(181027., 181549.,190238., 3075.));
col = max(col, SmoothTri(154377., 162052.,154372., 98698.));
col = max(col, SmoothTri(167161., 154372.,162052., 49921.));
col = max(col, SmoothTri(162799., 161767.,159216., 1882491.));
col = max(col, SmoothTri(161767., 163809.,159216., 1881458.));
col = max(col, SmoothTri(189391., 183220.,181185., 1354191.));
col = max(col, SmoothTri(178093., 181185.,183220., 1370451.));
col = max(col, SmoothTri(184218., 184701.,181635., 1304789.));
col = max(col, SmoothTri(183666., 181635.,184701., 1337289.));


    return col;
}

float sq(float x)
{
    return x*x;
}

float ell(float x, float y, vec2 scale, vec2 uv)
{
    uv -= vec2(x,y);
    uv *= scale;
    return sqrt(max(0.0, 1.0 - sq(uv.x) - sq(uv.y)));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    uv = fragCoord.xy / iResolution.xy;
    if(length(fragCoord.xy - vec2(0.0)) < 2.0)
    {
        fragColor = texelFetch(iChannel0, ivec2(0), 0);
        if(fragColor.xy != iResolution.xy)
            fragColor.z = 0.0;
        else
            fragColor.z ++;
        fragColor.xy = iResolution.xy;
        return;
    }
    int frameCounter = int(texelFetch(iChannel0, ivec2(0), 0).z);
    if(frameCounter == 1)
    {
        uv -= vec2(1.5)/512.0;
        fragColor = vec4(getHeadDepth());
        return;
    }
    if(frameCounter == 2) // Mirror step
    {
        float overlap = 1.0 - 2.0 * blendDistA;
        vec2 uv = fragCoord.xy / iResolution.xy;
        uv.x /= blendDistA + overlap;
        float leftSide = textureLod(iChannel0, uv, 0.0).x;

        uv.x -= blendDistA/(blendDistA + overlap);
        uv.x = 1.0 - uv.x;
        float rightSide = textureLod(iChannel0, uv, 0.0).x;
        float blendX = fragCoord.x / iResolution.x;
        fragColor = vec4(mix(leftSide, rightSide, saturate(blendX/overlap-blendDistA/overlap)));
        return;
    }    
    const float BLUR_RAD = 4.0;
    const float NORM_T = 20.0;
    float epsD = 1.0/512.0;
    float skipDepth = 0.03;
    fragColor = textureLod(iChannel0, uv, 0.0);
    if(frameCounter == 3 && fragColor.w > skipDepth) // X Blur
    {
        float cW = fragColor.w;
        float sum = 1.0;
        for(float ix = 1.0; ix<=BLUR_RAD; ix++)
        {
            vec4 r1 = textureLod(iChannel0, uv + vec2(epsD * ix, 0.0), 0.0);
            float w1 = exp(-NORM_T*abs(r1.w-cW));
            fragColor += r1 * w1;
            sum += w1;
            r1 = textureLod(iChannel0, uv - vec2(epsD * ix, 0.0), 0.0);
            w1 = exp(-NORM_T*abs(r1.w-cW));
            fragColor += r1 * w1;
            sum += w1;
        }
        fragColor /= sum;
        return;
    }
    if(frameCounter == 4) // Y Blur
    {
        if(fragColor.w > skipDepth)
        {
            float cW = fragColor.w;
            float sum = 1.0;
            for(float ix = 1.0; ix<=BLUR_RAD; ix++)
            {
                vec4 r1 = textureLod(iChannel0, uv + vec2(0.0, epsD * ix), 0.0);
                float w1 = exp(-NORM_T*abs(r1.w-cW));
                fragColor += r1 * w1;
                sum += w1;
                r1 = textureLod(iChannel0, uv - vec2(0.0, epsD * ix), 0.0);
                w1 = exp(-NORM_T*abs(r1.w-cW));
                fragColor += r1 * w1;
                sum += w1;
            }
            fragColor /= sum;
        }
        fragColor.x -= (textureLod(iChannel1, 30.0*uv, 0.0).x - 0.5)*0.003;
        return;
    }
    if(frameCounter == 5) // Normal map generation
    {
        float NORMAL_EPS = 1.0/512.0;
        vec4 centerRead = textureLod(iChannel0, uv, 0.0);
        vec3 centerWs = VOL_DIMS * vec3(uv, centerRead.x);
        vec3 X_Ws = VOL_DIMS * vec3(uv + vec2(NORMAL_EPS, 0.0), textureLod(iChannel0, uv + vec2(NORMAL_EPS, 0.0), 0.0).x);
        vec3 Y_Ws = VOL_DIMS * vec3(uv + vec2(0.0, NORMAL_EPS), textureLod(iChannel0, uv + vec2(0.0, NORMAL_EPS), 0.0).x);
        
        vec3 X_Ws_n = VOL_DIMS * vec3(uv - vec2(NORMAL_EPS, 0.0), textureLod(iChannel0, uv - vec2(NORMAL_EPS, 0.0), 0.0).x);
        vec3 Y_Ws_n = VOL_DIMS * vec3(uv - vec2(0.0, NORMAL_EPS), textureLod(iChannel0, uv - vec2(0.0, NORMAL_EPS), 0.0).x);
        vec3 X_min = abs(X_Ws.z - centerWs.z) < abs(X_Ws_n.z - centerWs.z) ? normalize(centerWs-X_Ws): -normalize(centerWs-X_Ws_n);        
        vec3 Y_min = abs(Y_Ws.z - centerWs.z) < abs(Y_Ws_n.z - centerWs.z) ? normalize(centerWs-Y_Ws): -normalize(centerWs-Y_Ws_n);
        
        float depthV = -0.02 + centerRead.x;
        float fixedD = 0.9*ell(0.5, 0.74, vec2(4.75, 3.4), uv);
        fixedD = max(fixedD, 0.5*ell(0.5, 0.5, vec2(6.5, 2.8), uv));
        fixedD = max(fixedD, 0.7*ell(0.5, 0.1, vec2(5.0, 2.8), uv));        
        fixedD = max(fixedD, 0.86*ell(0.5, 0.05, vec2(1.5, 4.8), uv));
        depthV = min(depthV, -fixedD);
        
        fragColor = vec4(PackNormals(normalize(cross(X_min, Y_min))), depthV, centerRead.x);
        return;
    }
}
