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
        select2_container.find(".select2-selection").click

      if options.has_key? :search
        find(:xpath, "//body").find(".select2-search input.select2-search__field").set(value)
        page.execute_script(%|$("input.select2-search__field:visible").keyup();|)
        drop_container = ".select2-results"
      else
        # select2 version 4.0
        drop_container = ".select2-dropdown"
      end

      [value].flatten.each do |value|
        retried = false
        begin
          # select2 version 4.0
          container = find(:xpath, "//body").find(drop_container)
          options = container.find_all("li.select2-results__option")
          found = false
          options.each do |option|
            if option.text.strip == value
              option.click
              found = true
              break
            end
          end
          unless found
            raise "Did not find an option with text #{text}"
          end
        rescue Capybara::ElementNotFound
          # it seems that sometimes the "open select2 field" click
          # would happen before select2 is initialized, hence
          # the dropdown wouldn't actually be opened; retry both operations
          if retried
            raise
          else
            retried = true
            retry
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::Select2
  config.include Capybara::Selectors::TagSelector
end
