#!/bin/bash
ask_dialog(){
	while(true);do
		ans=$(zenity --list --title "欢迎回来" --text "要做什么呢owo?" --radiolist  --column "选择" --column "" --column "一个项目"\
		 TRUE "1" "我要为 $USERNAME 手动安装osu!" \
		 FALSE "2" "我要为 $USERNAME 卸载osu!" \
		 FALSE "3" "我要退出");
		ans_stat="$?"
		echo "$ans $ans_stat"
		if [ $ans_stat == 0 ];then break;fi
		if [ $ans_stat == 3 ];then break;fi
	done
	return $ans
}

do_nothing(){
	echo "do nothing..."
}

download(){
	ret=1;
	echo "下载源 $1, 项目名 $2, 输出文件名 $3"
	for ((re=1;re<=3;re++));do
		wget "$1" -c -O "$3" 2>&1 \
		|sed -u "s/^.* \+\([0-9]\+%\) \+\([0-9.]\+[GMKB]\) \+\([0-9hms.]\+\).*$/\1\n# 正在下载$2... (\2,预计剩余\3)/"\
		|zenity --progress --title="正在下载$2 第$re次尝试" --auto-close
		ret="$?"
		if [ $ret == 0 ];then
			echo "#下载完成";
			return 0;
		fi
	done
	return $ret;
}

download_basics(){
	echo "下载源 $1, 项目名 $2, 输出文件名 $3"
	for ((re=1;re<=3;re++));do
		wget "$1" -c -O "$3" 2>&1 \
		|sed -u "s/^.* \+\([0-9]\+%\) \+\([0-9.]\+[GMKB]\) \+\([0-9hms.]\+\).*$/\1\n# 正在下载$2... (\2,预计剩余\3)/"\
		|zenity --progress --title="正在下载$2 第$re次尝试" --auto-close
		ret="$?"
		if [ $ret == 0 ];then
			echo "#下载完成";
			return 0;
		else
			logerror "下载时出现了一个错误,安装程序无法进行";
			exit 1;
		fi
	done
}

logerror(){
	echo "[`date +%T`][错误]: $2:$1" >> ./mflog.log
	if [ "$2" == "" ];then
		title="错误!"
	fi
	if [ "$3" == "" ];then
	zenity --error --title="$title" --text="$1" --ellipsize
fi
}

logwarn(){
	echo "[`date +%T`][警告]: $1" >> ./mflog.log
	if [ "$2" == "" ];then
		title="警告!"
	fi
	if [ "$3" == "" ];then
		zenity --warning --title="$title" --text="$1" --ellipsize
	fi
}

loginfo(){
	echo "[`date +%T`][信息]: $1" >> ./mflog.log
	if [ "$2" == "" ];then
		title="信息"
	fi
	if [ "$3" == "" ];then
		zenity --info --title="$title" --text="$1" --ellipsize;
	fi
}

logquestion(){
	echo "[`date +%T`][询问]: $1"; >> ./mflog.log
	zenity --question --ellipsize --text="$1";
	if [ "$?" == 0 ];then
		echo "是";
		return 0;
	else
		echo "否"
		return 1;
	fi
}

create_desktop_file(){
			echo "#下载osu图标"...
			download "https://github.com/ppy/osu/raw/master/assets/lazer.png" "osu图标" "$OSUPREFIX/osu.png"
			if [ $? != 0 ];then
				logerror "下载时发生了一个错误,这可能会导致快捷方式没有图标,将尝试继续运行..."
			fi
			echo "[Desktop Entry]
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
StartupNotify=false" > "$HOME/.local/share/applications/osu_test.desktop";
}

new_terminal_execute(){
	comment="$1";
	cmd="$2";
	gnome-terminal -- bash -c "echo $1 && $2 ";
	return $?
}

ins_choise_parser(){
	while [[ $# -gt 0 ]]; do
		case $1 in
			gdiplus)
				winetricks gdiplus;
				shift;
				;;
			桌面图标)
				mkdir -vp "$HOME/.local/share/applications/";
				create_desktop_file;
				shift;
				;;
			*)
				break;
				shift;
				;;
		esac
	done
}

check_wine_version(){
			#确定wine版本
			if [ "$(wine --version | grep wine-4)" != "" ]; then wine_version=4;echo "#找到wine 4.x"; #4.x
				else if [ "$(wine --version | grep wine-5)" != "" ]; then wine_version=5;echo "#找到wine 5.x"; #5.x
					else 																			#都不是
						echo "#注意!我们找到了wine,但是无法确定它的版本,请手动选择一个";
						wine_version=$(zenity --list --title "确定wine版本" --text "请选择一项" --radiolist  --column "" --column "忽略这栏" --column "版本号"\
						FALSE "2" "我无法确定版本"\
						FALSE "3" "更低版本"\
				 		TRUE "4" "4.x" \
				 		FALSE "5" "5.x" \
				 		FALSE "6" "更高版本" );
					fi;
			fi;
			echo "#wine已找到:\n$(wine --version) @ $wine_version";
}

basic_install(){
	software="$1";
	exit_or_not="$2";
	new_terminal_execute "安装$software" "sudo apt install $software"
	loginfo "请在安装好$software后点击 \"确定\" ";
	if [ "$exit_or_not" == "true" ];then
		if [ "$(which $software)" == "" ];then
			logerror "$software安装失败,将取消安装";
			exit 1
		fi
	fi
}

install(){
	#检测wine
	if [ "$(which wine)" == "" ]; then 
		logerror "错误:未找到wine,将尝试安装" #尝试安装wine
		new_terminal_execute "安装wine" "sudo apt install wine"
		loginfo "请在安装好wine后点击 \"确定\" "
		if [ "$(which wine)" == "" ];then #如果执行完之后仍找不到,则直接退出
			logerror "wine安装失败,将取消安装";
			exit 1;
			else
				check_wine_version;
		fi
		else
			check_wine_version;
	fi
	#检测wine end
	#判断wine版本以采取对应的措施
	if [ "$wine_version" == 5 ];then 
		echo "#bug修复: 无法联网..."
		basic_install "libldap2-dev" false;
	fi
	#检查winetricks
	if [  "$(which winetricks)" == "" ];then
		echo "#安装前置工具 winetricks..."
		basic_install "winetricks";
	fi
	#询问是否下载了osu!installer
	echo "#准备安装所需文件"
	logquestion "请问是否已经下载好了osu!installer.exe?"
	if [ $? == 0 ];then
		#已经下载好了,选择文件
		while(true);do
			installer_path=`zenity --file-selection --title="请选择osu!installer的文件位置"`
			if [ "$installer_path" == "" ];then #是否手残或者故意不选
				logerror "你没有制定osu!安装器的位置!" "未指定安装器"
			else
				zenity --ellipsize --question --title="请确认!" --text="osu!安装程序位置 $installer_path\n\nwine版本 $wine_version" --ok-label="确认" --cancel-label="重新选择"
				if [ $? == 0 ];then
				 	if [ $(file -b --mime-type "$installer_path") != "application/x-dosexec" ];then
					 	logerror "选择的目标不是Windows可执行文件"
					 	#zenity --ellipsize --error --title="错误!" --text="选择的目标不是Windows可执行文件";
						 continue;
					fi
					break;
				fi
			fi
		done;#选择文件 end
	else #如果没下载好 则下载文件
		for ((re=1;re<=3;re++));do
			download_basics "https://m1.ppy.sh/r/osu!install.exe" "osu!installer" "osu_install.exe";
			if [ $? == 0 ];then
				installer_path="$PWD/osu_install.exe";
				echo "#下载完成";
				break;
			fi
		done
	fi #osu!installer end
	#下载.NET
		download_basics "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe" ".NET 4.0框架" "dotnet40.exe"
		if [ $? == 0 ];then
			dotnet40="$PWD/dotnet40.exe";
			echo "#下载完成";
		fi
	#下载.NET end
		echo "#开始安装"
		zenity --info --text="所有文件都下载好了,点击确定开始安装"; 
		logwarn "将要进行的操作拥有一定的玄学性质,因此请勿在安装的过程中改变安装目录!"
		#zenity --ellipsize --warning --title="注意!" --text="将要进行的操作拥有一定的玄学性质,因此请勿在安装的过程中改变安装目录!"

		#选择安装位置
		while(true);do
			export WINEPREFIX=`zenity --directory --file-selection --title="请选择osu!容器的放置地点"`
			export OSUPREFIX=`zenity --directory --file-selection --title="请选择osu!游戏文件夹的放置地点"`
			zenity --ellipsize --question --title="请确认!" --text="osu!容器位置 $WINEPREFIX\n\nosu游戏文件夹位置 $OSUPREFIX" --ok-label="确认" --cancel-label="重新选择"
			if [ $? == 0 ];then
				break;
			fi
		done

		echo "创建目录及软链..."
		mkdir "$OSUPREFIX"
		mkdir -vp "$WINEPREFIX/drive_c/users/$USERNAME/Local Settings/Application Data"
		ln "$OSUPREFIX" "$WINEPREFIX/drive_c/users/$USERNAME/Local Settings/Application Data/osu!" -s
		#开始执行操作
		echo "#现在请根据提示进行操作,不要安装wine-mono和wine-gecko"
		export WINEARCH=win32;
		wineboot -u
		echo "#步骤:在\"Windows版本\"栏选择\"Windows XP\"后点击\"确定\",不要安装wine-mono和wine-gecko"
		winecfg
		echo "#步骤:跟随提示安装.NET\n这个步骤可能会耗时半小时以上,具体时间视性能而定"
		wine ./dotnet40.exe
		echo "#步骤:预处理"
		ins_choise=$(zenity --list --title "预处理" --text "以下是建议安装的项目" --checklist --separator=" " --column "选择" --column "" --column ""\
		TRUE "gdiplus" "修复游戏内图标显示异常"\
		TRUE "桌面图标" "应用列表快捷方式");
		ins_stat="$?"
		echo "$ins_choise $?"
		ins_choise_parser $ins_choise;
		echo "#步骤:安装osu!"
		wine "$installer_path"
		wineserver -w

		echo "#安装已完成"
		echo "$WINEPREFIX" > ./osuinfo
		echo "$OSUPREFIX" >> ./osuinfo
		loginfo "安装信息已被记录在osuinfo中,可用于卸载osu"
		return 0;
}

uninstall(){
	loginfo "步骤:从osuinfo读取信息" "2" "3"
	while(true);do
		osuinfo_path=`zenity --file-selection --title="请选择osuinfo文件的位置"`
		if [ "$osuinfo_path" == "" ];then
			logerror "osuinfo文件位置为空"
		fi
		logquestion "osuinfo文件位置 $osuinfo_path, 你确定吗?"
		if [ $? == 0 ];then
			break;
		fi
	done
	WINEPREFIX=`sed -n '1,1p' "$osuinfo_path"`
	OSUPREFIX=`sed -n '2,2p' "$osuinfo_path"`
	loginfo "wineprefix=$WINEPREFIX" "2" "3"
	loginfo "osuprefix=$OSUPREFIX" "2" "3"
	while(true);do
		logquestion "osu容器位置 $WINEPREFIX \nosu游戏位置 $OSUPREFIX \n你确定吗?"
		if [ $? == 0 ];then
			break;
		fi
	done
	wineserver -k
	rm -rf "$WINEPREFIX"
	rm -rf "$OSUPREFIX"
	rmdir "$WINEPREFIX"
	rmdir "$OSUPREFIX"
	rm "$HOME/.local/share/applications/osu_test.desktop"
	loginfo "完成"
}

while [[ $# -gt 0 ]]; do
	arg=$1
	case $1 in 
		*)
			echo "脚本暂不支持任何参数 :(";
			exit 1;
			;;
	esac
done
: main
rm ./mflog.log

if [ ! -f /etc/debian_version ]; then
	logerror "发行版非debian系OS :("
	exit 1;
fi


ask_dialog;
ask_dialog_stat="$?"
case $ask_dialog_stat in
	1)
		echo "install";
		install | zenity --progress --pulsate --text="等待输出中...";
		;;
	2)
		uninstall;
		echo "uninstall";
		;;
	3)
		echo "exit";
		exit 0;
		;;
esac
exit
