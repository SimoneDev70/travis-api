module Travis::API::V3
  class Renderer::Repository < ModelRenderer
    representation(:minimal,  :id, :name, :slug)
    representation(:standard, :id, :name, :slug, :description, :github_id, :github_language, :active, :private, :owner, :default_branch, :starred, :managed_by_installation, :active_on_org)
    representation(:experimental, :id, :name, :slug, :description, :github_id, :github_language, :active, :private, :owner, :default_branch, :starred, :current_build, :last_started_build, :next_build_number)

    hidden_representations(:experimental)

    def self.available_attributes
      super.add('email_subscribed')
    end

    def active
      !!model.active
    end

    def default_branch
      return model.default_branch if include_default_branch?
      {
        :@type           => 'branch'.freeze,
        :@href           =>  Renderer.href(:branch, name: model.default_branch_name, repository_id: id, script_name: script_name),
        :@representation => 'minimal'.freeze,
        :name            => model.default_branch_name
      }
    end

    def current_build
      build = model.current_build
      build if access_control.visible? build
    end

    def last_started_build
      build = model.last_started_build
      build if access_control.visible? build
    end

    def starred
      return false unless user = access_control.user
      user.starred_repository_ids.include? id
    end

    def email_subscribed
      return false unless user = access_control.user
      !user.email_unsubscribed_repository_ids.include?(id)
    end

    def include_default_branch?
      return true if include? 'repository.default_branch'.freeze
      return true if include.any? { |i| i.start_with? 'branch'.freeze }
      return true if included.any? { |i| i.is_a? Models::Branch and i.repository_id == id and i.name == model.default_branch_name }
    end

    def owner
      return nil         if model.owner_type.nil?
      return model.owner if include_owner?
      owner_href = Renderer.href(owner_type.to_sym, id: model.owner_id, script_name: script_name)

      if included_owner? and owner_href
        { :@href => owner_href }
      else
        result = { :@type => owner_type, :id => model.owner_id, :login => model.owner_name }
        result[:@href] = owner_href if owner_href
        result
      end
    end

    def include_owner?
      return false if model.owner_type.nil?
      return false if included_owner?
      return true  if include? 'repository.owner'.freeze
      return true  if include.any? { |i| i.start_with? owner_type or i.start_with? 'owner'.freeze }
    end

    def included_owner?
      included.any? { |i| i.is_a? Model and i.class.polymorphic_name == model.owner_type and i.id == model.owner_id }
    end

    def owner_type
      @owner_type ||= model.owner_type.downcase if model.owner_type
    end

    def managed_by_installation
      model.managed_by_installation?
    end
  end
end
