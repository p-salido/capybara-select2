require "capybara-select2/version"
require 'capybara/selectors/tag_selector'
require 'rspec/core'

module Capybara
  module Select2
    def select2(value, options = {})
      raise "Must pass a hash containing 'from' or 'xpath' or 'css'" unless options.is_a?(Hash) and [:from, :xpath, :css].any? { |k| options.has_key? k }

      if options.has_key? :xpath
        select2_container = find(:xpath, options[:xpath])
      elsif options.has_key? :css
        select2_container = find(:css, options[:css])
      else
        select_name = options[:from]
        select2_container = find("label", text: select_name).find(:xpath, '..').find(".select2-container")
      end

      # delay this a bit because it seems most times select2 is not
      # actually ready right away
      sleep 0.1

      # Open select2 field
      container = select2_container.find(".select2-choice, .select2-choices")
      if Capybara.current_driver == 'poltergeist'
        container.trigger('click')
      else
        container.click
      end

      if options.has_key? :search
        find(:xpath, "//body").find(".select2-search input.select2-search__field").set(value)
        page.execute_script(%|$("input.select2-search__field:visible").keyup();|)
        drop_container = ".select2-results"
      else
        drop_container = ".select2-drop"
      end

      [value].flatten.each do |value|
        begin
          find(:xpath, "//body").find("#{drop_container} li.select2-result-selectable", text: value).click
        rescue Capybara::ElementNotFound
          # it seems that sometimes the "open select2 field" click
          # would happen before select2 is initialized, hence
          # the dropdown wouldn't actually be opened; retry both operations
          container = select2_container.find(".select2-choice, .select2-choices")
          if Capybara.current_driver == 'poltergeist'
            container.trigger('click')
          else
            container.click
          end
          find(:xpath, "//body").find("#{drop_container} li.select2-result-selectable", text: value).click
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::Select2
  config.include Capybara::Selectors::TagSelector
end
