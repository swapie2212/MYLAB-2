output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_oidc_provider" {
  value = module.eks.oidc_provider
}

output "eks_node_group_role_arn" {
  value = module.eks.node_groups.default.iam_role_arn
}