module Qernel
  module Topology
    module Converter
      extend ActiveSupport::Concern

      SEPARATOR = ";"
      GROUPS_SEPARATOR = ','

      module InstanceMethods
        def topology_key
          code = self.code || self.full_key
          code = "00#{code}" if code.length == 1
          code = "0#{code}" if code.length == 2
          "#{code}"
        end

        def to_topology
          [
            [topology_key, key, sector_key, use_key, energy_balance_group, groups.join(GROUPS_SEPARATOR)].join(";\t"),
            inputs.map(&:to_topology),
            outputs.map(&:to_topology)
          ].join("\n")
        end
      end
      
      module ClassMethods
        def import(line)
          code, key, sector_key, use_key, energy_balance_group, groups = line.split(SEPARATOR).map(&:strip).map(&:to_sym)
          groups = groups.to_s.split(GROUPS_SEPARATOR).map(&:to_sym)
          code = code.to_s.scan(/\w+/).first.strip.gsub(/\s/,'').to_sym
          
          Qernel::Converter.new(code: code, key: key, sector_id: sector_key, use_id: use_key, groups: groups, energy_balance_group: energy_balance_group)
        end
      end
    end
    
    module Link
      extend ActiveSupport::Concern
      
      module InstanceMethods
      
        def topology_key
          "#{input.andand.topology_key} -- #{link_type.to_s[0]} --> #{output.andand.topology_key}"
        end

        def to_topology
          topology_key
        end
      end

      # Extract keys from a Slot Topology String
      #    Token.new("FOO-(HW) -- s --> (HW)-BAR") 
      #    => <Token carrier_key:HW, output_key:BAR, input_key:FOO, link_type: :share>
      #
      class Token
        attr_reader :input_key, :carrier_key, :output_key, :code, :link_type

        LINK_TYPES = {
          's' => :share,
          'f' => :flexible,
          'i' => :inversed_flexible,
          'd' => :dependent,
          'c' => :constant
        }

        def initialize(line)
          line.gsub!(/#.+/, '')
          line.strip!
          line.gsub!(/\s+/,'')
          @code = line

          input, output = Qernel::Slot::Token.find(line)

          raise "No Slots '#{line}'" if input.nil? or output.nil?
          raise "Carriers do not match in '#{line}'" if input.carrier_key != output.carrier_key
          @carrier_key = input.carrier_key
          @input_key   = input.converter_key
          @output_key  = output.converter_key

          @link_type   = LINK_TYPES[line.gsub(/\s+/,'').scan(/--(\w)-->/).flatten]
        end

        def self.find(line)
          if line.gsub(/\s/,'') =~ /\)--\w-->\(/
            new(line)
          else
            []
          end
        end
      end
    end
    
    module Slot
      extend ActiveSupport::Concern

      module InstanceMethods
        def topology_key
          if direction == :input
            "#{converter.topology_key}-#{carrier.to_topology}"
          else
            "#{carrier.to_topology}-#{converter.topology_key}"
          end
        end

        def to_topology
          arr = []
          if input?
            arr << topology_key if links.empty? && input?
            arr += links.map(&:to_topology)
          elsif output?
            arr << "#{topology_key} # #{links.length} links to: #{links.map{|l| l.parent.andand.topology_key}.join(', ')}"
          end
          arr.join("\n")
        end
      end

      # Extract keys from a Slot Topology String
      #    Token.new("(HW)-FOO") 
      #    t.converter_key # => :FOO
      #    t.carrier_key # => :HW
      #    t.direction # => :output
      #    t.code # => HW-FOO
      #
      class Token
        attr_reader :converter_key, :carrier_key, :direction, :code

        def initialize(line)
          @code = line.gsub(/#.+/, '').strip
          @converter_key, @carrier_key = if line.include?(')-')
            @direction = :output
            @code.split('-').reverse.map(&:to_sym)
          else
            @direction = :input
            @code.split('-').map(&:to_sym)
          end
          @carrier_key = @carrier_key.to_s.gsub(/[\(\)]/, '').to_sym
        end
        
        # @return [Array] all the slots in a given string.
        def self.find(line)
          (line.scan(/\w+-\(\w+\)|\(\w+\)-\w+/) || []).map{|t| new(t) }
        end
      end
    end
    
    module Carrier
      extend ActiveSupport::Concern

      module InstanceMethods        
        def topology_key
          # Code to return first letters upcased (hot_water => HW)
          # first,second = key.to_s.split("_")
          # carrier_code = first[0]+(second.andand[0] || first[1])
          # carrier_code.upcase
          key
        end

        # @return "(HW)"
        def to_topology
          "(#{topology_key})"
        end
      end   
    end    
  end
end