---
title: QT拾遗 part1 从消息循环说起
date: 2017-07-22 15:50:06
tags:
- C++
- QT
categories:
- QT
---

# 从main函数看QT程序的执行过程

一个典型的QT程序会拥有如下代码：
{% codeblock main.cpp lang:cpp %}
#include "mainwindow.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    w.show();
    
    return a.exec();
}

{% endcodeblock %}

我们知道，a.exec()会启动消息循环来处理窗体显示过程中的各种消息，QT窗体才可以正常地显示并相应各种输入消息。这里其实是有一个疑惑在的：
>> a.exec()到底是如何启动这个QApplication中的消循环的？各种QT消息又是如何发送到这个消息循环中的？如果有多个消息循环嵌套，会怎么样？

所幸的是，我们可以通过调试QT源码来尝试揭开这些谜题。
问卷
