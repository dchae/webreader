class Reader {
  constructor(id) {
    this.id = id;
    this.book = ePub(`/library/${id}`, { openAs: "epub" });
    this.rendition = this.book.renderTo("reader", {
      width: "100%",
      height: "100%",
    });

    this.toc = document.getElementById("chapter-select");
    this.leftBtn = document.getElementById("page-left");
    this.rightBtn = document.getElementById("page-right");
    this.favoriteBtn = document.getElementById("toggle-favorite");
    this.dir = null;
  }

  init() {
    this.rendition.display();

    this.book.ready.then(() => {
      this.dir = this.book.package.metadata.direction ?? "ltr";
    });

    this.initNavTOC();
    this.initEventListeners();
  }

  initNavTOC() {
    this.book.loaded.navigation.then(({ toc }) => {
      const select = document.getElementById("chapter-select");
      const options = toc.map((chapter) => {
        const option = document.createElement("option");
        option.textContent = chapter.label;
        option.setAttribute("ref", chapter.href);
        return option;
      });

      select.replaceChildren(...options);
    });
  }

  initEventListeners() {
    this.initPageNavButtonHandlers();

    // keyhandler should be bound twice, since epub.js iframe consumes keyup event
    document.addEventListener("keyup", this.keyHandler.bind(this));
    this.rendition.on("keyup", this.keyHandler.bind(this));
    this.rendition.on("rendered", this.updateCurrentChapterHandler.bind(this));
    this.toc.addEventListener("change", this.chapterSelectHandler.bind(this));
    this.favoriteBtn.addEventListener(
      "click",
      this.toggleFavoriteHandler.bind(this),
    );
  }

  initPageNavButtonHandlers() {
    this.leftBtn.addEventListener("click", (e) => {
      e.preventDefault();
      this.pageLeft();
    });

    this.rightBtn.addEventListener("click", (e) => {
      e.preventDefault();
      this.pageRight();
    });
  }

  keyHandler(e) {
    if (e.key === "ArrowLeft") this.pageLeft();
    if (e.key === "ArrowRight") this.pageRight();
  }

  pageLeft() {
    this.dir === "rtl" ? this.rendition.next() : this.rendition.prev();
  }

  pageRight() {
    this.dir === "rtl" ? this.rendition.prev() : this.rendition.next();
  }

  updateCurrentChapterHandler(section) {
    const cur = this.book.navigation && this.book.navigation.get(section.href);

    if (cur) {
      const selected = this.toc.querySelector("option[selected]");
      if (selected) selected.removeAttribute("selected");

      const options = this.toc.querySelectorAll("option");
      const curOption = [...options].find(
        (option) => option.getAttribute("ref") === cur.href,
      );
      curOption?.setAttribute("selected", "");
    }
  }

  chapterSelectHandler(e) {
    e.preventDefault();
    const index = this.toc.selectedIndex;
    const url = this.toc.options[index].getAttribute("ref");
    this.rendition.display(url);
  }

  async toggleFavoriteHandler(e) {
    try {
      e.preventDefault();

      const button = e.target;

      const last_read_page = 0;
      const favorite = button.dataset.favorite === "true";
      const path = button.getAttribute("href");
      const opts = {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ last_read_page, favorite: !favorite }),
      };

      const response = await fetch(path, opts);
      const json = await response.json();

      const state = json.favorite === "t";
      const whiteHeart = "&#9825;";
      const blackHeart = "&#9829;";
      button.dataset.favorite = state;
      button.innerHTML = state ? blackHeart : whiteHeart;
    } catch (error) {
      console.error("Error toggling favorite:", error);
    }
  }
}

const urlParams = new URLSearchParams(window.location.search);
const id = urlParams.get("id");

const reader = new Reader(id);
reader.init();
