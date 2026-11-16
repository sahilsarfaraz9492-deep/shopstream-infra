resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "shopstream-public-b" }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_ec2_tag" "elb" {
  for_each    = { a = aws_subnet.public.id, b = aws_subnet.public_b.id }
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_iam_role" "eks_cluster" {
  name = "shopstream-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "main" {
  name     = "shopstream-eks"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = [aws_subnet.public.id, aws_subnet.public_b.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.admin_cidrs
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]
}

resource "aws_iam_role" "eks_node" {
  name = "shopstream-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ])
  role       = aws_iam_role.eks_node.name
  policy_arn = each.value
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "shopstream-nodes"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = [aws_subnet.public.id, aws_subnet.public_b.id]
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  depends_on = [aws_iam_role_policy_attachment.eks_node]
}

resource "aws_ec2_tag" "cluster" {
  for_each    = { a = aws_subnet.public.id, b = aws_subnet.public_b.id }
  resource_id = each.value
  key         = "kubernetes.io/cluster/shopstream-eks"
  value       = "shared"
}
