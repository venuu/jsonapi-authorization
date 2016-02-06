module AuthorizationStubs
  AUTHORIZER_CLASS = JSONAPI::Authorization::DefaultPunditAuthorizer

  def allow_operation(operation, *args, authorizer: instance_double(AUTHORIZER_CLASS))
    allow(authorizer).to receive(operation).with(*args).and_return(nil)

    allow(AUTHORIZER_CLASS).to receive(:new).with(Hash).and_return(authorizer)
    authorizer
  end

  def disallow_operation(operation, *args, authorizer: instance_double(AUTHORIZER_CLASS))
    allow(authorizer).to receive(operation).with(*args).and_raise(Pundit::NotAuthorizedError)

    allow(AUTHORIZER_CLASS).to receive(:new).with(Hash).and_return(authorizer)
    authorizer
  end

  def allow_operations(operation, operation_args)
    authorizer = instance_double(AUTHORIZER_CLASS)
    operation_args.each do |args|
      allow(authorizer).to receive(operation).with(*args).and_return(nil)
    end

    allow(AUTHORIZER_CLASS).to receive(:new).with(Hash).and_return(authorizer)
  end
end
