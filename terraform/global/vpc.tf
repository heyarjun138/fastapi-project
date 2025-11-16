# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-${var.env}-internet-gateway"
  }
}

# Route Table for external to IGW
resource "aws_route_table" "route" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.project}-${var.env}-igw-rt"
    Environment = var.env
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

# Declaring the data source for getting AZ details for the region configured in the provider
data "aws_availability_zones" "available" {
  state = "available"
}

# Public subnets (2 AZs)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  count                   = var.subnet_count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "public-subnet-${data.aws_availability_zones.available.names[count.index]}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


# Private subnets (2 AZs)
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  count             = var.subnet_count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2) # to avoid overlap
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                        = "private-subnet-${data.aws_availability_zones.available.names[count.index]}"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Associating public subnets to route table
resource "aws_route_table_association" "public_route" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.route.id
}

# Allocate Elastic IP
resource "aws_eip" "nat" {
  tags = {
    Name        = "${var.project}-${var.env}-nat-eip"
    Environment = var.env
  }
}

# NAT Gateway for private subnets
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id #Associating public eip to nat gw
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.project}-${var.env}-nat-gateway"
  }

  depends_on = [aws_internet_gateway.gateway]

}

# Route Table for private subnets to access internet via NAT GW
resource "aws_route_table" "nat_gw_route" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-${var.env}-nat-gw-rt"
    Environment = var.env
  }
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
}

# Associating private subnets to nat gw route table
resource "aws_route_table_association" "private_route" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.nat_gw_route.id
}