
require 'open3'
require 'shellwords'

module PostfixAdmin
  class Doveadm
    def self.schemes
      result = `doveadm pw -l`
      result.split
    end

    def self.password(in_password, in_scheme)
      password = Shellwords.escape(in_password)
      scheme  = Shellwords.escape(in_scheme)
      stdin, stdout, stderr = Open3.popen3("doveadm pw -s #{scheme} -p #{password}")
      if stderr.readlines.to_s =~ /Fatal:/
        raise Error, stderr.readlines
      else
        stdout.readlines.first.chomp.gsub("{#{scheme}}", "")
      end
    end
  end
end
