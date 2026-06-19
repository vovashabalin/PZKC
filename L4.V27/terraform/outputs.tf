output "worker_ip" {
  description = "Static worker address for SSH and HTTP tests."
  value       = var.worker_ip
}

output "db_ip" {
  description = "Static DB address; PostgreSQL is reachable only from worker/db network hosts."
  value       = var.db_ip
}

output "ssh_user" {
  description = "Cloud-init creates this user on both VMs."
  value       = "ansible"
}
