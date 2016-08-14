// ------------------ channel define
// 0_# noise #_0
// 1_# grey1 #_1
// ------------------
//https://www.shadertoy.com/view/Xlc3zl

#define DISTANCE_THRESHOLD 0.005
#define GRADIENT_STEP 0.01
#define MIN_STEP_SIZE 0.01
#define FAR_CLIP 200.0
#define PI 3.14159265359
#define INF 1.21

int id = 0;
int glassId = 0;

/* Rotations */

void rX(inout vec3 p, float a) {
    float c;
    float s;
    vec3 q = p;
    c = cos(a);
    s = sin(a);
    p.y = c * q.y - s * q.z;
    p.z = s * q.y + c * q.z;
}

void rY(inout vec3 p, float a) {
    float c;
    float s;
    vec3 q = p;
    c = cos(a);
    s = sin(a);
    p.x = c * q.x + s * q.z;
    p.z = -s * q.x + c * q.z;
}

void rZ(inout vec3 p, float a) {
    float c;
    float s;
    vec3 q = p;
    c = cos(a);
    s = sin(a);
    p.x = c * q.x - s * q.y;
    p.y = s * q.x + c * q.y;
}

/* Distance Functions */

float sdBox(vec3 rp, vec3 box) {
    vec3 d = abs(rp) - box;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdOffsetBox(vec3 rp, vec3 box, vec3 bp) {
    vec3 d = abs(rp - bp) - box;   
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float sdCross(vec3 rp) {
    float da = sdBox(rp.xyz, vec3(INF, 1.0, 1.0));
    float db = sdBox(rp.yzx, vec3(1.0, INF, 1.0));
    float dc = sdBox(rp.zxy, vec3(1.0, 1.0, INF));
    return min(da, min(db, dc));
}

float sdFrame(vec3 rp) {
    return max(sdBox(rp, vec3(1.2)), -sdCross(rp));
}

float sdRotatedFrame(vec3 rp) {
    rX(rp, iGlobalTime);
    rY(rp, iGlobalTime);
    return max(sdBox(rp, vec3(1.2)), -sdCross(rp));
}

float sdPlane(vec3 rp) {
    return rp.y + 3.;    
}

float dfScene(vec3 rp) {
    id = 0;
    float msd = sdPlane(rp);
    if (msd < DISTANCE_THRESHOLD) {
        id = 1;    
    }
    rX(rp, iGlobalTime);
    rY(rp, iGlobalTime);
    return min(msd, sdFrame(rp));
}

float dfLight(vec3 rp) {
    glassId = 0;
    rX(rp, iGlobalTime);
    rY(rp, iGlobalTime);
    float msd1 = sdOffsetBox(rp, vec3(0.02, 1., 1.), vec3(1.1, 0., 0.));
    if (msd1 < DISTANCE_THRESHOLD) {
        glassId = 1;        
    }
    float msd2 = sdOffsetBox(rp, vec3(0.02, 1., 1.), vec3(-1.1, 0., 0.));
    if (msd2 < DISTANCE_THRESHOLD) {
        glassId = 2;        
    }
    float msd3 = sdOffsetBox(rp, vec3(1., 0.02, 1.), vec3(0., 1.1, 0.));
    if (msd3 < DISTANCE_THRESHOLD) {
        glassId = 3;   
    }
    float msd4 = sdOffsetBox(rp, vec3(1., 0.02, 1.), vec3(0., -1.1, 0.));
    if (msd4 < DISTANCE_THRESHOLD) {
        glassId = 4;   
    }
    float msd5 = sdOffsetBox(rp, vec3(1., 1., 0.02), vec3(0., 0., 1.1));
    if (msd5 < DISTANCE_THRESHOLD) {
        glassId = 5;   
    }
    float msd6 = sdOffsetBox(rp, vec3(1., 1., 0.02), vec3(0., 0., -1.1));
    if (msd6 < DISTANCE_THRESHOLD) {
        glassId = 6;   
    }
    float msd = min(msd1, min(msd2, min(msd3, min(msd4, min(msd5, msd6)))));
    return min(msd, sdFrame(rp));    
}

vec3 surfaceNormal(vec3 rp) {
    vec3 dx = vec3(GRADIENT_STEP, 0.0, 0.0);
    vec3 dy = vec3(0.0, GRADIENT_STEP, 0.0);
    vec3 dz = vec3(0.0, 0.0, GRADIENT_STEP);
    return normalize(vec3(dfScene(rp + dx) - dfScene(rp - dx),
                          dfScene(rp + dy) - dfScene(rp - dy),
                          dfScene(rp + dz) - dfScene(rp - dz)));
}

vec3 glassNormal(vec3 rp) {
    vec3 dx = vec3(GRADIENT_STEP, 0.0, 0.0);
    vec3 dy = vec3(0.0, GRADIENT_STEP, 0.0);
    vec3 dz = vec3(0.0, 0.0, GRADIENT_STEP);
    return normalize(vec3(dfLight(rp + dx) - dfLight(rp - dx),
                          dfLight(rp + dy) - dfLight(rp - dy),
                          dfLight(rp + dz) - dfLight(rp - dz)));
}

/* Lighting */

vec4 applyFog(in vec4  rgb, in float distance) {
    float b = 0.05;
    float fogAmount = 1.0 - exp(-distance * b);
    vec4  fogColor  = vec4(0.1, 0.1, 0.1, 1.0);
    return mix(rgb, fogColor, fogAmount);
}

// Create a checkboard texture
vec4 checkerTexture(vec3 rp) {
    vec2 m = mod(rp.xz, 4.0) - vec2(2.0);
    return m.x * m.y > 0.0 ? vec4(0.1) : vec4(1.0);
}

vec4 lighting(vec3 rp, vec3 n) {
 
    vec4 pc = vec4(0.); //pixel colour
    float ld = distance(vec3(0.), rp); //distance to light at origin
    vec3 la = normalize(vec3(0.0) - rp); //ray direction to light
    float d = 0.; //distance marched
    vec4 gc = vec4(0.); //glass colour
    //float f = 1.0; // IQ - soft shadow
    //float k = 8.0;
    
    for (int i = 0; i < 50; i++) {
        
        vec3 lrp = rp + la * d; //light ray position
        float ns = dfLight(lrp); //nearest surface to frame and glass(pass-through)
        //float nsf = sdRotatedFrame(lrp);
        d += max(ns, MIN_STEP_SIZE);; 
    
        if (ns < DISTANCE_THRESHOLD) {
            //march through glass
            //we only want the colour of the glass
            if (glassId == 1) {
                gc = vec4(1.0, 0.0, 0.0, 1.0);
            } else if (glassId == 2) {
                gc = vec4(0.0, 1.0, 0.0, 1.0);
            } else if (glassId == 3) {
                gc = vec4(0.0, 0.0, 1.0, 1.0);
            } else if (glassId == 4) { 
                gc = vec4(1.0, 1.0, 0.0, 1.0);
            } else if (glassId == 5) {
                gc = vec4(0.0, 1.0, 1.0, 1.0);
            } else if (glassId == 6) {
                gc = vec4(1.0, 0.0, 1.0, 1.0);
            } else {
                //hit frame
                //f = 0.0;
            }
        }
        
        if (d >= ld) {
            ////light hit floor
            //don't think I have this quite right :(
            pc = gc / ld * ld * 1.5; //inverse square
            pc = pc * dot(n, la); 
            //wnated to do penumbra stuff but couldn't get it right :(
            /*
            if (f > 0.0) {
            }
            */
            break;
        }
        
        //f = min(f, k * nsf / d);
    }
    
    return pc;
}

/* Ray Marching */

vec4 marchGlassRay(vec3 ro, vec3 rd) {
 
    vec4 pc = vec4(0.); //pixel colour
    float d = 0.0; //depth marched
    
    for (int i = 0; i < 50; i ++) {
        vec3 rp = ro + rd * d;
        float h = dfLight(rp); 
        d += max(h, MIN_STEP_SIZE);

        if (h < DISTANCE_THRESHOLD) {

            //hit frame - bail out
            if (glassId == 0) break;

            //colour of the glass
            if (length(pc) == 0.) {
                //front face
                if (glassId == 1) {
                    pc = vec4(1.0, 0.0, 0.0, 1.0);
                } else if (glassId == 2) {
                    pc = vec4(0.0, 1.0, 0.0, 1.0);
                } else if (glassId == 3) {
                    pc = vec4(0.0, 0.0, 1.0, 1.0);
                } else if (glassId == 4) { 
                    pc = vec4(1.0, 1.0, 0.0, 1.0);
                } else if (glassId == 5) {
                    pc = vec4(0.0, 1.0, 1.0, 1.0);
                } else if (glassId == 6) {
                    pc = vec4(1.0, 0.0, 1.0, 1.0);
                }
                
                vec3 n = glassNormal(rp);
                
                //Diffuse and specular lighting stolen from Shane.
                vec3 light = vec3(3.0);
                light -= rp; // Light to surface vector. Ie: Light direction vector.
                float dl = max(length(light), 0.001); // Light to surface distance.
                light /= dl; // Normalizing the light direction vector.
                pc.xyz += vec3(1.) * (dl * .01 + .2); // Applying the shading to the final color.
                
                float df = max(dot(light, n), 0.); // Diffuse.
                float sp = pow(max(dot(reflect(-light, n), -rd), 0.), 32.); // Specular.
                //Applying some diffuse and specular lighting to the surface.
                pc.xyz = pc.xyz * (df + .75) + pc.xyz * sp;        
            } else {
                //rear face
                if (glassId == 1) {
                    pc = mix(pc, vec4(1.0, 0.0, 0.0, 1.0), 0.03);
                } else if (glassId == 2) {
                    pc = mix(pc, vec4(0.0, 1.0, 0.0, 1.0), 0.03);
                } else if (glassId == 3) {
                    pc = mix(pc, vec4(0.0, 0.0, 1.0, 1.0), 0.03);
                } else if (glassId == 4) { 
                    pc = mix(pc, vec4(1.0, 1.0, 0.0, 1.0), 0.03);
                } else if (glassId == 5) {
                    pc = mix(pc, vec4(0.0, 1.0, 1.0, 1.0), 0.03);
                } else if (glassId == 6) {
                    pc = mix(pc, vec4(1.0, 0.0, 1.0, 1.0), 0.03);
                }
            }
        }
        
        if ( d > FAR_CLIP) {
            break;   
        }
    }
    
    return pc;
}

//march a single ray into main scene
vec4 marchSceneRay(vec3 ro, vec3 rd) {

    vec4 pc = vec4(0.); //pixel colour
    float d = 0.0; //distance marched
    
    for (int i = 0; i < 200; ++i) {
        
        vec3 rp = ro + rd * d; //ray position
        float ns = dfScene(rp); //nearest surface
        d += ns;
        
        if (ns < DISTANCE_THRESHOLD) {
            
            //hit surface
            rp = ro + rd * d;
            vec3 n = surfaceNormal(rp);    
            
            vec4 ilc = lighting(rp, n);
            
            if (id == 1) {
                //floor
                pc = checkerTexture(rp);
                pc = applyFog(pc, d);
                //pc = ilc;
                pc = mix(pc, ilc, 0.65);
            } else {
                //frame
                //Diffuse and specular lighting stolen from Shane.
                vec3 light = vec3(3.0);
                light -= rp; // Light to surface vector. Ie: Light direction vector.
                d = max(length(light), 0.001); // Light to surface distance.
                light /= d; // Normalizing the light direction vector.
                pc.xyz = vec3(1.) * (d * .01 + .2); // Applying the shading to the final color.
                float df = max(dot(light, n), 0.); // Diffuse.
                float sp = pow(max(dot(reflect(-light, n), -rd), 0.), 32.); // Specular.
                //Applying some diffuse and specular lighting to the surface.
                pc.xyz = pc.xyz * (df + .75) + vec3(1, .97, .92) * sp;        
            }
            
            break;
        }
        
        if (d > FAR_CLIP) {
            //miss as we've gone past rear clip
            break;
        }
    }
    
    return pc;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;
    
    //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0, 0, -5.5);
    
    //rotate camera
    rY(ro, iGlobalTime);
    rY(rd, iGlobalTime);
    //rY(ro, cos(iGlobalTime));
    //rY(rd, cos(iGlobalTime));
    //rZ(ro, sin(iGlobalTime));
    //rZ(rd, sin(iGlobalTime));

    //ray marching
    vec4 sceneColour = marchSceneRay(ro, rd);
    vec4 glassColour = marchGlassRay(ro, rd);
    
    //fragColor = glassColour;
    fragColor = mix(sceneColour, glassColour, 0.5);;
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
