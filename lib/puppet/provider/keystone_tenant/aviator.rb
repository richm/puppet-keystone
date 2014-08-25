$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/feature/aviator'
require 'puppet/provider/aviator'

Puppet::Type.type(:keystone_tenant).provide(
  :aviator,
  :parent => Puppet::Provider::Aviator
) do

  def create
    request(session.identity_service, :create_tenant) do |params|
      params.name        = resource[:name]
      params.enabled     = sym_to_bool(resource[:enabled])
      params.description = resource[:description]
    end
  end


  def exists?
    return ! instance(resource[:name]).empty?
  end


  def destroy
    tenant = instance(resource[:name])
    tenant_id = tenant['id']
    request(session.identity_service, :delete_tenant) do |params|
      params.id = tenant_id
    end
    @instance = nil
  end


  def enabled=(value)
    tenant = instance(resource[:name])
    tenant_id = tenant['id']
    request(session.identity_service, :update_tenant) do |params|
      params.enabled = sym_to_bool(value)
      params.id = tenant_id
    end
  end


  def enabled
    tenant = instance(resource[:name])
    bool_to_sym(tenant['enabled'])
  end


  def description=(value)
    tenant = instance(resource[:name])
    tenant_id = tenant['id']
    request(session.identity_service, :update_tenant) do |params|
      params.description = value
      params.id = tenant_id
    end
  end


  def description
    tenant = instance(resource[:name])
    tenant['description']
  end


  def id
    tenant = instance(resource[:name])
    tenant['id']
  end


  def self.instances
    response = request(session.identity_service, :list_tenants)
    instances = response.body.hash['tenants']
    instances.collect do |instance|
      new(
        :name        => instance['name'],
        :ensure      => :present,
        :enabled     => instance['enabled'],
        :description => instance['description'],
        :id          => instance['id']
      )
    end
  end


  def instances
    response = request(session.identity_service, :list_tenants)
    instances = response.body.hash['tenants']
    instances
  end


  def instance(name)
    @instance ||= instances.select { |instance| instance['name'] == name }.first || {}
  end

  private

  # Helper functions to use on the pre-validated enabled field
  def bool_to_sym(bool)
    bool == true ? :true : :false
  end


  def sym_to_bool(sym)
    sym == :true ? true : false
  end

end
