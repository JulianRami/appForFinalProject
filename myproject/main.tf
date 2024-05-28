provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}

# Usar la VPC y subnets del primer archivo
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Cambia esto a tu zona preferida
  tags = {
    Name = "main-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Cambia esto a tu zona preferida
  tags = {
    Name = "main-subnet2"
  }
}

# Crear Security Group para EC2
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ec2-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir el tráfico entrante desde cualquier dirección IP en el puerto 8000
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Crear EC2 en Subnet 1
resource "aws_instance" "app_instance1" {
  instance_type   = "t2.micro"
  ami             = "ami-0e001c9271cf7f3b9"
  subnet_id       = aws_subnet.subnet1.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true # Asignar una IP pública a la instancia
  tags = {
    Name = "app-instance1"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo docker run -d -p 8000:8000 --name myapp julianrami/myproject:latest
              EOF
}

# Crear EC2 en Subnet 2
resource "aws_instance" "app_instance2" {
  instance_type   = "t2.micro"
  ami             = "ami-0e001c9271cf7f3b9"
  subnet_id       = aws_subnet.subnet2.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true # Asignar una IP pública a la instancia
  tags = {
    Name = "app-instance2"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo docker run -d -p 8000:8000 --name myapp julianrami/myproject:latest
              EOF
}

# Crear Load Balancer
resource "aws_elb" "app_lb" {
  name    = "app-lb"
  subnets = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  listener {
    instance_port     = 8000
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:8000/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [
    aws_instance.app_instance1.id,
    aws_instance.app_instance2.id,
  ]

  tags = {
    Name = "app-lb"
  }
}

# Output de la URL del Load Balancer
output "load_balancer_dns" {
  value = aws_elb.app_lb.dns_name
}
