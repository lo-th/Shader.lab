
// ------------------ channel define
// 0_# bufferFULL_liquidA #_0
// 1_# bufferFULL_liquidB #_1
// 2_# bufferFULL_liquidC #_2
// 3_# bufferFULL_liquidD #_3
// ------------------


// Update the velocity and position of each particle

// iChannel0 = Buf A (density)
// iChannel1 = Buf B (velocity & position)
// iChannel2 = Buf C (id & colliders)
// iChannel3 = Buf D (inputs)

#define GRAVITY_NORM                100.0
#define PARTICLE_RADIUS             2.5
#define PARTICLE_PRESSURE_FACTOR    3000.0
#define PARTICLE_VISCOSITY_FACTOR   4.0
#define PARTICLE_VELOCITY_MAX       1.5
#define PARTICLE_SPAWN_VELOCITY     vec2 (-200.0, 0.0)
#define PARTICLE_SPAWN_POSITION     iResolution.xy - 12.5
#define COLLIDER_RADIUS             0.75
#define COLLIDER_SPRING_STIFFNESS   4000.0
#define COLLIDER_SPRING_DAMPING     4.0
#define TIME_STEP_MAX               0.02
#define SQRT3                       1.732

#define CEIL(x) (float (int ((x) + 0.9999))) // To workaround a bug with Firefox on Windows...
#define MAX(x,y) ((x) > (y) ? (x) : (y))

float particleDensity;
float particleDensityFactor;
vec2 particleAcceleration;
vec2 particleVelocity;
vec2 particlePosition;
vec2 particleIdCheck;

vec2 rand (in vec2 seed) {
    vec2 n = seed * vec2 (12.9898, 78.233);
    return fract (n.yx * fract (n));
}

vec2 rand (in float seed) {
    vec2 n = seed * vec2 (12.9898, 78.233);
    return fract (n.yx * fract (n));
}

void accelerationUpdate (in vec2 offset) {

    // Get the position of the cell
    vec2 cellPosition = floor (particlePosition + offset) + 0.5;

    // Get the particle ID and the collider
    vec4 data = texture2D (iChannel2, cellPosition / iResolution.xy);
    vec2 particleId = data.rg;
    float collider = data.a;

    // Check whether there is a particle here
    if (offset == vec2 (0.0)) {

        // This is the current particle
        particleIdCheck = particleId;
    } else if (particleId.x > 0.0) {

        // Get the position of this other particle
        data = texture2D (iChannel1, particleId / iResolution.xy);
        vec2 otherParticlePosition = data.ba;

        // Compute the distance between these 2 particles
        vec2 direction = otherParticlePosition - particlePosition;
        float dist = length (direction);

        // Check whether these 2 particles touch each other
        if (dist < 2.0 * PARTICLE_RADIUS) {

            // Normalize the direction
            direction /= dist;
            dist /= 2.0 * PARTICLE_RADIUS;

            // Get the velocity and density of this other particle
            vec2 otherParticleVelocity = data.rg;
            data = texture2D (iChannel0, particleId / iResolution.xy);
            float otherParticleDensity = data.r;
            float otherParticleDensityFactor = data.g;

            // Apply the pressure and viscosity forces (SPH)
            float compression = 1.0 - dist;
            float pressure = PARTICLE_PRESSURE_FACTOR * (particleDensityFactor + otherParticleDensityFactor);
            float viscosity = PARTICLE_VISCOSITY_FACTOR * max (0.0, dot (particleVelocity - otherParticleVelocity, direction)) / ((particleDensity + otherParticleDensity) * dist);
            particleAcceleration -= direction * (pressure + viscosity) * 3.0 * compression * compression;
        }
    }

    // Collision with a collider?
    if (collider > 0.5) {

        // Compute the signed distance between the center of the particle (circle) and the border of the collider (square)
        vec2 direction = cellPosition - particlePosition;
        vec2 distCollider = abs (direction) - COLLIDER_RADIUS;
        float dist = length (max (distCollider, 0.0)) + min (max (distCollider.x, distCollider.y), 0.0);

        // Check whether the particle touches the collider
        if (dist < PARTICLE_RADIUS) {

            // Normalize the direction
            direction = sign (direction) * (dist > 0.0 ? distCollider / dist : step (distCollider.yx, distCollider));

            // Apply the collision force (spring)
            float compression = 1.0 - (dist + COLLIDER_RADIUS) / (PARTICLE_RADIUS + COLLIDER_RADIUS);
            particleAcceleration -= direction * (compression * COLLIDER_SPRING_STIFFNESS + dot (particleVelocity, direction) * COLLIDER_SPRING_DAMPING);
        }
    }
}

void mainImage (out vec4 fragColor, in vec2 fragCoord) {

    // Check for a reset
    bool reset = iFrame == 0 || texture2D (iChannel3, vec2 (0.5) / iResolution.xy).a > 0.5;

    // Define the particle data
    if (reset) {

        // Define the particle spawning area
        float liquid =
            step (abs (fragCoord.x - iResolution.x * 0.5), iResolution.x * 0.5 - 5.0 - PARTICLE_RADIUS)
            * step (iResolution.y * 0.5, fragCoord.y)
            * step (fragCoord.y, iResolution.y - 5.0 - PARTICLE_RADIUS)
            * step (mod (fragCoord.x + SQRT3 * fragCoord.y, ceil (2.0 * PARTICLE_RADIUS)), 1.0)
            * step (mod (fragCoord.y, ceil (SQRT3 * PARTICLE_RADIUS)), 1.0);

        // Initialize the particle
        particleVelocity = vec2 (0.0);
        particlePosition = liquid > 0.5 ? fragCoord + 0.01 * rand (fragCoord): vec2 (-1.0);
    } else {

        // Get the particle data
        vec4 data = texture2D (iChannel0, fragCoord / iResolution.xy);
        particleDensity = data.r;
        if (particleDensity > 0.5) {
            particleDensityFactor = data.g;
            data = texture2D (iChannel1, fragCoord / iResolution.xy);
            particleVelocity = data.rg;
            particlePosition = data.ba;

            // Initialize the acceleration
            float gravityDirection = texture2D (iChannel3, vec2 (1.5, 0.5) / iResolution.xy).r;
            particleAcceleration = GRAVITY_NORM * vec2 (cos (gravityDirection), sin (gravityDirection));

            // Check for collisions with nearby particles and colliders
            particleIdCheck = vec2 (-1.0);
            const float collisionRadius = CEIL (PARTICLE_RADIUS + MAX (PARTICLE_RADIUS, COLLIDER_RADIUS));
            for (float i = -collisionRadius; i <= collisionRadius; ++i) {
                for (float j = -collisionRadius; j <= collisionRadius; ++j) {
                    accelerationUpdate (vec2 (i, j));
                }
            }

            // Make sure the particle is still tracked
            if (particleIdCheck != fragCoord) {

                // The particle is lost...
                particlePosition = vec2 (-1.0);
            } else {

                // Limit the time step
                float timeStep = min (iGlobalTime, TIME_STEP_MAX);

                // Update the velocity of the particle
                particleVelocity += particleAcceleration * timeStep;

                // Limit the velocity (to avoid losing track of the particle)
                float dist = length (particleVelocity * timeStep);
                if (dist > PARTICLE_VELOCITY_MAX) {
                    particleVelocity *= PARTICLE_VELOCITY_MAX / dist;
                }

                // Update the position of the particle
                particlePosition += particleVelocity * timeStep;
            }
        } else {

            // Check the particle ID
            vec2 particleId = 0.5 + floor (iResolution.xy * rand (iGlobalTime));
            if (fragCoord == particleId) {

                // Spawn a new particle
                particleVelocity = PARTICLE_SPAWN_VELOCITY;
                particlePosition = floor (PARTICLE_SPAWN_POSITION) + 0.5;
            } else {

                // The particle is lost...
                particlePosition = vec2 (-1.0);
            }
        }
    }

    // Update the fragment
    fragColor = vec4 (particleVelocity, particlePosition);
}