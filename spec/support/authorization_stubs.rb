def allow_operation(operation)
  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(any_args) do
    instance_double(JSONAPI::Authorization::Authorizer, operation => nil)
  end
end

def disallow_operation(operation)
  raising_double = instance_double(JSONAPI::Authorization::Authorizer)
  allow(raising_double).to receive(operation).and_raise(Pundit::NotAuthorizedError)
  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(any_args) do
    raising_double
  end
end
