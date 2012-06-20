# == Schema Information
#
# Table name: inputs
#
#  id                :integer(4)      not null, primary key
#  name              :string(255)
#  key               :string(255)
#  keys              :text
#  attr_name         :string(255)
#  share_group       :string(255)
#  start_value_gql   :string(255)
#  min_value_gql     :string(255)
#  max_value_gql     :string(255)
#  min_value         :float
#  max_value         :float
#  start_value       :float
#  created_at        :datetime
#  updated_at        :datetime
#  update_type       :string(255)
#  unit              :string(255)
#  factor            :float
#  label             :string(255)
#  comments          :text
#  label_query       :string(255)
#  updateable_period :string(255)     default("future"), not null
#  query             :text
#  v1_legacy_unit    :string(255)
#
# v1_legacy_unit is appended to the value provided by the user, and defines whether it
# is growth_rate (%y) or total growth (%) or absolute value ("")
#

class Input < ActiveRecord::Base
  attr_accessor :lookup_id, :dependent_on

  include InMemoryRecord

  validates :updateable_period, :presence => true,
                                :inclusion => %w[present future both before]

  ATTRIBUTES = [
    :id,
    :key,
    :attr_name,
    :comments,
    :factor,
    :keys,
    :label,
    :label_query,
    :max_value,
    :max_value_gql,
    :min_value,
    :min_value_gql,
    :name,
    :query,
    :share_group,
    :start_value,
    :start_value_gql,
    :unit,
    :update_type,
    :updateable_period,
    :v1_legacy_unit,
    :dependent_on
  ]

  def self.load_records
    h = {}
    Etsource::Loader.instance.inputs.each do |input|
      h[input.lookup_id]      = input
      h[input.lookup_id.to_s] = input
    end
    h
  end

  def self.with_share_group
    all.select{|input| input.share_group.present?}
  end

  def self.in_share_group(q)
    all.select{|input| input.share_group == q}
  end

  def self.by_name(q)
    q.present? ? all.select{|input| input.key.include?(q)} : all
  end

  def force_id(new_id)
    self.lookup_id = new_id
  end

  def self.before_inputs
    @before_inputs ||= all.select(&:before_update?)
  end

  def self.inputs_grouped
    @inputs_grouped ||= Input.with_share_group.group_by(&:share_group)
  end

  # i had to resort to a class method for "caching" procs
  # as somewhere inputs are marshaled (where??)
  def self.memoized_rubel_proc_for(input)
    @rubel_proc ||= {}
    @rubel_proc[input.lookup_id] ||= (input.rubel_proc)
  end

  def rubel
    # use memoized_rubel_proc_for for faster updates (50% increase)
    # rubel_proc
    self.class.memoized_rubel_proc_for(self)
  end

  def rubel_proc
    query and Gquery.rubel_proc(query)
  end

  def before_update?
    updateable_period == 'before'
  end

  def updates_present?
    updateable_period == 'present' || updateable_period == 'both'
  end

  def updates_future?
    updateable_period == 'future' || updateable_period == 'both'
  end

  # make as_json work
  def id
    self.lookup_id
  end

  def as_json(options={})
    super(
      :methods => [:id, :max_value, :min_value, :start_value]
    )
  end

  def client_values(gql)
    {
      lookup_id => {
        :max_value   => max_value_for(gql),
        :min_value   => min_value_for(gql),
        :start_value => start_value_for(gql),
        :full_label  => full_label_for(gql),
        :disabled    => disabled_in_current_area?(gql)
      }
    }
  end

  # This creates a giant hash with all value-related attributes of the inputs. Some inputs
  # require dynamic values, though. Check #dynamic_start_values
  #
  # @param [Gql::Gql the gql the query should run against]
  #
  def self.static_values(gql)
    Input.all.inject({}) do |hsh, input|
      begin
        hsh.merge input.client_values(gql)
      rescue => ex
        Rails.logger.warn("Input#static_values for input #{input.lookup_id} failed: #{ex}")
        Airbrake.notify(
          :error_message => "Input#static_values for input #{input.lookup_id} failed: #{ex}",
          :backtrace => caller,
          :parameters => {:input => input, :api_scenario => gql.scenario }) unless
           APP_CONFIG[:standalone]

        hsh
      end
    end
  end

  # See #static_values
  #
  def self.dynamic_start_values(gql)
    Input.all.select(&:dynamic_start_value?).inject({}) do |hsh, input|
      begin
        hsh.merge input.lookup_id => {
          :start_value => input.start_value_for(gql)
        }
      rescue => ex
        Rails.logger.warn("Input#dynamic_start_values for input #{input.lookup_id} failed for api_session_id #{gql.scenario.id}. #{ex}")
        Airbrake.notify(
          :error_message => "Input#dynamic_start_values for input #{input.lookup_id} failed for api_session_id #{gql.scenario.id}",
          :backtrace => caller,
        :parameters => {:input => input, :api_scenario => gql.scenario }) unless APP_CONFIG[:standalone]
        hsh
      end
    end
  end

  def full_label_for(gql)
    "#{gql.query("present:#{label_query}").round(2)} #{label}".html_safe unless label_query.blank?
  end

  def start_value_for(gql)
    gql_query = self[:start_value_gql]
    if !gql_query.blank? and result = gql.query(gql_query)
      result * factor
    else
      self[:start_value]
    end
  end

  def min_value_for(gql)
    min_value = min_value_for_current_area(gql)
    if min_value.present?
      min_value * factor
    elsif gql_query = self[:min_value_gql] and !gql_query.blank?
      gql.query(gql_query)
    else
      self[:min_value] || 0
    end
  end

  def max_value_for(gql)
    max_value = max_value_for_current_area(gql)
    if max_value.present?
      max_value * factor
    elsif
      gql_query = self[:max_value_gql] and !gql_query.blank?
      gql.query(gql_query)
    else
      self[:max_value] || 0
    end
  end

  def dynamic_start_value?
    self[:start_value_gql] && self[:start_value_gql].match(/^future:/) != nil
  end

  #############################################
  # Area Dependent min / max / fixed settings
  #############################################


  def min_value_for_current_area(gql = nil)
    area_input_values(gql).andand["min"]
  end

  def max_value_for_current_area(gql = nil)
    area_input_values(gql).andand["max"]
  end

  def disabled_in_current_area?(gql = nil)
    if gql.scenario.area_input_values['disabled']
      true
    elsif dependent_on.present?
      return true if !gql.scenario.area[dependent_on]
    end
    false
  end

  # this loads the hash with area dependent settings for the current inputs object
  def area_input_values(gql)
    gql.scenario.area_input_values[id]
  end

end
