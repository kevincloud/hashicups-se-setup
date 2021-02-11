output "E-server-ssh" {
    value = "ssh -i ~/keys/${var.key_pair}.pem ubuntu@${aws_instance.hashi-server.public_ip}"
}
