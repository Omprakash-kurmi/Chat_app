// Emoji picker, image preview and auto-scroll for the inquiry chat.
const EMOJI = {
  "😀": ["😀","😂","🥰","😍","😎","🤗","😉","😊","🙂","😅","🤔","😢","😭","😡","🥳","😴"],
  "👍": ["👍","👏","🙏","🙌","💪","🤝","👌","✌️","👋","👎","🤞","🫶"],
  "❤️": ["❤️","💜","💙","💚","💛","🔥","✨","🎉","💯","⭐","🌈","🎁"],
  "🏠": ["🏠","🏡","🏢","🔑","📍","💰","📅","✅","🛋️","🚗","🌳","📞","🕐","📸","🛏️","🚿"]
};

function initChat() {
  const root = document.getElementById("icx-chat");
  if (!root || root.dataset.uiReady) return;
  root.dataset.uiReady = "1";

  const me = root.dataset.userId;
  const msgs = root.querySelector(".icx-msgs");
  const input = root.querySelector(".icx-input");
  const panel = root.querySelector(".icx-emoji");
  const grid = root.querySelector(".icx-egrid");
  const tabs = root.querySelector(".icx-etabs");
  const file = root.querySelector(".icx-file");
  const prev = root.querySelector(".icx-prev");
  const form = root.querySelector("form");

  // my messages on the right (works for live-appended messages too)
  const mark = (el) => { if (el.dataset && el.dataset.senderId === me) el.classList.add("mine"); };
  const markAll = () => msgs.querySelectorAll(".icx-msg").forEach(mark);
  const toBottom = () => { msgs.scrollTop = msgs.scrollHeight; };
  markAll(); toBottom();
  new MutationObserver((list) => {
    list.forEach((m) => m.addedNodes.forEach((n) => n.nodeType === 1 && mark(n)));
    toBottom();
  }).observe(msgs, { childList: true });
  msgs.querySelectorAll("img").forEach((i) => i.addEventListener("load", toBottom));
  if (!form) return;

  // emoji picker
  const show = (key) => {
    grid.innerHTML = "";
    EMOJI[key].forEach((e) => {
      const b = document.createElement("button");
      b.type = "button"; b.className = "icx-e"; b.textContent = e;
      b.addEventListener("click", () => {
        const s = input.selectionStart ?? input.value.length, t = input.selectionEnd ?? s;
        input.value = input.value.slice(0, s) + e + input.value.slice(t);
        input.focus(); input.setSelectionRange(s + e.length, s + e.length);
      });
      grid.appendChild(b);
    });
    tabs.querySelectorAll(".icx-etab").forEach((t) => t.classList.toggle("on", t.dataset.k === key));
  };
  Object.keys(EMOJI).forEach((k) => {
    const t = document.createElement("button");
    t.type = "button"; t.className = "icx-etab"; t.textContent = k; t.dataset.k = k;
    t.addEventListener("click", () => show(k));
    tabs.appendChild(t);
  });
  show(Object.keys(EMOJI)[0]);
  root.querySelector("[data-emoji-btn]").addEventListener("click", (e) => { e.stopPropagation(); panel.classList.toggle("open"); });
  document.addEventListener("click", (e) => { if (!panel.contains(e.target)) panel.classList.remove("open"); });
  document.addEventListener("keydown", (e) => { if (e.key === "Escape") panel.classList.remove("open"); });

  // image preview
  const clearPrev = () => { file.value = ""; prev.classList.remove("on"); prev.innerHTML = ""; };
  file.addEventListener("change", () => {
    const f = file.files[0];
    if (!f) return clearPrev();
    if (!f.type.startsWith("image/") || f.size > 5 * 1024 * 1024) { alert("Please choose an image under 5 MB."); return clearPrev(); }
    prev.innerHTML = "";
    const img = document.createElement("img"); img.src = URL.createObjectURL(f);
    const name = document.createElement("span"); name.textContent = f.name;
    const x = document.createElement("button"); x.type = "button"; x.className = "icx-x"; x.textContent = "✕"; x.addEventListener("click", clearPrev);
    prev.append(img, name, x); prev.classList.add("on");
  });
  // after a send, reset the form (Turbo keeps the page)
  form.addEventListener("turbo:submit-end", () => { form.reset(); clearPrev(); panel.classList.remove("open"); });
}

document.addEventListener("turbo:load", initChat);
document.addEventListener("DOMContentLoaded", initChat);