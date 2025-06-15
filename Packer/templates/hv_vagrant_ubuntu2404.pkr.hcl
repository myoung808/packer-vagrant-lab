
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
	iso_checksum = "sha256:d6dab0c3a657988501b4bd76f1297c053df710e06e0c3aece60dead24f270b4d"
	iso_url = "https://releases.ubuntu.com/24.04.2/ubuntu-24.04.2-live-server-amd64.iso"
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
		"<wait10>sudo -Hi<enter><wait>vagrant<enter>",
		"<wait>echo \"vagrant ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/vagrant<enter>",
		"<wait>apt -y install linux-azure ansible<enter>",
		"<wait3m><enter>",
		"<wait>reboot<enter>",
		""		
	]
	cpus = "${var.cpus}"
	disk_size = "${var.disk_size}"
	memory = "${var.memory}"
	enable_dynamic_memory = true
	output_directory = "Ubuntu2404"
	shutdown_command = "sudo shutdown -h now"
	switch_name = "Default Switch"
	vm_name = "Ubuntu2404"
	ssh_username = "vagrant"
	ssh_password = "vagrant"
	#ssh_timeout = "15m"
	pause_before_connecting = "30s"
	
}

build {
	sources = ["source.hyperv-iso.vm"]
	
	provisioner "file" {
		source = "files\\vagrant.pub"
		destination = "/home/vagrant/.ssh/authorized_keys"
	}
	
	post-processor "shell-local" {
		inline = [
			"copy files\\metadata.json Ubuntu2404\\metadata.json",
			"cd Ubuntu2404",
			"tar.exe -cvzf ..\\..\\Vagrant\\ubuntu2404.box .\\*",
			"vagrant box remove ubuntu2404",
			"vagrant box add --name ubuntu2404 ..\\..\\Vagrant\\ubuntu2404.box"
		]
	}
}