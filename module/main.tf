
resource "aws_spot_instance_request" "instance" { 
  availability_zone      = "us-east-1a"
  wait_for_fulfillment   = true
  ami                    = data.aws_ami.centos.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.allow-all.id]
  tags = {
    Name = local.name
         }
  }

resource "null_resource" "provisioner" {
  depends_on = [aws_spot_instance_request.instance, aws_route53_record.dnsroute, aws_ec2_tag.tag]

  provisioner "remote-exec" {

    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_spot_instance_request.instance.private_ip
    }

    inline = var.app_type == "db" ? local.db_commands : local.app_commands
  }
}


resource "aws_ec2_tag" "tag" {
  resource_id            = aws_spot_instance_request.instance.spot_instance_id
  key                    = "Name"
  value                  = var.component_name
}

resource "aws_route53_record" "dnsroute" {
  zone_id = data.aws_route53_zone.main.zone_id
  name     = "${var.component_name}-dev.kalis30nov.online"
  type     = "A"
  ttl      = "300"
  records  = [aws_spot_instance_request.instance.private_ip]
}

resource "aws_iam_role" "role" {
  name = "${var.component_name}-${var.env}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })


  tags = {
    tag-key = "${var.component_name}-${var.env}-role"
  }
}
