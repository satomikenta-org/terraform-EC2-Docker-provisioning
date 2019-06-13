
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "DOCKER VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"
  tags = {
    Name = "DOCKER IGW"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = "${aws_vpc.main.id}"
  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
    Name = "DOCKER RT"
  }
}

resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "DOCKER SUBNET"
  }  
}

resource "aws_route_table_association" "public_association" {
  route_table_id = "${aws_route_table.rt.id}"
  subnet_id = "${aws_subnet.public.id}"
}


resource "aws_security_group" "sg" {
  vpc_id = "${aws_vpc.main.id}"
  name = "DOCKER SG"
  ingress = {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress = {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress = {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "DOCKER SG"
  }
}



resource "aws_instance" "ec2" {
  instance_type = "t2.micro"
  ami = "ami-0ebbf2179e615c338" # amazon_linux
  subnet_id = "${aws_subnet.public.id}"
  key_name = "${var.ec2_key}"
  security_groups = ["${aws_security_group.sg.id}"]
  
  provisioner "file" {
    source = "./scripts/install_docker.sh"
    destination = "/home/ec2-user/install_docker.sh"
    connection = {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.ec2_key_path)}"
    }
  }

  provisioner "file" {
    source = "../app/"
    destination = "/home/ec2-user/"
    connection = {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.ec2_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /home/ec2-user/install_docker.sh", 
      "cd /home/ec2-user/",
      "./install_docker.sh",
      "sudo docker build -t myapp .",
      "sudo docker run -p 3000:3000 -d --restart=always myapp",
    ]
    connection = {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.ec2_key_path)}"
    }
  }

  tags = {
    Name = "DOCKER EC2"
  }
}


output "ec2_ip" {
  value = "${aws_instance.ec2.public_ip}"
}


