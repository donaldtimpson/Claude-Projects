#include <metal_stdlib>
using namespace metal;

// Displacement shaders for the "living painting" — they warp the REAL painted pixels over time,
// so water actually ripples and smoke actually billows (instead of drawn-on dots).

// Water ripple: for each destination pixel, sample the source at a position pushed by crossing
// sine waves. Small amplitude → a gentle, continuous shimmer over the painted sea.
[[ stitchable ]] float2 waterRipple(float2 pos, float time) {
    float2 p = pos;
    p.x += sin(pos.y * 0.055 + time * 0.42) * 1.7
         + sin(pos.y * 0.130 - time * 0.60) * 0.9;
    p.y += sin(pos.x * 0.050 + time * 0.34) * 1.1
         + cos(pos.y * 0.090 + time * 0.50) * 0.6;
    return p;
}

// Smoke billow: mostly-upward flowing displacement with sideways sway, amplitude growing with
// height above the crater (passed as anchorY) so it rises and disperses like real smoke.
[[ stitchable ]] float2 smokeBillow(float2 pos, float time, float anchorY) {
    float rise = clamp((anchorY - pos.y) / 42.0, 0.0, 1.0);   // 0 at crater, 1 a little way up
    float2 p = pos;
    p.x += (sin(pos.y * 0.12 + time * 0.8) * 6.0 + sin(pos.y * 0.05 - time * 0.5) * 3.5) * rise;
    p.y += (-4.0 - sin(pos.x * 0.16 + time * 0.93) * 2.5) * rise;  // net upward flow, ~1/3 speed
    return p;
}
