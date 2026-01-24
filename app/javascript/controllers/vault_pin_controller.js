import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dot", "input"]
  static values = { length: Number }

  connect() {
    this.pin = ""
    this.render()
  }

  press(e) {
    const d = e.currentTarget.dataset.digit
    if (!d) return
    if (this.pin.length >= this.lengthValue) return
    this.pin += d
    this.render()
  }

  backspace() {
    this.pin = this.pin.slice(0, -1)
    this.render()
  }

  async submit() {
    if (this.pin.length !== this.lengthValue) return

    try {
      const res = await fetch("/api/vault/unlock", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ pin: this.pin })
      })

      if (!res.ok) throw new Error("PINが違うか、通信エラーです")

      window.location.href = "/vault/home"
    } catch (err) {
      this.shake()
      this.pin = ""
      this.render()
      alert(err.message)
    }
  }

  render() {
    if (this.hasInputTarget) {
      this.inputTarget.value = this.pin
    }
    this.dotTargets.forEach((el, i) => {
      el.classList.toggle("filled", i < this.pin.length)
    })
  }

  shake() {
    this.element.animate(
      [{ transform: "translateX(0px)" },
       { transform: "translateX(-8px)" },
       { transform: "translateX(8px)" },
       { transform: "translateX(0px)" }],
      { duration: 220 }
    )
  }
}
