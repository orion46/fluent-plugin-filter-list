require 'fluent/plugin/output'
require 'fluent/plugin/out_filter_list/version'
require 'matcher'
require 'ip'

module Fluent
  module Plugin
    class FilterListOutput < Output
      include Matchers
      include IP

      Plugin.register_output('filter_list', self)

      helpers :event_emitter

      config_param :filter, :string, default: 'AC'
      config_param :key_to_filter, :string, default: nil
      config_param :patterns_file_path, :string, default: ''
      config_param :filter_empty, :bool, default: false

      config_section :retag, required: true, multi: false do
        config_param :tag, :string, default: nil
        config_param :add_prefix, :string, default: nil
      end

      config_section :retag_filtered, param_name: :retag_for_filtered, required: false, multi: false do
        config_param :tag, :string, default: nil
        config_param :add_prefix, :string, default: nil
      end

      def initialize
        super
      end

      def validate(retag)
        return unless retag
        raise Fluent::ConfigError, "missing tag and add_prefix" unless retag.tag || retag.add_prefix
        raise Fluent::ConfigError, "tag and add_prefix are mutually exclusive" if retag.tag && retag.add_prefix
      end

      def configure_prefixes
        @prefix_for_filtered_tag = @retag_for_filtered.add_prefix + '.' if @retag_for_filtered && @retag_for_filtered.add_prefix
        @prefix_for_filtered_tag = @retag_for_filtered && @retag_for_filtered.add_prefix ? @retag_for_filtered.add_prefix + '.' : ''
        @prefix = @retag && @retag.add_prefix ? @retag.add_prefix + '.' : ''
      end

      def configure(conf)
        super
        [@retag, @retag_for_filtered].each { |c| validate c }
        patterns = @patterns_file_path.empty? ? [] : File.readlines(@patterns_file_path).map(&:chomp).reject(&:empty?)
        @matcher = (@filter == 'IP') ? IPMatcher.new(patterns) : ACMatcher.new(patterns)
        configure_prefixes
      end

      def start
        super
        log.debug sprintf(
          "@retag: %s, @retag_for_filtered: %s, @prefix: %s, @prefix_for_filtered_tag: %s",
          @retag,
          @retag_for_filtered,
          @prefix,
          @prefix_for_filtered_tag || ''
        )
      end

      def multi_workers_ready?
        true
      end

      def process(tag, es)
        es.each do |time, record|
          target = record[@key_to_filter]
          log.debug "target: #{target}"
          # Do filter
          if target && (@matcher.matches?(target) || (@filter_empty && target.strip.empty?))
            if @retag_for_filtered
              t = @retag_for_filtered.tag || ((tag && !tag.empty?) ? @prefix_for_filtered_tag + tag : @retag_for_filtered.add_prefix)
              log.debug "re-emit with the tag: '#{t}', originally: '#{tag}'"
              router.emit(t, time, record)
            end
            next
          end
          t = @retag.tag || ((tag && !tag.empty?) ? @prefix + tag : @retag.add_prefix)
          log.debug "re-emit with the tag: '#{t}', originally: '#{tag}'"
          router.emit(t, time, record)
        end
      end
    end
  end
end
