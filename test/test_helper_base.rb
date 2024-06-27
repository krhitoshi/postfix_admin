# common methods for tests and specs

def setup_db_connection
  database = if ENV["CI"]
               "mysql2://root:ScRgkaMz4YwHN5dyxfQj@127.0.0.1:13306/postfix_test"
             else
               "mysql2://root:ScRgkaMz4YwHN5dyxfQj@db:3306/postfix_test"
             end
  ENV["DATABASE_URL"] = database
  ActiveRecord::Base.establish_connection(database)
end

def db_reset
  DomainAdmin.delete_all
  Mailbox.delete_all
  Alias.delete_all
  Domain.without_all.delete_all
  Admin.delete_all
end

# Returns STDOUT and STDERR without rescuing SystemExit
def capture_base(&block)
  begin
    $stdout = StringIO.new
    $stderr = StringIO.new

    block.call
    out = $stdout.string
    err = $stderr.string
  ensure
    $stdout = STDOUT
    $stderr = STDERR
  end

  [out, err]
end
alias silent capture_base

# Returns STDOUT or STDERR as String suppressing both STDOUT and STDERR.
# Raises StandardError when tests unexpectedly exit.
def capture(stream = :stdout, &block)
  out, err = capture_base do
    block.call
    # Raises SystemExit with STDERR when a test unexpectedly exits.
  rescue SystemExit => e
    message = $stderr.string
    message += e.message
    raise StandardError, message
  end

  case stream
  when :stdout
    out
  when :stderr
    err
  else
    raise "MUST NOT HAPPEN"
  end
end

# Returns STDERR when application exits suppressing STDOUT
def exit_capture(&block)
  _out, err = capture_base do
    block.call
  rescue SystemExit
    # do nothing
  end
  err
end

def parse_table(text)
  inside_table = false
  res = {}
  text.each_line do |line|
    if line.start_with?("+-")
      inside_table = !inside_table
      next
    end

    next unless inside_table
    elems = line.chomp.split("|").map(&:strip)[1..]
    res[elems.first] = elems.last
  end

  res
end
