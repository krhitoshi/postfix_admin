
module PostfixAdmin
  class Doveadm
    def self.schemes
      result = `doveadm pw -l`
      result.split
    end

    def self.password(password, scheme)
      result = `doveadm pw -s #{scheme} -p #{password}`
      result.chomp.gsub("{#{scheme}}", "")
    end
  end
end
