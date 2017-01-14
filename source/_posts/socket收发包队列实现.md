---
title: socket收发包队列实现
date: 2016-08-27 18:39:38
tags: 
- socket
categories: 
- 技术文档
- socket开发
---


socket中的粘包问题
===

写过socket的人都应该知道，在tcp收发包的时候会存在烦人的粘包问题。
这是因为tcp是以流的形式处理数据的，我们传输的数据并没有一个明显的"边界"。网络环境下，我们发给服务器的一条消息，假设有100字节，可能会因为网络传输慢等原因，在一次revc中，服务器只收到了80字节。或者是我们连发几个包给服务器，在一次收包的过程中收到了超过100个字节，那100字节之后的内容其实属于另一个消息。这样一来，如何确定消息"边界"就成为了一个亟待解决的问题。

问题的解决方案——定长收包vs收发包队列
---
解决问题的方案有两种：
1. 在recv中指定收包长度进行阻塞接收。这带来另一个问题：我们要知道收包长度。那么采用定长消息是个简单易行的方案
2. 将受到的消息以数据流的方式存储在内存缓冲区中，然后手工在缓冲区中查找消息边界，拆分消息并处理。这个方式允许我们使用变长消息

方式1的定长消息+阻塞接收是最简单易行的方案，但阻塞的接收方式效率低下，定长的方式则使我们的消息浪费了额外的存储空间。想实现高效传输，这个方案明显缺乏竞争力

那么我们再把目光投向方式2，变长消息可以有效节约网络流量提高传输效率。缓冲区的方式使得我们可以使用一个线程收包，另一个线程处理缓冲区执行消息处理，这样的方式会更高效。但是变长消息的每个消息域长度的确定手工实现会花费大量精力，消息缓冲区的实现也需要花一些功夫。

消息缓冲区的C++实现
------------
SocketCacheBuffer.h
````C++
///////////////////////////////////////////////////////////////////
//	用于socket的内存收包缓冲队列
//	设计思路:
//	socket收发包统一保存到此buffer中，此buffer采用一次性内存分配方式
//	对于内存大小，可以设置增长策略或者占满后报错（暂时只实现了定长）
//	收发包线程把收到的内容按字节流的方式线性存储在buffer内存中
//	buffer实现类似循环队列的方案，可以循环存储内存，除非内存占满
//	处理线程在这个队列中查找变长包的包结构
//	buffer可以设置在处理过程中锁定队列头指针或者copy一个副本的工作方式
//////////////////////////////////////////////////////////////////

#ifndef _Include_SocketCacheBuffer
#define _Include_SocketCacheBuffer

#include "NetProtocol.h"


class SocketCacheBuffer {

#define SocketBufferDefaultSize			1024 * 1204 * 1				//默认大小1M
#define SocketBufferMaxSize				1024 * 1024 * 10			//最大10M 


public:
	SocketCacheBuffer();
	SocketCacheBuffer(int size);
	~SocketCacheBuffer();
public:
	void InitializeBuffer();							//初始化Buffer
	void showBufferInfo();								//显示当前buffer信息
	bool lockPushData(void* data, int iLen);			//写入队列
	void* lockPopData(int len);							//弹出队列
	bool pushPacket(TcpPackType type, void* data, int iLen);//压入封包
	void* popPacket(bool fastRet);						//弹出封包 参数决定是否快速失败 其实就是同步等待


private:
	char* _buffer;				//缓冲区
	int _head_offset;				//头指针 相对偏移
	int _tail_offset;				//尾指针 相对偏移
	int _usedLen;				//已使用长度
	int _totalLen;				//总长度

	Mutex _mutex;				//互斥锁

private:
	bool pushData(bool bLock, void* data, int iLen);	//写入队列
	void* popData(bool bLock, int len);				//弹出队列
};

#endif

````




SocketCacheBuffer.cpp
````C++
#include "pch.h"
#include "SocketCacheBuffer.h"


SocketCacheBuffer::SocketCacheBuffer() {
	_totalLen = SocketBufferDefaultSize;
	_buffer = new char[SocketBufferDefaultSize];
	InitializeBuffer();
}
SocketCacheBuffer::SocketCacheBuffer(int size) {
	_totalLen = size;
	_buffer = new char[size];
	InitializeBuffer();
}
SocketCacheBuffer::~SocketCacheBuffer() {
	LogUtils::i(LOG_TAG, "SocketCacheBuffer::~SocketCacheBuffer release buffer");
	delete _buffer;
}

void SocketCacheBuffer::InitializeBuffer() {
	bzero(_buffer, _totalLen);
	_usedLen = 0;
	_head_offset = _tail_offset = 0;			//头尾指针指向相同位置
}

bool SocketCacheBuffer::pushData(bool bLock, void* data, int iLen) {
	if (bLock)
	{
		_mutex.Lock();
	}
	bool bRet = false;
	try {
		int freeLen = _totalLen - _usedLen;
		do
		{
			LogUtils::i(LOG_TAG, "SocketCacheBuffer::Push freeLen: %d iLen: %d", freeLen, iLen);
			if (!data)
			{
				LogUtils::i(LOG_TAG, "SocketCacheBuffer::Push data == NULL");
				break;
			}
			if (iLen > freeLen)
			{
				LogUtils::i(LOG_TAG, "SocketCacheBuffer::Push iLen(%d) > freeLen(%d)", iLen, freeLen);
				break;
			}
			int hardLen = 0;
			if (_tail_offset + iLen > _totalLen)
			{
				hardLen = ((int)_tail_offset + iLen) % _totalLen;
			}
			//just copy it 
			memcpy(_buffer + _tail_offset, data, iLen - hardLen);
			_tail_offset = ((int)_tail_offset + iLen - hardLen) % _totalLen;

			if (hardLen)
			{
				memcpy(_buffer + _tail_offset, (void*)((int)data + iLen - hardLen), hardLen);
				_tail_offset = ((int)_tail_offset + hardLen) % _totalLen;
			}

			_usedLen += iLen;
			bRet = true;
		} while (0);
	}
	catch (...) {
		LogUtils::e(LOG_TAG, "SocketCacheBuffer::Push error occurred !");
	}
	if (bLock)
	{
		_mutex.Unlock();
	}
	return bRet;
}

void* SocketCacheBuffer::popData(bool bLock, int iLen) {
	char* retMsg = NULL;
	MutexLocker locker(&_mutex);
	try
	{
		do
		{
			LogUtils::i(LOG_TAG, "SocketCacheBuffer::Pop usedLen: %d iLen: %d", _usedLen, iLen);
			if (iLen > _usedLen)
			{
				LogUtils::i(LOG_TAG, "SocketCacheBuffer::Pop iLen(%d) > usedLen(%d)", iLen, _usedLen);
				return NULL;
			}
			int hardLen = 0;
			if (_head_offset + iLen > _totalLen)
			{
				hardLen = ((int)_head_offset + iLen) % _totalLen;
			}
			retMsg = new char[iLen];
			bzero(retMsg, iLen);
			//just copy it 
			memcpy(retMsg, _buffer + _head_offset, iLen - hardLen);
			_head_offset = ((int)_head_offset + iLen - hardLen) % _totalLen;

			if (hardLen)
			{
				memcpy(retMsg + iLen - hardLen, _buffer + _head_offset, hardLen);
				_head_offset = ((int)_head_offset + hardLen) % _totalLen;
			}

			_usedLen -= iLen;
		} while (0);
	}
	catch (...)
	{
		LogUtils::e(LOG_TAG, "SocketCacheBuffer::Pop error occurred !");
		if (retMsg)
			delete retMsg;
	}
	return retMsg;
}


bool SocketCacheBuffer::lockPushData(void* data, int iLen) {
	return pushData(true, data, iLen);
}
void* SocketCacheBuffer::lockPopData(int len) {
	return popData(true, len);
}


void SocketCacheBuffer::showBufferInfo() {
	LogUtils::i(LOG_TAG, "SocketCacheBuffer::showBufferInfo totalSize: %d usedSize: %d head_offset: %d tail_offset: %d", _totalLen, _usedLen, _head_offset, _tail_offset);
}


bool SocketCacheBuffer::pushPacket(TcpPackType type, void* data, int iLen) {
	bool bRet = false;
	if (!(type > TypeBegin && type < TypeEnd))
	{
		LogUtils::e(LOG_TAG, "SocketCacheBuffer::pushPacket type: %d invilad !");
		return false;
	}
	if (!data)
	{
		LogUtils::e(LOG_TAG, "SocketCacheBuffer::pushPacket invilad data param: %d", data);
		return false;
	}
	if (!iLen)
	{
		LogUtils::e(LOG_TAG, "SocketCacheBuffer::pushPacket invilad iLen param: %d", iLen);
		return false;
	}
	int needLen = iLen + sizeof(NetProtocol::tailSig) + sizeof(TcpPackHeader);
	if (_totalLen - _usedLen < needLen)
	{
		LogUtils::e(LOG_TAG, "SocketCacheBuffer::pushPacket freeLen: %d needLen: %d", _totalLen - _usedLen, needLen);
		return false;
	}

	//包长度是要额外注意的
	TcpPackHeader header(type, iLen + sizeof(NetProtocol::tailSig));
	//锁定并执行压入操作
	MutexLocker locker(&_mutex);
	//祈祷它们都能成功吧 其实就算失败了 我们也可以在popPacket的时候丢弃
	pushData(false, &header, sizeof(header));
	pushData(false, data, iLen);
	pushData(false, (void*)NetProtocol::tailSig, sizeof(NetProtocol::tailSig));
	return true;
}

void* SocketCacheBuffer::popPacket(bool fastRet) {
	//TODO: 待完成
	char* packet = NULL;

	return packet;
}


````


一些简单的说明
-----
这是一份用在android ndk里的C++代码。在实现思路上，并没有使用new分配内存的方式存放消息内容，而是在一块事先分配好的内存中进行内存分配。可以理解为一个循环链表一样的结构，使用头，尾指针记录队列头尾的位置。这其实是一个内存分配器的简单实现。这样的事先避免了一些不必要的new和delete，在效率上更高效。而且socket本身就是基于流的网络协议，使用数组的方式按流的形式存取，整个实现会更好一些。

这是我第一次实现队列缓冲区，这份代码经过了简单的测试，但并没有在实际项目中应用。上面的加锁操作其实是为了实现线程安全存取。在设计上存和取发生在两个线程中。