import consumer from "./consumer"

document.addEventListener("turbo:load", () => {
  const messages = document.getElementById("messages")
  if (!messages) return

  const roomId = messages.dataset.roomId
  const currentUserId = document.getElementById("chat-container").dataset.currentUserId
  const typingIndicator = document.getElementById("typing-indicator")
  const input = document.getElementById("message-input")
  const imageInput = document.getElementById("image-input")
  const imagePreview = document.getElementById("image-preview")

  function markOwnMessages() {
    messages.querySelectorAll(".message").forEach((el) => {
      el.classList.add(el.dataset.userId === currentUserId ? "sent" : "received")
    })
  }

  markOwnMessages()
  messages.scrollTop = messages.scrollHeight

  let typingTimeout = null
  let isCurrentlyTyping = false
  let selectedFile = null

  const channel = consumer.subscriptions.create(
    { channel: "ChatRoomChannel", room_id: roomId },
    {
      received(data) {
        if (data.typing !== undefined) {
          handleTypingBroadcast(data)
          return
        }
        messages.insertAdjacentHTML("beforeend", data.html)
        markOwnMessages()
        messages.scrollTop = messages.scrollHeight
      }
    }
  )

  function handleTypingBroadcast(data) {
    if (String(data.user_id) === currentUserId) return
    typingIndicator.textContent = data.typing ? `${data.user_name} is typing...` : ""
  }

  input.addEventListener("input", () => {
    if (!isCurrentlyTyping) {
      isCurrentlyTyping = true
      channel.perform("typing")
    }
    clearTimeout(typingTimeout)
    typingTimeout = setTimeout(() => {
      isCurrentlyTyping = false
      channel.perform("stopped_typing")
    }, 2000)
  })

  imageInput.addEventListener("change", () => {
    selectedFile = imageInput.files[0]
    if (!selectedFile) return

    const reader = new FileReader()
    reader.onload = (e) => {
      imagePreview.innerHTML = `
        <img src="${e.target.result}" alt="Preview">
        <span class="remove-preview">Remove</span>
      `
      imagePreview.querySelector(".remove-preview").addEventListener("click", () => {
        selectedFile = null
        imageInput.value = ""
        imagePreview.innerHTML = ""
      })
    }
    reader.readAsDataURL(selectedFile)
  })

  document.getElementById("message-form").addEventListener("submit", async (e) => {
    e.preventDefault()
    const text = input.value.trim()
    if (text === "" && !selectedFile) return

    clearTimeout(typingTimeout)
    isCurrentlyTyping = false
    channel.perform("stopped_typing")

    if (selectedFile) {
      // Image present: send via HTTP so the file can upload
      const formData = new FormData()
      formData.append("message[content]", text)
      formData.append("message[image]", selectedFile)

      await fetch(`/rooms/${roomId}/messages`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      })

      selectedFile = null
      imageInput.value = ""
      imagePreview.innerHTML = ""
    } else {
      // Text only: keep using the fast WebSocket path
      channel.perform("speak", { content: text })
    }

    input.value = ""
  })
})