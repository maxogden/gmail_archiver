require 'mail'
require 'message_formatter'
module GmailArchiver
  class FetchData
    attr_accessor :seqno, :uid, :envelope, :size, :flags, :mail

    def initialize(x)
      @seq = x.seqno
      @uid = x.attr['UID']
      @envelope = x.attr["ENVELOPE"]
      @size = x.attr["RFC822.SIZE"] # not sure what units this is
      @flags = x.attr["FLAGS"]  # e.g. [:Seen]
      @mail = Mail.new(x.attr['RFC822'])
    end

    def to_json
      obj = {
        :seq => @seq,
        :uid => @uid,
        :date => Time.parse(@envelope.date).utc.iso8601,
        :subject => format_subject(@envelope.subject),
        :from => format_recipients(@envelope.from),
        :to => format_recipients(@envelope.to),
        :body => message,
        :size => @size,
        :flags => @flags,
        :raw_mail => @mail.to_s
      }.to_json
    end

    def message
      formatter = MessageFormatter.new(@mail)
      message_text = <<-EOF
#{format_headers(formatter.extract_headers)}

#{formatter.process_body}
EOF
    end

    def format_subject(subject)
      Mail::Encodings.unquote_and_convert_to((subject || ''), 'UTF-8')
    end

    def format_recipients(recipients)
      recipients ? recipients.map{|m| [m.mailbox, m.host].join('@')} : ""
    end
    
    def format_parts_info(parts)
      lines = parts.select {|part| part !~ %r{text/plain}}
      if lines.size > 0
        "\n#{lines.join("\n")}"
      end
    end

    def format_headers(hash)
      lines = []
      hash.each_pair do |key, value|
        if value.is_a?(Array)
          value = value.join(", ")
        end
        lines << "#{key.gsub("_", '-')}: #{value}"
      end
      lines.join("\n")
    end

  end
end

# envelope.from # array
# envelope.to # array
# address_struct.name, mailbox, host , join @
# envelope.date
# envelope.subject
# subject = Mail::Encodings.unquote_and_convert_to((envelope.subject || ''), 'UTF-8')
#
