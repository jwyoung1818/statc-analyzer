  class ImageBlock < AbstractFileBlock

    acts_as_content_block :taggable => true
    content_module :core
    has_attachment :file, :styles => {:thumb => "80x80"}
    validates_attachment_presence :file, :message => "You must upload a file"


    def self.display_name
      "Image"
    end

    def image
      file
    end

     # Override default behavior to handle STI class when looking up other versions of attachments.
    def attachable_type
      Attachment::FILE_BLOCKS
    end
  end
