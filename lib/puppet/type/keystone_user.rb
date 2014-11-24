require 'puppet/util/aviator'
Puppet::Type.newtype(:keystone_user) do

  desc <<-EOT
    This is currently used to model the creation of
    keystone users.

    It currently requires that both the password
    as well as the tenant are specified.
  EOT

# TODO support description??

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the user.'
    newvalues(/\S+/)
  end

  newparam(:ignore_default_tenant, :boolean => true) do
    desc <<-EOT
      If this is set, do not acutally perform a tenant lookup,
      just use the value of tenant set in the user.
      Defaults to false, meaning the tenant will be looked up
    EOT
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
    defaultto(false)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:enabled) do
    desc 'Whether the user should be enabled. Defaults to true.'
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false)
    defaultto(true)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:password) do
    newvalues(/\S+/)
    def change_to_s(currentvalue, newvalue)
      if currentvalue == :absent
        return "created password"
      else
        return "changed password"
      end
    end

    def is_to_s( currentvalue )
      return '[old password redacted]'
    end

    def should_to_s( newvalue )
      return '[new password redacted]'
    end
  end

  newproperty(:tenant) do
    newvalues(/\S+/)
  end

  newproperty(:email) do
    newvalues(/^(\S+@\S+)|$/)
  end

  newproperty(:id) do
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  autorequire(:keystone_tenant) do
    self[:tenant]
  end

  # we should not do anything until the keystone service is started
  autorequire(:service) do
    ['keystone']
  end

  auth_param_doc=<<EOT
If no other credentials are present, the provider will search in
/etc/keystone/keystone.conf for an admin token and auth url.
EOT
  Puppet::Util::Aviator.add_aviator_params(self, auth_param_doc)
end
