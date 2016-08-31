
// ------------------ channel define
// 1_# bufferFULL_liquidB #_1
// 2_# bufferFULL_liquidC #_2
// 3_# bufferFULL_liquidD #_3
// ------------------

// Track the particles

// iChannel0 = [nothing]
// iChannel1 = Buf B (velocity & position)
// iChannel2 = Buf C (id & colliders)
// iChannel3 = Buf D (inputs)

#define PARTICLE_VELOCITY_MAX   1.5
#define PARTICLE_SPAWN_POSITION iResolution.xy - 12.5

#define CEIL(x) (float (int ((x) + 0.9999))) // To workaround a bug with Firefox on Windows...

bool reset;
vec2 particleIdFound;
float particleVelocity;

float track (in vec2 fragCoord, in vec2 offset) {

    // Get the particle ID and collider
    vec2 cellPosition = fragCoord + offset;
    vec4 data;
    if (reset) {

        // Define the colliders
        float collider = step (fragCoord.x, 5.0);
        collider += step (iResolution.x - 5.0, fragCoord.x);
        collider += step (fragCoord.y, 5.0);
        collider += step (iResolution.y - 5.0, fragCoord.y) * step (0.9 * iResolution.x, fragCoord.x);
        collider += step (length (fragCoord - iResolution.xy * vec2 (0.5, 0.3)), iResolution.y * 0.1);

        // Set the initial data
        data = vec4 (cellPosition, 0.0, collider);
    } else {

        // Get the exisiting data
        data = texture2D (iChannel2, cellPosition / iResolution.xy);
    }
    vec2 particleId = data.rg;
    float collider = data.a;

    // Get the position of this particle
    if (particleId.x > 0.0) {
        data = texture2D (iChannel1, particleId / iResolution.xy);
        vec2 particlePosition = data.ba;

        // Check whether this particle is the one to track
        vec2 delta = floor (particlePosition - fragCoord + 0.5);
        if (delta == vec2 (0.0)) {

            // Take note of the particle ID and its velocity
            particleIdFound = particleId;
            particleVelocity = length (data.rg);
        }
    }

    // Return the collider
    return collider;
}

vec2 rand (in float seed) {
    vec2 n = seed * vec2 (12.9898, 78.233);
    return fract (n.yx * fract (n));
}

float segDist (in vec2 p, in vec2 a, in vec2 b) {
    p -= a;
    b -= a;
    return length (p - b * clamp (dot (p, b) / dot (b, b), 0.0, 1.0));
}

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

    // Initialization
    particleIdFound = vec2 (-1.0);
    particleVelocity = -1.0;
    float collider = 0.0;

    // Check the player inputs
    vec4 data = texture2D (iChannel3, vec2 (0.5) / iResolution.xy);
    reset = iFrame == 0 || data.a > 0.5;

    // Check the current position
    vec2 offset = vec2 (0.0);
    collider = track (fragCoord, offset);

    // Allow to add colliders (removing particles)
    if (iMouse.z > 0.5) {
        float dist;
        if (data.b < 0.5) {
            dist = length (fragCoord - iMouse.xy);
        } else {
            dist = segDist (fragCoord, data.rg, iMouse.xy);
        }
        if (dist < 3.0) {
            collider = texture2D (iChannel3, vec2 (1.5, 0.5) / iResolution.xy).b;
        }
    }
    if (collider < 0.5) {

        // Track the particle (spiral loop from the current position)
        vec2 direction = vec2 (1.0, 0.0);
        for (float n = 1.0; n < (2.0 * CEIL (PARTICLE_VELOCITY_MAX) + 1.0) * (2.0 * CEIL (PARTICLE_VELOCITY_MAX) + 1.0); ++n) {
            if (particleIdFound.x > 0.0) {
                break;
            }
            offset += direction;
            track (fragCoord, offset);
            if (offset.x == offset.y || (offset.x < 0.0 && offset.x == -offset.y) || (offset.x > 0.0 && offset.x == 1.0 - offset.y)) {
                direction = vec2 (-direction.y, direction.x);
            }
        }

        // Spawn a new particle?
        if (particleIdFound.x < 0.0 && fragCoord == floor (PARTICLE_SPAWN_POSITION) + 0.5) {
            vec2 particleId = 0.5 + floor (iResolution.xy * rand (iGlobalTime));
            vec2 particlePosition = texture2D (iChannel1, particleId / iResolution.xy).ba;
            if (particlePosition == fragCoord) {
                particleIdFound = particleId;
            }
        }
    }

    // Update the fragment
    fragColor = vec4 (particleIdFound, particleVelocity, collider);
}