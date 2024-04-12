import * as THREE from 'three'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js'
import GUI from 'lil-gui'

import raymarchingVertex from './shader/raymarching/vertex.glsl'
import raymarchingFragment from './shader/raymarching/fragment.glsl'


/**
 * Base
 */
// Debug
const gui = new GUI()
const debugObject = {}
debugObject.progress = 0
gui.add(debugObject, 'progress').min(0).max(1).step(.1)

// Canvas
const canvas = document.querySelector('canvas.webgl')

// Scene
const scene = new THREE.Scene()

/**
 * Textures
 */
const textureLoader = new THREE.TextureLoader()
const matcapTextureOne = textureLoader.load('./textures/matcaps/7.png')
const matcapTextureTwo = textureLoader.load('./textures/matcaps/2.png')

/**
 * Test mesh
 */
// Geometry
const geometry = new THREE.PlaneGeometry(1, 1, 1, 1)

// Material
const material = new THREE.ShaderMaterial({
    side: THREE.DoubleSide,
    uniforms:{
        uTime: new THREE.Uniform(0),
        uMouse: new THREE.Uniform(new THREE.Vector2(0, 0)),
        uResolution: new THREE.Uniform(new THREE.Vector4()),
        uProgress: new THREE.Uniform(0),
        uMatcapOne: new THREE.Uniform(matcapTextureOne),
        uMatcapTwo: new THREE.Uniform(matcapTextureTwo),
    },
    vertexShader: raymarchingVertex,
    fragmentShader: raymarchingFragment
})

// Mesh
const mesh = new THREE.Mesh(geometry, material)
scene.add(mesh)

/**
 * Sizes
 */
const sizes = {
    width: window.innerWidth,
    height: window.innerHeight
}

const imageAspect = 1;

let a1
let a2

if(sizes.height/sizes.width > imageAspect){
    a1 = (sizes.width/sizes.height) * imageAspect
    a2 = 1
} else {
    a1 = 1
    a2 = (sizes.height/sizes.width) * imageAspect
}

material.uniforms.uResolution.value.x = sizes.width
material.uniforms.uResolution.value.y = sizes.height
material.uniforms.uResolution.value.z = a1
material.uniforms.uResolution.value.w = a2

window.addEventListener('resize', () =>
{
    // Update sizes
    sizes.width = window.innerWidth
    sizes.height = window.innerHeight

    const imageAspect = 1;

    let a1
    let a2

    if(sizes.height/sizes.width > imageAspect){
        a1 = (sizes.width/sizes.height) * imageAspect
        a2 = 1
    } else {
        a1 = 1
        a2 = (sizes.height/sizes.width) * imageAspect
    }

    material.uniforms.uResolution.value.x = sizes.width
    material.uniforms.uResolution.value.y = sizes.height
    material.uniforms.uResolution.value.z = a1
    material.uniforms.uResolution.value.w = a2

    // Update camera
    camera.aspect = sizes.width / sizes.height
    camera.updateProjectionMatrix()

    // Update renderer
    renderer.setSize(sizes.width, sizes.height)
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
})

// Mouse Events
const mouse = new THREE.Vector2()
window.addEventListener('mousemove', (e) => {
    mouse.x = e.pageX / sizes.width - .5
    mouse.y = - e.pageY / sizes.height + .5
})

/**
 * Camera
 */
// Base camera
const camera = new THREE.OrthographicCamera(1 / -2, 1 / 2, 1 / 2, 1 / -2, -1000, 1000)
camera.position.set(0, 0, 2)
scene.add(camera)

// Controls
const controls = new OrbitControls(camera, canvas)
controls.enableRotate = false
controls.enableZoom = false
controls.enablePan = false

/**
 * Renderer
 */
const renderer = new THREE.WebGLRenderer({
    canvas: canvas
})
renderer.setSize(sizes.width, sizes.height)
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))

/**
 * Animate
 */
const clock = new THREE.Clock()

const tick = () =>
{
    const elapsedTime = clock.getElapsedTime()

    // Update uniforms
    material.uniforms.uTime.value = elapsedTime
    material.uniforms.uProgress.value = debugObject.progress
    
    if(mouse){
        material.uniforms.uMouse.value = mouse
    }

    // Update controls
    controls.update()

    // Render
    renderer.render(scene, camera)

    // Call tick again on the next frame
    window.requestAnimationFrame(tick)
}

tick()