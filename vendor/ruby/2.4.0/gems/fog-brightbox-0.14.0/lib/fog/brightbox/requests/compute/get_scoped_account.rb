module Fog
  module Compute
    class Brightbox
      class Real
        # Requests details about currently scoped account
        #
        # @return [Hash] The JSON response parsed to a Hash
        def get_scoped_account(options = {})
          wrapped_request("get", "/1.0/account", [200], options)
        end
      end
    end
  end
end
