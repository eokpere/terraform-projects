provider "aws" {
   region   = var.region
   #profile = "default"
 }

#create vpc
module "vpc" {
    source                      = "../modules/vpc" #For example if your current directory is C:/projects/a/b/c then ../.. will be C:/projects/a
    region                      = var.region
    project_name                = var.project_name
    vpc_cidr                    = var.vpc_cidr
    public_subnet_az1_cidr      = var.public_subnet_az1_cidr
    public_subnet_az2_cidr      = var.public_subnet_az2_cidr
    private_app_subnet_az1_cidr = var.private_app_subnet_az1_cidr
    private_app_subnet_az2_cidr = var.private_app_subnet_az2_cidr
    private_data_subnet_az1_cidr = var.private_data_subnet_az1_cidr
    private_data_subnet_az2_cidr = var.private_data_subnet_az2_cidr
}

#create nat gateways
module "nat_gateway" {
  source                        = "../modules/nat-gateway"
  public_subnet_az1_id          = module.vpc.public_subnet_az1_id
  internet_gateway              = module.vpc.internet_gateway
  public_subnet_az2_id          = module.vpc.public_subnet_az2_id
  vpc_id                        = module.vpc.vpc_id
  private_app_subnet_az1_id     = module.vpc.private_app_subnet_az1_id
  private_data_subnet_az1_id    = module.vpc.private_data_subnet_az1_id
  private_app_subnet_az2_id     = module.vpc.private_app_subnet_az2_id
  private_data_subnet_az2_id    = module.vpc.private_data_subnet_az2_id
}

#create sg
module "security_group" {
  source = "../modules/security-group"
  vpc_id = module.vpc.vpc_id
}

module "ecs_task_execution_role" {
  source        ="../modules/ecs-tasks-execution-role"
  project_name  = module.vpc.project_name #because we created the project name in the vpc module
}

module "Aws-Cert-Mgr" {
  source              = "../modules/Aws-Cert-Mgr"
  domain_name         = var.domain_name
  alternative_name    = var.alternative_name
}

module "application_load_balancer" {
  source                = "../modules/alb"
  project_name          = module.vpc.project_name
  alb_security_group_id = module.security_group.alb_security_group_id
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
  certificate_arn       = module.Aws-Cert-Mgr.certificate_arn
}

module "ecs" {
  source                        = "../modules/ecs"
  project_name                  = module.vpc.project_name
  ecs_task_execution_role_arn   = module.ecs_task_execution_role.ecs_task_execution_role_arn
  container_image               = var.container_image
  region                        = module.vpc.region
  private_app_subnet_az1_id     = module.vpc.private_app_subnet_az1_id
  private_app_subnet_az2_id     = module.vpc.private_app_subnet_az2_id
  ecs_security_group_id         = module.security_group.ecs_security_group_id
  alb_target_group_arn          = module.application_load_balancer.alb_target_group_arn
}

module "auto_scaling_group" {
  source              = "../modules/asg"
  ecs_cluster_name    = module.ecs.ecs_cluster_name
  ecs_service_name    = module.ecs.ecs_service_name
}

module "route_53" {
  source        = "../modules/route53"
  domain_name   = module.Aws-Cert-Mgr.domain_name
  record_name   = var.record_name
  alb_dns_name  = module.application_load_balancer.alb_dns_name
  alb_zone_id   = module.application_load_balancer.alb_zone_id
}

output "website_url" {
  value = join ("",["https://", var.record_name, ".", var.domain_name])
}