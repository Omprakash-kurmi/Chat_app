console.log("emoji.js loaded")

const EMOJI_LIST = [
  // original
  "😀","😂","😍","😊","😉","😎","🤔","😅",
  "😭","😡","👍","👎","🙏","👏","🙌","💪",
  "❤️","🔥","🎉","✅","😴","😇","🤯","😱",
  "🥳","🤗","😬","😏","🤝","✨","💯","👀",

  // new faces
  "😁","😆","🤣","🙂","🙃","😋","😛","😜","🤪","😝",
  "🤑","🤭","🤫","🤨","😐","😑","😶","🙄","😒","😞",
  "😔","😟","😕","🙁","☹️","😣","😖","😫","😩","🥺",
  "😢","😤","😠","🤬","😳","🥵","🥶","😰","😥","😓",
  "🤤","😪","😵","🤐","🤢","🤮","🤧","😷","🤒","🤕",

  // new hands
  "👌","✌️","🤞","🤟","🤘","🤙","👈","👉","👆","👇",
  "✊","👊","🤛","🤜","🤲","👋","🤚","🖐️","✋","🖖",

  // new hearts and symbols
  "💔","💕","💖","💗","💙","💚","💛","🧡","💜","🖤",
  "💋","💤","💥","💫","⭐","🌟","⚡","💢","💦","💨",

  // new fun and objects
  "🎂","🎁","🎈","🎊","🏆","🥇","🍕","🍔","☕","🍺"
]

function setupEmoji() {
  const form = document.getElementById("message-form")
  const input = document.getElementById("message-input")
  if (!form || !input) return

  let btn = document.getElementById("emoji-btn")
  if (!btn) {
    btn = document.createElement("button")
    btn.type = "button"
    btn.id = "emoji-btn"
    btn.textContent = "😊"
    btn.style.cssText = "background:none;border:0;font-size:22px;cursor:pointer;padding:0 6px"
    form.insertBefore(btn, input)
  }
  input.style.paddingLeft = "14px" // remove the reserved gap

  let picker = document.getElementById("emoji-picker")
  if (!picker) {
    picker = document.createElement("div")
    picker.id = "emoji-picker"
    document.body.appendChild(picker)
  }
  if (picker.dataset.ready) return
  picker.dataset.ready = "true"

  picker.className = "" // ignore the old .hidden class
  picker.style.cssText =
    "display:none;position:fixed;z-index:9999;flex-wrap:wrap;gap:4px;width:300px;" +
    "padding:8px;background:#fff;border-radius:12px;box-shadow:0 4px 16px rgba(0,0,0,.2)"

  EMOJI_LIST.forEach((emoji) => {
    const b = document.createElement("button")
    b.type = "button"
    b.textContent = emoji
    b.style.cssText = "background:none;border:0;font-size:22px;cursor:pointer;padding:4px"
    b.addEventListener("click", () => {
      const start = input.selectionStart ?? input.value.length
      const end = input.selectionEnd ?? input.value.length
      input.setRangeText(emoji, start, end, "end")
      input.focus()
    })
    picker.appendChild(b)
  })

  btn.addEventListener("click", (e) => {
    e.stopPropagation()
    if (picker.style.display === "flex") {
      picker.style.display = "none"
      return
    }
    const r = btn.getBoundingClientRect()
    picker.style.left = Math.max(8, r.left) + "px"
    picker.style.bottom = (window.innerHeight - r.top + 8) + "px"
    picker.style.display = "flex"
  })
}

// registered once, outside setupEmoji
document.addEventListener("click", (e) => {
  const picker = document.getElementById("emoji-picker")
  const btn = document.getElementById("emoji-btn")
  if (picker && !picker.contains(e.target) && e.target !== btn) {
    picker.style.display = "none"
  }
})

document.addEventListener("turbo:load", setupEmoji)