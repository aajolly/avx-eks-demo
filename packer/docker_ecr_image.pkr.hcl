# Initialize Docker plugin
packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source = "github.com/hashicorp/docker"
    }
  }
}
source "docker" "aajolly" {
	image = var.image
	commit = true
}

# Build Image
build {
	name = "nyancat"
	sources = [
		"source.docker.aajolly"
	]
}

# Add a tag
post-processors {
	post-processor "docker-tag" {
		repository = var.nyancat_ecr_url
		tags = "latest"
	}

# Push the Docker image to your Amazon ECR registry
# Ideally, use an IAM role for credentials
	post-processor "docker-push" {
				login = false
				login_server = var.nyancat_ecr_url
		}
	}