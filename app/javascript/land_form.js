function applyListingType() {
  const checked = document.querySelector('input[name="property[listing_type]"]:checked');
  const isLand = !!checked && checked.value === "land";
  const isRent = !!checked && checked.value === "rent";

  document.querySelectorAll("[data-land-only]").forEach(el => { el.hidden = !isLand; });
  document.querySelectorAll("[data-not-land]").forEach(el => { el.hidden = isLand; });
  document.querySelectorAll("[data-rent-only]").forEach(el => { el.hidden = !isRent; });

  const price = document.querySelector("[data-price-label]");
  if (price) {
    if (!price.dataset.original) price.dataset.original = price.textContent;
    price.textContent = isLand ? "Total price" : price.dataset.original;
  }
}
document.addEventListener("turbo:load", applyListingType);
document.addEventListener("DOMContentLoaded", applyListingType);
document.addEventListener("change", e => {
  if (e.target.name === "property[listing_type]") applyListingType();
});
