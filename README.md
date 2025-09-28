# Home Assistant on Raspberry Pi with Docker

This project provides a streamlined setup for running a powerful and efficient Home Assistant instance on a Raspberry Pi 4. It leverages Docker to containerize Home Assistant and other essential services, including AppDaemon, InfluxDB, and Grafana.

## Features

* **Dockerized Services:** All services run in separate Docker containers for easy management and isolation.
* **Optimized for SSD:** The setup is designed to minimize writes to the SSD by using an in-memory SQLite database for Home Assistant's recorder.
* **Powerful Automations:** AppDaemon is included for creating complex automations in Python.
* **Metrics and Visualization:** InfluxDB and Grafana are integrated for storing and visualizing time-series data, such as energy prices or sensor readings.
* **System Monitoring:** Glances provides a web-based interface for monitoring your Raspberry Pi's system resources.
* **Secure Secret Management:** A `secrets.yaml` file is used to manage sensitive information, and it's ignored by Git to prevent accidental exposure.
* **Stable and Reproducible:** All Docker images are pinned to specific versions to ensure a stable and reproducible setup.

## Design Choices

### Database Setup

This setup uses a combination of two databases to optimize for both SSD longevity and long-term data storage:

*   **SQLite (in-memory):** Home Assistant's `recorder` is configured to use a temporary, in-memory SQLite database. This database stores the state history of all entities, which is used to render graphs and the logbook in the Home Assistant UI. Because it runs in RAM, it results in **zero writes to your SSD** for state history, significantly extending the life of your drive. The trade-off is that **all state history is lost on every restart** of Home Assistant.

*   **InfluxDB:** This is a time-series database used for long-term storage of sensor data and other metrics you want to keep permanently.

This setup is ideal for users who prioritize the longevity of their SSD over retaining a long-term state history within the Home Assistant UI.

## Getting Started

### Prerequisites

* **Hardware:**
    * Raspberry Pi 4 (4GB or 8GB RAM recommended)
    * Reliable SSD (e.g., Samsung T7 1TB) for booting and storage
    * Official Raspberry Pi power supply
    * Ethernet connection (recommended for stability)
* **Software:**
    * Raspberry Pi OS (64-bit) installed on the SSD
    * Git

### 1. Initial Setup

1.  **Clone the Repository:**

    ```bash
    git clone git@github.com:Haigutus/homeassistant-template.git
    cd homeassistant-template
    ```

2.  **Run the Setup Script:**

    The `setup.sh` script will:

    *   Enable USB boot on your Raspberry Pi.
    *   Install Docker and Docker Compose.
    *   Install Tailscale for secure remote access.
    *   Copy the `secrets.yaml.example` to `secrets.yaml` if it doesn't exist.

    ```bash
    sh setup.sh
    ```

### 2. Generating Secrets & Tokens

Before you can run all the services, you need to populate your `ha-config/secrets.yaml` file with the necessary tokens and passwords. Here’s how to get them.

#### Temporarily Running a Single Service

To get a token from a service (like InfluxDB), you often need to access its web UI. You can start a single service without starting the whole stack using the following command:

```bash
docker-compose up -d <service_name>
```

For example, to start only InfluxDB, you would run `docker-compose up -d influxdb`.

#### 1. Grafana Admin Password

*   **Secret:** `grafana_password`
*   **Action:** Choose a strong, unique password and put it in your `secrets.yaml` file.

#### 2. InfluxDB Admin Token and Password

*   **Secrets:** `influxdb_password`, `influxdb_admin_token`
*   **Action:**
    1.  Choose a strong, unique password for the `influxdb_password` and add it to your `secrets.yaml` file.
    2.  Temporarily start the InfluxDB service:
        ```bash
        docker-compose up -d influxdb
        ```
    3.  Open a web browser and go to `http://homeassistant:8086`.
    4.  You will be guided through the InfluxDB setup process. Use the following values:
        *   **Username:** `ha_admin`
        *   **Password:** The `influxdb_password` you just chose.
        *   **Initial Organization Name:** `homeassistant`
        *   **Initial Bucket Name:** `ha_metrics`
    5.  After the setup is complete, navigate to **Load Data** > **API Tokens** in the InfluxDB UI.
    6.  You will see a token named `<username>'s Token`. Click on the name to view the token.
    7.  Copy this token and paste it into your `secrets.yaml` file as the `influxdb_admin_token`.

##### Getting the InfluxDB Admin Token from the Command Line

If you have already completed the InfluxDB setup and need to retrieve the admin token again, you can run the following command:

```bash
sudo docker exec -it influxdb influx auth list --user ha__admin --json
```

This will output a JSON object containing the token.

#### 3. Home Assistant Long-Lived Access Token


*   **Secret:** `ha_token`
*   **Action:**
    1.  Start the Home Assistant service:
        ```bash
        docker-compose up -d homeassistant
        ```
    2.  Open a web browser and go to `http://homeassistant:8123`.
    3.  Complete the initial Home Assistant setup, creating a user account.
    4.  Once you are logged in, click on your user profile in the bottom left corner.
    5.  Scroll down to the **Long-Lived Access Tokens** section and click **Create Token**.
    6.  Give the token a name (e.g., `appdaemon_token`) and click **OK**.
    7.  **Copy the token immediately.** You will not be able to see it again.
    8.  Paste this token into your `secrets.yaml` file as the `ha_token`.

### 3. Start All Services

Once you have filled in all the necessary secrets in `ha-config/secrets.yaml`, you can start all the services:

```bash
sh start.sh
```

### 4. Post-Installation

*   **Home Assistant:** Access the web interface at `http://homeassistant:8123`.
*   **AppDaemon:** The AppDaemon dashboard is available at `http://homeassistant:5050`.
*   **Grafana:** Log in to Grafana at `http://homeassistant:3000` with the credentials you set in your `secrets.yaml` file.
*   **InfluxDB:** The InfluxDB UI is at `http://homeassistant:8086`.
*   **Glances:** Monitor your system at `http://homeassistant:61208`.

## Using a Private Repository

If you are using a private GitHub repository to store your configuration, you will need to add an SSH key to your Raspberry Pi and GitHub to allow access.

### 1. Checking for Existing SSH Keys

Before generating a new key, it's good practice to check if you already have one. Run the following command to list files in your `.ssh` directory:

```bash
ls -al ~/.ssh
```

Look for files named `id_rsa.pub`, `id_ed25519.pub`, or `id_dsa.pub`. If you see a `.pub` file, you already have a key pair and can skip to the "Add the Public Key to GitHub" step and use the existing key.

### 2. Generate an SSH Key on the Raspberry Pi

If you don't have an existing key, generate a new one. When prompted, you can just press Enter to accept the default file location and skip setting a passphrase.

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### 3. Add the Public Key to GitHub as a Deploy Key

Now, you need to add the public key to your GitHub repository. A deploy key is an SSH key that grants access to a single repository. It can be set to be read-only or read-write.

1.  **Display the public key:**

    ```bash
    cat ~/.ssh/id_ed25519.pub
    ```

2.  **Copy the public key:** Copy the entire output, starting with `ssh-ed25519` and ending with your email address.

3.  **Add the deploy key to GitHub:**
    *   Go to your repository on GitHub.
    *   Click on **Settings** > **Deploy keys**.
    *   Click **Add deploy key**.
    *   Give it a title (e.g., "Raspberry Pi").
    *   Paste the public key into the "Key" field.
    *   **To push changes from the Raspberry Pi back to GitHub**, you must check the **Allow write access** box. If you only want to pull changes, leave it unchecked for a more secure, read-only key.
    *   Click **Add key**.

Now your Raspberry Pi will be able to pull changes from and (optionally) push changes to your private repository.

## Backup and Restore

### Home Assistant

*   **Backup:** Home Assistant's built-in backup functionality will store snapshots in the `ha-config/backups` directory.
*   **Restore:** To restore from a backup, simply place your existing `ha-config` directory in the root of this project before starting the services. The `docker-compose.yaml` file is configured to mount this directory as a volume.

### InfluxDB

It is recommended to set up a regular backup of your InfluxDB data. You can use the `influxd backup` command or a custom script to export the data to a safe location.
