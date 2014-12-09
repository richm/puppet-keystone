$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..'))
require 'puppet/feature/aviator'
require 'puppet/provider/aviator'

Puppet::Type.type(:keystone_user).provide(
  :aviator,
  :parent => Puppet::Provider::Aviator
) do

  desc <<-EOT
    Provider that manages keystone users

    This provider makes a few assumptions/
      1. assumes that the admin endpoint can be accessed via localhost.
      2. Assumes that the admin token and port can be accessed from
         /etc/keystone/keystone.conf

    Does not support the ability to update the user's name
  EOT

  def self.prefetch(resource)
    # rebuild the cache for every puppet run
    @user_hash = nil
  end

  def self.user_hash
    @user_hash ||= build_user_hash
  end

  def user_hash
    self.class.user_hash
  end

  def self.instances
    user_hash.collect do |k, v|
      new(:name => k)
    end
  end

  def create
    request(session.identity_service, :create_user) do |params|
      params.name        = resource[:name]
      params.enabled     = resource[:enabled]
      if resource[:email]
        params.email     = resource[:email]
      end
      if resource[:password]
        params.password  = resource[:password]
      end
      if resource[:tenant]
        params.project  = resource[:tenant]
      end
      params.description = resource[:description]
    end
  end

  def exists?
    user_hash[resource[:name]]
  end

  def destroy
    request(session.identity_service, :delete_user) do |params|
      params.id = id
    end
  end

  def enabled
    user_hash[resource[:name]][:enabled]
  end

  def enabled=(value)
    request(session.identity_service, :update_user) do |params|
      params.enabled = value
      params.id = id
    end
  end

  def password
    # if we don't know a password we can't test it
    return nil if resource[:password] == nil
    # we can't get the value of the password but we can test to see if the one we know
    # about works, if it doesn't then return nil, causing it to be reset
    begin
      credentials = {
        :username => resource[:name],
        :password => resource[:password],
        :tenant_name => resource[:tenant],
        :host_uri => get_auth_url_from_keystone_file
      }
      session = get_authenticated_session(credentials)
    rescue Exception => e
      return nil if e.message =~ /Not Authorized/ or e.message =~ /HTTP 401/
      raise e
    end
    return resource[:password]
  end

  def password=(value)
    request(session.identity_service, :update_user) do |params|
      params.password = value
      params.id = id
    end
  end

  def tenant
    # TODO: this doesn't actually work because tenantId is (no longer?)
    # a property of the user entry - the best way to do this is to use
    # the keystone v3 api to list tenants for a user - so just leave
    # this as is
    return resource[:tenant] if resource[:ignore_default_tenant]
    user_id = user_hash[resource[:name]][:id]
    begin
      tenantId = self.class.get_keystone_object('user', user_id, 'tenantId')
    rescue
      tenantId = nil
    end
    if tenantId.nil? or tenantId == 'None' or tenantId.empty?
      tenant = 'None'
    else
      # this prevents is from failing if tenant no longer exists
      begin
        tenant = self.class.get_keystone_object('tenant', tenantId, 'name')
      rescue
        tenant = 'None'
      end
    end
    tenant
  end

  def tenant=(value)
    fail("tenant cannot be updated. Transition requested: #{user_hash[resource[:name]][:tenant]} -> #{value}")
  end

  def email
    user_hash[resource[:name]][:email]
  end

  def email=(value)
    request(session.identity_service, :update_user) do |params|
      params.email = value
      params.id = id
    end
  end

  def id
    user_hash[resource[:name]][:id]
  end

  private

    def self.build_user_hash
      hash = {}
      response = request(session.identity_service, :list_users)
      list = response.body.hash['users']
      list.collect do |user|
        password = 'nil'
        hash[user[1]] = {
          :id          => user['id'],
          :enabled     => user['enabled'],
          :email       => user['email'],
          :name        => user['name'],
          :tenant      => user['project'],
          :password    => password,
        }
      end
      hash
    end

end
