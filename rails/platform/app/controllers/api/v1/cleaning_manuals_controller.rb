module Api
  module V1
    class CleaningManualsController < BaseController
      ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
      MAX_IMAGE_SIZE = 10.megabytes

      def index
        manuals = CleaningManual.for_client(@client_code).recent
        render json: manuals.map { |m| manual_summary(m) }
      end

      def show
        manual = CleaningManual.for_client(@client_code).find_by(id: params[:id])
        return render_not_found unless manual

        render json: manual_detail(manual)
      end

      def generate
        images = params[:images] || []
        return render_error("画像を1枚以上アップロードしてください") if images.empty?

        invalid = images.reject { |img| img.content_type.in?(ALLOWED_CONTENT_TYPES) }
        if invalid.any?
          return render_error("対応していない画像形式が含まれています。JPEG, PNG, WebP のみ対応しています。")
        end

        oversized = images.select { |img| img.size > MAX_IMAGE_SIZE }
        if oversized.any?
          return render_error("画像は1枚あたり10MB以下にしてください。")
        end

        property_name = params[:property_name]
        room_type = params[:room_type]
        return render_error("property_name は必須です") if property_name.blank?
        return render_error("room_type は必須です") if room_type.blank?

        labels = params[:labels] || []

        service = CleaningManualGeneratorService.new(
          images: images,
          property_name: property_name,
          room_type: room_type,
          labels: labels
        )
        result = service.call

        unless result.success?
          return render_error(result.error)
        end

        manual = CleaningManual.new(
          client_code: @client_code,
          property_name: property_name,
          room_type: room_type,
          manual_data: result.data,
          status: "draft"
        )

        images.each { |img| manual.images.attach(img) }

        if manual.save
          render json: manual_detail(manual), status: :created
        else
          render_error(manual.errors.full_messages.join(", "))
        end
      end

      private

      def manual_summary(manual)
        {
          id: manual.id,
          property_name: manual.property_name,
          room_type: manual.room_type,
          status: manual.status,
          created_at: manual.created_at,
          updated_at: manual.updated_at
        }
      end

      def manual_detail(manual)
        {
          id: manual.id,
          client_code: manual.client_code,
          property_name: manual.property_name,
          room_type: manual.room_type,
          status: manual.status,
          manual_data: manual.manual_data,
          images: manual.images.map { |img| rails_blob_url(img) },
          created_at: manual.created_at,
          updated_at: manual.updated_at
        }
      end

      def rails_blob_url(blob)
        Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)
      end
    end
  end
end
