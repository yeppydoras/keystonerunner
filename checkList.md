git commit 前的 checkList:
1. 修改 KeystoneRunner.toc 中的 Version [後面代稱為 $version ]
1. 修改 changelog.txt，增加版本號和版本描述


打包發佈至 curseForge.com 的 checkList:
1. 修改 git clone 文件夾的 _deploy.cmd 檔案，將「C:\Program Files (x86)\World of Warcraft」修改為自己的遊戲安裝位置
1. run _deploy.cmd，目的是僅將需要的檔案複製到遊戲安裝位置，其他檔案保留在 git clone 文件夾就好
1. 登入 WoW，檢查 keyStone Runner 是否正常運作
1. 退出 WoW，將 World of Warcraft\_retail_\interface\addons\KeystoneRunner 文件夾 pack 成 zip 檔案（推薦使用 7-zip）
1. 將剛剛 pack 出的 zip 檔改名為 $version.zip，例如： 2.17.zip
1. 登入 curseForge，來到 https://wow.curseforge.com/projects/keystone-runner/files
1. 點「File」按鈕，「選擇檔案」，選擇剛剛 pack 出並改名的 zip 檔
1. Display Name 填寫 $version，例如： 2.17
1. Release Type 一般選 「Release」
1. Changelog 把整個 changelog.txt 檔案的內容複製進來就好
1. Supported Game Versions 選最新的遊戲版本就好
1. 點「Submit File」
1. 等待 Status 變更為：Approved，完成
