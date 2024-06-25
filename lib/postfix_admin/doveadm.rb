require 'open3'
require 'shellwords'

module PostfixAdmin
  class Doveadm
    # doveadm-pw: https://doc.dovecot.org/3.0/man/doveadm-pw.1/
    CMD_DOVEADM_PW = "doveadm pw"

    # List all supported password schemes
    def self.schemes
      result = `#{CMD_DOVEADM_PW} -l`
      result.split
    end

    # Generate a password hash using `doveadm pw` command
    def self.password(password, scheme, rounds: nil, user_name: nil,
                      prefix: true)
      escaped_password = Shellwords.escape(password)
      escaped_scheme   = Shellwords.escape(scheme)

      cmd = "#{CMD_DOVEADM_PW} -s #{escaped_scheme} -p #{escaped_password}"

      # DIGEST-MD5 requires -u option (user name)
      if scheme == "DIGEST-MD5"
        escaped_user_name = Shellwords.escape(user_name)
        cmd << " -u #{escaped_user_name}"
      end

      if rounds
        escaped_rounds   = Shellwords.escape(rounds.to_s)
        cmd << " -r #{rounds}"
      end

      output, error, status = Open3.capture3(cmd)

      if status.success?
        res = output.chomp
        if prefix
          res
        else
          # Remove the prefix
          res.gsub("{#{escaped_scheme}}", "")
        end
      else
        raise Error, "#{CMD_DOVEADM_PW}: #{error}"
      end
    end
  end
end
