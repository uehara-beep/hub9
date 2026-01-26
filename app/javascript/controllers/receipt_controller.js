import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "status", "preview", "form", "amount", "counterparty", "category", "note", "directionIncoming", "directionOutgoing"]

  async scan(event) {
    const file = event.target.files[0]
    if (!file) return

    // プレビュー表示
    this.showPreview(file)
    this.statusTarget.innerHTML = '<span class="scanning">読み取り中...</span>'

    try {
      // ファイルをBase64に変換
      const base64 = await this.fileToBase64(file)

      // APIにアップロード
      const response = await fetch('/charge_entries/scan_receipt', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ image: base64 })
      })

      const data = await response.json()

      if (data.success) {
        this.fillForm(data)
        this.statusTarget.innerHTML = '<span class="success">読み取り完了</span>'
      } else {
        this.statusTarget.innerHTML = `<span class="error">エラー: ${data.error}</span>`
      }
    } catch (error) {
      console.error('Receipt scan error:', error)
      this.statusTarget.innerHTML = `<span class="error">読み取りに失敗しました</span>`
    }
  }

  showPreview(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewTarget.innerHTML = `<img src="${e.target.result}" class="receipt-preview-img">`
    }
    reader.readAsDataURL(file)
  }

  fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => {
        // data:image/jpeg;base64,xxxxx から base64部分だけ抽出
        const base64 = reader.result.split(',')[1]
        resolve(base64)
      }
      reader.onerror = reject
      reader.readAsDataURL(file)
    })
  }

  fillForm(data) {
    // 金額
    if (data.amount && this.hasAmountTarget) {
      this.amountTarget.value = data.amount
    }

    // 相手（店名）
    if (data.store && this.hasCounterpartyTarget) {
      this.counterpartyTarget.value = data.store
    }

    // カテゴリ
    if (data.category && this.hasCategoryTarget) {
      this.categoryTarget.value = data.category
    }

    // メモ（商品名など）
    if (data.note && this.hasNoteTarget) {
      this.noteTarget.value = data.note
    }

    // 支払い（レシートは基本的に支払い）
    if (this.hasDirectionOutgoingTarget) {
      this.directionOutgoingTarget.checked = true
    }
  }
}
