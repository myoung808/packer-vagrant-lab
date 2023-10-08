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
		"<wait10><leftAlton>n<leftAltoff>",
		"<wait><space><leftAlton>n<leftAltoff>",
		"<wait><down><enter>",
		"<wait5><leftAlton>n<leftAltoff>",
		"<wait2m><down><up><enter>",
		"<wait>${var.admin_pass}<down>${var.admin_pass}<enter>",
		"<wait><enter>",
		"<wait5>15<enter>",
		"<wait>Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0<enter>",
		"<wait45s>Set-Service sshd -StartupType Automatic<enter>",
		"<wait>Start-Service sshd<enter>",
		"<wait>New-ItemProperty -Path \"HKLM:\\SOFTWARE\\OpenSSH\" -Name DefaultShell -Value \"C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe\" -PropertyType String -Force<enter>",
		# Disable Complex Password requirement for vagrant account
		"<wait>secedit.exe /export /cfg C:\\secconfig.ini<enter>",
		"<wait>notepad C:\\secconfig.ini<enter>",
		"<wait><leftCtrlon>f<leftCtrloff>PasswordComplexity<enter><esc><end><bs>0<leftCtrlon>s<leftCtrloff><leftAlton><f4><leftAltoff>",
		"<wait>secedit.exe /configure /db C:\\Windows\\security\\database\\newsecedit.sdb /cfg C:\\secconfig.ini /areas SECURITYPOLICY<enter>"
	]
	cpus = "${var.cpus}"
	disk_size = "${var.disk_size}"
	memory = "${var.memory}"
	enable_dynamic_memory = true
	output_directory = "Windows2022Core"
	shutdown_command = "shutdown /s /t 0"
	switch_name = "Default Switch"
	vm_name = "Windows2022Core"
	ssh_username = "Administrator"
	ssh_password = "${var.admin_pass}"
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
			"icacls.exe ssh /remove \"NT AUTHORITY\\Authenticated Users\""
		]
	}
	
	post-processor "shell-local" {
		inline = [
			"copy files\\metadata.json Windows2022Core\\metadata.json",
			"cd Windows2022Core",
			"tar.exe -cvzf ..\\..\\Vagrant\\windows2022core.box .\\*",
			"vagrant box remove windows2022core",
			"vagrant box add --name windows2022core ..\\..\\Vagrant\\windows2022core.box"
		]
	}
}