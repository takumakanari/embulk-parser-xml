require "nokogiri"

module Embulk
  module Parser

    class XPathParserPlugin < ParserPlugin
      Plugin.register_parser("xpath", self)

      def self.transaction(config, &control)
        schema = config.param("schema", :array)
        task = {
          :schema => schema,
          :root => config.param("root", :string, default: "/"),
          :namespaces => config.param("namespaces", :hash, default: {})
        }
        columns = schema.each_with_index.map do |c, i|
          path, name = c["path"], c["name"]
          Column.new(i, name.nil? ? path : name, c["type"].to_sym)
        end
        yield(task, columns)
      end

      def run(file_input)
        while file = file_input.next_file
          data = file.read
          if !data.nil? && !data.empty?
            Nokogiri::XML(data).xpath(@task["root"], @task["namespaces"]).each do |item|
              dest = @task["schema"].inject([]) do |memo, s|
                es = item.xpath(s["path"], @namespaces)
                memo << convert(es.empty? ? nil : es.text, s["type"])
                memo
              end
              @page_builder.add(dest)
            end
          end
        end
        @page_builder.finish
      end

      private
      def convert(val, type)
        v = val.nil? ? "" : val
        case type
          when "string"
            v
          when "long"
            v.to_i
          when "double"
            v.to_f
          when "boolean"
            ["yes", "true", "1"].include?(v.downcase)
          when "timestamp"
            v.empty? ? nil : Time.strptime(v, c["format"])
          else
            raise "Unsupported type '#{type}'"
        end
      end
    end
  end
end
