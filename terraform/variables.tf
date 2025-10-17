variable "aws_region" {
  description = "AWS Region für die Infrastruktur"
  type        = string
  # KEIN DEFAULT - Wird über GitHub Environment Variable übergeben!
  # Erzwingt korrekte Konfiguration
}

variable "project_name" {
    description = "Projekt-Name (wird für die Ressourcen-Namen verwendet)"
    type        = string
    default     = "github-actions-demo"
}

variable "environment" {
  description = "Environment (dev, staging, production)"
  type    = string
  default = "dev"
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  # ⚠️ KEIN DEFAULT - Wird über GitHub Environment Variable übergeben!
  # Region-spezifisch (z.B. eu-north-1 → t3.micro statt t2.micro)
}

variable "ami_id" {
  description = "AMI ID für die EC2-Instanz (Ubuntu 22.04 LTS)"
  type        = string
  # ⚠️ KEIN DEFAULT - Wird über GitHub Environment Variable übergeben!
  # AMI ist region-spezifisch!
  #
  # Beispiele:
  # eu-north-1: ami-0a716d3f3b16d290c (Ubuntu 22.04 LTS)
  # eu-central-1: ami-0a628e1e89aaedf80
  # us-east-1: ami-0866a3c8686eaeeba
}

variable "ssh_public_key" {
  description = "SSH Public Key für die EC2-Zugriff (leer lassen wenn kein SSH gewünscht)"
  type        = string
  default     = ""
  sensitive   = true
}

