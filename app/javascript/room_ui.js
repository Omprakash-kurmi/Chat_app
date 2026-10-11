// Marks my messages (right side) and adds click-to-enlarge for photos.
let observer = null;

function markMine() {
  const box = document.getElementById("chat-container");
  if (!box) return;
  const me = box.dataset.currentUserId;
  document.querySelectorAll("#messages .message").forEach((m) => {
    m.classList.toggle("rm-mine", m.dataset.userId === me);
  });
}

function setup() {
  const list = document.getElementById("messages");
  if (!list) return;
  markMine();
  list.scrollTop = list.scrollHeight;

  if (observer) observer.disconnect();
  observer = new MutationObserver(markMine);
  observer.observe(list, { childList: true });
}

document.addEventListener("turbo:load", setup);
document.addEventListener("DOMContentLoaded", setup);

document.addEventListener("click", (e) => {
  const img = e.target.closest("#messages .message-image");
  if (!img) return;
  const box = document.createElement("div");
  box.className = "rm-lightbox";
  box.innerHTML = `<img src="${img.src}" alt="Photo">`;
  box.addEventListener("click", () => box.remove());
  document.body.appendChild(box);
});