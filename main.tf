provider "google" {
	credentials 			= "${file("kthw-260206-8be7550fe9fa.json")}"
	project 			= "${var.var_project}"
	region 				= "${var.var_region}"
	zone 				= "${var.var_zone}"
}

#module "vpc" {
#	source 				= "../modules/global"
#	network_self_link 	= "${module.vpc.out_vpc_self_link}"
#	var_subnet 			= "${var.kthw_subnet}"
#}


#module "controller-0" {
#	source 				= "../modules/controller-0"
#	network_self_link 	= "${module.vpc.out_vpc_self_link}"
#	var_subnet 			= "${var.kthw_subnet}"
#}

resource "google_compute_network" "vpc" {
    name = "kubernetes-the-hard-way"
    auto_create_subnetworks = "false"
    routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "kthw-subnet" {
	name						= "kthw-subnet"
	ip_cidr_range				= "${var.kthw_subnet}"
	private_ip_google_access	= true
	network						= "${google_compute_network.vpc.self_link}"
}

resource "google_compute_firewall" "allow-internal" {
  name    = "kubernetes-the-hard-way-allow-internal"
  network = "${google_compute_network.vpc.self_link}"
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.240.0.0/24"]
}

resource "google_compute_firewall" "allow-tcp" {
  name    = "allow-tcp"
  network = "${google_compute_network.vpc.self_link}"
allow {
    protocol = "tcp"
    ports    = ["6443"]
  }
  target_tags = ["tcp-6443"] 
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "${google_compute_network.vpc.self_link}"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags = ["ssh-22"]
  }


resource "google_compute_address" "static-ip" {
	name = "kubernetes-the-hard-way"
}


#####################Controller####################

resource "google_compute_instance" "controller-0" {
	name = "controller-${count.index}"
	count = 3
	can_ip_forward = true
	boot_disk {
		initialize_params {
			size = 200
			image ="ubuntu-os-cloud/ubuntu-1804-lts"
		}
	}
	machine_type = "n1-standard-1"
	network_interface{
		network_ip = "10.240.0.1${count.index}"
		subnetwork = "${google_compute_subnetwork.kthw-subnet.self_link}"
	}
	service_account {
		scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
	}
	tags = ["kubernetes-the-hard-way", "controller"]
}

#####################Worker###########################

resource "google_compute_instance" "worker-0" {
	name = "worker-${count.index}"
	count = 3
	can_ip_forward = true
	boot_disk {
		initialize_params {
			size = 200
			image ="ubuntu-os-cloud/ubuntu-1804-lts"
		}
	}
	machine_type = "n1-standard-1"
	network_interface{
		network_ip = "10.240.0.2${count.index}"
		subnetwork = "${google_compute_subnetwork.kthw-subnet.self_link}"
	}
	metadata = {
		pod-cidr = "10.200.${count.index}.0/24"
	}
	service_account {
		scopes = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
	}
	tags = ["kubernetes-the-hard-way", "worker"]
}








################## Display Output #########################
output "vpc" {
	value = "google_compute_network.vpc.self_link"
}
