# Load libraries from openstacklib here to simulate how they live together in a real puppet run
$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures', 'modules', 'openstacklib', 'lib'))
require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_user/openstack'

provider_class = Puppet::Type.type(:keystone_user).provider(:openstack)

authlist = ['--os-username', 'test', '--os-password', 'abc123', '--os-tenant-name', 'foo', '--os-auth-url', 'http://127.0.0.1:5000/v2.0']
authhash = {
  'username'    => 'test',
  'password'    => 'abc123',
  'tenant_name' => 'foo',
  'auth_url'    => 'http://127.0.0.1:5000/v2.0',
}

describe provider_class do

  describe 'when updating a user' do
    let(:user_attrs) do
      {
        :name         => 'foo',
        :ensure       => 'present',
        :enabled      => 'True',
        :tenant       => 'foo2',
        :email        => 'foo@foo.com',
        :password     => 'passwd',
        :auth         => authhash
      }
    end

    let(:resource) do
      Puppet::Type::Keystone_user.new(user_attrs)
    end

    let(:provider) do
      provider_class.new(resource)
    end

    before :each do |example|
      if example.metadata[:build_user_hash]
        provider_class.expects(:build_user_hash).returns(
          'foo' => {:id   => 'id', :name => 'foo', :tenant => 'foo2', :password => 'passwd'}
        )
      end
      if example.metadata[:del_user_hash]
        provider_class.expects(:build_user_hash).returns({})
      end
    end

    after :each do
      # reset global state
      provider_class.prefetch(nil)
    end

    describe '#create' do
      it 'creates a user', :build_user_hash do
        provider.class.stubs(:openstack)
                      .with('user', 'create', [['foo', '--enable', '--email', 'foo@foo.com', '--password', 'passwd', '--project', 'foo2'] + authlist])
        provider.create
        expect(provider.exists?).to be_truthy
      end
    end

    describe '#destroy', :del_user_hash do
      it 'destroys a user' do
        provider.class.stubs(:openstack)
                      .with('user', 'delete', [['foo'] + authlist])
        provider.destroy
        expect(provider.exists?).to be_falsey
      end
    end

    it 'should call user-password-update to change password' do
      provider.expects(:request).with('user', 'set', ['--password', 'newpassword'], 'foo', authhash)
      provider.password=('newpassword')
    end

    it 'should call user-update to change email' do
      provider.expects(:request).with('user', 'set', ['--email', 'bar@bar.com'], 'foo', authhash)
      provider.email=('bar@bar.com')
    end

    it 'should call user-update to set email to blank' do
      provider.expects(:request).with('user', 'set', ['--email', ''], 'foo', authhash)
      provider.email=('')
    end
  end
end
