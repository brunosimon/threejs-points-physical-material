#define STANDARD

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

varying vec3 vViewPosition;

#ifndef FLAT_SHADED

    varying vec3 vNormal;

    #ifdef USE_TANGENT

        varying vec3 vTangent;
        varying vec3 vBitangent;

    #endif

#endif

#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <uv2_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <transmissionmap_pars_fragment>
#include <bsdfs>
#include <cube_uv_reflection_fragment>
#ifdef USE_ENVMAP

	uniform float envMapIntensity;
	uniform float flipEnvMap;
	uniform int maxMipLevel;

	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif
#if defined( USE_ENVMAP )

	#ifdef ENVMAP_MODE_REFRACTION
		uniform float refractionRatio;
	#endif

	vec3 getLightProbeIndirectIrradiance( /*const in SpecularLightProbe specularLightProbe,*/ const in GeometricContext geometry, const in int maxMIPLevel ) {

		vec3 worldNormal = inverseTransformDirection( geometry.normal, viewMatrix );

		#ifdef ENVMAP_TYPE_CUBE

			vec3 queryVec = vec3( flipEnvMap * worldNormal.x, worldNormal.yz );

			// TODO: replace with properly filtered cubemaps and access the irradiance LOD level, be it the last LOD level
			// of a specular cubemap, or just the default level of a specially created irradiance cubemap.

			#ifdef TEXTURE_LOD_EXT

				vec4 envMapColor = textureCubeLodEXT( envMap, queryVec, float( maxMIPLevel ) );

			#else

				// force the bias high to get the last LOD level as it is the most blurred.
				vec4 envMapColor = textureCube( envMap, queryVec, float( maxMIPLevel ) );

			#endif

			envMapColor.rgb = envMapTexelToLinear( envMapColor ).rgb;

		#elif defined( ENVMAP_TYPE_CUBE_UV )

			vec4 envMapColor = textureCubeUV( envMap, worldNormal, 1.0 );

		#else

			vec4 envMapColor = vec4( 0.0 );

		#endif

		return PI * envMapColor.rgb * envMapIntensity;

	}

	// Trowbridge-Reitz distribution to Mip level, following the logic of http://casual-effects.blogspot.ca/2011/08/plausible-environment-lighting-in-two.html
	float getSpecularMIPLevel( const in float roughness, const in int maxMIPLevel ) {

		float maxMIPLevelScalar = float( maxMIPLevel );

		float sigma = PI * roughness * roughness / ( 1.0 + roughness );
		float desiredMIPLevel = maxMIPLevelScalar + log2( sigma );

		// clamp to allowable LOD ranges.
		return clamp( desiredMIPLevel, 0.0, maxMIPLevelScalar );

	}

	vec3 getLightProbeIndirectRadiance( /*const in SpecularLightProbe specularLightProbe,*/ const in vec3 viewDir, const in vec3 normal, const in float roughness, const in int maxMIPLevel ) {

		#ifdef ENVMAP_MODE_REFLECTION

			vec3 reflectVec = reflect( -viewDir, normal );

			// Mixing the reflection with the normal is more accurate and keeps rough objects from gathering light from behind their tangent plane.
			reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );

		#else

			vec3 reflectVec = refract( -viewDir, normal, refractionRatio );

		#endif

		reflectVec = inverseTransformDirection( reflectVec, viewMatrix );

		float specularMIPLevel = getSpecularMIPLevel( roughness, maxMIPLevel );

		#ifdef ENVMAP_TYPE_CUBE

			vec3 queryReflectVec = vec3( flipEnvMap * reflectVec.x, reflectVec.yz );

			#ifdef TEXTURE_LOD_EXT

				vec4 envMapColor = textureCubeLodEXT( envMap, queryReflectVec, specularMIPLevel );

			#else

				vec4 envMapColor = textureCube( envMap, queryReflectVec, specularMIPLevel );

			#endif

			envMapColor.rgb = envMapTexelToLinear( envMapColor ).rgb;

		#elif defined( ENVMAP_TYPE_CUBE_UV )

			vec4 envMapColor = textureCubeUV( envMap, reflectVec, roughness );

		#endif

		return envMapColor.rgb * envMapIntensity;

	}

#endif
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <lights_physical_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>

#ifdef USE_POINTS
    uniform sampler2D uBrushTexture;

    varying vec4 vFinalColor;
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

    #ifdef USE_CLEARCOATMAP

        uniform sampler2D clearcoatMap;

    #endif

    #ifdef USE_CLEARCOAT_ROUGHNESSMAP

        uniform sampler2D clearcoatRoughnessMap;

    #endif

    #ifdef USE_CLEARCOAT_NORMALMAP

        uniform sampler2D clearcoatNormalMap;
        uniform vec2 clearcoatNormalScale;

    #endif

    vec4 diffuseColor = vec4( diffuse, opacity );
    ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
    vec3 totalEmissiveRadiance = emissive;

    #ifdef TRANSMISSION
        float totalTransmission = transmission;
    #endif

    #if defined( USE_LOGDEPTHBUF ) && defined( USE_LOGDEPTHBUF_EXT )

        // Doing a strict comparison with == 1.0 can cause noise artifacts
        // on some platforms. See issue #17623.
        gl_FragDepthEXT = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;

    #endif

    #ifdef USE_MAP

        vec4 texelColor = texture2D( map, vUv );

        texelColor = mapTexelToLinear( texelColor );
        diffuseColor *= texelColor;

    #endif

    #ifdef USE_COLOR

        diffuseColor.rgb *= vColor;

    #endif

    #ifdef USE_ALPHAMAP

        diffuseColor.a *= texture2D( alphaMap, vUv ).g;

    #endif

    // Brush
    #ifdef USE_POINTS
        vec2 pointUv = rotateUV(gl_PointCoord, vUvRotation);
        float brushStrength = texture2D(uBrushTexture, pointUv).r;

        // diffuseColor.rgb -= 1.0 - brushStrength;

        if(brushStrength < ALPHATEST)
        {
            discard;
        }
        // diffuseColor.a *= brushStrength;
        // gl_FragColor = vec4(gl_PointCoord, 1.0, 1.0);
    #endif

    #ifdef ALPHATEST

        if ( diffuseColor.a < ALPHATEST ) discard;

    #endif

    float roughnessFactor = roughness;

    #ifdef USE_ROUGHNESSMAP

        vec4 texelRoughness = texture2D( roughnessMap, vUv );

        // reads channel G, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
        roughnessFactor *= texelRoughness.g;

    #endif
        
    float metalnessFactor = metalness;

    #ifdef USE_METALNESSMAP

        vec4 texelMetalness = texture2D( metalnessMap, vUv );

        // reads channel B, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
        metalnessFactor *= texelMetalness.b;

    #endif
    #ifdef FLAT_SHADED

        // Workaround for Adreno/Nexus5 not able able to do dFdx( vViewPosition ) ...

        vec3 fdx = vec3( dFdx( vViewPosition.x ), dFdx( vViewPosition.y ), dFdx( vViewPosition.z ) );
        vec3 fdy = vec3( dFdy( vViewPosition.x ), dFdy( vViewPosition.y ), dFdy( vViewPosition.z ) );
        vec3 normal = normalize( cross( fdx, fdy ) );

    #else

        vec3 normal = normalize( vNormal );

        #ifdef DOUBLE_SIDED

            normal = normal * ( float( gl_FrontFacing ) * 2.0 - 1.0 );

        #endif

        #ifdef USE_TANGENT

            vec3 tangent = normalize( vTangent );
            vec3 bitangent = normalize( vBitangent );

            #ifdef DOUBLE_SIDED

                tangent = tangent * ( float( gl_FrontFacing ) * 2.0 - 1.0 );
                bitangent = bitangent * ( float( gl_FrontFacing ) * 2.0 - 1.0 );

            #endif

            #if defined( TANGENTSPACE_NORMALMAP ) || defined( USE_CLEARCOAT_NORMALMAP )

                mat3 vTBN = mat3( tangent, bitangent, normal );

            #endif

        #endif

    #endif

    // non perturbed normal for clearcoat among others

    vec3 geometryNormal = normal;

    #ifdef OBJECTSPACE_NORMALMAP

        normal = texture2D( normalMap, vUv ).xyz * 2.0 - 1.0; // overrides both flatShading and attribute normals

        #ifdef FLIP_SIDED

            normal = - normal;

        #endif

        #ifdef DOUBLE_SIDED

            normal = normal * ( float( gl_FrontFacing ) * 2.0 - 1.0 );

        #endif

        normal = normalize( normalMatrix * normal );

    #elif defined( TANGENTSPACE_NORMALMAP )

        vec3 mapN = texture2D( normalMap, vUv ).xyz * 2.0 - 1.0;
        mapN.xy *= normalScale;

        #ifdef USE_TANGENT

            normal = normalize( vTBN * mapN );

        #else

            normal = perturbNormal2Arb( -vViewPosition, normal, mapN );

        #endif

    #elif defined( USE_BUMPMAP )

        normal = perturbNormalArb( -vViewPosition, normal, dHdxy_fwd() );

    #endif

    #ifdef CLEARCOAT

        vec3 clearcoatNormal = geometryNormal;

    #endif

    #ifdef USE_CLEARCOAT_NORMALMAP

        vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vUv ).xyz * 2.0 - 1.0;
        clearcoatMapN.xy *= clearcoatNormalScale;

        #ifdef USE_TANGENT

            clearcoatNormal = normalize( vTBN * clearcoatMapN );

        #else

            clearcoatNormal = perturbNormal2Arb( - vViewPosition, clearcoatNormal, clearcoatMapN );

        #endif

    #endif
    
    #ifdef USE_EMISSIVEMAP

        vec4 emissiveColor = texture2D( emissiveMap, vUv );

        emissiveColor.rgb = emissiveMapTexelToLinear( emissiveColor ).rgb;

        totalEmissiveRadiance *= emissiveColor.rgb;

    #endif

    #ifdef USE_TRANSMISSIONMAP

        totalTransmission *= texture2D( transmissionMap, vUv ).r;

    #endif

    // accumulation
    PhysicalMaterial material;
    material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );

    vec3 dxy = max( abs( dFdx( geometryNormal ) ), abs( dFdy( geometryNormal ) ) );
    float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );

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
    
    /**
    * This is a template that can be used to light a material, it uses pluggable
    * RenderEquations (RE)for specific lighting scenarios.
    *
    * Instructions for use:
    * - Ensure that both RE_Direct, RE_IndirectDiffuse and RE_IndirectSpecular are defined
    * - If you have defined an RE_IndirectSpecular, you need to also provide a Material_LightProbeLOD. <---- ???
    * - Create a material parameter that is to be passed as the third parameter to your lighting functions.
    *
    * TODO:
    * - Add area light support.
    * - Add sphere light support.
    * - Add diffuse light probe (irradiance cubemap) support.
    */

    GeometricContext geometry;

    geometry.position = - vViewPosition;
    geometry.normal = normal;
    geometry.viewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );

    #ifdef CLEARCOAT

        geometry.clearcoatNormal = clearcoatNormal;

    #endif

    IncidentLight directLight;

    #if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )

        PointLight pointLight;
        #if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
        PointLightShadow pointLightShadow;
        #endif

        #pragma unroll_loop_start
        for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {

            pointLight = pointLights[ i ];

            getPointDirectLightIrradiance( pointLight, geometry, directLight );

            #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
            pointLightShadow = pointLightShadows[ i ];
            directLight.color *= all( bvec2( directLight.visible, receiveShadow ) ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
            #endif

            RE_Direct( directLight, geometry, material, reflectedLight );

        }
        #pragma unroll_loop_end

    #endif

    #if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )

        SpotLight spotLight;
        #if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
        SpotLightShadow spotLightShadow;
        #endif

        #pragma unroll_loop_start
        for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {

            spotLight = spotLights[ i ];

            getSpotDirectLightIrradiance( spotLight, geometry, directLight );

            #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
            spotLightShadow = spotLightShadows[ i ];
            directLight.color *= all( bvec2( directLight.visible, receiveShadow ) ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotShadowCoord[ i ] ) : 1.0;
            #endif

            RE_Direct( directLight, geometry, material, reflectedLight );

        }
        #pragma unroll_loop_end

    #endif

    #if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )

        DirectionalLight directionalLight;
        #if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
        DirectionalLightShadow directionalLightShadow;
        #endif

        #pragma unroll_loop_start
        for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {

            directionalLight = directionalLights[ i ];

            getDirectionalDirectLightIrradiance( directionalLight, geometry, directLight );

            #if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
            directionalLightShadow = directionalLightShadows[ i ];
            directLight.color *= all( bvec2( directLight.visible, receiveShadow ) ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
            #endif

            RE_Direct( directLight, geometry, material, reflectedLight );

        }
        #pragma unroll_loop_end

    #endif

    #if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )

        RectAreaLight rectAreaLight;

        #pragma unroll_loop_start
        for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {

            rectAreaLight = rectAreaLights[ i ];
            RE_Direct_RectArea( rectAreaLight, geometry, material, reflectedLight );

        }
        #pragma unroll_loop_end

    #endif

    #if defined( RE_IndirectDiffuse )

        vec3 iblIrradiance = vec3( 0.0 );

        vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );

        irradiance += getLightProbeIrradiance( lightProbe, geometry );

        #if ( NUM_HEMI_LIGHTS > 0 )

            #pragma unroll_loop_start
            for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {

                irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometry );

            }
            #pragma unroll_loop_end

        #endif

    #endif

    #if defined( RE_IndirectSpecular )

        vec3 radiance = vec3( 0.0 );
        vec3 clearcoatRadiance = vec3( 0.0 );

    #endif
    
    #if defined( RE_IndirectDiffuse )

        #ifdef USE_LIGHTMAP

            vec4 lightMapTexel= texture2D( lightMap, vUv2 );
            vec3 lightMapIrradiance = lightMapTexelToLinear( lightMapTexel ).rgb * lightMapIntensity;

            #ifndef PHYSICALLY_CORRECT_LIGHTS

                lightMapIrradiance *= PI; // factor of PI should not be present; included here to prevent breakage

            #endif

            irradiance += lightMapIrradiance;

        #endif

        #if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )

            iblIrradiance += getLightProbeIndirectIrradiance( /*lightProbe,*/ geometry, maxMipLevel );

        #endif

    #endif

    #if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )

        radiance += getLightProbeIndirectRadiance( /*specularLightProbe,*/ geometry.viewDir, geometry.normal, material.specularRoughness, maxMipLevel );

        #ifdef CLEARCOAT

            clearcoatRadiance += getLightProbeIndirectRadiance( /*specularLightProbe,*/ geometry.viewDir, geometry.clearcoatNormal, material.clearcoatRoughness, maxMipLevel );

        #endif

    #endif
    #if defined( RE_IndirectDiffuse )

        RE_IndirectDiffuse( irradiance, geometry, material, reflectedLight );

    #endif

    #if defined( RE_IndirectSpecular )

        RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometry, material, reflectedLight );

    #endif

    // modulation
    #ifdef USE_AOMAP

        // reads channel R, compatible with a combined OcclusionRoughnessMetallic (RGB) texture
        float ambientOcclusion = ( texture2D( aoMap, vUv2 ).r - 1.0 ) * aoMapIntensity + 1.0;

        reflectedLight.indirectDiffuse *= ambientOcclusion;

        #if defined( USE_ENVMAP ) && defined( STANDARD )

            float dotNV = saturate( dot( geometry.normal, geometry.viewDir ) );

            reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.specularRoughness );

        #endif

    #endif

    vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;

    // this is a stub for the transmission model
    #ifdef TRANSMISSION
        diffuseColor.a *= mix( saturate( 1. - totalTransmission + linearToRelativeLuminance( reflectedLight.directSpecular + reflectedLight.indirectSpecular ) ), 1.0, metalness );
    #endif

    gl_FragColor = vec4( outgoingLight, diffuseColor.a );

    #if defined( TONE_MAPPING )

        gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );

    #endif

    // Don't touch from here
    #include <encodings_fragment>
    #include <fog_fragment>
    #include <premultiplied_alpha_fragment>
    #include <dithering_fragment>
}