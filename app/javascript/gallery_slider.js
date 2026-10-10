function setup(el) {
  if (el.dataset.ready) return;
  const track = el.querySelector("[data-track]");
  if (!track) return;
  el.dataset.ready = "1";

  const slides = Array.from(track.children);
  const dots = Array.from(el.querySelectorAll("[data-dot]"));
  const thumbs = Array.from(el.querySelectorAll("[data-thumb]"));
  const counter = el.querySelector("[data-counter]");
  let index = 0, ticking = false, timer = null;

  const paint = () => {
    dots.forEach((d, n) => d.classList.toggle("is-active", n === index));
    thumbs.forEach((t, n) => t.classList.toggle("is-active", n === index));
    if (counter) counter.textContent = `${index + 1} / ${slides.length}`;
    const t = thumbs[index];
    if (t && t.parentElement) t.parentElement.scrollTo({ left: t.offsetLeft - 12, behavior: "smooth" });
  };

  const go = (n) => {
    index = (n + slides.length) % slides.length;
    track.scrollTo({ left: index * track.clientWidth, behavior: "smooth" });
    paint();
  };

  track.addEventListener("scroll", () => {
    if (ticking) return;
    ticking = true;
    requestAnimationFrame(() => {
      const n = Math.round(track.scrollLeft / track.clientWidth);
      if (n !== index && n >= 0 && n < slides.length) { index = n; paint(); }
      ticking = false;
    });
  }, { passive: true });

  const on = (sel, fn) => el.querySelector(sel)?.addEventListener("click", fn);
  on("[data-prev]", () => go(index - 1));
  on("[data-next]", () => go(index + 1));
  dots.forEach((d, n) => d.addEventListener("click", () => go(n)));
  thumbs.forEach((t, n) => t.addEventListener("click", () => go(n)));

  track.addEventListener("keydown", (e) => {
    if (e.key === "ArrowLeft") { e.preventDefault(); go(index - 1); }
    if (e.key === "ArrowRight") { e.preventDefault(); go(index + 1); }
  });

  const ms = parseInt(el.dataset.autoplay || "0", 10);
  if (ms > 0 && slides.length > 1) {
    const stop = () => clearInterval(timer);
    const start = () => {
      stop();
      timer = setInterval(() => {
        if (!el.isConnected) return stop();
        go(index + 1);
      }, ms);
    };
    el.addEventListener("mouseenter", stop);
    el.addEventListener("mouseleave", start);
    el.addEventListener("touchstart", stop, { passive: true });
    start();
  }
}

function initSliders() {
  document.querySelectorAll("[data-slider]").forEach(setup);
}

document.addEventListener("turbo:load", initSliders);
document.addEventListener("DOMContentLoaded", initSliders);
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("[data-slider]").forEach((el) => delete el.dataset.ready);
});

// click a gallery photo to enlarge it
document.addEventListener("click", (e) => {
  const img = e.target.closest("img[data-zoom]");
  if (!img) return;
  const box = document.createElement("div");
  box.className = "pgx-lightbox";
  box.innerHTML = `<img src="${img.dataset.zoom}" alt="">`;
  box.addEventListener("click", () => box.remove());
  document.body.appendChild(box);
});
document.addEventListener("keydown", (e) => {
  if (e.key === "Escape") document.querySelector(".pgx-lightbox")?.remove();
});