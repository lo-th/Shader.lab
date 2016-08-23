// "Terrain Explorer" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// ------------------ channel define
// 0_# bufferFULL_terraA #_0
// ------------------

vec4 Loadv4 (int idVar);
void Savev4 (int idVar, vec4 val, inout vec4 fCol, vec2 fCoord);

const float pi = 3.14159;
const float txRow = 32.;

void mainImage (out vec4 fragColor, in vec2 fragCoord)
{
  vec4 wgBx[9], mPtr, mPtrP, stDat, parmV1, parmV2;
  vec2 iFrag, canvas, ust;
  float tCur, tCurP, tCurM, vW, asp, el, az, flyVel, mvTot;
  int pxId, wgSel, wgReg, kSel, grType, qType, shType;
  iFrag = floor (fragCoord);
  pxId = int (iFrag.x + txRow * iFrag.y);
  if (iFrag.x >= txRow || pxId >= 5) discard;
  canvas = iResolution.xy;
  tCur = iGlobalTime;
  mPtr = iMouse;
  mPtr.xy = mPtr.xy / iResolution.xy - 0.5;
  wgSel = -1;
  wgReg = -2;
  asp = canvas.x / canvas.y;
  el = -0.1;
  az = 0.;
  if (iFrame == 0) {
    parmV1 = vec4 (0.6, 0.6, 0.7, 0.5);
    parmV2 = vec4 (0.3, 1., 2., 1.);
    mvTot = 0.;
    mPtrP = mPtr;
    tCurP = tCur;
    tCurM = tCur;
  } else {
    parmV1 = Loadv4 (0);
    parmV2 = Loadv4 (1);
    flyVel = parmV2.x;
    stDat = Loadv4 (2);
    tCurP = stDat.z;
    tCurM = stDat.w;
    stDat = Loadv4 (3);
    mvTot = stDat.x;
    mvTot += 8. * flyVel * (tCur - tCurP);
    stDat = Loadv4 (4);
    mPtrP = vec4 (stDat.xyz, 0.);
    wgSel = int (stDat.w);
  }
  if (mPtr.z > 0.) {
    for (int k = 0; k <= 4; k ++)
       wgBx[k] = vec4 ((0.25 + 0.05 * float (k)) * asp, 0., 0.014 * asp, 0.18);
    for (int k = 5; k <= 7; k ++)
       wgBx[k] = vec4 ((0.3 + 0.05 * float (k - 5)) * asp, -0.3, 0.024, 0.024);
    wgBx[8] = vec4 (0.45 * asp, -0.4, 0.022, 0.);
    for (int k = 0; k <= 7; k ++) {
      ust = abs (mPtr.xy * vec2 (asp, 1.) - wgBx[k].xy) - wgBx[k].zw;
      if (max (ust.x, ust.y) < 0.) wgReg = k;
    }
    ust = mPtr.xy * vec2 (asp, 1.) - wgBx[8].xy;
    if (length (ust) < wgBx[8].z) wgReg = 8;
    if (mPtrP.z <= 0.) wgSel = wgReg;
    if (wgSel >= 0) tCurM = tCur;
  } else {
    wgSel = -1;
    wgReg = -2;
  }
  if (wgSel < 0) {
    if (mPtr.z > 0.) {
      az = 2. * pi * mPtr.x;
      el = 0.8 * pi * mPtr.y;
    }
  } else {
    if (wgSel < 5) {
      for (int k = 0; k <= 4; k ++) {
        if (wgSel == k) {
          kSel = k;
          vW = clamp (0.5 + 0.5 * (mPtr.y - wgBx[k].y) / wgBx[k].w, 0., 0.99);
          break;
        }
      }
      if      (kSel == 0) parmV1.x = vW;
      else if (kSel == 1) parmV1.y = vW;
      else if (kSel == 2) parmV1.z = vW;
      else if (kSel == 3) parmV1.w = vW;
      else if (kSel == 4) parmV2.x = vW;
    } else if (mPtrP.z <= 0.) {
      if (wgSel == 5) {
        grType = int (parmV2.y);
        if (++ grType >= 5) grType = 1;
        parmV2.y = float (grType);
      } else if (wgSel == 6) {
        qType = int (parmV2.z);
        if (++ qType >= 4) qType = 1;
        parmV2.z = float (qType);
      } else if (wgSel == 7) {
        shType = int (parmV2.w);
        if (++ shType >= 4) shType = 1;
        parmV2.w = float (shType);
      }
    }
  }
  if (canvas.y < 200.) parmV2.y = floor (mod (tCur, 40.) / 10.) + 1.;
  if      (pxId == 0) stDat = parmV1;
  else if (pxId == 1) stDat = parmV2;
  else if (pxId == 2) stDat = vec4 (el, az, tCur, tCurM);
  else if (pxId == 3) stDat = vec4 (mvTot, 0., 0., 0.);
  else if (pxId == 4) stDat = vec4 (mPtr.xyz, float (wgSel));
  Savev4 (pxId, stDat, fragColor, fragCoord);
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



void main(){

    vec4 color = vec4(0.0);

    // screen space
    vec2 coord = gl_FragCoord.xy;
    // object space
    //vec2 coord = vUv * iResolution.xy;

    mainImage( color, coord );

    gl_FragColor = color;

}