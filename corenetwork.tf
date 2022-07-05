resource "aws_vpc" "vpc1" {
  cidr_block                = "10.0.0.0/16"
  enable_dns_support        = true
  enable_dns_hostnames      = true
  tags                      = {
      Name                  = "${var.ENV}-vpc1"
      Environment           = "${var.ENV}"
  }
}


resource "aws_subnet" "public_subnet" {
  vpc_id                    = "${aws_vpc.vpc1.id}"
  count                     = "${length(var.PUBLIC_CIDR)}"
  cidr_block                = "${element(var.PUBLIC_CIDR, count.index)}"
  availability_zone         = "${element(var.AZ, count.index)}"
  map_public_ip_on_launch   = true
  tags                      = {
    Name                    = "${var.ENV}-${element(var.AZ, count.index)}-public-subnet"
    Environment             = "${var.ENV}"
  }
}

resource "aws_internet_gateway" "public_igw" {
  vpc_id                    = "${aws_vpc.vpc1.id}"
  tags                      = {
    Name                    = "${var.ENV}-public-igw"
    Environment             = "${var.ENV}"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id                    = "${aws_vpc.vpc1.id}"
/*
  route {
      cidr_block            = "0.0.0.0/0"
      gateway_id            = aws_internet_gateway.public_igw.id
  }
*/
  tags = {
    Name                    = "${var.ENV}-public-route-table"
    Environment             = "${var.ENV}"
  }
}


resource "aws_route" "public_rt" {
  route_table_id            = "${aws_route_table.public_rtb.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = "${aws_internet_gateway.public_igw.id}"
}


resource "aws_route_table_association" "public_rtb_asso" {
  count                     = "${length(var.PRIVATE_CIDR)}"
  subnet_id                 = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id            = "${aws_route_table.public_rtb.id}"
}


resource "aws_subnet" "private_subnet" {
  vpc_id                    = "${aws_vpc.vpc1.id}"
  count                     = "${length(var.PRIVATE_CIDR)}"
  cidr_block                = "${element(var.PRIVATE_CIDR, count.index)}"
  availability_zone         = "${element(var.AZ, count.index)}"
  map_public_ip_on_launch   = false
  tags                      = {
    Name                    = "${var.ENV}-${element(var.AZ, count.index)}-private-subnet"
    Environment             = "${var.ENV}"
  }
}


resource "aws_eip" "nat_eip" {
  vpc                       = true
  depends_on                = [aws_internet_gateway.public_igw]
}


resource "aws_nat_gateway" "private_ngw" {
  allocation_id             = "${aws_eip.nat_eip.id}"
  subnet_id                 = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on                = [aws_internet_gateway.public_igw]
  tags                      = {
    Name                    = "private-ngw"
    Environment             = "${var.ENV}"
  }
}



resource "aws_route_table" "private_rt" {
  vpc_id                    = "${aws_vpc.vpc1.id}"
/*
  route {
      cidr_block            = "0.0.0.0/0"
      gateway_id            = aws_nat_gateway.private_ngw.id
  }
*/
  tags                      = {
    Name                    = "${var.ENV}-private-route-table"
    Environment             = "${var.ENV}"
  }
}


resource "aws_route" "private_nat_gw" {
  route_table_id            = "${aws_route_table.private_rt.id}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = "${aws_nat_gateway.private_ngw.id}"
}


resource "aws_route_table_association" "private_rtb_asso" {
  count                     = "${length(var.PRIVATE_CIDR)}"
  subnet_id                 = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id            = "${aws_route_table.private_rt.id}"
}
