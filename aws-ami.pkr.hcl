packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "nginx-final"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-0eda6cfb39d5ec19d" 
  ssh_username  = "ubuntu"
}

build {
  name    = "my-first-build"
  sources = ["source.amazon-ebs.ubuntu"] 

  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /var/www/html/index.nginx-debian.html /var/www/html/index.html.backup",
      "sudo cp /tmp/index.html /var/www/html/",
      "sudo systemctl restart nginx"
    ]
  }
}
