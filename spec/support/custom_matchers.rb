# Add better debuggability to be_forbidden failures
RSpec::Matchers.define :be_forbidden do
  match(&:forbidden?)

  failure_message do |actual|
    "expected response to be forbidden but HTTP code was #{actual.status}." \
      " Response body was:\n" + actual.body
  end
end

# Add better debuggability to be_not_found failures
RSpec::Matchers.define :be_not_found do
  match(&:not_found?)

  failure_message do |actual|
    "expected response to be not_found but HTTP code was #{actual.status}." \
      " Response body was:\n" + actual.body
  end
end

# Add better debuggability to be_unprocessable failures
RSpec::Matchers.define :be_unprocessable do
  match(&:unprocessable?)

  failure_message do |actual|
    "expected response to be unprocessable but HTTP code was #{actual.status}." \
      " Response body was:\n" + actual.body
  end
end

# Add better debuggability to be_successful failures
RSpec::Matchers.define :be_successful do
  match(&:successful?)

  failure_message do |actual|
    "expected response to be successful but HTTP code was #{actual.status}." \
      " Response body was:\n" + actual.body
  end
end

# Add better debuggability to be_ok failures
RSpec::Matchers.define :be_ok do
  match(&:ok?)

  failure_message do |actual|
    "expected response to be ok but HTTP code was #{actual.status}." \
      " Response body was:\n" + actual.body
  end
end
