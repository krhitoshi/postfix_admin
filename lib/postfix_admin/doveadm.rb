require 'open3'
require 'shellwords'

module PostfixAdmin
  class Doveadm
    # doveadm-pw: https://doc.dovecot.org/3.0/man/doveadm-pw.1/
    CMD_DOVEADM_PW = "doveadm pw"

    def self.schemes
      result = `#{CMD_DOVEADM_PW} -l`
      result.split
    end

    def self.password(in_password, in_scheme, prefix)
      password = Shellwords.escape(in_password)
      scheme = Shellwords.escape(in_scheme)
      cmd = "#{CMD_DOVEADM_PW} -s #{scheme} -p #{password}"
      output, error, status = Open3.capture3(cmd)

      if status.success?
        res = output.chomp
        if prefix
          res
        else
          res.gsub("{#{scheme}}", "")
        end
      else
        raise Error, "#{CMD_DOVEADM_PW}: #{error}"
      end
    end
  end
end
