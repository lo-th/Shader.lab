// ------------------ channel define
// 0_# tex10 #_0
// ------------------

// https://www.shadertoy.com/view/XltGDl

const float MAX_DEPTH = 50.0;


float Rand(vec2 pos) {
    return texture2D(iChannel0, pos / 64.0).r;
}


vec2 Rotate(vec2 pos, float angle) {
    return vec2(
        pos.x * cos(angle) - pos.y * sin(angle),
        pos.x * sin(angle) + pos.y * cos(angle)
    );
}


float BoxDistance(vec3 localPos, vec3 size) {
    vec3 dist = abs(localPos) - 0.5 * size;
    return max(dist.x, max(dist.y, dist.z));
}


float ShapeDistanceAt(vec3 pos, vec2 gridPos) {

    // Start with the underlying plane
    float dMin = pos.y;

    // Randomize sub-shape based on grid pos
    vec3 gridCenter = vec3(gridPos.x + 0.5, 0.5, gridPos.y + 0.5);
    float rand = Rand(gridCenter.xz);

    // ... vanes (2 widths)
    if (rand < 0.2) {
        gridCenter.xy -= vec2(0.4, 0.7);
        pos.x = floor(pos.x) + mod(pos.x, 0.10);
        float width = 0.4;
        if (rand < 0.1) {
            width = 0.8;
        }
        float dBox = BoxDistance(pos - gridCenter, vec3(0.09, 0.8, width));
        dMin = min(dMin, dBox);
    }

    // ... little box
    else if (rand < 0.4) {
        
        gridCenter.y -= 0.35 + 0.4 * (rand - 0.25);
        float dBox = BoxDistance(pos - gridCenter, vec3(0.9, 0.2, 0.6));
        dMin = min(dMin, dBox);

        // ... antenna greebles
        float modStep = 0.5;
        for (int i = 0; i < 3; i++) {
            
            // ... an attempt at randomizing x & z without another rand lookup
            vec3 greeblePos = gridCenter;
            greeblePos.x += 1.0 * ((mod(rand, modStep) / modStep) - 0.5);
            modStep *= 0.5;
            greeblePos.z += 0.5 * ((mod(rand, modStep) / modStep) - 0.5);
            modStep *= 0.5;
            float dGreeble = BoxDistance(pos - greeblePos, vec3(0.04, 1.3, 0.04));
            dMin = min(dMin, dGreeble);
        }
    }

    // ... big flat box
    else if (rand < 0.94) {
        gridCenter.y -= 0.3 + 0.5 * (rand - 0.5);
        float dBox = BoxDistance(pos - gridCenter, vec3(1.0, 0.2, 1.0));
        dMin = min(dMin, dBox);

        // ... box greebles
        float modStep = 0.5;
        for (int i = 0; i < 4; i++) {
            vec3 greeblePos = gridCenter;
            greeblePos.x += 0.65 * ((mod(rand, modStep) / modStep) - 0.5);
            modStep *= 0.5;
            greeblePos.z += 0.65 * ((mod(rand, modStep) / modStep) - 0.5);
            modStep *= 0.5;
            float height = 0.3 + 0.4 * mod(float(i + 1) * rand, modStep) / modStep;
            float dGreeble = BoxDistance(pos - greeblePos, vec3(0.45, height, 0.45));
            dMin = min(dMin, dGreeble);
        }
    }

    // ... sphere
    else {
        gridCenter.y -= 0.95;
        float dSphere = length(pos - gridCenter) - 0.6;
        dMin = min(dMin, dSphere);
    }

    return dMin;
}


// Scene distance function.
float SceneDistance(vec3 pos) {

    // Limit ship height (build up front in steps)
    pos.z += 3.0;
    float height = 1.95 + clamp(floor(-pos.z / 6.0), 0.0, 1.35);
    if (abs(pos.x) > height || pos.z > 0.0) {
        return 10.0;
    }

    // Ignore details until ray gets close
    float objectTopDist = pos.y - 1.0;
    if (objectTopDist > 0.2) {
        return objectTopDist;
    }

    // We're close: check adjacent shapes in view dir
    vec2 gridPos = floor(pos.xz);
    float dist = 
        min(
            min(
                ShapeDistanceAt(pos, gridPos), 
                ShapeDistanceAt(pos, gridPos + vec2(0, 1))
            ),
            min(
                ShapeDistanceAt(pos, gridPos + vec2(1, 0)), 
                ShapeDistanceAt(pos, gridPos + vec2(-1, 0))
            )
        );

    return dist;
}


float RayMarch(vec3 startPos, vec3 dir) {
    float depth = 0.0;
    for (int i = 0; i < 64; i++) {
        vec3 pos = startPos + dir * depth;
        float dist = SceneDistance(pos);
        if (dist < 0.0001) {
            return depth;
        }
        depth += 0.99 * dist;
        if (depth >= MAX_DEPTH) {
            return MAX_DEPTH;
        }
    }
    return MAX_DEPTH;
}


vec3 SceneNormal(vec3 pos) {
    const float DX = 0.02;
    const vec3 dx = vec3(DX, 0.0, 0.0);
    const vec3 dy = vec3(0.0, DX, 0.0);
    const vec3 dz = vec3(0.0, 0.0, DX);
    return normalize(vec3(
        SceneDistance(pos + dx) - SceneDistance(pos - dx),
        SceneDistance(pos + dy) - SceneDistance(pos - dy),
        SceneDistance(pos + dz) - SceneDistance(pos - dz)
    ));
}


void mainImage(out vec4 fragColor, in vec2 fragCoord) {

    // Set up view
    vec3 eyePos = vec3(-0.2, 7.0, -3.0 - 1.5 * iGlobalTime);
    vec2 xy = (2.0 * fragCoord - iResolution.xy) * 0.5;
    vec3 rayDir = normalize(vec3(xy, 1.0 / tan(0.5 * radians(45.0)) * 0.5 * iResolution.y));
    rayDir.xz = Rotate(rayDir.xz, radians(-43.0));
    rayDir.xy = Rotate(rayDir.xy, radians(-90.0));
    
    // Do the raymarch; if we hit...
    float depth = RayMarch(eyePos, rayDir);
    if (depth < MAX_DEPTH) {

        // ... normal 
        vec3 pos = eyePos + rayDir * depth;
        vec3 normal = SceneNormal(pos);

        // ... ambient occlusion
        float ao = 0.0;
        const float AO_STEP = 0.07;
        for (int i = 0; i < 5; i++) {
            float stepDist = float(i) * AO_STEP;
            vec3 aoPos = pos - stepDist * rayDir;
            float aoDist = SceneDistance(aoPos);
            ao += 5.2 * (1.0 / float(i + 1)) * (stepDist - aoDist);
        }
        ao = clamp(1.0 - ao, 0.0, 1.0);

        // ... texturing
        float tex = 0.0;
        float texScale = 1.0;
        for (int i = 0; i < 4; i++) {
            tex += texture2D(iChannel0, pos.xz * texScale * 0.08).r / texScale;
            texScale *= 2.0;
        }
        tex /= 1.5;

        // ... lighting
        vec3 lightDir = normalize(vec3(0.5, 0.8, -0.6));
        float diffuse = clamp(dot(lightDir, normal), 0.0, 1.0) * 1.4;
        vec3 lightViewHalf = normalize(lightDir - rayDir);
        float specular = 0.8 * pow(clamp(dot(normal, lightViewHalf), 0.0, 1.0), 25.0);
        float distanceFade = pow(1.0 - depth / MAX_DEPTH, 2.0);
        float value = (diffuse + specular) *  distanceFade * ao * mix(0.5, 1.0, tex);
        value *= clamp(iGlobalTime * 0.1, 0.0, 1.0);
        fragColor.rgb = value * vec3(0.75, 0.85, 1.0);
    }
    
    // If we didn't hit...
    else {
        
        // ... sky gradient + stars
        vec2 uv = fragCoord / iResolution.y;
        float star = texture2D(iChannel0, Rotate(0.01 * fragCoord, radians(20.0))).r;
        if (star < 0.90) {
            star = 0.0;
        }
        else {
            star = (star - 0.90) * 10.0;
        }
        fragColor.rgb = vec3(0.05, 0.0, 0.15) + star;
        fragColor.rgb *= abs(uv.y - 0.5);
    }
}
