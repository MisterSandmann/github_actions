terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

# AWS Provider -Region kommt aus Variablen
provider "aws" {
    region = var.aws_region

    # Credentials kommen aus Umgebungsvariablen:
    # AWS_ACCESS_KEY_ID und AWS_SECRET_ACCESS_KEY
    # Diese werden von GitHub Actions gesetzt
}

# lokale Variablen für die wiederkehrende Werte
locals {
    common_tags = {
        Project     = "GitHubActions-Workshop"
        Environment = var.environment
        ManagedBy   = "Terraform"
        CreatedBy   = "GitHub-Actions"
    }
}

# VPC -Eigenes Netzwerk
resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = merge(locals.common.tags, {
        Name = "${var.project_name}-vpc"
    })  
}

# Internet Gateway - Verbindung zum Internet
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = merge(locals.common_tags, {
        Name = "${var.project_name}-igw"
    })
}

# Public Subnet - öffentliches Netzwerk-Segment
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = merge(locals.common_tags, {
    Name = "${var.project_name}-public-subnet"
  })
}

# Route Table -Routing-Regeln
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route = {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
    tags = merge(locals.common_tags, {
        Name = "${var.project_name}-public-rt"
    })
}

# Route Table Association - Subnet mit Route Table verbinden
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group - Firewall-Regeln
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # HTTP (Port 80) von überall
  ingress = {
    description = "HTTP from anywhere"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (Port 22) von überall (in Produktion: IP einschränken!!!)
  ingress {
    description = "SSH from anywhere"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ausgehender Traffic - alles erlaubt
  egress {
    description = "All outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(locals.common_tags, {
    Name = "${var.project_name}-web-sg"
  })
}

# EC2-Schlüsselpaar (nur wenn SSH-Key angegeben)
resource "aws_key_pair" "deployer" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key

  tags = locals.common_tags
}

# User Data Script - Wird beim EC2-Start ausgeführt
locals {
    user_data = <<-EOF
    #!/bin/bash
    set -e

    # System aktualisieren
    apt-get update
    apt-get upgrade -y

    # Nginx installieren
    apt-get install -y nginx

    # Custom HTML-Seite erstellen
    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
        <title>GitHub Actions + Terraform</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .container {
                background: rgba(255,255,255,0.1);
                padding: 30px;
                border-radius: 10px;
                backdrop-filter: blur(10px);
            }
            h1 { margin-top: 0; }
            .success { color: #4ade80; font-size: 24px; }
            pre {
                background: rgba(0,0,0,0.3);
                padding: 15px;
                border-radius: 5px;
                overflow-x: auto;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Deployment erfolgreich!</h1>
            <p class="success">✅ Terraform + GitHub Actions funktionieren!</p>

            <h2>Server-Informationen:</h2>
            <pre>Hostname: $(hostname)
    IP: $(hostname -I | awk '{print $1}')
    Region: ${var.aws_region}
    Environment: ${var.environment}
    Deployed: $(date)</pre>

            <h2>Deployed via:</h2>
            <ul>
                <li>✅ GitHub Actions</li>
                <li>✅ Terraform</li>
                <li>✅ AWS EC2</li>
                <li>✅ Nginx Webserver</li>
            </ul>
        </div>
    </body>
    </html>
    HTML

    # Nginx starten
    systemctl start nginx
    systemctl enable nginx

    echo "✅ Nginx installed and configured successfully!"
  EOF
}

# EC2-Instanz - Der Webserver
resource "aws_instance" "web" {
    ami           = var.ami_id
    instance_type = var.instance_type

    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.web.id]
    associate_public_ip_address = true 
    
    key_name = var.ssh_public_key != "" ? aws_key_pair.deployer[0].key_name : null

    user_data = locals.user_data

    # Root Volume
    root_block_device {
      volume_size = 8
      volume_type = "gp3"
      encrypted = true

      tags = merge(locals.common_tags, {
        Name = "${var.project_name}-root-volume"
      })
    }

    tags = merge(locals.common_tags, {
        Name = "${var.project_name}-webserver"
    })
}
