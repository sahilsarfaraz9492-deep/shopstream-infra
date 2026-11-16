output "k3s_public_ip" {
  value = aws_instance.k3s.public_ip
}

output "ecr_urls" {
  value = { for k, r in aws_ecr_repository.repos : k => r.repository_url }
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}
