---
title: Qt信号槽解析：信号槽的触发机制分析
toc: true
tags:
  - C++
  - Qt
categories:
  - Qt
date: 2021-03-18 00:57:21
---


# 前言

Qt的**信号槽**机制是Qt有别于其它界面库的一大特色，极大地简化了开发时工作量。对比MFC的MESSAGE_MAP机制，Qt的信号槽简单优雅，类型安全，提供同步异步调用方式，配合MOC编译器自动生成信号函数体，简单，好用。
下面给出Qt中关于信号槽连接方式和跨线程信号槽连接的相关说明：

enum Qt::ConnectionType
这个宏描述了信号槽连接时的连接类型，特别地，它决定了一个特定的信号是立即触发槽函数还是加入队列以便稍后触发。

| 常量 | 值 | 描述 |
|--|--|--|
| Qt::AutoConnection | 0 | (默认) 如果receiver位于发出信号的线程中，则使用Qt::DirectConnection。否则，将使用Qt::QueuedConnection。**连接类型在发出信号时确定。**|
| Qt::DirectConnection | 1 |当发出信号时，将立即调用槽函数。槽函数在信号发送线程中执行。 |
| Qt::QueuedConnection | 2 | 当控制权返回到receiver线程的事件循环时，将调用槽函数。槽函数在receiver的线程中执行。 |
| Qt::BlockingQueuedConnection | 3 | 与Qt::QueuedConnection相同，只是信号发送线程阻塞，直到槽函数返回。如果槽函数位于信号发送线程中，则不能使用此连接，否则应用程序将死锁。|
| Qt::UniqueConnection | 0x80 | 这是一个标志，可以与上述任何一种连接类型结合使用位或。设置Qt::UniqueConnection时，如果连接已存在（即，如果同一信号已连接到同一对对象的同一槽函数），则QObject::connect（）将失败。这个标志是在qt4.6中引入的。 |

<!-- more -->

> 跨线程信号槽
>
> Qt支持以下信号槽连接类型：
>> 自动连接：（默认）如果在接收对象具有亲缘关系的线程中发出信号，则行为与直接连接相同。否则，行为与队列连接相同。
直接连接当信号发出时，立即调用槽函数。槽函数在信号发射的线程中执行，而不一定是receiver的线程。
队列连接：当控制返回到接收方线程的事件循环时，将调用槽函数。槽函数在receiver的线程中执行。
阻塞队列连接：以队列连接的方式调用槽函数，当前线程阻塞，直到槽函数返回。
注意：使用此类型连接同一线程中的对象将导致死锁。
唯一连接：行为与自动连接相同，但只有在不复制现有连接时才建立连接。例如，如果同一信号已连接到同一对对象的同一插槽，则不进行连接，connect()返回false。
>
>可以通过向connect（）传递附加参数来指定连接类型。请注意，如果事件循环正在接收方的线程中运行，那么在发送方和接收方位于不同线程中时使用直接连接是不安全的，原因与对另一个线程中的对象调用任何函数都是不安全的相同。
QObject::connect()本身是线程安全的。

# Qt对象的线程相关性
Thread Affinity
A QObject instance is said to have a thread affinity, or that it lives in a certain thread. When a QObject receives a queued signal or a posted event, the slot or event handler will run in the thread that the object lives in.
Note: If a QObject has no thread affinity (that is, if thread() returns zero), or if it lives in a thread that has no running event loop, then it cannot receive queued signals or posted events.
By default, a QObject lives in the thread in which it is created. An object's thread affinity can be queried using thread() and changed using moveToThread().
All QObjects must live in the same thread as their parent. Consequently:
setParent() will fail if the two QObjects involved live in different threads.
When a QObject is moved to another thread, all its children will be automatically moved too.
moveToThread() will fail if the QObject has a parent.
If QObjects are created within QThread::run(), they cannot become children of the QThread object because the QThread does not live in the thread that calls QThread::run().
Note: A QObject's member variables do not automatically become its children. The parent-child relationship must be set by either passing a pointer to the child's constructor, or by calling setParent(). Without this step, the object's member variables will remain in the old thread when moveToThread() is called. 



# QueuedConnection是如何夸线程调用的



# BlockingQueuedConnection的同步实现机制