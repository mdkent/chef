
class Chef
  class Provider
    class RubyBlock < Chef::Provider
      def load_current_resource
        true
      end

      def action_create
        @new_resource.block.call
      end
    end
  end
end
