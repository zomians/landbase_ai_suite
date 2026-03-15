import BasePdfUploadController from "controllers/base_pdf_upload_controller"

export default class extends BasePdfUploadController {
  get uploadUrl() { return "/api/v1/bank_statements/process_statement" }
  get sourceType() { return "bank" }
}
