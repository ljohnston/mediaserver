import pytest

@pytest.mark.parametrize("pkg",
                         ['docker-ce',
                          'mergerfs',
                          'samba',
                          'snapraid'])
def test_packages(host, pkg):
    assert host.package(pkg).is_installed

def test_docker_running_and_enabled(host):
    docker = host.service("docker")
    assert docker.is_running
    assert docker.is_enabled

@pytest.mark.parametrize("container", ["plex", "mysql", "nextcloud"])
def test_docker_containers_running(host, container):
    assert host.docker(container).is_running
