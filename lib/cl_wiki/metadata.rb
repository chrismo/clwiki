module ClWiki
  class Metadata
    def self.split_file_contents(content)
      idx = content =~ /\n{3}/m
      metadata = []

      if idx
        metadata = content[0..(idx - 1)].split(/\n/)
        valid_metadata?(metadata) ? content = content[(idx + 3)..-1] : metadata = []
      end
      [self.new(metadata), content]
    end

    def self.valid_metadata?(lines)
      lines.map { |ln| ln.scan(/\A(\w+):?/) }.flatten.
        map { |k| supported_keys.include?(k) }.uniq == [true]
    end

    def self.supported_keys
      %w[mtime encrypted owner]
    end

    def initialize(lines = [])
      @hash = {}
      @keys = Metadata.supported_keys
      parse_lines(lines)
    end

    def [](key)
      @hash[key]
    end

    def []=(key, value)
      raise "Unexpected key: #{key}" unless @keys.include?(key)

      @hash[key] = value
    end

    def has?(key)
      @hash.key?(key)
    end

    def to_s
      @hash.collect { |k, v| "#{k}: #{v}" }.join("\n") + "\n\n\n"
    end

    def to_h
      @hash
    end

    private

    def parse_lines(lines)
      lines.each do |ln|
        key, value = ln.split(': ')
        @hash[key] = value.chomp if @keys.include?(key)
      end
    end
  end
end
