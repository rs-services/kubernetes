# Kubernetes IaaS Cluster
Launches a Kubernetes cluster using IaaS components (i.e. servers).
This is as opposed to using a Container as a Service or Kubernetes as a Service offering to stand up the cluster.

# Prerequisites
- AWS and/or AzureRM and/or Google connected to the account.

# Set up
- Create "PFT Ubuntu 16.04" MCI in the account if necessary.
  - This CAT can be used to set up the MCI: https://github.com/rs-services/rs-premium_free_trial/blob/master/Account_Management/mci_management_base_linux.cat.rb
- Create credential named, RS_REFRESH_TOKEN containing a valid refresh token.
- Run right_st and pass it the Kubernetes.yml file
- Upload the "pft/mci" package file.
  - https://github.com/rs-services/rs-premium_free_trial/blob/master/Account_Management/mci_management.pkg.rb
- Upload the "pft/mci/linux_mappings" package file
  - https://github.com/rs-services/rs-premium_free_trial/blob/master/Account_Management/mci_management_linux_mappings.pkg.rb
- Upload and publish the kubernetes.cat.rb file 

# Usage
- Launch the CAT
  - You must provide your IP address to be able to access the Kubernetes dashboard.
- Once launched click the link to the dashboard.
  - Click "Skip" on the login screen.
