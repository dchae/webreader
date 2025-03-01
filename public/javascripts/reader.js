const urlParams = new URLSearchParams(window.location.search);
const id = urlParams.get("id");
const url = `/library/${id}`;

const book = ePub(url, { openAs: "epub" });
const rendition = book.renderTo("reader", { width: 600, height: 400 });
const displayed = rendition.display();
