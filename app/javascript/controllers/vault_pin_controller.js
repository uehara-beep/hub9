import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field"]

  connect() {
    this.pin = ""
    this.max = 4
  }

  tap(e) {
    const val = e.currentTarget.dataset.val
    if (!val) return

    if (val === "del") {
      this.pin = this.pin.slice(0, -1)
      this.render()
      return
    }
    if (val === "clr") {
      this.pin = ""
      this.render()
      return
    }
    if (this.pin.length >= this.max) return

    this.pin += val
    this.render()

    // 4桁になったら自動でsubmit（フォームがあれば）
    if (this.pin.length === this.max) {
      const form = this.element.closest("form")
      if (form) form.requestSubmit()
    }
  }

  // iOS対策：touchstart -> tap を確実に通す
  touch(e) {
    e.preventDefault()
    this.tap(e)
  }

  render() {
    if (!this.hasFieldTarget) return
    this.fieldTarget.value = this.pin
  }
}
