require 'travis/api/v3/renderer/collection_renderer'

module Travis::API::V3
  class Renderer::Active < Renderer::CollectionRenderer
    type            :builds
    collection_key  :builds

    def representation
      :active
    end
  end
end
