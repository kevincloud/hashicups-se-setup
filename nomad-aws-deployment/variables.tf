variable "aws_region" {
    description = "AWS Region"
    default = "us-east-1"
}

variable "aws_kms_key_id" {
    description = "AWS KMS Key for Unsealing"
}

variable "key_pair" {
    description = "Key pair used to login to the instance"
}

variable "instance_size" {
    description = "Size of instance for most servers"
    default = "t3.large"
}

variable "consul_dl_url" {
    description = "URL for downloading Consul"
    default = "https://releases.hashicorp.com/consul/1.6.1/consul_1.6.1_linux_amd64.zip"
}

variable "nomad_dl_url" {
    description = "URL for downloading Nomad"
    default = "https://releases.hashicorp.com/nomad/0.10.1/nomad_0.10.1_linux_amd64.zip"
}

variable "consul_license_key" {
    description = "License key for Consul Enterprise"
}

variable "nomad_license_key" {
    description = "License key for Vault Enterprise"
}

variable "identifier" {
    description = "Unique identifier for each resource to be created"
}

variable "consul_join_key" {
    description = "Key for joining Consul"
}

variable "consul_join_value" {
    description = "value for the join key"
}

variable "git_branch" {
    description = "Branch used for this instance"
    default = "master"
}

variable "slack_url" {
    description = "Optional URL for posting to a Slack channel"
}

variable "owner" {
    description = ""
}

variable "se-region" {
    description = ""
}

variable "purpose" {
    description = ""
}

variable "ttl" {
    description = ""
}

variable "terraform" {
    description = "Managed by Terraform"
    default = "true"
}