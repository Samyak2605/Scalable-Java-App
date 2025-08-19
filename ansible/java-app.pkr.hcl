variable "ami_id" {
  type        = string
  default     = "ami-03f65b8614a860c29"  # Ubuntu 20.04 LTS in us-west-2
  description = "The base AMI ID to use for building the Java application AMI"
}

variable "instance_type" {
  type        = string
  default     = "t2.medium"
  description = "The instance type to use for building the AMI"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "The AWS region to build the AMI in"
}

locals {
  app_name = "java-petclinic-app"
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "java-app" {
  ami_name      = "PACKER-${local.app_name}-${local.timestamp}"
  instance_type = var.instance_type
  region        = var.region
  source_ami    = var.ami_id
  ssh_username  = "ubuntu"
  
  # AMI configuration
  ami_description = "Pet Clinic Java Application AMI built with Packer"
  
  # Instance configuration
  associate_public_ip_address = true
  
  # Storage configuration
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }
  
  # Tags for the AMI
  tags = {
    Name        = "PACKER-${local.app_name}-${local.timestamp}"
    Environment = "DEMO"
    Application = "PetClinic"
    BuildTool   = "Packer"
    BuildDate   = "${local.timestamp}"
    OS          = "Ubuntu"
    Java        = "OpenJDK-17"
  }
  
  # Tags for the temporary instance
  run_tags = {
    Name = "Packer-Builder-${local.app_name}"
    Type = "TemporaryInstance"
  }
}

build {
  name    = "java-petclinic-ami"
  sources = ["source.amazon-ebs.java-app"]

  # Run Ansible provisioner
  provisioner "ansible" {
    playbook_file = "java-app.yml"
    
    # Ansible configuration
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_SSH_ARGS=-o ForwardAgent=yes -o ControlMaster=auto -o ControlPersist=60s"
    ]
    
    # Use specific Python interpreter
    extra_arguments = [
      "--extra-vars", "ansible_python_interpreter=/usr/bin/python3"
    ]
  }

  # Post-processor to manifest the AMI information
  post-processor "manifest" {
    output = "packer-manifest.json"
    strip_path = true
    custom_data = {
      build_time = "${local.timestamp}"
      source_ami = "${var.ami_id}"
      region     = "${var.region}"
    }
  }
}
