terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "1.70.0"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.7.2"  # Use the latest compatible version
    }
  }
}
