module AuthorizationStubs
  AUTHORIZER_CLASS = JSONAPI::Authorization::DefaultPunditAuthorizer

  def allow_operation(operation, authorizer: instance_double(AUTHORIZER_CLASS), **kwargs)
    allow(authorizer).to receive(operation).with(**kwargs).and_return(nil)

    allow(AUTHORIZER_CLASS).to receive(:new).with(context: kind_of(Hash)).and_return(authorizer)
    authorizer
  end

  def disallow_operation(operation, authorizer: instance_double(AUTHORIZER_CLASS), **kwargs)
    allow(authorizer).to receive(operation).with(**kwargs).and_raise(Pundit::NotAuthorizedError)

    allow(AUTHORIZER_CLASS).to receive(:new).with(context: kind_of(Hash)).and_return(authorizer)
    authorizer
  end

  def allow_operations(operation, operation_args)
    authorizer = instance_double(AUTHORIZER_CLASS)
    operation_args.each do |args|
      allow(authorizer).to receive(operation).with(*args).and_return(nil)
    end

    allow(AUTHORIZER_CLASS).to receive(:new).with(context: kind_of(Hash)).and_return(authorizer)
  end
end
