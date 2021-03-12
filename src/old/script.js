/**
 * Loaders
 */
const textureLoader = new THREE.TextureLoader()
const cubeTextureLoader = new THREE.CubeTextureLoader()

const doorColorTexture = textureLoader.load('/textures/door/color.jpg')
const doorAlphaTexture = textureLoader.load('/textures/door/alpha.jpg')
const doorAmbientOcclusionTexture = textureLoader.load('/textures/door/ambientOcclusion.jpg')
const doorHeightTexture = textureLoader.load('/textures/door/height.jpg')
const doorNormalTexture = textureLoader.load('/textures/door/normal.jpg')
const doorMetalnessTexture = textureLoader.load('/textures/door/metalness.jpg')
const doorRoughnessTexture = textureLoader.load('/textures/door/roughness.jpg')
const brush1Texture = textureLoader.load('/textures/brushes/brush1.png')
const brush2Texture = textureLoader.load('/textures/brushes/brush2.png')
const brush3Texture = textureLoader.load('/textures/brushes/brush3.png')
const brush4Texture = textureLoader.load('/textures/brushes/brush4.png')

doorColorTexture.encoding = THREE.sRGBEncoding
doorAlphaTexture.encoding = THREE.LinearEncoding
doorAmbientOcclusionTexture.encoding = THREE.LinearEncoding
doorHeightTexture.encoding = THREE.LinearEncoding
doorNormalTexture.encoding = THREE.LinearEncoding
doorMetalnessTexture.encoding = THREE.LinearEncoding
doorRoughnessTexture.encoding = THREE.LinearEncoding

/**
 * Objects
 */
// Geometry
const geometry = new THREE.SphereGeometry(0.5, 20, 20)

const verticesCount = geometry.attributes.position.count

for(let i = 0; i < verticesCount; i++)
{
    geometry.attributes.position.array[i * 3 + 0] += (Math.random() - 0.5) * 0
    geometry.attributes.position.array[i * 3 + 1] += (Math.random() - 0.5) * 0
    geometry.attributes.position.array[i * 3 + 2] += (Math.random() - 0.5) * 0
}

const uvRotation = new Float32Array(verticesCount)
for(let i = 0; i < verticesCount; i++)
{
    uvRotation[i] = Math.random() * Math.PI * 2
}
geometry.setAttribute('aUvRotation', new THREE.BufferAttribute(uvRotation, 1))

geometry.setAttribute('uv2', new THREE.BufferAttribute(geometry.attributes.uv.array, 2))

// Material
debugObject.usePoints = true
debugObject.materialColor = 0x0000ff

const material = new BrushParticlesMaterial({
    // map: doorColorTexture,
    // alphaMap: doorAlphaTexture,
    // aoMap: doorAmbientOcclusionTexture,
    // displacementMap: doorHeightTexture,
    // normalMap: doorNormalTexture,
    // metalnessMap: doorMetalnessTexture,
    // roughnessMap: doorRoughnessTexture,
    color: new THREE.Color(debugObject.materialColor),
    envMap: environmentMap,

    brushTexture: brush3Texture,
    usePoints: debugObject.usePoints
})

const materialFolder = gui.addFolder('material')
materialFolder.open()
materialFolder.add(material.uniforms.uSize, 'value').min(0).max(1000).step(1).name('uSize')
materialFolder.add(material.uniforms.roughness, 'value').min(0).max(1).step(0.001).name('roughness')
materialFolder.add(material.uniforms.metalness, 'value').min(0).max(1).step(0.001).name('metalness')
materialFolder.add(material.uniforms.envMapIntensity, 'value').min(0).max(50).step(0.1).name('envMapIntensity')
materialFolder.addColor(debugObject, 'materialColor').onChange(() =>
{
    material.uniforms.diffuse.value.set(debugObject.materialColor)
})
materialFolder.add(debugObject, 'usePoints').onChange(() =>
{
    
    if(debugObject.usePoints)
    {
        material.defines.USE_POINTS = ''
        material.needsUpdate = true

        scene.remove(sphereMesh)
        scene.add(spherePoints)
    }
    else
    {
        delete material.defines.USE_POINTS
        material.needsUpdate = true

        scene.add(sphereMesh)
        scene.remove(spherePoints)
    }
})

// Points
const spherePoints = new THREE.Points(geometry, material)
scene.add(spherePoints)

// Mesh
const sphereMesh = new THREE.Mesh(geometry, material)
