
# memory in MB
variable "memory" {
  type    = string
  default = "4096"
}

variable "cpus" {
  type    = string
  default = "2"
}

# disk size in MB
variable "disk_size" {
  type    = string
  default = "76800"
}

source "hyperv-iso" "vm" {
	communicator = "ssh"
	iso_checksum = "sha256:A4ACFDA10B18DA50E2EC50CCAF860D7F20B389DF8765611142305C0E911D16FD"
	iso_url = "https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso"
	boot_command = [
		"<enter>", # grub
		"<wait30s><enter>", # language
		"<wait><enter>", # install update
		"<wait><enter>", # keyboard
		"<wait><enter>", # install type
		"<wait><enter>", # network
		"<wait><enter>", # proxy
		"<wait10><enter>", # mirror
		"<wait><down><down><down><down><down><enter>",
		"<wait><enter>",
		"<wait><down><enter>",
		"<wait>vagrant<tab>vagrant<tab>vagrant<tab>vagrant<tab>vagrant<tab><enter>",
		"<wait><enter>",
		"<wait><enter><wait><down><down><enter>",
		"<wait><tab><wait><enter>",
		"<wait3m><tab><tab><enter>",
		"<wait5><enter>",
		"<wait1m>vagrant<enter><wait>vagrant<enter>",
		"<wait10>sudo apt -y install linux-azure<enter><wait>vagrant<enter>",
		"<wait3m><enter>",
		"<wait>reboot<enter>",
		""		
	]
	cpus = "${var.cpus}"
	disk_size = "${var.disk_size}"
	memory = "${var.memory}"
	enable_dynamic_memory = true
	output_directory = "Ubuntu2204"
	shutdown_command = "shutdown -h now"
	switch_name = "Default Switch"
	vm_name = "Ubuntu2204"
	ssh_username = "vagrant"
	ssh_password = "vagrant"
	#ssh_timeout = "15m"
	pause_before_connecting = "90s"
	
}

build {
	sources = ["source.hyperv-iso.vm"]
	
	provisioner "file" {
		source = "files\\vagrant.pub"
		destination = "/home/vagrant/.ssh/authorized_keys"
	}
	
	post-processor "shell-local" {
		inline = [
			"copy files\\metadata.json Ubuntu2204\\metadata.json",
			"cd Ubuntu2204",
			"tar.exe -cvzf ..\\..\\Vagrant\\ubuntu2204.box .\\*",
			"vagrant box remove ubuntu2204",
			"vagrant box add --name ubuntu2204 ..\\..\\Vagrant\\ubuntu2204.box"
		]
	}
}