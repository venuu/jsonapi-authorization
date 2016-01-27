def allow_operation(operation)
  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(any_args) do
    double(operation => nil)
  end
end

def disallow_operation(operation)
  raising_double = double
  allow(raising_double).to receive(operation).and_raise(Pundit::NotAuthorizedError)
  allow(JSONAPI::Authorization::Authorizer).to receive(:new).with(any_args) do
    raising_double
  end
end
