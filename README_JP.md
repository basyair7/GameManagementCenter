# 🎮 Game Management Center

ゲーム管理センター

## 📌 概要

**Game Management Center** は、**RetroPie 用の Bash
スクリプト集**です。\
whiptail を使ったテキストメニューで、ゲーム ROM を簡単に管理できます。

------------------------------------------------------------------------

## ✨ 機能

### 🎯 主な機能

-   空きストレージ容量の表示
-   ゲーム総数の表示
-   USB からゲームを追加
-   USB へゲームをコピー
-   ゲームの安全な削除
-   PSX メモリーカード管理

------------------------------------------------------------------------

## 🚀 インストール方法

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

## 📄 ライセンス

本プロジェクトはオープンソースで、自由に使用・改変可能です。

🎮 RetroPie のゲーム管理をお楽しみください！
