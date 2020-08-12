# osu_script

## 介绍
一个脚本搞定osu!stable在linux上的安装，附中日韩字体解决方案

## 软件架构
i386/amd64

## 安装教程

### 懒人式

复制以下指令，粘贴到终端中(需要预先安装git)\
`git clone https://gitee.com/matrix-feather/osu_script.git && cd osu_script.git && chmod +x ./Install.sh && ./Install.sh`

### 详细步骤

1. 克隆仓库
2. 给予`Install.sh`运行权限
3. 在终端中运行`Install.sh`
4. 如果勾选了应用列表快捷方式，此时在`~/.local/share/applications`下应该会生成一个`wine-osu.desktop`
    5. 在启动器中找到`osu!`, 点击即可开玩


## 效果图

![?](https://s1.ax1x.com/2020/08/12/avbKQf.png)
![?](https://s1.ax1x.com/2020/08/12/avbQOS.png)
![?](https://s1.ax1x.com/2020/08/12/avbuSP.png)
![?](https://s1.ax1x.com/2020/08/12/avbMy8.png)

## 使用说明

1.  在Deepin V20上您可能需要使用deepin-wine5运行osu!以避免编辑器顶栏黑条问题 
2.  GDI+可能会因为网络问题而安装失败
3.  ~~目前还没有找到能解决韩文堆在一起的方法~~(已通过安装[malgun](https://zh.wikipedia.org/zh-hans/Malgun_Gothic)字体解决)

## TODO
- [x] 修复韩文堆在一起的问题
- [ ] 解决字体偏高的问题 (*需要帮助*)
- [ ] 解决泰文不显示, 显示为方框的问题 (*需要帮助: 找不到字体, 网上也查不到*)

## 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request
