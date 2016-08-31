
// ------------------ channel define
// 0_# buffer128_phy2A #_0
// ------------------

// "Destruction" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

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

vec4 EulToQt (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
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

float Hashff (float p)
{
  const float cHashM = 43758.54;
  return fract (sin (p) * cHashM);
}

const float txRow = 128.;

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

const float pi = 3.14159;

const int nBlock = 64;
const int nSiteBk = 30;
const vec3 blkSph = vec3 (5., 3., 2.);
const vec3 blkGap = vec3 (1., 0.8, 0.8);

float tCur, nStep;

vec3 RSite (int sId)
{
  float sIdf;
  sIdf = float (sId);
  return blkGap * (floor (vec3 (mod (sIdf, blkSph.x),
      mod (sIdf, blkSph.x * blkSph.y) / blkSph.x,
      sIdf / (blkSph.x * blkSph.y))) - 0.5 * (blkSph - 1.));
}

vec3 FcFun (vec3 dr, float rSep, vec3 dv)
{
  vec3 f;
  float vRel, fo, drv;
  const float fOvlap = 1000., fricN = 10., fricT = 1., fricS = 5.;
  fo = fOvlap * (1. / rSep - 1.);
  drv = dot (dr, dv) / (rSep * rSep);
  dv -= drv * dr;
  vRel = length (dv);
  fo = max (fo - fricN * drv, 0.);
  f = fo * dr;
  if (vRel > 0.001) f -= min (fricT, fricS * abs (fo) * rSep / vRel) * dv;
  return f;
}

void Step (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm)
{
  mat3 mRot, mRotN;
  vec3 rmN, vmN, wmN, dr, dv, dvs, rts, rtsN, rms, vms, fc, am, wam, dSp;
  float farSep, rSep, grav, dt;
  grav = 0.2;
  dt = 0.01;
  rm = Loadv4 (4 + 4 * mId).xyz;
  vm = Loadv4 (4 + 4 * mId + 1).xyz;
  qm = Loadv4 (4 + 4 * mId + 2);
  wm = Loadv4 (4 + 4 * mId + 3).xyz;
  if (nStep < 50.) return;
  if (mId < nBlock) mRot = QtToRMat (qm);
  farSep = length (blkGap * (blkSph - 1.)) + 1.;
  am = vec3 (0.);
  wam = vec3 (0.);
  for (int n = 0; n < nBlock + 4; n ++) {
    rmN = Loadv4 (4 + 4 * n).xyz;
    if (n != mId && length (rm - rmN) < farSep) {
      vmN = Loadv4 (4 + 4 * n + 1).xyz;
      if (n < nBlock) {
        mRotN = QtToRMat (Loadv4 (4 + 4 * n + 2));
        wmN = Loadv4 (4 + 4 * n + 3).xyz;
      }
      for (int j1 = 0; j1 < nSiteBk; j1 ++) {
        rms = rm;
        vms = vm;
        if (mId < nBlock) {
          rts = mRot * RSite (j1);
          rms += rts;
          vms += cross (wm, rts);
        }
        dv = vms - vmN;
        fc = vec3 (0.);
        for (int j2 = 0; j2 < nSiteBk; j2 ++) {
          dr = rms - rmN;
          dvs = dv;
          if (n < nBlock) {
            rtsN = mRotN * RSite (j2);
            dr -= rtsN;
            dvs -= cross (wmN, rtsN);
          }
          rSep = length (dr);
          if (rSep < 1.) fc += FcFun (dr, rSep, dvs);
          if (n >= nBlock) break;
        }
        am += fc;
        if (mId < nBlock) wam += cross (rts, fc);
        else break;
      }
    }
  }
  for (int j = 0; j < nSiteBk; j ++) {
    dr = rm;
    if (mId < nBlock) {
      rts = mRot * RSite (j);
      dr += rts;
    }
    rSep = abs (dr.y);
    if (rSep < 1.) {
      dvs = vm;
      if (mId < nBlock) dvs += cross (wm, rts);
      fc = FcFun (vec3 (0., dr.y, 0.), rSep, dvs);
      am += fc;
      if (mId < nBlock) wam += cross (rts, fc);
      else break;
    }
  }
  am.y -= grav;
  vm += dt * am;
  rm += dt * vm;
  if (mId < nBlock) {
    dSp = blkGap * blkSph;
    wam = mRot * (wam * mRot / (0.5 * (vec3 (dot (dSp, dSp)) - dSp * dSp) + 1.));
    wm += dt * wam;
    qm = normalize (QtMul (RMatToQt (LpStepMat (0.5 * dt * wm)), qm));
  }
}

void Init (int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm)
{
  vec3 r, fn;
  float fmId, szReg, rowGap, layGap, blkGap, a;
  int nb;
  const int npRow = 2;
  rowGap = 18.;
  layGap = 2.61;
  blkGap = 1.55;
  szReg = (float (npRow) + 1.) * rowGap;
  if (mId < nBlock) {
    nb = 0;
    for (int ny = 0; ny < 4 * npRow; ny ++) {
      fn.y = float (ny);
      r.y = (fn.y + 0.5) * layGap + 0.6;
      for (int nz = 0; nz < 2 * npRow; nz ++) {
        if (mod (fn.y, 2.) == 1. && nz == npRow) break;
        fn.z = float (nz);
        if (mod (fn.y, 2.) == 1.) r.z = (fn.z + 1.) * rowGap - 0.5 * szReg;
        else r.z = (floor (0.5 * fn.z) + 1.) * rowGap -
           blkGap * (2. - ((mod (fn.z, 2.) == 0.) ? 1. : 3.)) - 0.5 * szReg;
        for (int nx = 0; nx < 2 * npRow; nx ++) {
          if (mod (fn.y, 2.) == 0. && nx == npRow) break;
          fn.x = float (nx);
      if (mod (fn.y, 2.) == 1.) r.x = (floor (0.5 * fn.x) + 1.) * rowGap -
             blkGap * (2.- ((mod (fn.x, 2.) == 0.) ? 1. : 3.)) - 0.5 * szReg;
      else r.x = (fn.x + 1.) * rowGap - 0.5 * szReg;
          if (nb == mId) {
            rm = r;
            qm = EulToQt (0.5 * pi * vec3 (1., mod (fn.y, 2.), 1.));
          }
          ++ nb;
        }
      }
    }
    vm = vec3 (0.);
    wm = vec3 (0.);
  } else {
    a = float (mId - nBlock);
    rm.y = 20. - 3.1 * a;
    vm.y = 0.;
    a = 0.5 * pi * (a + 0.5);
    rm.xz = 25. * vec2 (cos (a), sin (a));
    a += 0.1 * pi * (Hashff (tCur) - 0.5);
    vm.xz = -8. * vec2 (cos (a), sin (a));
    qm = vec4 (0.);
    wm = vec3 (0.);
  }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 stDat, p, qm;
  vec3 rm, vm, wm;
  vec2 iFrag;
  float mxStep;
  int mId, pxId;
  bool doInit;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 4 * (nBlock + 4) + 4) discard;
  tCur = iGlobalTime;
  if (pxId >= 4) mId = (pxId - 4) / 4;
  else mId = -1;
  doInit = false;
  mxStep = 5500.;
  if (iFrame == 0) {
    doInit = true;
  } else {
    nStep = Loadv4 (0).x;
    ++ nStep;
    if (mId >= 0) Step (mId, rm, vm, qm, wm);
  }
  if (nStep > mxStep) doInit = true;
  if (doInit) {
    nStep = 0.;
    if (mId >= 0) Init (mId, rm, vm, qm, wm);
  }
  if (pxId == 0) stDat = vec4 (nStep, mxStep, 0., 0.);
  else if (pxId == 4 + 4 * mId) p = vec4 (rm, 0.);
  else if (pxId == 4 + 4 * mId + 1) p = vec4 (vm, 0.);
  else if (pxId == 4 + 4 * mId + 2) p = qm;
  else if (pxId == 4 + 4 * mId + 3) p = vec4 (wm, 0.);
  Savev4 (pxId, ((pxId >= 4) ? p : stDat), fragColor, fragCoord);
}
