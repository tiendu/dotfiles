// Ghostty 1.3+ — Purple cursor glide
// Save as ~/.config/ghostty/shaders/cursor-trail.glsl
// Ghostty config:
//   custom-shader = ~/.config/ghostty/shaders/cursor-trail.glsl
//   custom-shader-animation = true
//
// A cursor-shaped follower glides toward the real cursor with a faint
// connecting ribbon. The real cursor and underlying terminal are retained.
// Ghostty supplies the uniforms and calls mainImage; do not add #version.

// --- Appearance ---
const float TRAIL_OPACITY = 0.55;
const vec3 TRAIL_COLOR = vec3(0.77647, 0.47059, 0.86667); // #C678DD
const float ELASTIC_STRETCH = 0.14; // Subtle squash/stretch; 0.0 disables it.

// --- Animation ---
const float TRAIL_SECONDS = 0.15;
const float FADE_START = 0.50; // Hold visible through the first half.

// --- Movement limit ---
const float MAX_JUMP_HEIGHTS = 12.0;

float boxDistance(vec2 point, vec2 halfSize) {
    vec2 q = abs(point) - halfSize;
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 base = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = base;

    float age = iTime - iTimeCursorChange;
    if (iCursorVisible == 0 || age < 0.0 || age >= TRAIL_SECONDS) {
        return;
    }

    vec2 size = iCurrentCursor.zw;
    vec2 oldSize = iPreviousCursor.zw;
    if (min(size.x, size.y) <= 0.0 || min(oldSize.x, oldSize.y) <= 0.0) {
        return;
    }

    // Avoid trailing a block cursor into a bar cursor (or vice versa).
    if (length(size - oldSize) > 1.0) {
        return;
    }

    // Cursor coordinates are top-left, with pixel Y increasing upward.
    vec2 current = iCurrentCursor.xy + size * vec2(0.5, -0.5);
    vec2 previous = iPreviousCursor.xy + oldSize * vec2(0.5, -0.5);
    vec2 movement = current - previous;
    float distanceMoved = length(movement);
    float cellExtent = max(size.x, size.y);

    if (distanceMoved < 0.5 ||
        distanceMoved > MAX_JUMP_HEIGHTS * cellExtent) {
        return;
    }

    float progress = clamp(age / TRAIL_SECONDS, 0.0, 1.0);

    // Fast start, gentle arrival — the Neovide-like glide.
    float eased = 1.0 - pow(1.0 - progress, 3.0);
    vec2 follower = mix(previous, current, eased);

    // Subtle elastic deformation while moving, relaxed upon arrival.
    vec2 axis = movement / distanceMoved;
    float moveStrength = smoothstep(
        0.15, 1.75, distanceMoved / max(min(size.x, size.y), 1.0)
    );
    float stretch = ELASTIC_STRETCH * moveStrength
        * (1.0 - smoothstep(0.0, 0.85, progress));
    vec2 scale = vec2(1.0 - 0.20 * stretch)
        + abs(axis) * (1.20 * stretch);
    vec2 halfSize = max(size * 0.5 * scale, vec2(0.75));

    // Solid cursor-shaped follower.
    float followerMask = 1.0 - smoothstep(
        -0.5, 0.75, boxDistance(fragCoord - follower, halfSize)
    );

    // Faint connection from the follower toward the actual cursor.
    vec2 direction = (current - follower) / halfSize;
    vec2 localPoint = (fragCoord - follower) / halfSize;
    float along = clamp(
        dot(localPoint, direction) / max(dot(direction, direction), 0.0001),
        0.0, 1.0
    );
    float radius = mix(0.35, 0.65, along);
    float ribbonMask = 1.0 - smoothstep(
        radius, radius + 0.25,
        length(localPoint - along * direction)
    );
    float mask = max(followerMask, ribbonMask * 0.35);

    // Never paint over the real cursor.
    float outsideCursor = smoothstep(
        0.0, 1.0, boxDistance(fragCoord - current, size * 0.5)
    );

    // Hold the ghost cursor longer, then fade smoothly.
    float fade = 1.0 - smoothstep(FADE_START, 1.0, progress);
    float alpha = clamp(
        mask * outsideCursor * fade * TRAIL_OPACITY, 0.0, 1.0
    );

    // Preserve terminal transparency and unmodified pixels outside the trail.
    fragColor = vec4(
        TRAIL_COLOR * alpha + base.rgb * (1.0 - alpha),
        alpha + base.a * (1.0 - alpha)
    );
}
