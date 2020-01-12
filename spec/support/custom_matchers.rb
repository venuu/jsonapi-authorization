# Add better debuggability to be_forbidden failures
RSpec::Matchers.define :be_forbidden do
  match(&:forbidden?)

  failure_message do |actual|
    debug_text_for_failure('forbidden', response: actual, last_request: last_request)
  end
end

# Add better debuggability to be_not_found failures
RSpec::Matchers.define :be_not_found do
  match(&:not_found?)

  failure_message do |actual|
    debug_text_for_failure('not_found', response: actual, last_request: last_request)
  end
end

# Add better debuggability to be_unprocessable failures
RSpec::Matchers.define :be_unprocessable do
  match(&:unprocessable?)

  failure_message do |actual|
    debug_text_for_failure('unprocessable', response: actual, last_request: last_request)
  end
end

# Add better debuggability to be_successful failures
RSpec::Matchers.define :be_successful do
  match(&:successful?)

  failure_message do |actual|
    debug_text_for_failure('successful', response: actual, last_request: last_request)
  end
end

# Add better debuggability to be_ok failures
RSpec::Matchers.define :be_ok do
  match(&:ok?)

  failure_message do |actual|
    debug_text_for_failure('ok', response: actual, last_request: last_request)
  end
end

def debug_text_for_failure(expected, response:, last_request:)
  debug_text = "expected response to be #{expected} but HTTP code was #{response.status}."
  debug_text += " Last request was #{last_request.request_method} to #{last_request.fullpath}"
  unless last_request.get?
    debug_text += " with body:\n" + last_request.body.read
  end
  debug_text += "\nResponse body was:\n" + response.body
  debug_text
end
