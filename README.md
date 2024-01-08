
To install the Babylon Node using the Auto-Installer script from your GitHub repository, follow these steps:

Step 1: Open Terminal
Open a terminal on your Ubuntu system. You can find it in your applications menu or press Ctrl + Alt + T.

Step 2: Download the Script
Use wget or curl to download the script from your GitHub repository. If wget is not installed on your system, you can install it using sudo apt install wget. To download the script, run:


wget https://raw.githubusercontent.com/avocadodefi/Babylon-Node-Auto-Installer/main/babylon_setup.sh

Or using curl:

curl -O https://raw.githubusercontent.com/avocadodefi/Babylon-Node-Auto-Installer/main/babylon_setup.sh

Step 3: Make the Script Executable
Before running the script, it needs to be made executable. Change the file permissions using the chmod command:

chmod +x babylon_setup.sh

Step 4: Run the Script

Now, you can run the script. Some steps in the script might require superuser privileges, so it's recommended to run it with sudo:

sudo ./babylon_setup.sh
