// app/javascript/channels/chat_room_channel.js
import consumer from "./consumer"

document.addEventListener("turbo:load", () => {
  const messages = document.getElementById("messages")
  if (!messages) return

  const roomId = messages.dataset.roomId
  const currentUserId = document.getElementById("chat-container").dataset.currentUserId

  function markOwnMessages() {
    messages.querySelectorAll(".message").forEach((el) => {
      if (el.dataset.userId === currentUserId) {
        el.classList.add("sent")
      } else {
        el.classList.add("received")
      }
    })
  }

  markOwnMessages()
  messages.scrollTop = messages.scrollHeight

  const channel = consumer.subscriptions.create(
    { channel: "ChatRoomChannel", room_id: roomId },
    {
      received(data) {
        messages.insertAdjacentHTML("beforeend", data.html)
        markOwnMessages()
        messages.scrollTop = messages.scrollHeight
      }
    }
  )

  document.getElementById("message-form").addEventListener("submit", (e) => {
    e.preventDefault()
    const input = document.getElementById("message-input")
    if (input.value.trim() === "") return
    channel.perform("speak", { content: input.value })
    input.value = ""
  })
})