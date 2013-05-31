
module PostfixAdmin
  class Doveadm
    def self.schemes
      result = `doveadm pw -l`
      result.split
    end
  end
end
