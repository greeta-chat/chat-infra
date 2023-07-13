module "eks" {
  source = "./module-eks"

  region                 = var.aws_region
  author                 = "skyglass"
  cluster_name           = var.cluster_name
}

module "app" {
  source                                           = "./module-app"

  region                                           = var.aws_region
  environment                                      = var.environment
  domain_name                                      = "greeta.net"
  cluster_id                                       = module.eks.cluster_id
  cluster_name                                     = module.eks.cluster_name
  ssl_certificate_arn                              = var.ssl_certificate_arn
}