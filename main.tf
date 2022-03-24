locals {
  ssh_public_key = file(pathexpand("${var.ssh_public_key_file}"))
  ssh_public_key_file = pathexpand("${var.ssh_public_key_file}")
  ssh_private_key_file = pathexpand("${var.ssh_private_key_file}")
}
module "cos" {
  source = "./modules/cos"
  basename = var.basename
  region = var.region
  resource_group = "asset-forome"
  resource_instance = "asset-forome"
}
module "ssh" {
  source = "./modules/ssh"
  basename = var.basename
  region = var.region
  resource_group = var.resource_group
  ssh_public_key = local.ssh_public_key
}
module "vsi" {
  source = "./modules/vsi"
  basename = var.basename
  region = var.region
  zone = var.zone
  vpc = var.vpc
  subnet= var.subnet
  security_group = var.security_group
  resource_group = var.resource_group
  instance_name = var.instance_name
  instance_profile = var.instance_profile
  var_volume_profile = var.var_volume_profile
  var_volume_capacity = var.var_volume_capacity
  data_volume_profile = var.data_volume_profile
  data_volume_capacity = var.data_volume_capacity
  ssh_key_id = module.ssh.id
  ssh_public_key_file = local.ssh_public_key_file
  ssh_public_key = local.ssh_public_key
  user_name = var.user_name
  var_disk_name = var.var_disk_name
  data_disk_name = var.data_disk_name
}
resource "local_file" "ansible_inventory" {
  content = templatefile("inventory.tpl",
    {
      basename = var.basename
      instance_name = module.vsi.instance_name
      instance_ext_ip = module.vsi.instance_ext_ip
      user_name = var.user_name
      public_key = local.ssh_public_key
      ssh_private_key_file = local.ssh_private_key_file
    }
  )
  filename = "inventory"
}
resource "time_sleep" "wait" {
  create_duration = "10s"
  triggers = {
    always_run = timestamp()
  }
}
resource "null_resource" "ansible" {
  depends_on = [time_sleep.wait]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = "ansible-playbook main.yml"
    interpreter = ["bash", "-c"]
  }
}