import * as THREE from 'three'

export default class DefaultCamera
{
    constructor(_options)
    {
        this.time = _options.time
        this.baseInstance = _options.baseInstance

        this.active = false

        this.instance = this.baseInstance.clone()
        this.instance.position.set(0, 1.68, 2)
        this.instance.lookAt(new THREE.Vector3(0, 1.55, 0))
        this.instance.rotation.order = 'YXZ'
    }

    activate()
    {
        this.active = true
    }

    deactivate()
    {
        this.active = false
    }
}
