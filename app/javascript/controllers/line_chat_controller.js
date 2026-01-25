import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "fileInput", "preview", "previewContainer"]

  connect() {
    console.log("LINE chat connected")
    this.scrollToBottom()
  }

  send(event) {
    // フォーム送信は通常通り（サーバーサイドでリダイレクト）
    const message = this.inputTarget.value.trim()
    const hasFile = this.fileInputTarget.files.length > 0
    
    if (!message && !hasFile) {
      event.preventDefault()
      alert("メッセージまたは画像を入力してください")
      return
    }
    
    this.submitTarget.disabled = true
    this.submitTarget.innerHTML = "⏳"
  }

  handleKeydown(event) {
    // Cmd/Ctrl + Enter で送信
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      const form = event.target.closest('form')
      form.requestSubmit()
    }
  }

  autoResize() {
    const textarea = this.inputTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 100) + "px"
  }

  previewImage(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.src = e.target.result
      this.previewContainerTarget.style.display = "block"
    }
    reader.readAsDataURL(file)
  }

  removeImage() {
    this.fileInputTarget.value = ""
    this.previewContainerTarget.style.display = "none"
  }

  scrollToBottom() {
    setTimeout(() => {
      window.scrollTo(0, document.body.scrollHeight)
    }, 100)
  }
}
