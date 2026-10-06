console.log("emi_calculator loaded")

const inr = new Intl.NumberFormat("en-IN", { maximumFractionDigits: 0 })
const money = (n) => "₹" + inr.format(Math.round(n))
const words = (n) =>
  n >= 1e7 ? `${(n / 1e7).toFixed(2)} Crore` : n >= 1e5 ? `${(n / 1e5).toFixed(2)} Lakh` : ""

function calcEmi(principal, annualRate, years) {
  const n = Math.round(years * 12)
  if (n <= 0 || principal <= 0) return { monthly: 0, n: 0 }
  const r = annualRate / 12 / 100
  if (r === 0) return { monthly: principal / n, n }
  const f = Math.pow(1 + r, n)
  return { monthly: (principal * r * f) / (f - 1), n }
}

function yearlySchedule(principal, annualRate, monthly, n) {
  const r = annualRate / 12 / 100
  let balance = principal
  const rows = []
  for (let m = 1; m <= n; m++) {
    const interest = balance * r
    const paid = Math.min(monthly - interest, balance)
    balance -= paid
    const i = Math.ceil(m / 12) - 1
    rows[i] ||= { year: i + 1, principal: 0, interest: 0, balance: 0 }
    rows[i].principal += paid
    rows[i].interest += interest
    rows[i].balance = Math.max(balance, 0)
  }
  return rows
}

function update(root) {
  const read = (key) => parseFloat(root.querySelector(`[data-emi-number="${key}"]`).value) || 0
  const out = (key) => root.querySelector(`[data-emi-out="${key}"]`)

  const amount = read("amount"), years = read("years"), rate = read("rate")
  const { monthly, n } = calcEmi(amount, rate, years)
  const total = monthly * n
  const interest = Math.max(total - amount, 0)

  out("monthly").textContent = money(monthly)
  out("principal").textContent = money(amount)
  out("interest").textContent = money(interest)
  out("total").textContent = money(total)
  out("amount-words").textContent = words(amount) ? `₹${words(amount)}` : ""

  const share = total > 0 ? (amount / total) * 100 : 50
  root.querySelector('[data-emi-bar="principal"]').style.flexBasis = `${share}%`

  out("schedule").innerHTML = yearlySchedule(amount, rate, monthly, n)
    .map((row) => `<tr><td>${row.year}</td><td>${money(row.principal)}</td><td>${money(row.interest)}</td><td>${money(row.balance)}</td></tr>`)
    .join("")

  root.querySelectorAll("[data-emi-range]").forEach((slider) => {
    const min = parseFloat(slider.min), max = parseFloat(slider.max)
    slider.style.setProperty("--fill", `${((slider.value - min) / (max - min)) * 100}%`)
  })
}

const initAll = () => document.querySelectorAll("[data-emi]").forEach(update)

document.addEventListener("input", (event) => {
  const root = event.target.closest("[data-emi]")
  if (!root) return
  const key = event.target.dataset.emiRange || event.target.dataset.emiNumber
  if (!key) return
  const partner = event.target.dataset.emiRange
    ? root.querySelector(`[data-emi-number="${key}"]`)
    : root.querySelector(`[data-emi-range="${key}"]`)
  partner.value = event.target.value
  update(root)
})

document.addEventListener("change", (event) => {
  const box = event.target
  if (!box.dataset || !box.dataset.emiNumber) return
  const root = box.closest("[data-emi]")
  const min = parseFloat(box.min), max = parseFloat(box.max)
  const value = parseFloat(box.value)
  box.value = Number.isNaN(value) ? min : Math.min(Math.max(value, min), max)
  root.querySelector(`[data-emi-range="${box.dataset.emiNumber}"]`).value = box.value
  update(root)
})

document.addEventListener("turbo:load", initAll)
if (document.readyState !== "loading") initAll()