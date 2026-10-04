document.addEventListener("change", (event) => {
  if (!event.target.matches("[data-photo-input]")) return
  const box = document.getElementById("photo-previews")
  if (!box) return
  box.innerHTML = ""
  Array.from(event.target.files).slice(0, 8).forEach((file) => {
    const img = document.createElement("img")
    img.src = URL.createObjectURL(file)
    img.alt = file.name
    box.appendChild(img)
  })
})