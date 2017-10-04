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
              dest = @task["schema"].inject([]) do |memo, schema|
                es = item.xpath(schema["path"], @namespaces)
                memo << convert(es.empty? ? nil : es.map(&:text), schema)
                memo
              end
              @page_builder.add(dest)
            end
          end
        end
        @page_builder.finish
      end

      private
      def convert(val, schema)
        v = if schema["type"] == "json"
          val.nil? ? nil : val
        else
          val.nil? ? "" : val.join("")
        end
        case schema["type"]
        when "string", "json"
          v
        when "long"
          v.to_i
        when "double"
          v.to_f
        when "boolean"
          ["yes", "true", "1"].include?(v.downcase)
        when "timestamp"
          v.empty? ? nil : Time.strptime(v, schema["format"])
        else
          raise "Unsupported type '#{type}'"
        end
      end
    end
  end
end
