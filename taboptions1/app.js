(() => {
  const viewport = document.getElementById("viewport");
  const box = document.getElementById("box");

  let rotX = -28;
  let rotY = 32;
  let dragging = false;
  let lastX = 0;
  let lastY = 0;
  let activePointerId = null;

  const clampX = (value) => Math.max(-89, Math.min(89, value));

  function render() {
    box.style.transform = `rotateX(${rotX}deg) rotateY(${rotY}deg)`;
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

    // Horizontal drag spins around Y; vertical drag tips around X.
    rotY += dx * 0.45;
    rotX = clampX(rotX - dy * 0.45);
    render();
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
  viewport.addEventListener("lostpointercapture", () => {
    dragging = false;
    activePointerId = null;
    viewport.classList.remove("is-dragging");
  });

  render();
})();
