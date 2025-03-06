class MessageQueue {
  constructor() {
    this.container = document.querySelector(".flash-messages");
    this.messages = this.container.children;
    this.container.addEventListener("click", this.clickHandler.bind(this));
    this.observe();
  }

  init() {
    [...this.messages].forEach((msg) => {
      const dismissable = msg.dataset.dismissable === "true";
      const timeout = parseInt(msg.dataset.timeout, 10);

      if (dismissable && timeout > 0) {
        setTimeout(() => this.hide(msg), timeout);
      }
    });
  }

  observe() {
    const observer = new MutationObserver((mutations) => {
      if (
        mutations.some(
          (mutation) =>
            mutation.type === "childList" && mutation.addedNodes.length > 0,
        )
      ) {
        this.init();
      }
    });

    observer.observe(this.container, { childList: true });
  }

  clickHandler(e) {
    const li = e.target.closest("li");
    this.hide(li);
  }

  hide(target) {
    target.style.opacity = "0";
    target.addEventListener("transitionend", () => target.remove());
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new MessageQueue().init();
});
