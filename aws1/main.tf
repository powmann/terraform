resource "aws_vpc" "jb_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "jb_subnet" {
  vpc_id                  = aws_vpc.jb_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    Name = "dev-public"
  }
}

resource "aws_internet_gateway" "jb_igw" {
  vpc_id = aws_vpc.jb_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "jb_rt" {
  vpc_id = aws_vpc.jb_vpc.id

  tags = {
    Name = "dev-rt"
  }
}

resource "aws_route" "jb_rt_public" {
  route_table_id         = aws_route_table.jb_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.jb_igw.id
}

resource "aws_route_table_association" "jb_rta" {
  subnet_id      = aws_subnet.jb_subnet.id
  route_table_id = aws_route_table.jb_rt.id
}

resource "aws_security_group" "jb_sg" {
  name        = "dev-sg"
  description = "dev-sg"
  vpc_id      = aws_vpc.jb_vpc.id

  ingress {
    description = "allow all traffic from my public ip"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["84.75.181.43/32"] # my public ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "jb_key" {
  key_name   = "dev-key"
  public_key = file("/home/jorb/.ssh/aws-jb-key.pub")
}

resource "aws_instance" "jb_node1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.jb_key.key_name
  subnet_id     = aws_subnet.jb_subnet.id
  vpc_security_group_ids = [aws_security_group.jb_sg.id]

  # bootstrap the instance
  user_data = file("userdata.tpl")

  # resize the root volume
  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "dev-instance"
  }
}
