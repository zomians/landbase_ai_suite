class CleaningManualGenerateJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 2

  discard_on ActiveRecord::RecordNotFound

  after_discard do |_job, exception|
    manual_id = _job.arguments.first
    manual = CleaningManual.find_by(id: manual_id)
    manual&.update(status: "failed", error_message: "ジョブ実行エラー: #{exception.message}")
  end

  def perform(cleaning_manual_id, labels: [])
    manual = CleaningManual.find(cleaning_manual_id)
    return unless manual.status == "processing"

    image_wrappers = manual.images.map { |blob| BlobImageWrapper.new(blob) }

    begin
      service = CleaningManualGeneratorService.new(
        images: image_wrappers,
        property_name: manual.property_name,
        room_type: manual.room_type,
        labels: labels
      )
      result = service.call

      if result.success?
        manual.update!(manual_data: result.data, status: "draft", error_message: nil)
      else
        manual.update!(status: "failed", error_message: result.error)
      end
    ensure
      image_wrappers.each(&:close)
    end
  end
end
