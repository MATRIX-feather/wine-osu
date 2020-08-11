#!/bin/bash
#########################
#   名称: NewScript
#   用途: 负责主要的工作
#########################

#shellcheck disable=SC1090
#shellcheck disable=SC2143

readonly HERE="$( dirname "$(readlink -f "${0}")" )";
readonly RESOURCES="$HERE/resources";

source "$RESOURCES"/script/Statics
source "$RESOURCES"/script/ZenityPush
source "$RESOURCES"/script/Logger

function Dialog()
{
    local Selection;
    Selection="$(zenity --list --radiolist \
                              --title "欢迎回来" --text "要做点什么呢?"\
                              --column "选择" \
                              --column "" \
                              --column "一个项目" \
                              --hide-column=2 \
                              true "Install" "我要为$USERNAME安装osu!" \
                              false "FontPatch" "我要为$USERNAME打CJK字体补丁！"
    )";

    echo "$Selection"; #return不管用？？？
}

function Download()
{
    local re=0;
	local Source="$1";
    local Title="$2";
    local TargetFile="$3";

	putinfo "下载源 $Source($1), 项目名 $Title($2), 输出文件名 $TargetFile($3)";

	for ((re=1;re<=3;re++));do
    {
		wget "$Source" -c -O "$TargetFile" 2>&1 \
		|sed -u "s/^.* \+\([0-9]\+%\) \+\([0-9.]\+[GMKB]\) \+\([0-9hms.]\+\).*$/\1\n# 正在下载$Title... (\2,预计剩余\3)/"\
		|zenity --progress --title="正在下载$Title 第$re次尝试" --auto-close

        if [ "$?" == 0 ];then
        {
            break;
        };fi;

    };done;
}

function CheckEnvironment()
{
    #检查wine版本是否会遇到问题
    if [ -n "$(wine --version | grep -- "-5.")" ];then
    {
        putwarn "如果您在此wine版本中遇到了网络问题，请尝试安装libldap2-dev(Ubuntu)";
    };fi;

    if [ -z "$(command -v winetricks)" ];then
    {
        puterror "没有检测到winetricks! 请确保winetricks已被正确安装在您的设备上。";
        exit 1;
    };fi;
}

function ParseOptionalOptions()
{
    while [ $# -gt 0 ]; do
    {
        case "$1" in
            (GdiPlus)
                putinfo "GdiPlus";
                winetricks gdiplus;
                shift;
                ;;

            (DesktopIcon)
                putinfo "DesktopIcon";
				mkdir -vp "$HOME/.local/share/applications/";
                Download "https://github.com/ppy/osu/raw/master/assets/lazer.png" "osu图标" "$OSUPREFIX/osu.png"
			    if [ "$?" != 0 ];then
			    	puterror "下载时发生了一个错误,这可能会导致快捷方式没有图标,将尝试继续运行..."
			    fi
                cat > "$HOME/.local/share/applications/osu_test.desktop" << EOF
[Desktop Entry]
Encoding=UTF-8
Name=osu!
Comment=节奏一*触*即发!
Type=Application
Exec=env WINEPREFIX=$WINEPREFIX wine osu!.exe
Icon=$OSUPREFIX/osu.png
StartupWMClass=osu!.exe
Categories=
Path=$WINEPREFIX/drive_c/users/$USER/Local Settings/Application Data/osu!
Terminal=false
StartupNotify=false
EOF
                shift;
                ;;

            (Font)
                putinfo "字体: 复制假的Microsoft YaHei";
                cp "$RESOURCES/font/fake-msyh.ttf" "$WINEPREFIX/drive_c/windows/Fonts";

                putinfo "字体: winetricks Tahoma";
                winetricks tahoma;

                putinfo "字体: 注册表补丁";
                wine regedit "$RESOURCES/regedit/patch-Font.reg";

                shift;
                ;;

            (*)
                puterror "包含未知选项：$1";
                shift;;
        esac;
    };done;
}

function RunInstall()
{
    #region 一些基础的东西
    local InstallerFile="";
    local Dotnet40InstallerFile="";
    #endregion

    #region 检查wine
    putinfo "正在检查wine...";
    if [ -z "$(command -v wine)" ];then
    {
        puterror "没有检测到wine! 请确保wine已被正确安装在您的设备上。";
        exit 1;
    };fi;
    #endregion

    #region 准备安装器

    #询问是否要进行本地程序安装
    if [ "$(ZenityPushQuestion "是否要使用本地的osu!installer和.NET 4.0安装?")" -eq 0 ];then
    {
        #使用本地程序
        #region 询问osu!installer的位置
        while(true);do
        {
            Tmp_FileSelection="$(ZenityPushFileSelection "请选择osu!installer的文件位置")";
            if [ -z "$Tmp_FileSelection" ];then
            {
                puterror "你没有选择文件路径！";
                ZenityPushError "你没有选择文件路径！";
            };else
            {
                if [ "$(file -b --mime-type "$Tmp_FileSelection")" != "application/x-dosexec" ];then
                {
                    puterror "选择的文件不是有效的Windows程序！";
                    ZenityPushError "选择的文件不是有效的Windows程序！";
                    continue;
                };fi;

                break;
            };fi;
        };done

        InstallerFile="$Tmp_FileSelection";
        unset Tmp_FileSelection;
        #endregion 询问osu!installer的位置

        #region 询问dotnet40的位置
        while(true);do
        {
            Tmp_FileSelection="$(ZenityPushFileSelection "请选择.NET 4.0安装程序的文件位置")";
            if [ -z "$Tmp_FileSelection" ];then
            {
                puterror "你没有选择文件路径！";
                ZenityPushError "你没有选择文件路径！";
            };else
            {
                if [ "$(file -b --mime-type "$Tmp_FileSelection")" != "application/x-dosexec" ];then
                {
                    puterror "选择的文件不是有效的Windows程序！";
                    ZenityPushError "选择的文件不是有效的Windows程序！";
                    continue;
                };fi;

                break;
            };fi;
        };done

        Dotnet40InstallerFile="$Tmp_FileSelection";
        unset Tmp_FileSelection;
        #endregion 询问dotnet40的位置
    };else
    {
        #不使用本地程序
        #region 下载osu!installer和dotnet40
        putinfo "下载必要的程序...";
        Download "https://m1.ppy.sh/r/osu!install.exe" "osu!installer" "osu_install.exe";
        Download "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe" ".NET 4.0框架" "dotnet40.exe";

        InstallerFile="osu_install.exe";
        Dotnet40InstallerFile="dotnet40.exe";
        #endregion 下载osu!installer和dotnet40
    };fi;

    #endregion 准备安装器

    #检查md5
    if [ "$(md5sum "$InstallerFile" | cut -d ' ' -f1)" != "db95d46aed7de500a31b2fe7d493bef1" ] || [ "$(md5sum "$Dotnet40InstallerFile" | cut -d ' ' -f1)" != "251743dfd3fda414570524bac9e55381" ];then
    {
        puterror "文件md5不匹配，请重试。";
        puterror "Installer $(md5sum "$InstallerFile")";
        puterror "Dotnet40 $(md5sum "$Dotnet40InstallerFile")";
        exit 1;
    };fi;
    ZenityPushInfo "所有东西都准备好了，点击\"确定开始安装\"";

    #region 初始化wine容器

    #初始化wine的环境变量
    readonly WinePrefix="$(ZenityPushDirectorySelection "请选择osu!容器的放置地点")";
    readonly OSUPREFIX="$(ZenityPushDirectorySelection "请选择osu!游戏文件夹的放置地点")";
    export WINEPREFIX="$WinePrefix";
    export WINEARCH=win32;

    #建立目录
    mkdir -vp "$OSUPREFIX";
	mkdir -vp "$WINEPREFIX/drive_c/users/$USERNAME/Local Settings/Application Data";

    #软链
	ln "$OSUPREFIX" "$WINEPREFIX/drive_c/users/$USERNAME/Local Settings/Application Data/osu!" -s;

    #设置wine容器
    wineboot -u;
    winetricks winxp;

    #endregion 初始化wine容器

    #region 预先处理
    local OptionalOptions;
    OptionalOptions="$(zenity --list --checklist --separator=" " \
                              --title "预先处理" --text "以下是建议安装的项目" \
                              --column "选择" --column "" --column "" \
                              --hide-column=2 \
                              TRUE "GdiPlus" "修复游戏内图标显示异常" \
		                      TRUE "DesktopIcon" "应用列表快捷方式" \
		                      TRUE "Font" "修复游戏内字体问题"
    )";
    ParseOptionalOptions $OptionalOptions;
    #endreion 预先处理

    #启动安装程序
    putinfo "正在开始安装...";
    wine "$Dotnet40InstallerFile";
    wine "$InstallerFile";

    #endregion 初始化wine容器
}

function main()
{
    #region 检查环境
    putinfo "正在检查环境...";
    CheckEnvironment;
    #endregion

    case "$(Dialog)" in
        (Install)
            RunInstall;
            ;;
        (FontPatch)
            local main_WinePrefix;
            main_WinePrefix="$(ZenityPushDirectorySelection "请选择osu容器地址")";

            local shouldContinue;
            shouldContinue="$(ZenityPushQuestion "我们将默认您已经预先配置好了osu容器\nosu!容器地址为: $main_WinePrefix\n\n如果没有，请点击\"否\"取消")";
            if [ "$shouldContinue" -eq 1 ];then
            {
                putinfo "中止";
                exit 0;
            };fi;

            export WINEPREFIX="$main_WinePrefix";
            ParseOptionalOptions Font;
            exit 0;
            ;;
        (*)
            puterror "传来了一个未知选项呢(´・ω・\`)";
            exit 1;
            ;;
    esac;
}

main;