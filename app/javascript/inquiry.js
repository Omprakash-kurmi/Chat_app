const scrollChat = () => {
  const list = document.querySelector(".im-list")
  if (list) list.scrollTop = list.scrollHeight
}

document.addEventListener("turbo:load", () => {
  scrollChat()
  const list = document.querySelector(".im-list")
  if (list && !list.dataset.watching) {
    list.dataset.watching = "true"
    new MutationObserver(scrollChat).observe(list, { childList: true })
  }
})
