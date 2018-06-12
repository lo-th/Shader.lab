// ------------------ channel define
// 0_# bufferFULL_rollingA #_0
// ------------------

// "Rolling Stones" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec4 QtMul (vec4 q1, vec4 q2);
mat3 QtToRMat (vec4 q);
vec4 RMatToQt (mat3 m);
vec4 EulToQt (vec3 e);
mat3 LpStepMat (vec3 a);
float Hashff (float p);
float Noisefv2 (vec2 p);
vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

mat2 fqRot;
vec3 rLead;
float todCur, nStep, fWav, aWav, htFac, htMax;
const int nBall = 144;
const float txRow = 128.;
const float pi = 3.14159;

float GrndHt (vec2 p)
{
  vec2 q;
  float f, wAmp;
  q = 0.05 * p;
  f = 0.;
  wAmp = 1.;
  for (int j = 0; j < 5; j ++) {
    f += wAmp * Noisefv2 (q);
    wAmp *= aWav;
    q *= fqRot;
  }
  return htMax * f;
}

void Step (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm,
   out float sz)
{
  vec4 p;
  vec3 rmN, vmN, wmN, dr, dv, drw, am, wam, vn;
  float fOvlap, fricN, fricT, fricS, fricSW, fDamp, fAttr, grav, rSep, szN, szAv,
     fc, ft, ms, drv, dt;
  const vec2 e = vec2 (0.1, 0.);
  fOvlap = 1000.;
  fricN = 10.;
  fricS = 1.;
  fricSW = 10.;
  fricT = 0.5;
  fAttr = 0.2;
  fDamp = 0.05;
  grav = 10.;
  p = Loadv4 (4 * mId);
  rm = p.xyz;
  sz = p.w;
  vm = Loadv4 (4 * mId + 1).xyz;
  qm = Loadv4 (4 * mId + 2);
  wm = Loadv4 (4 * mId + 3).xyz;
  ms = sz * sz * sz;
  am = vec3 (0.);
  wam = vec3 (0.);
  for (int n = 0; n < nBall; n ++) {
    p = Loadv4 (4 * n);
    rmN = p.xyz;
    szN = p.w;
    dr = rm - rmN;
    rSep = length (dr);
    szAv = 0.5 * (sz + szN);
    if (n != mId && rSep < szAv) {
      fc = fOvlap * (szAv / rSep - 1.);
      vmN = Loadv4 (4 * n + 1).xyz;
      wmN = Loadv4 (4 * n + 3).xyz;
      dv = vm - vmN;
      drv = dot (dr, dv) / (rSep * rSep);
      fc = max (fc - fricN * drv, 0.);
      am += fc * dr;
      dv -= drv * dr + cross ((sz * wm + szN * wmN) / (sz + szN), dr);
      ft = min (fricT, fricS * abs (fc) * rSep / max (0.001, length (dv)));
      am -= ft * dv;
      wam += (ft / rSep) * cross (dr, dv);
    }
  }
  vn = normalize (vec3 (GrndHt (rm.xz + e.xy) - GrndHt (rm.xz - e.xy), 2. * e.x,
     GrndHt (rm.xz + e.yx) - GrndHt (rm.xz - e.yx)));
  dr.xz = -0.5 * sz * vn.xz;
  dr.y = rm.y + 0.55 * sz - GrndHt (rm.xz - dr.xz);
  rSep = length (dr);
  if (rSep < sz) {
    fc = fOvlap * (sz / rSep - 1.);
    dv = vm;
    drv = dot (dr, dv) / (rSep * rSep);
    fc = max (fc - fricN * drv, 0.);
    am += fc * dr;
    dv -= drv * dr + cross (wm, dr);
    ft = min (fricT, fricSW * abs (fc) * rSep / max (0.001, length (dv)));
    am -= ft * dv;
    wam += (ft / rSep) * cross (dr, dv);
  }
  am += fAttr * (rLead - rm);
  am.y -= grav * ms;
  am -= fDamp * vm;
  dt = 0.01;
  vm += dt * am / ms;
  rm += dt * vm;
  wm += dt * wam / (0.1 * ms * sz);
  qm = normalize (QtMul (RMatToQt (LpStepMat (0.5 * dt * wm)), qm));
}

void Init (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm,
   out float sz)
{
  vec3 e;
  float mIdf, nbEdge;
  nbEdge = floor (sqrt (float (nBall)) + 0.1);
  mIdf = float (mId);
  rm.xz = floor (vec2 (mod (mIdf, nbEdge), mIdf / nbEdge)) - 0.5 * (nbEdge - 1.) - 20.;
  rm.y = GrndHt (rm.xz) + 3.;
  vm = 2. * normalize (vec3 (Hashff (mIdf + todCur), Hashff (mIdf + todCur + 0.3),
     Hashff (mIdf + todCur + 0.6)) - 0.5);
  e = normalize (vec3 (Hashff (mIdf), Hashff (mIdf + 0.3),
     Hashff (mIdf + 0.6)));
  qm = EulToQt (e);
  wm = vec3 (0.);
  sz = 1. - 0.3 * Hashff (mIdf + 0.1);
}

#define N_SLIDR 4

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 wgBx[N_SLIDR + 1], mPtr, mPtrP, stDat, parmV, p, qm;
  vec3 rm, vm, wm, rMid;
  vec2 iFrag, canvas, ust;
  float sz, tCur, tCurM, vW, asp, el, az, drSpd;
  int mId, pxId, wgSel, wgReg, kSel, kp;
  bool doInit;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 4 * nBall + 5) discard;
  canvas = iResolution.xy;
  tCur = iGlobalTime;
  todCur = iDate.w;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
  wgSel = -1;
  wgReg = -2;
  asp = canvas.x / canvas.y;
  if (pxId < 4 * nBall) mId = pxId / 4;
  else mId = -1;
  if (iFrame == 0) {
    doInit = true;
    parmV = vec4 (0.5, 0.5, 0.5, 0.5);
    mPtrP = mPtr;
    el = 0.;
    az = 0.;
    tCurM = tCur;
  } else {
    doInit = false;
    parmV = Loadv4 (4 * nBall + 2);
    stDat = Loadv4 (4 * nBall + 3);
    mPtrP = vec4 (stDat.xyz, 0.);
    wgSel = int (stDat.w);
    stDat = Loadv4 (4 * nBall + 4);
    el = stDat.x;
    az = stDat.y;
    tCurM = stDat.w;
  }
  if (mPtr.z > 0.) {
    for (int k = 0; k < N_SLIDR; k ++)
       wgBx[k] = vec4 ((0.31 + 0.05 * float (k)) * asp, -0.15, 0.014 * asp, 0.18);
    wgBx[N_SLIDR] = vec4 (0.45 * asp, -0.4, 0.022, 0.);
    for (int k = 0; k < N_SLIDR; k ++) {
      ust = abs (mPtr.xy * vec2 (asp, 1.) - wgBx[k].xy) - wgBx[k].zw;
      if (max (ust.x, ust.y) < 0.) wgReg = k;
    }
    ust = mPtr.xy * vec2 (asp, 1.) - wgBx[N_SLIDR].xy;
    if (length (ust) < wgBx[N_SLIDR].z) wgReg = N_SLIDR;
    if (mPtrP.z <= 0.) wgSel = wgReg;
    if (wgSel >= 0) tCurM = tCur;
  } else {
    wgSel = -1;
    wgReg = -2;
  }
  if (wgSel < 0) {
    if (mPtr.z > 0.) {
      az = pi * mPtr.x;
      el = 0.5 * pi * mPtr.y;
    } else {
      el = 0.;
      az = 0.;
    }
  } else {
    if (wgSel < N_SLIDR) {
      for (int k = 0; k < N_SLIDR; k ++) {
        if (wgSel == k) {
          kSel = k;
          vW = clamp (0.5 + 0.5 * (mPtr.y - wgBx[k].y) / wgBx[k].w, 0., 0.99);
          break;
        }
      }
      if      (kSel == 0) parmV.x = vW;
      else if (kSel == 1) parmV.y = vW;
      else if (kSel == 2) parmV.z = vW;
      else if (kSel == 3) parmV.w = vW;
      if (kSel <= 2) doInit = true;
    }
  }
  fWav = 4. * (0.5 + 0.1 * (parmV.x - 0.5));
  fqRot = fWav * mat2 (0.6, -0.8, 0.8, 0.6);
  aWav = 1. * (0.5 + 0.2 * (parmV.y - 0.5));
  htFac = 30. * (0.5 + 0.2 * (parmV.z - 0.5));
  htMax = htFac * (1. - aWav) / (1. - pow (aWav, 5.));
  drSpd = 1. * (0.52 + 0.96 * (parmV.w - 0.5));
  if (doInit) {
    nStep = 0.;
    if (mId >= 0) Init (mId, rm, vm, qm, wm, sz);
  } else {
    nStep = Loadv4 (4 * nBall).w;
    ++ nStep;
    rLead = Loadv4 (4 * nBall + 1).xyz;
    rLead += drSpd * vec3 (0.03, 0., 0.1);
    rLead.y = GrndHt (rLead.xz) + 2.;
    if (mId >= 0) Step (mId, rm, vm, qm, wm, sz);
  }
  if (pxId == 4 * nBall) {
    rMid = vec3 (0.);
    for (int n = 0; n < nBall; n ++) rMid += Loadv4 (4 * n).xyz;
    rMid /= float (nBall);
    if (doInit) rLead = rMid;
  }
  if (pxId < 4 * nBall) {
    kp = 4 * mId;
    if      (pxId == kp + 0) p = vec4 (rm, sz);
    else if (pxId == kp + 1) p = vec4 (vm, 0.);
    else if (pxId == kp + 2) p = qm;
    else if (pxId == kp + 3) p = vec4 (wm, 0.);
    stDat = p;
  } else {
    kp = 4 * nBall;
    if      (pxId == kp + 0) stDat = vec4 (rMid, nStep);
    else if (pxId == kp + 1) stDat = vec4 (rLead, 0.);
    else if (pxId == kp + 2) stDat = parmV;
    else if (pxId == kp + 3) stDat = vec4 (mPtr.xyz, float (wgSel));
    else if (pxId == kp + 4) stDat = vec4 (el, az, tCur, tCurM);
  }
  Savev4 (pxId, stDat, fragColor, fragCoord);
}

vec4 QtMul (vec4 q1, vec4 q2)
{
  return vec4 (
       q1.w * q2.x - q1.z * q2.y + q1.y * q2.z + q1.x * q2.w,
       q1.z * q2.x + q1.w * q2.y - q1.x * q2.z + q1.y * q2.w,
     - q1.y * q2.x + q1.x * q2.y + q1.w * q2.z + q1.z * q2.w,
     - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w);
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec4 RMatToQt (mat3 m)
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

vec4 EulToQt (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
}

mat3 LpStepMat (vec3 a)
{
  mat3 m1, m2;
  vec3 t, c, s;
  float b1, b2;
  t = 0.25 * a * a;
  c = (1. - t) / (1. + t);
  s = a / (1. + t);
  m1[0][0] = c.y * c.z;  m2[0][0] = c.y * c.z;
  b1 = s.x * s.y * c.z;  b2 = c.x * s.z;
  m1[0][1] = b1 + b2;  m2[1][0] = b1 - b2;
  b1 = c.x * s.y * c.z;  b2 = s.x * s.z;
  m1[0][2] = - b1 + b2;  m2[2][0] = b1 + b2;
  b1 = c.y * s.z;
  m1[1][0] = - b1;  m2[0][1] = b1;  
  b1 = s.x * s.y * s.z;  b2 = c.x * c.z;
  m1[1][1] = - b1 + b2;  m2[1][1] = b1 + b2; 
  b1 = c.x * s.y * s.z;  b2 = s.x * c.z;
  m1[1][2] = b1 + b2;  m2[2][1] = b1 - b2;
  m1[2][0] = s.y;  m2[0][2] = - s.y;
  b1 = s.x * c.y;
  m1[2][1] = - b1;  m2[1][2] = b1;
  b1 = c.x * c.y;
  m1[2][2] = b1;  m2[2][2] = b1;
  return m1 * m2;
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashff (float p)
{
  return fract (sin (p) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

vec4 Loadv4 (int idVar)
{
  float fi;
  fi = float (idVar);
  return texture2D (txBuf, (vec2 (mod (fi, txRow), floor (fi / txRow)) + 0.5) /
     txSize);
}

void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord)
{
  vec2 d;
  float fi;
  fi = float (idVar);
  d = abs (fCoord - vec2 (mod (fi, txRow), floor (fi / txRow)) - 0.5);
  if (max (d.x, d.y) < 0.5) fCol = val;
}
