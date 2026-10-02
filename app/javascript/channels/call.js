import consumer from "./consumer"

document.addEventListener("turbo:load", () => {
  const container = document.getElementById("chat-container")
  if (!container) return

  const roomId = container.dataset.roomId
  const currentUserId = container.dataset.currentUserId

  const voiceCallBtn = document.getElementById("voice-call-btn")
  const videoCallBtn = document.getElementById("video-call-btn")
  const callModal = document.getElementById("call-modal")
  const callStatus = document.getElementById("call-status")
  const callVideos = document.getElementById("call-videos")
  const voiceDisplay = document.getElementById("voice-call-display")
  const localVideo = document.getElementById("local-video")
  const remoteVideo = document.getElementById("remote-video")
  const answerBtn = document.getElementById("answer-call-btn")
  const declineBtn = document.getElementById("decline-call-btn")

  let peerConnection = null
  let localStream = null
  let incomingOffer = null
  let currentCallType = null // "voice" or "video"

  const rtcConfig = {
    iceServers: [{ urls: "stun:stun.l.google.com:19302" }]
  }

  const callChannel = consumer.subscriptions.create(
    { channel: "ChatRoomChannel", room_id: roomId },
    {
      received(data) {
        if (!data.call_event) return
        if (String(data.from_user_id) === currentUserId) return

        switch (data.call_event) {
          case "offer":
            handleIncomingOffer(data)
            break
          case "answer":
            handleAnswer(data)
            break
          case "ice_candidate":
            handleRemoteIceCandidate(data)
            break
          case "hangup":
            endCall()
            break
        }
      }
    }
  )

  function showCallUI(callType) {
    currentCallType = callType
    if (callType === "video") {
      callVideos.classList.remove("hidden")
      voiceDisplay.classList.add("hidden")
    } else {
      callVideos.classList.add("hidden")
      voiceDisplay.classList.remove("hidden")
    }
    callModal.classList.remove("hidden")
  }

  async function getLocalStream(callType) {
    const constraints = callType === "video"
      ? { video: true, audio: true }
      : { video: false, audio: true }

    localStream = await navigator.mediaDevices.getUserMedia(constraints)
    if (callType === "video") {
      localVideo.srcObject = localStream
    }
  }

  function createPeerConnection() {
    const pc = new RTCPeerConnection(rtcConfig)

    pc.onicecandidate = (event) => {
      if (event.candidate) {
        callChannel.perform("call_ice_candidate", { candidate: event.candidate })
      }
    }

    pc.ontrack = (event) => {
      if (currentCallType === "video") {
        remoteVideo.srcObject = event.streams[0]
      } else {
        // Voice-only: play audio via a hidden element on remote-video (video tag plays audio tracks fine)
        remoteVideo.srcObject = event.streams[0]
      }
    }

    localStream.getTracks().forEach((track) => pc.addTrack(track, localStream))
    return pc
  }

  // ---- Starting a call ----

  async function startCall(callType) {
    showCallUI(callType)
    await getLocalStream(callType)
    peerConnection = createPeerConnection()

    const offer = await peerConnection.createOffer()
    await peerConnection.setLocalDescription(offer)

    callChannel.perform("call_offer", { sdp: offer, call_type: callType })

    callStatus.textContent = callType === "video" ? "Video calling..." : "Voice calling..."
    answerBtn.classList.add("hidden")
    declineBtn.textContent = "Cancel"
  }

  voiceCallBtn.addEventListener("click", () => startCall("voice"))
  videoCallBtn.addEventListener("click", () => startCall("video"))

  // ---- Receiving a call ----

  async function handleIncomingOffer(data) {
    incomingOffer = data.sdp
    showCallUI(data.call_type)

    callStatus.textContent = `${data.from_user_name} is ${data.call_type === "video" ? "video calling" : "voice calling"}...`
    answerBtn.classList.remove("hidden")
    declineBtn.textContent = "Decline"
  }

  answerBtn.addEventListener("click", async () => {
    await getLocalStream(currentCallType)
    peerConnection = createPeerConnection()

    await peerConnection.setRemoteDescription(new RTCSessionDescription(incomingOffer))
    const answer = await peerConnection.createAnswer()
    await peerConnection.setLocalDescription(answer)

    callChannel.perform("call_answer", { sdp: answer })

    callStatus.textContent = "Connected"
    answerBtn.classList.add("hidden")
    declineBtn.textContent = "Hang up"
  })

  async function handleAnswer(data) {
    if (!peerConnection) return
    await peerConnection.setRemoteDescription(new RTCSessionDescription(data.sdp))
    callStatus.textContent = "Connected"
  }

  async function handleRemoteIceCandidate(data) {
    if (!peerConnection) return
    try {
      await peerConnection.addIceCandidate(new RTCIceCandidate(data.candidate))
    } catch (err) {
      console.error("Error adding ICE candidate", err)
    }
  }

  // ---- Ending a call ----

  declineBtn.addEventListener("click", () => {
    callChannel.perform("call_hangup")
    endCall()
  })

  function endCall() {
    if (peerConnection) {
      peerConnection.close()
      peerConnection = null
    }
    if (localStream) {
      localStream.getTracks().forEach((track) => track.stop())
      localStream = null
    }
    localVideo.srcObject = null
    remoteVideo.srcObject = null
    incomingOffer = null
    currentCallType = null
    callModal.classList.add("hidden")
  }
})