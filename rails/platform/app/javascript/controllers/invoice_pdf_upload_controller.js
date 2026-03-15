import BasePdfUploadController from "controllers/base_pdf_upload_controller"

export default class extends BasePdfUploadController {
  get uploadUrl() { return "/api/v1/invoices/process_statement" }
  get sourceType() { return "invoice" }
  get documentLabel() { return "請求書" }
}
