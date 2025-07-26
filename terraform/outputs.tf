output "instance_self_links" {
  value = [for vm in google_compute_instance.vm : vm.self_link]
}

output "public_ips" {
  value = [for vm in google_compute_instance.vm : vm.network_interface[0].access_config[0].nat_ip]
}

output "internal_ips" {
  value = [for vm in google_compute_instance.vm : vm.network_interface[0].network_ip]
}

output "ssh_commands" {
  value = [
    for ip in google_compute_instance.vm[*].network_interface[0].access_config[0].nat_ip :
    "ssh -i id_ed25519 ${var.username}@${ip}"
  ]
}

