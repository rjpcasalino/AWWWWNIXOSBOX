# ==============================================================================
# VPC & Dual-Stack Networking Configuration
# ==============================================================================

resource "aws_vpc" "ecs_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames             = true
  enable_dns_support               = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = {
    Name = "${var.app_name}-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                          = aws_vpc.ecs_vpc.id
  cidr_block                      = "10.0.1.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.ecs_vpc.ipv6_cidr_block, 8, 1)
  availability_zone               = "${var.aws_region}a"
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "${var.app_name}-public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                          = aws_vpc.ecs_vpc.id
  cidr_block                      = "10.0.2.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.ecs_vpc.ipv6_cidr_block, 8, 2)
  availability_zone               = "${var.aws_region}b"
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "${var.app_name}-public-subnet-b"
  }
}

# Internet Routing Configuration
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.app_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
