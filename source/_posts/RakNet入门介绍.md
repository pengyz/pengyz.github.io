---
title: RakNet入门介绍
date: 2016-09-07 21:00:14
tags: 
- RakNet
categories: 
- 技术文档
- socket
- udp
---

# RakNet简单介绍 #

最近由于项目需要简单看了一下RakNet。
这是一个C++开发的基于UDP的开源网络库，具有良好的跨平台特性，主要用于网络游戏的通信，也可以用在各种网络软件上用于处理网络通信。

总体来说这个库功能完善，提供可靠的UDP传输，完善的插件机制。项目托管在[github](https://github.com/OculusVR/RakNet)目前已停止更新。关于它的具体用法，可以参考官网的例子和文档。

按照网上的说法 RakNet大概有如下特点：
> Radnet有以下特点：

>       高性能         在同一台计算机上，Radnet可以实现在两个程序之间每秒传输25，000条信息；

>       容易使用       Radnet有在线用户手册，视频教程。每一个函数和类都有详细的讲解，每一个功能都有自己的例程；

>       跨平台         当前Radnet支持Windows, Linux, Macs，可以建立在Visual Studio, GCC, Code: Blocks, DevCPP 和其它平台上；

>       在线技术支持   RakNet有一个活跃的论坛，邮件列表，你只要给他们发信，他们可以在几小时之内回复你。

>       安全的传输     RakNet在你的代码中自动使用SHA1, AES128, SYN，用RSA避免传输受到攻击

>       音频传输       用Speex编码解码，8位的音频只需要每秒500字节传输。

>       远程终端       用RakNet，你能远程管理你的程序，包括程序的设置，密码的管理和日志的管理。

>       目录服务器     目录服务器允许服务器列举他们自己需要的客户端，并与他们连接。

>       Autopatcher   Autopatcher系统将限制客户端传输到服务端的文件，这样是为了避免一些不合法的用户将一些不合法的文件传输到服务端。

>       对象重载系统

>       网络数据压缩   BitStream类允许压缩矢量，矩阵，四元数和在-1到1之间的实数。

>       远程功能调用

>       强健的通信层   可以保障信息按照不同的信道传输

而且网上说这个东西的文档和例子丰富，然而百度了一圈发现，除了官网的例子，RakNet的其他例子很少。像我这样暂时只要一个UDP可靠通信的人来说，就有点不太友好了。百度知道上关于RakNet词条中的例子肯定不是4.x版本的，根本就不能用。
经过一番百度+测试，终于自己搞定了一个简单的例子，代码贴上来做个备忘。

VS2015的测试工程，新建控制台工程，把github上clone的src目录的源码全部添加到工程，然后加上如下的测试代码：

````
#include "../RakNet/src/RakPeerInterface.h"
#include "../RakNet/src/RakNetTypes.h"
#include "../RakNet/src/MessageIdentifiers.h"
#include "../RakNet/src/BitStream.h"
#include "../RakNet/src/RakString.h"
#include "../RakNet/src/StringCompressor.h"


int StartServer();
int StartClient(void* param);

//测试下RakNet
void main(int argc, char* argv[]) {
	PTHREAD pThread = 0;
	RakNet::RakPeerInterface* peer = RakNet::RakPeerInterface::GetInstance();
	if (!peer)
	{
		LogUtils::e(LOG_TAG, "main get peer failed.");
		system("pause");
		return;
	}
	LogUtils::i(LOG_TAG, "（C）客服端 (S)服务器?");
	char str = getchar();
	if (str == 'c')
	{
		StartClient(NULL);
		//PlatformAbstract::CreateThread(pThread, (THREADPROCTYPE)&StartClient, NULL);
		LogUtils::e(LOG_TAG, "::main 客服端已经建立。");
	}
	else
	{
		StartServer();
		//PlatformAbstract::CreateThread(pThread, (THREADPROCTYPE)&StartServer, NULL);
		LogUtils::e(LOG_TAG, "::main 服务器已经建立。");
	}





	system("pause");
}

////这里是一个测试方法 可以直接放到测试工程中测试
int StartServer() {
	//给服务器端创建一个实例  
	RakNet::RakPeerInterface* pPeer = RakNet::RakPeerInterface::GetInstance();
	if (NULL == pPeer)
	{
		LogUtils::e(LOG_TAG, "TestFunc get pPeer failed.");
		return -1;
	}
	else
	{
		LogUtils::e(LOG_TAG, "::TestFunc ---------MyChatServer Init Success(C)-----------");
	}

	RakNet::Packet* pPacket;
	LogUtils::i(LOG_TAG, "::TestFunc Start Server .....");
	//启动服务器  
	RakNet::SocketDescriptor sd = RakNet::SocketDescriptor(6000, 0);
	RakAssert(RakNet::RAKNET_STARTED == pPeer->Startup(1, &sd, 1));
	//设置最大链接数  
	pPeer->SetMaximumIncomingConnections(1);
	auto boundAddress = pPeer->GetMyBoundAddress();
	const char* sAddr = boundAddress.ToString();
	LogUtils::e(LOG_TAG, "::StartServer sAddr: %s", sAddr);


	//////////////////////////////////////////////////////////////////////////  
	while (1)
	{
		for (pPacket = pPeer->Receive(); pPacket; pPeer->DeallocatePacket(pPacket), pPacket = pPeer->Receive())
		{
			LogUtils::e(LOG_TAG, "StartServer pPacket type: %d", pPacket->data[0]);
			switch (pPacket->data[0])
			{
			case ID_REMOTE_DISCONNECTION_NOTIFICATION: {
				LogUtils::e(LOG_TAG, "StartServer Another client has disconnected");
			}break;
			case ID_REMOTE_CONNECTION_LOST: {
				LogUtils::i(LOG_TAG, "StartServer ID_REMOTE_CONNECTION_LOST");
			}break;
			case ID_REMOTE_NEW_INCOMING_CONNECTION: {
				LogUtils::i(LOG_TAG, "StartServer ID_REMOTE_CONNECTION_LOST");
				RakNet::BitStream bs;
				bs.Write < RakNet::MessageID>(ServerConnectBack);
				RakNet::StringCompressor::Instance()->EncodeString(pPacket->systemAddress.ToString(true), 255, &bs);

			}break;
				//client端调用Connect后收到的server响应
			case ID_CONNECTION_REQUEST_ACCEPTED: {
				LogUtils::i(LOG_TAG, "StartServer ID_CONNECTION_REQUEST_ACCEPTED");

				RakNet::BitStream bsOut;
				bsOut.Write((RakNet::MessageID)ID_USER_PACKET_ENUM + 1);
				bsOut.Write("Server Say Hello.");
				pPeer->Send(&bsOut, HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 0, pPeer->GetMyBoundAddress(), false);
			}break;
				//server端收到来自client的Connect
			case ID_NEW_INCOMING_CONNECTION: {
				LogUtils::e(LOG_TAG, "StartServer ID_NEW_INCOMING_CONNECTION");
			}break;
			case ID_NO_FREE_INCOMING_CONNECTIONS: {
				LogUtils::e(LOG_TAG, "StartServer ID_NO_FREE_INCOMING_CONNECTIONS");
			}break;
			case ID_DISCONNECTION_NOTIFICATION: {
				LogUtils::e(LOG_TAG, "StartServer ID_DISCONNECTION_NOTIFICATION");
			}break;
			case ID_CONNECTION_LOST: {
				LogUtils::e(LOG_TAG, "StartServer ID_CONNECTION_LOST");
			}break;
			case ID_CONNECTION_ATTEMPT_FAILED: {
				LogUtils::e(LOG_TAG, "StartServer ID_CONNECTION_ATTEMPT_FAILED");
			}break;

				//用户自定义数据包  
			case ID_USER_PACKET_ENUM + 1:
			{
				LogUtils::e(LOG_TAG, "StartServer recv ID_USER_PACKET_ENUM + 1: %d", ID_USER_PACKET_ENUM + 1);
				RakNet::RakString rs1, rs2;
				RakNet::BitStream bsIn(pPacket->data, pPacket->length, false);
				bsIn.IgnoreBytes(sizeof(RakNet::MessageID));
				//bsIn.Read(rs);  //提取字符串           
				RakNet::StringCompressor::Instance()->DecodeString(&rs1, 255, &bsIn);
				RakNet::StringCompressor::Instance()->DecodeString(&rs2, 255, &bsIn);
				LogUtils::e(LOG_TAG, "::StartServer Recv User Data: %s %s %s", pPacket->systemAddress.ToString(true, '|'), rs1.C_String(), rs2.C_String());
			}
			break;

			default: {
				LogUtils::i(LOG_TAG, "::TestFunc Message with identifier %i has arrived", pPacket->data[0]);
			}break;
			}
		}
		sleep(100);
	}

	//////////////////////////////////////////////////////////////////////////  
	RakNet::RakPeerInterface::DestroyInstance(pPeer);
}

int StartClient(void* param) {
	//获取RakNetPeer接口
	RakNet::RakPeerInterface* peer = RakNet::RakPeerInterface::GetInstance();
	if (!peer)
	{
		LogUtils::e(LOG_TAG, "::StartClient get peer failed.");
		return 0;
	}
	RakNet::SocketDescriptor  sd = RakNet::SocketDescriptor(0, 0);
	RakAssert(RakNet::RAKNET_STARTED == peer->Startup(1, &sd, 1));
	LogUtils::i(LOG_TAG, "::StartClient get peer success");
	RakAssert(RakNet::CONNECTION_ATTEMPT_STARTED == peer->Connect("127.0.0.1", 6000, 0, 0, 0, 0));
	while (peer->IsActive())
	{
		//开始发包了
		LogUtils::i(LOG_TAG, "::StartClient %d 发包", GetTickCount());

		RakNet::BitStream bIn;
		bIn.Write<RakNet::MessageID>(ID_USER_PACKET_ENUM + 1);
		RakNet::StringCompressor::Instance()->EncodeString("Client Say Hello", 255, &bIn);
		RakNet::StringCompressor::Instance()->EncodeString("Client Say NMH", 255, &bIn);
		//注意broadcast参数 如果是true，则发广播，systemidentifier表示不发送地址，一般使用常量 RakNet::UNASSIGNED_SYSTEM_ADDRESS
		//					如果是false，则往systemidentifier指定的ip和端口处发送
		//					如果发包是有序的，则channel指定了信道，同一信道的具有递增的排序值，避免有多种有序消息的排序值相互干扰
		uint32_t sendrs = peer->Send(&bIn, HIGH_PRIORITY, UNRELIABLE_SEQUENCED, 0, RakNet::SystemAddress("127.0.0.1", 6000), false);
		LogUtils::e(LOG_TAG, "StartClient sendres: %d", sendrs);
		Sleep(1000);
	}

	peer->Shutdown(1000);
	RakNet::RakPeerInterface::DestroyInstance(peer);
	peer = NULL;
	LogUtils::e(LOG_TAG, "Disconnect from Server. StartClient peer closed");
	return 0;
}
````


对于Android，我们可以把RakNet编译成静态库，然后链接到我们的so库中使用，

Android.mk内容如下
````
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := RakNet
LOCAL_MODULE_FILENAME := libRakNet

APP_ABI := armeabi armeabi-v7a 


# 遍历目录及子目录的函数
define walk
$(wildcard $(1)) $(foreach e, $(wildcard $(1)/*), $(call walk, $(e)))
endef

# 按目录引用
FILE_LIST := $(filter %.cpp, $(call walk, $(LOCAL_PATH)/src))


# 这里注意做一次重复条目过滤 call uniq 不然重复条目会报很多错误
LOCAL_SRC_FILES := $(call uniq,$(FILE_LIST:$(LOCAL_PATH)/%=%))


include $(BUILD_STATIC_LIBRARY)
````

Application.mk内容如下
````
APP_STL := gnustl_static
APP_CPPFLAGS += -fexceptions
APP_ABI :=armeabi armeabi-v7a
APP_PLATFORM := android-19
````