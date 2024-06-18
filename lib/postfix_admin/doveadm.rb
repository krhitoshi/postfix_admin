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

    def self.password(password, scheme, prefix, rounds: nil)
      escaped_password = Shellwords.escape(password)
      escaped_scheme   = Shellwords.escape(scheme)
      cmd = "#{CMD_DOVEADM_PW} -s #{escaped_scheme} -p #{escaped_password}"
      cmd << " -r #{rounds}" if rounds
      output, error, status = Open3.capture3(cmd)

      if status.success?
        res = output.chomp
        if prefix
          res
        else
          res.gsub("{#{escaped_scheme}}", "")
        end
      else
        raise Error, "#{CMD_DOVEADM_PW}: #{error}"
      end
    end
  end
end
