class BlobImageWrapper
  attr_reader :original_filename, :content_type

  def initialize(attachment)
    @attachment = attachment
    @original_filename = attachment.filename.to_s
    @content_type = attachment.content_type
    @tempfile = nil
  end

  def tempfile
    @tempfile ||= begin
      tmp = Tempfile.new(["blob_", File.extname(@original_filename)])
      tmp.binmode
      @attachment.download { |chunk| tmp.write(chunk) }
      tmp.rewind
      tmp
    end
  end

  def size
    @attachment.byte_size
  end

  def rewind
    @tempfile&.rewind
  end

  def close
    return unless @tempfile

    @tempfile.close
    @tempfile.unlink
    @tempfile = nil
  end
end
