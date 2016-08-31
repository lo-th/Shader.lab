
// ------------------ channel define
// 0_# bufferFULL_billiardB #_0
// ------------------

// "Quasi Billiards" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy
#define mPtr iMouse

const float pi = 3.14159;

float Hashff (float p)
{
  const float cHashM = 43758.54;
  return fract (sin (p) * cHashM);
}

const float txRow = 32.;

vec4 Loadv4 (int idVar)
{
  float fi = float (idVar);
  return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  float fi = float (idVar);
  vec2 d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}

mat3 VToRMat (vec3 v, float a)
{
  mat3 m;
  float c, s, a1, a2;
  c = cos (a);  s = sin (a);
  m[0][0] = (1. - c) * v.x * v.x + c;
  m[1][1] = (1. - c) * v.y * v.y + c;
  m[2][2] = (1. - c) * v.z * v.z + c;
  a1 = (1. - c) * v.x * v.y;  a2 = - s * v.z;
  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = (1. - c) * v.z * v.x;  a2 = - s * v.y;
  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = (1. - c) * v.y * v.z;  a2 = - s * v.x;
  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return m;
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

vec4 RMatToQ (mat3 m)
{
  vec4 q;
  const float tol = 1e-6;
  q.w = 0.5 * sqrt (max (1. + m[0][0] + m[1][1] + m[2][2], 0.));
  if (abs (q.w) > tol) q.xyz =
     vec3 (m[1][2] - m[2][1], m[2][0] - m[0][2], m[0][1] - m[1][0]) / (4. * q.w);
  else {
    q.x = sqrt (max (0.5 * (1. + m[0][0]), 0.));
    if (abs (q.x) > tol) q.yz = vec2 (m[0][1], m[0][2]) / q.x;
    else {
      q.y = sqrt (max (0.5 * (1. + m[1][1]), 0.));
      if (abs (q.y) > tol) q.z = m[1][2] / q.y;
      else q.z = 1.;
    }
  }
  return normalize (q);
}

vec4 EulToQ (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
}

const int nBall = 16;
float hbLen, dt, tCur, aCue, nPlay, nStep, runState;

void Step (int mId, out vec4 p, out vec4 qt)
{
  vec2 r, rn, dr, f, v;
  float fOvlap, fric, rSep, vm;
  fOvlap = 1000.;
  fric = 0.015;
  p = Loadv4 (2 * mId);
  r = p.xy;
  v = p.zw;
  qt = Loadv4 (2 * mId + 1);
  if (r.x < 2. * hbLen) {
    f = vec2 (0.);
    for (int n = 0; n < nBall; n ++) {
      rn = Loadv4 (2 * n).xy;
      if (rn.x < 2. * hbLen) {
        dr = r - rn;
        rSep = length (dr);
        if (n != mId && rSep < 1.) f += fOvlap * (1. / rSep - 1.) * dr;
      }
    }
    dr = hbLen * vec2 (1., 1.75) - abs (r);
    f -= step (dr, vec2 (1.)) * fOvlap * sign (r) * (1. / abs (dr) - 1.) * dr;
    f -= fric * v;
    if (runState == 2.) {
      v += dt * f;
      r += dt * v;
    }
    if (length (abs (r) - hbLen * vec2 (1., 1.75) + 0.6) < 0.9 ||
       length (abs (r) - hbLen * vec2 (1., 0.) + 0.6) < 0.9) r.x = 100. * hbLen;
    if (runState == 2.) {
      vm = length (v);
      if (vm > 1e-6) qt = RMatToQ (QToRMat (qt) *
         VToRMat (normalize (vec3 (v.y, 0., - v.x)), vm * dt / 0.5));
    }
  }
  p = vec4 (r, v);
}

void Init (int mId, out vec4 p, out vec4 qt)
{
  vec3 e;
  vec2 r, v;
  float s, fm;
  if (mId == 0) r = vec2 (0., -0.6 * hbLen);
  else if (mId < nBall) {
    fm = float (mId);
    if (mId == 1) r = vec2 (0., 0.);
    else if (mId <= 3) r = vec2 (fm - 2.5, 1.);
    else if (mId <= 6) r = vec2 (fm - 5., 2.);
    else if (mId <= 10) r = vec2 (fm - 8.5, 3.);
    else r = vec2 (fm - 13., 4.);
    r.x *= 1.1;
    r.y += 0.2 * hbLen;
  }
  if (runState == 0.) aCue = pi * (0.5 + 0.09 * sin (0.6 * 2. * pi * tCur));
  if (mId < nBall) {
    v = (mId == 0) ? 10. * vec2 (cos (aCue), sin (aCue)) : vec2 (0.);
    p = vec4 (r, v);
    s = 7.7 * (nPlay + float (mId)) / float (nBall);
    e = normalize (vec3 (Hashff (mod (s, 1.)),
       Hashff (mod (s + 0.2, 1.)), Hashff (mod (s + 0.4, 1.))));
    qt = EulToQ (vec3 (atan (e.x, e.y), acos (e.z),
       2. * pi * Hashff (mod (s + 0.6, 1.))));
  }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 stDat, p, qt;
  int mId, pxId;
  tCur = iGlobalTime;
  vec2 kv = floor (fragCoord);
  pxId = int (kv.x + txRow * kv.y);
  if (kv.x >= txRow || pxId > 2 * nBall) discard;
  mId = pxId / 2;
  hbLen = 8.;
  aCue = 0.;
  nPlay = 0.;
  nStep = 0.;
  runState = 0.;
  dt = 0.03;
  if (iFrame == 0) {
    stDat = vec4 (nStep, 0., aCue, nPlay);
    runState = 0.;
  } else {
    stDat = Loadv4 (2 * nBall);
    nStep = stDat.x;
    runState = stDat.y;
    aCue = stDat.z;
    nPlay = stDat.w;
    if (runState == 0.) {
      if (nStep > 50. && mPtr.z > 0. || nStep > 300.) {
        runState = 1.;
        nStep = 0.;
      }
    } else if (runState == 1.) {
      if (nStep > 50.) runState = 2.;
    }
    ++ nStep;
    if (mId < nBall) {
      Step (mId, p, qt);
      if (pxId != 2 * mId) p = qt;
    }
    if (runState == 2.) {
      if (mPtr.z > 0. || nStep > 1800.) {
        runState = 0.;
        nStep = 0.;
        ++ nPlay;
      }
    }
  }
  if (runState == 0.) {
    Init (mId, p, qt);
    if (pxId != 2 * mId) p = qt;
  }
  if (pxId == 2 * nBall) stDat = vec4 (nStep, runState, aCue, nPlay);
  Savev4 (pxId, ((pxId < 2 * nBall) ? p : stDat), fragColor, fragCoord);
}
