// shop-data.js
// ─────────────────────────────────────────────────────────────────────────────
// BHSS Product Catalog — edit this file to add, remove, or update products.
// Reload the page after saving to see changes.
//
// FIELDS:
//   id          — unique slug, no spaces (used as cart key)
//   name        — display name
//   description — short description shown on the card
//   price       — number (CAD, e.g. 55.00)
//   image       — path relative to shop.html (e.g. "assets/images/merch/crewneck.jpg")
//               — leave as "" or omit to show the placeholder graphic
//   sizes       — array of size strings, e.g. ["XS","S","M","L","XL","XXL"]
//               — use [] for items with no size (bottles, bags, hats)
//   stock       — "in" | "low" | "out"
//               — "out" disables the Add to Cart button automatically
//   category    — "Tops" | "Accessories"
//               — used by the filter bar
//   featured    — true | false  (shows "Featured" badge on image)
// ─────────────────────────────────────────────────────────────────────────────

window.BHSS_PRODUCTS = [
  {
    id: "bhss-crewneck-maroon",
    name: "BHSS Crewneck — Maroon",
    description: "Heavyweight fleece crewneck with embroidered BHSS shield logo on chest. Unisex sizing — fits true to size.",
    price: 55.00,
    image: "assets/images/merch/crewneck-maroon.jpg",
    sizes: ["XS", "S", "M", "L", "XL", "XXL"],
    stock: "in",
    category: "Tops",
    featured: true
  },
  {
    id: "bhss-crewneck-navy",
    name: "BHSS Crewneck — Navy",
    description: "Same premium heavyweight fleece, now in midnight navy. Embroidered BHSS logo. Unisex sizing.",
    price: 55.00,
    image: "assets/images/merch/crewneck-navy.jpg",
    sizes: ["XS", "S", "M", "L", "XL", "XXL"],
    stock: "low",
    category: "Tops",
    featured: false
  },
  {
    id: "bhss-hoodie-blue",
    name: "BHSS Hoodie — Blue",
    description: "Pullover hoodie in BHSS blue with kangaroo pocket, drawstring hood, and embroidered logo. Unisex sizing.",
    price: 60.00,
    image: "assets/images/merch/hoodie-blue.jpg",
    sizes: ["XS", "S", "M", "L", "XL", "XXL"],
    stock: "in",
    category: "Tops",
    featured: true
  },
  {
    id: "bhss-tote-bag",
    name: "BHSS Tote Bag",
    description: "Heavy-duty canvas tote with the BHSS shield screen-printed in maroon. Perfect for textbooks, groceries, or lab gear.",
    price: 15.00,
    image: "assets/images/merch/tote-bag.jpg",
    sizes: [],
    stock: "in",
    category: "Accessories",
    featured: true
  },
  {
    id: "bhss-water-bottle",
    name: "BHSS Water Bottle",
    description: "Insulated 1L stainless steel bottle. Keeps drinks cold 24 hrs, hot 12 hrs. BHSS logo laser-etched.",
    price: 30.00,
    image: "assets/images/merch/water-bottle.jpg",
    sizes: [],
    stock: "in",
    category: "Accessories",
    featured: false
  },
  {
    id: "bhss-baseball-cap",
    name: "BHSS Baseball Cap",
    description: "Structured 6-panel cap in maroon with white embroidered BHSS text. Adjustable strap, one size fits most.",
    price: 25.00,
    image: "assets/images/merch/cap.jpg",
    sizes: [],
    stock: "out",
    category: "Accessories",
    featured: false
  }
];
