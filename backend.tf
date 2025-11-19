terraform {
  cloud {
    organization = "merict1010"

    workspaces {
      name = "mt-lab-workspace"
    }

    # IMPORTANT: ensures local execution
    
  }
}
