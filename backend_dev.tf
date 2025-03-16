terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "ProjZero"
    workspaces {
      name = "aws-projzero-prod"
    }
  }
  # required_version = ">= 1.0.0"
  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #     version = "~> 3.0"
  #   }
  #   http = {
  #     source  = "hashicorp/http"
  #     version = "2.1.0"
  #   }
  #   random = {
  #     source  = "hashicorp/random"
  #     version = "3.1.0"
  #   }
  #   local = {
  #     source  = "hashicorp/local"
  #     version = "2.1.0"
  #   }
  #   tls = {
  #     source  = "hashicorp/tls"
  #     version = "3.1.0"
  #   }
    
  # }
  required_providers {
   # /** aws = {
   #   source  = "hashicorp/aws"
   #   version = "~> 5.47.0"
    # }

    # random = {
    #  source  = "hashicorp/random"
    #  version = "~> 3.6.1"
   # }

    # tls = {
    #  source  = "hashicorp/tls"
    #  version = "~> 4.0.5"
   # }

   # cloudinit = {
    #  source  = "hashicorp/cloudinit"
    #  version = "~> 2.3.4"
   # } **/

     aws = {
      source  = "hashicorp/aws"
      version = "~> 4.47.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

  }

  required_version = "~> 1.3"

}
