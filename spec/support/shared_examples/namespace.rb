RSpec.shared_examples "a namespace" do |namespace|
  let(:namespace) { namespace ? namespace : "" }

  def verify_namespace(object)
    (namespace.split("/").map(&:capitalize).join("::") + "::#{object.name}").constantize
  end

  def add_namespace(object)
    namespace + [object]
  end
end
