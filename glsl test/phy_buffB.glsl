
// > buff A
#define txBuf iChannel0
#define txSize iChannelResolution[0].xy

precision highp float;
precision highp int;
uniform float time;
varying vec2 vUv;


vec4 QtMul(vec4 q1, vec4 q2) {

    return vec4(q1.w * q2.x - q1.z * q2.y + q1.y * q2.z + q1.x * q2.w, q1.z * q2.x + q1.w * q2.y - q1.x * q2.z + q1.y * q2.w, -q1.y * q2.x + q1.x * q2.y + q1.w * q2.z + q1.z * q2.w, -q1.x * q2.x - q1.y * q2.y - q1.z * q2.z + q1.w * q2.w);
}

mat3 QtToRMat(vec4 q) {

    mat3 m;
    float a1, a2, s;
    q = normalize(q);
    s = q.w * q.w - 0.5;
    m[0][0] = q.x * q.x + s;
    m[1][1] = q.y * q.y + s;
    m[2][2] = q.z * q.z + s;
    a1 = q.x * q.y;
    a2 = q.z * q.w;
    m[0][1] = a1 + a2;
    m[1][0] = a1 - a2;
    a1 = q.x * q.z;
    a2 = q.y * q.w;
    m[2][0] = a1 + a2;
    m[0][2] = a1 - a2;
    a1 = q.y * q.z;
    a2 = q.x * q.w;
    m[1][2] = a1 + a2;
    m[2][1] = a1 - a2;
    return 2. * m;

}

vec4 RMatToQt(mat3 m) {

    vec4 q;
    const float tol = 1e-6;
    q.w = 0.5 * sqrt(max(1. + m[0][0] + m[1][1] + m[2][2], 0.));
    if (abs(q.w) > tol) q.xyz = vec3(m[1][2] - m[2][1], m[2][0] - m[0][2], m[0][1] - m[1][0]) / (4. * q.w);
 else 
    {
        q.x = sqrt(max(0.5 * (1. + m[0][0]), 0.));
        if (abs(q.x) > tol) q.yz = vec2(m[0][1], m[0][2]) / q.x;
 else 
        {
            q.y = sqrt(max(0.5 * (1. + m[1][1]), 0.));
            if (abs(q.y) > tol) q.z = m[1][2] / q.y;
 else q.z = 1.;
        }
    }
    return normalize(q);
}

vec4 EulToQt(vec3 e) {

    float a1, a2, a3, c1, s1;
    a1 = 0.5 * e.y;
    a2 = 0.5 * (e.x - e.z);
    a3 = 0.5 * (e.x + e.z);
    s1 = sin(a1);
    c1 = cos(a1);
    return normalize(vec4(s1 * cos(a2), s1 * sin(a2), c1 * sin(a3), c1 * cos(a3)));

}

mat3 LpStepMat(vec3 a) {

    mat3 m1, m2;
    vec3 t, c, s;
    float b1, b2;
    t = 0.25 * a * a;
    c = (1. - t) / (1. + t);
    s = a / (1. + t);
    m1[0][0] = c.y * c.z;
    m2[0][0] = c.y * c.z;
    b1 = s.x * s.y * c.z;
    b2 = c.x * s.z;
    m1[0][1] = b1 + b2;
    m2[1][0] = b1 - b2;
    b1 = c.x * s.y * c.z;
    b2 = s.x * s.z;
    m1[0][2] = -b1 + b2;
    m2[2][0] = b1 + b2;
    b1 = c.y * s.z;
    m1[1][0] = -b1;
    m2[0][1] = b1;
    b1 = s.x * s.y * s.z;
    b2 = c.x * c.z;
    m1[1][1] = -b1 + b2;
    m2[1][1] = b1 + b2;
    b1 = c.x * s.y * s.z;
    b2 = s.x * c.z;
    m1[1][2] = b1 + b2;
    m2[2][1] = b1 - b2;
    m1[2][0] = s.y;
    m2[0][2] = -s.y;
    b1 = s.x * c.y;
    m1[2][1] = -b1;
    m2[1][2] = b1;
    b1 = c.x * c.y;
    m1[2][2] = b1;
    m2[2][2] = b1;
    return m1 * m2;

}

float Hashff(float p) {

    const float cHashM = 43758.54;
    return fract(sin(p) * cHashM);

}

const float txRow = 128.;

vec4 Loadv4(int idVar) {

    float fi;
    fi = float(idVar);
    return texture2D(txBuf, (vec2(mod(fi, txRow), floor(fi / txRow)) + 0.5) / txSize);

}

void Savev4(int idVar, vec4 val, inout vec4 fCol, vec2 fCoord) {

    vec2 d;
    float fi;
    fi = float(idVar);
    d = abs(fCoord - vec2(mod(fi, txRow), floor(fi / txRow)) - 0.5);
    if (max(d.x, d.y) < 0.5) fCol = val;

 }

const float pi = 3.14159;
const int nBall = 144;

vec3 rLead;
float tCur, nStep;

void Step(int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm, out float sz) {

    vec4 p;
    vec3 rmN, vmN, wmN, dr, dv, drw, am, wam;
    float fOvlap, fricN, fricT, fricS, fricSW, fDamp, fAttr, grav, rSep, szN, szAv, fc, ft, ms, drv, dt;
    fOvlap = 1000.;
    fricN = 10.;
    fricS = 0.05;
    fricSW = 10.;
    fricT = 0.5;
    fAttr = 0.02;
    fDamp = 0.01;
    grav = 5.;
    p = Loadv4(4 + 4 * mId);
    rm = p.xyz;
    sz = p.w;
    vm = Loadv4(4 + 4 * mId + 1).xyz;
    qm = Loadv4(4 + 4 * mId + 2);
    wm = Loadv4(4 + 4 * mId + 3).xyz;
    ms = sz * sz * sz;
    am = vec3(0.);
    wam = vec3(0.);
    for (int n = 0; n < nBall; n++) 
    {
        p = Loadv4(4 + 4 * n);
        rmN = p.xyz;
        szN = p.w;
        dr = rm - rmN;
        rSep = length(dr);
        szAv = 0.5 * (sz + szN);
        if (n != mId && rSep < szAv) 
        {
            fc = fOvlap * (szAv / rSep - 1.);
            vmN = Loadv4(4 + 4 * n + 1).xyz;
            wmN = Loadv4(4 + 4 * n + 3).xyz;
            dv = vm - vmN;
            drv = dot(dr, dv) / (rSep * rSep);
            fc = max(fc - fricN * drv, 0.);
            am += fc * dr;
            dv -= drv * dr + cross((sz * wm + szN * wmN) / (sz + szN), dr);
            ft = min(fricT, fricS * abs(fc) * rSep / max(0.001, length(dv)));
            am -= ft * dv;
            wam += (ft / rSep) * cross(dr, dv);
        }
         if (mId / 16 == n / 16) am += 0.5 * fAttr * (rmN - rm);
     }
    szAv = 0.5 * (sz + 1.);
    dr = vec3(0., rm.y, 0.);
    rSep = abs(dr.y);
    if (rSep < szAv) 
    {
        fc = fOvlap * (szAv / rSep - 1.);
        dv = vm;
        drv = dot(dr, dv) / (rSep * rSep);
        fc = max(fc - fricN * drv, 0.);
        am += fc * dr;
        dv -= drv * dr + cross(wm, dr);
        ft = min(fricT, fricSW * abs(fc) * rSep / max(0.001, length(dv)));
        am -= ft * dv;
        wam += (ft / rSep) * cross(dr, dv);
    }
     szAv = 0.5 * (sz + 1.);
    dr = rm;
    dr.xz -= 10. * floor((rm.xz + 5.) / 10.);
    dr = max(abs(dr) - vec3(0.5, 0.75, 0.5), 0.) * sign(dr);
    rSep = length(dr);
    if (rSep < szAv) 
    {
        fc = fOvlap * (szAv / rSep - 1.);
        dv = vm;
        drv = dot(dr, dv) / (rSep * rSep);
        fc = max(fc - fricN * drv, 0.);
        am += fc * dr;
        dv -= drv * dr + cross(wm, dr);
        ft = min(fricT, fricSW * abs(fc) * rSep / max(0.001, length(dv)));
        am -= ft * dv;
        wam += (ft / rSep) * cross(dr, dv);
    }
     am += fAttr * (rLead - rm);
    am.y -= grav * ms;
    am -= fDamp * vm;
    dt = 0.01;
    vm += dt * am / ms;
    rm += dt * vm;
    wm += dt * wam / (0.1 * ms * sz);
    qm = normalize(QtMul(RMatToQt(LpStepMat(0.5 * dt * wm)), qm));

}

void Init(int mId, out vec3 rm, out vec3 vm, out vec4 qm, out vec3 wm, out float sz) {

    vec3 e;
    float mIdf, nbEdge;
    nbEdge = floor(sqrt(float(nBall)) + 0.1);
    mIdf = float(mId);
    rm.xz = floor(vec2(mod(mIdf, nbEdge), mIdf / nbEdge)) - 0.5 * (nbEdge - 1.);
    rm.y = 3.;
    vm = 2. * normalize(vec3(Hashff(mIdf), Hashff(mIdf + tCur + 0.3), Hashff(mIdf + 0.6)) - 0.5);
    e = normalize(vec3(Hashff(mIdf), Hashff(mIdf + 0.3), Hashff(mIdf + 0.6)));
    qm = EulToQt(e);
    wm = vec3(0.);
    sz = 1. - 0.3 * Hashff(mIdf + 0.1);

}

void main() {

    vec4 stDat, p, qm;
    vec3 rm, vm, wm, rMid;
    vec2 iFrag;
    float sz;
    int mId, pxId;
    bool doInit;
    iFrag = floor(vUv);
    pxId = int(iFrag.x + txRow * iFrag.y);
    if (iFrag.x >= txRow || pxId >= 4 * nBall + 4) discard;
     tCur = time;
    if (pxId >= 4) mId = (pxId - 4) / 4;
    else mId = -1;
    doInit = false;
    if (iFrame == 0) {
        rLead = vec3(0., 0., 0.);
        doInit = true;
    } else {
        nStep = Loadv4(0).x;
        ++nStep;
        rLead = Loadv4(1).xyz;
        rLead += 0.7 * vec3(0.03, 0., 0.1);
        if (mId >= 0) Step(mId, rm, vm, qm, wm, sz);
     }
    if (doInit) {

        nStep = 0.;
        if (mId >= 0) Init(mId, rm, vm, qm, wm, sz);

    }
    if (pxId == 2) {

        rMid = vec3(0.);
        for (int n = 0; n < nBall; n++) rMid += Loadv4(4 + 4 * n).xyz;
        rMid /= float(nBall);

    }

    if (pxId == 0) stDat = vec4(nStep, 0., 0., 0.);
    else if (pxId == 1) stDat = vec4(rLead, 0.);
    else if (pxId == 2) stDat = vec4(rMid, 0.);
    else if (pxId == 4 + 4 * mId) p = vec4(rm, sz);
    else if (pxId == 4 + 4 * mId + 1) p = vec4(vm, 0.);
    else if (pxId == 4 + 4 * mId + 2) p = qm;
    else if (pxId == 4 + 4 * mId + 3) p = vec4(wm, 0.);
    Savev4(pxId, ((pxId >= 4) ? p : stDat), gl_FragColor, vUv);

}
