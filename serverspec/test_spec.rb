
require_relative 'spec_helper'

[ 'docker-ce',
  'mergerfs',
  'samba',
  'snapraid'
].each do |pkg|
  describe package(pkg) do
    it { should be_installed }
  end
end

describe service('docker') do
  it { should be_running }
end

describe docker_container('plex') do
  it { should be_running }
end

describe group('mediausers') do
  it { should exist }
end

[ 'alison',
  'ljohnston'
].each do |u|
  describe user(u) do
    it { should exist }
    it { should belong_to_group 'mediausers' }
  end
end

describe command('sync_music --help') do
  its(:exit_status) { should eq 0 }
end

describe command('sync_photos --help') do
  its(:exit_status) { should eq 0 }
end

describe command('historian_rsync --help') do
  its(:exit_status) { should eq 0 }
end

describe command('/test/test_mediaserver_itunes_sync.py') do
  its(:exit_status) { should eq 0 }
end

describe command('/test/test_mediaserver_photosyncapp_sync.py') do
  its(:exit_status) { should eq 0 }
end

describe command('/test/test_historian_rsync.py') do
  its(:exit_status) { should eq 0 }
end
