provider "google" {
  project = "my-web-deployemnt"
  region  = "us-central1"
  zone    = "us-central1-b"
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  target_tags   = ["http-server"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "default" {
  name = "my-static-ip"
}

resource "google_compute_instance" "default" {
  name         = "flask-app-instance"
  machine_type = "f1-micro"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = google_compute_address.default.address // use static ip address
    }
  }

  metadata = {
    startup-script = <<-EOT
      #!/bin/bash
      sudo apt-get update
      sudo apt-get install -y python3 python3-pip nginx git python3-tk
      sudo pip3 install flask gunicorn
      git clone https://github.com/yyggzz/yigezhang.net
      cd yigezhang.net/
      sudo cp nginx.conf /etc/nginx/sites-enabled/flaskapp
      sudo rm /etc/nginx/sites-enabled/default
      sudo nginx -t
      sudo service nginx restart
      gunicorn app:app
    EOT
  }
}

output "static_ip" {
  value = google_compute_address.default.address
}
