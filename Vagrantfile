# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_NAME    = ENV.fetch("BOX_NAME",         "ubuntu")
BOX_URI     = ENV.fetch("BOX_URI",          "http://files.vagrantup.com/precise64.box")
BOX_IP      = ENV.fetch("BOX_IP",           "11.11.11.2")
BOX_MEM     = ENV.fetch("BOX_MEM",          "1024")
BOX_CPUS    = ENV.fetch("BOX_CPUS",         "2")
VF_BOX_URI  = ENV.fetch("BOX_URI",          "http://files.vagrantup.com/precise64_vmware_fusion.box")
SHARED_DIRS = ENV.fetch("BOX_SHARED_DIRS",  "").strip.split(" ")

def share_dirs
  lambda { |config|
    if SHARED_DIRS.any?
      SHARED_DIRS.each do |shared_dir|
        config.vm.synced_folder(
          File.expand_path(shared_dir),
          "/mnt/#{File.basename(shared_dir)}",
          :nfs => true
        )
      end
    end
  }
end

Vagrant::Config.run do |config|
  # Setup virtual machine box. This VM configuration code is always executed.
  config.vm.box       = BOX_NAME
  config.vm.box_url   = BOX_URI
  provisioning_script = ["export DEBIAN_FRONTEND=noninteractive"]

  provision_docker = [
    "apt-get update -q",
    "apt-get install -q -y linux-image-generic-lts-raring",
    "wget -q -O - https://get.docker.io/gpg | apt-key add -",
    "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list",
    "apt-get update -q; apt-get install -q -y --force-yes lxc-docker",
    'sed -i "s/respawn.*/&\n\nenv http_proxy=\"http:\/\/proxy.intra.bt.com:8080\"\nenv https_proxy=\"http:\/\/proxy.intra.bt.com:8080\"/" /etc/init/docker.conf',
    'service docker restart'
  ]

  provision_dockerize = [
    %{apt-get install -q -y git-core},
    %{dockerize_source="https://gitlab.nat.bt.com/rupert/dockerize/repository/archive"},
    %{dockerize_dir="/usr/local/src/dockerize.git"},
    %{dockerize_bin="${dockerize_dir}/bin/dockerize"},
    %{if [[ ! -e $dockerize_bin ]]; then wget -q --no-check-certificate -O - "${dockerize_source}" | tar -C /usr/local/src -zxv; fi},
    %{if [[ $(sudo grep -c "$dockerize_bin init" /root/.profile) == 0 ]]; then sudo echo 'eval \"$(/usr/local/src/dockerize.git/bin/dockerize init -)\"' >> /root/.profile; fi},
    %{if [[ $(sudo grep -c "$dockerize_bin init" /home/vagrant/.profile) == 0 ]]; then sudo echo 'eval \"$(/usr/local/src/dockerize.git/bin/dockerize init -)\"' >> /home/vagrant/.profile; fi},
  ]

  provision_app = [
    "sudo touch /root/.no_prompting_for_git_credentials",
    "sudo touch /home/vagrant/.no_prompting_for_git_credentials",
    "sudo -i dockerize boot rupert/sinatra_docker_test:master sinatra_docker_test",
    "if [[ $? = 0 ]]; then sudo -i echo \"sinatra_docker_test successfully started, available on http://#{BOX_IP}:$(sudo -i dockerize show sinatra_docker_test Tcp | awk '{ print $2 }')\"; fi",
  ]

  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    provisioning_script += provision_docker
    provisioning_script += provision_dockerize
    provisioning_script += provision_app
    provisioning_script << %{echo "\nVM ready!\n"}
  end

  config.vm.provision :shell, :inline => provisioning_script.join("\n")
end

# Providers were added on Vagrant >= 1.1.0
Vagrant::VERSION >= "1.1.0" and Vagrant.configure("2") do |config|
  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box     = BOX_NAME
    override.vm.box_url = VF_BOX_URI

    # Sharing dirs over NFS requires a private network
    config.vm.network(:private_network, :ip => BOX_IP)
    override.vm.synced_folder(".", "/vagrant", :disabled => true)
    f.vmx["displayName"] = "hi_sinatra"
  end

  config.vm.provider :virtualbox do |vb|
    config.vm.box     = BOX_NAME
    config.vm.box_url = BOX_URI

    # Sharing dirs over NFS requires a private network
    config.vm.network(:private_network, :ip => BOX_IP)
    config.vm.synced_folder(".", "/vagrant", :disabled => true)
    share_dirs.call(config)
    vb.customize ["modifyvm", :id, "--ioapic",  "on"]
    vb.customize ["modifyvm", :id, "--memory",  BOX_MEM]
    vb.customize ["modifyvm", :id, "--cpus",    BOX_CPUS]
  end
end

