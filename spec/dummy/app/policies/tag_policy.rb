# frozen_string_literal: true

class TagPolicy
  Scope = Struct.new(:user, :scope) do
    def resolve
      raise NotImplementedError
    end
  end

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    raise NotImplementedError
  end

  def show?
    raise NotImplementedError
  end

  def create?
    raise NotImplementedError
  end

  def update?
    raise NotImplementedError
  end

  def destroy?
    raise NotImplementedError
  end
end
