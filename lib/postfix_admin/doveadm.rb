require 'open3'
require 'shellwords'

module PostfixAdmin
  class Doveadm
    CMD_DOVEADM_PW = "doveadm pw"

    def self.schemes
      result = `#{CMD_DOVEADM_PW} -l`
      result.split
    end

    def self.password(in_password, in_scheme, prefix)
      password = Shellwords.escape(in_password)
      scheme = Shellwords.escape(in_scheme)
      cmd = "#{CMD_DOVEADM_PW} -s #{scheme} -p #{password}"
      _stdin, stdout, stderr = Open3.popen3(cmd)

      if stderr.readlines.to_s =~ /Fatal:/
        raise Error, stderr.readlines
      else
        res = stdout.readlines.first.chomp
        if prefix
          res
        else
          res.gsub("{#{scheme}}", "")
        end
      end
    end
  end
end
