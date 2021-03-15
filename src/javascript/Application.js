import Guify from 'guify'
import * as THREE from 'three'

import EventEmitter from './Utils/EventEmitter.js'
import Time from './Utils/Time.js'
import Sizes from './Utils/Sizes.js'
import Stats from './Utils/Stats.js'

import Camera from './Camera/index.js'
import Renderer from './Renderer.js'
import Physics from './Physics.js'
import Controls from './Controls.js'
import World from './World.js'
import Fullscreen from './Fullscreen.js'
import Resources from './Resources.js'
import assets from './assets.js'

export default class Application
{
    /**
     * Constructor
     */
    constructor(_options = {})
    {
        window.application = this

        this.targetElement = _options.targetElement

        if(!this.targetElement)
        {
            console.warn('Missing \'targetElement\' property')
            return
        }

        this.time = new Time()
        this.sizes = new Sizes()

        this.setConfig()
        this.setDebug()
        this.setStats()
        this.setResources()
        this.setScene()
        this.setCamera()
        this.setRenderer()
        this.setPhysics()
        this.setFullscreen()
        this.setControls()

        this.time.on('tick', () =>
        {
            this.update()
        })
    }

    /**
     * Set config
     */
    setConfig()
    {
        this.config = {}

        // Debug
        this.config.debug = window.location.hash === '#debug'

        // Pixel ratio
        this.config.pixelRatio = Math.min(Math.max(window.devicePixelRatio, 1), 1.5)

        // Width and height
        const boundings = this.targetElement.getBoundingClientRect()
        this.config.width = boundings.width
        this.config.height = boundings.height
        this.config.heightRatio = this.config.height / this.sizes.viewport.height

        this.sizes.on('resize', () =>
        {
            const boundings = this.targetElement.getBoundingClientRect()
            this.config.width = boundings.width
            this.config.height = boundings.height
            this.config.heightRatio = this.config.height / this.sizes.viewport.height
        })

        // Touch
        this.config.touch = false

        window.addEventListener('touchstart', () =>
        {
            this.config.touch = true
        }, { once: true })
    }

    /**
     * Set debug
     */
    setDebug()
    {
        if(this.config.debug)
        {
            this.debug = new Guify({
                title: 'Brush Particles',
                theme: 'dark', // dark, light, yorha, or theme object
                align: 'right', // left, right
                width: 500,
                barMode: 'none', // none, overlay, above, offset
                panelMode: 'inner',
                opacity: 1,
                open: true
            })
        }
    }

    /**
     * Set stats
     */
    setStats()
    {
        this.stats = new Stats(true)
    }

    /**
     * Set resources
     */
    setResources()
    {
        this.resources = new Resources(assets)

        this.resources.on('progress', (_group, _resource, _data) =>
        {
        })

        this.resources.on('groupEnd', (_group) =>
        {
        })

        this.resources.on('end', (_group) =>
        {
            this.setWorld()
        })
    }

    /**
     * Set scene
     */
    setScene()
    {
        this.scene = new THREE.Scene()
    }

    /**
     * Set camera
     */
    setCamera()
    {
        this.camera = new Camera({
            interactionTarget: this.targetElement
        })

        this.scene.add(this.camera.instance)
    }

    /**
     * Set renderer
     */
    setRenderer()
    {
        this.renderer = new Renderer()

        this.targetElement.appendChild(this.renderer.instance.domElement)
    }

    /**
     * Set physics
     */
    setPhysics()
    {
        this.physics = new Physics()
    }

    /**
     * Set fullscreen
     */
    setFullscreen()
    {
        this.fullscreen = new Fullscreen()
    }

    /**
     * Set controls
     */
    setControls()
    {
        this.controls = new Controls({
            interactionTarget: this.targetElement
        })
    }

    /**
     * Set levels
     */
    setWorld()
    {
        this.world = new World()
    }

    /**
     * Update
     */
    update()
    {
        this.stats.update()
        this.camera.update()
        this.physics.update()
        this.controls.update()
        if(this.world)
        {
            this.world.update()
        }
        this.renderer.update()
    }
}
