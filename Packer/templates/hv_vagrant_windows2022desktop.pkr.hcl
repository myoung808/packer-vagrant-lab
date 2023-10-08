variable "admin_pass" {
	type = string
	default = "v@grant1"
}

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
	iso_checksum = "sha256:3E4FA6D8507B554856FC9CA6079CC402DF11A8B79344871669F0251535255325"
	iso_url = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
	boot_command = [
		"<wait><leftAlton>n<leftAltoff>",
		"<wait>i",
		"<wait10><down><leftAlton>n<leftAltoff>",
		"<wait><space><leftAlton>n<leftAltoff>",
		"<wait><down><enter>",
		"<wait5><leftAlton>n<leftAltoff>",
		"<wait3m>${var.admin_pass}<tab>${var.admin_pass}<enter>",
		"<wait><leftCtrlon><leftAlton><del><leftAltoff><leftCtrloff>",
		"<wait>${var.admin_pass}<enter>",
		"<wait30s><enter>",
		"<wait5><leftCtrlon><leftShifton><esc><leftShiftoff><leftCtrloff><wait><leftAlton>df<leftAltoff><enter><wait5>powershell<wait><enter>",
		"<wait5>Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0<enter>",
		"<wait30s>Set-Service sshd -StartupType Automatic<enter>",
		"<wait>Start-Service sshd<enter>",
		"<wait>New-ItemProperty -Path \"HKLM:\\SOFTWARE\\OpenSSH\" -Name DefaultShell -Value \"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -PropertyType String -Force<enter>",
		# disable password complexity for vagrant user
		"<wait5><leftCtrlon><leftShifton><esc><leftShiftoff><leftCtrloff><wait><leftAlton>f<leftAltoff><enter><wait5>gpedit.msc<enter>",
		"<wait5>w<right>se<right>a<right>p<wait><tab>p<wait><enter>s<enter>"
		#"<wait><leftAlton><f4><leftAltoff>"
	]
	cpus = "${var.cpus}"
	disk_size = "${var.disk_size}"
	memory = "${var.memory}"
	enable_dynamic_memory = true
	output_directory = "Windows2022Desktop"
	shutdown_command = "shutdown /s /t 0"
	switch_name = "Default Switch"
	vm_name = "Windows2022Desktop"
	ssh_username = "Administrator"
	ssh_password = "${var.admin_pass}"
	ssh_timeout = "15m"
}

build {
	sources = ["source.hyperv-iso.vm"]
	
	provisioner "powershell" {
		inline = [
			"Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -name \"fDenyTSConnections\" -value 0",
			"Enable-NetFirewallRule -DisplayGroup \"Remote Desktop\""
		]
	}

	provisioner "powershell" {
		inline = [
			"net user vagrant vagrant /add",
			"net localgroup administrators vagrant /add"
		]
	}
	
	provisioner "file" {
		source = "files\\vagrant.pub"
		destination = "C:\\ProgramData\\ssh\\administrators_authorized_keys"
	}
	
	provisioner "powershell" {
		inline = [
			"cd C:\\ProgramData",
			"icacls ssh /remove \"NT AUTHORITY\\Authenticated Users\""
		]
	}
	
	post-processor "shell-local" {
		inline = [
			"copy files\\metadata.json Windows2022Desktop\\metadata.json",
			"cd Windows2022Desktop",
			"tar.exe -cvzf ..\\..\\Vagrant\\windows2022desktop.box .\\*",
			"vagrant box remove windows2022desktop",
			"vagrant box add --name windows2022desktop ..\\..\\Vagrant\\windows2022desktop.box"
		]
	}
}
