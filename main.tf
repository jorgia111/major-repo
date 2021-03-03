provider "aws" {
 region = "us-east-1"
}
resource "aws_key_pair" "hawey-key" {
 key_name = "hawey-key"
 public_key = file("hawey-key.pub") 
}
resource "aws_vpc" "production-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "produ"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.production-vpc.id
  tags = {
    Name = "produ"
  }
}

resource "aws_route_table" "produ-route" {
  vpc_id = aws_vpc.production-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "produ"
  }
}
resource "aws_subnet" "sample" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "sample"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sample.id
  route_table_id = aws_route_table.produ-route.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web-traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.production-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_traffic"
  }
}


resource "aws_network_interface" "sample" {
  subnet_id       = aws_subnet.sample.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.sample.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_instance" "web" {
  ami           = "ami-047a51fa27710816e"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = aws_key_pair.hawey-key.key_name
  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.sample.id 
  }
  user_data = <<-EOF
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo bash -c 'echo your very first webserver > /var/www/html/index.html' 
              EOF
  tags = {
    Name = "web-server"
  }
}

output "server_private_ip" {
  value = aws_instance.web.private_ip
}

output "server_id" {
  value = aws_instance.web.id
}

resource "aws_ebs_volume" "sabri" {
  availability_zone = "us-east-1a"
  size              = 40

  tags = {
    Name = "major"
  }
}




https://aws.amazon.com/blogs/aws/amazon-elasticache-update-online-resizing-for-redis-clusters/




