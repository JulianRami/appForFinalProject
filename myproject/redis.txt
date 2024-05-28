provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}

# Crear VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Crear Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Crear Subnet 1
resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Cambia esto a tu zona preferida
  tags = {
    Name = "main-subnet1"
  }
}

# Crear Subnet 2
resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Cambia esto a tu zona preferida
  tags = {
    Name = "main-subnet2"
  }
}

# Crear Security Group para Redis
resource "aws_security_group" "redis_sg" {
  vpc_id = aws_vpc.main.id
  name   = "redis-sg"

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Crear grupo de parámetros de Elasticache para Redis
resource "aws_elasticache_parameter_group" "redis" {
  name        = "redis7-parameter-group"
  family      = "redis7"
  description = "Parameter group for Redis version 7"
}

# Crear Elasticache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "redis-cluster"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = {
    Name = "redis-cluster"
  }
}

# Crear Elasticache Subnet Group
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.subnet1.id]

  tags = {
    Name = "redis-subnet-group"
  }
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
