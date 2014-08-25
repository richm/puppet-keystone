require 'puppet/util/aviator'
Puppet::Type.newtype(:keystone_tenant) do

  desc 'This type can be used to manage keystone tenants.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the tenant.'
    newvalues(/\w+/)
  end

  newproperty(:enabled) do
    desc 'Whether the tenant should be enabled. Defaults to true.'
    newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
    defaultto(true)
    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newproperty(:description) do
    desc 'A description of the tenant.'
    defaultto('')
  end

  newproperty(:id) do
    desc 'Read-only property of the tenant.'
    validate do |v|
      raise(Puppet::Error, 'This is a read only property')
    end
  end

  Puppet::Util::Aviator.add_aviator_params(self)
end
