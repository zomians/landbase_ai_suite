import BasePdfUploadController from "controllers/base_pdf_upload_controller"

export default class extends BasePdfUploadController {
  get uploadUrl() { return "/api/v1/bank_statements/process_statement" }
  get statusUrlPrefix() { return "/api/v1/bank_statements" }
  get sourceType() { return "bank" }

  renderSummaryCards(summary, _data) {
    let html = ""
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-blue-600">${this.escapeHTML(String(summary.total_transactions || 0))}</p>`
    html += `<p class="text-sm text-gray-500">取引件数</p></div>`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-red-600">${this.escapeHTML(String((summary.total_withdrawals || 0).toLocaleString()))}円</p>`
    html += `<p class="text-sm text-gray-500">出金合計</p></div>`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-green-600">${this.escapeHTML(String((summary.total_deposits || 0).toLocaleString()))}円</p>`
    html += `<p class="text-sm text-gray-500">入金合計</p></div>`
    html += `<div class="bg-white shadow rounded-lg p-4 text-center">`
    html += `<p class="text-2xl font-bold text-yellow-600">${this.escapeHTML(String(summary.review_required_count || 0))}</p>`
    html += `<p class="text-sm text-gray-500">要確認</p></div>`
    return html
  }
}
