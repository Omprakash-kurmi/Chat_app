const history = [];

const $ = (s) => document.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

function addMsg(kind, text) {
  const box = $("#aiq-msgs");
  const div = document.createElement("div");
  div.className = `aiq-msg aiq-msg--${kind}`;
  div.textContent = text;
  box.appendChild(div);
  box.scrollTop = box.scrollHeight;
  return div;
}

function addCards(list) {
  const box = $("#aiq-msgs");
  list.forEach(p => {
    const a = document.createElement("a");
    a.href = p.url;
    a.className = "aiq-card";
    a.innerHTML =
      `<span class="aiq-card-ico">${p.kind === "land" ? "🌳" : "🏠"}</span>` +
      `<span class="aiq-card-body"><b>${esc(p.title)}</b>` +
      `<small>${esc(p.place || "")}</small><em>${esc(p.price)}</em></span>`;
    box.appendChild(a);
  });
  box.scrollTop = box.scrollHeight;
}

async function send(text) {
  text = (text || "").trim();
  if (!text) return;
  addMsg("user", text);
  const typing = addMsg("bot", "Thinking…");
  typing.classList.add("aiq-typing");

  try {
    const token = document.querySelector('meta[name="csrf-token"]')?.content;
    const res = await fetch("/ai/assistant", {
      method: "POST",
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": token },
      body: JSON.stringify({ message: text, history: history.slice(-6) })
    });
    const data = await res.json();
    typing.remove();
    addMsg("bot", data.reply || "Sorry, I could not answer that.");
    if (data.properties?.length) addCards(data.properties);
    history.push({ role: "user", text }, { role: "assistant", text: data.reply || "" });
  } catch (e) {
    typing.remove();
    addMsg("bot", "Something went wrong. Please try again.");
  }
}

document.addEventListener("click", (e) => {
  if (e.target.closest("[data-aiq-toggle]")) {
    const panel = $("#aiq .aiq-panel");
    panel.hidden = !panel.hidden;
    if (!panel.hidden) $("#aiq-input")?.focus();
    return;
  }
  const chip = e.target.closest("[data-aiq-chip]");
  if (chip) send(chip.dataset.aiqChip);
});

document.addEventListener("submit", (e) => {
  if (e.target.id !== "aiq-form") return;
  e.preventDefault();
  const input = $("#aiq-input");
  const v = input.value;
  input.value = "";
  send(v);
});