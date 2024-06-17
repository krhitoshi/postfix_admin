require 'active_support/concern'

module HasPassword
  extend ActiveSupport::Concern

  # example: {CRAM-MD5}, {BLF-CRYPT}, {PLAIN}
  # return nil if no scheme prefix
  def scheme_prefix
    res = password&.match(/^\{.*?\}/)
    if res
      res[0]
    else
      nil
    end
  end
end
