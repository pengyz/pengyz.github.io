---
title: 重构版Launcher开发实践01：CEF篇
toc: true
tags:
  - C++
  - CEF
categories:
  - 技术
  - CEF
date: 2020-11-27 00:48:05
---

# 1. 重构版Launcher的技术方案

## 简单的对比
多厂商Launcher本身是一个使用QT作为界面库，CEF作为内嵌浏览器，使用C++语言进行开发的桌面程序。多厂商Launcher存在很多的问题，在决定重构之后，对后续的技术方案进行了一番考量，具体的对比如下：

||多厂商|重构版|
|--|--|--|
|Qt版本|5.6.3|5.12.6|
|CEF版本|76.0.3809.162 (支持XP+) |86.0.4044.132 (支持win7+)|
|VS版本|VS 2013| VS 2017|
|构建系统|VS工程+CMake|CMake|
|版本升级方式|大网易的补丁升级系统|ngl-pacman工具|
|打包方式|bash脚本和cmd脚本|bash脚本|

<!-- more -->

下面是一些简单的说明：
* 重构版Launcher不再支持xp，故Qt版本选用了最新的LTS版本，VS版本选用2017方便使用更新的C++标准。 
* 内嵌浏览器考虑过使用QtWebEngine，此模块是Qt官方对chromium进行的封装，可以方便地与Qt程序集成，但后续考虑到游戏内商城需要进行离屏渲染， QtWebEngine未开放相应接口，故放弃，继续使用CEF但对CEF版本进行了升级。
* 对工程结构进行了整理和简化，全部使用CMake进行构建，可以方便地跨平台，VS2017本身也对CMake提供了良好的支持。
* 大网易的补丁升级系统更适合对游戏进行升级，需要依次应用所有补丁，过于繁琐。创建了一个独立进程完成升级功能，可以跨版本进行升级。


## 内嵌浏览器需要完成的功能

Launcher本身是一个重Web的项目，开发过程中考虑过使用Electron来实现，但纯web技术栈做游戏Launcher存在不少的限制，安全性上也存在很大的挑战，最终走回了应用内嵌浏览器的解决方案。内嵌浏览器需要完成如下功能：
* 提供浏览器环境，加载和显示网页。
* 将C++函数暴露给浏览器，提供底层数据存储，游戏下载，npl stub集成功能。
* 支持传入和触发JavaScript回调。
* 支持绑定native属性到JavaScript环境。
* 为网页提供跨页面数据访问和事件注册/触发功能。
* 提供离屏渲染功能用于显示游戏内商城。

基于以上需求，重构版使用了一个开源的CEF QT封装层QCefView并对它进行了大量的改造，添加了基于Qt反射的函数和属性自动绑定层，对离屏渲染进行了实现。


# 2. CEF介绍

Chromium Embedded Framework (CEF)是一个将基于Chromium的浏览器嵌入到应用程序中的简单框架。
> ## 背景
> The Chromium Embedded Framework (CEF)是一个由Marshall Greenblatt于2008年创建的开源项目，旨在开发基于Google Chromium项目的Web浏览器控件。CEF目前支持一系列编程语言和操作系统，可以很容易地集成到新的和现有的应用程序中。它从一开始就考虑到性能和易用性。基础框架包括通过本地库导出的C和C++编程接口，它们将宿主应用与Chromium和Blink的实现细节隔离。它提供浏览器控件和宿主应用程序之间的紧密集成，包括对自定义插件、协议、JavaScript对象和JavaScript扩展的支持。宿主应用程序可以选择性地控制资源加载、导航、上下文菜单、打印等，同时获得与Google Chrome浏览器相同的性能优势和HTML5技术支持。
> ## 依赖
> CEF项目依赖于由第三方维护的许多其他项目。CEF依赖的主要项目有：
> 
> * Chromium - 提供创建一个功能齐全的Web浏览器所需的网络堆栈、线程、消息循环、日志记录和进程控制等常规功能。实现允许Blink与V8和Skia通信的“平台”代码。许多Chromium设计文件可以在 http://dev.chromium.org/developers 找到。
> * Blink（以前叫WebKit）——Chromium使用的渲染实现。提供DOM解析、布局、事件处理、呈现和html5 Javascript API。一些HTML5实现被分散在Blink和Chromium代码库之间。
> * V8 - JavaScript 引擎.
> * Skia - 用于渲染非加速内容的二维图形库。关于Chrome是如何整合Skia的更多信息可以在 *[这里](http://www.chromium.org/developers/design-documents/graphics-and-skia)* 找到。
> * Angle - 为Windows实现的3D图形转换层，用于将GLES调用转换为DirectX调用。有关acclerated composing的更多信息，请访问 *[此处](http://dev.chromium.org/developers/design-documents/gpu-accelerated-compositing-in-chrome)* 。
> 
> ## CEF3实现细节
> 自2013年1月以来，CEF3一直是CEF的推荐和支持版本。它通过Chromium Content API来使用与Chromium Web浏览器相同的多进程体架构。与使用单进程体架构的 CEF1（已废弃）相比，该体系结构具有许多优势：
> 
> * 支持多进程运行模式
> * 与Chromium浏览器共享更多代码
> * 基于上一条，由于使用了“受支持”的代码路径，因此性能得到了改善，功能破坏次数更少。
> * 更快地跟进Chromium更新以访问新功能
> 在大多数情况下，CEF3将具有与Chromium Web浏览器相同的性能和稳定性特性。

Chromium的多进程架构
> ![](重构版Launcher开发实践：CEF篇/IMG_2020-11-28-19-26-55.png)



# 3 C++和JavaScript的互调用

## C++调用JavaScript
CEF提供了相应的接口可以直接使用
````C++
browser->GetMainFrame()->ExecuteJavaScript("__GDATA__.toogleLogin();");
````

## JavaScript调用C++

### 1. CefV8Handler接口

CEF提供了标准的函数执行接口CefV8Handler，所有Native方法都必须实现此接口
````C++

class CefV8Handler : public virtual CefBaseRefCounted {
 public:
  //当JavaScript函数执行时会调用此接口
  virtual bool Execute(const CefString& name,
                       CefRefPtr<CefV8Value> object,
                       const CefV8ValueList& arguments,
                       CefRefPtr<CefV8Value>& retval,
                       CefString& exception) = 0;
};
````

### 2. 实现CefV8Handler接口
````C++
//继承CefV8Handler
class QCefFunctionObject : public CefV8Handler {
public:
    virtual bool Execute(const CefString& name, CefRefPtr<CefV8Value> object, const CefV8ValueList& arguments, CefRefPtr<CefV8Value>& retval, CefString& exception) OVERRIDE
    {
      printf("function: %s executed!\n", name.toStdString().c_str());
    }
    
    ....
};
````

### 3. 调用V8接口创建Native JavaScript函数
````C++
//创建handler
CefRefPtr<QCefFunctionObject> functionHandler = new QCefFunctionObject();
//通过handler创建函数对象
CefRefPtr<CefV8Value> func = CefV8Value::CreateFunction(funcInfo.name.toStdWString(), functionHandler);
//获取页面全局window对象
CefRefPtr<CefV8Value> objWindow = context->GetGlobal();
//将函数对象插入到window对象中
objWindow->SetValue("test", func, V8_PROPERTY_ATTRIBUTE_NONE);
````
### 4. 在控制台执行如下JavaScript函数
````javascript
window.test();
````
得到输出：function: test executed!

# 4. 偷该偷的懒：自动绑定的缘由和构想

Launcher中界面主要由web构建，如果按照MVC模式进行分层，Web处于View和Controller层，C++更多时候充当一个model层：提供游戏下载安装信息，stub功能集成，窗口的打开关闭控制等。C++通过注册Native函数到JavaScript中，为web提供增强功能，以便web更好地实现业务功能。
基于这种逻辑分层关系，随着业务需求的变更，C++经常要和web协商添加新的接口，注册新的函数到JavaScript中，所以简化这个注册流程是很有必要的，可以有效地降低开发工作量。

## 4.1 动机：手动注册的弊端
如果我们手动来给每一个C++函数做绑定，我们需要在两个项目中同时添加代码，繁琐而且容易出错。
在Browser进程响应IPC消息的时候，我们的代码中必然会出现一个如下分派代码：
````C++
if (functionName == "getWebId") {
  //调用getWebId
  auto strWebId = obj.getWebId();
  ...
} else if (functionName == "startDownload") {
  //调用startDownload
  auto gameVersion = params.GetString(0);
  auto downloadPath=params.GetString(1);
  auto result = obj.startDownload(gameVersion, downloadPath);
  ...
} else if (...) {
  ...
}
````
因为JavaScript是一种动态脚本，而C++是编译型强类型语言，因此收到IPC消息后要根据C++函数签名对参数数量和类型做合法性校验，写起来很繁琐。

在Render进程的CefV8Handler::Execute接口中，我们需要手动去拼接IPC消息，
每当添加一个新的JavaScript接口，都需要在此处添加新的序列化代码。这种重复性的工作最好能交给程序自动完成而不需要人工介入，这样就可以尽可能地简化工作量，提高开发效率。

**说了这么多，主要还是我们懒**

## 4.2 可行性：IPC调用和本地调用的等价转换

**一个典型的JavaScript接口调用过程**
![](重构版Launcher开发实践：CEF篇/IMG_2020-12-02-11-51-03.png)

可以看到，C++函数本身位于Browser进程（Launcher进程）中，JavaScript函数到额执行在render进程中，所以这里是一个典型的IPC跨进程调用过程。render进程中的函数只是一个stub，它仅用于将调用请求转发给browser进程。

当进行自动绑定的构想时，遇到的第一个问题就是：
**如果把JavaScript函数都变成了RPC调用，是否存在某些情况我们无法进行等价转换？**

实际情况是，RPC调用和本地调用在能力上讲是等价的，可以进行切换，调用者不会感知到一个调用到底是本地调用还是远程调用，RPC调用在web后端开发中已经大量应用。从软件设计上讲，软件应该是模块化的，高内聚，低耦合，必要时我们使用接口来进行模块间的通信，此时接口等价于一种消息。如果调用是跨进程的，使用IPC来进行进程间的通信，这两者没有什么本质区别，调用者并不关心这个调用是跨了“模块”还是垮了“进程”，我们可以把“进程”理解为模块概念的强化，进程间的资源是天然强制隔离的，通信必须完全依赖消息。

## 4.3 解决思路：基于Qt反射实现自动注册

CEF中C++函数调用是一个典型的IPC调用过程，render进程中仅存在一个stub函数，将函数调用序列化后通过IPC消息通知给browser进程，browser进程执行完真整的函数调用后，通过IPC消息将结果发送回render进程。
所以问题的关键是，如果我们能在render进程中拿到要注册的C++函数的完整函数签名（函数名，参数数量，参数类型），我们就可以以此为基础注册一个同名的JavaScript函数，当这个函数被调用时，将函数调用信息（函数名，参数等）序列化并通过CEF标准的IPC通信机制发送给browser进程。browser进程解析IPC消息，根据调用函数名查找函数元信息，校验调用参数并最终通过反射执行对应的C++函数，最后将执行结果通过IPC消息发回render进程，完成整个调用过程。

C++本身不支持反射但是Qt是支持的，可以在Qt元对象系统和反射的基础上实现自动绑定。

# 5. 实现细节

## 5.1 注册和绑定
### 1. browser进程中以指定的名字注册一个QObject的子类对象
````C++
QCefJavaScriptEngine::get()->registerObject("base", new JSObjectBase(this));
````
### 2. 注册细节：遍历元对象，获取函数签名信息，写入共享内存
````C++
bool QCefObjectProtocol::registerJavaScriptHandlerObject(const QString& registerName, const QObject* registerObject) {
  //获取元对象
  auto metaObj = registerObject->metaObject();
  QJsonObject registerObjInfo;
  registerObjInfo.insert("registerName", registerName);
  registerObjInfo.insert("className", metaObj->className());
  for (int i = 0; i < metaObj->methodCount(); i++) {
    //获取函数名，函数签名，参数
    functionInfo.insert("functionName", QString::fromUtf8(metaMethod.name()));
    functionInfo.insert("functionSignature", QString::fromUtf8(metaMethod.methodSignature()));
    functionInfo.insert("returnType", metaMethod.returnType());
    //遍历参数列表
    for (int j = 0; j < metaMethod.parameterCount(); j++) {
      //获取参类型名和参数名，添加到Json Array中
    }
    //添加到Json Array
  }
  //将序列化好的函数注册信息Json写入到共享内存
  writeJsObjectRegisterInfo(jsonStr);
}
````
### 3. render进程初始化时解析Json信息并完成注册
````C++
bool QCefJavaScriptBinder::initRegisterObjectsData(const QString& jsonData)
{
    //解析注册信息，将函数签名信息反序列化为结构体，最终以注册名为key保存在map里
    ...
    m_javaScriptMetaObjectMap[regName] = objectInfo;
    return true;
}
````
### 4. 浏览器对象创建时（OnContextCreated接口调用），注册所有的C++函数
````C++
void* QCefJavaScriptBinder::bindAllObjects(CefRefPtr<CefV8Value> parentObj, CefRefPtr<CefBrowser> browser, CefRefPtr<CefFrame> frame)
{
    QCefJavaScriptEnvironment* pJsEnv = new QCefJavaScriptEnvironment();
    QStringList allRegisterNames = m_javaScriptMetaObjectMap.keys();
    for (const auto& regNameKey : allRegisterNames) {
        //一些必要的校验判断
        ...
        JavaScriptMetaObject& metaInfo = m_javaScriptMetaObjectMap[regNameKey];
        CefRefPtr<QCefJavaScriptObject> jsObj = new QCefJavaScriptObject(metaInfo, browser, frame);
        //根据函数注册信息完成C++函数到JavaScript环境的自动注册
        jsObj->registerObject(pJsEnv, regNameKey.toStdWString(), parentObj);
    }

    return pJsEnv;
}
````
### 5. 注册细节：
````C++
bool QCefJavaScriptObject::registerObject(QCefJavaScriptEnvironment* pJsEnv, CefString registerName, CefRefPtr<CefV8Value> cefParentObj)
{
    //遍历找到正确的parent对象
    ...
    //如果当前对象为空，创建它
    if (!currObjValue)
        currObjValue = CefV8Value::CreateObject(this, nullptr);
    //遍历所有的function注册信息
    for (const JavaScriptMetaMethod& funcInfo : m_metaObject.functions) {
        //创建handler实例用于响应JavaScript函数调用
        CefRefPtr<QCefFunctionObject> functionHandler = new QCefFunctionObject(funcInfo, m_browser, m_frame);
        //使用handler创建JavaScript函数，它是一个CefV8Value的实例
        CefRefPtr<CefV8Value> func = CefV8Value::CreateFunction(funcInfo.name.toStdWString(), functionHandler);
        //将handler保存在map中，方便后续访问
        m_functionMap.insert(funcInfo.name, functionHandler);
        //将新创建的函数对象插入到当前JS对象中
        currObjValue->SetValue(funcInfo.name.toStdWString(), func, V8_PROPERTY_ATTRIBUTE_NONE);
    }
    ...
    return true;
}
````
### 6. QCefFunctionObject::Execute实现
````C++
bool QCefFunctionObject::Execute(const CefString& name, CefRefPtr<CefV8Value> object,
    const CefV8ValueList& arguments, CefRefPtr<CefV8Value>& retval, CefString& exception)
{
    //创建CEF标准的IPC消息，消息名为QCEF_INVOKENGLMETHOD
    CefRefPtr<CefProcessMessage> msg = CefProcessMessage::Create(QCEF_INVOKENGLMETHOD);
    //获取调用参数列表
    CefRefPtr<CefListValue> args = msg->GetArgumentList();
    //获取browserId和frameId，前者是浏览器内部唯一标识，后者是frame内部唯一标识
    int browserId = m_browser->GetIdentifier();
    int64 frameId = m_frame->GetIdentifier();

    int idx = 0;
    //消息格式: browserId, frameId, C++类名，调用函数名，回调函数签名，参数列表
    args->SetString(idx++, QString::number(browserId).toStdString());
    args->SetString(idx++, QString::number(frameId).toStdString());
    args->SetString(idx++, m_metaMethod.className.toStdWString());
    args->SetString(idx++, name);
    args->SetString(idx++, m_metaMethod.signature.toStdWString());
    //check param count
    QStringList signatureList;
    QString callbackSignatures;
    int iSigIndex = idx;
    args->SetString(idx++, callbackSignatures.toStdWString());

    //序列化参数列表，根据不同的参数类型分别处理
    for (std::size_t i = 0; i < arguments.size(); i++) {
        if (arguments[i]->IsBool()) {
            args->SetBool(idx++, arguments[i]->GetBoolValue());
        } else if (arguments[i]->IsInt()) {
            args->SetInt(idx++, arguments[i]->GetIntValue());
        } else if (arguments[i]->IsDouble()) {
            double dValue = arguments[i]->GetDoubleValue();
            //如果double值为NAN，报错
            if (isnan(dValue)) {
                exception = QString(u8"argument %1 is nan !").arg(i).toStdWString();
                retval = CefV8Value::CreateUndefined();
                return false;
            }
            args->SetDouble(idx++, dValue);
        } else if (arguments[i]->IsString()) {
            args->SetString(idx++, arguments[i]->GetStringValue());
        } else if (arguments[i]->IsFunction()) {
            //参数类型为函数，生成回调函数签名
            ...
        } else {
            args->SetNull(idx++);
        }
    }

    //处理带返回值的同步调用，略
    ...
    // 发送IPC消息，尝试读取返回值，异步调用返回undefined
    if (m_browser && m_frame) {
        m_frame->SendProcessMessage(PID_BROWSER, msg);
        retval = readSynchronizeValue(retTypeSignature, m_metaMethod.retType);
    } else {
        retval = CefV8Value::CreateUndefined();
    }

    return true;
}
````
### 7. browser进程收到调用请求后的处理
````C++
bool QCefBrowserHandlerBase::DispatchNotifyRequest(CefRefPtr<CefBrowser> browser,
    CefProcessId source_process,
    CefRefPtr<CefProcessMessage> message)
{
    CefString messageName = message->GetName();
    CefRefPtr<CefListValue> messageArguments = message->GetArgumentList();
    if (!messageArguments)
        return false;

    int browserId = browser->GetIdentifier();
    if (messageName == QCEF_INVOKENGLMETHOD) {
        QVariantList varList;
        //遍历参数，将CEF参数列表转换为QVariantList
        for (size_t i = 0; i < messageArguments->GetSize(); i++) {
            ...
        }

        int idx = 0;
        if (QVariant::Type::String != varList[idx].type() ||
            QVariant::Type::String != varList[idx + 1].type()) {
            return false;
        }
        //获取browserId，判断是否需要处理此消息
        //browser和render是一对多的关系，当收到QCEF_INVOKENGLMETHOD消息时，需要根据browserId进行过滤，否则会重复调用
        int messageBrowserId = QString::fromStdString(varList[idx++].toString().toStdString()).toInt();
        int64 frameId = QString::fromStdString(varList[idx++].toString().toStdString()).toLongLong();
        if (messageBrowserId != browserId)
            return false;

        //执行反射调用
        QString strCallbackSignatures;
        bool bOk = QCefJavaScriptEngine::get()->inovkeMethod(browserId, varList, strCallbackSignatures);
        //调用失败，发送清理回调消息
        if (!bOk) {
            //send clear callbacks
            CefRefPtr<CefProcessMessage> msg = CefProcessMessage::Create(QCEF_CLEARNGLCALLBACKS);
            auto paramValue = msg->GetArgumentList();
            int idx = 0;
            paramValue->SetString(idx++, strCallbackSignatures.toStdWString());
            browser->GetMainFrame()->SendProcessMessage(CefProcessId::PID_RENDERER, msg);
        }
        return bOk;
    } else if (...) {
      ...
    }
}
````
### 8 Qt反射调用
````C++
bool QCefJavaScriptEngine::inovkeMethod(int browserId, const QVariantList& messageArguments, QString& callbackSignature)
{
    int messageBrowserId = QString::fromStdString(messageArguments[idx++].toString().toStdString()).toInt();
    qint64 frameId = QString::fromStdString(messageArguments[idx++].toString().toStdString()).toLongLong();
    //校验browserId
    if (messageBrowserId != browserId) {
        return false;
    }
    //校验消息格式
    //browserId className method methodSignature
    if (QVariant::Type::String != messageArguments[idx].type() ||
        QVariant::Type::String != messageArguments[idx + 1].type() ||
        QVariant::Type::String != messageArguments[idx + 2].type() ||
        QVariant::Type::String != messageArguments[idx + 3].type())
        return false;
    
    ...

    //根据IPC消息中的类名获取元对象实例
    if (!m_registeredMetaObjectMap.contains(className)) {
        TRACEE("meta method for name: %s not found !", qPrintable(className));
        return false;
    }
    const QMetaObject* metaObj = m_registeredMetaObjectMap[className];
    //校验元对象中是否存在此函数
    int iMethod = metaObj->indexOfMethod(metaObj->normalizedSignature(methodSignature.toStdString().c_str()).toStdString().c_str());
    if (iMethod == -1) {
        TRACEE("method %s index not found !", qPrintable(method));
        return false;
    }
    //获取元函数信息，以此为基础准备反射调用参数，对JS传过来的参数做适当的转换
    QMetaMethod metaMethod = m_registeredMetaObjectMap[className]->method(iMethod);

    //查找注册对象实例，后续在此对象上执行反射调用
    if (!m_jsObjectBindingMap.contains(className)) {
        TRACEE("class name: %s not found !", qPrintable(className));
        return false;
    }
    QObject* obj = m_jsObjectBindingMap[className];
    bool bNeedWrap = false;
    //参数转换，会做类型兼容处理，如果参数数量不够则补齐，多余的参数则忽略
    QVariantList varList;
    for (int i = 1; i < metaMethod.parameterCount(); i++) {
        int paramTypeId = metaMethod.parameterType(i);
        int messageIndex = idx + i;
        //转换和准备反射调用参数
        ...
    }

    bool bRet = false;
    QGenericReturnArgument retArg;
    //使用Qt的反射调用接口发起反射调用
    bRet = QMetaObject::invokeMethod(obj, qUtf8Printable(method), Qt::DirectConnection, retArg, argList[0],
        argList[1], argList[2], argList[3], argList[4], argList[5], argList[6], argList[7], argList[8], argList[9]);
    return bRet;
}
````
## 5.2 回调函数触发机制

在CEF中，JavaScript函数多为异步调用，通过传递一个callback的方式接收异步调用结果。callback本身是一个V8内的Function对象，它仅在当前render进程上下文中有效，无法通过简单的序列化直接传递到browser进程中，最终callback的触发也是要落回到render进程，那我们应该怎么触发回调呢？
所以我们想到了一个经典的解决方案“句柄”。
在Win32编程中， **句柄** 的存在非常普遍，大量的Win32 API都使用它作为参数，如WriteFile, CloseHandle，WaitForSingleObject等。句柄其实是内核句柄表的一个标识，使用它可以引用一个内核资源。这样内核就在不暴露内部资源本身的情况下允许用户操作该资源。
我们借用这个思路，当一个JavaScript函数被执行时，将参数传入的Function对象记录下来，为该对象生成一个唯一的key，将key作为参数通过IPC发送到browser进程，browser进程在合适的时机通过这个key发送IPC消息给render进程来触发回调。

### 1 Execute函数中对回调函数的处理
生成signature，将对象以以signature为key保存起来，这里考虑到一个函数中可以接收多个回调，最后拼接的signature以;分隔。
````C++
bool QCefFunctionObject::Execute(const CefString& name, CefRefPtr<CefV8Value> object,
    const CefV8ValueList& arguments, CefRefPtr<CefV8Value>& retval, CefString& exception)
{
    ...

    //序列化参数列表，根据不同的参数类型分别处理
    for (std::size_t i = 0; i < arguments.size(); i++) {
        if (arguments[i]->IsBool()) {
            ...
        } else if (arguments[i]->IsFunction()) {
            //参数类型为函数，生成回调函数签名
            QString strUuid;
            strUuid = QUuid::createUuid().toString().toUpper();
            strUuid = strUuid.mid(1, strUuid.size() - 2);
            strUuid = strUuid.replace("-", "");
            //生成格式为：browserId.frameId.className.methodName.index.uuid
            QString callbackSig = QString("%1.%2.%3.%4.%5.%6").arg(m_browser->GetIdentifier()).arg(frameId).arg(m_metaMethod.className).arg(m_metaMethod.name)
                .arg(i).arg(strUuid);
            signatureList << callbackSig;
            //保存当前的callback和contex
            QCefFunctionCallback functionCallback;
            functionCallback.callback = arguments[i];
            functionCallback.context = CefV8Context::GetCurrentContext();
            //以signature为key，插入到map中
            CefString callbackSignature = callbackSig.toStdWString();
            m_callbacksMap.insert(callbackSignature, functionCallback);
            TRACED("callback found at: %d, signature is: %s", i, qPrintable(callbackSig));
        } else {
            args->SetNull(idx++);
        }
    }

    //处理带返回值的同步调用，略
    ...
    // 发送IPC消息，尝试读取返回值，异步调用返回undefined
    if (m_browser && m_frame) {
        m_frame->SendProcessMessage(PID_BROWSER, msg);
        retval = readSynchronizeValue(retTypeSignature, m_metaMethod.retType);
    } else {
        retval = CefV8Value::CreateUndefined();
    }

    return true;
}
````
### 2 browser进程IPC触发回调
browser进程中，当函数执行结束后，拼接IPC消息发送给render进程用来触发回调
````C++
bool QCefCoreBrowserBase::invokeJavaScriptCallback(qint64 frameId, const QString& jsCallbackSignature, QVariantList params)
{
    if (!_browser)
        return false;

    CefRefPtr<CefProcessMessage> msg = CefProcessMessage::Create(QCEF_INVOKENGLCALLBACK);
    auto paramValue = msg->GetArgumentList();
    int idx = 0;
    paramValue->SetString(idx++, jsCallbackSignature.toStdWString());
    for (const auto& value : params) {
        QVariant::Type vType = value.type();
        if (vType == QVariant::Type::String) {
            ...
        } else {
            paramValue->SetNull(idx);
        }
    }
    CefRefPtr<CefFrame> frame = _browser->GetFrame(frameId);
    if (!frame) {
        TRACEE("browserId: %d get frame by frameId: %ld failed !", getBrowserId(), frameId);
        return false;
    }
    frame->SendProcessMessage(CefProcessId::PID_RENDERER, msg);
    return true;
}
````

### 3 render进程响应代码

render进程收到回调触发的IPC消息后，通过signatur中的信息查找到对应的回调函数并触发该回调

````C++
bool RenderDelegate::OnTriggerEventNotifyMessage(CefRefPtr<CefBrowser> browser,
            CefRefPtr<CefFrame> frame,
            CefProcessId source_process,
            CefRefPtr<CefProcessMessage> message)
    {
        TRACET();
        CefString messageName = message->GetName();
        if (messageName == QCEF_INVOKENGLCALLBACK) {
            CefRefPtr<CefListValue> messageArguments = message->GetArgumentList();
            ...
            strSignature = QString::fromStdWString(messageArguments->GetString(idx++).ToWString());
            auto sigList = strSignature.split(".");
            ...
            int browserId = sigList[0].toInt();
            int64 frameId = sigList[1].toLongLong();
            //not the same browser, return it.
            if (browserId != browser->GetIdentifier())
                return false;
            CefRefPtr<CefListValue> newArguments = CefListValue::Create();
            int iNewIdx = 0;
            //准备回调函数的参数
            for (idx; idx < messageArguments->GetSize(); idx++) {
                newArguments->SetValue(iNewIdx++, messageArguments->GetValue(idx));
            }
            auto it = frame_id_to_client_map_.find(frameId);
            if (it != frame_id_to_client_map_.end()) {
                it->second->invokeCallBack(strSignature, newArguments);
            } else {
                TRACEE("QCEF_INVOKENGLCALLBACK can't find QCefClient by id: %ld", frameId);
            }
        } else if (messageName == QCEF_CLEARNGLCALLBACKS) {
            ...
        }

        return false;
    }
}
````
### 4. 执行回调
````C++
bool QCefJavaScriptEnvironment::invokeCallBack(const QString& signature, CefRefPtr<CefListValue> argumentList)
{
    TRACED("signature is: %s", qPrintable(signature));
    auto sigList = signature.split(".");
    if (sigList.size() != SIGNATURE_VALID_PARTS_COUNT)
        return false;
    int browserId = sigList[0].toInt();
    int frameId = sigList[1].toInt();
    const QString& className = sigList[2];
    const QString& method = sigList[3];
    //根据className查找JavaScript对象
    if (!m_javaScriptObjectMap.contains(className)) {
        TRACEE("js object map not found %s", qPrintable(className));
        return false;
    }
    QPair<CefRefPtr<QCefJavaScriptObject>, CefRefPtr<CefV8Value>> jsObjectPair = m_javaScriptObjectMap[className];
    if (!jsObjectPair.first || !jsObjectPair.second) {
        TRACEE("%s: jsObjectPair invalid !", qPrintable(className));
        return false;
    }
    //根据函数名查找函数对象
    CefRefPtr<QCefFunctionObject> functionObj = jsObjectPair.first->getFunction(method);
    if (!functionObj) {
        TRACEE("get functionObj failed !");
        return false;
    }

    CefRefPtr<CefV8Value> retVal;
    CefString exception;
    //触发回调
    bool bRet = functionObj->ExecuteCallback(signature.toStdWString(), jsObjectPair.second, argumentList, retVal, exception);
    if (bRet)
        TRACED("execute callback using signature: %s success !", qPrintable(signature));
    else
        TRACEE("execute callback using signature: %s failed !!!", qPrintable(signature));
    return bRet;
}
````

````C++
bool QCefFunctionObject::ExecuteCallback(const CefString& signature, CefRefPtr<CefV8Value> object, CefRefPtr<CefListValue> arguments, CefRefPtr<CefV8Value>& retval, CefString& exception)
{
    //判断当前callback是否存在
    if (!m_callbacksMap.contains(signature)) {
        exception = "can't get callback !";
        return false;
    }
    //获取之前保存的callback结构，切换context
    QCefFunctionCallback funcCallback = m_callbacksMap[signature];
    if (!funcCallback.context->Enter()) {
        exception = L"enter current context error !";
        retval = CefV8Value::CreateUndefined();
        return false;
    }
    CefV8ValueList v8Arguments(arguments->GetSize());
    if (arguments) {
        for (size_t i = 0; i < arguments->GetSize(); i++) {
            //参数转换
            ...
        }
    }
    //调用CEF标准接口触发函数执行 CefV8Value::ExecuteFunction
    retval = funcCallback.callback->ExecuteFunction(object, v8Arguments);
    //退出上下文环境
    if (!funcCallback.context->Exit()) {
        exception = L"exit current context error !";
    }
    return true;
}
````

## 5.3 回调资源的管理

当我们使用句柄的时候，记得一定要调用CloseHandle关闭打开的句柄资源，否则会导致句柄泄露。回顾我们对回调函数的处理过程，回调函数也需要在合适的实际被释放，否则同样会造成泄露。CEF内部对象统一使用引用计数来管理，我们将回调保存在map中会导致该对象无法释放，这样是存在问题的。
那思考这样一个问题：**一个JavaScript回调函数的生命周期是怎样的？**
一个简单的思路是，回调函数执行完之后立即销毁回调对象，这样我们可以保证回调函数最终会被释放。 但是这样做是否恰当？当函数执行结束后，回调函数是否还可能继续存在？
在Launcher中存在这样一个接口调用：
````javascript
nts.stub.setCallback(callback);
````
这里要求web端注册一个回调，当stub的通知消息到达时，此回调会被触发，将通知消息透传给web。这时注册进去的callback更类似一个全局变量，可以被重复触发。
所以实际的情况是，回调函数在调用结束后，可能会继续存在，也可能被销毁，这个要看具体的业务需求，而业务存在于browser进程。
所以回调函数的释放时机：
1. 函数执行完之后自动释放
2. **由browser进程决定何时释放**

我们选方案2

简单的思路，添加一种专门用于释放回调函数的IPC消息，在恰当的时机发送给render进程，专门用来释放回调资源。但是这样存在一个问题，如果使用者忘了发送清理消息，callback仍然会泄露。本着**避免使用者出错**的原则，我们不希望用户关心释放的细节，这里使用C++的RAII对回调函数进行管理。
> RAII（**R**esource **A**cquisition **I**s **I**nitialization）,也称为“资源获取就是初始化”，是C++语言的一种管理资源、避免泄漏的惯用法。C++标准保证任何情况下，已构造的对象最终会销毁，即它的析构函数最终会被调用。简单的说，RAII 的做法是使用一个对象，在其构造时获取资源，在对象生命期控制对资源的访问使之始终保持有效，最后在对象析构的时候释放资源。

我们将callback的signature放如callBack对象中进行管理，通过引用计数来管理此对象的生命周期，直到不存在指针指向此对象，则销毁它，析构函数中发送释放回调函数的消息，从render进程中清理掉此回调。

实现代码如下：
````C++
class QCEFCORE_EXPORT JavaScriptCallback {
public:
    JavaScriptCallback(const QString& signature, class QCefCoreManagerBase* coreManager);
    JavaScriptCallback();
    ~JavaScriptCallback();
    bool isValid();
    void clear();
    void trigger(const QVariantList& vars);
    int getBrowserId();
    qint64 getFrameId();

public:
    QString m_callbackSignature;
    ...
};

//实现代码
JavaScriptCallback::~JavaScriptCallback()
{
    if (m_callbackSignature.isEmpty() || !m_coreManager)
        return;
    m_coreManager->clearJavaScriptCallback(m_callbackSignature);
}

bool JavaScriptCallback::isValid()
{
    return !m_callbackSignature.isEmpty();
}

void JavaScriptCallback::clear()
{
    m_callbackSignature.clear();
}

void JavaScriptCallback::trigger(const QVariantList& vars)
{
    if (m_callbackSignature.isEmpty() || !m_coreManager)
        return;
    m_coreManager->invokeJavaScriptCallback(m_callbackSignature, vars);
}

````

因为回调函数可能存在多个，所以我们构造了一个JavaScriptCallbacksCollection对象用来管理这些回调函数，它会接收形如：sig1;sig2;sig3;的字符串，拆分并依次构造回调对象，保存在内部的对象列表中。此对象是每一个C++导出函数的第一个参数，下面的绑定示例代码中演示了此对象的使用。当通过反射调用时，此对象会被构造并传递给C++函数。

## 5.4 简单使用

自动绑定层实现完成之后，使用是非常方便的，仅需要定义要导出的接口，然后注册即可，新增接口时直接添加新的C++函数，无需其它繁琐步骤即可自动注到JavaScript中。
### 1 定义QObject的子类，通过Qt宏将要导出的C++接口定义为槽函数
````C++
class JSObjectBase : public QObject {
    Q_OBJECT
public:
    JSObjectBase(QObject* parent);
public slots:

    /*
    1.getWebId——获取窗口的ID
    function signature	nts.base.getWebId(ResultCallback callback)
    parameters	参数名	参数类型	参数说明
    callback
    response	参数名	参数类型	参数说明
        id	string	该页面的唯一标识

    */
    void getWebId(const JavaScriptCallbacksCollection& cbCollection);

    ....
}

//实现代码
void JSObjectBase::getWebId(const JavaScriptCallbacksCollection& cbCollections)
{
    //获取第一个回调函数
    JavaScriptGetDataCallbackPtr cb = cbCollections.get<JavaScriptGetDataCallback>(0);
    //获取此回调对应的browserId
    int browserId = cb->getBrowserId();
    //根据browserId获取webId
    const QString& webId = NglLauncher::get()->getMainWindow()->getWebId(browserId);
    //拼接返回json，发送IPC消息触发回调
    cb->execute(ResultStatus_Success, JsonBuilder().add("id", webId).build(), "");
    //cb对象销毁，发送清理消息
}

````

### 2 注册Qt对象
````C++
void JavaScriptEngine::init(const QString& contextId, const QString& version, int versionCode)
{
    bool bOk = QCefJavaScriptEngine::get()->init();
    if (!bOk) {
        TRACEE("QCefJavaScriptEngine init failed !");
        return;
    }
    QCefJavaScriptEngine::get()->registerObject("base", new JSObjectBase(this));
    QCefJavaScriptEngine::get()->registerObject("login", new JSObjectLogin(this));
    QCefJavaScriptEngine::get()->registerObject("game", new JSObjectGame(this));
    QCefJavaScriptEngine::get()->registerObject("system", new JSObjectSystem(this));
    QCefJavaScriptEngine::get()->registerObject("system.os", new JSObjectOs(this));
    QCefJavaScriptEngine::get()->registerObject("system.disk", new JSObjectDisk(this));
    QCefJavaScriptEngine::get()->registerObject("system.memory", new JSObjectMemory(this));
    QCefJavaScriptEngine::get()->registerObject("system.cpu", new JSObjectCPU(this));
    QCefJavaScriptEngine::get()->registerObject("system.videoCard", new JSObjectVideoCard(this));
    QCefJavaScriptEngine::get()->registerObject("stub", new JSObjectStub(this));
    QCefJavaScriptEngine::get()->registerObject("ngl", new JSObjectNgl(contextId, version, versionCode, this));
    ...
}
````

### 3 测试
![](重构版Launcher开发实践：CEF篇/IMG_2020-11-30-09-47-26.png)