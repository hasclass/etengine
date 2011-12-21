# ResearchDataset holds all the values entered by researchers into the input tool.
# They can be accessed systematically by ETsource templates using "get".
#
#     get(households,hot_water,demand) # => 32.0
#
# gets are meant to be chained togeter.
#
#     # Transform a percentage (50%) into a factor (0.5)
#     get(households,hot_water,share,heating) / 100 
#
# To DRY up ETsource templates we can also create shortcuts or macros using "set".
#
#     # Transform a percentage (50%) into a factor (0.5)
#     set(hh_hot_water_heating_share, get(households,hot_water,share,heating) / 100)
#     get(hh_hot_water_heating_share)
# 
#
module InputTool
  class ResearchDataset
    
    attr_reader :values, :wizard_codes
    
    def initialize(saved_wizards_or_hash)
      if saved_wizards_or_hash.is_a?(Hash)
        @values = saved_wizards_or_hash
      else
        @wizard_codes = saved_wizards_or_hash.map(&:code)
        @values = saved_wizards_or_hash.inject({}) {|hsh,f| hsh.merge f.code => f.research_data_bucket}
      end
    end

    def self.area(area_code)
      new(InputTool::SavedWizard.area_code(area_code).all)
    end

    # Sets a shortcut for a value. Typically used in conjunction with multiple #get.
    #
    #     set(:hh_demand_bln, (get(households, demand_total) / BILLIONS) )
    #         `··· key ····´   `··· value ····························´
    #
    def shortcut(key, value)
      @values[key] = value
    end
    alias_method :set, :shortcut


    #     {:hh => 
    #       {:sector => {
    #         :coal  => {:needle => 1.0}, 
    #         :water => {:needle => 1.0}, 
    #         :gas   => {:something => {:needle => 3.0}}, ...
    #
    #     keys_that_contain(:hh, :sector, :needle)
    #     # => [:coal, :gas]
    #     keys_that_contain(:hh, :needle)
    #     # => [] 
    #
    def keys_that_contain(*args)
      needle = args.pop
      haystack = get(*args)

      return [] if haystack.nil?

      haystack.map do |possible_needle, hash|
        if hash.with_indifferent_access.has_key?(needle)
          possible_needle
        end
      end.compact
    end


    # Recursively retrieves a value from the input tool value hashes.
    # 
    #     {:foo => {:bar => {:baz => 3.0 }}}
    #
    #     get(:foo) # => nil
    #     get(:foo, default : 23.0) # => 23.0
    #
    #     get(:foo, :bar, :baz) # => 3.0
    #     get(:foo, :bar, :baz, default : 23.0) # => 3.0
    #     
    #
    # @option args [Float] :default Value returned if lookup value is undefined or nil
    # @option args [Float] :error   Value returned if exception happens
    #
    def get(*args)
      options = args.extract_options!

      value = nil
      hsh = @values.with_indifferent_access
      # iterate with keys through nested hash.
      # only assign value a number after iterating over *all* keys.
      args.each do |key|
        if hsh.has_key?(key)
          hsh = hsh[key]
          if args.last == key 
            value = hsh #unless hsh.is_a?(Hash)
          else
            hsh = hsh.with_indifferent_access
          end
        else
          # prevents from going further down, when a key was not found.
          #  
          #     values = {:foo => {:bar => 3}}
          #     get(:xyz, :foo, :bar) # => will return nil and not 3.
          hsh = {} 
        end
      end
      if value.blank?
        options[:default] 
      elsif value.respond_to?(:to_f)
        value.to_f
      else
        value
      end
    rescue => e
      options[:error] || raise(e)
    end
  end
end