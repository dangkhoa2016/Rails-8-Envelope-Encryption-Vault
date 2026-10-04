module Vault
  class EnvParser
    KEY_PATTERN = /\A[A-Za-z_][A-Za-z0-9_]*\z/

    def self.parse(text)
      entries = []
      seen = {}
      text.to_s.each_line.with_index(1) do |raw, line_number|
        line = raw.strip
        next if line.empty? || line.start_with?("#")
        line = line.delete_prefix("export ").strip
        key, value = line.split("=", 2)
        raise ArgumentError, "line #{line_number}: expected KEY=VALUE" if value.nil?
        key = key.strip
        raise ArgumentError, "line #{line_number}: invalid key" unless key.match?(KEY_PATTERN)
        raise ArgumentError, "line #{line_number}: duplicate key #{key}" if seen[key]
        seen[key] = true
        entries << { "key" => key, "value" => unquote(value.strip) }
      end
      entries
    end

    def self.dump(entries)
      Array(entries).map do |entry|
        key = entry.fetch("key")
        value = entry.fetch("value").to_s
        rendered = value.match?(/[\s#"'\\]/) ? %Q("#{value.gsub("\\", "\\\\").gsub('"', '\\"').gsub("\n", "\\n")}") : value
        "#{key}=#{rendered}"
      end.join("\n") + "\n"
    end

    def self.unquote(value)
      if value.start_with?("\"") && value.end_with?("\"") && value.length >= 2
        value[1..-2].gsub("\\n", "\n").gsub('\\"', '"').gsub("\\\\", "\\")
      elsif value.start_with?("'") && value.end_with?("'") && value.length >= 2
        value[1..-2]
      else
        value
      end
    end
    private_class_method :unquote
  end
end
