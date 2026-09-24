# Introduction
The files in this directory are used to install and customize Kasm Workspaces.

# `Dockerfile` & `resources` Usage
1. On the Kasm admin dashboard, navigate to the page: `Workspaces/Workspaces`.  
Click **Add Workspace** and save the workspace's settings, including your customized Docker Image.

2. Build the Docker Image in the path where the `Dockerfile` is located from the terminal of a server:

    `sudo docker build -t <image_name>:<tag> .`

    `<tag>` is the installed version of Kasm Workspaces.

    `resources` contains the other files required for the `Dockerfile` to build the Docker Image.

3. On the Kasm admin dashboard, navigate to the page: `Workspaces/Registry/Installed Workspaces`, to check if the workspace is installed.  
Once the workspace is installed *(Docker Image is built)*, the session of the workspace can be launched on the **WORKSPACES** *(User Dashboard)*.

# Other Files Usage
`nvidia_container_toolkit`:  
`daemon.json` can be copied to the host path: `/etc/docker`, to enable the '***nvidia***' runtime for Docker manually.

`user_script`:  
Both `code_install-extension.sh` and `pip_download.sh` can be copied to the host path: `/mnt/kasm/share` via **Volume Mappings (JSON)** in the workspace's settings.  
They will guide the user to the installation of Visual Studio Code extensions and Python packages in an offline approach.

`workspace_option`:  
`restrict_image_to_docker_network.sh` can be executed on the host to restrict the Docker Image to the Docker Network.  
Enabling **Restrict Image to Docker Network** and choosing **kasm_w/o_network** for **Docker Networks** in the workspace's settings will make the session offline.  
The contents of `volume_mappings.json` can be copied and pasted to **Volume Mappings (JSON)** in the workspace's settings, to share files with the user in the session.
