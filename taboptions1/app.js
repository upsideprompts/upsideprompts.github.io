(() => {
  const viewport = document.getElementById("viewport");
  const box = document.getElementById("box");

  let rotX = -28;
  let rotY = 32;
  let dragging = false;
  let moved = false;
  let lastX = 0;
  let lastY = 0;
  let activePointerId = null;
  let ignoreViewportUntil = 0;

  const clampX = (value) => Math.max(-89, Math.min(89, value));

  function render() {
    box.style.transform = `rotateX(${rotX}deg) rotateY(${rotY}deg)`;
  }

  function onPointerDown(event) {
    if (event.target.closest(".surface-btn")) return;
    if (Date.now() < ignoreViewportUntil) return;

    dragging = true;
    moved = false;
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
    if (Math.abs(dx) > 2 || Math.abs(dy) > 2) moved = true;

    lastX = event.clientX;
    lastY = event.clientY;

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

  function openAfterAnimation(button, url) {
    if (button.dataset.busy === "1") return;
    button.dataset.busy = "1";
    button.classList.add("is-pressing");
    ignoreViewportUntil = Date.now() + 600;

    window.setTimeout(() => {
      window.open(url, "_blank", "noopener,noreferrer");
      button.classList.remove("is-pressing");
      button.dataset.busy = "0";
    }, 450);
  }

  document.querySelectorAll(".surface-btn").forEach((button) => {
    button.addEventListener("pointerdown", (event) => {
      event.stopPropagation();
    });

    button.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      const url = button.dataset.url;
      if (!url) return;
      openAfterAnimation(button, url);
    });
  });

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
