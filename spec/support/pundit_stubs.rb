module PunditStubs
  def allow_action(record, action)
    policy = ::Pundit::PolicyFinder.new(record).policy
    allow(policy).to(
      receive(:new).with(any_args, record) { instance_double(policy, action => true) }
    )
  end

  def disallow_action(record, action)
    policy = ::Pundit::PolicyFinder.new(record).policy
    allow(policy).to(
      receive(:new).with(any_args, record) { instance_double(policy, action => false) }
    )
  end
end
