
require 'open3'
require 'shellwords'

module PostfixAdmin
  class Doveadm
    def self.schemes
      result = `#{self.command_name} -l`
      result.split
    end

    def self.password(in_password, in_scheme, prefix)
      password = Shellwords.escape(in_password)
      scheme = Shellwords.escape(in_scheme)
      _stdin, stdout, stderr = Open3.popen3("#{self.command_name} -s #{scheme} -p #{password}")

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

    def self.command_name
      begin
        Open3.capture3("doveadm pw -l")[2].exited?
        "doveadm pw"
      rescue Errno::ENOENT
        "dovecotpw"
      end
    end
  end
end
