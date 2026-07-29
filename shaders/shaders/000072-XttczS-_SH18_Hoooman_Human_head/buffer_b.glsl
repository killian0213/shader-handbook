// Buffer B (buffer) — [SH18] Hoooman: Human head by ThomasSchander
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
    float gamma = 1.0 - alpha - beta;
    return vec3(alpha, beta, gamma);
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

vec3 BaryTri(float pA, float pB, float pC, float pCol1, vec3 col)
{
	vec3 bar = barycentric(unpackCoord(pA), unpackCoord(pB), unpackCoord(pC), uv);
    return mix(col, unpackParams(pCol1), 60.0*vec3(inRangeAll(bar))/256.0);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    int frameCounter = int(texelFetch(iChannel1, ivec2(0), 0).z);
    uv = fragCoord.xy / iResolution.xy;
    if(frameCounter == 1)
    {
        uv -= vec2(1.5)/512.0;
        uv.x *= 2.0;
        uv.x -= 1.0;
        vec3 col = vec3(195.0, 151.0, 141.0)/255.0;
        col = BaryTri(74407., 221432.,199167., 282949., col);
col = BaryTri(27509., 107204.,146292., 1324490., col);
col = BaryTri(49368., 185398.,166912., 415841., col);
col = BaryTri(56102., 205776.,95231., 842549., col);
col = BaryTri(26522., 68382.,184705., 1737570., col);
col = BaryTri(253951., 168446.,71210., 1536766., col);
col = BaryTri(191446., 121974.,115123., 1382., col);
col = BaryTri(83865., 234850.,193166., 1809604., col);
col = BaryTri(162808., 251358.,213588., 1502207., col);
col = BaryTri(229097., 150853.,224708., 1941621., col);
col = BaryTri(161805., 167885.,60821., 697429., col);
col = BaryTri(89599., 95434.,185208., 728102., col);
col = BaryTri(70883., 166905.,70102., 631245., col);
col = BaryTri(159717., 143030.,74075., 2097023., col);
col = BaryTri(43952., 123535.,233983., 1389181., col);
col = BaryTri(91115., 114735.,117212., 1685958., col);
col = BaryTri(154630., 146556.,238876., 614611., col);
col = BaryTri(40322., 71878.,167355., 688944., col);
col = BaryTri(123453., 36167.,161740., 55577., col);
col = BaryTri(164797., 218995.,231688., 2097151., col);
col = BaryTri(73846., 109455.,60202., 2080124., col);
col = BaryTri(219786., 51310.,183206., 1164052., col);
col = BaryTri(202185., 188402.,196300., 1456511., col);
col = BaryTri(216941., 138507.,108543., 1488111., col);
col = BaryTri(171713., 63631.,142847., 34., col);
col = BaryTri(58776., 88570.,101480., 1343451., col);
col = BaryTri(131421., 89544.,108500., 1043332., col);
col = BaryTri(111836., 92624.,165862., 912711., col);
col = BaryTri(137690., 221457.,53595., 919913., col);
col = BaryTri(199616., 201048.,139076., 753., col);
col = BaryTri(148979., 146725.,60515., 255., col);
col = BaryTri(126521., 100768.,36431., 1667610., col);
col = BaryTri(183466., 239237.,174339., 1255226., col);
col = BaryTri(100728., 147967.,147251., 74., col);
col = BaryTri(34792., 214359.,67192., 1008096., col);
col = BaryTri(200570., 213285.,198232., 2037248., col);
col = BaryTri(103923., 167485.,92227., 387., col);
col = BaryTri(45768., 35941.,194451., 1875670., col);
col = BaryTri(130467., 186768.,218804., 197813., col);
col = BaryTri(208118., 180559.,184437., 311322., col);
col = BaryTri(171590., 118592.,228465., 1384951., col);
col = BaryTri(97556., 167190.,144383., 46., col);
col = BaryTri(124308., 179774.,74818., 17468., col);
col = BaryTri(143460., 76175.,49468., 1946360., col);
col = BaryTri(116961., 203191.,199805., 6141., col);
col = BaryTri(117704., 72011.,194121., 2002605., col);
col = BaryTri(100757., 7553.,15126., 1433566., col);
col = BaryTri(227075., 232439.,55080., 1629947., col);
col = BaryTri(105560., 196929.,219220., 457307., col);
col = BaryTri(148479., 46038.,202613., 675545., col);
col = BaryTri(144257., 122163.,237695., 1908060., col);
col = BaryTri(181774., 195085.,114642., 1470178., col);
col = BaryTri(231595., 256730.,195980., 1386718., col);
col = BaryTri(96316., 32416.,60235., 608036., col);
col = BaryTri(105434., 123903.,174676., 1537258., col);
col = BaryTri(201060., 198143.,164963., 20545., col);
col = BaryTri(170644., 29388.,140684., 2697., col);
col = BaryTri(50984., 238286.,239013., 1488502., col);
col = BaryTri(157438., 158142.,97972., 6., col);
col = BaryTri(180088., 164910.,75942., 104279., col);
col = BaryTri(31966., 80544.,188867., 153019., col);
col = BaryTri(34112., 148991.,89599., 924610., col);
col = BaryTri(148064., 42725.,165769., 1580872., col);
col = BaryTri(175336., 229601.,238995., 1241323., col);
col = BaryTri(117173., 46250.,200788., 2082562., col);
col = BaryTri(67489., 39188.,74487., 16478., col);
col = BaryTri(115436., 150979.,194231., 1818513., col);
col = BaryTri(251592., 233553.,145297., 1321556., col);
col = BaryTri(158394., 159690.,88749., 16540., col);
col = BaryTri(55592., 232439.,227058., 1079545., col);
col = BaryTri(45192., 240096.,237181., 1031793., col);
col = BaryTri(127994., 112684.,135077., 183074., col);
col = BaryTri(104932., 82497.,203326., 394248., col);
col = BaryTri(196176., 218966.,208815., 2095359., col);
col = BaryTri(117247., 141797.,116780., 1453432., col);
col = BaryTri(219220., 205037.,39002., 1593690., col);
col = BaryTri(162901., 0.,165191., 1025248., col);
col = BaryTri(198559., 199259.,202578., 0., col);
col = BaryTri(198783., 202557.,197592., 0., col);
col = BaryTri(210319., 201795.,249331., 1374332., col);
col = BaryTri(49844., 85955.,113485., 2015221., col);
col = BaryTri(118184., 138725.,139488., 2097151., col);
col = BaryTri(71049., 135268.,125465., 2093281., col);
col = BaryTri(197000., 143210.,202751., 909275., col);
col = BaryTri(114296., 176523.,148429., 1966079., col);
col = BaryTri(113047., 122463.,50451., 2031615., col);
col = BaryTri(146990., 33341.,70016., 1913295., col);
col = BaryTri(46925., 95851.,67675., 166295., col);
col = BaryTri(238819., 73308.,227446., 1503467., col);
col = BaryTri(192911., 147102.,54981., 555434., col);
col = BaryTri(132713., 58105.,38260., 812022., col);
col = BaryTri(34560., 61829.,55392., 1699155., col);
col = BaryTri(144595., 41394.,62937., 891606., col);
col = BaryTri(117993., 177774.,41559., 8649., col);
col = BaryTri(202335., 198677.,141894., 1089238., col);
col = BaryTri(188635., 182148.,111801., 360448., col);
col = BaryTri(202531., 143580.,198608., 24., col);
col = BaryTri(173055., 141650.,175803., 1604350., col);
col = BaryTri(33670., 262143.,261989., 1437282., col);
col = BaryTri(13183., 112423.,83967., 1504365., col);
col = BaryTri(127715., 147520.,210672., 483936., col);
col = BaryTri(44965., 197133.,121873., 925536., col);
col = BaryTri(176390., 210224.,189321., 514117., col);
col = BaryTri(101302., 58651.,120406., 2095103., col);
col = BaryTri(195868., 30914.,57095., 188081., col);
col = BaryTri(156599., 168086.,126687., 3., col);
col = BaryTri(100859., 180819.,103808., 397750., col);
col = BaryTri(107526., 377.,0., 1108070., col);
col = BaryTri(100235., 139868.,200082., 114696., col);
col = BaryTri(141160., 101375.,109737., 529951., col);
col = BaryTri(29055., 101316.,28140., 1239526., col);
col = BaryTri(105388., 170331.,124049., 2096867., col);
col = BaryTri(103891., 117971.,102515., 0., col);
col = BaryTri(261983., 208762.,193681., 1519720., col);
col = BaryTri(5460., 52406.,2238., 1288680., col);
col = BaryTri(152636., 142818.,125643., 0., col);
col = BaryTri(62634., 191677.,161362., 2087295., col);
col = BaryTri(202404., 170910.,104748., 1719., col);
col = BaryTri(143451., 198529.,198940., 2097151., col);
col = BaryTri(26012., 116468.,98747., 1745375., col);
col = BaryTri(202475., 191108.,150440., 12., col);
col = BaryTri(105797., 170148.,200114., 34825., col);
col = BaryTri(64536., 226904.,151688., 1137744., col);
col = BaryTri(162383., 196212.,154033., 37., col);
col = BaryTri(61153., 34562.,45435., 479009., col);
col = BaryTri(148417., 183900.,118887., 2097151., col);
col = BaryTri(118953., 91382.,40243., 508330., col);
col = BaryTri(219558., 221059.,138635., 976618., col);
col = BaryTri(97076., 1418.,33417., 2040918., col);
col = BaryTri(85309., 58086.,153864., 46200., col);
col = BaryTri(169609., 86321.,193928., 3., col);
col = BaryTri(107313., 150339.,122037., 2064319., col);
col = BaryTri(57964., 112262.,79611., 671795., col);
col = BaryTri(62516., 114387.,34043., 1724505., col);
col = BaryTri(202486., 118391.,125305., 425983., col);
col = BaryTri(40020., 172885.,1926., 452977., col);
col = BaryTri(161679., 60573.,199735., 1452401., col);
col = BaryTri(92344., 123266.,145118., 1326855., col);
col = BaryTri(45802., 158405.,86117., 1297776., col);
col = BaryTri(182694., 64071.,128562., 1980644., col);
col = BaryTri(198529., 198265.,204672., 924., col);
col = BaryTri(66867., 110969.,34603., 856746., col);
col = BaryTri(195976., 195493.,111953., 1605631., col);
col = BaryTri(56501., 23413.,123683., 783469., col);
col = BaryTri(172655., 258290.,262029., 1404256., col);
col = BaryTri(84722., 57477.,101645., 4316., col);
col = BaryTri(203056., 197220.,75436., 2068., col);
col = BaryTri(47199., 135995.,9408., 1104996., col);
col = BaryTri(47062., 101797.,75775., 1273063., col);
col = BaryTri(99695., 132307.,49549., 1874275., col);
col = BaryTri(138700., 116363.,26012., 768366., col);
col = BaryTri(163503., 191914.,73939., 680227., col);
col = BaryTri(134736., 140287.,205965., 16464., col);
col = BaryTri(200294., 201683.,149923., 313739., col);
col = BaryTri(128432., 136617.,147733., 1997055., col);
col = BaryTri(143428., 72729.,199401., 1015766., col);
col = BaryTri(24643., 180164.,124433., 629858., col);
col = BaryTri(151336., 169021.,71767., 8522., col);
col = BaryTri(107965., 110079.,102911., 17163., col);
col = BaryTri(155369., 115823.,114094., 1184646., col);
col = BaryTri(74097., 141931.,194912., 806784., col);
col = BaryTri(145325., 135931.,183632., 2047359., col);
col = BaryTri(75665., 126480.,58418., 1551844., col);
col = BaryTri(189629., 23954.,23611., 1288675., col);
col = BaryTri(122777., 198494.,197861., 1160432., col);
col = BaryTri(37182., 42232.,91843., 910923., col);
col = BaryTri(179594., 203151.,202002., 1., col);
col = BaryTri(202966., 201631.,69185., 39., col);
col = BaryTri(63344., 178787.,106441., 362244., col);
col = BaryTri(203844., 200133.,164491., 13., col);
col = BaryTri(118361., 78205.,79088., 72899., col);
col = BaryTri(101044., 159642.,188593., 1720319., col);
col = BaryTri(148298., 185941.,173460., 1949695., col);
col = BaryTri(191681., 153708.,78941., 2027996., col);
col = BaryTri(227960., 56847.,238827., 994924., col);
col = BaryTri(76171., 101310.,85328., 1833595., col);
col = BaryTri(203831., 107291.,154874., 885291., col);
col = BaryTri(156042., 116388.,81611., 1372416., col);
col = BaryTri(204524., 197300.,198614., 0., col);
col = BaryTri(65701., 107861.,30907., 940493., col);
col = BaryTri(78580., 129900.,122266., 215683., col);
col = BaryTri(6515., 169916.,80890., 1024861., col);
col = BaryTri(195557., 222601.,209126., 1931519., col);
col = BaryTri(28498., 51634.,52924., 927065., col);
col = BaryTri(25453., 249824.,73217., 1449447., col);
col = BaryTri(202293., 62629.,196025., 2014841., col);
col = BaryTri(43927., 76691.,209472., 1236956., col);
col = BaryTri(65568., 203226.,27940., 846173., col);
col = BaryTri(198036., 198891.,135490., 1666175., col);
col = BaryTri(195198., 189764.,199492., 1966079., col);
col = BaryTri(53075., 253903.,213430., 1817211., col);
col = BaryTri(179344., 167325.,24644., 1418860., col);
col = BaryTri(153657., 68854.,145930., 1403489., col);
col = BaryTri(176504., 431.,34467., 1107682., col);
col = BaryTri(120716., 91416.,401., 1139424., col);
col = BaryTri(73216., 109735.,36632., 910808., col);
col = BaryTri(210107., 130855.,143972., 691382., col);
col = BaryTri(130675., 151458.,73245., 1405159., col);
col = BaryTri(238718., 150381.,206445., 665687., col);
col = BaryTri(156933., 106687.,160867., 377216., col);
col = BaryTri(118567., 233050.,210978., 1239117., col);
col = BaryTri(183., 137737.,153420., 1240294., col);
col = BaryTri(185970., 104817.,155184., 99113., col);
col = BaryTri(194656., 144695.,199507., 1835007., col);
col = BaryTri(117348., 144677.,134595., 1470576., col);
col = BaryTri(174215., 106367.,86260., 674577., col);
col = BaryTri(74341., 175705.,204280., 843883., col);
col = BaryTri(250282., 167482.,197651., 1191405., col);
col = BaryTri(161979., 175433.,199461., 1801688., col);
col = BaryTri(144355., 116838.,145832., 24., col);
col = BaryTri(156737., 197764.,116958., 3879., col);
col = BaryTri(184995., 150483.,112251., 2097151., col);
col = BaryTri(142905., 191041.,92853., 1060346., col);
col = BaryTri(200943., 181404.,193124., 0., col);
col = BaryTri(179851., 136988.,178583., 1914751., col);
col = BaryTri(201931., 204933.,173169., 1550185., col);
col = BaryTri(176909., 182374.,188828., 50858., col);
col = BaryTri(133963., 153460.,142125., 873501., col);
col = BaryTri(228331., 51010.,75253., 1271009., col);
col = BaryTri(180044., 188850.,80104., 1587195., col);
col = BaryTri(133253., 87342.,198845., 412712., col);
col = BaryTri(157052., 201653.,154439., 1288953., col);
col = BaryTri(157305., 170388.,182476., 1702139., col);
col = BaryTri(154726., 104895.,104654., 624398., col);
col = BaryTri(39640., 96774.,26625., 1173087., col);
col = BaryTri(70144., 238128.,238757., 1156315., col);
col = BaryTri(204493., 242364.,242531., 1142254., col);
col = BaryTri(66804., 51598.,153419., 1404646., col);
col = BaryTri(27219., 201852.,151082., 844515., col);
col = BaryTri(4677., 144384.,154741., 1173092., col);
col = BaryTri(200583., 205065.,195239., 0., col);
col = BaryTri(62009., 107701.,165465., 1236338., col);
col = BaryTri(200657., 190036.,159313., 1225973., col);
col = BaryTri(106953., 124900.,136880., 1584994., col);
col = BaryTri(110890., 46259.,81557., 1189737., col);
col = BaryTri(75264., 32791.,130327., 1221857., col);
col = BaryTri(128162., 133898.,80665., 762929., col);
col = BaryTri(203238., 237029.,100166., 1188842., col);
col = BaryTri(87489., 80535.,107137., 1338750., col);
col = BaryTri(120258., 205921.,118474., 1749375., col);
col = BaryTri(81613., 88020.,133435., 924460., col);
col = BaryTri(214614., 119392.,202380., 1354595., col);
col = BaryTri(190554., 198611.,14102., 1369322., col);
col = BaryTri(239556., 84512.,237694., 1349475., col);
col = BaryTri(127117., 57641.,122748., 1007439., col);
col = BaryTri(185754., 30761.,125194., 1337956., col);
col = BaryTri(144054., 155065.,76372., 1485133., col);
col = BaryTri(168544., 49982.,89107., 1107932., col);
col = BaryTri(183955., 172957.,18127., 1271399., col);
col = BaryTri(205874., 62629.,112911., 891978., col);
col = BaryTri(233579., 44084.,177867., 1125082., col);
col = BaryTri(30875., 155839.,81947., 1074013., col);
col = BaryTri(236091., 133469.,36932., 1239272., col);
col = BaryTri(161788., 24985.,191878., 1121887., col);
col = BaryTri(202567., 187018.,199882., 0., col);
col = BaryTri(196164., 228823.,52103., 977384., col);


        fragColor.xyz = col;
		return;
    }
    if(frameCounter == 2)
    {        
        float overlap = 1.0 - 2.0 * blendDistA;
        vec2 uv = fragCoord.xy / iResolution.xy;
        uv.x /= blendDistA + overlap;
        vec4 leftSide = textureLod(iChannel0, uv, 0.0);

        uv.x -= blendDistA/(blendDistA + overlap);
        uv.x = 1.0 - uv.x;
        vec4 rightSide = textureLod(iChannel0, uv, 0.0);
        float blendX = fragCoord.x / iResolution.x;
        fragColor = mix(leftSide, rightSide, saturate(blendX/overlap-blendDistA/overlap));
        return;
    }
    if(frameCounter == 3)
    {
        seed = fragCoord.x + fragCoord.y * 1.125125 + iTime;
        uv += 2.0*floatRand2()/512.0;
    }
    fragColor = textureLod(iChannel0, uv, 0.0);
}