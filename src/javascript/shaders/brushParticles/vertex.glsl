#define STANDARD

// ##############################
// Fragment start
// ##############################
#ifdef PHYSICAL
    #define REFLECTIVITY
    #define CLEARCOAT
    #define TRANSMISSION
#endif

uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;

#ifdef TRANSMISSION
    uniform float transmission;
#endif

#ifdef REFLECTIVITY
    uniform float reflectivity;
#endif

#ifdef CLEARCOAT
    uniform float clearcoat;
    uniform float clearcoatRoughness;
#endif

#ifdef USE_SHEEN
    uniform vec3 sheen;
#endif
// ##############################
// Fragment end
// ##############################

#include <common>

// ##############################
// Fragment start
// ##############################
#define gl_FragColor pc_fragColor
#define gl_FragDepthEXT gl_FragDepth
#define texture2D texture
#define textureCube texture
#define texture2DProj textureProj
#define texture2DLodEXT textureLod
#define texture2DProjLodEXT textureProjLod
#define textureCubeLodEXT textureLod
#define texture2DGradEXT textureGrad
#define texture2DProjGradEXT textureProjGrad
#define textureCubeGradEXT textureGrad
precision highp float;
precision highp int;
#define HIGH_PRECISION
#define SHADER_NAME ShaderMaterial
#define PHYSICAL 
#define USE_POINTS 
#define USE_ENVMAP 
#define ENVMAP_TYPE_CUBE 
#define ALPHATEST 0.1
#define GAMMA_FACTOR 2
#define USE_ENVMAP
#define ENVMAP_TYPE_CUBE
#define ENVMAP_MODE_REFLECTION
#define ENVMAP_BLENDING_NONE
#define PHYSICALLY_CORRECT_LIGHTS
#define TEXTURE_LOD_EXT

#include <encodings_pars_fragment>

vec4 envMapTexelToLinear( vec4 value ) { return sRGBToLinear( value ); }
vec4 linearToOutputTexel( vec4 value ) { return LinearTosRGB( value ); }

#include <packing>
#include <dithering_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <transmissionmap_pars_fragment>
#include <bsdfs>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <lights_pars_begin>
#include <lights_physical_pars_fragment>
#include <shadowmask_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>

// ##############################
// Fragment end
// ##############################

// varying vec3 vViewPosition;

// #ifndef FLAT_SHADED

//     varying vec3 vNormal;

//     #ifdef USE_TANGENT

//         varying vec3 vTangent;
//         varying vec3 vBitangent;

//     #endif

// #endif

#include <uv_pars_vertex>
#include <uv2_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>

// ##############################
// Custom start
// ##############################
uniform float uSize;

attribute float aUvRotation;

varying vec4 vFinalColor;

#ifdef USE_POINTS
    varying float vUvRotation;
#endif
// ##############################
// Custom end
// ##############################

void main() {

    #include <uv_vertex>
    #include <uv2_vertex>
    #include <color_vertex>

    #include <beginnormal_vertex>
    #include <morphnormal_vertex>
    #include <skinbase_vertex>
    #include <skinnormal_vertex>
    #include <defaultnormal_vertex>

    #ifndef FLAT_SHADED // Normal computed with derivatives when FLAT_SHADED

        vec3 vNormal = normalize( transformedNormal );

        #ifdef USE_TANGENT

            vec3 vTangent = normalize( transformedTangent );
            vec3 vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );

        #endif

    #endif

    #include <begin_vertex>
    #include <morphtarget_vertex>
    #include <skinning_vertex>
    #include <displacementmap_vertex>
    #include <project_vertex>
    #include <logdepthbuf_vertex>
    #include <clipping_planes_vertex>

    vec3 vViewPosition = - mvPosition.xyz;

    #include <worldpos_vertex>
    #include <shadowmap_vertex>
    #include <fog_vertex>

    // ##############################
    // Custom start
    // ##############################
    vec4 modelViewPosition = modelViewMatrix * vec4(position, 1.0);
    // gl_Position = projectionMatrix * modelViewPosition;

    #ifdef USE_POINTS
        gl_PointSize = uSize;
        gl_PointSize *= (1.0 / - modelViewPosition.z);

        vUvRotation = aUvRotation;
    #endif
    // ##############################
    // Custom end
    // ##############################

    // ##############################
    // Fragment start
    // ##############################

    #include <clipping_planes_fragment>

    vec4 diffuseColor = vec4( diffuse, opacity );
    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
    vec3 totalEmissiveRadiance = emissive;

    #ifdef TRANSMISSION
        float totalTransmission = transmission;
    #endif

    #include <logdepthbuf_fragment>
    #include <map_fragment>
    #include <color_fragment>
    #include <alphamap_fragment>
    // #include <alphatest_fragment>
    #include <roughnessmap_fragment>
    #include <metalnessmap_fragment>
    #include <normal_fragment_begin>
    #include <normal_fragment_maps>
    #include <clearcoat_normal_fragment_begin>
    #include <clearcoat_normal_fragment_maps>
    #include <emissivemap_fragment>
    #include <transmissionmap_fragment>

    // accumulation
    // Start new implementation of <lights_physical_fragment>
    PhysicalMaterial material;
    material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );

    // Custom TODO
    // vec3 dxy = max( abs( dFdx( geometryNormal ) ), abs( dFdy( geometryNormal ) ) );
    // float geometryRoughness = max( max( geometryNormal.x, geometryNormal.y ), geometryNormal.z );
    
    // Custom fix
    float geometryRoughness = 0.0;

    material.specularRoughness = max( roughnessFactor, 0.0525 );// 0.0525 corresponds to the base mip of a 256 cubemap.
    material.specularRoughness += geometryRoughness;
    material.specularRoughness = min( material.specularRoughness, 1.0 );

    #ifdef REFLECTIVITY

        material.specularColor = mix( vec3( MAXIMUM_SPECULAR_COEFFICIENT * pow2( reflectivity ) ), diffuseColor.rgb, metalnessFactor );

    #else

        material.specularColor = mix( vec3( DEFAULT_SPECULAR_COEFFICIENT ), diffuseColor.rgb, metalnessFactor );

    #endif

    #ifdef CLEARCOAT

        material.clearcoat = clearcoat;
        material.clearcoatRoughness = clearcoatRoughness;

        #ifdef USE_CLEARCOATMAP

            material.clearcoat *= texture2D( clearcoatMap, vUv ).x;

        #endif

        #ifdef USE_CLEARCOAT_ROUGHNESSMAP

            material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vUv ).y;

        #endif

        material.clearcoat = saturate( material.clearcoat ); // Burley clearcoat model
        material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
        material.clearcoatRoughness += geometryRoughness;
        material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );

    #endif

    #ifdef USE_SHEEN

        material.sheenColor = sheen;

    #endif
    // End new implementation of <lights_physical_fragment>
    
    #include <lights_fragment_begin>
    #include <lights_fragment_maps>
    #include <lights_fragment_end>

    // modulation
    #include <aomap_fragment>

    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;

    // this is a stub for the transmission model
    #ifdef TRANSMISSION
        diffuseColor.a *= mix( saturate( 1. - totalTransmission + linearToRelativeLuminance( reflectedLight.directSpecular + reflectedLight.indirectSpecular ) ), 1.0, metalness );
    #endif

    vFinalColor = vec4( outgoingLight, diffuseColor.a );

    // ##############################
    // Fragment end
    // ##############################
}