module PunditStubs
  def allow_action(record, action)
    policy = ::Pundit::PolicyFinder.new(record).policy
    record = record.kind_of?(Array) ? record.last : record
    allow(policy).to(
      receive(:new).with(any_args, record) { instance_double(policy, action => true) }
    )
  end

  def disallow_action(record, action)
    policy = ::Pundit::PolicyFinder.new(record).policy
    record = record.kind_of?(Array) ? record.last : record
    allow(policy).to(
      receive(:new).with(any_args, record) { instance_double(policy, action => false) }
    )
  end

  def stub_policy_actions(record, actions_and_return_values)
    policy = ::Pundit::PolicyFinder.new(record).policy
    record = record.kind_of?(Array) ? record.last : record
    allow(policy).to(
      receive(:new).with(any_args, record) do
        instance_double(policy).tap do |policy_double|
          actions_and_return_values.each do |action, is_allowed|
            allow(policy_double).to receive(action).and_return(is_allowed)
          end
        end
      end
    )
  end
end
