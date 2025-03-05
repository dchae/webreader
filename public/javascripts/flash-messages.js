class MessageQueue {
  constructor() {
    this.container = document.querySelector(".flash-messages");
    this.messages = this.container.querySelectorAll(".flash-message");
  }

  init() {
    this.messages.forEach((msg) => {
      const dismissable = msg.dataset.dismissable === "true";
      const timeout = parseInt(msg.dataset.timeout, 10);

      if (dismissable && timeout > 0) {
        setTimeout(() => this.hide(msg), timeout);
      }

      msg.addEventListener("click", () => this.hide(msg));
    });
  }

  hide(target) {
    target.style.opacity = "0";
    target.addEventListener("transitionend", () => target.remove());
  }
}

document.addEventListener("DOMContentLoaded", () => {
  new MessageQueue().init();
});
