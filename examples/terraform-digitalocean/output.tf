output "public_ip" {
  value = digitalocean_droplet.mywebserver.ipv4_address
}

output "name" {
  value = digitalocean_droplet.mywebserver.name
}

