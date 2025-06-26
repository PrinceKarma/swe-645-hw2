# SWE 645: Web Application Deployment with Rancher and Jenkins CI/CD

This document provides a complete guide to deploying a containerized web application on a Kubernetes cluster managed by Rancher. The entire process is automated using a Jenkins CI/CD pipeline that builds a Docker image from source code, pushes it to Docker Hub, and deploys it to the cluster.

---

## Links
- Website: http://ec2-44-217-167-34.compute-1.amazonaws.com:30080/
- Rancher UI: https://ec2-44-217-167-34.compute-1.amazonaws.com/
- Jenkins UI: http://ec2-34-195-150-49.compute-1.amazonaws.com:8080/

---

## Key Technologies

-   **Frontend**: HTML, CSS, JavaScript
-   **Containerization**: Docker
-   **Orchestration**: Kubernetes
-   **Cluster Management**: Rancher
-   **CI/CD**: Jenkins, GitHub, Docker Hub

---

## Table of Contents

* [Prerequisites](#prerequisites)
* [Step 1: Setting up the Git Repository](#step-1-setting-up-the-git-repository)
* [Step 2: Creating the Docker Image and Setting Up Docker Hub](#step-2-creating-the-docker-image-and-setting-up-docker-hub)
* [Step 3: Set Up a Kubernetes Cluster with Rancher](#step-3-set-up-a-kubernetes-cluster-with-rancher)
* [Step 4: Set Up the Jenkins Server](#step-4-set-up-the-jenkins-server)
* [Step 5: Create and Run the CI/CD Pipeline](#step-5-create-and-run-the-cicd-pipeline)
* [Step 6: Accessing the Application](#step-6-accessing-the-application)

---

## Prerequisites

Before you begin, ensure you have the following:

-   An **AWS Account**.
-   A **Docker Hub Account** to store your container images.
-   A **GitHub Account** to host your project code.
-   **Git** installed on your local machine.
-   An **SSH client** (like Terminal or PuTTY) to connect to your servers.

---

## Step-by-Step Instructions

### Step 1: Setting up the Git Repository

First, you need to create a local Git repository and push it to GitHub.

1.  **Create Project Files**: Create all the files (`Dockerfile`, `Jenkinsfile`, etc.) and directories as shown in the [Project Structure](#1-project-structure) section on your local machine.
2.  **Initialize Git**: Open a terminal in your project's root directory and run:

    ```bash
    git init
    git add .
    git commit -m "Initial project setup"
    ```

3.  **Create GitHub Repository**: Go to GitHub and create a new, empty repository without a `README` or `.gitignore` file.
4.  **Push to GitHub**: Follow the instructions from GitHub to push your local repository:

    ```bash
    git remote add origin [https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git](https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git)
    git branch -M main
    git push -u origin main
    ```

### Step 2: Creating the Docker Image and Setting Up Docker Hub

Before automating, it's crucial to confirm your Docker setup works manually.

1.  **Create a Docker Hub Repository**:
    * Log in to [Docker Hub](https://hub.docker.com/).
    * Click **Create Repository**.
    * Give it a name that matches your intended image name (e.g., `swe645-webapp`).
    * Make sure it is set to **Public**.

2.  **Build the Docker Image Locally**:
    * Make sure Docker Desktop is running on your machine.
    * From your project's root directory, run the build command. Replace `YOUR_DOCKER_HUB_USERNAME` with your actual username.

    ```bash
    docker build -t YOUR_DOCKER_HUB_USERNAME/swe645-webapp:test .
    ```

3.  **Push the Image to Docker Hub**:
    * Log in to Docker Hub from your terminal:

        ```bash
        docker login
        ```

    * Push the `test` image you just built:

        ```bash
        docker push YOUR_DOCKER_HUB_USERNAME/swe645-webapp:test
        ```

    * Confirm that you can see the `test` tag in your repository on the Docker Hub website.

### Step 3: Set Up a Kubernetes Cluster with Rancher

We will first set up the Rancher management server and then use it to provision a new Kubernetes cluster.

1.  **Provision the Rancher & Kubernetes Server**
    * Using the AWS Management Console, launch a new EC2 instance.
    * **AMI**: `Ubuntu Server 24.04 LTS`.
    * **Instance Type**: `t3.large`
    * **Storage**: Increase the default storage to **30 GB**.
    * **Security Group**: Create a group named `rancher-k8s-sg` and add these inbound rules:
        * **Type**: `SSH` (Port 22) | **Source**: `My IP`
        * **Type**: `HTTP` (Port 80) | **Source**: `Anywhere`
        * **Type**: `HTTPS` (Port 443) | **Source**: `Anywhere`
        * **Type**: `Custom TCP` (Port 30080) | **Source**: `Anywhere`
    * **Assign an Elastic IP**: After the instance is running, assign an Elastic IP address to it so its public IP address does not change.


2.  **Install Rancher**
    * Connect to the server via SSH.
    * Install Docker:

        ```bash
        sudo apt update && sudo apt upgrade
        sudo apt install docker.io
        sudo usermod -aG docker $USER
        # Log out and log back in for the group change to take effect
        ```

    * Install and run the Rancher server software in a Docker container:

        ```bash
        docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher
        ```

    * Wait a few minutes, then in your web browser, navigate to the public IP of your server.
    * The first time, Rancher will show you a command to get your initial admin password. Run it in your SSH terminal and use the password to log in. Set a new permanent password when prompted.

3.  **Create the Kubernetes Cluster**
    * Click **Create**.
    * Select **Custom**.
    * Enter **Cluster Name** (e.g., `swe645-cluster`).
    * Leave the other settings as default and click **Next**.
    * On the next screen, under **Node Role**, select all three roles: **etcd**, **Control Plane**, **Worker**, **Insecure**.
    * Copy the long registration command shown on the screen.
    * Run the registration command in the terminal

4.  **Get Your kubeconfig File**
    * On the **Cluster Management** page, click the three vertical dots (**⋮**) next to the your cluster and select **Download KubeConfig**.
    * Save this file. You will need to paste its contents into a Jenkins credential later.



### Step 4: Set Up the Jenkins Server

You need a separate server to run Jenkins.

-   **Launch EC2 Instance**: Create a new `t3.medium` EC2 instance for Jenkins with a security group that allows inbound traffic on port `22` (SSH) and `8080` (Jenkins UI).
    * **Assign an Elastic IP**: After the instance is running, assign an Elastic IP address to it so its public IP address does not change.

-   **Install Tools**: SSH into the Jenkins server and run this script to install Jenkins, Docker, and kubectl.
    ```bash
    # Update, install Java and Git
    sudo apt update && sudo apt upgrade
    sudo apt install -y openjdk-17-jdk git

    # Install Jenkins
    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins

    # Install Docker
    sudo apt-get install -y docker.io
    sudo usermod -aG docker jenkins # Allow Jenkins to use Docker

    # Install kubectl
    sudo snap install kubectl --classic

    # Restart Jenkins to apply permissions
    sudo systemctl restart jenkins
    ```
-   **Jenkins Setup Wizard**: Access Jenkins in your browser at `http://<JENKINS_SERVER_IP>:8080` and complete the setup wizard. The initial password can be found by running `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` on your Jenkins server. Choose to "Install suggested plugins".
-   **Configure Credentials**:
    1.  Navigate to **Manage Jenkins > Credentials > System > Global credentials**.
    2.  **Docker Hub**: Add new "**Username with password**" credentials. Use your Docker Hub username and password, and set the ID to the one you defined in your `Jenkinsfile` (e.g., `DockerCreds`).
    3.  **Kubernetes**: Add new "**Secret file**" credentials. Paste the `kubeconfig` content you copied from Rancher, and set the ID to the one you defined in your `Jenkinsfile` (e.g., `KubeCreds`).
    4. Add additional plugins
        - Docker pipeline
        - Kubernetes
        - Rancher

### Step 5: Create and Run the CI/CD Pipeline

-   **Push Code to GitHub**: Commit all your project files and push them to a new GitHub repository.
-   **Create Pipeline in Jenkins**:
    1.  On the Jenkins dashboard, click **New Item**.
    2.  Enter a name (e.g., `swe645-pipeline`) and select **Pipeline**.
    3.  In the configuration, scroll to the **Pipeline** section.
        -   **Definition**: Pipeline script from SCM.
        -   **SCM**: Git.
        -   **Repository URL**: Enter your GitHub repository's URL.
        -   **Branch**: `*/main`.
    4.  Click **Save**.
-   **Run the Build**: Click **Build Now** to start your CI/CD pipeline. You can watch its progress in the "Console Output".

---

### Step 6: Accessing the Application

Once your Jenkins pipeline completes successfully:

-   **Find the Load Balancer IP**:
    -   Access the webstie in your browser at `http://<RANCHER_SERVER_IP>:30080` 
    -   Alternatively, use `kubectl` with your Rancher `kubeconfig` file:
        ```bash
        kubectl get service swe645-webapp-service
        ```
-   **Open in Browser**: Paste the external IP address into your web browser. You should see your deployed web application.


### References
- https://www.jenkins.io/doc/tutorials/tutorial-for-installing-jenkins-on-AWS/
- https://www.rancher.com/quick-start
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://docs.docker.com/get-started/

