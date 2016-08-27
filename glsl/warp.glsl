// ------------------ channel define
// 0_# noise #_0
// 1_# tex03 #_1
// 2_# tex09 #_2
// ------------------


// https://www.shadertoy.com/view/XtdGR7

const float PI = 3.1415926535;
const float SPEED = 10.0;
const float ARMS = 3.0;
const vec2 EPSILON = vec2(0, .005);

const vec3 sunDir = vec3(-0.363696,0.581914,0.727393);//normalize(vec3(-.5,.8,1));
const vec3 sunColor = vec3(3,2,1);

float time;
float z_offset;
float tunnelShake;

vec2 rotate(vec2 p, float a)
{
    return vec2(cos(a)*p.x + sin(a)*p.y, -sin(a)*p.x + cos(a)*p.y);
}

float Noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;
    return -1.0+2.0*mix( rg.x, rg.y, f.z );
}

float Map3( in vec3 p )
{
    vec3 q = p;
    float f;
    f  = 0.50000*Noise( q ); q = q*2.02;
    f += 0.25000*Noise( q ); q = q*2.03;
    f += 0.12500*Noise( q ); q = q*2.01;
    return f;
}

float Map5( in vec3 p )
{
    vec3 q = p;
    float f;
    f  = 0.50000*Noise( q ); q = q*2.02;
    f += 0.25000*Noise( q ); q = q*2.03;
    f += 0.12500*Noise( q ); q = q*2.01;
    f += 0.06250*Noise( q ); q = q*2.02;
    f += 0.03125*Noise( q );
    return f;
}

mat4 LookAt(vec3 pos, vec3 target, vec3 up)
{
    vec3 dir = normalize(target - pos);
    vec3 x = normalize(cross(dir, up));
    vec3 y = cross(x, dir);
    return mat4(vec4(x, 0), vec4(y, 0), vec4(dir, 0), vec4(pos, 1));
}

vec2 TunnelCenter(float z)
{
    return vec2(sin(z*.17)*.4,sin(z*.1+4.))*3. * tunnelShake;
}

float GetAngle(vec3 pos)
{
    return atan(pos.y,pos.x) - pos.z*.25 + time*3.7 + sin(time)*.2;
}


vec3 Fresnel(vec3 R0, vec3 normal, vec3 viewDir)
{
    float NdotV = max(0., dot(normal, viewDir));
    return R0 + (vec3(1.0) - R0) * pow(1.0 - NdotV, 5.0);
}

float Map(vec3 pos)
{
    pos.z -= z_offset;
    pos.xy -= TunnelCenter(pos.z);
    float fft = texture2D( iChannel3, vec2(0.5,0.15) ).x;
    float angle = GetAngle(pos);
    float r = sin(pos.z*.1)*0.5 + 3. + Map5(pos)*.3 + fft * 2.0 + sin(angle*ARMS)*.3;
    //r += texture2D( iChannel3, vec2(fract(pos.z*.1),0.0) ).x;
    return length(pos.xy) - r;
}

vec3 Normal(vec3 pos)
{
    vec2 e = vec2(0, .05);
    return normalize(vec3(Map(pos + e.yxx), Map(pos + e.xyx), Map(pos + e.xxy)) - Map(pos));
}

float IntersectPlanets(vec3 pos, vec3 dir, out vec3 normal, out float max_d, out int type)
{
    const float PLANET_CYCLE = 25.0;
    const int PLANET_PASSES = 3;
    float best_dist = 1e10;
    bool hit = false;
    max_d = -1e10;
    for(int i = 0; i < PLANET_PASSES; i++)
    {
        int tp = i;
        if(tp >= 3) tp-=3;
        float time2 = time + 15.5*float(i);
        float planetRound = floor(time2 / PLANET_CYCLE);
        float planetPos = time2 - planetRound * PLANET_CYCLE;
        float planetAngle = planetRound * 23.1;
        float planetDistance =  (tp==0) ? 20. :
                                (tp==1) ? 13. :
                                13.;
        vec3 sphereCenter = vec3(cos(planetAngle)*planetDistance,sin(planetAngle)*planetDistance,(PLANET_CYCLE- planetPos)*10.);
        vec3 delta = pos - sphereCenter;
        float sphereRadius =    (tp==0) ? 13. :
                                (tp==1) ? 7. :
                                7.;
    
        float B = dot(dir, delta);
        float C = dot(delta, delta) - sphereRadius * sphereRadius;
        float D = B*B - C;
        
        if(D >= 0.0)
        {
            float t = -B - sqrt(D);
            if(t >= 0. && t < best_dist)
            {
                vec3 spherePos = pos + t * dir;
                normal = normalize(spherePos - sphereCenter);
                best_dist = t;
                type = tp;
                hit = true;
            }
        }
        max_d = max(max_d, D);
    }
    return hit ? best_dist : -1.;
}

float EarthHeight(vec3 pos)
{
    vec2 coord = vec2(acos(pos.y)/(2.0*PI), atan(pos.x, pos.z)/(2.0*PI));
    vec3 te = texture2D( iChannel2, coord ).rgb + texture2D( iChannel2, coord*3.0 ).rgb * .3;
    float landLerp = smoothstep( 0.45, 0.5, te.x);
    vec3 albedo = mix( vec3(0.1, 0.2, 0.45), (vec3(0.055, 0.275, 0.0275) + 0.45*te + te*te*0.5*texture2D( iChannel2, 2.0*coord.xy ).xyz)*0.4, landLerp );
    return length(pos) - albedo.x*.015;
}

vec3 BackgroundInner(vec3 pos, vec3 dir, bool enableSun, out bool sphereHit, out vec3 spherePos, out vec3 sphereNormal, out vec3 reflectivity)
{
    vec3 nebulaPos = dir.yxz;
    float v = Map5(nebulaPos*1.3 + Map5(nebulaPos*0.5)*3.0) + .1;
    v = max(v, 0.);
    
    vec3 color = v*mix(vec3(1.,.2,2), vec3(2,.2,10), clamp(Map3(dir*1.3),0.,1.)) + 0.1;
    
    vec2 uv = vec2(acos(dir.x), atan(dir.y,dir.z));
    
    vec3 a = texture2D( iChannel1, uv*1.5).rgb;
    
    vec3 b = texture2D( iChannel1, uv*0.4).rgb;
    
    color *= (a * b) * 4.;
    color += pow(texture2D(iChannel1, uv*1.0).rgb, vec3(4.0)) * 0.5;
    if(enableSun)
    {
        float sunDot = max(0., dot(dir, sunDir));
        color += (pow(sunDot, 8.0)*.03 + pow(sunDot, 512.0)) * 5. * sunColor;
    }

    sphereHit = false;
    reflectivity = vec3(0);
    float max_d;
    int type;
    float t = IntersectPlanets(pos, dir, sphereNormal, max_d, type);
    if(t >= 0.0)
    {
        spherePos = pos + t * dir;
        vec2 coord = vec2(acos(sphereNormal.y)/(2.0*PI), atan(sphereNormal.x, sphereNormal.z)/(2.0*PI));
        float time_offset = time*.04;
        coord.y += time_offset;

        if(type == 0)
        {
            float offset = texture2D( iChannel2, coord ).r * .005;
            vec3 lookup = sphereNormal;
            lookup.xy = rotate(lookup.xy, time_offset*2.0*PI);
            float height = Map5(lookup*4.)*.5+.8;//texture2D( iChannel2, coord + vec2(offset)).r;
            height = pow(min(height, 1.),8.);
            vec3 fire = (texture2D( iChannel2, coord*5. + time*.02).rgb +
                         texture2D( iChannel2, coord*1. + time*.006).rgb

                        ) * vec3(3,1,1) * .5;

            vec3 albedo = texture2D( iChannel2, coord + vec2(offset)).rgb * .25 -
                          texture2D( iChannel2, coord*7.0).rgb * .1;
            color = albedo * max(0., dot(sphereNormal, sunDir)) * sunColor + fire * pow(1.0-height,16.);
        }
        else if(type == 2)
        {
            vec3 te = texture2D( iChannel2, coord ).rgb + texture2D( iChannel2, coord*3.0 ).rgb * .3;
        
            float offset = 0.0 + texture2D( iChannel2, coord).x*.003;
            vec3 albedo = (texture2D( iChannel2, coord*vec2(.4,0)+vec2(offset,0) ).rgb-.5)*.7 + .4;
            albedo += texture2D( iChannel2, coord*1.0).rgb * .2;
            albedo += texture2D( iChannel2, coord*16.0).rgb * .075;
            color = albedo * max(0., dot(sphereNormal, sunDir)) * sunColor;
        }
        else if(type == 1)
        {
            vec3 te = texture2D( iChannel2, coord ).rgb + texture2D( iChannel2, coord*3.0 ).rgb * .3;

            vec3 bumpedNormal = normalize(vec3(EarthHeight(sphereNormal + EPSILON.yxx), EarthHeight(sphereNormal + EPSILON.xyx), EarthHeight(sphereNormal + EPSILON.xxy)) - EarthHeight(sphereNormal));
            sphereNormal = bumpedNormal;
            float landLerp = smoothstep( 0.45, 0.5, te.x);
            vec3 albedo = mix( vec3(0.1, 0.2, 0.45), (vec3(0.055, 0.275, 0.0275) + 0.45*te + te*te*0.5*texture2D( iChannel2, 2.0*coord.xy ).xyz)*0.4, landLerp );
            float specPower = mix(2048., 32., landLerp);
            float q = (  texture2D( iChannel2, coord+vec2(0,time*.02) ).x +
                            texture2D( iChannel2, coord*2.0+vec2(0,time*.013) ).x) * .5;

            float skyLerp = smoothstep( 0.4, 0.8, q);
            reflectivity = mix(vec3(0.1), vec3(0.0), skyLerp);

            float NdotL = max(0., dot(sphereNormal, sunDir));
            vec3 opaque = albedo * NdotL * sunColor;
            color = opaque + pow(max(0., dot(bumpedNormal, normalize(-dir + sunDir))), specPower) * (specPower + 8.0) / (8.0 * PI) * sunColor * reflectivity;

            vec3 sky = vec3(0.9) * NdotL * sunColor;
            color = mix( color, sky, skyLerp);        
        }

        sphereHit = true;
    }
    
    return color;
}
    
vec3 Background(vec3 pos, vec3 dir)
{
    dir = normalize(dir);
    
    bool sphereHit;
    vec3 spherePos;
    vec3 sphereNormal;
    vec3 reflectivity;
    vec3 color = BackgroundInner(pos, dir, true, sphereHit, spherePos, sphereNormal, reflectivity);
    if(sphereHit)
    {
        vec3 R = Fresnel(reflectivity, sphereNormal, -dir);

        vec3 reflectionDir = reflect(dir,sphereNormal);
        bool dummyHit;
        vec3 dummyPos;
        vec3 dummyNormal;
        color += (BackgroundInner(spherePos + sphereNormal*.01, reflectionDir, false, dummyHit, dummyPos, dummyNormal, reflectivity)*(1.0-R)+vec3(1,2,3)*.075)*R*sunColor;
    }
    
    return color;
}


vec3 LensFlare(vec2 x)
{
    x = abs(x);
    float e = 1.5;
    float d = pow(pow(x.x*.5, e) + pow(x.y*3., e), 1./e);
    
    vec3 c = vec3(exp(-2.5*d))*sunColor*(.3+sin(x.y*iResolution.y*2.)*.01) * .5;
    c += vec3(exp(-dot(d,d)))*sunColor*.05;
    
    return c;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    
    time = iGlobalTime;
    vec3 camPos = vec3(0);
    z_offset = time*SPEED;
 
    float introFade = min(time*.05, 1.0);
    
    float camZoom = 3.0 - introFade*2.0;
    
    tunnelShake = introFade;
    camPos.xy += TunnelCenter(camPos.z-z_offset)*.5;
    vec3 camTarget = vec3(0,0,5);
    camTarget.xy += TunnelCenter(camTarget.z-z_offset)*.5;
    //camTarget = vec3(3,0,5);
    camTarget = mix(vec3(3,0,5), camTarget, introFade);
    
    float camAngle = sin(time*.3) + time*.1;
    vec3 camUp = vec3(sin(camAngle),cos(camAngle),0);

    mat4 viewToWorld = LookAt(camPos, camTarget, camUp);
    vec2 uv2 = (fragCoord - .5*iResolution.xy) / (iResolution.y * camZoom);
    vec3 eyeDir = (viewToWorld * normalize(vec4(uv2, 1, 0))).xyz;
    
    float t = 0.0;
    vec3 p = camPos;
    float iterationCount = 0.0;
    for(int i = 0; i < 70; i++)
    {
        float dist = Map(p);
        
        t += dist;
        p += dist*eyeDir;
        iterationCount++;
        if(abs(dist) < .001) break;
    }
    
    
    vec3 normal = Normal(p);
    vec3 refraction = refract(normalize(eyeDir), normal, 1.012);
    vec3 reflection = reflect(-normalize(eyeDir), normal);
    vec3 halfDir = normalize(sunDir - eyeDir);
    vec2 circlePos = p.xy - TunnelCenter(p.z - z_offset);
    float angle = atan(circlePos.y,circlePos.x);
    
    float z = p.z - z_offset;
    
    vec3 R = Fresnel(vec3(0.0), normal, -eyeDir);
    //vec3 c = mix(vec3(2,1,1),vec3(1,1,2),sin(p.z*.1)*.5+.5);
    vec3 c = vec3(1);
    vec3 outColor = Background(p, refraction)*(vec3(1.0) - R)*c + Background(p, -reflection)*R;
    
    float fft = texture2D( iChannel3, vec2(0.2,0.25) ).x;
    fft = max(.0, fft - .5);
    
    float tunnelDist = length(p - camPos);
    outColor = outColor * exp(-tunnelDist*.05) + (1.0-exp(-tunnelDist*.05))*vec3(2,1,3)*(.1+fft*.6);
    
    outColor += sqrt(iterationCount)*.005;
    
    vec3 sunPos = (vec4(sunDir, 0) * viewToWorld).xyz;
    vec2 sunUV = sunPos.xy / sunPos.z;

    float vignette = uv.x * (1.0-uv.x) * uv.y * (1.0-uv.y) * 32. * 0.75 + 0.25;
    outColor *= vignette;
    
    vec3 sphereNormal;
    float max_d;
    int type;
    float planet_t = IntersectPlanets(camPos, sunDir, sphereNormal, max_d, type);
    float lensIntensity = clamp(1.0 - max_d*.02, 0.0, 1.0);
    
    outColor += LensFlare(uv2 - sunUV) * lensIntensity;
    outColor += LensFlare(uv2 + sunUV) * .4 * lensIntensity;

    outColor = clamp(outColor, 0.0, 1.0);
    outColor *= vec3(sqrt(min(time*.2, 1.0)));
    fragColor = vec4( outColor, 1.0 );
}

//---------------------------

// THREE JS TRANSPHERE

void main(){

    vec4 color = vec4(0.0);

    // screen space
    //vec2 coord = gl_FragCoord.xy;
    // object space
    vec2 coord = vUv * iResolution.xy;

    mainImage( color, coord );

    // tone mapping
    #if defined( TONE_MAPPING ) 
    color.rgb = toneMapping( color.rgb ); 
    #endif

    gl_FragColor = color;

}

//---------------------------