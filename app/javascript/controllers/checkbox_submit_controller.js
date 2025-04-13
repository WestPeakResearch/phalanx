import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const form = this.element.closest('form')
    const formData = new FormData(form)
    
    fetch(form.action, {
      method: form.method,
      body: formData,
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
  }
} 