output "container_id" {
    description = "ID of docker container"
    value = docker_container.nginx.id
}

output "image_id" {
    description = "ID of docker image"
    value = docker_image.nginx.id
}