Vagrant.configure("2") do |config|
  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  config.vm.provision :shell, :inline => $BOOTSTRAP_SCRIPT # see below
  config.vm.network :forwarded_port, guest: 8080, host: 8080
end

$BOOTSTRAP_SCRIPT = <<EOF
	set -e # Stop on any error

	# --------------- SETTINGS ----------------
	# Other settings
	export DEBIAN_FRONTEND=noninteractive

	# --------------- APT-GET REPOS ----------------
	# Install prereqs
	sudo apt-get update
	sudo apt-get install -y python-software-properties
	sudo add-apt-repository ppa:chris-lea/node.js
	sudo apt-get update
	sudo apt-get install -y python-dev libmysqlclient-dev libpq-dev python-pip
	sudo apt-get install -y mongodb coffeescript nodejs
EOF
