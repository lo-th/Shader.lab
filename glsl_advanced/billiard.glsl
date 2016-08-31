
// ------------------ channel define
// 0_# bufferFULL_billiardA #_0
// ------------------

// https://www.shadertoy.com/view/MsGGD1

// "Quasi Billiards" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
An enhanced, (slightly) interactive version of "Pseudo Billiards 2", "quasi" being
closer to reality than "pseudo".

The game starts and stops automatically; alternatively, click the mouse while
the cue is swinging to shoot, and later click to reset the game.
*/

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

const float pi = 3.14159;
const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 i = floor (p);
  vec2 f = fract (p);
  f = f * f * (3. - 2. * f);
  vec4 t = Hashv4f (dot (i, cHashA3.xy));
  return mix (mix (t.x, t.y, f.x), mix (t.z, t.w, f.x), f.y);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) * vec2 (1., 1.) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

const float txRow = 32.;

vec4 Loadv4 (int idVar)
{
  float fi = float (idVar);
  return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

mat3 QToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

const int nBall = 16;

vec4 qtBall[nBall];
vec3 ltDir, qHit;
vec2 pBall[nBall];
float dstFar, hbLen, dCue, aCue, nStep, runState;
int idObj;
bool showCue;

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, dh, hIn;
  dMin = dstFar;
  for (int n = 0; n < nBall; n ++) {
    q = p;
    q.xz -= pBall[n];
    d = PrSphDf (q, 0.46);
    if (d < dMin) { dMin = d;  idObj = 10 + n; }
  }
  hIn = hbLen - 0.4;
  q = p;
  d = PrBoxDf (q, vec3 (hIn, 0.4, 1.75 * hIn));
  q.y -= -0.6;
  d = max (PrRoundBoxDf (q, vec3 (hIn + 0.5, 0.5, 1.75 * hIn + 0.5), 0.2), - d);
  q = p;
  q.xz = abs (abs (q.xz) - hIn * vec2 (1., 1.75) + 0.4);
  dh = PrCylDf (q.xzy, 0.55, 1.2);
  q = p;
  q.x = abs (q.x) - hIn + 0.4;
  dh = min (dh, PrCylDf (q.xzy, 0.55, 1.2)); 
  d = max (d, - dh);
  if (d < dMin) { dMin = d;  idObj = 1; }
  if (showCue) {
    q = p;
    q.yz -= vec2 (0., -0.6 * (hIn + 0.4));
    q.xz = Rot2D (q.xz, 0.5 * pi - aCue);
    q.z -= -2.55 - dCue;
    d = PrCylDf (q, 0.1, 2.);
    if (d < dMin) { dMin = d;  idObj = 2;  qHit = q; }
  }
  return dMin;
}


float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  const vec3 e = vec3 (0.0002, -0.0002, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float BallChqr (vec3 rHit, vec4 qtHit)
{
  vec3 r;
  r = QToRMat (qtHit) * rHit;
  return (r.z * (mod (pi + atan (r.x, r.y), 2. * pi) - pi) < 0.) ? 0.4 : 1.;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 qtHit;
  vec3 objCol, col, vn, rHit;
  float dstHit, spec, c;
  int idObjT;
  idObj = -1;
  dstHit = ObjRay (ro, rd);
  if (idObj < 0) dstHit = dstFar;
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    if (idObj == 1) {
      if (abs (ro.x) < (hbLen - 0.4) + 0.3 &&
         abs (ro.z) < 1.75 * (hbLen - 0.4) + 0.3) {
        objCol = vec3 (0.2, 0.3, 0.6);
        if (vn.y > 0.99) objCol *= 1. - 0.2 * Noisefv2 (100. * ro.xz);
        for (int n = 0; n < nBall; n ++) {
          c = length (ro.xz - pBall[n]);
          if (c < 0.5) {
            objCol *= 0.6 + 0.4 * smoothstep (0.2, 0.5, c);
            break;
          }
        }
        if (ro.y < -0.7) objCol *= 0.3;
        else if (ro.y > 0.) objCol *= 1.2;
        spec = 0.1;
      } else {
        objCol = vec3 (0.2, 0.07, 0.);
        spec = 0.4;
      }
    } else if (idObj == 2) {
      objCol = (qHit.z < 1.8) ? vec3 (0.5, 0.3, 0.) : vec3 (0.7, 0.7, 0.3);
      spec = 0.5;
    } else {
      if (idObj == 10) objCol = vec3 (1.);
      else {
        c = float (idObj - 11);
        objCol = HsvToRgb (vec3 (mod (c / float (nBall), 1.),
           1. - 0.3 * mod (c, 3.), 1. - 0.3 * mod (c, 2.)));
      }
      rHit.y = ro.y;
      for (int n = 0; n < nBall; n ++) {
        if (n == idObj - 10) {
          rHit.xz = ro.xz - pBall[n];
          qtHit = qtBall[n];
          break;
        }
      }
      objCol *= BallChqr (rHit, qtHit);
      spec = 0.5;
    }
    col = objCol * (0.2 + 0.8 * max (dot (vn, ltDir), 0.) +
       spec * pow (max (0., dot (ltDir, reflect (rd, vn))), 32.));
  } else col = vec3 (0.02, 0.1, 0.02) * clamp (2.7 + 3. * rd.y, 0., 1.);
  return pow (clamp (col, 0., 1.), vec3 (0.7));
}

void GetBalls ()
{
  vec4 p;
  for (int n = 0; n < nBall; n ++) {
    pBall[n] = Loadv4 (2 * n).xy;
    qtBall[n] = Loadv4 (2 * n + 1);
  }
  p = Loadv4 (2 * nBall);
  nStep = p.x;
  runState = p.y;
  showCue = (runState != 2. || nStep < 150.);
  aCue = p.z;
  dCue = (runState == 1.) ? 3. * smoothstep (0., 30., nStep) *
     (1. - smoothstep (30., 50., nStep)) : 0.;
  hbLen = 8.;
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  mat3 vuMat;
  vec3 rd, ro;
  vec2 ori, ca, sa;
  float tCur, az, el, zmFac, s;
  vec2 canvas = iResolution.xy;
  vec2 uv = 2. * fragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = iGlobalTime;
  GetBalls ();
  dstFar = 100.;
  ltDir = normalize (vec3 (1., 3., 1.));
  az = mod (pi + 0.1 * tCur, 2. * pi);
  el = 0.8 + 0.3 * sin (2. * pi * 0.07 * tCur);
  zmFac = 8.5 - 4. * abs (cos (az));
  if (runState == 0.) s = smoothstep (0., 100., nStep);
  else if (runState == 1.) s = 1.;
  else if (runState == 2.) s = (1. - smoothstep (120., 250., nStep));
  az = mix (az, 0., s);
  el = mix (el, 0.4, s);
  zmFac = mix (zmFac, 15., s);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x) *
     mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y);
  rd = normalize (vec3 (uv, zmFac)) * vuMat;
  ro = vec3 (0., 0., -80.) * vuMat;
  fragColor = vec4 (ShowScene (ro, rd), 1.);
}
