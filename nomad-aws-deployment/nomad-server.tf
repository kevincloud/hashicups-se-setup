resource "aws_instance" "hashi-server" {
    ami = data.aws_ami.ubuntu.id
    instance_type = var.instance_size
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.hashi-server-sg.id]
    subnet_id = aws_subnet.public-subnet.id
    iam_instance_profile = aws_iam_instance_profile.hashi-main-profile.id
    user_data = templatefile("${path.module}/scripts/install.sh", {
        AWS_KMS_KEY_ID = var.aws_kms_key_id
        REGION = var.aws_region
        KEY_PAIR_NAME = var.key_pair
        CONSUL_URL = var.consul_dl_url
        CONSUL_LICENSE = var.consul_license_key
        CONSUL_JOIN_KEY = var.consul_join_key
        CONSUL_JOIN_VALUE = var.consul_join_value
        NOMAD_URL = var.nomad_dl_url
        NOMAD_LICENSE = var.nomad_license_key
        BRANCH_NAME = var.git_branch
        SLACK_URL = var.slack_url
    })

    tags = {
        Name = "hashicups-server-${var.identifier}"
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_security_group" "hashi-server-sg" {
    name = "hashicups-server-sg-${var.identifier}"
    description = "Nomad server security group"
    vpc_id = aws_vpc.primary-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 4646
        to_port = 4648
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 4648
        to_port = 4648
        protocol = "udp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
       from_port = 5801
       to_port = 5801
       protocol = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 5821
        to_port = 5826
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8200
        to_port = 8200
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8300
        to_port = 8303
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 8500
        to_port = 8500
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 9090
        to_port = 9090
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

data "aws_iam_policy_document" "hashi-assume-role" {
    statement {
        effect  = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["ec2.amazonaws.com"]
        }
    }
}

data "aws_iam_policy_document" "hashi-main-access-doc" {
    statement {
        sid       = "FullAccess"
        effect    = "Allow"
        resources = ["*"]

        actions = [
            "ec2:DescribeInstances",
            "ec2:DescribeTags",
            "ec2messages:GetMessages",
            "ssm:UpdateInstanceInformation",
            "ssm:ListInstanceAssociations",
            "ssm:ListAssociations",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage",
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:DescribeKey",
            "s3:*"
        ]
    }
}

resource "aws_iam_role" "hashi-main-access-role" {
    name               = "hashicups-access-role-${var.identifier}"
    assume_role_policy = data.aws_iam_policy_document.hashi-assume-role.json

    tags = {
        owner = var.owner
        se-region = var.se-region
        purpose = var.purpose
        ttl = var.ttl
        terraform = var.terraform
    }
}

resource "aws_iam_role_policy" "hashi-main-access-policy" {
    name   = "hashicups-access-policy-${var.identifier}"
    role   = aws_iam_role.hashi-main-access-role.id
    policy = data.aws_iam_policy_document.hashi-main-access-doc.json
}

resource "aws_iam_instance_profile" "hashi-main-profile" {
    name = "hashicups-access-profile-${var.identifier}"
    role = aws_iam_role.hashi-main-access-role.name
}

