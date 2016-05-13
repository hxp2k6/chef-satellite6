#
# Cookbook Name:: satellite6
# Spec:: server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'satellite6::server' do
  platforms = {
    'redhat' => {
      'versions' => ['6.6', '7.1']
    }
  }
  platforms.keys.each do |platform|
    platforms[platform]['versions'].each do |version|
      mypath = "spec/fixtures/fauxhai/#{platform}/#{version}.json"
      context "On #{platform} #{version}" do
        context 'When all attributes are default, on a satellite server' do
          cached(:chef_run) do
            ChefSpec::ServerRunner.new(platform: platform, version: version, path: mypath) do |node, server|
              loadfixtures(server)

              node.automatic['fqdn'] = 'satellite6.example.com'
            end.converge(described_recipe)
          end
          let(:answerstemplate) { chef_run.template('/etc/katello-installer/answers.katello-installer.yaml') }
          let(:rhsmtemplate) { chef_run.template('/etc/rhsm/rhsm.conf') }

          it 'converges successfully' do
            chef_run # This should not raise an error
          end
          packages = %w(
            katello
            pulp-admin-client
            pulp-rpm-admin-extensions
            pulp-rpm-handlers
            ruby193-rubygem-passenger-native
            foreman-postgresql
            katello-certs-tools
            mod_passenger
            puppet-server
            qpid-dispatch-router
            ruby193-rubygem-passenger-native
            rubygem-smart_proxy_pulp
            dhcp
            bind
            tftp-server
          )
          it "installs a #{packages.inspect} with the default action" do
            expect(chef_run).to install_package(packages)
          end
          it 'includes the selinux::default recipe' do
            expect(chef_run).to include_recipe('selinux::default')
          end
          it 'includes the ntp::default recipe' do
            expect(chef_run).to include_recipe('ntp::default')
          end
          it 'includes the iptables::default recipe' do
            expect(chef_run).to include_recipe('iptables::default')
          end
          it 'creates /etc/rhsm/rhsm.conf' do
            expect(chef_run).to create_template('/etc/rhsm/rhsm.conf').with(
              user: 'root',
              group: 'root'
            )
            expect(chef_run).to render_file('/etc/rhsm/rhsm.conf') \
              .with_content('Red Hat Subscription Manager Configuration File')
            expect(chef_run).to render_file('/etc/rhsm/rhsm.conf') \
              .with_content('Generated by Chef')
          end
          it 'creates /etc/katello-installer/answers.katello-installer.yaml' do
            expect(chef_run).to create_template('/etc/katello-installer/answers.katello-installer.yaml').with(
              user: 'root',
              group: 'root'
            )
            expect(chef_run).to render_file('/etc/katello-installer/answers.katello-installer.yaml') \
              .with_content('pulp_admin_password')
            expect(chef_run).to render_file('/etc/katello-installer/answers.katello-installer.yaml') \
              .with_content('dns_tsig_keytab')
          end
          it 'notifies the katello-installer' do
            expect(answerstemplate).to notify('execute[katello-installer]').to(:run).immediately
          end
          it 'notifies the rhsmcertd' do
            expect(rhsmtemplate).to notify('service[rhsmcertd]').to(:restart).immediately
            expect(rhsmtemplate).to notify('execute[repolist]').to(:run).immediately
          end
        end
      end
    end
  end
end
