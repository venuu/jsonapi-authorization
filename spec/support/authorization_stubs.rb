def allow_operation(operation, *args)
  authorizer = instance_double(JSONAPI::Authorization::Authorizer)
  allow(authorizer).to receive(operation).with(*args).and_return(nil)

  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(Hash).and_return(authorizer)
end

def disallow_operation(operation, *args)
  authorizer = instance_double(JSONAPI::Authorization::Authorizer)
  allow(authorizer).to receive(operation).with(*args).and_raise(Pundit::NotAuthorizedError)

  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(Hash).and_return(authorizer)
end

def allow_operations(operation, operation_args)
  authorizer = instance_double(JSONAPI::Authorization::Authorizer)
  operation_args.each do |args|
    allow(authorizer).to receive(operation).with(*args).and_return(nil)
  end

  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(Hash).and_return(authorizer)
end
