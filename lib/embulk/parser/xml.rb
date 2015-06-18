require "nokogiri"

module Embulk
  module Parser

    class XmlParserPlugin < ParserPlugin
      Plugin.register_parser("xml", self)

      def self.transaction(config, &control)
        schema = config.param("schema", :array)
        extra_schema = config.param("extra_schema", :array, default: [])
        schema_serialized = schema.inject({}) do |memo, s|
          memo[s["name"]] = s["type"]
          memo
        end
        extra_schema_serialized = extra_schema.inject({}) do |memo, s|
          memo[s["path"]] = {:name => s["name"], :type => s["type"]}
          memo
        end
        task = {
          :schema => schema_serialized,
          :extra_schema => extra_schema_serialized,
          :root_to_route => config.param("root", :string).split("/")
        }
        columns = schema.each_with_index.map do |c, i|
          Column.new(i, c["name"], c["type"].to_sym)
        end
        yield(task, columns)
      end

      def run(file_input)
        on_new_record = lambda {|record|
          @page_builder.add(record)
        }
        doc = RecordBinder.new(@task["root_to_route"], @task["schema"],
                               @task["extra_schema"], on_new_record)
        parser = Nokogiri::XML::SAX::Parser.new(doc)
        while file = file_input.next_file
          parser.parse(file.read)
          doc.clear
        end
        @page_builder.finish
      end
    end

    class RecordBinder  < Nokogiri::XML::SAX::Document

      def initialize(route, schema, extra_schema, on_new_record)
        @route = route
        @schema = schema
        @extra_schema = extra_schema
        @on_new_record = on_new_record
        @element_path = ""
        clear
        super()
      end

      def clear
        @find_route_idx = 0
        @enter = false
        @current_element_name = nil
        @current_data = new_map_by_schema
        @extra_data = {} # TODO init by method
        @element_path = ""
      end

      def start_element(name, attributes = [])
        if !@enter
          if name == @route[@find_route_idx]
            if @find_route_idx == @route.size - 1
              @enter = true
            else
              @find_route_idx += 1
            end
          end
        end
        @current_element_name  = name
        @current_element_name = name
        @element_path += "/" if @element_path.size > 0
        @element_path += "#{name}"
      end

      def characters(string)
        return if string.strip.size == 0
        @current_data[@current_element_name] ||= ""
        @current_data[@current_element_name] += string
      end

      def end_element(name, attributes = [])
        if @enter
          if name == @route.last
            @enter = false
            @on_new_record.call(@current_data.map{|k, v| v})
            @current_data = new_map_by_schema
          elsif @schema.key?(name)
            @current_data[name] = convert(@current_data[name], @schema[name])
          end
        end
        if @extra_schema && @extra_schema.key?(@element_path)
          # FIXME re-arrange data handle ...
          @extra_data[name] = convert(@current_data[name],
                                      @extra_schema[@element_path]["type"])
        end
        @current_element_name = nil
        pop_element_path
      end

      private

      def pop_element_path
        path_list = @element_path.split("/")
        path_list.delete_at(-1)
        @element_path = path_list.join("/")
      end

      def new_map_by_schema
        @schema.keys.inject({}) do |memo, k|
          memo[k] = nil
          memo
        end
      end

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
