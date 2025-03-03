class Reader {
  constructor(url) {
    this.book = ePub(url, { openAs: "epub" });
    this.rendition = this.book.renderTo("reader", {
      width: "100%",
      height: "100%",
    });

    this.toc = document.getElementById("chapter-select");
    this.leftBtn = document.getElementById("page-left");
    this.rightBtn = document.getElementById("page-right");
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
    console.log(e.key);
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
}

const urlParams = new URLSearchParams(window.location.search);
const id = urlParams.get("id");
const url = `/library/${id}`;

const reader = new Reader(url);
reader.init();
