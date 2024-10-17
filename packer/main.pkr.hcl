variable "artifact_path" {
  type    = string
  default = "/tmp/build-artifacts"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

source "amazon-ebs" "ubuntu_ami" {
  region  = var.aws_region # Directly use the environment variable
  profile = "dev"          # Specify your AWS CLI profile, if needed
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-focal-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["099720109477"]
    most_recent = true
  }
  instance_type = "t2.micro"
  ami_name      = "assignment4_ami_Deepansh_${formatdate("YYYY_MM_DD",timestamp())}"
  ssh_username  = "ubuntu"
  tags = {
    Name        = "custom-ubuntu-24.04-node-postgres"
    Environment = "dev"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu_ami"]

  # Set non-interactive mode
  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive"
    ]
  }

  # Install PostgreSQL and Node.js
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nodejs npm",
      "sudo apt-get install -y postgresql postgresql-contrib",
      "sudo systemctl enable postgresql",
      "sudo apt-get clean"
    ]
  }

  # Create non-login user
  provisioner "shell" {
    inline = [
      "sudo groupadd -r csye6225",
      "sudo useradd -r -g csye6225 -s /usr/sbin/nologin csye6225"
    ]
  }

  # Copy application artifact and configure permissions
  provisioner "file" {
    source      = var.artifact_path
    destination = "/tmp/build-artifacts"
  }

  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/app",
      "sudo cp -r /tmp/build-artifacts/* /opt/app/",
      "sudo chown -R csye6225:csye6225 /opt/app",
      "sudo chmod -R 755 /opt/app"
    ]
  }

  # Configure systemd service
  provisioner "shell" {
    inline = [
      "echo '[Unit]' > /etc/systemd/system/nodeapp.service",
      "echo 'Description=Node.js Application' >> /etc/systemd/system/nodeapp.service",
      "echo '[Service]' >> /etc/systemd/system/nodeapp.service",
      "echo 'ExecStart=/usr/bin/node /opt/app/server.js' >> /etc/systemd/system/nodeapp.service",
      "echo 'Restart=always' >> /etc/systemd/system/nodeapp.service",
      "echo '[Install]' >> /etc/systemd/system/nodeapp.service",
      "echo 'WantedBy=multi-user.target' >> /etc/systemd/system/nodeapp.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable nodeapp"
    ]
  }
}
