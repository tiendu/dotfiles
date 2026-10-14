// Ghostty 1.3+ : short purple cursor trail.
// Save as ~/.config/ghostty/shaders/cursor-trail.glsl
// Add to your Ghostty config:
//   custom-shader = ~/.config/ghostty/shaders/cursor-trail.glsl
//   custom-shader-animation = true
// Then reload Ghostty's configuration.
// Disable the separate Neovim trail to avoid overlapping effects.
//
// Ghostty supplies all uniforms and calls mainImage; do not add #version.
// The original terminal image and real cursor are retained.
// This shader cannot distinguish shell movement from application redraws.

const float TRAIL_SECONDS = 0.10;  // Increase to 0.15 for a slower glide.
const float TRAIL_OPACITY = 0.45;  // 0..1; lower keeps underlying text clearer.
const float MAX_JUMP_HEIGHTS = 12.0;
const vec3 TRAIL_COLOR = vec3(0.77647, 0.47059, 0.86667); // #C678DD

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
    // Skip cursor shape changes (e.g. block -> bar on entering Insert mode).
    if (length(size - oldSize) > 1.0) {
        return;
    }

    // Cursor coordinates use the top-left corner in a bottom-up pixel grid.
    vec2 current = iCurrentCursor.xy + size * vec2(0.5, -0.5);
    vec2 previous = iPreviousCursor.xy + oldSize * vec2(0.5, -0.5);
    float distanceMoved = length(current - previous);
    float cellExtent = max(size.x, size.y);
    if (distanceMoved < 0.5 || distanceMoved > MAX_JUMP_HEIGHTS * cellExtent) {
        return;
    }

    float progress = clamp(age / TRAIL_SECONDS, 0.0, 1.0);
    float eased = 1.0 - pow(1.0 - progress, 3.0);
    vec2 follower = mix(previous, current, eased);
    vec2 halfSize = max(size * 0.5, vec2(0.75));

    // Gliding cursor-sized follower plus a faint, tapered connection.
    float followerMask = 1.0 - smoothstep(-0.5, 0.75,
        boxDistance(fragCoord - follower, halfSize));
    vec2 direction = (current - follower) / halfSize;
    vec2 localPoint = (fragCoord - follower) / halfSize;
    float along = clamp(dot(localPoint, direction)
        / max(dot(direction, direction), 0.0001), 0.0, 1.0);
    float radius = mix(0.35, 0.65, along);
    float ribbonMask = 1.0 - smoothstep(radius, radius + 0.25,
        length(localPoint - along * direction));
    float mask = max(followerMask, ribbonMask * 0.35);

    // Leave the actual cursor and the character it covers untouched.
    float outsideCursor = smoothstep(0.0, 1.0,
        boxDistance(fragCoord - current, size * 0.5));
    float fade = 1.0 - smoothstep(0.35, 1.0, progress);
    float alpha = clamp(mask * outsideCursor * fade * TRAIL_OPACITY, 0.0, 1.0);

    // Overlay premultiplied color, preserving transparency outside the trail.
    fragColor = vec4(TRAIL_COLOR * alpha + base.rgb * (1.0 - alpha),
                     alpha + base.a * (1.0 - alpha));
}
