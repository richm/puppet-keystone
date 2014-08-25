# Load libraries from openstacklib and aviator here to simulate how they live together in a real puppet run
$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures', 'modules', 'openstacklib', 'lib'))
$LOAD_PATH.push(File.join(File.dirname(__FILE__), '..', '..', '..', 'fixtures', 'modules', 'aviator', 'lib'))
require 'puppet'
require 'spec_helper'
require 'puppet/provider/keystone_tenant/aviator'
require 'vcr'

provider_class = Puppet::Type.type(:keystone_tenant).provider(:aviator)

describe provider_class do

  describe 'when updating a tenant' do

    let :tenant_attrs do
      {
        :name         => 'foo',
        :description  => 'foo',
        :ensure       => 'present',
        :enabled      => 'True',
        :auth         => {
          'username'    => 'admin',
          'password'    => 'fyby-tet',
          'tenant_name' => 'admin',
          'host_uri'    => 'http://192.168.11.4:35357/v2.0',
        }
      }
    end

    let :resource do
      Puppet::Type::Keystone_tenant.new(tenant_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    describe '#create' do
      it 'creates a tenant' do
        response = nil

        VCR.use_cassette('keystone_tenant/create') do
          # create is only called if resource does not exist
          # resource does not exist yet on this cassette
          provider.create
          response = provider.exists?
        end
        expect(response).to be_truthy
      end
    end

    describe '#destroy' do
      it 'destroys a tenant' do
        response = nil

        VCR.use_cassette('keystone_tenant/destroy') do
          # destroy is only called if resource exists
          # resource already exists on this cassette
          provider.destroy
          response = provider.exists?
        end

        expect(response).to be_falsey
      end

    end

    describe '#exists' do
      context 'when tenant exists' do
        response = nil

        subject(:response) do
          VCR.use_cassette('keystone_tenant/exists') do
            # resource should already exist on this cassette
            response = provider.exists?
          end
        end

        it { is_expected.to be_truthy }
      end

      context 'when tenant does not exist' do
        response = nil

        subject(:response) do
          VCR.use_cassette('keystone_tenant/not_exists') do
            # resource should not exist on this cassette
            response = provider.exists?
          end
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#instances' do
      it 'gets the right number of tenants' do
        instances = nil
        VCR.use_cassette('keystone_tenant/instances') do
          # there are four tenants on this cassette
          instances = provider.instances
        end
        expect(instances.count).to eq(4)
      end
    end

  end
end
