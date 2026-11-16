
output "ecr_urls" {
  value = { for k, r in aws_ecr_repository.repos : k => r.repository_url }
}

output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}
