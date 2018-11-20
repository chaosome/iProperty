provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}



data "template_file" "init" {
  template = "${file("userdata.tpl")}"
}



resource "aws_instance" "Sinatra_App_Server" {
  ami = "${var.ami_image}" 
  subnet_id = "${var.pub_subnet_id}" 
  instance_type = "t2.micro"
  associate_public_ip_address = "true"
  user_data = "${data.template_file.init.rendered}"
  vpc_security_group_ids = [
  	"${var.allow_jumphost_secgroup_id}",
	"${aws_security_group.allow_http.id}"
  ]

  
  tags {
          Name = "Sinatra App Server"
       }

}


resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = "${var.vpc_id}"

      ingress {
          from_port   = 80
	  to_port     = 80
	  protocol    = "tcp"
	  cidr_blocks = ["${var.cidr_blocks}"]
      }

      tags {
        Name = "HTTP-SG"
      }
}


output "public_ip" {
  value = "${aws_instance.Sinatra_App_Server.public_ip}"
}
