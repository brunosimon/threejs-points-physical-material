import * as THREE from 'three'
import PointsPhysicalMaterial from './Materials/PointsPhysicalMaterial.js'

export default class World
{
    constructor(_options)
    {
        this.application = window.application
        this.scene = this.application.scene
        this.debug = this.application.debug
        this.time = this.application.time

        // Debug
        if(this.debug)
        {
            this.debug.Register({
                type: 'folder',
                label: 'world',
                open: true
            })
        }

        // const mesh = new THREE.Mesh(
        //     new THREE.SphereGeometry(1, 32, 32),
        //     new THREE.MeshStandardMaterial()
        // )
        // this.scene.add(mesh)

        this.setEnvironmentMap()
        this.setLights()
        this.setBrushParticles()
    }

    setEnvironmentMap()
    {
        const cubeTextureLoader = new THREE.CubeTextureLoader()

        this.environmentMap = cubeTextureLoader.load([
            '/textures/environmentMaps/0/px.jpg',
            '/textures/environmentMaps/0/nx.jpg',
            '/textures/environmentMaps/0/py.jpg',
            '/textures/environmentMaps/0/ny.jpg',
            '/textures/environmentMaps/0/pz.jpg',
            '/textures/environmentMaps/0/nz.jpg'
        ])
        
        this.environmentMap.encoding = THREE.sRGBEncoding
    }

    setLights()
    {
        this.lights = {}

        /**
         * Debug
         */
        if(this.debug)
        {
            this.debug.Register({
                type: 'folder',
                folder: 'world',
                label: 'lights',
                open: true
            })
        }

        /**
         * Ambient light
         */
        this.lights.ambientLight = {}
        this.lights.ambientLight.color = '#ff0000'
        this.lights.ambientLight.instance = new THREE.AmbientLight(this.lights.ambientLight.color, 0.2)
        this.scene.add(this.lights.ambientLight.instance)

        // Debug
        if(this.debug)
        {
            this.debug.Register({
                folder: 'lights',
                type: 'range',
                label: 'ambientLightIntensity',
                min: 0,
                max: 1,
                object: this.lights.ambientLight.instance,
                property: 'intensity'
            })

            this.debug.Register({
                type: 'color',
                folder: 'lights',
                label: 'ambientLightColor',
                object: this.lights.ambientLight,
                property: 'color',
                format: 'hex',
                onChange: () =>
                {
                    this.lights.ambientLight.instance.color.set(this.lights.ambientLight.color)
                }
            })
        }

        /**
         * Directional light
         */
        this.lights.directionalLight = {}
        this.lights.directionalLight.color = '#ffffff'
        this.lights.directionalLight.instance = new THREE.DirectionalLight(this.lights.directionalLight.color, 3.5)
        this.scene.add(this.lights.directionalLight.instance)

        // Debug
        if(this.debug)
        {
            this.debug.Register({
                folder: 'lights',
                type: 'range',
                label: 'directionalLightIntensity',
                min: 0,
                max: 10,
                object: this.lights.directionalLight.instance,
                property: 'intensity'
            })

            this.debug.Register({
                type: 'color',
                folder: 'lights',
                label: 'directionalLightColor',
                object: this.lights.directionalLight,
                property: 'color',
                format: 'hex',
                onChange: () =>
                {
                    this.lights.directionalLight.instance.color.set(this.lights.directionalLight.color)
                }
            })
        }
    }

    setBrushParticles()
    {
        this.brushParticles = {}

        /**
         * Use points
         */
        this.brushParticles.usePoints = true

        if(this.debug)
        {
            this.debug.Register({
                folder: 'world',
                type: 'checkbox',
                label: 'usePoints',
                object: this.brushParticles,
                property: 'usePoints',
                onChange: () =>
                {
                    for(const _item of this.brushParticles.items)
                    {
                        if(this.brushParticles.usePoints)
                        {
                            _item.material.defines.USE_POINTS = ''
                            _item.material.needsUpdate = true
            
                            this.scene.remove(_item.mesh)
                            this.scene.add(_item.points)
                        }
                        else
                        {
                            delete _item.material.defines.USE_POINTS
                            _item.material.needsUpdate = true
            
                            this.scene.add(_item.mesh)
                            this.scene.remove(_item.points)
                        }
                    }
                }
            })
        }

        /**
         * Brush texture
         */
        const textureLoader = new THREE.TextureLoader()
        this.brushParticles.brushTexture = textureLoader.load('/textures/brushes/brush3.png')

        // Options
        this.brushParticles.options = [
            { name: 'a', geometry: new THREE.SphereGeometry(0.5, 15, 15), position: new THREE.Vector3(- 2, 0, 0), color: 0x100200, roughness: 0.236, metalness: 1, envMapIntensity: 15 },
            { name: 'b', geometry: new THREE.SphereGeometry(0.5, 15, 15), position: new THREE.Vector3(0, 0, 0), color: 0x224466, roughness: 0.636, metalness: 0, envMapIntensity: 1.7 },
            { name: 'c', geometry: new THREE.SphereGeometry(0.5, 15, 15), position: new THREE.Vector3(2, 0, 0), color: 0x91971f, roughness: 0.563, metalness: 0, envMapIntensity: 1.4 }
        ]

        /**
         * Items
         */
        this.brushParticles.items = []

        for(const _options of this.brushParticles.options)
        {
            const item = {}
            item.options = _options

            /**
             * Geometry
             */
            item.geometry = _options.geometry
            const verticesCount = item.geometry.attributes.position.count

            for(let i = 0; i < verticesCount; i++)
            {
                item.geometry.attributes.position.array[i * 3 + 0] += (Math.random() - 0.5) * 0
                item.geometry.attributes.position.array[i * 3 + 1] += (Math.random() - 0.5) * 0
                item.geometry.attributes.position.array[i * 3 + 2] += (Math.random() - 0.5) * 0
            }

            const uvRotation = new Float32Array(verticesCount)
            for(let i = 0; i < verticesCount; i++)
            {
                uvRotation[i] = Math.random() * Math.PI * 2
            }
            item.geometry.setAttribute('aUvRotation', new THREE.BufferAttribute(uvRotation, 1))

            // item.geometry.setAttribute('uv2', new THREE.BufferAttribute(item.geometry.attributes.uv.array, 2))

            /**
             * Material
             */
            item.material = new PointsPhysicalMaterial({
                color: new THREE.Color(_options.color),
                roughness: _options.roughness,
                metalness: _options.metalness,
                envMap: this.environmentMap,
                envMapIntensity: _options.envMapIntensity,
                brushTexture: this.brushParticles.brushTexture,
                usePoints: this.brushParticles.usePoints,
                fogColor: new THREE.Color(0x0f0914),
                fogDensity: 0.15
            })

            /**
             * Object
             */
            // Points
            item.points = new THREE.Points(item.geometry, item.material)
            item.points.position.copy(_options.position)
            this.scene.add(item.points)
    
            // Mesh
            item.mesh = new THREE.Mesh(item.geometry, item.material)
            item.mesh.position.copy(_options.position)

            /**
             * Debug
             */
            if(this.debug)
            {
                this.debug.Register({
                    type: 'folder',
                    folder: 'world',
                    label: _options.name,
                    open: true
                })

                this.debug.Register({
                    folder: _options.name,
                    type: 'range',
                    label: 'uSize',
                    min: 0,
                    max: 1000,
                    step: 1,
                    object: item.material.uniforms.uSize,
                    property: 'value'
                })

                this.debug.Register({
                    folder: _options.name,
                    type: 'range',
                    label: 'roughness',
                    min: 0,
                    max: 1,
                    step: 0.001,
                    object: item.material.uniforms.roughness,
                    property: 'value'
                })

                this.debug.Register({
                    folder: _options.name,
                    type: 'range',
                    label: 'metalness',
                    min: 0,
                    max: 1,
                    step: 0.001,
                    object: item.material.uniforms.metalness,
                    property: 'value'
                })

                this.debug.Register({
                    folder: _options.name,
                    type: 'range',
                    label: 'envMapIntensity',
                    min: 0,
                    max: 50,
                    step: 0.1,
                    object: item.material.uniforms.envMapIntensity,
                    property: 'value'
                })

                this.debug.Register({
                    type: 'color',
                    folder: _options.name,
                    label: 'color',
                    object: _options,
                    property: 'color',
                    format: 'hex',
                    onChange: () =>
                    {
                        item.material.uniforms.diffuse.value.set(_options.color)
                    }
                })
            }

            /**
             * Save
             */
            this.brushParticles.items.push(item)
        }
    }

    update()
    {
        this.lights.directionalLight.instance.position.x = Math.sin(this.time.elapsed / 1000)
        this.lights.directionalLight.instance.position.z = Math.sin(this.time.elapsed / 1000 * 0.8)
    }
}
