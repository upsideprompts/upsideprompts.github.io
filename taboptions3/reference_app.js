import * as THREE from "three";
import { parseBinarySTL } from "./stl.js";

const viewport = document.getElementById("viewport");
const canvas = document.getElementById("canvas");
const statusEl = document.getElementById("status");
const facetCountEl = document.getElementById("facetCount");

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(42, 1, 0.1, 500);
camera.position.set(0, 18, 55);

const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  alpha: true,
});
renderer.setClearColor(0x000000, 0);
renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));

const hemi = new THREE.HemisphereLight(0xe8f4ff, 0x6a8aa0, 1.05);
scene.add(hemi);
const key = new THREE.DirectionalLight(0xffffff, 0.85);
key.position.set(40, 60, 30);
scene.add(key);
const fill = new THREE.DirectionalLight(0xb8dfff, 0.35);
fill.position.set(-30, -10, -40);
scene.add(fill);

const root = new THREE.Group();
scene.add(root);

let mesh = null;
let rotX = -0.35;
let rotY = 0.55;
let distance = 55;
let dragging = false;
let lastX = 0;
let lastY = 0;
let activePointerId = null;

function fitCameraToObject(object) {
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  const maxDim = Math.max(size.x, size.y, size.z);
  distance = maxDim * 1.85;
  camera.near = maxDim / 200;
  camera.far = maxDim * 40;
  camera.updateProjectionMatrix();
}

function resize() {
  const w = viewport.clientWidth;
  const h = viewport.clientHeight;
  camera.aspect = w / Math.max(h, 1);
  camera.updateProjectionMatrix();
  renderer.setSize(w, h, false);
}

function render() {
  root.rotation.x = rotX;
  root.rotation.y = rotY;
  camera.position.set(
    Math.sin(0) * distance,
    distance * 0.22,
    Math.cos(0) * distance
  );
  camera.lookAt(0, 0, 0);
  renderer.render(scene, camera);
}

function frame() {
  render();
  requestAnimationFrame(frame);
}

function onPointerDown(event) {
  dragging = true;
  activePointerId = event.pointerId;
  lastX = event.clientX;
  lastY = event.clientY;
  viewport.classList.add("is-dragging");
  viewport.setPointerCapture(event.pointerId);
}

function onPointerMove(event) {
  if (!dragging || event.pointerId !== activePointerId) return;
  const dx = event.clientX - lastX;
  const dy = event.clientY - lastY;
  lastX = event.clientX;
  lastY = event.clientY;
  rotY += dx * 0.008;
  rotX = Math.max(-1.2, Math.min(1.2, rotX + dy * 0.008));
}

function endDrag(event) {
  if (event.pointerId !== activePointerId) return;
  dragging = false;
  activePointerId = null;
  viewport.classList.remove("is-dragging");
  if (viewport.hasPointerCapture(event.pointerId)) {
    viewport.releasePointerCapture(event.pointerId);
  }
}

viewport.addEventListener("pointerdown", onPointerDown);
viewport.addEventListener("pointermove", onPointerMove);
viewport.addEventListener("pointerup", endDrag);
viewport.addEventListener("pointercancel", endDrag);
viewport.addEventListener(
  "wheel",
  (event) => {
    event.preventDefault();
    distance = Math.max(18, Math.min(140, distance * (event.deltaY > 0 ? 1.08 : 0.92)));
  },
  { passive: false }
);

window.addEventListener("resize", resize);

async function loadModel() {
  const response = await fetch("Cassette_Keyring.stl");
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const buffer = await response.arrayBuffer();
  const parsed = parseBinarySTL(buffer);

  facetCountEl.textContent = parsed.triangleCount.toLocaleString();

  const geometry = new THREE.BufferGeometry();
  geometry.setAttribute("position", new THREE.BufferAttribute(parsed.positions, 3));
  geometry.setAttribute("normal", new THREE.BufferAttribute(parsed.normals, 3));
  geometry.computeBoundingBox();

  // Center model at origin for orbiting
  const center = new THREE.Vector3();
  geometry.boundingBox.getCenter(center);
  geometry.translate(-center.x, -center.y, -center.z);

  // Cassette is long in Z; stand it more upright for display
  const material = new THREE.MeshPhongMaterial({
    color: 0x7ad0ef,
    specular: 0xffffff,
    shininess: 90,
    transparent: true,
    opacity: 0.42,
    side: THREE.DoubleSide,
    depthWrite: true,
  });

  mesh = new THREE.Mesh(geometry, material);

  const edges = new THREE.LineSegments(
    new THREE.EdgesGeometry(geometry, 28),
    new THREE.LineBasicMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.22,
    })
  );

  root.clear();
  // Orient: STL Z-up length → tilt for keyring silhouette
  root.rotation.order = "YXZ";
  const orient = new THREE.Group();
  orient.rotation.x = -Math.PI / 2;
  orient.add(mesh);
  orient.add(edges);
  root.add(orient);

  fitCameraToObject(root);
  statusEl.textContent = `${parsed.triangleCount.toLocaleString()} facets · ${parsed.header || "binary STL"}`;
  window.setTimeout(() => statusEl.classList.add("is-hidden"), 1400);
}

resize();
frame();

loadModel().catch((err) => {
  console.error(err);
  statusEl.textContent = "Failed to load Cassette_Keyring.stl";
  statusEl.classList.remove("is-hidden");
});
