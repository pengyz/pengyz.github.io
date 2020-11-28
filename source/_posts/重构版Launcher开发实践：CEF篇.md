---
title: 重构版Launcher开发实践01：CEF篇
tags:
  - C++
  - CEF
date: 2020-11-27 00:48:05
---


# 1. 重构版Launcher的技术方案

多厂商Launcher本身是一个使用QT作为界面库，CEF作为内嵌浏览器，使用C++语言进行开发的桌面程序。多厂商Launcher存在很多的问题，在决定重构之后，对后续的技术方案进行了一番考量，具体的对比如下：
||多厂商|重构版|
|--|--|--|
|Qt版本|5.6.3|5.12.6|
|CEF版本|76.0.3809.162 **支持XP+** |86.0.4044.132 **支持win7+**|
|VS版本|VS 2013| VS 2017|
|构建系统|VS工程+CMake|CMake|
|版本升级方式|大网易的补丁升级系统|ngl-pacman工具|
下面是一些简单的说明：
* 重构版Launcher不再支持xp，故Qt版本选用了最新的LTS版本，VS版本选用2017方便使用更新的C++标准。 
* 内嵌浏览器考虑过使用QtWebEngine，此模块是Qt官方对chromium进行的封装，可以方便地与Qt程序集成，但后续考虑到游戏内商城需要进行离屏渲染， QtWebEngine未开放相应接口，故放弃，继续使用CEF但对CEF版本进行了升级。
* 对工程结构进行了整理和简化，全部使用CMake进行构建，可以方便地跨平台，VS2017本身也对CMake提供了良好的支持。
* 大网易的补丁升级系统更适合对游戏进行升级，需要依次应用所有补丁，过于繁琐。创建了一个独立进程完成升级功能，可以跨版本进行升级。

# 2. 内嵌浏览器

重构版Launcher


# 3. CEF的封装和使用

## 3.1. CEF简介
Chromium Embedded Framework (CEF)是一个将基于Chromium的浏览器嵌入到应用程序中的简单框架。
> ### 背景
> The Chromium Embedded Framework (CEF)是一个由Marshall Greenblatt于2008年创建的开源项目，旨在开发基于Google Chromium项目的Web浏览器控件。CEF目前支持一系列编程语言和操作系统，可以很容易地集成到新的和现有的应用程序中。它从一开始就考虑到性能和易用性。基础框架包括通过本地库导出的C和C++编程接口，它们将宿主应用与Chromium和Blink的实现细节隔离。它提供浏览器控件和宿主应用程序之间的紧密集成，包括对自定义插件、协议、JavaScript对象和JavaScript扩展的支持。主机应用程序可以选择性地控制资源加载、导航、上下文菜单、打印等，同时获得与Google Chrome浏览器相同的性能优势和HTML5技术支持。
> ### 依赖
> CEF项目依赖于由第三方维护的许多其他项目。CEF依赖的主要项目有：
> 
> * Chromium - 提供创建一个功能齐全的Web浏览器所需的网络堆栈、线程、消息循环、日志记录和进程控制等常规功能。实现允许Blink与V8和Skia通信的“平台”代码。许多Chromium设计文件可以在 http://dev.chromium.org/developers 找到。
> * Blink（以前叫WebKit）——Chromium使用的渲染实现。提供DOM解析、布局、事件处理、呈现和html5 Javascript API。一些HTML5实现在被分散在Blink和Chromium代码库之间。
> * V8 - JavaScript 引擎.
> * Skia - 用于渲染非加速内容的二维图形库。关于铬是如何整合Skia的更多信息可以在 *[这里](http://www.chromium.org/developers/design-documents/graphics-and-skia)* 找到。
> * Angle - 为Windowsi同实现的3D图形转换层，用于将GLES调用转换为DirectX调用。有关加速合成的更多信息，请访问 *[此处](http://dev.chromium.org/developers/design-documents/gpu-accelerated-compositing-in-chrome)* 。
> 
> ### CEF3实现细节
> 自2013年1月以来，CEF3一直是CEF的推荐和支持版本。它通过Chromium Content API来使用与Chromium Web浏览器相同的多进程体架构。与使用单进程体架构的 CEF1（已废弃）相比，该体系结构具有许多优势：
> 
> * 支持多进程运行模式
> * 与Chromium浏览器共享更多代码
> * 基于上一条，由于使用了“受支持”的代码路径，因此性能得到了改善，功能破坏次数更少。
> * 更快地跟进Chromium更新以访问新功能
> 在大多数情况下，CEF3将具有与Chromium Web浏览器相同的性能和稳定性特性。

## 3.2 CEF的简单使用


### 3.2.1 Chromium的多进程架构

![](重构版Launcher开发实践：CEF篇/IMG_2020-11-28-19-26-55.png)

