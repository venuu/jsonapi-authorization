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
