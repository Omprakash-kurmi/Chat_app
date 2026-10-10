// Voice + video calls (WebRTC). Action Cable only carries the "signals".
import consumer from "channels/consumer"

const ICE = { iceServers: [{ urls: ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"] }] }

function initCalls() {
  const root = document.getElementById("icx-chat")
  if (!root || root.dataset.callReady) return
  root.dataset.callReady = "1"

  const me = Number(root.dataset.userId)
  const inquiryId = root.dataset.inquiryId
  const peerName = root.dataset.peerName
  const ui = root.querySelector(".icx-call-ui")
  if (!ui) return
  const remoteEl = ui.querySelector(".icx-remote")
  const localEl = ui.querySelector(".icx-local")
  const statusEl = ui.querySelector(".icx-call-status")
  const toast = root.querySelector(".icx-toast")

  let pc = null, local = null, kind = "audio", state = "idle", role = null
  let queued = [], tick = null, secs = 0, noAnswer = null, ringCtx = null, ringTimer = null

  const sub = consumer.subscriptions.create({ channel: "CallChannel", inquiry_id: inquiryId }, {
    received(d) { if (d.from !== me) onSignal(d).catch(console.error) }
  })
  const send = (type, extra = {}) => sub.perform("signal", { type, ...extra })

  const screen = (st, text) => {
    state = st === "idle" ? "idle" : state
    if (st === "idle") { ui.removeAttribute("data-state"); return }
    ui.dataset.state = st; ui.dataset.kind = kind
    ui.querySelector(".icx-call-name").textContent = peerName
    ui.querySelector(".icx-call-avatar").textContent = (peerName || "?")[0].toUpperCase()
    statusEl.textContent = text
  }
  const say = (t) => { toast.textContent = t; toast.classList.add("on"); setTimeout(() => toast.classList.remove("on"), 3000) }

  function ring(on) {
    clearInterval(ringTimer)
    if (!on) return
    try {
      ringCtx = ringCtx || new (window.AudioContext || window.webkitAudioContext)()
      const beep = () => {
        const o = ringCtx.createOscillator(), g = ringCtx.createGain()
        o.frequency.value = 520; g.gain.value = 0.07
        o.connect(g); g.connect(ringCtx.destination); o.start(); o.stop(ringCtx.currentTime + 0.35)
      }
      beep(); ringTimer = setInterval(beep, 1800)
    } catch (_) {}
  }

  async function getMedia(k) {
    try {
      local = await navigator.mediaDevices.getUserMedia({ audio: true, video: k === "video" ? { width: 1280, height: 720 } : false })
      localEl.srcObject = local
      return true
    } catch (e) {
      say(location.protocol === "http:" && location.hostname !== "localhost"
        ? "Calls need HTTPS (or localhost)." : "Allow camera/microphone access to call.")
      return false
    }
  }

  function makePc() {
    pc = new RTCPeerConnection(ICE)
    local.getTracks().forEach((t) => pc.addTrack(t, local))
    pc.ontrack = (e) => { remoteEl.srcObject = e.streams[0] }
    pc.onicecandidate = (e) => e.candidate && send("ice", { payload: e.candidate.toJSON() })
    pc.onconnectionstatechange = () => {
      if (pc && pc.connectionState === "connected") connected()
      if (pc && ["failed", "closed"].includes(pc.connectionState)) finish("Connection lost", state === "active" ? "completed" : "missed")
    }
  }

  function connected() {
    if (state === "active") return
    state = "active"; clearTimeout(noAnswer)
    remoteEl.play().catch(() => {})
    secs = 0; screen("active", "00:00")
    tick = setInterval(() => {
      secs++
      statusEl.textContent = String(Math.floor(secs / 60)).padStart(2, "0") + ":" + String(secs % 60).padStart(2, "0")
    }, 1000)
  }

  // status: completed | missed | declined | cancelled  (only the caller records it in the chat)
  function finish(msg, status) {
    if (state === "idle") return
    const duration = secs
    if (status && role === "caller") sub.perform("log_call", { media: kind, status, seconds: duration })

    ring(false); clearInterval(tick); clearTimeout(noAnswer)
    if (pc) { const p = pc; pc = null; p.close() }
    if (local) { local.getTracks().forEach((t) => t.stop()); local = null }
    remoteEl.srcObject = null; localEl.srcObject = null; queued = []
    state = "idle"; role = null; secs = 0; screen("idle")
    ui.querySelectorAll(".icx-cc.off").forEach((b) => b.classList.remove("off"))
    if (msg) say(msg)
  }

  async function start(k) {
    if (state !== "idle") return
    kind = k
    if (!(await getMedia(k))) return
    role = "caller"; state = "calling"
    screen("calling", k === "video" ? "Video calling…" : "Calling…")
    send("ring", { media: k })
    noAnswer = setTimeout(() => { send("end"); finish("No answer", "missed") }, 45000)
  }

  async function accept() {
    ring(false)
    role = "callee"
    if (!(await getMedia(kind))) { send("decline"); finish(); return }
    makePc()
    state = "connecting"; screen("calling", "Connecting…")
    send("accept")
  }

  async function onSignal(d) {
    switch (d.type) {
      case "ring":
        if (state !== "idle") return send("busy")
        kind = d.media === "video" ? "video" : "audio"; state = "ringing"
        screen("incoming", kind === "video" ? "Incoming video call…" : "Incoming voice call…")
        ring(true); break
      case "accept":                       // caller: other side said yes -> send offer
        if (state !== "calling") return
        clearTimeout(noAnswer); makePc()
        await pc.setLocalDescription(await pc.createOffer())
        send("offer", { payload: pc.localDescription.toJSON() }); statusEl.textContent = "Connecting…"; break
      case "offer":                        // callee: answer it
        if (!pc) return
        await pc.setRemoteDescription(d.payload); await flush()
        await pc.setLocalDescription(await pc.createAnswer())
        send("answer", { payload: pc.localDescription.toJSON() }); break
      case "answer":
        if (!pc) return
        await pc.setRemoteDescription(d.payload); await flush(); break
      case "ice":
        if (pc && pc.remoteDescription) await pc.addIceCandidate(d.payload).catch(() => {})
        else queued.push(d.payload); break
      case "decline": finish("Call declined", "declined"); break
      case "busy":    finish(peerName + " is on another call", "missed"); break
      case "end":
        finish(state === "active" ? "Call ended" : "Missed call", state === "active" ? "completed" : "missed"); break
    }
  }
  const flush = async () => { for (const c of queued) await pc.addIceCandidate(c).catch(() => {}); queued = [] }

  // buttons
  root.querySelectorAll("[data-call]").forEach((b) => b.addEventListener("click", () => start(b.dataset.call)))
  ui.querySelector(".icx-cc.accept").addEventListener("click", accept)
  ui.querySelector(".icx-cc.hang").addEventListener("click", () => {
    if (state === "ringing") { send("decline"); finish(""); return }
    const wasActive = state === "active"
    send("end")
    finish(wasActive ? "Call ended" : "", wasActive ? "completed" : "cancelled")
  })
  ui.querySelector(".icx-cc.mute").addEventListener("click", (e) => {
    local?.getAudioTracks().forEach((t) => (t.enabled = !t.enabled)); e.currentTarget.classList.toggle("off")
  })
  ui.querySelector(".icx-cc.cam").addEventListener("click", (e) => {
    local?.getVideoTracks().forEach((t) => (t.enabled = !t.enabled)); e.currentTarget.classList.toggle("off")
  })
  window.addEventListener("beforeunload", () => { if (state !== "idle") send("end") })
}

document.addEventListener("turbo:load", initCalls)
document.addEventListener("DOMContentLoaded", initCalls)