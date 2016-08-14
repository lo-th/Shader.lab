////////////////////////////////////////////////////////////////
// 
// "2nd stage BOSS" by 0x4015 & YET11 - Shadertoy port
//   http://www.pouet.net/prod.php?which=66962
//   Big thanks to i-saint for initial GLSL Sandbox port!
//     http://glslsandbox.com/e#31067
// 
////////////////////////////////////////////////////////////////

// https://www.shadertoy.com/view/MsGGDK

float u,y,z;
vec3 v,w,x;

float B(vec3 a)
{
    return max(max(a.x,a.y),a.z);
}

float C(float a)
{
    return a/(abs(a)+1.0);
}

float D(float a)
{
    float b = max(0.0, a);
    return exp(1.0 - b) * b;
}

float E(float a,float b,float c)
{
    float d = clamp((b-a)/c*.5+.5, 0.0, 1.0);
    return mix(b,a,d) - c * d * (1.0-d);
}

float F(vec3 a, vec3 b, vec3 c, vec3 d, int i)
{
    vec3 e = a-b;
    float f = dot(c,c);
    float g = dot(d,d);
    float h = dot(d,e);
    float j = dot(c,e);
    float k = dot(c,d);
    float l = clamp((k*h-j*g)/(f*g-k*k), 0.0, 1.0);
    float m = k*l+h;
    float n = 0.0;
    if( m < 0.0) {
        l = clamp(-j/f, 0.0, 1.0);
    }
    else if(m > g) {
        n = 1.0;
        l = clamp((k-j)/f, 0.0, 1.0);
    }
    else {
        n = m/g;
    }
    e += c*l-d*n;
    return(sin(l*50.0 - u*500.0) + 1.1)/(fract(u*9.0 + float(i)*.11)*dot(e,e)+.0001);
}

float G(vec3 a,int b,float c,float d,float e)
{
    float f = 0.0;
    for(int i=0; i<8; ++i){
        if(i>=b) break;
        vec3 g = (a+e)*c;
        g += sin(g.zxy*1.13)*1.63;
        f += (length(cos(g)+sin(g.yzx))-1.5)*d;
        a = a.yzx;
        c *= 1.93;
        d *= .419;
    }
    return f;
}

float H(vec3 a)
{
    return (abs(a.z)*.5 + a.y - 2333.0) * .89;
}

float I(vec3 a)
{
    return length(sin(a*.01)) * 125.0 - 137.0;
}

float J(vec3 a)
{
    return max(B(abs(a)),B(vec3(length(a.xy),length(a.yz),length(a.zx)))-.2)-1.0;
}

float K(vec3 a)
{
    a = abs(a);
    return max(a.x*.87+a.y*.5, a.y) - 1.0;
}

float L(vec3 a)
{
    a.z -= 5.0;
    return max(max(abs(length(a)-5.0) - .05, K(a)), a.z);
}

vec2 M(vec3 a, int b)
{
    vec3 c = (a-x)*.5;
    vec3 d = a-v;
    vec3 e = d*.1;
    float f = .5;
    float g = length(c)-5.0;
    if(int(g) < 1){
        float b=(floor(atan(c.x,c.y)/3.14159265*1.5)+.5)/3.0*3.14159265*2.0;
        float d=sin(b);
        float e=cos(b);
        vec3 f=vec3(c.x*d+c.y*e,abs(c.x*e-c.y*d),c.z),h=vec3(abs(c.x),c.zy);
        g = min(min(max(L(h*vec3(.6, .3, -.3) + vec3(.3, -.1, 0.0))/.6,.2-abs(h.x)),L(h*vec3(1.0, .5, -.5)+vec3(.3, 0.0, .3))),min(min(max(K(f*1.25-vec3(.2,1.1,-2.5))/1.25,abs(h.y+2.0)-1.75),L(vec3(0.0, -.5, 1.5)-f.yzx*.5)*2.0),max(J(f*.7+vec3(-1.75, .35, 1.4))/.7, -J(f*.8+vec3(-2.0, .4, 2.8))/.8)))*2.0;
    }
    for(int i=0; i<8; ++i) {
        vec3 a = floor(e) + vec3(mod(float(i), 2.0), mod(floor(float(i)/2.0), 2.0), mod(floor(float(i)/4.0), 2.0));
        if(max(I(a*10.0),H(a*10.0)) < 0.0 && fract(a.x*.1+a.y*.17+a.z*.31)>.5) f = min(f,B(abs(a-e))-.49);
    }
    float h = I(d);
    float j = H(d);
    float k = max(max(max(h-2.0, j-5.0), f*10.0), B(abs(.5-fract(d*.01))*100.0)-41.0)+G(d, b, .5,.1, 0.0)+.1;
    float l = length(a-w)-110.0;
    float m = min(E(E(h+a.y*.15-15.0+max(0.0, j)-G(d, b, .05, 2.0, 0.0), a.y + 40.0 - E(-G(a, b, .01, 15.0, 0.0),-G(a+40.0, b, .011, 15.0, 0.0), .3)+(b>1 ? sin(G(a, b, .02, 1.0, 0.0) * 30.0 + a.x + a.z)*.05 : 0.0), 50.0)*.95, k, 10.0), min(l,g));
    return vec2(m, float(m==k) + float(m==l) * 2.0 + float(m==g) * 3.0);
}

vec2 N5(vec3 a, vec3 c)
{
    vec2 d;
    float e = 0.0;
    for(int i=0; i<5; ++i) {
        d = M(a+c*e, 1);
        if(abs(d.x)<(e*5.0 + 1.0)*.0001 || e>=3000.0) break;
        e = min(e+d.x*y, 3000.0);
    }
    return vec2(e, d.y);
}
vec2 N80(vec3 a, vec3 c)
{
    vec2 d;
    float e = 0.0;
    for(int i=0; i<80; ++i) {
        d = M(a+c*e, 1);
        if(abs(d.x)<(e*5.0 + 1.0)*.0001 || e>=3000.0) break;
        e = min(e+d.x*y, 3000.0);
    }
    return vec2(e, d.y);
}

float O(vec3 a,float b)
{
    return exp(min(H(a-v), 0.0)*b);
}

float P(vec3 a,vec3 b)
{
    float c = N5(a+b*2.0, b).x;
    return C(c*c*.005);
}

float Q(vec3 a,int b,float c,float d)
{
    float e = C(c*10.0)+c*.3;
    float f = G(a, b, d, .3, C(c*2.0) + c * .2);
    return E(
        min(min(length(a.zx),length(a.xy)),length(a.yz))+(length(a)-C(c*50.0)*5.0+c)*.3-f*e,
        E(  E(length(a+e*1.2)-e*2.0-f, length(a+e*1.2*vec3(-1.0, -1.0, 1.0))-e*2.2-f,.4),
            E(length(a+e*1.2*vec3(1.0,-1.0,-1.0))-e*2.4-f,length(a+e*1.2*vec3(-1.0, 1.0, -1.0))-e*2.6-f,.4),
            .4), .2);
}

vec4 R(vec3 a,vec3 b,vec3 c,float d,float e,float f)
{
    float g = 0.0;
    float h = 1.0;
    vec3 j = vec3(0);
    if(d > 0.0) {
        d += .1;
        for(int i=0; i<32; ++i) {
            if(g>=f) break;
            vec3 k=b+c*g-a,l=k/e;
            float m = Q(l, 3, d, 1.2);
            float n = Q(l, 5, d-.1,1.2);
            float p = exp(smoothstep(d, -d, n*.2) * 40.0 - 20.0);
            float q = max(min(m,n),.1) * e * y / (h*.8+.4);
            j += h*((exp(smoothstep(d,-d,m*.5)*20.0-10.0)*exp(-d*9.0)*vec3(1.0, .2, .1)+C(p*.005)*(C(Q(l+vec3(.73,.64,.23)*.3, 5, d-.1,1.2)*e*5.0)*.5+.5)*vec3(40.0, 32.0, 28.0) * O(k+a,.004)+vec3(2.0, 1.0, 5.0)*.0001)*vec3(6.0, 5.0, 3.0)*.01) * q;
            h *= exp(-.1*p*q);
            g+=q;
        }
    }
    return vec4(j,h);
}

vec3 S(vec3 a,vec3 b,vec3 c,float d)
{
    float e = dot(c,vec3(.73,.64,.23))*.1+.9;
    float f = G(c*vec3(1.0, 3.0, 1.0), 8, 3.0, .3, 0.0);
    float g = O(b+c*d,.004);
    return mix(vec3(5.0, 3.4, 2.9)*(pow(e,4.0)*.2+pow(e,99.0)*.7+.1)*g, mix(a,mix(vec3(.42, .6, 12.0)*smoothstep(1.0, 0.0, f), vec3(40.0, 32.0, 28.0),smoothstep(0.0,1.0,f-G(vec3(.73,.64,.23)*.02+c*vec3(1.0, 3.0, 1.0), 8, 3.0, .3, 0.0)))*g,smoothstep(1800.0,3000.0,d)), exp(-d*.0025*(smoothstep(.5, -1.0, c.y)*.95+.05)));
}

vec3 T(vec3 a,vec3 b,vec3 c,vec3 d,vec3 e)
{
    vec3 f = normalize(b+e);
    float g = d.z * d.z;
    float h = max(0.0, dot(a,e));
    float j = max(0.0, dot(a,f));
    float k = j * j * (g*g-1.0)+1.0;
    float l = g * .5;
    return(c*(1.0-d.y)+d.x*g*g/(3.14159265*k*k)*(d.y+(1.0-d.y)*pow(1.0-max(0.0,dot(e,f)),5.0))/((h*(1.0-l)+l)*(max(0.0,dot(a,b))*(1.0-l)+l)))*h;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 fc = (fragCoord.xy / iResolution.xy) * vec2(1280.0, 720.0);
    vec2 sc = fragCoord.xy / (iResolution.x / 1280.0);
    u = iGlobalTime;
    y = fract(sin(float(fc.x)*.67 + float(fc.y)*.97 + u*7.0)*85081.0)*.05 + .95;
    z = u + y*.2 - .2;
    v = vec3(0.0, smoothstep(52.0, 66.0, z)*2000.0, 0.0);
    w = v;
    x = vec3(sin(z*.5)*2.0, 0.0, z*21.0 - 2015.0)*10.0;

    vec3 a = vec3(0.0, smoothstep(19.5, 0.0, z)*80.0 - 2.0, z*40.0 - 4000.0)*5.0;
    vec3 b;
    vec3 c = vec3(0.0, z - 25.0, z + 9.0);
    vec3 h = vec3(0.0);
    vec3 d = h;
    float e = .002;
    float f = 0.0;
    float g = 40.0;
    if (30.0 < u) {
        if (u < 46.0) {
            a = x + sin(vec3(3.0, 5.0, 7.0)*(z - 17.0)*.05)*30.0;
            c = x + sin(vec3(3.0, 5.0, 7.0)*(z - 17.0)*.07)*7.0 - a;
            e = .005;
        }
        else if (u < 91.0) {
            float b = z - 60.0;
            a = vec3(180.0, 174.0, b*200.0 - 7670.0);
            c = vec3(sin(b*.2)*3.0 + 2.0, smoothstep(0.0, 4.0, b)*smoothstep(50.0, 10.0, b)*15.0 - 5.0, 5.0);
            e += D(b - 1.0)*.02;
            w = vec3(33.0, 57.0, b*45.0 - 1650.0)*5.0;
            x = w + vec3(cos(b*.5), -1.0, 6.0)*50.0;
            if (b < 3.0) x = a - vec3(sin(b*.4 - 2.0)*3.0, -b - 2.0, b + 2.0) * 15.0;
        }
        else {
            e *= 2.0;
            float b = z - 100.0;
            float h = b + sin(b*.4*3.14159265 - 1.7);
            w = vec3(32.0, 54.0, b*70.0 - 220.0)*5.0;
            x = w + vec3(sin(h)*3.0, sin(h*1.7) - 1.0, 14.0)*20.0;
            a = w + mix(mix(vec3(7.0, 22.0, b*3.0 + 20.0), -vec3(13.0, 16.0, b - 60.0), smoothstep(0.0, 15.0, b)), vec3(-sin(b*.34)*35.0, 5.0, cos(b*.68)*33.0 + 30.0), smoothstep(4.0, 7.0, b)*smoothstep(22.0, 18.0, b))*5.0;
            c = mix(x, w, (smoothstep(3.0, -9.0, b) + smoothstep(21.0, 23.0, b)*smoothstep(37.0, 32.0, b))*.8 + .1) - a;
            d = vec3(3.0, 7.0, 32.0) * 50.0;
            f = b / 3.0 - 1.8;
            if (b > 15.0) {
                d = vec3(3, 4, 96)*50.0;
                f -= 3.3;
            }
            if (b > 22.8) {
                b -= 22.8;
                d = vec3(3.0, b + 5.0, b*3.0 + 137.0) * 50.0;
                f = b / 8.0;
                g = 150.0;
                e += D(b*2.0)*.05;
                x = w + vec3(sin(b*.7 + 2.0)*10.0 - 4.0, sin(b*.5 + 4.0)*2.0 - 12.0, 50.0 + b*b*.5 - b*8.0)*5.0;
                w *= float(b < .5);
            }
        }
    }

    {
        vec3 a = normalize(c);
        vec3 d = normalize(cross(vec3(0.0, 1.0, 0.0), a));
        vec3 f = normalize(vec3(G(vec3(z), 5, 1.3, e, 0.0), G(vec3(z), 5, 1.7, e, 0.0), .5));
        vec3 g = normalize(cross(vec3(G(vec3(z), 5, 1.5, e, 0.0) + sin(z*.15), 2.0, 0.0), f));
        b = normalize(
//          mat3(d, cross(a, d), a) * mat3(-g, cross(f, g), f) * vec3(sc / 108.0 - vec2(8.9, 5.0), 6.0));
            mat3(d, cross(a, d), a) * mat3(-g, cross(f, g), f) * vec3(sc / 72.0 - vec2(8.9, 5.0), 6.0));
    }

    vec2 j = N80(a, b);
    float k = j.x;
    vec3 l = a + b*k;
    vec3 t = fract((v - l) / 3.14159265*.01 + vec3(.5, 0.0, .5)) - .5;
    vec3 m = vec3(1.0, -1.0, -1.0) * .01;
    vec3 n = normalize(M(l + m, 5).x*m + M(l + m.yyx, 5).x*m.yyx + M(l + m.yxy, 5).x*m.yxy + M(l + m.xxx, 5).x*m.xxx);
    vec3 o = vec3(5.0, 1.0, 1.0)*.01;
    vec3 p = vec3(.2, .15, .8);
    float q = O(l, .004);
    float r = P(l, n);
    if (int(j.y) == 1) {
        o = vec3(5.0, 4.0, 3.0)*.01;
        p = vec3(.1, .1, .5);
    }
    else if (int(j.y) == 2) {
        vec3 c = fract(n*.1);
        vec3 d = abs(.5 - c) - .5;
        float b = 1.0;
        float e = B(d);
        for (int i = 0; i < 7; ++i) {
            d = .5 - abs(.5 - fract(c*b))*3.0;
            b *= 3.0;
            e = max(min(max(d.x, d.z), min(max(d.x, d.y), max(d.y, d.z))) / b, e);
        }
        b = smoothstep(-(k*.001 + .05), k*.001 + .05, abs(.5 - fract(e*900.0)) - .4);
        o = vec3(1.0, 2.0, 5.0)*.01;
        p = vec3(.3, .1, mix(.5, .1, b));
        h = (b + .01) * .002 * vec3(5.0, 1.0, 5.0) / (1.0001 - sin(u*3.14159265*.4 + 1.3));
    }
    else if (int(j.y) == 3) {
        o = vec3(2.0, 3.0, 3.0) * .01;
        p = vec3(.3, .1, .1);
        h = smoothstep(1.0, 0.0, abs(l - x + 4.0).z)*.1*vec3(1.0, 5.0, 1.0) / (1.0001 - sin(u*13.0772 + .07));
    }
    vec4 s = R(d, a, b, f, g, k);
    h = mix(S(s.xyz, a, b, length(a - d)), S(h + (T(n, -b, o, p, vec3(.73, .64, .23))*P(l, vec3(.73, .64, .23)) + T(n, -b, o, mix(p, vec3(p.xy, 1.0), .5), -vec3(.73, .64, .23))*P(l, -vec3(.73, .64, .23))*vec3(.1, .088, .085))*vec3(40.0, 32.0, 28.0)*q + T(n, -b, o, mix(p, vec3(p.xy, 1.0), .5), n)*(mix(vec3(.64, .47, 1.4), vec3(6.4, 5.4, 16.0), n.y*.5 + .5)*q + g*9.0*vec3(1.0, .2, .1)*D(f*20.0)*(dot(normalize(d - l), n)*.5 + .5) / exp(length(d - l)*.01) + .02*vec3(5.0, 1.0, 5.0) / (1.0001 - sin(u*3.14159265*.4 + 1.3))*(dot(normalize(w - l), n)*.5 + .5) / exp(length(w - l)*.01) + .5*vec3(2.0, 1.0, 5.0)*(dot(normalize(t), n)*.5 + .5) / exp(length(t)*7.0)*(1.0 / (1.0001 - B(sin(u + (v - l)*.1)) + float(j.y != 1.0)*.5) + 1.0)*smoothstep(3000.0, 2000.0, abs(l.z - 4000.0))*smoothstep(108.0, 113.0, u))*r, a, b, k), s.a);
    if (99.0 < u && u < 123.0 && fract(u*.2) < .2) {
        for (int i = 0; i < 3; ++i) {
            float c = floor(u*5.0)*3.14159265*.5;
            h += F(w + vec3(sin(c), cos(c), 0.0)*110.0, a, vec3(sin(z*(float(i) + 2.0)*.7), sin(z*(float(i) + 2.0)*.5), 7.0)*300.0, l - a, i)*vec3(5.0, 1.0, 1.0)*.2;
        }
    }
    if (118.0 < u && u < 123.0) {
        for (int i = 0; i < 4; ++i) {
            float c = z*2.0 + float(i)*3.14159265*.5;
            float b = smoothstep(120.0, 120.5, z)*3.14159265*.5;
            h += F(x, a, vec3(sin(c)*cos(b), cos(c)*cos(b), -sin(b))*5000.0, l - a, i) * vec3(1.0, 5.0, 1.0);
        }
    }
    h *= O(a, -.0015);
    fragColor = vec4(pow(h / (abs(h) + 1.0), vec3(.45)), 1.0);
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