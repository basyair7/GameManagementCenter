# 🎮 Game Management Center

## 📌 Overview

**Game Management Center** is a collection of **Bash scripts for
RetroPie** that helps you manage game ROMs through a simple text-based
menu using **whiptail**.

This tool allows you to insert, copy, and delete games, as well as
manage PSX memory cards, without manually navigating folders via
terminal or file manager.

------------------------------------------------------------------------

## ✨ Features

### 🎯 Main Functions

-   Display free storage space
-   Display total number of games
-   Insert games from USB
-   Copy games to USB
-   Delete games or game folders safely
-   PSX memory card management

------------------------------------------------------------------------

## 🚀 Installation

``` bash
git clone https://github.com/basyair7/GameManagementCenter.git
cd GameManagementCenter/RetroPie/scripts
chmod +x *.sh
mkdir /home/pi/RetroPie/scripts
mv *.sh /home/pi/RetroPie/scripts/

chmod +x "Game Management Center.sh"
mv "Game Management Center.sh" /home/pi/RetroPie/retropiemenu/

reboot
```

------------------------------------------------------------------------

## 📄 License

This project is open-source and free to use and modify.

🎮 Enjoy managing your RetroPie games!
