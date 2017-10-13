module Less
  module Rails
    class ImportProcessor

      IMPORT_SCANNER = /@import\s*['"]([^'"]+)['"]\s*;/.freeze

      PATHNAME_FINDER = Proc.new { |scope, path|
        begin
          scope.resolve(path)
        rescue Sprockets::FileNotFound
          nil
        end
      }

      def initialize(filename, &block)
        @filename = filename
        @source   = block.call
      end

      def render(scope, locals)
        self.class.evaluate(@filename, @source, scope)
      end

      def self.evaluate(filename, source, scope)
        depend_on scope, source
        source
      end

      def self.call(input)
        filename = input[:filename]
        source   = input[:data]
        scope  = input[:environment].context_class.new(input)

        result = evaluate(filename, source, scope)
        scope.metadata.merge(data: result)
      end

      def self.default_mime_type
        'text/css'
      end

      def self.depend_on(scope, source, base=File.dirname(scope.logical_path))
        import_paths = source.scan(IMPORT_SCANNER).flatten.compact.uniq
        import_paths.each do |path|
          pathname = PATHNAME_FINDER.call(scope,path) || PATHNAME_FINDER.call(scope, File.join(base, path))
          scope.depend_on(pathname) if pathname && pathname.to_s.ends_with?('.less')
          depend_on scope, File.read(pathname), File.dirname(path) if pathname
        end
        source
      end

    end
  end
end
