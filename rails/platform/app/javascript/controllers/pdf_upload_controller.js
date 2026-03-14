import BasePdfUploadController from "controllers/base_pdf_upload_controller"

export default class extends BasePdfUploadController {
  get uploadUrl() { return "/api/v1/amex_statements/process_statement" }
  get statusUrlPrefix() { return "/api/v1/amex_statements" }
  get sourceType() { return "amex" }
}
