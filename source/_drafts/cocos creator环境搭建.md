---
title: cocos creator环境搭建
date: 2016-06-06 18:53:17
tags: 
- 开源游戏
- cocos creator
categories: 
- 技术文档
- 游戏开发
---

扯淡：论如何成为游戏开发者
===

自己做游戏或许是一个在我脑子里呆了足够长事的点子，长到我自己都不记得这个念头产生的具体时间。大概是从小学开始的小霸王到初中的war3到高中的各种网游的长期熏陶产生的。

对我来说，做游戏，是一个很好玩的事情，为了这个想法，我跑去了计算机专业。很遗憾的是毕业后却跑去做了网站。时至今日，移动端游戏如火如荼，我也偶然认识了一群想要重置恶魔城游戏的人，这也促使我重新考虑这个问题：***如何成为一个独立游戏开发者？***

其实我并不是太清楚这个问题的答案，对我来说也没有什么所谓的标准答案。我的想法很简单：***Just Do It***

于是兴致勃勃地跑去在github上起一个开源项目，每天自娱自乐地写一点，貌似是个看着还不错的主意。

或许我还远当不了独立游戏开发者这个称谓，那就让我尝试成为一个game coding monky。

为什么是cocos2d和cocos creator
====

对于游戏开发而言，其实unity会是一个更好的选择。那对我来说，重制一款2d动作游戏，为什么会选cocos2d？

这个其实没有经过太多的考量：也许是更喜欢研究一些底层实现，也许是不爽unity和C#，也许是对UE4高山仰止？开始考虑过用coocos2d-x，用C++写，因为它是我的主语言。但是后面发现了cocos creator，下载下来玩了下，感觉更像是一个unity，只是语言是js。就使用体验来说，这个还是挺不错的，组件化编程的灵活性确实优于继承。js的灵活性也是C++望尘莫及的。加上一个完善的正在成长中的开发环境和自己喜欢折腾的性格，结论就是：不错，就是它吧。

Windows上的Cocos Creator环境搭建
===
1. 直接从[官网](http://www.cocoscreator.com/)下载cocos creator的最新版本: 
{%qnimg cocosCreatorDownload.png title:cocos下载 alt:cocos下载%}
2. 运行安装程序并等待安装结束
{%qnimg installing.png title:cocos安装过程 alt:cocos安装过程%}
3. 安装结束后打开cocos creator，新建项目,新手可以看看范例集合
{%qnimg NewProject.png title:cocos creator 新建项目 alt:cocos creator 新建项目%}

修改默认js编辑器
---
1. 官方自带的编辑器功能有限，高亮还可以，提示做的不全，官方的建议是要替换默认的js编辑器到vscode，从微软的[vscode官网](https://www.visualstudio.com/en-us/products/code-vs.aspx)下载最新的vscode
{%qnimg downloadCode.png title:vscode下载页面 alt:vscode下载页面%}
2. 安装vscode，一般默认安装即可。
3. cocos creator中选择Cocos Creator->偏好设置
{%qnimg phsettings.png title:cocos creator偏好设置 alt:cocos creator偏好设置%}

4. 在打开的窗口中的左侧选项卡中选择数据编辑，在第一项 ***外部脚本编辑器***右边点击预览
{%qnimg visitEditor.png title:外部数据编辑器 alt:外部数据编辑器%}
5. 找到vscode所在路径，win7一般位于 ***C:\Program Files (x86)\Microsoft VS Code*** 路径下，选中 ***Code.exe*** ,同样，外部图片编辑器可以用同样的方式设置到photoshop，前提是你有安装过。
6. 在cocos creator中更新vscode插件并生成vscode所需的js智能提示数据(前两个菜单项依次执行)，执行结束后重启vscode
{%qnimg updateVsCodeData.png title:安装插件并生成智能提示数据 alt:安装插件并生成智能提示数据%}

7. js编辑器设置结束，现在可以愉快地在cocos creator中双击脚本，然后打开vscode来编辑了。
