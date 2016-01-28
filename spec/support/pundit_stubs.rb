module PunditStubs
  def allow_action(action, record)
    policy = ::Pundit::PolicyFinder.new(record).policy
    allow(policy).to receive(:new).with(any_args, record) { instance_double(policy, action => true) }
  end

  def disallow_action(action, record)
    policy = ::Pundit::PolicyFinder.new(record).policy
    allow(policy).to receive(:new).with(any_args, record) { instance_double(policy, action => false) }
  end
end
