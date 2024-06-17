require 'active_support/concern'

module ExistingTimestamp
  extend ActiveSupport::Concern

  class_methods do
    private

    def timestamp_attributes_for_create
      ["created"]
    end

    def timestamp_attributes_for_update
      ["modified"]
    end
  end
end
