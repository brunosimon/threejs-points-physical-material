import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'

export default class DebugCamera
{
    constructor(_options)
    {
        this.time = _options.time
        this.baseInstance = _options.baseInstance
        this.interactionTarget = _options.interactionTarget

        this.active = false
        this.instance = this.baseInstance.clone()
        
        this.orbitControls = new OrbitControls(this.instance, this.interactionTarget)
        this.orbitControls.enabled = this.active
        this.orbitControls.screenSpacePanning = true
        this.orbitControls.enableKeys = false
        this.orbitControls.zoomSpeed = 0.25
        this.orbitControls.enableDamping = true
        this.orbitControls.update()
    }

    update()
    {
        if(!this.active)
        {
            return
        }

        this.orbitControls.update()
    }

    activate()
    {
        this.active = true
        this.orbitControls.enabled = true
    }

    deactivate()
    {
        this.active = false
        this.orbitControls.enabled = false
    }
}
