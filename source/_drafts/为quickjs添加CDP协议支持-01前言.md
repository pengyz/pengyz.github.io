---
title: 为quickjs添加CDP协议支持 01前言
date: 2021-12-18 22:25:14
tags: 
- quickjs 
- Chrome DevTools Protocol
categories: 
- 技术
- quickjs
---

# 缘起

公司项目中使用了[quickjs](https://github.com/bellard/quickjs.git)作为嵌入式环境下的JS引擎，它是一个纯C库，小巧高效，对标准支持积极，最新支持到ES2020标准。唯一美中不足的是，目前引擎是没有任何调试功能的，在上面写JS代码除了问题没法调试，多少有点不便但还能接受。
后来，我们需要开发IDE给开发者使用（我们做的是一种应用开发框架），这就必须要提供JS调试功能给开发者。为了支持JS调试，我们使用了一个vscode插件[Quickjs Debugger](https://marketplace.visualstudio.com/items?itemName=koush.quickjs-debug)来实现调试功能，它自带了一个[quickjs的修改版]()以提供调试支持。感谢开源社区，我们很愉快地把这个功能移植到了我们的项目中，虽然遇到了一些bug但是无伤大雅，现在我们可调试JS了。
但是好景不长，做IDE的同学不满足于仅仅对JS进行调试，他们希望能显示和调试dom树，显示css等，以尽量符合前端开发者的开发习惯。经过调研，他们决定使用Google Chrome DevTools作为调试前端，把以前基于vscode插件的quickjs调试器对接到DevTools上。

# 初识CDP(Chrome DevTools Protocol)

首先介绍一下[CDP协议](https://chromedevtools.github.io/devtools-protocol/)，官方网站上有如下说明:
> The Chrome DevTools Protocol allows for tools to instrument, inspect, debug and profile Chromium, Chrome and other Blink-based browsers. Many existing projects currently use the protocol. The Chrome DevTools uses this protocol and the team maintains its API.
> 
> Instrumentation is divided into a number of domains (DOM, Debugger, Network etc.). Each domain defines a number of commands it supports and events it generates. Both commands and events are serialized JSON objects of a fixed structure.

简单理解，CDP协议是一套基于JSON的通信协议，它被Chrome DevTools所实现，用于调试Chrome,Chromium等基于Blink的浏览器。也就是说，只要在quickjs中实现一个基于CDP协议的JS调试器后端，我们就可以用DevTools替换掉vscode插件来作为JS调试前端。
在CDP协议中，不同的功能被分割在了不同的域中，如Runtime实现运行时功能，Debugger实现JS调试，DOM实现DOM树查看，Network实现网络功能等。
当前我们只需要关注Debugger域中的内容，基于quickjs来实现调试必备的一些关键消息。我们来看官网中的一个具体的消息描述来做一些讲解：

**Debugger.paused**
Fired when the virtual machine stopped on breakpoint or exception or any other stop criteria.
当虚拟机因断点或异常或任何其他的停止标准而暂停时发送
**PARAMETERS**
| 名称 | 类型 | 描述 | 是否可选 |
|-|-|-|-|
|callFrames| array[ CallFrame ]| 虚拟机暂停时所在堆栈.| 否 |
|reason|string| 暂停原因. <br/>有效值: ambiguous, assert, CSPViolation, debugCommand, DOM, EventListener, exception, instrumentation, OOM, other, promiseRejection, XHR| 否 |
|data|object|包含暂停相关的辅助属性的对象.| 是 |
|hitBreakpoints|array[ string ]|命中的断点ID| 是 |
|asyncStackTrace|Runtime.StackTrace|异步堆栈追踪，如果有的话| 是 |
|asyncStackTraceId|Runtime.StackTraceId| 异步调用堆栈，如果有的话. <br/>**EXPERIMENTAL** | 是 |
|asyncCallStackTraceId|Runtime.StackTraceId|不再提供，将会被移除. <br/>**EXPERIMENTAL DEPRECATED**| 是 |

这段截取自CDP协议官方文档，我们可以看到，针对每一个协议消息，文档详细描述了它所需的参数，大致的含义。文档中给出的含义描述比较简略，也没有具体的功能和实现流程方面的描述，需要我们搭建起开发环境后通过观察CDP协议标准实现——Chrome浏览器的协议消息发送和响应流程慢慢理解。

**一些参考资料**


# 开发环境搭建
我们的目标是开发一个标准的CDP协议的Server以配合devTools实现调试功能，就像Chrome浏览器做的那样。
万里长城第一步，我们需要搭建相应的开发环境。