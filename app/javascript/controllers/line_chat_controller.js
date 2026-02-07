import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit", "fileInput", "preview", "previewContainer"]
  static values = { streamUrl: String }

  connect() {
    this.scrollToBottom()
  }

  send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    const hasFile = this.hasFileInputTarget && this.fileInputTarget.files.length > 0

    if (!message && !hasFile) {
      return
    }

    // UIをロック
    this.submitTarget.disabled = true
    this.submitTarget.innerHTML = "..."
    this.submitTarget.style.opacity = "0.5"
    this.inputTarget.readOnly = true
    this.inputTarget.style.opacity = "0.5"

    // ユーザーメッセージを即座に画面に表示
    const imagePreviewSrc = this.hasPreviewTarget && this.previewContainerTarget.style.display !== "none"
      ? this.previewTarget.src : null
    this.appendUserMessage(message, imagePreviewSrc)

    // Miaの空の吹き出しを先に作成
    const assistantBubble = this.createAssistantBubble()

    // フォームデータを構築
    const form = event.target.closest('form')
    const formData = new FormData(form)

    // ストリーミングURL
    const streamUrl = this.streamUrlValue || '/hub/send_stream'

    // fetchでストリーミング受信
    fetch(streamUrl, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
      }
    })
    .then(res => {
      if (!res.ok) throw new Error(`HTTP ${res.status}`)
      const reader = res.body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''

      const processStream = () => {
        return reader.read().then(({ done, value }) => {
          if (done) {
            this.resetUI()
            return
          }

          buffer += decoder.decode(value, { stream: true })

          // SSEイベントをパース
          const lines = buffer.split('\n')
          buffer = lines.pop() // 未完了の行を保持

          let eventType = null
          for (const line of lines) {
            if (line.startsWith('event: ')) {
              eventType = line.slice(7).trim()
            } else if (line.startsWith('data: ') && eventType) {
              try {
                const data = JSON.parse(line.slice(6))
                this.handleSSE(eventType, data, assistantBubble)
              } catch (e) {
                // JSONパースエラーはスキップ
              }
              eventType = null
            }
          }

          return processStream()
        })
      }

      return processStream()
    })
    .catch(err => {
      const textEl = assistantBubble.querySelector('.bubble-text-content')
      if (textEl) textEl.textContent = "Error: " + err.message
      this.resetUI()
    })
  }

  handleSSE(event, data, bubble) {
    const textEl = bubble.querySelector('.bubble-text-content')
    if (!textEl) return

    switch (event) {
      case 'chunk':
        // テキストを追記
        textEl.textContent += data.text
        this.scrollToBottom()
        break
      case 'done':
        // 時刻を表示
        const timeEl = bubble.closest('.r')?.querySelector('.bt')
        if (timeEl) timeEl.textContent = data.time || ''
        this.scrollToBottom()
        break
      case 'error':
        textEl.textContent = "Error: " + (data.error || "Unknown error")
        break
    }
  }

  createAssistantBubble() {
    const chatEl = this.getChatContainer()
    if (!chatEl) return null

    // introを削除
    const intro = chatEl.querySelector('.intro')
    if (intro) intro.remove()

    const html = `
      <div class="r">
        <div class="r-av r-av-mia">Mia</div>
        <div class="r-c">
          <div class="bb">
            <span class="bubble-text-content"></span>
            <span class="cur">|</span>
          </div>
          <div class="bt"></div>
        </div>
      </div>
    `
    chatEl.insertAdjacentHTML('beforeend', html)
    this.scrollToBottom()

    // 最後に追加したbubbleを返す
    const bubbles = chatEl.querySelectorAll('.bb')
    return bubbles[bubbles.length - 1]
  }

  appendUserMessage(text, imageSrc) {
    const chatEl = this.getChatContainer()
    if (!chatEl) return

    // introを削除
    const intro = chatEl.querySelector('.intro')
    if (intro) intro.remove()

    const now = new Date()
    const time = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')}`

    let contentHtml = ''
    if (imageSrc) {
      contentHtml += `<img src="${imageSrc}" class="chat-image" alt="Image">`
    }
    if (text) {
      contentHtml += `<p>${this.escapeHtml(text)}</p>`
    }

    const html = `
      <div class="r me">
        <div class="r-av r-av-user">ta9</div>
        <div class="r-c">
          <div class="bb">${contentHtml}</div>
          <div class="bt">${time}</div>
        </div>
      </div>
    `
    chatEl.insertAdjacentHTML('beforeend', html)
    this.scrollToBottom()
  }

  resetUI() {
    // カーソルを消す
    document.querySelectorAll('.cur').forEach(el => el.remove())

    this.inputTarget.value = ""
    this.inputTarget.readOnly = false
    this.inputTarget.style.opacity = "1"
    this.inputTarget.style.height = "auto"
    this.submitTarget.disabled = false
    this.submitTarget.innerHTML = '<svg width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 8h12M10 4l4 4-4 4"/></svg>'
    this.submitTarget.style.opacity = "1"
    if (this.hasFileInputTarget) this.fileInputTarget.value = ""
    if (this.hasPreviewContainerTarget) this.previewContainerTarget.style.display = "none"
    this.inputTarget.focus()
  }

  getChatContainer() {
    return document.getElementById('chat-messages')
  }

  handleKeydown(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      const form = event.target.closest('form')
      form.requestSubmit()
    }
  }

  autoResize() {
    const textarea = this.inputTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 120) + "px"
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

  insertQuick(event) {
    const text = event.currentTarget.dataset.text
    if (text && this.hasInputTarget) {
      this.inputTarget.value = text
      this.inputTarget.focus()
    }
  }

  scrollToBottom() {
    setTimeout(() => {
      const chat = this.getChatContainer()
      if (chat) chat.scrollTop = chat.scrollHeight
    }, 50)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
