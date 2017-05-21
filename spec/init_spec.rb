# for serverspec documentation: http://serverspec.org/
require_relative 'spec_helper'

describe port(51678) do
  it { should be_listening }
end

describe docker_image('amazon/amazon-ecs-agent:latest') do
  it { should exist }
end

describe service('amazon-ecs-agent.service') do
  it { should be_running.under('systemd') }
  it { should be_enabled }
end

files = ['/var/log/ecs-agent.log','/etc/systemd/system/amazon-ecs-agent.service']

files.each do |file|
  describe file("#{file}") do
    it { should be_file }
  end
end
