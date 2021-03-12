#define STANDARD

#include <fog_pars_fragment>

varying vec4 vFinalColor;

#ifdef USE_POINTS
    uniform sampler2D uBrushTexture;

    varying float vUvRotation;

    vec2 rotateUV(vec2 uv, float rotation)
    {
        float mid = 0.5;
        return vec2(
            cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
            cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
        );
    }
#endif

void main() {

    // Brush texture
    #ifdef USE_POINTS
        vec2 pointUv = rotateUV(gl_PointCoord, vUvRotation);
        float brushStrength = texture2D(uBrushTexture, pointUv).r;

        if(brushStrength < ALPHATEST)
        {
            discard;
        }
    #endif

    gl_FragColor = vFinalColor;

    #include <encodings_fragment>
    #include <fog_fragment>
    #include <premultiplied_alpha_fragment>
    #include <dithering_fragment>
}